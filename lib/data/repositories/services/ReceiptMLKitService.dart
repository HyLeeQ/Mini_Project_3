import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Kết quả bóc tách dữ liệu hóa đơn từ On-Device ML Kit & Regex Heuristics
class ParsedReceiptResult {
  final double? totalAmount;
  final String? rawAmountString;
  final DateTime? transactionDate;
  final String? rawDateString;
  final String? merchantName;
  final String? suggestedCategoryId;
  final String rawExtractedText;

  ParsedReceiptResult({
    this.totalAmount,
    this.rawAmountString,
    this.transactionDate,
    this.rawDateString,
    this.merchantName,
    this.suggestedCategoryId,
    required this.rawExtractedText,
  });
}

class ReceiptMLKitService {
  static final ReceiptMLKitService instance = ReceiptMLKitService._init();
  ReceiptMLKitService._init();

  /// Quét hóa đơn hoàn toàn OFFLINE trên thiết bị bằng Google ML Kit
  /// [cropRectRatio]: Rect tỉ lệ tương đối (0.0 - 1.0) để cắt khung trước khi nhận diện (Framing crop)
  Future<ParsedReceiptResult> parseReceiptImage(
    File imageFile, {
    Rect? cropRectRatio,
  }) async {
    File fileToProcess = imageFile;

    // 1. Framing Crop nếu được cung cấp tỉ lệ khung ngắm
    if (cropRectRatio != null) {
      final cropped = await cropImageWithRatio(imageFile, cropRectRatio);
      if (cropped != null) {
        fileToProcess = cropped;
      }
    }

    // 2. Nhận diện văn bản On-Device bằng Google ML Kit (Offline, sub-100ms)
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFilePath(fileToProcess.path);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      final fullText = recognizedText.text;

      // 3. Trích xuất thông tin qua Custom Heuristic Regex Engine
      final lines = recognizedText.blocks
          .expand((b) => b.lines)
          .map((l) => l.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final total = _extractTotalAmount(fullText, lines);
      final date = _extractTransactionDate(fullText);
      final merchant = _extractMerchantName(lines);
      final categoryId = _guessCategoryId(fullText, merchant);

      return ParsedReceiptResult(
        totalAmount: total,
        rawAmountString: total?.toInt().toString(),
        transactionDate: date,
        rawDateString: date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
            : null,
        merchantName: merchant,
        suggestedCategoryId: categoryId,
        rawExtractedText: fullText,
      );
    } catch (e) {
      debugPrint('Lỗi On-Device ML Kit OCR: $e');
      return ParsedReceiptResult(rawExtractedText: '');
    } finally {
      await textRecognizer.close();
    }
  }

  /// Cắt ảnh theo khung viền tương đối (Framing crop overlay)
  Future<File?> cropImageWithRatio(File imageFile, Rect ratioRect) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final x = (ratioRect.left * image.width).clamp(0, image.width - 1).toInt();
      final y = (ratioRect.top * image.height).clamp(0, image.height - 1).toInt();
      final w = (ratioRect.width * image.width).clamp(1, image.width - x).toInt();
      final h = (ratioRect.height * image.height).clamp(1, image.height - y).toInt();

      final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
      final tempPath = '${imageFile.parent.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));
      return croppedFile;
    } catch (e) {
      debugPrint('Lỗi crop framing ảnh: $e');
      return null;
    }
  }

  /// ================== 1. REGEX TỔNG TIỀN (TOTAL AMOUNTS) ==================
  /// Hỗ trợ các mẫu: 150,000 VND, 150.000 đ, 150 000, v.v.
  double? _extractTotalAmount(String fullText, List<String> lines) {
    // Chuẩn hóa khoảng trắng hàng nghìn (ví dụ 150 000 -> 150000)
    final normalized = fullText.replaceAllMapped(
      RegExp(r'(\d)\s+(\d{3})'),
      (m) => '${m.group(1)}${m.group(2)}',
    );
    final lower = normalized.toLowerCase();

    // Các từ khóa chỉ tổng tiền theo thứ tự ưu tiên
    final totalKeywords = [
      'tổng cộng',
      'tong cong',
      'tổng tiền',
      'tong tien',
      'thành tiền',
      'thanh tien',
      'thanh toán',
      'thanh toan',
      'tiền thanh toán',
      'tiền mặt',
      'phải trả',
      'khách phải trả',
      'grand total',
      'total amount',
      'total',
      'amount due',
      'amount',
      'cộng tiền hàng',
    ];

    // Regex bắt các format tiền: 150,000 VND, 150.000 đ, 150.000, 150,000, v.v.
    final amountPattern = RegExp(
      r'(?:[\$₫]|vnd|vnđ)?\s*(\d{1,3}(?:[\.,]\d{3})+(?:[\.,]\d{2})?|\d{4,})\s*(?:[\$₫]|vnd|vnđ)?',
      caseSensitive: false,
    );

    // 1. Tìm theo khu vực lân cận của các từ khóa tổng tiền
    for (final kw in totalKeywords) {
      int kwIndex = lower.indexOf(kw);
      while (kwIndex != -1) {
        // Lấy đoạn văn bản 120 ký tự ngay sau từ khóa
        final start = kwIndex + kw.length;
        final end = (start + 120).clamp(0, lower.length);
        final segment = lower.substring(start, end);

        final matches = amountPattern.allMatches(segment);
        double maxInSegment = 0.0;
        for (final m in matches) {
          final raw = m.group(1);
          if (raw != null) {
            final val = _cleanNumber(raw);
            if (val != null && val >= 1000 && val < 500000000) {
              if (val > maxInSegment) maxInSegment = val;
            }
          }
        }
        if (maxInSegment > 0) return maxInSegment;

        kwIndex = lower.indexOf(kw, start);
      }
    }

    // 2. Tìm theo từng dòng có chứa từ khóa total
    for (final line in lines) {
      final lineLower = line.toLowerCase();
      if (totalKeywords.any((k) => lineLower.contains(k))) {
        final matches = amountPattern.allMatches(line);
        double maxInLine = 0.0;
        for (final m in matches) {
          final raw = m.group(1);
          if (raw != null) {
            final val = _cleanNumber(raw);
            if (val != null && val >= 1000 && val < 500000000) {
              if (val > maxInLine) maxInLine = val;
            }
          }
        }
        if (maxInLine > 0) return maxInLine;
      }
    }

    // 3. Fallback: Lấy số tiền lớn nhất trong toàn bộ hóa đơn (loại bỏ SĐT/Mã số thuế)
    double maxFallback = 0.0;
    for (final m in amountPattern.allMatches(normalized)) {
      final raw = m.group(1);
      if (raw != null) {
        // Loại bỏ số điện thoại bắt đầu 03, 05, 07, 08, 09
        if (raw.startsWith('09') ||
            raw.startsWith('08') ||
            raw.startsWith('07') ||
            raw.startsWith('03')) {
          continue;
        }
        final val = _cleanNumber(raw);
        if (val != null && val >= 1000 && val < 100000000) {
          if (val > maxFallback) maxFallback = val;
        }
      }
    }

    return maxFallback > 0 ? maxFallback : null;
  }

  double? _cleanNumber(String raw) {
    // Nếu có dạng 150.000 hoặc 150,000
    final clean = raw.replaceAll(RegExp(r'[\.,\s]'), '');
    return double.tryParse(clean);
  }

  /// ================== 2. REGEX NGÀY GIAO DỊCH (TRANSACTION DATES) ==================
  /// Hỗ trợ DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, YYYY-MM-DD
  DateTime? _extractTransactionDate(String fullText) {
    // Regex cho ngày tháng
    final datePatterns = [
      // DD/MM/YYYY hoặc DD-MM-YYYY hoặc DD.MM.YYYY
      RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](20\d\d)\b'),
      // YYYY-MM-DD hoặc YYYY/MM/DD
      RegExp(r'\b(20\d\d)[\/\-\.](0?[1-9]|1[012])[\/\-\.](0?[1-9]|[12][0-9]|3[01])\b'),
      // DD/MM/YY
      RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](\d{2})\b'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        try {
          if (match.pattern == datePatterns[1]) {
            // YYYY-MM-DD
            final y = int.parse(match.group(1)!);
            final m = int.parse(match.group(2)!);
            final d = int.parse(match.group(3)!);
            return DateTime(y, m, d);
          } else if (match.pattern == datePatterns[2]) {
            // DD/MM/YY
            final d = int.parse(match.group(1)!);
            final m = int.parse(match.group(2)!);
            final yy = int.parse(match.group(3)!);
            final y = 2000 + yy;
            return DateTime(y, m, d);
          } else {
            // DD/MM/YYYY
            final d = int.parse(match.group(1)!);
            final m = int.parse(match.group(2)!);
            final y = int.parse(match.group(3)!);
            return DateTime(y, m, d);
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// ================== 3. HEURISTICS TÊN CỬA HÀNG (MERCHANT NAMES) ==================
  String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    // Danh sách thương hiệu phổ biến thường gặp ở Việt Nam
    final knownBrands = [
      'co.opmart',
      'coopmart',
      'winmart',
      'vinmart',
      'circle k',
      '7-eleven',
      'familymart',
      'gs25',
      'ministop',
      'highlands coffee',
      'highlands',
      'phúc long',
      'phuclong',
      'the coffee house',
      'starbucks',
      'kfc',
      'lotteria',
      'jollibee',
      'mcdonald',
      'pizza hut',
      'domino',
      'bách hóa xanh',
      'bach hoa xanh',
      'big c',
      'tops market',
      'lotte mart',
      'lotte cinema',
      'cgv',
      'fahasa',
      'tiki',
      'nhà sách',
      'nhà thuốc',
      'pharmacity',
      'long châu',
      'petrolimex',
      'pvoil',
      'fpt shop',
      'thế giới di động',
      'thegioididong',
      'cellphones',
      'điện máy xanh',
    ];

    // Kiểm tra các dòng đầu tiên xem có thương hiệu đã biết không
    for (int i = 0; i < lines.length && i < 8; i++) {
      final lineLower = lines[i].toLowerCase();
      for (final brand in knownBrands) {
        if (lineLower.contains(brand)) {
          return lines[i];
        }
      }
    }

    // Các từ ngữ loại trừ (tiêu đề chứng từ, mã số thuế, v.v.)
    final excludeWords = [
      'hóa đơn',
      'hoa don',
      'phiếu tính tiền',
      'phieu tinh tien',
      'phiếu thanh toán',
      'receipt',
      'invoice',
      'bill',
      'mst',
      'mã số thuế',
      'địa chỉ',
      'dia chi',
      'tel',
      'phone',
      'hotline',
      'ngày',
      'date',
      'thu ngân',
      'cashier',
      'bàn',
      'khách hàng',
      'customer',
    ];

    // Duyệt qua 4 dòng đầu tiên để lấy dòng thương hiệu hợp lý nhất
    for (int i = 0; i < lines.length && i < 4; i++) {
      final line = lines[i].trim();
      final lineLower = line.toLowerCase();

      if (line.length < 3 || line.length > 50) continue;
      if (excludeWords.any((e) => lineLower.contains(e))) continue;
      // Tránh dòng toàn số hoặc ký tự đặc biệt
      if (RegExp(r'^\d+$').hasMatch(line)) continue;

      // Ưu tiên dòng có từ khóa cửa hàng / quán / shop
      if (lineLower.contains('quán') ||
          lineLower.contains('cửa hàng') ||
          lineLower.contains('tiệm') ||
          lineLower.contains('shop') ||
          lineLower.contains('store') ||
          lineLower.contains('mart') ||
          lineLower.contains('cafe') ||
          lineLower.contains('coffee') ||
          lineLower.contains('nhà hàng') ||
          lineLower.contains('restaurant')) {
        return line;
      }

      // Trả về dòng đầu tiên hợp lệ nếu chữ hoa hoặc tên riêng
      if (i <= 1) {
        return line;
      }
    }

    return lines.isNotEmpty ? lines.first : null;
  }

  /// ================== 4. PHÂN LOẠI DANH MỤC (CATEGORY CLASSIFICATION) ==================
  /// Phân loại chính xác vào 5 nhóm chuẩn Mini-Project 3:
  /// - Food (1)
  /// - Study (10)
  /// - Travel (11)
  /// - Gear (20)
  /// - Entertainment (5)
  String _guessCategoryId(String fullText, String? merchant) {
    final combined = '${merchant ?? ""} $fullText'.toLowerCase();

    // 1. Food: Ăn uống
    final foodKeywords = [
      'cơm', 'phở', 'bún', 'mì', 'mi', 'bánh', 'trà', 'cafe', 'cà phê', 'coffee',
      'thịt', 'rau', 'gà', 'bò', 'lẩu', 'nướng', 'snack', 'buffet', 'bánh mì',
      'nước', 'food', 'pizza', 'burger', 'kfc', 'lotteria', 'jollibee', 'quán ăn',
      'nhà hàng', 'highlands', 'phúc long', 'starbucks', 'co.opmart', 'winmart',
      'bách hóa xanh', 'chợ', 'trứng', 'sữa', 'bia', 'uống', 'ăn'
    ];
    if (foodKeywords.any((k) => combined.contains(k))) return '1'; // Food

    // 2. Study: Học tập
    final studyKeywords = [
      'sách', 'vở', 'bút', 'photo', 'in ấn', 'giáo trình', 'học phí', 'khóa học',
      'fahasa', 'nhà sách', 'thước', 'tập', 'bài giảng', 'course', 'study',
      'book', 'tài liệu', 'trường', 'đại học', 'tiếng anh'
    ];
    if (studyKeywords.any((k) => combined.contains(k))) return '10'; // Study

    // 3. Travel: Di chuyển / Du lịch
    final travelKeywords = [
      'xăng', 'petrolimex', 'pvoil', 'grab', 'be', 'gojek', 'taxi', 'mai linh',
      'vé xe', 'gửi xe', 'vé máy bay', 'vietjet', 'vietnam airlines', 'bamboo',
      'bus', 'xe buýt', 'khách sạn', 'hotel', 'homestay', 'resort', 'vé tàu',
      'tour', 'du lịch', 'travel'
    ];
    if (travelKeywords.any((k) => combined.contains(k))) return '11'; // Travel

    // 4. Gear: Thiết bị / Đồ dùng
    final gearKeywords = [
      'điện thoại', 'máy tính', 'laptop', 'chuột', 'bàn phím', 'cáp', 'sạc',
      'tai nghe', 'pin', 'ốp lưng', 'thế giới di động', 'fpt shop', 'cellphones',
      'gear', 'phụ kiện', 'màn hình', 'usb', 'ram', 'ssd', 'đồ dùng'
    ];
    if (gearKeywords.any((k) => combined.contains(k))) return '20'; // Gear

    // 5. Entertainment: Giải trí
    final entertainmentKeywords = [
      'cgv', 'lotte cinema', 'bhd', 'galaxy cinema', 'vé xem phim', 'rạp',
      'game', 'bi-a', 'bida', 'karaoke', 'net', 'playstation', 'cinema',
      'bowling', 'giải trí', 'vé ca nhạc', 'concert'
    ];
    if (entertainmentKeywords.any((k) => combined.contains(k))) return '5'; // Entertainment

    return '1'; // Mặc định là Food (Ăn uống)
  }
}
