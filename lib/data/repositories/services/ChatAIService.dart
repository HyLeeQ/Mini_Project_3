import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../model/TransactionModel.dart';

class ChatAIService {
  final String _apiKey = "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";
  final String _url = "https://api.groq.com/openai/v1/chat/completions";

  static const Map<String, String> categoryNames = {
    '1':  '🍔 Ăn uống',
    '2':  '🛍️ Shopping',
    '3':  '🚗 Di chuyển',
    '4':  '💊 Sức khỏe',
    '5':  '🎬 Giải trí',
    '6':  '🏠 Nhà ở',
    '7':  '💰 Lương',
    '8':  '🎁 Thưởng',
    '9':  '📄 Hóa đơn',
    '10': '📚 Giáo dục',
    '11': '✈️ Du lịch',
    '12': '💸 Trả nợ',
    '13': '📈 Đầu tư',
    '14': '🛡️ Bảo hiểm',
    '15': '🐾 Thú cưng',
    '16': '🎀 Quà tặng',
    '17': '❤️ Từ thiện',
    '18': '💄 Làm đẹp',
    '19': '⚽ Thể thao',
    '20': '📱 Điện tử',
  };

  Future<Map<String, dynamic>> getAIResponse(
      String userMessage,
      List<TransactionModel> allTransactions,
      double balance,
      ) async {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;

    final txToday      = _filterTx(allTransactions, _rangeToday(now));
    final txThisWeek   = _filterTx(allTransactions, _rangeThisWeek(now));
    final txThisMonth  = _filterTx(allTransactions, _rangeThisMonth(now));
    final txLastMonth  = _filterTx(allTransactions, _rangeLastMonth(now));
    final txThisYear   = _filterTx(allTransactions, _rangeThisYear(now));

    final statsToday     = _calcStats(txToday);
    final statsAll       = _calcStats(allTransactions);
    final statsThisWeek  = _calcStats(txThisWeek);
    final statsThisMonth = _calcStats(txThisMonth);
    final statsLastMonth = _calcStats(txLastMonth);
    final statsThisYear  = _calcStats(txThisYear);

    final systemData = _buildSystemData(
      now: now,
      daysLeft: daysLeft,
      balance: balance,
      statsToday: statsToday,
      statsAll: statsAll,
      statsThisWeek: statsThisWeek,
      statsThisMonth: statsThisMonth,
      statsLastMonth: statsLastMonth,
      statsThisYear: statsThisYear,
    );

    debugPrint('[AI] Balance: $balance');
    debugPrint('[AI] Today expense: ${statsToday['totalExpense']}');
    debugPrint('[AI] This month expense: ${statsThisMonth['totalExpense']}');

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": _buildSystemPrompt(systemData, daysLeft, allTransactions),
            },
            {"role": "user", "content": userMessage},
          ],
          "response_format": {"type": "json_object"},
        }),
      );

      if (response.statusCode == 200) {
        final groqData = jsonDecode(utf8.decode(response.bodyBytes));
        final aiContent = groqData['choices'][0]['message']['content'] as String;
        return jsonDecode(aiContent) as Map<String, dynamic>;
      }
      return {"reply": "Lỗi rồi, thử lại đi ông nội! 😤", "extracted_data": null};
    } catch (e) {
      return {"reply": "Lỗi hệ thống: $e", "extracted_data": null};
    }
  }

  Map<String, DateTime> _rangeToday(DateTime now) {
    return {
      'from': DateTime(now.year, now.month, now.day, 0, 0, 0),
      'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
    };
  }

  String _buildSystemData({
    required DateTime now,
    required int daysLeft,
    required double balance,
    required Map<String, dynamic> statsToday,
    required Map<String, dynamic> statsAll,
    required Map<String, dynamic> statsThisWeek,
    required Map<String, dynamic> statsThisMonth,
    required Map<String, dynamic> statsLastMonth,
    required Map<String, dynamic> statsThisYear,
  }) {
    final lastMonth = DateTime(now.year, now.month - 1);

    return """
[DỮ LIỆU HỆ THỐNG CHÍNH XÁC - CẤM AI TỰ TÍNH LẠI]
Hôm nay: ${now.day}/${now.month}/${now.year}
Số ngày còn lại trong tháng: $daysLeft ngày
Số dư hiện tại: ${_fmt(balance)} VNĐ

━━━━━ HÔM NAY (${now.day}/${now.month}/${now.year}) ━━━━━
Tổng thu hôm nay: ${_fmt(statsToday['totalIncome'])} VNĐ
Tổng chi hôm nay: ${_fmt(statsToday['totalExpense'])} VNĐ
Chi tiết theo danh mục:
${_fmtCategoryBlock(statsToday['byCategory'] as Map<String, double>, statsToday['totalExpense'] as double)}

━━━━━ TUẦN NÀY ━━━━━
Tổng thu: ${_fmt(statsThisWeek['totalIncome'])} VNĐ
Tổng chi: ${_fmt(statsThisWeek['totalExpense'])} VNĐ
Chi tiết theo danh mục:
${_fmtCategoryBlock(statsThisWeek['byCategory'] as Map<String, double>, statsThisWeek['totalExpense'] as double)}

━━━━━ THÁNG ${now.month}/${now.year} (THÁNG NÀY) ━━━━━
Tổng thu: ${_fmt(statsThisMonth['totalIncome'])} VNĐ
Tổng chi: ${_fmt(statsThisMonth['totalExpense'])} VNĐ
Chi tiết theo danh mục:
${_fmtCategoryBlock(statsThisMonth['byCategory'] as Map<String, double>, statsThisMonth['totalExpense'] as double)}

━━━━━ THÁNG ${lastMonth.month}/${lastMonth.year} (THÁNG TRƯỚC) ━━━━━
Tổng thu: ${_fmt(statsLastMonth['totalIncome'])} VNĐ
Tổng chi: ${_fmt(statsLastMonth['totalExpense'])} VNĐ
Chi tiết theo danh mục:
${_fmtCategoryBlock(statsLastMonth['byCategory'] as Map<String, double>, statsLastMonth['totalExpense'] as double)}

━━━━━ NĂM ${now.year} ━━━━━
Tổng thu: ${_fmt(statsThisYear['totalIncome'])} VNĐ
Tổng chi: ${_fmt(statsThisYear['totalExpense'])} VNĐ
Chi tiết theo danh mục:
${_fmtCategoryBlock(statsThisYear['byCategory'] as Map<String, double>, statsThisYear['totalExpense'] as double)}

━━━━━ TOÀN BỘ LỊCH SỬ ━━━━━
Tổng thu: ${_fmt(statsAll['totalIncome'])} VNĐ
Tổng chi: ${_fmt(statsAll['totalExpense'])} VNĐ
""";
  }

  String _buildSystemPrompt(
      String systemData,
      int daysLeft,
      List<TransactionModel> allTransactions,
      ) {
    return """Bạn là trợ lý tài chính DoctorDong: cục súc, thẳng tính, hay cà khịa nhưng phân tích số liệu CỰC CHÍNH XÁC.

$systemData

DỮ LIỆU GIAO DỊCH GẦN ĐÂY (CHỈ ĐỂ TRA CỨU TÊN/GHI CHÚ):
${_recentTxJson(allTransactions)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NHIỆM VỤ:

【TRƯỜNG HỢP 1 - THỐNG KÊ/HỎI HAN】
Nếu người dùng hỏi tình hình tài chính (hôm nay, tuần này, tháng này, tháng trước, năm nay,...):
- PHẢI dùng đúng block dữ liệu tương ứng ở trên. KHÔNG tự cộng trừ.
- Liệt kê CHI TIẾT từng danh mục: tên danh mục → số tiền → % tổng chi.
- Tìm danh mục chi NHIỀU NHẤT và mỉa mai cực mạnh nếu > 30% tổng chi.
- Nếu chi > thu: báo động đỏ 🚨.
- Tất cả số tiền PHẢI có dấu chấm ngăn cách (VD: 1.500.000 VNĐ).
- Nếu hỏi "hôm nay": dùng block HÔM NAY. Nếu không có giao dịch thì nói "Hôm nay ông chưa tiêu gì, hoặc chưa ghi lại 🤔".
- Trả về JSON: {"reply": "Phân tích chi tiết kèm mỉa mai 😤", "extracted_data": null}

【TRƯỜNG HỢP 2 - NHẬP GIAO DỊCH】
Nếu người dùng nói chi tiêu (VD: "Ăn trưa 30k", "Đổ xăng 100k"):
- Nhận diện category ID phù hợp từ danh sách: 1=Ăn uống, 2=Shopping, 3=Di chuyển, 4=Sức khỏe, 5=Giải trí, 6=Nhà ở, 9=Hóa đơn, 10=Giáo dục, 11=Du lịch, 12=Trả nợ, 13=Đầu tư, 14=Bảo hiểm, 15=Thú cưng, 16=Quà tặng, 17=Từ thiện, 18=Làm đẹp, 19=Thể thao, 20=Điện tử, 7=Lương (thu), 8=Thưởng (thu).
- Trả về JSON: {
    "reply": "Câu cà khịa phù hợp với giao dịch đó ☕",
    "extracted_data": {
      "amount": <số tiền dạng số>,
      "note": "<nội dung người dùng nhập nguyên văn>",
      "category": "<ID danh mục>",
      "type": "<expense hoặc income>",
      "is_complete": true
    }
  }

【TRƯỜNG HỢP 3 - LẬP KẾ HOẠCH】
Nếu người dùng nhờ chia tiền cho $daysLeft ngày còn lại:
- Lấy số dư hiện tại ÷ $daysLeft để tính ngân sách mỗi ngày.
- Lên lịch chi tiêu hợp lý theo ngày, có cảnh báo nếu ngân sách eo hẹp.
- Trả về JSON: {"reply": "Kế hoạch chi tiết theo ngày + lời cảnh báo 📅", "extracted_data": null}

【TRƯỜNG HỢP 4 - CÂU HỎI NGOÀI LỀ】
Nếu người dùng hỏi những thứ không liên quan đến tài chính (thời tiết, tình yêu, nấu ăn, tin tức, vui vẻ,...):
- KHÔNG từ chối cứng nhắc. Trả lời ngắn gọn, tự nhiên theo phong cách DoctorDong.
- Sau đó nhẹ nhàng kéo cuộc trò chuyện trở lại chủ đề tài chính bằng 1 câu liên kết hài hước.
- Ví dụ: hỏi thời tiết → "Trời nắng hay mưa tôi không biết, nhưng tôi biết ví ông đang bão tuyết 🌨️. Hôm nay ông tiêu bao nhiêu rồi?"
- Trả về JSON: {"reply": "Câu trả lời ngoài lề + câu kéo về tài chính 😄", "extracted_data": null}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
QUY TẮC BẮT BUỘC:
- Dùng tiếng Việt, xưng Tôi - Ông.
- Dùng nhiều emoji (💸 😤 🍺 📉 💰 🚨 📊).
- KHÔNG thêm trường lạ vào JSON.
- KHÔNG tự suy đoán số liệu ngoài dữ liệu hệ thống đã cho.""";
  }

  // ==================== FILTER BY DATE RANGE ====================
  List<TransactionModel> _filterTx(List<TransactionModel> txs, Map<String, DateTime> range,) {
    return txs.where((tx) {
      return !tx.date.isBefore(range['from']!) &&
          !tx.date.isAfter(range['to']!);
    }).toList();
  }

  Map<String, DateTime> _rangeThisWeek(DateTime now) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final from = DateTime(monday.year, monday.month, monday.day);
    return {'from': from, 'to': now};
  }

  Map<String, DateTime> _rangeThisMonth(DateTime now) {
    return {
      'from': DateTime(now.year, now.month, 1),
      'to': now,
    };
  }

  Map<String, DateTime> _rangeLastMonth(DateTime now) {
    final firstOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final lastOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
    return {'from': firstOfLastMonth, 'to': lastOfLastMonth};
  }

  Map<String, DateTime> _rangeThisYear(DateTime now) {
    return {
      'from': DateTime(now.year, 1, 1),
      'to': now,
    };
  }

  // ==================== CALC STATS ====================
  Map<String, dynamic> _calcStats(List<TransactionModel> txs) {
    double totalIncome = 0;
    double totalExpense = 0;
    final byCategory = <String, double>{};

    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
        byCategory[tx.categoryId] =
            (byCategory[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'byCategory': byCategory,
    };
  }

  // ==================== FORMAT CATEGORY BLOCK ====================
  String _fmtCategoryBlock(
      Map<String, double> byCategory,
      double totalExpense,
      ) {
    if (byCategory.isEmpty) return '  (Không có giao dịch)';

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    for (final entry in sorted) {
      final name =
          categoryNames[entry.key] ?? ' Unknown (ID ${entry.key})';
      final pct = totalExpense > 0
          ? (entry.value / totalExpense * 100).toStringAsFixed(1)
          : '0.0';
      buffer.writeln('  $name: ${_fmt(entry.value)} VNĐ ($pct%)');
    }
    return buffer.toString().trimRight();
  }

  // ==================== RECENT TRANSACTIONS JSON ====================
  String _recentTxJson(List<TransactionModel> txs) {
    final recent = txs.take(30).toList();
    final data = recent
        .map((tx) => {
      'd': '${tx.date.day}/${tx.date.month}/${tx.date.year}',
      'a': tx.amount.toInt(),
      'n': tx.note ?? '',
      'c': tx.categoryId,
      't': tx.type.name,
    })
        .toList();
    return jsonEncode(data);
  }

  // ==================== FORMAT MONEY ====================
  String _fmt(dynamic amount) {
    final value =
    (amount is double) ? amount.toInt() : (amount as int);
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
    );
  }

  void debugPrint(String msg) {
    print(msg);
  }
}