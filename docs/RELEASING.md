# Android APK releases and updates

## Publish a build

Open **Actions → Release APK → Run workflow**, select the branch, optionally enter an app version such as `1.0.1`, and run it. Leaving the version empty uses `pubspec.yaml`. The workflow analyzes the code, runs local Flutter tests, builds a signed ARM64 release APK, verifies its certificate, and always creates a GitHub prerelease, including builds from `master`. It never changes Latest automatically.

Testers can download the APK from that prerelease's assets. Prereleases are publicly visible in Releases, but the README and GitHub Pages download links continue to point to the latest stable release. The landing page's version, date and APK links come from GitHub Releases. Its Polish patch notes are stored separately in `site/release-notes.pl.json`, keyed by the exact release tag. Its archive lists stable releases with an ARM64 APK and excludes drafts and prereleases. Older release descriptions and APKs remain accessible.

After testing, edit the chosen release on GitHub, remove its prerelease flag, and mark it as **Latest**. Alternatively:

```sh
gh release edit <release-tag> --prerelease=false --latest
```

Promoting the existing release keeps the exact APK that was tested; no rebuild or Pages redeployment is needed for the download links to change. Metadata and badges may take time to refresh because of caching.

Download `bielik-arm64.apk` directly from [the latest stable release](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest/download/bielik-arm64.apk), or use **Releases → Assets**. Keep the asset name unchanged: the landing page uses GitHub's permanent latest-asset URL. Each release also includes its SHA-256 checksum, `BUILD.txt`, `SIGNING.txt`, and the MIT license. An artifact copy is retained for 30 days. The ARM64 debug build workflow is a separate CI check; use Release APK for distribution.

## Build an AAB for Google Play

Open **Actions → Release Google Play AAB → Run workflow** on `master`. Leave `source_release` as `latest` (or empty) to build from the latest stable APK. To select another release, enter its exact existing tag, for example `v1.0.6-build.12.1`. This is the source release, not a name for the new AAB. Stable releases and published APK prereleases are supported. The release must include `bielik-arm64.apk` and `BUILD.txt`. A missing tag produces an error with a list of available releases.

The workflow resolves the release tag to its exact commit and checks it against `BUILD.txt`. It reuses the source release's visible app version, assigns a new increasing Android version code, analyzes and tests the source, then builds a signed ARM64 Android App Bundle. It uses the same signing secrets and pinned certificate as the APK workflow. APK and AAB jobs share a concurrency group.

Download `bielik-google-play.aab` from the **google-play-latest** release and upload it manually to Google Play Console. The release description and attached `BUILD.txt` identify the original OneClick release, source commit, version code and workflow run. A SHA-256 checksum and signature details are attached.

GitHub releases do not support issue-style labels: `google-play-latest` is a dedicated moving tag and release. Successful builds replace its assets and update its source commit and notes. Each build also remains available as an Actions artifact for 30 days.

This release stays a **prerelease** with **Latest disabled**, so the website and README continue to offer the stable APK. It does not upload anything to Google Play automatically. An AAB cannot be installed directly like an APK.

## Version names and patch notes

Use `MAJOR.MINOR.PATCH` versions: for example, `1.0.1` for a fix and `1.1.0` for a feature release. The workflow uses that value as Android's visible `versionName`.

Release titles look like **Bielik OneClick 1.0.1 · build 42.1**. Tags look like `v1.0.1-build.42.1`; the workflow run number and attempt distinguish test builds of the same version. Existing release tags and download links are preserved.

GitHub generates initial release notes from merged pull requests. Keep GitHub release descriptions in English. Before promoting a prerelease, edit its description into short, user-facing English patch notes and add a Polish translation to `site/release-notes.pl.json` under the exact release tag. Deploy Pages to publish that translation. Entries are displayed only when the corresponding release is stable and has an ARM64 APK; adding a translation early does not expose a prerelease.

The website never inserts the English release body into its Polish content. Missing translations produce a Polish message with a link to the English GitHub description. English release notes and Polish translations are maintained explicitly; there is no automatic translation service. Version, date, archive availability and APK links still refresh from GitHub without redeploying Pages.

Technical build details stay in the attached `BUILD.txt`. The large Android `versionCode` remains an internal increasing identifier, rather than the public release title. Avoid changing signing keys when changing version numbers.

## Updating an installation

Download a newer signed release APK and install it over the existing installation. Android preserves the app's database, downloaded models, and settings when the application ID and signing certificate match. No uninstallation or app-managed updater is required.

Older debug APKs may have different certificates and cannot be upgraded with this release key. Do not uninstall an old build if you need its local data; uninstalling removes private app storage. This setup establishes update compatibility between releases signed with the pinned key, not with every previous debug APK.

The application ID remains `bielik.ai.bielik_oneclick_launcher`. CI derives `versionCode` from UTC seconds since 2020-01-01, so newly started release builds get higher codes, including reruns of older source revisions. All branches share one release concurrency group. `versionName` comes from the workflow version input, falling back to `pubspec.yaml`. Local builds must also use a higher `--build-number` than the installed release.

## Signing identity

The public certificate SHA-256 is pinned in [android/release-signing.sha256](../android/release-signing.sha256). The workflow verifies the signed APK against it before uploading anything.

Repository Actions secrets:

| Secret | Contents |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded JKS keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Signing key alias |
| `ANDROID_KEY_PASSWORD` | Private key password |

The keystore is restored under the runner's temporary directory immediately before signing and removed afterwards, including after a failed build. Passwords are passed through step-scoped environment variables. Missing secrets fail the workflow; release builds never fall back to the debug key.

The initial private backup is in the local, Git-ignored `android/signing/` directory:

- `release.jks`: private signing keystore.
- `credentials.json`: its alias and password.

Keep an encrypted backup of both files outside the repository and development machine. GitHub does not return uploaded secret values. Do not regenerate or replace the signing key for routine releases: a different key breaks update compatibility. The public fingerprint is not a backup of the private key.

## Local signed builds

Provide these environment variables:

```text
ANDROID_KEYSTORE_PATH
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

Alternatively, create a private, Git-ignored `android/key.properties`:

```properties
storeFile=/absolute/path/to/release.jks
storePassword=your-keystore-password
keyAlias=your-key-alias
keyPassword=your-key-password
```

Environment variables take precedence. Relative `storeFile` paths are resolved from `android/`; use forward slashes or escaped backslashes on Windows.

```sh
flutter pub get --enforce-lockfile
flutter build apk --release --target-platform android-arm64 --build-number <higher-version-code>
```

Keep dependency resolution enabled for the release build. Flutter 3.47.9 regenerates its native plugin registrant for release mode during this step, excluding development-only plugins such as `integration_test`. The preceding `--enforce-lockfile` command checks the locked dependency set.

Output: `build/app/outputs/flutter-apk/app-release.apk`. Check its certificate with Android SDK `apksigner verify --verbose --print-certs` before distributing it. Debug/profile development builds do not require release credentials.

Platform reference: [Flutter Android signing and deployment](https://docs.flutter.dev/deployment/android).
