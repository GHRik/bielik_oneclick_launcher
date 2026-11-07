# Testy

Testy są pogrupowane według funkcjonalności. Nazwa grupy opisuje funkcję, a nazwa testu konkretne oczekiwane zachowanie. Obie są po angielsku i pojawiają się w raporcie uruchomienia.

| Katalog | Zakres |
| --- | --- |
| `app/` | Przepływy aplikacji, wstrzykiwanie repozytoriów i granice warstw |
| `configuration/` | Wybór SQLite dla platformy, konfiguracja LLM, walidacja i zapis ustawień |
| `database/` | Schemat, integralność danych, zapis i odtwarzanie rozmów w SQLite |
| `chat/` | Wysyłanie, streaming, kontekst, szkice, nawigacja, usuwanie i kopiowanie |
| `llm/` | Izolacja CPU/GPU, wybór trybu i prompt systemowy |
| `device_resources/` | Odczyt RAM i wolnego miejsca przez źródło platformowe |
| `model_management/` | Pobieranie, weryfikacja plików, usuwanie i wymagania modelu |
| `statistics/` | Mapowanie pomiarów, historia, cykl odświeżania i wykresy |
| `native/` | Samodzielne testy Java odczytu czujników GPU z sysfs |
| `support/` | Wspólne repozytoria w pamięci używane zamiast rzeczywistych usług |

## Zasady

- Jeden test sprawdza jedno zachowanie. Kilka asercji jest uzasadnione, gdy opisują ten sam wynik operacji.
- Przygotowanie, wykonanie operacji i sprawdzenie wyniku są oddzielone pustymi wierszami.
- Każdy wariant platformy, danych lub rozmiaru ekranu ma osobny nazwany przypadek.
- Wspólne przygotowanie jest w lokalnych funkcjach lub `setUp`; każdy przypadek dostaje własny stan.
- Testy SQLite używają osobnej bazy tymczasowej, zamykanej i usuwanej po próbie.
- `test` służy do logiki i repozytoriów, `testWidgets` do widoków i obiektów wymagających wiązania Fluttera. Próby korzystające z rzeczywistego SQLite są lokalnymi testami integracyjnymi.
- Testy z atrapą silnika lub źródła platformowego nie potwierdzają wydajności modelu ani dostępności GPU na telefonie.

## Uruchamianie

Polecenia wykonuj z głównego katalogu projektu po `flutter pub get`.

```sh
flutter test --no-pub
flutter analyze --no-pub
flutter test --no-pub test/chat
flutter test --no-pub test/model_management/model_files_repository_test.dart
```

Testy Java uruchamia się osobno, z JDK dostępnym w PATH:

```sh
javac -d .agent-staging/native-tests android/app/src/main/java/bielik/ai/bielik_oneclick_launcher/GpuSysfsReader.java test/native/GpuSysfsReaderTest.java
java -cp .agent-staging/native-tests bielik.ai.bielik_oneclick_launcher.GpuSysfsReaderTest
```

Do tych testów nie jest potrzebny telefon, emulator, pobrany model ani połączenie z serwerem modeli.
