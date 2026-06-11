import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPricingScreen extends StatefulWidget {
  const AddPricingScreen({super.key});

  @override
  State<AddPricingScreen> createState() => _AddPricingScreenState();
}

class _AddPricingScreenState extends State<AddPricingScreen> {
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _savePrice() async {
    // 1. التحقق من الحقول
    if (_locationController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تعبئة كافة الحقول')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driver_id');
      
      // 2. إرسال البيانات لقاعدة البيانات
      await supabase.from('driver_pricing').insert({
        'driver_id': driverId,
        'location_name': _locationController.text,
        'price': int.parse(_priceController.text),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ السعر بنجاح!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        title: const Text('إضافة تسعيرة جديدة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTextField(_locationController, 'اسم المنطقة أو الوجهة', Icons.location_on),
            const SizedBox(height: 16),
            _buildTextField(_priceController, 'السعر (ل.س)', Icons.attach_money, isNumber: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ السعر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}