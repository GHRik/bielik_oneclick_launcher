# Android APK releases and updates

## Publish a build

Open **Actions → Release APK → Run workflow**, select the branch, and run it. The workflow analyzes the code, runs local Flutter tests, builds a signed ARM64 release APK, verifies its certificate, and always creates a GitHub prerelease, including builds from `master`. It never changes Latest automatically.

Testers can download the APK from that prerelease's assets. Prereleases are publicly visible in Releases, but the README and GitHub Pages download links continue to point to the latest stable release. The landing page's version and date also come from the latest stable release.

After testing, edit the chosen release on GitHub, remove its prerelease flag, and mark it as **Latest**. Alternatively:

```sh
gh release edit <release-tag> --prerelease=false --latest
```

Promoting the existing release keeps the exact APK that was tested; no rebuild or Pages redeployment is needed for the download links to change. Metadata and badges may take time to refresh because of caching.

Download `bielik-arm64.apk` directly from [the latest stable release](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest/download/bielik-arm64.apk), or use **Releases → Assets**. Keep the asset name unchanged: the landing page uses GitHub's permanent latest-asset URL. Each release also includes its SHA-256 checksum, `BUILD.txt`, `SIGNING.txt`, and the MIT license. An artifact copy is retained for 30 days. The ARM64 debug build workflow is a separate CI check; use Release APK for distribution.

## Updating an installation

Download a newer signed release APK and install it over the existing installation. Android preserves the app's database, downloaded models, and settings when the application ID and signing certificate match. No uninstallation or app-managed updater is required.

Older debug APKs may have different certificates and cannot be upgraded with this release key. Do not uninstall an old build if you need its local data; uninstalling removes private app storage. This setup establishes update compatibility between releases signed with the pinned key, not with every previous debug APK.

The application ID remains `bielik.ai.bielik_oneclick_launcher`. CI derives `versionCode` from UTC seconds since 2020-01-01, so newly started release builds get higher codes, including reruns of older source revisions. All branches share one release concurrency group. `versionName` comes from `pubspec.yaml`. Local builds must also use a higher `--build-number` than the installed release.

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
