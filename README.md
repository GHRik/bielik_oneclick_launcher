[![Code Quality](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/code-quality.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/code-quality.yml)
[![Unit Tests](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/unit-tests.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/unit-tests.yml)
[![Component Tests](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/component-tests.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/component-tests.yml)
[![Integration Tests](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/integration-tests.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/integration-tests.yml)
[![Architecture](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/architecture.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/architecture.yml)
[![Android Build](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/android-build.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/android-build.yml)
[![Release APK](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/build-apk.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/build-apk.yml)

# Bielik OneClick Launcher

A one-click Android launcher for running Bielik language models locally on your phone, with chat, live statistics, and configurable model parameters, including experimental GPU acceleration.

- Download and manage Bielik 1.5B and 4.5B GGUF models inside the app.
- Chat with streamed Markdown replies, including bold text, lists, and code; conversations and message drafts are saved in SQLite.
- View resource usage, available device temperatures, and model generation statistics.
- Adjust CPU threads, context size, response length, and sampling parameters.
- Experiment with GPU acceleration through a separate Vulkan/OpenCL adapter.

CPU is the default. GPU inference is experimental and has not been validated on a device with this implementation; earlier attempts produced corrupted text. GPU settings apply only to the current app session. Hardware statistics depend on what the device exposes.

## License

The launcher code and original project assets are available under the [MIT License](LICENSE): free to use, modify, and distribute, including commercially, while retaining the license and copyright notice. Third-party dependencies and Bielik model weights retain their own licenses and terms.

## Model attribution

Bielik models are developed by **SpeakLeash (Spichlerz)** and **ACK Cyfronet AGH**. This repository provides an independent launcher, not the models themselves. Rights to the models remain with their respective authors and rights holders; use is subject to each model's license and terms.

Official model cards and licenses: [Bielik 1.5B v3.0 Instruct GGUF](https://huggingface.co/speakleash/Bielik-1.5B-v3.0-Instruct-GGUF) and [Bielik 4.5B v3.0 Instruct GGUF](https://huggingface.co/speakleash/Bielik-4.5B-v3.0-Instruct-GGUF).

## Download and install

1. Open [Releases](https://github.com/GHRik/bielik_oneclick_launcher/releases) and download a `bielik-arm64-….apk` from the release's **Assets**.
2. Install the APK on your Android phone. Allow installation from your browser or file manager if prompted.
3. Open the app, select and download a model, then open the chat.

No Flutter or Android Studio installation is needed. Models are downloaded separately inside the app: approximately 1.7 GB for 1.5B and 5.06 GB for 4.5B. Running a model also requires sufficient RAM.

The APK is currently a debug build for ARM64 phones. A stable signing key for updates is still planned; CI builds may have different signatures.

## Adding models

The app currently offers these models:

| Model | Download | Required free RAM |
| --- | --- | --- |
| Bielik 1.5B v3.0 Instruct · Q8_0 | About 1.7 GB | 4 GB |
| Bielik 4.5B v3.0 Instruct · Q8_0 | About 5.06 GB | 8 GB |

RAM requirements are estimates and depend on the context and runtime settings.

To extend the dropdown, edit **[lib/configuration/bielik_models.dart](lib/configuration/bielik_models.dart)** and add another `BielikModel` to `bielikModels`. Copy an existing entry as a template and replace:

| Field | Value to provide |
| --- | --- |
| `name` | Display name in the model selector |
| `file.name` | Unique local GGUF filename |
| `file.url` | Direct HTTPS download URL for the GGUF; use a fixed repository revision for stable metadata |
| `file.sizeBytes` / `file.sha256` | Exact byte size and SHA-256 of that file |
| `downloadSizeMb` / `diskSpace` | Download size in decimal MB and storage description |
| `requiredFreeRamGb` / `ram` | Numeric free RAM threshold in decimal GB and a readable estimate |

For example, an entry has this shape; replace every example value with the actual model metadata:

```dart
BielikModel(
  name: 'My Bielik · Q8',
  file: ModelFile(
    name: 'my-bielik.Q8_0.gguf',
    url: 'https://huggingface.co/<owner>/<repo>/resolve/<commit>/<file>.gguf',
    sizeBytes: 1234567890,
    sha256: '<exact 64-character SHA-256>',
  ),
  diskSpace: 'about 1.24 GB',
  downloadSizeMb: 1234.57,
  ram: 'at least 4 GB of free RAM',
  requiredFreeRamGb: 4,
),
```

Use a GGUF architecture supported by the bundled `llamadart` / `llama.cpp` runtime. An arbitrary GGUF file is not guaranteed to work. Incorrect size or SHA-256 prevents the download from being accepted.

Rebuild the APK using the [quick start](#quick-start-from-source). The new entry appears automatically and the user downloads its weights inside the app. This changes the catalog in source code; installed APKs do not have a custom-model import screen.

A catalog entry uses the shared model settings. Only if it needs different defaults, add an optional filename-keyed override in [llm_configuration.dart](lib/configuration/llm_configuration.dart). A profile saved in the app's settings takes precedence over file defaults.

## Project layout

```text
lib/
├── main.dart              # Startup and dependency injection
├── configuration/         # Model catalog, LLM defaults, system prompt, database setup
└── src/
    ├── app.dart           # Application setup and screen dependencies
    ├── presentation/      # Pages, widgets, state controllers, sidebars, formatters
    ├── domain/            # Models, repository contracts, business services
    └── data/              # Data sources, repository implementations, runtime adapters

android/                   # Android host, resource/statistics channels, build setup
test/                      # Component, integration, architecture, and manual E2E tests
site/                      # Polish GitHub Pages landing page
.github/workflows/         # Separate CI checks, APK releases, Pages deployment
```

Unit tests live in `ut/` directories beside their production classes under `lib/`. See [testing](test/README.md) and [architecture](ARCHITECTURE.md) for details.

## Quick start from source

Use Flutter **3.47.9** with Dart **3.13.7**, Android SDK, and an Android device with USB debugging enabled.

```sh
git clone https://github.com/GHRik/bielik_oneclick_launcher.git
cd bielik_oneclick_launcher
flutter pub get
flutter devices
flutter run -d <android-device-id>
```

To build an ARM64 APK locally:

```sh
flutter build apk --debug --no-pub --target-platform android-arm64
```

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. Model files are not bundled with it.

## Checks and releases

The badges above link to separate workflows for code quality, unit tests, component tests, integration tests, architecture, Android builds, and APK releases.

Automatic checks run on pull requests to `master` and pushes to `master` when application code, tests, assets, dependencies, or analysis configuration change. Documentation-only and `.github/`-only changes do not trigger these checks. E2E tests remain manual.

To publish a downloadable test APK, open **Actions → Release APK → Run workflow** and select a branch. The workflow publishes the APK, SHA-256 checksum, and source commit details to Releases.

- [Test quick start and directory guide](test/README.md)
- [Manual Android E2E tests](test/e2e/README.md)
- [Architecture and configuration](ARCHITECTURE.md)
- [Polish landing page maintenance](site/README.md)
