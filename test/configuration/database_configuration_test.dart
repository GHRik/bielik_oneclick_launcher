import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi;

import 'package:bielik_oneclick_launcher/configuration/database_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';

class _RetryFactory extends Fake implements DatabaseFactory {
  bool _firstOpen = true;

  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    if (_firstOpen) {
      _firstOpen = false;
      throw StateError('Temporary database opening failure');
    }
    return databaseFactoryFfi.openDatabase(path, options: options);
  }
}

void main() {
  group('SQLite platform selection', () {
    test('Windows uses the FFI factory', () async {
      final database = await createAppDatabase(
        platform: TargetPlatform.windows,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);

      expect(database.factory, same(databaseFactoryFfi));
    });

    test('Linux uses the FFI factory', () async {
      final database = await createAppDatabase(
        platform: TargetPlatform.linux,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);

      expect(database.factory, same(databaseFactoryFfi));
    });

    test('Fuchsia reports unsupported database access', () async {
      expect(
        createAppDatabase(platform: TargetPlatform.fuchsia),
        throwsUnsupportedError,
      );
    });
  });

  group('Local database lifecycle', () {
    late AppDatabase database;
    late String databasePath;

    setUp(() async {
      final directory = await Directory.systemTemp.createTemp('database-test');
      addTearDown(() => directory.delete(recursive: true));
      databasePath = path.join(directory.path, 'app.db');
      database = await createAppDatabase(
        platform: TargetPlatform.windows,
        databasePath: databasePath,
      );
      addTearDown(database.close);
    });

    test('Creates the database file at the configured path', () async {
      await database.open();

      expect(await File(databasePath).exists(), isTrue);
    });

    test('Concurrent opens share one connection', () async {
      final connections = await Future.wait([database.open(), database.open()]);

      expect(connections.first, same(connections.last));
    });

    test('A new database uses schema version 2', () async {
      final connection = await database.open();

      expect(await connection.getVersion(), 2);
    });

    test('Preserves a conversation after reopening', () async {
      final connection = await database.open();
      await connection.insert('conversations', {
        'title': 'Zachowaj',
        'created_at': 1,
        'updated_at': 1,
      });
      await database.close();

      final reopened = await database.open();
      final conversations = await reopened.query('conversations');

      expect(conversations.single['title'], 'Zachowaj');
    });

    test('Propagates opening failures to the caller', () async {
      final failingDatabase = AppDatabase(
        factory: _RetryFactory(),
        databasePath: databasePath,
      );
      addTearDown(failingDatabase.close);

      expect(failingDatabase.open(), throwsStateError);
    });

    test('Allows retrying after a failed open', () async {
      final retryingDatabase = AppDatabase(
        factory: _RetryFactory(),
        databasePath: databasePath,
      );
      addTearDown(retryingDatabase.close);
      try {
        await retryingDatabase.open();
      } on StateError {
        final reopened = await retryingDatabase.open();

        expect(reopened.isOpen, isTrue);
        return;
      }
      fail('The first open must fail before retrying.');
    });
  });
}
