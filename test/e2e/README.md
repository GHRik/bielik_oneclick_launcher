# Android end-to-end

Trzy wykonywalne scenariusze z rzeczywistym SQLite, plikami, `flutter_downloader` i silnikiem CPU. Nie korzystają z atrap repozytoriów ani modelu. Weryfikacja na urządzeniu jest oddzielna od analizy kodu i zbudowania APK.

## Izolacja

Runner zawsze buduje aplikację z `BIELIK_E2E=true`. Gradle nadaje jej osobny identyfikator `bielik.ai.bielik_oneclick_launcher.e2e`. Test dodatkowo sprawdza ścieżkę prywatnego katalogu aplikacji przed otwarciem bazy i downloadera. Zwykła aplikacja zachowuje dotychczasowy identyfikator i dane.

Używany jest pierwszy model z katalogu aplikacji: Bielik 1.5B Q8, około 1,7 GB. Potrzebne są sieć, miejsce na plik tymczasowy i RAM do uruchomienia modelu. Profil E2E używa CPU, kontekstu 512, maksymalnie 32 tokenów odpowiedzi i dwóch wątków. Odpowiedź musi być niepusta i widoczna w UI; nie wymagamy identycznej treści.

## Scenariusze

| Plik | Sprawdzane zachowanie |
| --- | --- |
| `android/model_lifecycle_scenario.dart` | Pobranie przez UI, potwierdzenie wymagań, rzeczywisty transfer, gotowość, niezależne sprawdzenie rozmiaru i SHA; później usunięcie przez UI oraz brak pliku, części i zadania |
| `android/cpu_generation_scenario.dart` | Nowa rozmowa przez UI, rzeczywista odpowiedź CPU ze streama, widoczny tekst i zapis odpowiedzi w SQLite |
| `android/chat_persistence_scenario.dart` | Wysłanie pytania, odpowiedź i szkic; ponowny start w innym procesie, odtworzenie tej samej rozmowy i tekstów; anulowanie usunięcia oraz potwierdzone usunięcie |

Pełny przebieg składa się z pięciu faz: `download → cpu → create → verify → delete`. Model jest pobierany raz i współdzielony przez fazy, a na końcu usuwany. Po każdej fazie runner wykonuje `adb shell am force-stop` wyłącznie dla aplikacji E2E. Faza `verify` sprawdza również, czy PID różni się od zapisanego przed restartem.

## Uruchamianie

Z głównego katalogu projektu, z Flutter SDK i ADB:

```sh
flutter pub get
dart run test/e2e/run_android_e2e.dart --device <android-serial> --scenario all
```

Dostępne zestawy: `all`, `model`, `cpu`, `chat`. Każdy przygotowuje model przez rzeczywiste pobranie i kończy jego usunięciem. Można pominąć `--device`, jeżeli Flutter widzi dokładnie jednego Androida.

Jeżeli ADB lub Flutter nie są dostępne w PATH:

```sh
dart run test/e2e/run_android_e2e.dart --scenario all --adb <path-to-adb> --flutter <path-to-flutter>
```

Runner używa `flutter drive --keep-app-running` z jawnym celem i hostowym driverem. Flaga zapobiega domyślnemu odinstalowaniu aplikacji przez Flutter Driver; proces zatrzymuje runner, zachowując bazę i pliki pomiędzy fazami. Nie uruchamiaj osobno faz z ręcznie zmienianym identyfikatorem aplikacji. Pliki `*_scenario.dart` nie są wykrywane przez zwykłe `flutter test`, więc lokalne UT i workflow APK pozostają oddzielne.

Uruchomienie buduje i instaluje oddzielny APK E2E. Model, baza i rozmowy testowe należą do aplikacji E2E; nie wykonujemy `pm clear`, odinstalowania ani czyszczenia danych zwykłej aplikacji.

## Wyniki

Artefakty trafiają do [output/android](output/android/README.md):

```text
<run-id>_<suite>/
├── report.json
├── devices.json
├── download/
│   ├── flutter.log
│   ├── logcat.txt
│   └── device-report.json
├── cpu/
├── create/
├── verify/
└── delete/
```

Przy błędzie test próbuje zapisać zrzut do `<phase>/screenshots/`. Jeżeli aplikacja nie uruchomi się lub proces ulegnie awarii, raport może nie zawierać zrzutu ani odpowiedzi urządzenia. Logcat jest filtrowany po UID aplikacji E2E.

Status całości jest `passed` tylko wtedy, gdy wszystkie fazy zwrócą sukces, raport z urządzenia zawiera `passed`, a zatrzymanie aplikacji powiedzie się. Brak Androida daje `blocked` i kod wyjścia 2; błąd testu daje `failed` i kod 1. Raport jest zapisywany także wtedy, gdy nie da się rozpocząć testów.

Limity: każda faza ma limit hosta 40 minut, samo pobieranie 30 minut, a generowanie odpowiedzi 10 minut. Wygenerowane artefakty są ignorowane przez Git. Testy uruchamiamy ręcznie; nie są podpięte do automatycznego workflow.

Framework: [Flutter integration_test](https://github.com/flutter/flutter/tree/master/packages/integration_test).
