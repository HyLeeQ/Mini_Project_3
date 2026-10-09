import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'ReceiptMLKitService.dart';

class ReceiptAIService {
  /// Quét hóa đơn ưu tiên On-Device ML Kit (Offline, sub-100ms, zero cloud cost)
  Future<Map<String, dynamic>?> scanReceipt(
    File imageFile, {
    Rect? cropRectRatio,
  }) async {
    try {
      // 1. Thử nhận diện bằng On-Device ML Kit và Heuristic Regex
      final mlResult = await ReceiptMLKitService.instance.parseReceiptImage(
        imageFile,
        cropRectRatio: cropRectRatio,
      );

      if (mlResult.totalAmount != null ||
          mlResult.merchantName != null ||
          mlResult.rawExtractedText.isNotEmpty) {
        return {
          "total": mlResult.totalAmount?.toInt(),
          "categoryId": mlResult.suggestedCategoryId ?? "1",
          "merchantName": mlResult.merchantName,
          "date": mlResult.transactionDate ?? DateTime.now(),
          "note": mlResult.merchantName != null
              ? 'Hóa đơn: ${mlResult.merchantName}'
              : 'Quét hóa đơn OCR',
          "rawText": mlResult.rawExtractedText,
        };
      }
    } catch (e) {
      debugPrint("Lỗi khi chạy on-device ML Kit: $e");
    }

    return null;
  }
}