# Bielik OneClick Launcher

Run **Bielik** on your Android phone — download a GGUF in the app, chat offline, tune inference, and watch live stats.

| | |
| --- | --- |
| **[Download APK (ARM64)](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest/download/bielik-arm64.apk)** | [All releases](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest) |
| [Polish overview](https://ghrik.github.io/bielik_oneclick_launcher/) | [YouTube demo](https://www.youtube.com/shorts/5ruxjgcFAZc) |

## Install

1. [Download the latest APK](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest/download/bielik-arm64.apk) (ARM64).
2. Install on your phone (allow installs from your browser or file manager if asked).
3. Open the app → choose a model → download → chat.

No Flutter or Android Studio required. Weights download inside the app (~1.7 GB for 1.5B, ~5 GB for 4.5B).

| Model | Download | Free RAM (estimate) |
| --- | --- | --- |
| Bielik 1.5B v3.0 Instruct · Q8_0 | ~1.7 GB | 4 GB |
| Bielik 4.5B v3.0 Instruct · Q8_0 | ~5.06 GB | 8 GB |

Install a newer signed release over the old one to keep chats and models. See [releases and updates](docs/RELEASING.md).

**CPU** inference is the default. **GPU** (Vulkan / OpenCL) is experimental — use CPU in production.

## Build & contribute

Flutter **3.47.9**, Android SDK, USB debugging:

```sh
git clone https://github.com/GHRik/bielik_oneclick_launcher.git
cd bielik_oneclick_launcher && flutter pub get && flutter run
```

Everything else (catalog, layout, CI, adding models): **[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)** · [ARCHITECTURE.md](ARCHITECTURE.md) · [test/README.md](test/README.md)

## License and models

Launcher: [MIT](LICENSE). **Bielik** weights are by SpeakLeash / ACK Cyfronet AGH — [1.5B](https://huggingface.co/speakleash/Bielik-1.5B-v3.0-Instruct-GGUF), [4.5B](https://huggingface.co/speakleash/Bielik-4.5B-v3.0-Instruct-GGUF).
