import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../data/model/TransactionModel.dart';
import '../../../../../data/repositories/local/DatabaseHelper.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc() : super(TransactionInitial()) {
    on<LoadRecentTransactions>(_onLoad);
    on<AddTransaction>(_onAdd);
    on<DeleteTransaction>(_onDelete);
    on<RefreshTransactions>(_onRefresh);
  }

  // ── Load Offline First (SQLite) & Đồng bộ Firestore ───────────────
  Future<void> _onLoad(
      LoadRecentTransactions event,
      Emitter<TransactionState> emit,
      ) async {
    emit(TransactionLoading());

    // 1. Tải tức thì từ SQLite (Offline database)
    List<TransactionModel> localList = [];
    try {
      localList = await DatabaseHelper.instance.getTransactions(userId: event.userId);
      if (localList.isNotEmpty) {
        emit(TransactionLoaded(
          transactions: localList,
          recent: localList.take(5).toList(),
        ));
      }
    } catch (_) {}

    // 2. Đồng bộ Firestore nếu có mạng
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Transactions')
          .where('userId', isEqualTo: event.userId)
          .get();

      final allMap = <String, TransactionModel>{
        for (final t in localList) t.id: t,
      };

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final tx = TransactionModel.fromJson({
            ...data,
            'id': data['id'] ?? doc.id,
          });
          allMap[tx.id] = tx;
          // Lưu cache vào SQLite
          await DatabaseHelper.instance.insertTransaction(tx);
        } catch (_) {}
      }

      final combined = allMap.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      emit(TransactionLoaded(
        transactions: combined,
        recent: combined.take(5).toList(),
      ));
    } catch (e) {
      if (localList.isNotEmpty) {
        // Đã emit localList ở trên
      } else {
        emit(TransactionLoaded(transactions: const [], recent: const []));
      }
    }
  }

  // ── Thêm mới (optimistic update — không cần gọi lại Firestore) ──
  Future<void> _onAdd(
      AddTransaction event,
      Emitter<TransactionState> emit,
      ) async {
    if (state is! TransactionLoaded) return;
    final current = state as TransactionLoaded;

    // Thêm vào đầu danh sách (mới nhất)
    final updated = [event.transaction, ...current.transactions];
    final sorted  = [...updated]..sort((a, b) => b.date.compareTo(a.date));

    emit(TransactionLoaded(
      transactions: updated,
      recent: sorted.take(5).toList(),
    ));
  }

  // ── Xoá (optimistic update) ─────────────────────────────────────
  Future<void> _onDelete(
      DeleteTransaction event,
      Emitter<TransactionState> emit,
      ) async {
    if (state is! TransactionLoaded) return;
    final current = state as TransactionLoaded;

    final updated = current.transactions
        .where((t) => t.id != event.transactionId)
        .toList();
    final sorted = [...updated]..sort((a, b) => b.date.compareTo(a.date));

    emit(TransactionLoaded(
      transactions: updated,
      recent: sorted.take(5).toList(),
    ));

    // Xoá khỏi SQLite và Firestore ở nền
    try {
      await DatabaseHelper.instance.deleteTransaction(event.transactionId);
      await FirebaseFirestore.instance
          .collection('Transactions')
          .doc(event.transactionId)
          .delete();
    } catch (_) {
      // rollback nếu cần
    }
  }

  // ── Refresh (reload lại từ Firestore) ───────────────────────────
  // ── Refresh (reload lại từ Firestore, KHÔNG emit Loading) ──────
  Future<void> _onRefresh(
      RefreshTransactions event,
      Emitter<TransactionState> emit,
      ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Transactions')
          .where('userId', isEqualTo: event.userId)
          .get();

      final all = <TransactionModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          all.add(TransactionModel.fromJson({
            ...data,
            'id': data['id'] ?? doc.id,
          }));
        } catch (_) {}
      }

      all.sort((a, b) => b.date.compareTo(a.date));

      emit(TransactionLoaded(
        transactions: all,
        recent: all.take(5).toList(),
      ));
    } catch (_) {
      // Giữ state cũ nếu lỗi, không emit gì cả
    }
  }
}