import 'package:flutter/services.dart';

class VndFormatter extends TextInputFormatter {
  static String format(int v) {
    final s = v.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return result.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old,
      TextEditingValue val,
      ) {
    final digits = val.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return val.copyWith(text: '');
    final clean = digits.replaceFirst(RegExp(r'^0+'), '');
    if (clean.isEmpty) return val.copyWith(text: '0');
    final result = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && (clean.length - i) % 3 == 0) result.write('.');
      result.write(clean[i]);
    }
    final s = result.toString();
    return val.copyWith(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}