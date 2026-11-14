import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:wa_contact_collector/core/utils/phone_normalizer.dart';
import 'package:wa_contact_collector/data/database/app_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('normalizes supported Indonesian formats', () {
    expect(PhoneNormalizer.normalize('+628123456789'), '628123456789');
    expect(PhoneNormalizer.normalize('628123456789'), '628123456789');
    expect(PhoneNormalizer.normalize('08123456789'), '628123456789');
  });

  test('rejects non Indonesian or malformed numbers', () {
    expect(PhoneNormalizer.normalize('081234'), isNull);
    expect(PhoneNormalizer.normalize('+14155552671'), isNull);
  });

  test('extracts unique numbers from notification title', () {
    expect(
      PhoneNormalizer.extract('Chat dari +628123456789 dan 08123456789'),
      ['628123456789'],
    );
  });

  test('keeps one local row and updates last detection for duplicates', () async {
    final database = AppDatabase(
      databasePath: join(await getDatabasesPath(), 'test_duplicates.db'),
    );
    await database.open();
    await database.clearDetectedNumbers();
    final first = DateTime.utc(2026, 1, 1, 10);
    final second = DateTime.utc(2026, 1, 1, 11);
    await database.upsertDetectedNumber(
      phoneNumber: '628123456789',
      source: 'WhatsApp',
      detectedAt: first,
    );
    await database.upsertDetectedNumber(
      phoneNumber: '628123456789',
      source: 'WhatsApp Business',
      detectedAt: second,
    );
    final rows = await database.getDetectedNumbers();
    expect(rows, hasLength(1));
    expect(rows.single.source, 'WhatsApp Business');
    expect(rows.single.firstDetectedAt, first);
    expect(rows.single.lastDetectedAt, second);
    await database.close();

    final reopened = AppDatabase(
      databasePath: join(await getDatabasesPath(), 'test_duplicates.db'),
    );
    await reopened.open();
    expect(await reopened.getDetectedNumbers(), hasLength(1));
    await reopened.clearDetectedNumbers();
    await reopened.close();
  });
}
