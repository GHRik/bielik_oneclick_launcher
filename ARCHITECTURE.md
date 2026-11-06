# Architektura aplikacji

Kod aplikacji znajduje się w `lib/src/`. `lib/main.dart` uruchamia aplikację.

```text
lib/src/
├── app.dart
├── presentation/
│   ├── pages/
│   ├── widgets/
│   ├── controllers/
│   └── sidebars/
├── domain/
│   ├── models/
│   └── repositories/
└── data/
    ├── datasources/
    └── repositories_impl/
```

## Zależności

- `domain` zawiera czyste modele Dart, ocenę wymagań zasobów i kontrakty repozytoriów. Nie zależy od Fluttera, widoków ani źródeł danych.
- `presentation` zawiera ekrany, widgety, panele boczne i kontrolery stanu UI. Zależy od domeny, ale nie importuje warstwy danych.
- `data` implementuje kontrakty domeny i dostarcza dane ze źródeł. Nie zależy od widoków.
- `app.dart` składa aplikację: wybiera implementacje repozytoriów i przekazuje dane do ekranów. Testy mogą wstrzyknąć własne implementacje.

## Obecne źródła danych

Repozytoria `PreviewModelCatalogRepository` i `PreviewStatisticsRepository` dostarczają lokalny katalog modeli i przykładowe serie wykresów. Nie wykonują operacji sieciowych, odczytów parametrów telefonu ani inferencji AI.

`Conversation` jest modelem domenowym. `ConversationController` przechowuje kontroler biblioteki czatu, szkic wiadomości i stan widoku. `ChatWorkspace` zarządza wyborem i cyklem życia rozmów.

`ModelFilesRepository` definiuje pobieranie i usuwanie modeli. `FlutterModelDownloadDataSource` przekazuje transfer do `flutter_downloader`, który zapisuje zadania i wykonuje je na Androidzie przez WorkManager. `main.dart` inicjalizuje plugin przed uruchomieniem widoków. `LocalModelFilesRepository` odczytuje stan zapisanych zadań, mierzy przyrost pliku dla prędkości i ETA oraz weryfikuje rozmiar i SHA-256 przed zmianą nazwy `.part` na docelową. Zamknięcie widoku nie anuluje zadania. Po ponownym wyborze modelu kontroler dołącza do istniejącego zadania, również gdy transfer zakończył się podczas nieobecności aplikacji; weryfikacja odbywa się wtedy po jej otwarciu. Gotowe pliki pozostają w prywatnym katalogu aplikacji. Usuwanie kasuje również powiązane zadania pluginu.

Ocena RAM i miejsca jest wspólną regułą domenową wykorzystywaną przez oznaczenia wymagań oraz potwierdzenie pobierania.

## Lokalny LLM w czacie

`LlmRepository` w domenie definiuje strumień odpowiedzi, zatrzymanie i zwolnienie modelu. `LocalLlmRepository` korzysta z `llamadart` / `llama.cpp`, otwierając lokalny GGUF wybrany na ekranie głównym. Jeden model pozostaje w pamięci podczas pracy w czacie. Generowanie działa na CPU, z kontekstem 2048 tokenów i limitem odpowiedzi 512 tokenów. Przed generowaniem najstarsze tury są pomijane, aż sformatowany prompt zmieści się w budżecie; pełna historia w bazie nie jest przycinana.

`ChatWorkspace` najpierw zapisuje wiadomość użytkownika, a potem uruchamia generowanie poza kolejką operacji szkiców. Odpowiedź jest przypisana do rozmowy źródłowej także po przełączeniu widoku. Pierwszy fragment tworzy wiadomość asystenta; kolejne aktualizują jej tekst w UI, okresowo w SQLite i zawsze przy zakończeniu lub zatrzymaniu. Zapis asystenta nie czyści szkicu użytkownika. Usunięcie aktywnej rozmowy czeka na zatrzymanie generowania. Wyjście z czatu lub przejście do tła zatrzymuje generowanie i zwalnia silnik po zakończeniu zapisu.

## SQLite — trwała historia rozmów

`AppDatabase` w `data/datasources/local/` otwiera prywatny plik `bielik.db` przy ładowaniu historii. Interfejs może pokazać błąd otwarcia bazy i pozwolić ponowić próbę. Schemat w wersji 1 tworzy tabele `conversations` i `messages`, indeks wiadomości oraz klucz obcy z `ON DELETE CASCADE`. Rozmowa ma też miejsce na szkic wiadomości. Czas jest przechowywany jako liczba milisekund od epoki UTC.

Baza jest tworzona przy pierwszym otwarciu; kolejne otwarcia zachowują dane. Zmiany schematu będą wymagać zwiększenia wersji i dodania migracji.

Kontrakt `ChatRepository` jest w domenie. `SqliteChatRepository` mapuje rekordy SQLite na modele domenowe, a `SqliteChatDataSource` wykonuje zapytania. `main.dart` wstrzykuje repozytorium do aplikacji; prezentacja nie importuje SQLite.

`ChatWorkspace` ładuje rozmowy, wiadomości i szkice z bazy. Przy pustej historii tworzy pierwszą rozmowę. Po restarcie domyślnie otwiera najnowszą utworzoną rozmowę; pozostałe są dostępne na liście.

Wysłanie wiadomości, aktualizacja tytułu i wyczyszczenie zapisanego szkicu odbywają się w jednej transakcji. UI pokazuje wiadomość dopiero po zapisie. Identyfikatory wiadomości są generowane w SQLite, więc nie resetują się po uruchomieniu aplikacji.

Zmiany szkiców i operacje rozmów są kolejkowane w kolejności wykonania. Nowszy szkic nie jest czyszczony przez kończący się zapis wcześniejszej wiadomości. Błędy odczytu i zapisu są pokazywane w czacie; nieudane wysłanie pozostawia tekst w polu wpisywania.

Usunięcie rozmowy jest trwałe, wraz z jej wiadomościami. Po usunięciu ostatniej rozmowy tworzona jest nowa. Nie zmieniono wersji schematu ani nie usunięto istniejących danych.

Testy używają `sqflite_common_ffi` z rzeczywistym tymczasowym plikiem SQLite. Produkcja na Androidzie korzysta z `sqflite`.

## Weryfikacja

`flutter analyze --no-pub` oraz `flutter test --no-pub`.

Test architektury pilnuje kierunków zależności. Test wstrzykiwania repozytoriów sprawdza, czy ekrany faktycznie korzystają z przekazanych implementacji.
