# Bielik OneClick Launcher

Aplikacja Flutter na Androida do pobierania modeli Bielik i uruchamiania ich lokalnie na telefonie. Lokalny czat generuje odpowiedzi fragmentami i zapisuje rozmowy w SQLite.

[![Code Quality](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/code-quality.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/code-quality.yml)
[![Unit Tests](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/unit-tests.yml/badge.svg?branch=master)](https://github.com/GHRik/bielik_oneclick_launcher/actions/workflows/unit-tests.yml)

**[Pobierz APK na telefon](https://github.com/GHRik/bielik_oneclick_launcher/releases)**, zainstaluj i uruchom. Bez Fluttera i Android Studio.

## Co już działa

- Wybór Bielika 1.5B lub 4.5B v3.0 Instruct w formacie GGUF Q8.
- Pobieranie przez `flutter_downloader`, postęp, prędkość, ETA i anulowanie. Odczyt zapisanych zadań po ponownym otwarciu aplikacji.
- Sprawdzanie rozmiaru i SHA-256 przed oznaczeniem modelu jako pobrany; usuwanie lokalnych plików modeli.
- Tworzenie i usuwanie rozmów z potwierdzeniem. Wiadomości i szkice pozostają w SQLite po zamknięciu aplikacji.
- Przybliżony rozmiar treści każdej rozmowy na liście.
- Odpowiedzi LLM w czacie przez `llamadart` / `llama.cpp`: strumieniowanie, historia jako kontekst i zatrzymywanie generowania.
- Wybrany na ekranie głównym model jest ładowany przy pierwszej wiadomości. Wyjście z czatu lub przejście aplikacji do tła zatrzymuje generowanie i zwalnia model.
- Częściowa odpowiedź jest zapisywana także po zatrzymaniu generowania.

RAM i wolne miejsce są odczytywane z Androida i porównywane z wymaganiami modelu. Statystyki zbierają historię ostatnich 60 sekund: RAM i CPU aplikacji, użycie całego GPU telefonu, temperatury CPU/GPU/baterii dostępne w systemie oraz rzeczywiste metryki LLM. Odczyty GPU zależą od sterownika i uprawnień Androida; brak dostępu jest pokazywany jako „Brak danych”. Prędkość i liczba tokenów aktualizują się po raporcie silnika na końcu odpowiedzi. Temperatura CPU może być niedostępna; temperatura baterii jest pokazywana osobno. Pomiary pozostają tylko w pamięci bieżącej sesji.

## Archiwalny etap: jedna odpowiedź

Integracja `llamadart` / `llama.cpp` została sprawdzona na fizycznym telefonie CPH2747 z Androidem 16 (ARM64). Próba korzysta z CPU, kontekstu 512 tokenów i limitu odpowiedzi 64 tokenów.

Pytanie:

> Odpowiedz jednym krótkim zdaniem po polsku: czym jest sztuczna inteligencja?

Uzyskana odpowiedź:

> Sztuczna inteligencja to dziedzina nauki zajmująca się tworzeniem maszyn i systemów, które mogą wykonywać zadania wymagające inteligencji ludzkiej.

Branch **`Bielik1-5-one-generation-test-done`** zachowuje ten etap razem z dokumentacją. Aby do niego wrócić:

```sh
git fetch origin
git switch Bielik1-5-one-generation-test-done
```

Powrót do dalszego rozwoju:

```sh
git switch master
```

## Instalacja na telefonie

Wystarczy pobrać APK na telefon z Androidem, zainstalować je i otworzyć aplikację. Flutter i Android Studio nie są potrzebne.

1. Otwórz [wydania z APK](https://github.com/GHRik/bielik_oneclick_launcher/releases).
2. W wybranym wydaniu rozwiń **Assets** i pobierz plik `bielik-arm64-….apk`.
3. Otwórz plik na telefonie. Jeśli Android o to poprosi, zezwól przeglądarce lub menedżerowi plików na instalację aplikacji.
4. Uruchom Bielika, wybierz **Bielik 1.5B v3.0 · Q8** i pobierz model.
5. Naciśnij **Otwórz czat** i wyślij wiadomość. Przycisk **Zatrzymaj** kończy bieżącą odpowiedź.

Czat używa kontekstu 2048 tokenów i limitu odpowiedzi 512 tokenów. Do modelu trafia najnowsza historia mieszcząca się w tym limicie; pełna historia pozostaje w SQLite. Starsze wydania APK, w tym branch archiwalny, zachowują ekran próby zamiast pełnego czatu.

APK jest wersją testową `debug` dla telefonów ARM64. Podpis instalacji z GitHub Actions może różnić się od lokalnej wersji developerskiej i między buildami CI; stałe podpisywanie aktualizacji jest kolejnym krokiem.

## Ręczne generowanie APK

Na GitHubie otwórz **Actions → Build Android APK → Run workflow**, wybierz branch i uruchom workflow. Działa wyłącznie na żądanie.

Workflow sprawdza kod i testy, buduje APK z dokładnego commita wybranego brancha i publikuje je jako testowe wydanie w **Releases**. Dołącza sumę SHA-256 oraz plik `BUILD.txt` z identyfikatorem commita. Kopia plików jest też dostępna przez 30 dni jako artefakt uruchomienia. Pliki APK nie trafiają do historii kodu.

Konfiguracja: [.github/workflows/build-apk.yml](.github/workflows/build-apk.yml). Używana wersja Fluttera: **3.47.9**.

## Uruchomienie ze źródeł

Dla programistów: potrzebny jest Flutter z Dartem zgodnym z `pubspec.yaml` (`^3.13.7`), Android SDK i telefon z Androidem.

```sh
flutter pub get
flutter devices
flutter run -d <identyfikator-telefonu>
```

Pliki modeli pobiera użytkownik podczas działania aplikacji — nie są dołączone do APK. Wariant 1.5B zajmuje około 1,7 GB, a 4.5B około 5,06 GB; pamięć potrzebna do uruchomienia jest większa od samego pliku. Dotychczasowy test generowania dotyczy wyłącznie wariantu 1.5B.

## Modele i ustawienia LLM

Pliki edytowane przy dodawaniu modeli są w `lib/configuration/`, obok `main.dart`:

- [bielik_models.dart](lib/configuration/bielik_models.dart) — lista modeli w interfejsie: nazwa, adres GGUF, nazwa pliku, dokładny rozmiar w bajtach, SHA-256 oraz wymagania RAM i miejsca.
- [llm_configuration.dart](lib/configuration/llm_configuration.dart) — wspólne ustawienia silnika: wątki CPU, kontekst, limit odpowiedzi, batch, temperatura i parametry losowania.

Aby dodać model, dopisz `BielikModel` do `bielikModels`, z własną nazwą pliku GGUF i jego prawidłowymi metadanymi. Model musi być obsługiwany przez używany silnik llama.cpp. Lista na ekranie głównym korzysta bezpośrednio z tego katalogu.

Jeśli model wymaga innych parametrów, dodaj wpis do `modelLlmConfigurations` w pliku konfiguracji LLM. Kluczem jest dokładna wartość `ModelFile.name`, np.:

```dart
final modelLlmConfigurations = <String, LlmConfiguration>{
  'Bielik-4.5B-v3.0-Instruct.Q8_0.gguf':
      defaultLlmConfiguration.copyWith(numberOfThreads: 4, contextSize: 2048),
};
```

Brak wpisu oznacza użycie `defaultLlmConfiguration`. Domyślna ścieżka CPU używa 4 wątków, kontekstu 2048 i odpowiedzi do 512 tokenów. Eksperymentalna akceleracja ma osobny adapter GPU z wyborem Vulkan/OpenCL, limitem warstw, mikropartią i Flash Attention. GPU jest wyłączone po każdym restarcie aplikacji; jego ustawienia działają tylko w bieżącej sesji po zapisaniu formularza. CPU oraz GPU mają osobne instancje silnika, a zmiana trybu zwalnia poprzednią. Błąd GPU nie uruchamia automatycznej próby CPU. Ta integracja GPU nie została zweryfikowana na telefonie; wcześniejsze próby dawały błędny tekst. Statystyki GPU są niezależnymi odczytami telefonu.

Zębatka na ekranie głównym otwiera konfigurację LLM. Przycisk „Zapisz” sprawdza wartości i zapisuje wspólne ustawienia CPU oraz generowania w SQLite. Obowiązują przy kolejnym otwarciu czatu i pozostają po restarcie aplikacji. Powrót bez zapisu odrzuca edycję. Zapisany profil ma pierwszeństwo przed konfiguracją z plików; przed pierwszym zapisem działają profile z `lib/configuration/`.

## Kolejne plany

1. Sprawdzić generowanie dla Bielika 4.5B i dobrać parametry do możliwości telefonu.
2. Porównać wydajność CPU i opcjonalnej akceleracji GPU na rzeczywistych urządzeniach.
3. Rozszerzyć testy pobierania i pracy LLM na różnych urządzeniach.
4. Dodać stałe podpisywanie APK do wygodnych aktualizacji.

## Struktura projektu

```text
lib/
├── main.dart                     # Inicjalizacja i wstrzykiwanie repozytoriów
├── configuration/
│   ├── bielik_models.dart         # Katalog modeli do pobrania
│   └── llm_configuration.dart     # Domyślne i indywidualne parametry LLM
└── src/
    ├── app.dart                  # Konfiguracja aplikacji
    ├── presentation/
    │   ├── pages/                # Ekrany: główny, czat, statystyki
    │   ├── controllers/          # Stan widoków
    │   ├── widgets/              # Elementy interfejsu
    │   ├── sidebars/             # Lista rozmów i jej elementy
    │   └── formatters/           # Formatowanie danych do wyświetlenia
    ├── domain/
    │   ├── models/               # Czyste modele Dart
    │   ├── repositories/         # Kontrakty danych i operacji
    │   └── services/             # Wysyłanie, zapis odpowiedzi i polityka kontekstu
    └── data/
        ├── datasources/          # SQLite, pliki, downloader, dane przykładowe
        └── repositories_impl/    # Implementacje kontraktów, w tym silnik LLM

test/                             # Testy logiki, SQLite, widoków i architektury
```

Szczegóły zależności warstw i zapisu rozmów: [ARCHITECTURE.md](ARCHITECTURE.md).
Podział testów, zakres funkcjonalności i polecenia uruchomienia: [test/README.md](test/README.md).

## CI/CD

Każdy workflow ma osobny status powyżej. Kliknięcie badge'a otwiera jego historię uruchomień.

| Workflow | Zakres |
| --- | --- |
| [Code Quality](.github/workflows/code-quality.yml) | Formatowanie Dart i analiza statyczna. |
| [Unit Tests](.github/workflows/unit-tests.yml) | UT klas przez rejestr `test/ut_test.dart`. |

Automatyczne CI działa na pull requestach do `master` i pushach na `master`, tylko gdy zmieniają się źródła aplikacji, testy, zasoby, zależności lub konfiguracja analizy. Zmiany samych README, dokumentacji, strony `site/` lub plików `.github/` nie uruchamiają tych sprawdzeń. Każdy workflow można też uruchomić ręcznie z Actions.

Raporty testów JSON i logi są dostępne przez 14 dni w artefaktach danego uruchomienia. E2E Androida pozostają ręczne i nie są wykonywane przez GitHub Actions. Osobny workflow Pages obsługuje publikację strony.

Workflowów pomijanych przez filtry ścieżek nie należy ustawiać jako bezwarunkowo wymaganych sprawdzeń: PR zmieniający samą dokumentację mógłby czekać na ich wynik bez końca. Szczegóły: [GitHub — pomijane workflowy](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs).

## Weryfikacja lokalna

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub --target-platform android-arm64
```
