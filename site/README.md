# Bielik OneClick landing page

A static Polish landing page in `index.html` and `styles.css`. Open `index.html` in a browser to preview it; no dependencies or build step are required. Keep the public page copy in Polish.

## Feature carousel

Four slides pair a real screenshot with a plain feature description: chat, model downloads, statistics, and settings. `carousel.js` advances every seven seconds while visible. A horizontal scroll-snap slider supports touch swipes and trackpad scrolling alongside arrows, dots, and keyboard navigation; manual selection pauses rotation. Only the selected slide is interactive. All slides share the tallest slide's height, with aligned screenshot and caption rows on phones. The track scrolls horizontally only, while vertical gestures scroll the page rather than the content inside a slide. Screenshots are up to 300px wide on desktop and 260px on phones. Hover, keyboard focus, and a hidden tab suspend rotation. Round 48px arrow and pause/resume icon buttons sit above a separate row of 44px dot targets, and reduced-motion preferences disable automatic rotation initially. Without JavaScript, all feature descriptions remain visible. Screenshots sit beside descriptions on desktop and above them on phones.

## Visual palette

The Organic Tech variant uses warm charcoal `#151613`, olive surfaces `#1C211A`, muted sage accents `#9EAF87`, and cream text. The light theme retains its warm terracotta accents. Fraunces headings and Plus Jakarta Sans body text load from Google Fonts with local serif/sans-serif fallbacks; technical data uses system monospace. The centered introduction uses a three-line heading (Bielik, Edge-AI, One Click). A larger phone preview, tilted 4° clockwise, sits over a muted terminal, with subtle feather-like vector lines behind it. Motion respects reduced-motion preferences.

## Color themes

Three round header buttons (sun, moon, half-filled circle) select light, dark (Organic Tech), and high-contrast themes. Accessible names, tooltips, and pressed states identify each option. `theme.js` applies the saved choice before the stylesheet loads and stores changes in local storage. Without a saved choice, dark is used unless the visitor requests increased contrast. Storage failures do not prevent switching themes. Screenshots and embedded YouTube content retain their own colors.

## Page navigation

The introduction has one download button and a demo link. Installation steps appear as a horizontal timeline in the download section instead of repeating navigation in the introduction.

## Content

The page presents the current Android app: local chat, model download and resource checks, live statistics, and configurable LLM parameters. Android GPU inference is labeled experimental.

The roadmap sits below the YouTube demo. An icon row marks Android and CPU as available with checkmarks, GPU as experimental with a laboratory flask, and iOS as ongoing. The future platform scope is limited to iOS with GPU acceleration. Desktop support and in-app model importing are not advertised as planned features.

Feature captions use short phrases. The model section names both bundled models and links to the root README's `#adding-models` instructions. Adding a model means editing `lib/configuration/bielik_models.dart` and rebuilding the APK, not importing a file through the UI.

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

The carousel uses static screenshots. The introduction plays `assets/chat-live.mp4`: a short, silent edit of a real Android screen recording captured on 8 November 2026. It shows entering a question, sending it, the “Bielik pisze…” indicator, and the streamed response. Idle gaps between input actions are cut, and the footage is sped up to 1.25× for a shorter preview (about nine seconds), with no reconstructed messages or simulated typing. The release build has no DEBUG ribbon, and the crop excludes system bars. H.264 encoding at 392 × 760 and 25 fps keeps it smaller than a GIF. `chat-live-poster.jpg` provides a still frame. `generation-preview.js` loops playback only while visible, pauses in background tabs, respects reduced-motion preferences, and lets visitors click the video or press Enter/Space while it is focused to play or pause. There is no caption or separate playback button beneath the recording. All asset paths are relative for GitHub Pages repository hosting.

## Video demo

The section before downloads embeds YouTube Shorts `5ruxjgcFAZc` in a responsive 9:16 player. It uses `youtube-nocookie.com`, loads lazily, and does not autoplay. Playback starts with the visitor's Play click; a separate YouTube link is available if embedding is blocked. Keep the iframe referrer policy so YouTube receives the embedding origin.

## Downloads

The header and hero download buttons scroll to the download section. Only that section's APK button links directly to `/releases/latest/download/bielik-arm64.apk`. The release workflow keeps this asset name fixed, marks `master` builds as Latest, and leaves other branches as prereleases. The two prominent “Rozwijaj z nami!” buttons open the source repository. Models are downloaded separately inside the app.

`release-info.js` fetches the latest stable release from GitHub's public API and displays its Android version code and publication date in Polish under the APK button. This updates without redeploying Pages. If the request fails or is rate-limited, a link to release details remains visible and downloading still works.

## Deploy to GitHub Pages

1. Open **Settings → Pages → Build and deployment → Source → GitHub Actions** in the repository.
2. Push any commit to `master`, or start **Deploy GitHub Pages** manually from Actions.
3. The workflow runs on every push to `master` and publishes only `site/`. Keep the Pages publishing source set to **GitHub Actions**, not a branch's root directory; the root README is not the landing page.
4. The default URL is [ghrik.github.io/bielik_oneclick_launcher](https://ghrik.github.io/bielik_oneclick_launcher/), available after a successful deployment.

Deploying the page does not require rebuilding the Android app.
