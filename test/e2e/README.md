# Android end-to-end tests

## Quick start

From the repository root, with Flutter 3.47.9, ADB on PATH, and an Android device connected with USB debugging enabled:

```sh
flutter pub get
flutter devices
dart run test/e2e/run_android_e2e.dart --device <android-serial> --scenario all
```

Use an ARM64 Android phone capable of running Bielik 1.5B. The tests need network access, storage for a roughly 1.7 GB model and its temporary download, and enough RAM for inference. The CPU test profile uses a 512-token context, at most 32 response tokens, and two threads.

You can omit `--device` when exactly one supported Android device is connected. To select tools outside PATH:

```sh
dart run test/e2e/run_android_e2e.dart --scenario all --adb <path-to-adb> --flutter <path-to-flutter>
```

| Suite | Phases |
| --- | --- |
| `all` | download → cpu → create → verify → delete |
| `model` | download → delete |
| `cpu` | download → cpu → delete |
| `chat` | download → create → verify → delete |

Every suite downloads the model through the app and removes it at the end of a successful run. These tests are manual; neither ordinary `flutter test` nor GitHub Actions runs them.

## What these tests verify

These scenarios exercise user flows with real SQLite, files, `flutter_downloader`, and the CPU inference engine. They check behavior that fakes and a successful APK build cannot establish.

| Scenario | Checks |
| --- | --- |
| [Model lifecycle](android/model_lifecycle_scenario.dart) | Download through the UI, confirm resource warnings when shown, verify file size and SHA-256, then delete the model and its associated task |
| [CPU generation](android/cpu_generation_scenario.dart) | Create a conversation, send a message, display a real streamed reply, and persist the response |
| [Chat persistence](android/chat_persistence_scenario.dart) | Save messages and a draft, restore them in a new Android process, cancel deletion, then confirm deletion |

The reply must be nonempty and visible; it does not need to match a fixed sentence.

## Isolation and process restart

The runner builds with `BIELIK_E2E=true`, which selects the separate application ID `bielik.ai.bielik_oneclick_launcher.e2e`. Before opening the database or downloader, the test verifies that it is inside this app's private directory. The regular app's data is preserved.

The runner uses `flutter drive --keep-app-running` to prevent Flutter Driver from uninstalling the app between phases. After each phase, it force-stops only the E2E app. The persistence scenario checks that verification runs with a different process ID and restores the original data. Run complete suites through the host runner rather than invoking individual phases manually.

## Output

The runner prints the artifact directory and final status. Each run creates:

```text
test/e2e/output/android/<run-id>_<suite>/
├── report.json                  # Overall status, source revision, device, phase results
├── devices.json                 # Flutter device discovery result
└── <phase>/
    ├── flutter.log              # Build and test output
    ├── device-report.json       # Scenario result, model, process ID, elapsed time
    ├── logcat.txt               # Android logs filtered by the E2E app UID
    └── screenshots/             # PNG screenshot attempted on scenario failure
```

JSON reports can be inspected directly or parsed by tools. Logs are plain text; screenshots are PNG. Device reports and screenshots may be absent if the app cannot start or its process crashes. Generated artifacts are ignored by Git.

| Final status | Exit code | Meaning |
| --- | --- | --- |
| `passed` | 0 | Every phase, device report, and process stop succeeded |
| `failed` | 1 | A scenario, build, or runner operation failed |
| `blocked` | 2 | No suitable device was selected or connected |

Invalid arguments return exit code 64. A phase has a 40-minute host timeout; downloading has a 30-minute timeout and generation a 10-minute timeout. Failed runs stop at the failing phase and may leave test files in the isolated E2E app.

See the [output directory guide](output/android/README.md) for artifact details.
