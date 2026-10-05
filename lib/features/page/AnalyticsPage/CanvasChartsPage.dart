import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/model/CategoryModel.dart';
import '../../../data/model/TransactionModel.dart';

class CanvasChartsPage extends StatefulWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  const CanvasChartsPage({
    super.key,
    required this.transactions,
    required this.categories,
  });

  @override
  State<CanvasChartsPage> createState() => _CanvasChartsPageState();
}

class _CanvasChartsPageState extends State<CanvasChartsPage>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0A0A0F);
  static const _card = Color(0xFF1C1C26);
  static const _gold = Color(0xFFD4A843);
  static const _muted = Color(0xFF7A7A8C);
  static const _grid = Color(0xFF2A2A38);

  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  int _selectedDay = DateTime.now().weekday - 1;

  List<_Slice> get _slices {
    final totals = <String, double>{};
    for (final tx in widget.transactions.where(
      (t) =>
          t.type == TransactionType.expense &&
          t.date.month == DateTime.now().month &&
          t.date.year == DateTime.now().year,
    )) {
      totals.update(
        tx.categoryId,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((entry) {
      final category = widget.categories.cast<CategoryModel?>().firstWhere(
        (item) => item?.id == entry.key,
        orElse: () => null,
      );
      return _Slice(
        name: category?.name ?? 'Khác',
        amount: entry.value,
        color: _parseColor(category?.colorHex),
      );
    }).toList();
  }

  List<double> get _weekSpending {
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    return List.generate(7, (index) {
      final start = monday.add(Duration(days: index));
      final end = start.add(const Duration(days: 1));
      return widget.transactions
          .where(
            (tx) =>
                tx.type == TransactionType.expense &&
                !tx.date.isBefore(start) &&
                tx.date.isBefore(end),
          )
          .fold<double>(0, (sum, tx) => sum + tx.amount);
    });
  }

  Color _parseColor(String? value) {
    try {
      return Color(int.parse('FF${value!.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _gold;
    }
  }

  String _money(double value) =>
      '${value.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')} ₫';

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slices = _slices;
    final bars = _weekSpending;
    final total = slices.fold<double>(0, (sum, item) => sum + item.amount);
    final maxBar = bars.fold<double>(
      0,
      (largest, value) => math.max(largest, value),
    );
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Biểu đồ thống kê'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 28.h),
        children: [
          Text(
            'Phân bố chi tiêu tháng này',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          _cardWrap(
            child: Column(
              children: [
                SizedBox(
                  height: 220.h,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (_, __) => CustomPaint(
                      painter: _DonutCanvasPainter(
                        slices: slices,
                        progress: _animation.value,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TỔNG CHI',
                              style: TextStyle(color: _muted, fontSize: 11.sp),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _money(total),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (slices.isEmpty)
                  Text(
                    'Chưa có khoản chi trong tháng này',
                    style: TextStyle(color: _muted, fontSize: 12.sp),
                  )
                else
                  Wrap(
                    spacing: 14.w,
                    runSpacing: 10.h,
                    children: slices
                        .take(6)
                        .map(
                          (slice) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 9.w,
                                height: 9.w,
                                decoration: BoxDecoration(
                                  color: slice.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                slice.name,
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Chi tiêu theo ngày trong tuần',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          _cardWrap(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days[_selectedDay],
                  style: TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _money(bars[_selectedDay]),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 210.h,
                  width: double.infinity,
                  child: GestureDetector(
                    onTapDown: (details) {
                      final slotWidth = details.localPosition.dx / 7;
                      setState(
                        () => _selectedDay = slotWidth
                            .floor()
                            .clamp(0, 6)
                            .toInt(),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (_, __) => CustomPaint(
                        painter: _WeeklyCanvasPainter(
                          values: bars,
                          labels: days,
                          maxValue: maxBar,
                          selected: _selectedDay,
                          progress: _animation.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Biểu đồ được vẽ trực tiếp bằng CustomPainter trên canvas.',
            style: TextStyle(color: _muted, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _cardWrap({required Widget child}) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: _grid),
    ),
    child: child,
  );
}

class _Slice {
  final String name;
  final double amount;
  final Color color;
  const _Slice({required this.name, required this.amount, required this.color});
}

class _DonutCanvasPainter extends CustomPainter {
  final List<_Slice> slices;
  final double progress;
  const _DonutCanvasPainter({required this.slices, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.amount);
    if (total <= 0) return;
    const stroke = 20.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF30303B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    var angle = -math.pi / 2;
    for (final slice in slices) {
      final sweep = slice.amount / total * math.pi * 2 * progress;
      canvas.drawArc(
        rect,
        angle,
        sweep,
        false,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutCanvasPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.slices != slices;
}

class _WeeklyCanvasPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxValue;
  final int selected;
  final double progress;
  const _WeeklyCanvasPainter({
    required this.values,
    required this.labels,
    required this.maxValue,
    required this.selected,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0, top = 8.0, bottom = 27.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - left * 2;
    final gridPaint = Paint()
      ..color = const Color(0xFF2A2A38)
      ..strokeWidth = 1;
    for (var line = 0; line < 4; line++) {
      final y = top + chartHeight * line / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width - left, y), gridPaint);
    }
    final slot = chartWidth / values.length;
    for (var i = 0; i < values.length; i++) {
      final barHeight = maxValue == 0
          ? 0.0
          : chartHeight * values[i] / maxValue * progress;
      final rect = Rect.fromLTWH(
        left + slot * i + slot * .27,
        top + chartHeight - barHeight,
        slot * .46,
        barHeight,
      );
      final paint = Paint()
        ..color = i == selected
            ? const Color(0xFFF5D07A)
            : const Color(0xFFD4A843).withOpacity(.65);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        paint,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: i == selected
                ? const Color(0xFFF5D07A)
                : const Color(0xFF7A7A8C),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(left + slot * i + (slot - tp.width) / 2, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyCanvasPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.progress != progress ||
      oldDelegate.values != values;
}
