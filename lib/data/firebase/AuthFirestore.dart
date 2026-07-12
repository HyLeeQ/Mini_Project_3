import 'package:firebase_auth/firebase_auth.dart';

class AuthFireStore{
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}