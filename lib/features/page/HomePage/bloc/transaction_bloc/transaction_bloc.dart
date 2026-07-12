import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../data/model/TransactionModel.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc() : super(TransactionInitial()) {
    on<LoadRecentTransactions>(_onLoad);
    on<AddTransaction>(_onAdd);
    on<DeleteTransaction>(_onDelete);
    on<RefreshTransactions>(_onRefresh);
  }

  // ── Load từ Firestore ───────────────────────────────────────────
  Future<void> _onLoad(
      LoadRecentTransactions event,
      Emitter<TransactionState> emit,
      ) async {
    emit(TransactionLoading());
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Transactions')
          .where('userId', isEqualTo: event.userId)
          .get();

      final all = <TransactionModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          all.add(
            TransactionModel.fromJson({
              ...data,
              // Ưu tiên id từ document nếu field id bị thiếu/sai.
              'id': data['id'] ?? doc.id,
            }),
          );
        } catch (_) {
          // Bỏ qua record lỗi để không làm hỏng toàn bộ danh sách.
        }
      }

      all.sort((a, b) => b.date.compareTo(a.date));

      emit(TransactionLoaded(
        transactions: all,
        recent: all.take(5).toList(),
      ));
    } catch (e) {
      emit(TransactionError('Không thể tải giao dịch: $e'));
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

    // Xoá khỏi Firestore ở nền
    try {
      await FirebaseFirestore.instance
          .collection('Transactions')
          .doc(event.transactionId)
          .delete();
    } catch (_) {
      // TODO: rollback nếu cần
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