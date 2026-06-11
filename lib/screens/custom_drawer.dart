import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'radar_screen.dart';
import 'car_setup_screen.dart';
import 'add_pricing_screen.dart'; // تأكد أن اسم الملف صحيح عندك
import 'login_screen.dart'; // لتسجيل الخروج

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0B1120),
      child: Column(
        children: [
          // رأس القائمة الجانبية (الهيدر)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Color(0xFF38BDF8), width: 2)),
            ),
            child: const Column(
              children: [
                Icon(Icons.directions_car, size: 70, color: Color(0xFF38BDF8)),
                SizedBox(height: 15),
                Text('كابتن وصلني', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                Text('لوحة التحكم', style: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Cairo')),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // 1. زر الرادار
          _buildMenuItem(
            context: context,
            icon: Icons.radar,
            title: 'رادار الرحلات',
            onTap: () {
              Navigator.pop(context); // إغلاق القائمة أولاً
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RadarScreen()));
            },
          ),

          // 2. زر إضافة الأسعار
          _buildMenuItem(
            context: context,
            icon: Icons.price_change,
            title: 'إضافة تسعيرة للمناطق',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPricingScreen()));
            },
          ),

          // 3. زر إعدادات السيارة
          _buildMenuItem(
            context: context,
            icon: Icons.edit_road,
            title: 'إعدادات مركبتي',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CarSetupScreen()));
            },
          ),

          const Spacer(), // لدفع زر تسجيل الخروج للأسفل
          const Divider(color: Colors.white24),

          // 4. زر تسجيل الخروج
          _buildMenuItem(
            context: context,
            icon: Icons.logout,
            title: 'تسجيل خروج',
            color: Colors.redAccent,
            onTap: () async {
              // مسح بيانات الدخول
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('driver_id');
              
              if (context.mounted) {
                // العودة لشاشة الدخول ومسح كل الشاشات السابقة
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // دالة مساعدة لتصميم أزرار القائمة بشكل فخم
  Widget _buildMenuItem({
    required BuildContext context, 
    required IconData icon, 
    required String title, 
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color == Colors.white ? const Color(0xFF38BDF8) : color),
      title: Text(title, style: TextStyle(color: color, fontSize: 16, fontFamily: 'Cairo')),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap,
    );
  }
}