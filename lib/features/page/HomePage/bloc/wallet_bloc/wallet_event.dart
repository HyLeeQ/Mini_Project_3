import 'package:equatable/equatable.dart';

import '../../../../../data/model/WalletModel.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

// Load danh sách ví từ Firestore
class LoadWallets extends WalletEvent {
  final String userId;
  const LoadWallets(this.userId);
  @override
  List<Object?> get props => [userId];
}

// Thêm ví mới
class AddWallet extends WalletEvent {
  final WalletModel wallet;
  const AddWallet(this.wallet);
  @override
  List<Object?> get props => [wallet];
}

// Xóa ví
class DeleteWallet extends WalletEvent {
  final String walletId;
  const DeleteWallet(this.walletId);
  @override
  List<Object?> get props => [walletId];
}
class RefreshWallets extends WalletEvent {
  final String userId;
  const RefreshWallets(this.userId);

  @override
  List<Object> get props => [userId];
}