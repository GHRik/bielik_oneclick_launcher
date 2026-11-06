# Bielik OneClick Launcher

Aplikacja Flutter na Androida do pobierania modeli Bielik i uruchamiania ich lokalnie na telefonie. Obecny etap: działająca próba jednej odpowiedzi Bielika 1.5B oraz czat z historią w SQLite.

## Co już działa

- Wybór Bielika 1.5B lub 4.5B v3.0 Instruct w formacie GGUF Q8.
- Pobieranie przez `flutter_downloader`, postęp, prędkość, ETA i anulowanie. Odczyt zapisanych zadań po ponownym otwarciu aplikacji.
- Sprawdzanie rozmiaru i SHA-256 przed oznaczeniem modelu jako pobrany; usuwanie lokalnych plików modeli.
- Tworzenie i usuwanie rozmów z potwierdzeniem. Wiadomości i szkice pozostają w SQLite po zamknięciu aplikacji.
- Przybliżony rozmiar treści każdej rozmowy na liście.
- Osobny ekran próby: pobrany Bielik 1.5B odpowiada na jedno ustalone pytanie, po czym aplikacja zwalnia model z pamięci.

**Pełny czat nie generuje jeszcze odpowiedzi LLM.** Wykresy statystyk pokazują dane przykładowe, a dostępny RAM i miejsce na telefonie nie są jeszcze automatycznie odczytywane.

## Potwierdzony etap: jedna odpowiedź

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

## Uruchomienie

Potrzebny jest Flutter z Dartem zgodnym z `pubspec.yaml` (`^3.13.7`), Android SDK i telefon z Androidem. Dotychczasową próbę wykonano na ARM64.

```sh
flutter pub get
flutter devices
flutter run -d <identyfikator-telefonu>
```

W aplikacji wybierz **Bielik 1.5B v3.0 · Q8**, pobierz model, a następnie otwórz **Próba Bielika 1.5B → Wygeneruj odpowiedź**.

Pliki modeli pobiera użytkownik podczas działania aplikacji — nie są dołączone do APK. Wariant 1.5B zajmuje około 1,7 GB, a 4.5B około 5,06 GB; pamięć potrzebna do uruchomienia jest większa od samego pliku. Dotychczasowy test generowania dotyczy wyłącznie wariantu 1.5B.

## Kolejne plany

1. Podłączyć generowanie do istniejącego czatu: historia jako kontekst, odpowiedź wyświetlana fragmentami i zapisywana do SQLite.
2. Dodać zatrzymywanie generowania oraz bezpieczne ładowanie i przełączanie modeli.
3. Sprawdzić generowanie dla Bielika 4.5B i dobrać parametry do możliwości telefonu.
4. Odczytywać rzeczywisty RAM i wolne miejsce oraz podłączyć pomiary do wykresów.
5. Rozszerzyć testy pobierania i pracy LLM na urządzeniach, w tym zachowanie po przejściu aplikacji do tła.

## Struktura projektu

```text
lib/
├── main.dart                     # Inicjalizacja i wstrzykiwanie repozytoriów
└── src/
    ├── app.dart                  # Konfiguracja aplikacji
    ├── presentation/
    │   ├── pages/                # Ekrany: główny, czat, statystyki, próba modelu
    │   ├── controllers/          # Stan widoków
    │   ├── widgets/              # Elementy interfejsu
    │   ├── sidebars/             # Lista rozmów i jej elementy
    │   └── formatters/           # Formatowanie danych do wyświetlenia
    ├── domain/
    │   ├── models/               # Czyste modele Dart
    │   └── repositories/         # Kontrakty danych i operacji
    └── data/
        ├── datasources/          # SQLite, pliki, downloader, dane przykładowe
        └── repositories_impl/    # Implementacje kontraktów, w tym próba LLM

test/                             # Testy logiki, SQLite, widoków i architektury
```

Szczegóły zależności warstw i zapisu rozmów: [ARCHITECTURE.md](ARCHITECTURE.md).

## Weryfikacja

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub --target-platform android-arm64
```

Na etapie zapisanym w branchu przeszły analiza, 32 testy i build APK. Generowanie jednej odpowiedzi potwierdzono dodatkowo na telefonie.
