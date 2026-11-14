import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/detected_number.dart';

class AppDatabase {
  AppDatabase({this.databasePath});

  final String? databasePath;
  Database? _database;

  Future<void> open() async {
    _database = await openDatabase(
      databasePath ?? join(await getDatabasesPath(), 'detected_numbers.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE detected_numbers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone_number TEXT NOT NULL UNIQUE,
            source TEXT NOT NULL,
            first_detected_at TEXT NOT NULL,
            last_detected_at TEXT NOT NULL,
            is_saved_contact INTEGER NOT NULL DEFAULT 0,
            contact_name TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_detected_numbers_last_detected '
          'ON detected_numbers(last_detected_at DESC)',
        );
      },
    );
  }

  Database get db => _database!;

  Future<void> upsertDetectedNumber({
    required String phoneNumber,
    required String source,
    DateTime? detectedAt,
  }) async {
    final timestamp = (detectedAt ?? DateTime.now()).toUtc().toIso8601String();
    await db.transaction((transaction) async {
      await transaction.rawInsert(
        'INSERT OR IGNORE INTO detected_numbers '
        '(phone_number, source, first_detected_at, last_detected_at, is_saved_contact) '
        'VALUES (?, ?, ?, ?, 0)',
        [phoneNumber, source, timestamp, timestamp],
      );
      await transaction.update(
        'detected_numbers',
        {'source': source, 'last_detected_at': timestamp},
        where: 'phone_number = ?',
        whereArgs: [phoneNumber],
      );
    });
  }

  Future<List<DetectedNumber>> getDetectedNumbers() async {
    final rows = await db.query('detected_numbers', orderBy: 'last_detected_at DESC');
    return rows.map(DetectedNumber.fromMap).toList();
  }

  Future<void> updateContactStatus({
    required int id,
    required bool isSaved,
    String? contactName,
  }) async {
    await db.update(
      'detected_numbers',
      {'is_saved_contact': isSaved ? 1 : 0, 'contact_name': contactName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDetectedNumber(int id) async {
    await db.delete('detected_numbers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearDetectedNumbers() async {
    await db.delete('detected_numbers');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
