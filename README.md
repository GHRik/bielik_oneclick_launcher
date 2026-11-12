# Bielik OneClick Launcher

Run **Bielik** on your Android phone — download a GGUF in the app, chat offline, tune inference, and watch live stats.

| | |
| --- | --- |
| **[Download APK (ARM64)](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest/download/bielik-arm64.apk)** [![Version](https://img.shields.io/github/v/release/GHRik/bielik_oneclick_launcher?sort=date&label=version)](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest) [![Release date](https://img.shields.io/github/release-date/GHRik/bielik_oneclick_launcher?label=released)](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest) | [![Dołącz do zamkniętych testów Google Play!](https://img.shields.io/badge/Do%C5%82%C4%85cz_do_zamkni%C4%99tych_test%C3%B3w_Google_Play%21-34A853?style=for-the-badge&logo=googleplay&logoColor=white)](mailto:damian.panasiuk.console@gmail.com?subject=Bielik%20OneClick%20%E2%80%93%20pro%C5%9Bba%20o%20dodanie%20do%20test%C3%B3w%20zamkni%C4%99tych&body=Cze%C5%9B%C4%87%2C%0Achc%C4%99%20do%C5%82%C4%85czy%C4%87%20do%20test%C3%B3w%20zamkni%C4%99tych%20Bielik%20OneClick%20w%20Google%20Play.%0A%0AAdres%20e-mail%20konta%20Google%20u%C5%BCywanego%20w%20Sklepie%20Play%3A%0AModel%20telefonu%3A%0AWersja%20Androida%3A%0A%0AWiem%2C%20%C5%BCe%20m%C3%B3j%20adres%20zostanie%20u%C5%BCyty%20tylko%20do%20dodania%20mnie%20do%20listy%20tester%C3%B3w.) · [All releases](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest) |
| [Polish overview](https://ghrik.github.io/bielik_oneclick_launcher/) | [YouTube demo](https://www.youtube.com/shorts/3f2A8yVDN88) |

## Install

[![Dołącz do zamkniętych testów Google Play!](https://img.shields.io/badge/Do%C5%82%C4%85cz_do_zamkni%C4%99tych_test%C3%B3w_Google_Play%21-34A853?style=for-the-badge&logo=googleplay&logoColor=white)](mailto:damian.panasiuk.console@gmail.com?subject=Bielik%20OneClick%20%E2%80%93%20pro%C5%9Bba%20o%20dodanie%20do%20test%C3%B3w%20zamkni%C4%99tych&body=Cze%C5%9B%C4%87%2C%0Achc%C4%99%20do%C5%82%C4%85czy%C4%87%20do%20test%C3%B3w%20zamkni%C4%99tych%20Bielik%20OneClick%20w%20Google%20Play.%0A%0AAdres%20e-mail%20konta%20Google%20u%C5%BCywanego%20w%20Sklepie%20Play%3A%0AModel%20telefonu%3A%0AWersja%20Androida%3A%0A%0AWiem%2C%20%C5%BCe%20m%C3%B3j%20adres%20zostanie%20u%C5%BCyty%20tylko%20do%20dodania%20mnie%20do%20listy%20tester%C3%B3w.)

Closed testing on Google Play — public release planned for December 2026. Tap the badge to request access by e-mail (damian.panasiuk.console@gmail.com); use the address of your Google Play account. Until then, install via APK.

1. [Download the latest APK](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest/download/bielik-arm64.apk) (ARM64) [![Version](https://img.shields.io/github/v/release/GHRik/bielik_oneclick_launcher?sort=date&label=version)](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest) [![Release date](https://img.shields.io/github/release-date/GHRik/bielik_oneclick_launcher?label=released)](https://github.com/GHRik/bielik_oneclick_launcher/releases/latest)
2. Install on your phone (allow installs from your browser or file manager if asked).
3. Open the app → choose a model → download → chat.

No Flutter or Android Studio required. Weights download inside the app (~1.7 GB for 1.5B, ~5 GB for 4.5B).

| Model | Download | Free RAM (estimate) |
| --- | --- | --- |
| Bielik 1.5B v3.0 Instruct · Q8_0 | ~1.7 GB | 4 GB |
| Bielik 4.5B v3.0 Instruct · Q8_0 | ~5.06 GB | 8 GB |

Install a newer signed release over the old one to keep chats and models. See [releases and updates](docs/RELEASING.md).

**CPU** is the default. **OpenCL** on GPU has been tested on OnePlus 15 (CPH2747) and Pixel 8 Pro. GPU inference does **not** work on Samsung Galaxy S24+. **Vulkan** has not been tested.

## Build & contribute

Flutter **3.47.9**, Android SDK, USB debugging:

```sh
git clone https://github.com/GHRik/bielik_oneclick_launcher.git
cd bielik_oneclick_launcher && flutter pub get && flutter run
```

Everything else (catalog, layout, CI, adding models): **[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)** · [ARCHITECTURE.md](ARCHITECTURE.md) · [test/README.md](test/README.md)

## License and models

Launcher: [MIT](LICENSE). **Bielik** weights are by SpeakLeash / ACK Cyfronet AGH — [1.5B](https://huggingface.co/speakleash/Bielik-1.5B-v3.0-Instruct-GGUF), [4.5B](https://huggingface.co/speakleash/Bielik-4.5B-v3.0-Instruct-GGUF).
