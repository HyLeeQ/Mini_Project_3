import 'package:expense_tracker/features/page/HomePage/bloc/wallet_bloc/wallet_event.dart';
import 'package:expense_tracker/features/page/HomePage/bloc/wallet_bloc/wallet_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../data/firebase/WalletStorage.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletStorage _walletStorage;

  WalletBloc({WalletStorage? walletStorage})
      : _walletStorage = walletStorage ?? WalletStorage(),
        super(WalletInitial()) {
    on<LoadWallets>(_onLoadWallets);
    on<RefreshWallets>(_onRefreshWallets);
    on<AddWallet>(_onAddWallet);
    on<DeleteWallet>(_onDeleteWallet);
  }

  Future<void> _onLoadWallets(
      LoadWallets event,
      Emitter<WalletState> emit,
      ) async {
    emit(WalletLoading());
    try {
      final wallets = await _walletStorage.getWallets(event.userId);
      emit(WalletLoaded(wallets));
    } catch (e) {
      emit(WalletError('Không thể tải ví: $e'));
    }
  }

  Future<void> _onRefreshWallets(
      RefreshWallets event,
      Emitter<WalletState> emit,
      ) async {
    try {
      final wallets = await _walletStorage.getWallets(event.userId);
      emit(WalletLoaded(wallets));
    } catch (_) {
    }
  }

  // Thêm ví mới vào list hiện tại
  Future<void> _onAddWallet(
      AddWallet event,
      Emitter<WalletState> emit,
      ) async {
    if (state is WalletLoaded) {
      final current = (state as WalletLoaded).wallets;
      emit(WalletLoaded([...current, event.wallet]));
    }
  }

  // Xóa ví khỏi list
  Future<void> _onDeleteWallet(
      DeleteWallet event,
      Emitter<WalletState> emit,
      ) async {
    if (state is WalletLoaded) {
      final current = (state as WalletLoaded).wallets;
      emit(WalletLoaded(
        current.where((w) => w.id != event.walletId).toList(),
      ));
    }
  }
}