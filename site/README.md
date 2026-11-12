# Bielik OneClick landing page

A static landing page in `index.html` and `styles.css`. Open `index.html` in a browser; no build step is required. Documentation is in English; visitor-facing content is in Polish.

## Introduction and themes

The introduction presents one-click installation, local AI features, and offline chat after downloading a model. Its download link scrolls to the download section; the GitHub link opens the repository. A tilted phone plays `assets/chat-live.mp4`, with `chat-live-poster.jpg` as its poster. Feature tiles link to the text-selection, translation, TXT, update, and demo sections. The update tile explains that downloaded models and conversations are kept.

The dark palette uses warm charcoal, olive surfaces, sage accents, and cream text. Fraunces headings and Plus Jakarta Sans body text load from Google Fonts, with local fallbacks. Header buttons select light, dark, or high-contrast themes. `theme.js` saves the choice in local storage; screenshots and videos keep their original colors. Motion respects reduced-motion preferences. `generation-preview.js` controls the inline video and pauses it when it is not visible.

## Feature carousel

The HTML contains nine slides:

| Slide ID | Feature |
| --- | --- |
| `slide-ask` | Zapytaj Bielika |
| `slide-dictation` | Podyktuj i przetłumacz |
| `slide-actions` | Szybkie akcje |
| `slide-txt` | Załączniki TXT |
| `slide-chat` | Czat z Bielikiem |
| `slide-stats` | Statystyki urządzenia i modelu |
| `slide-models` | Pobieranie i wybór modelu |
| `slide-settings` | Konfiguracja modelu |
| `slide-updates` | Aktualizacje w aplikacji |

`carousel.js` supports horizontal swipes, trackpad scrolling, arrow buttons, dots, and keyboard arrows. There is no autoplay or play/pause button. Only the selected slide is interactive; without JavaScript, the descriptions remain available. Desktop arrows sit beside the dots below the slide; mobile arrows overlay the screen area. Dot colors progress through the page palette, and the active dot has a ring.

Screenshots sit beside descriptions on desktop and above them on phones. Red SVG overlays mark the relevant controls. `screenshot-zoom.js` opens a screenshot and its annotations in a modal dialog when clicked. Close it with its button, Escape, or the backdrop.

## Detailed walkthroughs

| Section ID | Heading and contents |
| --- | --- |
| `zapytaj-bielika` | **Twój tekst. Odpowiedź Bielika.** — select text, choose “Streść”, read the response |
| `tlumacz-tekst` | **Ten sam tekst. Inny język.** — choose “Przetłumacz”, select a language, check the result |
| `pliki-txt` | **Dodaj plik TXT i zapytaj Bielika o jego treść.** — add a file, open or translate it, check the translation |
| `aktualizacje-aplikacji` | **Nowa wersja bez szukania APK.** — check for an update, download/install it, see the changed version |

The text-selection menu depends on the source app. Dictation depends on the phone's speech service and may need internet access. The page explicitly asks visitors to verify generated translations against their sources. APK updates require internet and Android installation confirmation.

## Captures and preview assets

The page identifies the capture device as **OnePlus 15 (CPH2747)** running Android. It includes OpenCL recording frames, direct app captures, and an explicitly labelled dictation UI preview.

- `ask-selection-opencl.png`, `quick-actions-opencl.png`, `summary-opencl.png`, and `statistics-opencl.png` illustrate text selection, quick actions, chat, and statistics.
- `translate-language-opencl.png` and `translated-opencl.png` illustrate language choice and translation.
- `dictation-translate-android.png` is labelled “Podgląd interfejsu”; numbered annotations indicate the microphone and translation action.
- `txt-add-android.png`, `txt-attached-android.png`, and `txt-translated-android.png` show the TXT flow.
- `update-before-android.png`, `update-available-android.png`, and `update-after-android.png` show an actual update.
- `models-android.png` and `settings-android.png` show model management and configuration.

Keep screenshots authentic, review them for private content, and match image dimensions and SVG view boxes when replacing them. Do not describe the labelled UI preview as a device recording. Phone frames and decorations are CSS; hero excerpts crop existing screenshots.

## YouTube demos

The demo section embeds these films via `youtube-nocookie.com`:

| YouTube ID | Heading |
| --- | --- |
| `u4ovz4G72to` | Streszczanie — offline · GPU OpenCL |
| `GNGXWQAcr3Q` | Tłumaczenie — offline · GPU OpenCL |
| `3f2A8yVDN88` | Przegląd aplikacji — tryb samolotowy |
| `wXv1ux307sk` | Krótki czat — tryb samolotowy |

Players load lazily, do not autoplay, and include direct YouTube links. Keep their referrer policy so YouTube receives the embedding origin.

## Roadmap and other sections

**Plan rozwoju** appears after the demos. PDF support, iOS, and NPU acceleration are marked “W trakcie”. GPU acceleration currently carries the “50/50” status and the documented device-specific OpenCL results: OnePlus 15 and Pixel 8 Pro work, Samsung Galaxy S24+ does not; Vulkan is untested. This is not a claim of universal GPU compatibility.

**Rozwijaj z nami** links to the model contribution guide and the GitHub repository. Near the bottom, **Dołącz do testów zamkniętych w Google Play** explains the three steps: join https://groups.google.com/g/bielik-oneclick-testers, confirm participation at https://play.google.com/apps/testing/bielik.ai using the same Play Store account, and install the app. The download section links to these instructions; email remains available for help. **O mnie** introduces Damian Panasiuk with a portrait and LinkedIn link. Attribution identifies the launcher as independent and credits the model creators. The footer links to the Polish [privacy policy](privacy.html), including Google Play internal-testing data and contact details.

## Downloads and release notes

The primary APK link remains GitHub's stable `/releases/latest/download/bielik-arm64.apk` URL. Models are downloaded separately inside the app.

`release-info.js` fetches version, publication date, and stable release availability from GitHub. Polish patch notes come from `release-notes.pl.json`, using an exact tag or version key. **Co nowego?** shows the latest stable release; **Archiwalne wersje APK** lists older stable APKs, excluding the current release, drafts, and prereleases. Translations require a Pages deployment; release metadata updates independently.

The APK workflow always creates a prerelease. Promotion to Latest is manual; see [RELEASING.md](../docs/RELEASING.md). A Pages deployment does not build the Android app or promote a release.

## Deploy to GitHub Pages

1. Set **Settings → Pages → Build and deployment → Source** to **GitHub Actions**.
2. Push to `master`, or run **Deploy GitHub Pages** manually.
3. The workflow publishes only `site/` at [ghrik.github.io/bielik_oneclick_launcher](https://ghrik.github.io/bielik_oneclick_launcher/).

Keep private drafts and local preview artifacts outside the published directory.
