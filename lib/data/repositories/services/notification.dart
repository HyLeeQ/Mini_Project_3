import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 🔐 xin quyền
    await FirebaseMessaging.instance.requestPermission();

    // 📱 init local notification
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(settings: settings);

    // 🎯 lắng nghe foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // 👉 click khi app background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("User click notification");
    });
  }
  void _showNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // 👈 QUAN TRỌNG
      title: message.notification?.title ?? "No title",
      body: message.notification?.body ?? "No body",
      notificationDetails: details,
    );
  }

  Future<String?> getToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}