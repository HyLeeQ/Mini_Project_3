import 'dart:convert';

import 'package:expense_tracker/data/model/UserModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsService{
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    print('luu thanh cong');
  }
  static Future<UserModel?> getUser() async{
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null) {
      final json = jsonDecode(data);
      print('lay du lieu thanh cong');
      return UserModel.fromJson(json);
    }
    return null;
  }
}