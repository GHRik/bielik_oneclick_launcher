# Testy

Pierwszy katalog określa poziom testu, kolejny funkcjonalność. Nazwy grup i przypadków są po angielsku i opisują oczekiwane zachowanie.

## Poziomy

| Katalog | Co sprawdza | Rzeczywiste zależności / atrapy |
| --- | --- | --- |
| `unit/` | Pojedynczą klasę lub funkcję: polityki, formatowanie, walidację, kontroler, serwis lub router | Modele wartości są rzeczywiste; zewnętrzne źródła danych i repozytoria są atrapami. Bez plików, SQLite i widoków. |
| `component/` | Widok lub współpracę kilku klas: workspace, serwis, kontrolery, repozytorium statystyk i wykresy | Komponenty aplikacji są rzeczywiste; zapis, LLM, pobieranie i pomiary urządzenia zastępują atrapy lub brak dostępnego kanału platformowego. |
| `integration/` | Współpracę z lokalnym SQLite lub systemem plików | Baza i pliki tymczasowe są rzeczywiste. Silnik LLM i transfer sieciowy nadal są atrapami. |
| `architecture/` | Dozwolone zależności między warstwami | Czyta importy plików produkcyjnych. |
| `support/` | Wspólne repozytoria w pamięci | Pomocniki; nie zawiera samodzielnych przypadków testowych. |

O poziomie decyduje zakres i zależności, nie samo użycie `test()` lub `testWidgets()`. Test workspace bez renderowania widoku jest komponentowy, jeżeli uruchamia rzeczywisty serwis i kontrolery rozmów. Test z widokiem i rzeczywistą bazą pozostaje integracyjny.

## Funkcjonalności

| Podkatalog | Zakres |
| --- | --- |
| `unit/chat/` | Kontekst, serwis wysyłania z atrapami repozytoriów, rozmiar wiadomości i formatowanie bajtów |
| `unit/configuration/` | Domyślne parametry LLM, nadpisania i walidacja szkicu ustawień |
| `unit/device_resources/` | Mapowanie odczytów RAM/miejsca i kontroler odświeżania z atrapami źródeł |
| `unit/llm/` | Routing CPU/GPU i parametry adapterów z atrapą silnika |
| `unit/model_management/` | Wymagania modelu, klasyfikacja zasobów i kontroler pobierania z atrapą repozytorium |
| `component/app/` | Przepływy aplikacji i wstrzykiwanie repozytoriów do widoków |
| `component/chat/` | Streaming, szkice, nawigacja, nagłówek, rozmiar w panelu i kopiowanie |
| `component/configuration/` | Formularz ustawień i przycisk zapisu z podstawionym callbackiem |
| `component/llm/` | Wybór trybu obliczeń z ekranu głównego |
| `component/model_management/` | Potwierdzenie pobierania, kolory wymagań i responsywność |
| `component/statistics/` | Współpraca repozytorium, metryk, kontrolera i wykresów; pomiary źródłowe są sztuczne |
| `integration/database/` | Fabryka SQLite, schemat, migracje, trwałość ustawień, rozmów i workspace |
| `integration/model_management/` | Pliki modeli, SHA, rozmiar, usuwanie i odtwarzanie zadań z atrapą downloadera |
| `integration/llm/` | Repozytorium LLM z rzeczywistym plikiem testowym, ale atrapą silnika; prompt, parametry i cykl życia |
| `integration/native/android/` | Test Java odczytu GPU ze sztucznego drzewa plików sysfs |

Pliki łączące różne poziomy zostały rozdzielone: rozmiar wiadomości i formatter mają UT, panel z rozmiarem test komponentowy; ustawienia mają osobno UT walidacji, test formularza oraz integrację zapisu i migracji.

## Zasady

- Jeden test sprawdza jedno zachowanie. Kilka asercji może opisywać ten sam wynik operacji.
- Przygotowanie, wykonanie operacji i sprawdzenie wyniku są oddzielone pustymi wierszami.
- Warianty platformy, danych i rozmiaru ekranu mają osobne nazwane przypadki.
- Każdy przypadek dostaje własny stan; bazy i pliki tymczasowe są sprzątane po próbie.

## Uruchamianie

Z głównego katalogu projektu, po `flutter pub get`:

```sh
flutter test --no-pub
flutter test --no-pub test/unit
flutter test --no-pub test/component
flutter test --no-pub test/integration
flutter test --no-pub test/architecture
flutter analyze --no-pub
```

Test Java uruchamia się osobno, z JDK w PATH:

```sh
javac -d .agent-staging/native-tests android/app/src/main/java/bielik/ai/bielik_oneclick_launcher/GpuSysfsReader.java test/integration/native/android/GpuSysfsReaderTest.java
java -cp .agent-staging/native-tests bielik.ai.bielik_oneclick_launcher.GpuSysfsReaderTest
```

## Platformy

UT i testy komponentowe działają na komputerze z Flutter SDK bez telefonu i emulatora. Korzystanie z atrap oznacza, że nie sprawdzają rzeczywistego Android API ani sprzętu.

Lokalne integracje SQLite wymagają działającego FFI na komputerze uruchamiającym testy. Testy plikowe używają katalogów tymczasowych tego komputera. Java sprawdza implementację Androida bez uruchamiania Androida.

Nie ma tu testów end-to-end na urządzeniu. Wynik nie potwierdza działania pobierania, uprawnień, natywnego SQLite, silnika LLM ani GPU na Androidzie, iOS czy desktopie. Taka weryfikacja wymaga osobnych testów na docelowej platformie.
