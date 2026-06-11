import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // مكتبة فايربيس الأساسية
import 'package:firebase_messaging/firebase_messaging.dart'; // مكتبة الإشعارات
import 'screens/login_screen.dart';
import 'screens/radar_screen.dart';

// 1. الدالة المسؤولة عن استقبال الإشعارات عندما يكون التطبيق مغلقاً أو في الخلفية
// يجب أن تكون خارج أي كلاس
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 إشعار في الخلفية (سائق): ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة Firebase قبل تشغيل التطبيق
  await Firebase.initializeApp();

  // 3. تفعيل مستقبل الإشعارات في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. طلب صلاحية إرسال الإشعارات من الكابتن (مهم جداً لنظام أندرويد 13+)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 5. جلب وطباعة الـ Token السري الخاص بهذا الهاتف (سنستخدمه لاحقاً لإرسال الإشعار)
  String? token = await messaging.getToken();
  debugPrint("🔑 Firebase Token (Driver): $token");

  // تهيئة Supabase
  await Supabase.initialize(
    url: 'https://ioibmpzageijxvmsqpem.supabase.co',
    publishableKey: 'sb_publishable_3jNA9wjj8Ns3YB2y7AT48g_ZmmNfJQW',
  );

  final prefs = await SharedPreferences.getInstance();
  final String? userId = prefs.getString('driver_id');

  runApp(WasalniDriverApp(initialRoute: userId == null ? 'login' : 'radar'));
}

class WasalniDriverApp extends StatelessWidget {
  final String initialRoute;
  
  const WasalniDriverApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وصلني - كابتن',
      theme: ThemeData(
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)), // كحلي فخم
        useMaterial3: true,
      ),
      home: initialRoute == 'login' ? const LoginScreen() : const RadarScreen(),
    );
  }
}