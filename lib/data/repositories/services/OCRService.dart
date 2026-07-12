import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as pkg_img; // Dùng pkg_img cho rõ ràng
import 'dart:typed_data';
class ReceiptAIService {
  final String _apiKey = "K88606641388957";
  final String _apiUrl = "https://api.ocr.space/parse/image";

  Future<Map<String, dynamic>?> scanReceipt(File imageFile) async {
    try {
      // 1. Đọc bytes từ file
      final List<int> imageBytes = await imageFile.readAsBytes();

      // 2. Decode ảnh - Sử dụng pkg_img.decodeImage để tránh Lookup failed
      final pkg_img.Image? decodedImage = pkg_img.decodeImage(Uint8List.fromList(imageBytes));

      if (decodedImage == null) {
        print("Không thể giải mã hình ảnh");
        return null;
      }

      // 3. Nén và Resize ảnh cực nhỏ để tiết kiệm RAM
      final pkg_img.Image resized = pkg_img.copyResize(decodedImage, width: 600);
      final List<int> compressedBytes = pkg_img.encodeJpg(resized, quality: 70);

      // Chuyển sang Base64
      final String base64Image = "data:image/jpg;base64,${base64Encode(compressedBytes)}";

      // 4. Gửi request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "apikey": _apiKey,
          "base64image": base64Image,
          "language": "eng",
          "OCREngine": "2",
          "scale": "true",
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['ParsedResults'] != null && data['ParsedResults'].isNotEmpty) {
          return _processOCRSpaceResponse(data);
        }
      }
      return null;
    } catch (e) {
      print("Lỗi tại ReceiptAIService: $e");
      return null;
    }
  }

  Map<String, dynamic> _processOCRSpaceResponse(Map<String, dynamic> data) {
    String fullText = data['ParsedResults'][0]['ParsedText'] ?? "";
    print("--- DATA FROM OCR ---\n$fullText");

    double total = _extractTotalAmount(fullText);

    return {
      "total": total.toInt(),
      "categoryId": _guessCategoryId(fullText),
      "date": DateTime.now().toString(),
    };
  }

  double _extractTotalAmount(String text) {
    // 1. Chuẩn hóa khoảng trắng cho số tiền (VD: 947 000 -> 947000)
    String normalizedText = text.replaceAllMapped(RegExp(r'(\d)\s+(\d{3})'), (match) {
      return '${match.group(1)}${match.group(2)}';
    });

    String lowerText = normalizedText.toLowerCase();
    List<String> keywords = ['thanh toán', 'tổng tiền', 'tổng cộng', 'thành tiền', 'tong tien'];

    for (var kw in keywords) {
      if (lowerText.contains(kw)) {
        int index = lowerText.indexOf(kw);
        // Lấy đoạn văn bản sau từ khóa
        String subText = lowerText.substring(index + kw.length);
        if (subText.length > 150) subText = subText.substring(0, 150);

        RegExp regExp = RegExp(r'(\d{1,3}([\.,]\d{3})+)|(\d{4,})');
        Iterable<RegExpMatch> matches = regExp.allMatches(subText);

        if (matches.isNotEmpty) {
          // Thay vì lấy matches.last, ta tìm số LỚN NHẤT trong các số sau chữ "Thanh toán"
          double maxInSub = 0;
          for (var m in matches) {
            String cleanStr = m.group(0)!.replaceAll(RegExp(r'[\.,]'), '');
            double? val = double.tryParse(cleanStr);
            if (val != null && val > maxInSub && val < 5000000) {
              maxInSub = val;
            }
          }
          if (maxInSub > 1000) return maxInSub;
        }
      }
    }

    // 2. Backup: Nếu không thấy từ khóa, tìm số lớn nhất toàn bài (loại bỏ SĐT/Mã NV)
    RegExp regExp = RegExp(r'(\d{1,3}([\.,]\d{3})+)|(\d{4,})');
    double maxAmount = 0;
    for (var match in regExp.allMatches(normalizedText)) {
      String cleanStr = match.group(0)!.replaceAll(RegExp(r'[\.,]'), '');
      double? val = double.tryParse(cleanStr);

      // Loại bỏ SĐT đầu 09 hoặc 01
      String rawMatch = match.group(0)!;
      if (val != null && val > maxAmount && val < 5000000) {
        if (!rawMatch.startsWith('09') && !rawMatch.startsWith('01')) {
          maxAmount = val;
        }
      }
    }

    return maxAmount;
  }

  String _guessCategoryId(String text) {
    String lower = text.toLowerCase();

    // 1. Nhóm Ăn uống (ID: 1)
    if (lower.contains('cơm') || lower.contains('nước') || lower.contains('food') ||
        lower.contains('cafe') || lower.contains('nướng') || lower.contains('lẩu')) {
      return '1';
    }

    // 2. Nhóm Shopping / Siêu thị (ID: 2 hoặc 9)
    if (lower.contains('mart') || lower.contains('siêu thị') || lower.contains('vinmart') || lower.contains('co.op')) {
      return '2';
    }

    // 3. Nhóm Di chuyển (ID: 3)
    if (lower.contains('xăng') || lower.contains('grab') || lower.contains('be ') || lower.contains('vận tải')) {
      return '3';
    }
    // 5. Nhóm Giải Trí (ID: 5)
    if (lower.contains('bia') || lower.contains('giờ') || lower.contains('garden') || lower.contains('tiger') || lower.contains('snack')) {
      return '5';
    }
    // 4. Nhóm Điện tử (ID: 20)
    if (lower.contains('điện thoại') || lower.contains('thẻ cào') || lower.contains('phụ kiện') || lower.contains('📱')) {
      return '20';
    }

    // 5. Nhóm Hóa đơn (ID: 9)
    if (lower.contains('điện') || lower.contains('nước') || lower.contains('internet') || lower.contains('viettel')) {
      return '9';
    }

    // Mặc định trả về ID '1' (Ăn uống) hoặc một ID chung nào đó nếu không khớp
    return '1';
  }

}