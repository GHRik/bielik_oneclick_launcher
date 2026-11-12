# Testing

## Quick start

Run from the repository root with Flutter 3.47.9:

```sh
flutter pub get
flutter test --no-pub
```

This runs the registered unit tests, component tests, Flutter integration tests, and architecture checks. It does not run Android E2E tests or the standalone Java test.

Run an individual level:

```sh
flutter test --no-pub test/ut_test.dart
flutter test --no-pub test/component
flutter test --no-pub test/integration
flutter test --no-pub test/architecture
```

Run a single colocated unit test:

```sh
flutter test --no-pub lib/src/data/datasources/ut/test_device_resources_datasource.dart
```

For static checks:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
```

## Testing levels

| Level | Scope | External dependencies |
| --- | --- | --- |
| Unit | One production class or the functions in one file; one behavior per case | Private fakes replace collaborators and platform channels |
| Component | Views and cooperating services, controllers, workspaces, and runtime adapters | Storage, LLM inference, and platform readings are replaced as needed |
| Integration | Real SQLite persistence and temporary files; repository and adapter integration | Network transfers and LLM inference are still faked |
| Native adapter | Java GPU reader against a synthetic sysfs tree | No Android device or real GPU is used |
| Architecture | Layer boundaries, allowed imports, and unit test registration | Reads project source files |
| End-to-end | Download/delete a real model, generate a CPU reply, restore chat after a process restart | Real Android app, plugins, SQLite, network, and model |

The scope and dependencies determine the level, rather than the choice of `test()` or `testWidgets()`. Mocked platform channels do not verify the Android implementation; the native adapter test does not verify hardware access on a phone.

## Directory layout

```text
lib/**/ut/
├── test_<production_file>.dart   # Unit tests beside the production class
└── analysis_options.yaml         # Includes the shared UT analyzer configuration

test/
├── ut_test.dart                  # Registers all colocated unit tests
├── component/                    # UI and cooperating component tests, grouped by feature
├── integration/
│   ├── database/                 # SQLite schema, migrations, persistence, configuration
│   ├── llm/                      # Inference integration with fake engines
│   ├── model_management/         # Model files and download repository integration
│   └── native/android/           # Standalone Java GPU sysfs reader test
├── architecture/                 # Dependency rules and UT registration checks
├── support/                      # Shared fakes for component/integration tests
└── e2e/                          # Manual Android scenarios, runner, and output
```

A file named `ut/test_<production_file>.dart` tests the class or functions from that production file. Unit tests use their own private fakes. The current suites cover selected classes; this layout does not imply complete coverage.

Names beginning with `test_` are not automatically discovered like `*_test.dart`. When adding a colocated UT file, import it and invoke its `main()` in `test/ut_test.dart`. The architecture check detects missing registrations.

The root `analysis_options_ut.yaml` inherits project rules and disables only `depend_on_referenced_packages`, allowing tests under `lib/` to use the development dependency `flutter_test`. Each local UT analyzer file includes this shared configuration.

## Standalone Java test

With a JDK on PATH, run from the repository root:

```sh
javac -d .agent-staging/native-tests android/app/src/main/java/bielik/ai/bielik_oneclick_launcher/GpuSysfsReader.java test/integration/native/android/GpuSysfsReaderTest.java
java -cp .agent-staging/native-tests bielik.ai.bielik_oneclick_launcher.GpuSysfsReaderTest
```

## Android E2E and CI

Before promoting a GitHub prerelease to **Latest**, run manual E2E tests on a physical Android phone from the repository root:

```sh
dart run test/e2e/run_android_e2e.dart --scenario all
```

Keeping these tests outside CI is deliberate: they require a real device and download a roughly 1.7 GB model. See the [E2E quick start](e2e/README.md) for setup and reports and the [release process](../docs/RELEASING.md#publish-a-build) for promotion. Also test the chosen prerelease APK on the phone: the runner builds an isolated E2E app rather than installing that release asset.

CI has separate workflows for unit, component, integration, and architecture tests. The integration workflow also runs the Java adapter test in its own job. Test JSON reports and logs are uploaded as artifacts for 14 days.

Local Flutter tests require a working Flutter SDK and SQLite FFI support; the Java test requires a JDK. Device E2E results apply to the tested platform and device, not automatically to iOS or desktop.
