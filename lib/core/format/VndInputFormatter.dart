import 'package:flutter/services.dart';

// ── VND Formatter ───────────────────────────────────────────────────
// Tự động format: 1000000 → 1.000.000
// Khi lấy giá trị thật: xoá dấu chấm rồi parse
class VndInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Chỉ giữ lại chữ số
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format với dấu chấm phân cách hàng nghìn
    final formatted = _formatVnd(digits);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatVnd(String digits) {
    // Xoá số 0 ở đầu (trừ khi chỉ có 1 chữ số)
    final cleaned = digits.length > 1
        ? digits.replaceFirst(RegExp(r'^0+'), '')
        : digits;

    if (cleaned.isEmpty) return '0';

    // Chèn dấu chấm mỗi 3 chữ số từ phải sang trái
    final result = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && (cleaned.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(cleaned[i]);
    }
    return result.toString();
  }
}

// ── Helper lấy giá trị double từ text đã format ─────────────────────
// Dùng khi save: parseVnd(controller.text) → 1000000.0
double parseVnd(String formattedText) {
  return double.tryParse(
    formattedText.replaceAll('.', '').replaceAll(',', ''),
  ) ??
      0.0;
}