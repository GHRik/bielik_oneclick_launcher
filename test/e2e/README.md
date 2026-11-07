# Android end-to-end

Szkielet rzadko uruchamianych testów pełnej aplikacji na Androidzie, oparty na Flutter `integration_test`.

```text
test/e2e/
├── android/
│   ├── chat_persistence_scenario.dart
│   ├── model_lifecycle_scenario.dart
│   ├── cpu_generation_scenario.dart
│   └── support/
│       ├── pending_scenario.dart
│       └── driver.dart
└── output/
    └── android/
        └── README.md
```

Pliki mają końcówkę `_scenario.dart`, dzięki czemu zwykłe `flutter test` nie wykrywa E2E i nie inicjalizuje ich wiązania urządzenia.

## Stan

**Wszystkie trzy scenariusze są obecnie pomijane przez `skip: true`.** To struktura do dalszej implementacji, nie gotowe testy E2E. Pusty scenariusz rzuci `UnimplementedError`, jeśli ktoś usunie pomijanie przed dopisaniem kroków. Pominięcie nie potwierdza działania funkcji.

| Plik | Scenariusz | Limit |
| --- | --- | --- |
| `android/chat_persistence_scenario.dart` | Utworzenie rozmowy, wysłanie i zapis wiadomości, rzeczywisty restart aplikacji, odtworzenie danych, usunięcie z potwierdzeniem | 3 min |
| `android/model_lifecycle_scenario.dart` | Pobranie modelu przez rzeczywisty downloader, gotowość po weryfikacji, usunięcie pliku | 30 min |
| `android/cpu_generation_scenario.dart` | Załadowanie pobranego modelu na CPU, pytanie, niepusta odpowiedź ze streama, zatrzymanie i zwolnienie modelu | 10 min |

`android/support/pending_scenario.dart` zawiera wspólną inicjalizację i rejestrację oczekujących scenariuszy. `driver.dart` jest hostowym punktem wejścia dla `flutter drive`.

## Wymagania docelowe

- Android: emulator dla zapisu i pobierania, rzeczywisty telefon dla próby z LLM.
- Rzeczywista baza, pliki, downloader i silnik CPU; bez repozytoriów w pamięci ani atrap LLM.
- Ustalony mały model z katalogu aplikacji, znany rozmiar i SHA, sieć do pobrania oraz odpowiednia ilość RAM i wolnego miejsca.
- Osobny profil lub urządzenie testowe. Przyszłe scenariusze powinny usuwać wyłącznie własne rozmowy i pliki oraz sprzątać po błędach.
- Dla rozmów trzeba ustalić przygotowanie modelu, ponieważ wysyłanie może uruchamiać generowanie. Przygotowanie należy oddzielić od sprawdzania trwałości.
- Rzeczywisty restart procesu wymaga sterowania spoza aplikacji. Ponowne zbudowanie widgetu lub wywołanie `main()` nie zastępuje restartu.
- Odpowiedź LLM sprawdzamy po obecności tekstu, bez wymagania identycznej treści. GPU pozostaje poza zakresem.

## Ręczne uruchamianie

Po implementacji kroków i usunięciu pomijania wybranego scenariusza, z głównego katalogu projektu:

```sh
flutter pub get
flutter drive --driver=test/e2e/android/support/driver.dart --target=test/e2e/android/model_lifecycle_scenario.dart -d <android-device-id>
flutter drive --driver=test/e2e/android/support/driver.dart --target=test/e2e/android/cpu_generation_scenario.dart -d <android-device-id>
```

Te polecenia mogą budować, instalować i uruchamiać aplikację na wskazanym urządzeniu. Nie są częścią zwykłego lokalnego uruchomienia testów ani obecnego workflow budowania APK. Dla tej lokalizacji używamy `flutter drive` z jawną ścieżką celu.

Test trwałości rozmów będzie dodatkowo potrzebował sterowania restartem procesu z komputera. Podstawowy driver jeszcze tego nie realizuje.

Dokumentacja frameworka: [Flutter integration_test](https://github.com/flutter/flutter/tree/master/packages/integration_test).

## Wyniki i dalsza implementacja

Katalog wyników na komputerze: [output/android](output/android/README.md).

Docelowe zbieranie artefaktów powinno zapisywać osobno dla każdego uruchomienia:
- wynik i czas scenariusza oraz wersję kodu, urządzenie i model w `report.json`;
- wyjście Fluttera w `flutter.log`;
- logi Androida w `logcat.txt`;
- zrzut po błędzie w `screenshots/`.

Obecnie przygotowany jest katalog i opis formatu. Zbieranie tych artefaktów, restart procesu i wykonywalne kroki scenariuszy pozostają do dopisania. Szkielet nie jest podpięty do automatycznego uruchamiania na każdym commicie.
