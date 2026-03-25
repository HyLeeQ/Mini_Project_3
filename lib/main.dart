import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'features/intro/splashscreen.dart';
import 'firebase_options.dart'; // file được gen bởi flutterfire configure

void main() async {
  // ✅ Bắt buộc phải có trước mọi thứ
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // ✅ Kích thước máy đang debug SM A750GN
      designSize: const Size(360, 740),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'DoctorĐồng',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFF07070D),
            fontFamily: 'SF Pro Display', // hoặc font bạn đang dùng
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}