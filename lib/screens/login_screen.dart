import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'car_setup_screen.dart';
import 'radar_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  final Color bgColor = const Color(0xFF0B1120);
  final Color accentColor = const Color(0xFF38BDF8);
  final Color inputFillColor = const Color(0xFF1E293B);
  final Color textColor = Colors.white;

  Future<void> _registerDriver() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    // 1. التحقق من صحة البيانات
    if (name.isEmpty || phone.isEmpty) {
      _showSnackBar('الرجاء إدخال الاسم ورقم الموبايل ✋');
      return;
    }

    final phoneRegex = RegExp(r'^[0-9]{9,10}$');
    if (!phoneRegex.hasMatch(phone)) {
      _showSnackBar('الرجاء إدخال رقم هاتف صحيح (9 أو 10 أرقام)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      String userId;
      bool isNewDriver = false;

      // 2. البحث عن الكابتن في قاعدة البيانات
      final existingUser = await supabase
          .from('users')
          .select()
          .eq('phone_number', phone)
          .eq('role', 'driver')
          .maybeSingle();

      if (existingUser != null) {
        userId = existingUser['id'];
        if (existingUser['full_name'] != name) {
          await supabase.from('users').update({'full_name': name}).eq('id', userId);
        }
      } else {
        final newUser = await supabase.from('users').insert({
          'full_name': name,
          'phone_number': phone,
          'role': 'driver',
        }).select().single();
        
        userId = newUser['id'];
        isNewDriver = true;
      }

      // 3. حفظ الجلسة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driver_id', userId);

      // 4. فحص هل الكابتن أكمل بيانات سيارته؟
      final carProfile = await supabase
          .from('driver_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      bool needsCarSetup = isNewDriver || carProfile == null;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => needsCarSetup ? const CarSetupScreen() : const RadarScreen()),
        );
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال بالسيرفر. حاول لاحقاً.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
      backgroundColor: accentColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              FadeInDown(child: Center(child: Icon(Icons.drive_eta_rounded, size: 80, color: accentColor))),
              const SizedBox(height: 40),
              FadeInLeft(child: const Text('بوابة الكباتن', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo'))),
              const SizedBox(height: 60),
              FadeInUp(child: _buildTextField(_nameController, 'اسم الكابتن', Icons.person)),
              const SizedBox(height: 20),
              FadeInUp(child: _buildTextField(_phoneController, 'رقم الموبايل', Icons.phone, TextInputType.phone)),
              const SizedBox(height: 50),
              FadeInUp(child: SizedBox(height: 58, child: ElevatedButton(
                onPressed: _isLoading ? null : _registerDriver,
                style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('دخول الكابتن 🚀', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
              ))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType type = TextInputType.text]) {
    return Container(
      decoration: BoxDecoration(color: inputFillColor, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5), fontFamily: 'Cairo'),
          prefixIcon: Icon(icon, color: accentColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}