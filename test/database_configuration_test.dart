import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi;

import 'package:bielik_oneclick_launcher/configuration/database_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';

class _RetryFactory extends Fake implements DatabaseFactory {
  int attempts = 0;

  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    if (++attempts == 1) throw StateError('Temporary open failure');
    return databaseFactoryFfi.openDatabase(path, options: options);
  }
}

void main() {
  test(
    'Desktop uses FFI and preserves data when reopening an explicit path',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'database-config',
      );
      addTearDown(() => directory.delete(recursive: true));
      for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
        final database = await createAppDatabase(
          platform: platform,
          databasePath: path.join(directory.path, '${platform.name}.db'),
        );
        addTearDown(database.close);
        expect(database.factory, same(databaseFactoryFfi));
        final connections = await Future.wait([
          database.open(),
          database.open(),
        ]);
        expect(identical(connections.first, connections.last), isTrue);
        expect(await connections.first.getVersion(), 2);
        await connections.first.insert('conversations', {
          'title': 'Zachowaj',
          'created_at': 1,
          'updated_at': 1,
        });
        await database.close();
        expect(
          (await (await database.open()).query('conversations'))
              .single['title'],
          'Zachowaj',
        );
      }
    },
  );

  test('Unsupported platforms fail explicitly', () async {
    await expectLater(
      createAppDatabase(platform: TargetPlatform.fuchsia),
      throwsUnsupportedError,
    );
  });

  test('A failed factory open can be retried', () async {
    final directory = await Directory.systemTemp.createTemp('database-retry');
    addTearDown(() => directory.delete(recursive: true));
    final configured = await createAppDatabase(
      platform: TargetPlatform.windows,
      databasePath: path.join(directory.path, 'app.db'),
    );
    final factory = _RetryFactory();
    final database = AppDatabase(
      factory: factory,
      databasePath: configured.databasePath,
    );
    addTearDown(database.close);
    await expectLater(database.open(), throwsStateError);
    expect(await (await database.open()).getVersion(), 2);
    expect(factory.attempts, 2);
  });
}
