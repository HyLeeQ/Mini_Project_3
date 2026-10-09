import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../model/TransactionModel.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        walletId TEXT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        merchantName TEXT,
        receiptImagePath TEXT,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  /// ================== CRUD TRANSACTIONS ==================

  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.insert(
      'transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions({String? userId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (userId != null && userId.isNotEmpty) {
      maps = await db.query(
        'transactions',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
    } else {
      maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );
    }

    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<int> updateTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ================== RECEIPT THUMBNAIL CACHING ==================
  /// Caches and compresses a receipt image into application storage directory
  Future<String?> cacheReceiptThumbnail(File originalFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(p.join(appDir.path, 'receipt_thumbnails'));
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final bytes = await originalFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Resize thumbnail to 500px width while keeping ratio
      final thumbnail = img.copyResize(decoded, width: 500);
      final compressedBytes = img.encodeJpg(thumbnail, quality: 75);

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = p.join(cacheDir.path, fileName);

      final savedFile = File(targetPath);
      await savedFile.writeAsBytes(compressedBytes);
      return savedFile.path;
    } catch (e) {
      debugPrint('Lỗi cache receipt thumbnail: $e');
      return null;
    }
  }
}
