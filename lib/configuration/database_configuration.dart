import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';

Future<AppDatabase> createAppDatabase({
  TargetPlatform? platform,
  String? databasePath,
}) async {
  final target = platform ?? defaultTargetPlatform;
  if (kIsWeb || target == TargetPlatform.fuchsia) {
    throw UnsupportedError('Baza danych nie obsługuje tej platformy.');
  }
  final desktop =
      target == TargetPlatform.windows || target == TargetPlatform.linux;
  if (desktop) {
    sqfliteFfiInit();
    if (databasePath == null) {
      final support = await getApplicationSupportDirectory();
      final directory = Directory(path.join(support.path, 'databases'));
      await directory.create(recursive: true);
      databasePath = path.join(directory.path, AppDatabase.fileName);
    }
  }
  return AppDatabase(
    factory: desktop ? databaseFactoryFfi : databaseFactory,
    databasePath: databasePath,
  );
}
