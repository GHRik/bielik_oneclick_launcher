# Bielik OneClick landing page

A static Polish landing page in `index.html` and `styles.css`. Open `index.html` in a browser to preview it; no dependencies or build step are required. Keep the public page copy in Polish.

## Visual palette

Colors are adapted from [bielik.ai](https://www.bielik.ai/): paper `#FFF9F5`, coral `#F66953`, deep coral `#B8371E`, ink `#25251E`, and dark olive `#424237`. Deep coral is used for readable text accents; coral buttons use dark text. The layout and independent launcher identity remain specific to this project.

## Content

The page presents the current Android app: local chat, model download and resource checks, live statistics, and configurable LLM parameters. Android GPU inference is labeled experimental.

The roadmap is limited to an iOS version with GPU acceleration. Desktop support and in-app model importing are not advertised as planned features.

The model section lists both bundled catalog entries and links to the root README's `#adding-models` instructions. Adding a model means editing `lib/configuration/bielik_models.dart` and rebuilding the APK, not importing a file through the UI.

Attribution near the top and bottom credits SpeakLeash (Spichlerz) and ACK Cyfronet AGH, identifies OneClick as an independent launcher, and links to the official model cards and licenses.

The favicon and page brand mark use the launcher's original eagle artwork, not the official Bielik logo. Source artwork and Android icon variants are documented in [assets/branding](../assets/branding/README.md).

## Real device screenshots

| File | Screen |
| --- | --- |
| `assets/chat-android.png` | Actual Bielik 1.5B CPU response in chat |
| `assets/models-android.png` | Model selection, download controls, RAM and storage readings |
| `assets/statistics-android.png` | Live resource charts from the device |
| `assets/settings-android.png` | Context, response, and performance settings |

These are direct captures from a CPH2747 running Android 16, using a profile build of the app. The conversation uses a synthetic prompt. Screen contents are not reconstructed or retouched; the phone frames and background decorations are CSS.

To refresh the captures, run the current app on an Android device, open the relevant screen, and capture it as PNG. Keep the full portrait screenshot and update the HTML dimensions if its resolution differs from 1272 × 2772. Review every capture for private content before publishing. Update the device caption when using a different phone.

Static screenshots are used instead of animated GIFs to keep the page light and readable. All asset paths are relative for GitHub Pages repository hosting.

## Downloads

Download buttons link to the releases list because the APK workflow publishes prereleases without marking them as latest. The page explains that the APK is a test build for Android ARM64 and models are downloaded separately.

## Deploy to GitHub Pages

1. Open **Settings → Pages → Build and deployment → Source → GitHub Actions** in the repository.
2. Push a change under `site/` to `master`.
3. The workflow publishes only `site/` and runs only for changes under that directory. Changes to app code, root documentation, or workflow files do not trigger deployment.
4. The default URL is [ghrik.github.io/bielik_oneclick_launcher](https://ghrik.github.io/bielik_oneclick_launcher/), available after a successful deployment.

Deploying the page does not require rebuilding the Android app.
