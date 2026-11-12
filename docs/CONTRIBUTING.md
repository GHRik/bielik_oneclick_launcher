# Contributing

Guide for building, extending, and maintaining Bielik OneClick Launcher. The [README](../README.md) is for a quick install and links here.

[![Release APK](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/build-apk.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/build-apk.yml)
[![Code Quality](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/code-quality.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/code-quality.yml)
[![Unit Tests](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/unit-tests.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/unit-tests.yml)

## How we work

Before you open a pull request, read the [open issues](https://github.com/GHRik/bielik_oneclick_launcher/issues). Work that is not tied to an issue should start with a new issue, so scope and acceptance are clear.

| Rule | What we expect |
| --- | --- |
| **One branch, one feature** | A branch and its PR address a single topic (one issue or one coherent change). |
| **Small commits** | Keep commits on the branch as small and reviewable as possible — one logical step per commit. |
| **Tests with the change** | Every behavior change in the same commit (or the same small commit series before merge) must include automated tests that cover it: unit (`lib/**/ut/`), component, or integration, as fits the layer. Do not merge production changes without matching tests. |
| **Issues first** | Prefer picking up [open issues](https://github.com/GHRik/bielik_oneclick_launcher/issues). If you fix something else, open an issue first or in the same PR and link it. |
| **ARM64 only** | Supported and shipped target is **Android ARM64** (`android-arm64`). **ARM32 (armeabi-v7a) is not supported** and should not be reintroduced. Local builds and CI use `--target-platform android-arm64` unless a workflow says otherwise. |
| **Target `master`** | Open PRs against `master`. CI must pass for code changes (documentation-only and `.github/`-only edits may skip app workflows — see [Checks and releases](#checks-and-releases)). |
| **Layer boundaries** | Respect `domain` / `data` / `presentation` rules; run `flutter test test/architecture` before pushing. New colocated unit tests must be registered in `test/ut_test.dart`. |
| **Toolchain** | Use Flutter **3.47.9** / Dart **3.13.7** and `flutter pub get --enforce-lockfile` so your tree matches CI. |
| **Before push** | From the repo root: `dart format lib test`, `flutter analyze --no-pub`, and `flutter test --no-pub` (or the level you touched). |
| **PR description** | State cause and change, link issues (`Fixes #…`), list tests added or updated, and note what you verified on a device or emulator when relevant. |
| **Secrets** | Never commit signing keys, tokens, or `.env` credentials. Release signing stays in GitHub Actions secrets. |
| **User-visible text** | Polish copy for in-app messages and snackbars; English is fine for code, architecture docs, and contributor docs. |

Keep GPU and device-statistics documentation aligned with [Runtime notes (CPU / GPU)](#runtime-notes-cpu--gpu) when you change inference or related UI copy.

### Commit messages

Use short, imperative subjects with a conventional prefix (same style as recent history):

| Prefix | Use for |
| --- | --- |
| `feat:` | New user-visible behavior |
| `fix:` | Bug fixes |
| `docs:` | README, CONTRIBUTING, architecture or feature docs |
| `test:` | Tests only |
| `style:` | UI or site presentation without behavior change |
| `site:` | Polish GitHub Pages (`site/`) |

Example: `fix: open chat hyperlinks and clarify link instructions`. Multi-line bodies are welcome when they explain cause and verification.

### Manual Android E2E

Automated CI does **not** run [Android E2E tests](../test/e2e/README.md). They use a real device, network, model download (~1.7 GB), SQLite, `flutter_downloader`, and CPU inference.

**When they matter.** Run (or extend) E2E when you change anything on this path:

- model download, verification, deletion, or storage or RAM checks;
- chat, drafts, conversations, or process restart / persistence;
- Android platform channels, app ID, or native code used by the above;
- CPU inference wiring that E2E exercises (GPU-only paths need separate on-device verification unless you add coverage).

**What we ask — and thank you for.** The maintainer will still run checks before a **released** APK, but it helps a lot if contributors:

1. On current `master`, run the relevant E2E suite **before** you start, when your issue touches the areas above — so you know the baseline passes.
2. On **your branch**, run the same suite **before** you open or update the PR — so we do not merge a regression that only shows up on a phone.

Quick start:

```sh
dart run test/e2e/run_android_e2e.dart --device <android-serial> --scenario all
```

Use `--scenario model`, `cpu`, or `chat` when a full `all` run is unnecessary. Mention the suite and result in the PR (pass, fail, or blocked with reason). E2E failures on your branch should be fixed or explained before merge, even though GitHub Actions will stay green.

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

Unit tests live in `ut/` directories beside their production classes under `lib/`. See [testing](../test/README.md) and [architecture](../ARCHITECTURE.md).

## Adding models

The app currently offers these models (same table as the README; RAM figures are estimates):

| Model | Download | Required free RAM |
| --- | --- | --- |
| Bielik 1.5B v3.0 Instruct · Q8_0 | About 1.7 GB | 4 GB |
| Bielik 4.5B v3.0 Instruct · Q8_0 | About 5.06 GB | 8 GB |

To extend the dropdown, edit **[lib/configuration/bielik_models.dart](../lib/configuration/bielik_models.dart)** and add another `BielikModel` to `bielikModels`. Copy an existing entry as a template and replace:

| Field | Value to provide |
| --- | --- |
| `name` | Display name in the model selector |
| `file.name` | Unique local GGUF filename |
| `file.url` | Direct HTTPS download URL for the GGUF; use a fixed repository revision for stable metadata |
| `file.sizeBytes` / `file.sha256` | Exact byte size and SHA-256 of that file |
| `downloadSizeMb` / `diskSpace` | Download size in decimal MB and storage description |
| `requiredFreeRamGb` / `ram` | Numeric free RAM threshold in decimal GB and a readable estimate |

Example shape (replace every value with real metadata):

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

Rebuild the APK using the [quick start](#quick-start-from-source) above. The new entry appears in the app catalog; users download weights inside the app. Installed APKs do not support ad-hoc model import.

A catalog entry uses the shared model settings. Only if it needs different defaults, add an optional filename-keyed override in [llm_configuration.dart](../lib/configuration/llm_configuration.dart). A profile saved in the app's settings takes precedence over file defaults.

## Checks and releases

[![Android Build](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/android-build.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/android-build.yml)
[![Architecture](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/architecture.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/architecture.yml)
[![Component Tests](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/component-tests.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/component-tests.yml)
[![Integration Tests](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/integration-tests.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/integration-tests.yml)

CI badges on the [README](../README.md) were moved here so the landing page stays scannable.

Automatic checks run on pull requests to `master` and pushes to `master` when application code, tests, assets, dependencies, or analysis configuration change. Documentation-only and `.github/`-only changes do not trigger these checks. E2E tests remain manual.

To publish a downloadable test APK, open **Actions → Release APK → Run workflow** and select a branch. The workflow publishes a signed release APK, SHA-256 checksum, certificate details, and source commit information to Releases. Signing secrets are configured in the repository; the public certificate fingerprint is pinned in source control. See [release maintenance](RELEASING.md).

### Further reading

- [Test quick start and directory guide](../test/README.md)
- [Manual Android E2E tests](../test/e2e/README.md)
- [Architecture and configuration](../ARCHITECTURE.md)
- [Polish landing page maintenance](../site/README.md)
- Feature notes: [ASK_BIELIK.md](ASK_BIELIK.md), [ATTACHMENTS.md](ATTACHMENTS.md), [SPEECH_TO_TEXT.md](SPEECH_TO_TEXT.md)

## Runtime notes (CPU / GPU)

CPU is the default. **OpenCL** on GPU has been tested on OnePlus 15 (CPH2747) and Pixel 8 Pro. GPU inference does **not** work on Samsung Galaxy S24+. **Vulkan** has not been tested. GPU settings apply only for the current app session. Hardware statistics depend on what the device exposes.
