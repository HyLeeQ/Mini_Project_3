import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/model/CategoryModel.dart';
import '../../../../data/model/TransactionModel.dart';
import '../../add_transaction/models/sample_data.dart';
import '../bloc/transaction_bloc/transaction_bloc.dart';
import '../bloc/transaction_bloc/transaction_event.dart';
import '../bloc/transaction_bloc/transaction_state.dart';

class AllTransactionsScreen extends StatelessWidget {
  final String userId;
  final List<CategoryModel> categories;

  const AllTransactionsScreen({
    super.key,
    required this.userId,
    this.categories = const [],
  });

  static const _bg = Color(0xFF0A0A0F);
  static const _card = Color(0xFF1C1C26);
  static const _textPrimary = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border = Color(0xFF2A2A38);
  static const _gold = Color(0xFFD4A843);

  List<CategoryModel> get _allCategories =>
      categories.isNotEmpty ? categories : SampleData.categories;

  CategoryModel? _categoryById(String id) {
    try {
      return _allCategories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Color _parseColor(String hex, {Color fallback = _textSecondary}) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _fmt(double amount) {
    final str = amount
        .abs()
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '$str ₫';
  }

  String _fmtDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays == 1) return 'Hôm qua';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Tất cả giao dịch',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          if (state is TransactionError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textSecondary, fontSize: 13.sp),
                ),
              ),
            );
          }

          final all = state is TransactionLoaded
              ? [...state.transactions]
              : <TransactionModel>[];
          all.sort((a, b) => b.date.compareTo(a.date));

          if (all.isEmpty) {
            return Center(
              child: Text(
                'Chưa có giao dịch nào',
                style: TextStyle(color: _textSecondary, fontSize: 13.sp),
              ),
            );
          }

          return RefreshIndicator(
            color: _gold,
            onRefresh: () async {
              context.read<TransactionBloc>().add(RefreshTransactions(userId));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              itemCount: all.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final tx = all[index];
                final cat = _categoryById(tx.categoryId);
                final catName = cat?.name ?? 'Khác';
                final catColor = cat != null
                    ? _parseColor(cat.colorHex)
                    : _textSecondary;
                final isExpense = tx.type == TransactionType.expense;
                final isTransfer = tx.type == TransactionType.transfer;
                final amountColor = isTransfer
                    ? _gold
                    : isExpense
                    ? const Color(0xFFE05555)
                    : const Color(0xFF2ECC8A);
                final sign = isTransfer ? '⇄' : (isExpense ? '-' : '+');

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: _border, width: 1.w),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            cat?.icon ?? '💳',
                            style: TextStyle(fontSize: 18.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.note?.isNotEmpty == true ? tx.note! : catName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '$catName  ·  ${_fmtDate(tx.date)}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '$sign ${_fmt(tx.amount)}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
