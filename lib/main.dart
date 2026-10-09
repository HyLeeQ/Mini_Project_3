import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'data/repositories/services/PermissionService.dart';
import 'data/repositories/services/notification.dart';
import 'features/intro/splashscreen.dart';
import 'firebase_options.dart'; // file được gen bởi flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } catch (e) {
      debugPrint('SystemChrome error: $e');
    }
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initializeApp error: $e');
  }

  if (!kIsWeb) {
    try {
      await PermissionService.requestAllPermissions();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService().init();
      final token = await NotificationService().getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Mobile services init error: $e');
    }
  }

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoctorĐồng',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF07070D),
        fontFamily: 'SF Pro Display',
      ),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            // Màn hình điện thoại hoặc thiết bị nhỏ (chiều rộng <= 500px)
            if (constraints.maxWidth <= 500) {
              return ScreenUtilInit(
                designSize: const Size(360, 740),
                minTextAdapt: true,
                splitScreenMode: true,
                child: child,
              );
            }

            // Trên máy tính / Desktop Web: Hiển thị khung điện thoại chuẩn đẹp mắt
            const phoneWidth = 390.0;
            final phoneHeight = (820.0).clamp(0.0, constraints.maxHeight - 32.0);

            return Container(
              color: const Color(0xFF07070D),
              child: Center(
                child: Container(
                  width: phoneWidth,
                  height: phoneHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(color: const Color(0xFF282E40), width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(0xFFD4A843).withOpacity(0.08),
                        blurRadius: 60,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34.5),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(phoneWidth, phoneHeight),
                      ),
                      child: ScreenUtilInit(
                        designSize: const Size(360, 740),
                        minTextAdapt: true,
                        splitScreenMode: true,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      home: const SplashScreen(),
    );
  }
}