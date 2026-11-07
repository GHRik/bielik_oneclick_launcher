import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const applicationId = 'bielik.ai.bielik_oneclick_launcher.e2e';
const phasesBySuite = <String, List<String>>{
  'all': ['download', 'cpu', 'create', 'verify', 'delete'],
  'model': ['download', 'delete'],
  'cpu': ['download', 'cpu', 'delete'],
  'chat': ['download', 'create', 'verify', 'delete'],
};

Future<int> execute(
  String executable,
  List<String> arguments,
  File log, {
  Duration timeout = const Duration(minutes: 40),
  Map<String, String>? environment,
}) async {
  final sink = log.openWrite();
  Process? process;
  StreamSubscription<List<int>>? output;
  StreamSubscription<List<int>>? errors;
  final outDone = Completer<void>();
  final errDone = Completer<void>();
  try {
    process = await Process.start(
      executable,
      arguments,
      runInShell: Platform.isWindows,
      environment: environment,
    );
    output = process.stdout.listen(sink.add, onDone: outDone.complete);
    errors = process.stderr.listen(sink.add, onDone: errDone.complete);
    int code;
    try {
      code = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      sink.writeln('Host timeout after ${timeout.inMinutes} minutes.');
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/PID', '${process.pid}', '/T', '/F']);
      } else {
        process.kill(ProcessSignal.sigkill);
      }
      code = 124;
    }
    try {
      await Future.wait([outDone.future, errDone.future])
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      sink.writeln('Output streams did not close within the deadline.');
    }
    return code;
  } finally {
    await output?.cancel();
    await errors?.cancel();
    await sink.flush();
    await sink.close();
  }
}

Future<void> main(List<String> arguments) async {
  final options = <String, String>{};
  for (var i = 0; i < arguments.length; i += 2) {
    if (i + 1 >= arguments.length || !arguments[i].startsWith('--')) {
      stderr.writeln(
        'Usage: dart run test/e2e/run_android_e2e.dart [--device SERIAL] [--scenario all|model|cpu|chat] [--adb PATH] [--flutter PATH]',
      );
      exitCode = 64;
      return;
    }
    options[arguments[i].substring(2)] = arguments[i + 1];
  }
  final suite = options['scenario'] ?? 'all';
  if (!phasesBySuite.containsKey(suite)) {
    stderr.writeln('Unknown scenario: $suite');
    exitCode = 64;
    return;
  }
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run from the project root.');
    exitCode = 64;
    return;
  }
  final runId = DateTime.now().toUtc().toIso8601String().replaceAll(
    RegExp(r'[^0-9]'),
    '',
  );
  final root = await Directory(
    path.join('test', 'e2e', 'output', 'android', '${runId}_$suite'),
  ).create(recursive: true);
  final reportFile = File(path.join(root.path, 'report.json'));
  final report = <String, dynamic>{
    'runId': runId,
    'suite': suite,
    'startedAt': DateTime.now().toUtc().toIso8601String(),
    'status': 'running',
    'applicationId': applicationId,
    'phases': <Map<String, dynamic>>[],
  };
  Future<void> save() => reportFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
    flush: true,
  );
  final sdkBin = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .path;
  final inferredFlutter = path.join(
    sdkBin,
    Platform.isWindows ? 'flutter.bat' : 'flutter',
  );
  final flutter =
      options['flutter'] ??
      (File(inferredFlutter).existsSync() ? inferredFlutter : 'flutter');
  final adb = options['adb'] ?? 'adb';
  await save();
  stdout.writeln('Android E2E artifacts: ${root.absolute.path}');
  try {
    final revision = await Process.run('git', ['rev-parse', 'HEAD']);
    report['revision'] = revision.stdout.toString().trim();
    final discovery = await Process.run(flutter, [
      'devices',
      '--machine',
    ], runInShell: Platform.isWindows);
    await File(path.join(root.path, 'devices.json'))
        .writeAsString(discovery.stdout.toString());
    if (discovery.exitCode != 0) {
      throw StateError('Flutter device discovery failed: ${discovery.stderr}');
    }
    final devices = (jsonDecode(discovery.stdout.toString()) as List)
        .cast<Map<String, dynamic>>()
        .where(
          (d) =>
              d['isSupported'] == true &&
              d['targetPlatform'].toString().startsWith('android'),
        )
        .toList();
    final requested = options['device'];
    final candidates = requested == null
        ? devices
        : devices.where((d) => d['id'] == requested).toList();
    if (candidates.length != 1) {
      report['status'] = 'blocked';
      report['reason'] = devices.isEmpty
          ? 'No Android device or emulator is connected.'
          : 'Specify exactly one connected Android using --device SERIAL.';
      exitCode = 2;
      return;
    }
    final device = candidates.single;
    final serial = device['id'] as String;
    if (!RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(serial)) {
      throw StateError('Unexpected device serial format.');
    }
    report['device'] = device;
    final adbCheck = await Process.run(adb, [
      'version',
    ], runInShell: Platform.isWindows);
    if (adbCheck.exitCode != 0) {
      throw StateError('ADB is unavailable; provide --adb PATH.');
    }
    for (final phase in phasesBySuite[suite]!) {
      final phaseDirectory = await Directory(path.join(root.path, phase))
          .create();
      final target = switch (phase) {
        'download' || 'delete' => 'model_lifecycle_scenario.dart',
        'cpu' => 'cpu_generation_scenario.dart',
        _ => 'chat_persistence_scenario.dart',
      };
      final phaseReport = <String, dynamic>{
        'phase': phase,
        'status': 'running',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
      };
      (report['phases'] as List).add(phaseReport);
      await save();
      stdout.writeln('Running Android E2E phase: $phase');
      final timer = Stopwatch()..start();
      final result = await execute(
        flutter,
        [
          'drive',
          '--no-pub',
          '--keep-app-running',
          '-d',
          serial,
          '--driver=test/e2e/android/support/driver.dart',
          '--target=test/e2e/android/$target',
          '--dart-define=BIELIK_E2E=true',
          '--dart-define=E2E_PHASE=$phase',
          '--dart-define=E2E_RUN_ID=$runId',
        ],
        File(path.join(phaseDirectory.path, 'flutter.log')),
        environment: {'E2E_OUTPUT_DIR': phaseDirectory.absolute.path},
      );
      phaseReport['exitCode'] = result;
      phaseReport['durationMs'] = timer.elapsedMilliseconds;
      try {
        final packages = await Process.run(adb, [
          '-s',
          serial,
          'shell',
          'cmd',
          'package',
          'list',
          'packages',
          '-U',
          applicationId,
        ], runInShell: Platform.isWindows);
        final uid = RegExp(r'uid:(\d+)')
            .firstMatch(packages.stdout.toString())
            ?.group(1);
        if (uid != null) {
          await execute(
            adb,
            ['-s', serial, 'logcat', '-d', '-v', 'threadtime', '--uid=$uid'],
            File(path.join(phaseDirectory.path, 'logcat.txt')),
            timeout: const Duration(seconds: 30),
          );
        }
      } catch (error) {
        phaseReport['logcatError'] = '$error';
      }
      final stopped = await Process.run(adb, [
        '-s',
        serial,
        'shell',
        'am',
        'force-stop',
        applicationId,
      ], runInShell: Platform.isWindows);
      phaseReport['forceStopExitCode'] = stopped.exitCode;
      final deviceReport = File(
        path.join(phaseDirectory.path, 'device-report.json'),
      );
      final data = await deviceReport.exists()
          ? jsonDecode(await deviceReport.readAsString())
                as Map<String, dynamic>?
          : null;
      phaseReport['deviceReport'] = data;
      final passed =
          result == 0 && data?['status'] == 'passed' && stopped.exitCode == 0;
      phaseReport['status'] = passed ? 'passed' : 'failed';
      await save();
      if (!passed) {
        report['status'] = 'failed';
        report['reason'] =
            'Phase $phase failed. Inspect its flutter.log and device-report.json.';
        exitCode = 1;
        return;
      }
    }
    report['status'] = 'passed';
    exitCode = 0;
  } catch (error, stack) {
    report['status'] = 'failed';
    report['reason'] = '$error';
    report['stack'] = '$stack';
    exitCode = 1;
  } finally {
    report['finishedAt'] = DateTime.now().toUtc().toIso8601String();
    await save();
    stdout.writeln('Android E2E: ${report['status']}');
    stdout.writeln(reportFile.absolute.path);
  }
}
