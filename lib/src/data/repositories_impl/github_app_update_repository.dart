import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_update_repository.dart';

class GithubAppUpdateRepository implements AppUpdateRepository {
  static const _api =
      'https://api.github.com/repos/GHRik/bielik_oneclick_launcher/releases/latest';
  static const _assetPrefix =
      'https://github.com/GHRik/bielik_oneclick_launcher/releases/download/';
  static const _channel = MethodChannel('bielik/apk_update');
  final HttpClient Function() clientFactory;
  GithubAppUpdateRepository({HttpClient Function()? clientFactory})
    : clientFactory = clientFactory ?? HttpClient.new;
  HttpClient? _active;

  Uri _asset(Map<String, dynamic> asset) {
    final url = Uri.parse(asset['browser_download_url'] as String);
    if (!url.toString().startsWith(_assetPrefix) || url.scheme != 'https') {
      throw const FormatException('Unexpected release asset URL');
    }
    return url;
  }

  Future<HttpClientResponse> _get(HttpClient client, Uri uri) async {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 15));
    request.headers.set(HttpHeaders.userAgentHeader, 'Bielik-OneClick-Updater');
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    return response;
  }

  Future<String> _text(HttpClient client, Uri uri) async {
    final response = await _get(client, uri);
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      bytes.addAll(chunk);
      if (bytes.length > 1024 * 1024) {
        throw const FormatException('Metadata too large');
      }
    }
    return utf8.decode(bytes);
  }

  @override
  Future<AppUpdate?> check(int installedBuild) async {
    final client = _active = clientFactory();
    try {
      final release = jsonDecode(
        await _text(client, Uri.parse(_api)),
      ) as Map<String, dynamic>;
      if (release['draft'] != false ||
          release['prerelease'] != false ||
          (release['tag_name'] as String).startsWith('google-play-')) {
        throw const FormatException('Not a stable APK release');
      }
      final assets = (release['assets'] as List).cast<Map<String, dynamic>>();
      Map<String, dynamic> asset(String name) =>
          assets.firstWhere((a) => a['name'] == name);
      final apk = asset('bielik-arm64.apk');
      final buildText = await _text(client, _asset(asset('BUILD.txt')));
      final build = int.parse(
        RegExp(
          r'^Android version code: (\d+)$',
          multiLine: true,
        ).firstMatch(buildText)![1]!,
      );
      final version = RegExp(
        r'^Version: (\d+\.\d+\.\d+)$',
        multiLine: true,
      ).firstMatch(buildText)![1]!;
      if (build <= installedBuild) return null;
      final checksum = await _text(
        client,
        _asset(asset('bielik-arm64.apk.sha256')),
      );
      final hash = RegExp(r'^([a-fA-F0-9]{64})\s+\*?bielik-arm64\.apk\s*$')
          .firstMatch(checksum.trim())?[1];
      final size = apk['size'] as int;
      if (hash == null || size <= 0) {
        throw const FormatException('Invalid APK metadata');
      }
      return AppUpdate(
        version: version,
        build: build,
        url: _asset(apk),
        sha256: hash.toLowerCase(),
        bytes: size,
      );
    } on SocketException {
      throw const UpdateFailure('Wróć tutaj, gdy będziesz znowu online.');
    } on TimeoutException {
      throw const UpdateFailure(
        'Przekroczono czas oczekiwania. Sprawdź połączenie i spróbuj ponownie.',
      );
    } catch (error) {
      if (error is UpdateFailure) rethrow;
      throw const UpdateFailure(
        'Nie udało się sprawdzić aktualizacji. Spróbuj ponownie później.',
      );
    } finally {
      client.close(force: true);
      if (identical(_active, client)) _active = null;
    }
  }

  @override
  Future<String> download(
    AppUpdate update,
    void Function(double) onProgress,
  ) async {
    final client = _active = clientFactory();
    File? file;
    IOSink? sink;
    var complete = false;
    try {
      if (!update.url.toString().startsWith(_assetPrefix)) {
        throw const FormatException('Unexpected APK URL');
      }
      final path = await _channel.invokeMethod<String>('downloadPath');
      if (path == null) throw const FormatException('No download directory');
      file = File(path);
      final response = await _get(client, update.url);
      sink = file.openWrite();
      var received = 0;
      await sink.addStream(
        response.timeout(const Duration(seconds: 30)).map((chunk) {
          received += chunk.length;
          if (received > update.bytes) {
            throw const FormatException('APK too large');
          }
          onProgress(received / update.bytes);
          return chunk;
        }),
      );
      await sink.flush();
      await sink.close();
      sink = null;
      if (received != update.bytes ||
          (await sha256.bind(file.openRead()).first).toString() !=
              update.sha256) {
        throw const UpdateFailure(
          'Pobrany APK jest uszkodzony. Pobierz aktualizację ponownie.',
        );
      }
      complete = true;
      return path;
    } on UpdateFailure {
      rethrow;
    } on SocketException {
      throw const UpdateFailure(
        'Pobieranie przerwane. Wróć tutaj, gdy będziesz znowu online.',
      );
    } on FileSystemException {
      throw const UpdateFailure(
        'Nie można zapisać APK. Sprawdź wolne miejsce na telefonie.',
      );
    } catch (_) {
      throw const UpdateFailure(
        'Nie udało się pobrać aktualizacji. Spróbuj ponownie.',
      );
    } finally {
      client.close(force: true);
      if (identical(_active, client)) _active = null;
      await sink?.close();
      if (!complete && file != null && await file.exists()) await file.delete();
    }
  }

  @override
  Future<bool> install(String path) async {
    try {
      return await _channel.invokeMethod<bool>('install', path) ?? false;
    } on PlatformException catch (error) {
      throw UpdateFailure(
        error.message ?? 'Nie udało się otworzyć instalatora.',
      );
    }
  }

  @override
  void cancel() => _active?.close(force: true);
}
