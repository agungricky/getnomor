import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  await database.open();
  runApp(WaContactCollectorApp(database: database));
}
