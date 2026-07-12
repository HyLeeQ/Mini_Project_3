import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../model/TransactionModel.dart';
import '../model/WalletModel.dart';

class WalletStorage{
  Future<WalletModel?> addWallet(String userId, String name, String icon, String colorHex, double balance,WalletType type,String? cardNumber) async{
    try{
      final docRef = FirebaseFirestore.instance.collection('Wallets').doc();
      final wallet = WalletModel(id: docRef.id, userId: userId, name: name, icon: icon, colorHex: colorHex, balance: balance, type: type,cardNumber: cardNumber);
      await docRef.set(wallet.toJson());
      return wallet;
    }catch(e){
      print(e.toString());
      return null;
    }
  }
  Future<List<WalletModel>> getWallets(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Wallets')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => WalletModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }


}