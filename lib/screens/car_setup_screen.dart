import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ضروري للويب
import 'dart:typed_data'; // ضروري للويب

class CarSetupScreen extends StatefulWidget {
  const CarSetupScreen({super.key});

  @override
  State<CarSetupScreen> createState() => _CarSetupScreenState();
}

class _CarSetupScreenState extends State<CarSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  
  File? _imageFile;      // للموبايل
  Uint8List? _webImage;  // للويب
  bool _isLoading = false;

  // 1. اختيار الصورة (يدعم الويب والموبايل)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _imageFile = File(pickedFile.path));
      }
    }
  }

  // 2. حفظ البيانات ورفع الصورة (يدعم الويب والموبايل)
  Future<void> _saveCarDetails() async {
    // التحقق: هل المستخدم اختار صورة؟
    if (_nameController.text.isEmpty || (_imageFile == null && _webImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تعبئة الاسم واختيار صورة!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // رفع الصورة بناءً على المنصة
      if (kIsWeb && _webImage != null) {
        await supabase.storage.from('car_images').uploadBinary(fileName, _webImage!);
      } else if (_imageFile != null) {
        await supabase.storage.from('car_images').upload(fileName, _imageFile!);
      }

      final imageUrl = supabase.storage.from('car_images').getPublicUrl(fileName);

      // حفظ البيانات
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driver_id');

      await supabase.from('driver_profiles').upsert({
        'user_id': driverId,
        'driver_name': _nameController.text,
        'car_model': _carModelController.text,
        'car_color': _carColorController.text,
        'car_image_url': imageUrl,
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/radar'); 
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الرفع: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المركبة الشخصية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                // عرض الصورة (يتغير حسب المنصة)
                child: kIsWeb 
                    ? (_webImage != null ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_webImage!, fit: BoxFit.cover)) : const Icon(Icons.camera_alt, size: 50, color: Colors.grey))
                    : (_imageFile != null ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, fit: BoxFit.cover)) : const Icon(Icons.camera_alt, size: 50, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم الكابتن')),
            TextField(controller: _carModelController, decoration: const InputDecoration(labelText: 'نوع السيارة')),
            TextField(controller: _carColorController, decoration: const InputDecoration(labelText: 'لون السيارة')),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _saveCarDetails, child: const Text('حفظ البيانات والبدء')),
          ],
        ),
      ),
    );
  }
}