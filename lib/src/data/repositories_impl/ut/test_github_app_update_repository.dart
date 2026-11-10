import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/github_app_update_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_update.dart';

class _Headers implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.bytes);
  final List<int> bytes;
  @override
  int get statusCode => 200;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.bytes);
  final List<int> bytes;
  @override
  HttpHeaders get headers => _Headers();
  @override
  Future<HttpClientResponse> close() async => _Response(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements HttpClient {
  _Client(this.replies, {this.offline = false});
  final List<List<int>> replies;
  final bool offline;
  @override
  Future<HttpClientRequest> getUrl(Uri uri) async {
    if (offline) throw const SocketException('offline');
    return _Request(replies.removeAt(0));
  }

  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _prefix =
    'https://github.com/GHRik/bielik_oneclick_launcher/releases/download/v1/';
Map<String, dynamic> _release({bool prerelease = false}) => {
  'draft': false,
  'prerelease': prerelease,
  'tag_name': 'v1.0.9-build.1.1',
  'assets': [
    for (final name in [
      'bielik-arm64.apk',
      'BUILD.txt',
      'bielik-arm64.apk.sha256',
    ])
      {'name': name, 'size': 3, 'browser_download_url': '$_prefix$name'},
  ],
};
List<List<int>> _metadata({bool prerelease = false}) => [
  utf8.encode(jsonEncode(_release(prerelease: prerelease))),
  utf8.encode('Version: 1.0.9\nAndroid version code: 42\n'),
  utf8.encode('${sha256.convert([1, 2, 3])}  bielik-arm64.apk\n'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Detects a newer build even when the display version is unchanged',
    () async {
      final repository = GithubAppUpdateRepository(
        clientFactory: () => _Client(_metadata()),
      );
      expect((await repository.check(41))?.build, 42);
    },
  );
  test('Does not offer an equal or older build', () async {
    final repository = GithubAppUpdateRepository(
      clientFactory: () => _Client(_metadata()),
    );
    expect(await repository.check(42), isNull);
  });
  test('Rejects prereleases', () async {
    final repository = GithubAppUpdateRepository(
      clientFactory: () => _Client(_metadata(prerelease: true)),
    );
    await expectLater(repository.check(1), throwsA(isA<UpdateFailure>()));
  });
  test('Rejects release assets outside the project repository', () async {
    final release = _release();
    (release['assets'] as List)[1]['browser_download_url'] =
        'https://example.com/BUILD.txt';
    final repository = GithubAppUpdateRepository(
      clientFactory: () => _Client([utf8.encode(jsonEncode(release))]),
    );
    await expectLater(repository.check(1), throwsA(isA<UpdateFailure>()));
  });
  test('Offline checks return the return-online message', () async {
    final repository = GithubAppUpdateRepository(
      clientFactory: () => _Client([], offline: true),
    );
    await expectLater(
      repository.check(1),
      throwsA(
        isA<UpdateFailure>().having(
          (e) => e.message,
          'message',
          contains('online'),
        ),
      ),
    );
  });

  group('APK integrity', () {
    late Directory temp;
    late File apk;
    const channel = MethodChannel('bielik/apk_update');
    setUp(() async {
      temp = await Directory.systemTemp.createTemp('bielik-update-test');
      apk = File('${temp.path}/update.apk');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => apk.path);
    });
    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await temp.delete(recursive: true);
    });

    AppUpdate update(String hash, {int bytes = 3}) => AppUpdate(
      version: '1.0.9',
      build: 42,
      url: Uri.parse('${_prefix}bielik-arm64.apk'),
      sha256: hash,
      bytes: bytes,
    );

    test('Keeps a complete APK with the expected SHA-256', () async {
      final repository = GithubAppUpdateRepository(
        clientFactory: () => _Client([
          [1, 2, 3],
        ]),
      );
      final progress = <double>[];
      expect(
        await repository.download(
          update(sha256.convert([1, 2, 3]).toString()),
          progress.add,
        ),
        apk.path,
      );
      expect(await apk.readAsBytes(), [1, 2, 3]);
      expect(progress.last, 1);
    });
    test('Deletes an APK with an incorrect checksum', () async {
      final repository = GithubAppUpdateRepository(
        clientFactory: () => _Client([
          [1, 2, 3],
        ]),
      );
      await expectLater(
        repository.download(update('0' * 64), (_) {}),
        throwsA(isA<UpdateFailure>()),
      );
      expect(await apk.exists(), isFalse);
    });
    test('Deletes a truncated APK', () async {
      final repository = GithubAppUpdateRepository(
        clientFactory: () => _Client([
          [1, 2],
        ]),
      );
      await expectLater(
        repository.download(update('0' * 64), (_) {}),
        throwsA(isA<UpdateFailure>()),
      );
      expect(await apk.exists(), isFalse);
    });
  });
}
