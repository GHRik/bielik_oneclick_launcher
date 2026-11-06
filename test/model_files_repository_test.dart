import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

void main() {
  late Directory directory;
  late HttpServer server;
  late LocalModelFilesRepository repository;
  late List<int> bytes;
  late ModelFile model;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bielik-model-test-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    repository = LocalModelFilesRepository(
      ModelFileDataSource(directory: () async => directory),
    );
    bytes = List.generate(1024 * 128, (i) => i % 256);
    model = ModelFile(
      name: 'test.gguf',
      url: 'http://127.0.0.1:${server.port}/model',
      sizeBytes: bytes.length,
      sha256: sha256.convert(bytes).toString(),
    );
  });

  tearDown(() async {
    repository.cancelDownload();
    await server.close(force: true);
    await directory.delete(recursive: true);
  });

  test('Streams file, verifies hash, recognizes it after restart and deletes it', () async {
    server.listen((request) async {
      request.response.contentLength = bytes.length;
      request.response.add(bytes);
      await request.response.close();
    });
    final reports = <ModelDownloadProgress>[];
    expect(await repository.isDownloaded(model), isFalse);
    await repository.download(model, reports.add);
    expect(reports.last.verifying, isTrue);
    expect(reports.last.receivedBytes, bytes.length);
    expect(await File('${directory.path}/models/test.gguf').readAsBytes(), bytes);
    expect(await File('${directory.path}/models/test.gguf.part').exists(), isFalse);
    final reopened = LocalModelFilesRepository(
      ModelFileDataSource(directory: () async => directory),
    );
    expect(await reopened.isDownloaded(model), isTrue);
    await reopened.delete(model);
    expect(await reopened.isDownloaded(model), isFalse);
  });

  test('Rejects a file with the wrong hash and removes partial data', () async {
    server.listen((request) async {
      request.response.add(List.filled(bytes.length, 0));
      await request.response.close();
    });
    await expectLater(repository.download(model, (_) {}), throwsFormatException);
    expect(await repository.isDownloaded(model), isFalse);
    expect(await File('${directory.path}/models/test.gguf.part').exists(), isFalse);
  });

  test('HTTP errors do not create a completed file and allow retry', () async {
    var failed = false;
    server.listen((request) async {
      if (!failed) {
        failed = true;
        request.response.statusCode = 503;
      } else {
        request.response.add(bytes);
      }
      await request.response.close();
    });
    await expectLater(repository.download(model, (_) {}), throwsA(isA<HttpException>()));
    expect(await repository.isDownloaded(model), isFalse);
    await repository.download(model, (_) {});
    expect(await repository.isDownloaded(model), isTrue);
  });

  test('Cancels a pending request and clears the partial file', () async {
    final requested = Completer<void>();
    server.listen((request) {
      requested.complete();
    });
    final result = repository.download(model, (_) {});
    final assertion = expectLater(result, throwsA(isA<ModelDownloadCancelled>()));
    await requested.future;
    repository.cancelDownload();
    await assertion;
    expect(await repository.isDownloaded(model), isFalse);
    expect(await File('${directory.path}/models/test.gguf.part').exists(), isFalse);
  });

  test('Rejects truncated response and wrong content length', () async {
    server.listen((request) async {
      request.response.contentLength = 3;
      request.response.add([1, 2, 3]);
      await request.response.close();
    });
    await expectLater(repository.download(model, (_) {}), throwsFormatException);
    expect(await repository.isDownloaded(model), isFalse);
  });
}
