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
│   ├── repositories/
│   └── services/
└── data/
    ├── datasources/
    └── repositories_impl/
```

## Zależności

- `domain` zawiera modele, kontrakty repozytoriów i serwisy czystego Darta. Nie zależy od Fluttera, widoków ani źródeł danych. Jedyna dodatkowa biblioteka domeny, `characters`, zachowuje poprawne granice znaków Unicode w tytułach.
- `presentation` zawiera ekrany, widgety, panele boczne i kontrolery stanu UI. Zależy od domeny, ale nie importuje warstwy danych.
- `data` implementuje kontrakty domeny i dostarcza dane ze źródeł. Nie zależy od widoków.
- `app.dart` składa aplikację: wybiera implementacje repozytoriów i przekazuje dane do ekranów. Testy mogą wstrzyknąć własne implementacje.

## Obecne źródła danych

Repozytoria `PreviewModelCatalogRepository` i `PreviewStatisticsRepository` dostarczają lokalny katalog modeli i przykładowe serie wykresów. Nie wykonują operacji sieciowych, odczytów parametrów telefonu ani inferencji AI.

`Conversation` jest modelem domenowym. `ConversationController` przechowuje kontroler biblioteki czatu, szkic wiadomości i stan widoku. `ChatWorkspace` zarządza wyborem i cyklem życia rozmów.

`ModelFilesRepository` definiuje pobieranie i usuwanie modeli. `FlutterModelDownloadDataSource` przekazuje transfer do `flutter_downloader`, który zapisuje zadania i wykonuje je na Androidzie przez WorkManager. `main.dart` inicjalizuje plugin przed uruchomieniem widoków. `LocalModelFilesRepository` odczytuje stan zapisanych zadań, mierzy przyrost pliku dla prędkości i ETA oraz weryfikuje rozmiar i SHA-256 przed zmianą nazwy `.part` na docelową. Zamknięcie widoku nie anuluje zadania. Po ponownym wyborze modelu kontroler dołącza do istniejącego zadania, również gdy transfer zakończył się podczas nieobecności aplikacji; weryfikacja odbywa się wtedy po jej otwarciu. Gotowe pliki pozostają w prywatnym katalogu aplikacji. Usuwanie kasuje również powiązane zadania pluginu.

`DeviceResourcesRepository` udostępnia dostępny i całkowity RAM oraz wolne miejsce w bajtach. `LocalDeviceResourcesRepository` korzysta z `DeviceResourcesDataSource` i kanału `bielik/device_resources`. Androidowy `DeviceResourcesChannel` odczytuje `ActivityManager.MemoryInfo` oraz `StatFs` dla katalogu aplikacji, w którym przechowujemy modele; pracuje w kolejce tła. Nie wymaga dodatkowych uprawnień. `DeviceResourcesController` odświeża dane przy otwarciu, wznowieniu aplikacji, powrocie z czatu oraz po pobraniu lub usunięciu modelu. Brak obsługi platformy lub błąd daje brak danych. Implementację dla laptopa można dodać przez ten sam kontrakt, bez zmiany widoku. GB oznacza tutaj miliard bajtów, zgodnie z rozmiarami modeli.

`ModelRequirements.evaluate` jest wspólną regułą domenową oceniającą RAM i miejsce. Zwraca stany zasobów oraz decyzję `requiresConfirmation`. Widgety tylko wyświetlają wyniki i otwierają okno potwierdzenia.

## Lokalny LLM w czacie

`LlmRepository` w domenie definiuje strumień odpowiedzi, zatrzymanie i zwolnienie modelu. `LocalLlmRepository` korzysta z `llamadart` / `llama.cpp`, otwierając lokalny GGUF wybrany na ekranie głównym. Jeden model pozostaje w pamięci podczas pracy w czacie. Generowanie działa na CPU, z kontekstem 2048 tokenów i limitem odpowiedzi 512 tokenów. `ChatContextPolicy` w domenie scala kolejne wiadomości tej samej roli i wybiera najnowsze tury mieszczące się w budżecie. Adapter LLM dostarcza liczenie tokenów na podstawie rzeczywistego szablonu modelu. Pełna historia w bazie nie jest przycinana.

`ChatService` w domenie prowadzi wysłanie: tworzy tytuł, zapisuje użytkownika, uruchamia LLM oraz okresowo i na końcu utrwala odpowiedź. Serializuje zapisy ze szkicami i emituje zdarzenia `ChatMessageSaved` / `ChatMessageUpdated`. Nie zna kontrolerów Fluttera ani biblioteki czatu. `ChatWorkspace` przekazuje polecenia i mapuje zdarzenia na stan widoku oraz właściwy `ConversationController`, także po przełączeniu rozmowy. Usunięcie aktywnej rozmowy czeka na zatrzymanie generowania. Wyjście z czatu lub przejście do tła zatrzymuje generowanie i zwalnia silnik po zakończeniu zapisu.

## SQLite — trwała historia rozmów

`AppDatabase` w `data/datasources/local/` otwiera prywatny plik `bielik.db` przy ładowaniu historii. Interfejs może pokazać błąd otwarcia bazy i pozwolić ponowić próbę. Schemat w wersji 1 tworzy tabele `conversations` i `messages`, indeks wiadomości oraz klucz obcy z `ON DELETE CASCADE`. Rozmowa ma też miejsce na szkic wiadomości. Czas jest przechowywany jako liczba milisekund od epoki UTC.

Baza jest tworzona przy pierwszym otwarciu; kolejne otwarcia zachowują dane. Zmiany schematu będą wymagać zwiększenia wersji i dodania migracji.

Kontrakt `ChatRepository` jest w domenie. `SqliteChatRepository` mapuje rekordy SQLite na modele domenowe, a `SqliteChatDataSource` wykonuje zapytania. `main.dart` wstrzykuje repozytorium do aplikacji; prezentacja nie importuje SQLite.

`ChatWorkspace` ładuje rozmowy, wiadomości i szkice z bazy. Przy pustej historii tworzy pierwszą rozmowę. Po restarcie domyślnie otwiera najnowszą utworzoną rozmowę; pozostałe są dostępne na liście.

`ChatService` jawnie przekazuje `clearDraft: true` dla wiadomości użytkownika i `false` dla asystenta. SQLite nie rozpoznaje autora ani nie podejmuje tej decyzji. Zapis wiadomości, aktualizacja tytułu i ewentualne wyczyszczenie szkicu pozostają jedną transakcją. UI pokazuje wiadomość dopiero po zapisie. Identyfikatory wiadomości są generowane w SQLite, więc nie resetują się po uruchomieniu aplikacji.

Zmiany szkiców i operacje rozmów są kolejkowane w kolejności wykonania. Nowszy szkic nie jest czyszczony przez kończący się zapis wcześniejszej wiadomości. Błędy odczytu i zapisu są pokazywane w czacie; nieudane wysłanie pozostawia tekst w polu wpisywania.

Usunięcie rozmowy jest trwałe, wraz z jej wiadomościami. Po usunięciu ostatniej rozmowy tworzona jest nowa. Nie zmieniono wersji schematu ani nie usunięto istniejących danych.

Testy używają `sqflite_common_ffi` z rzeczywistym tymczasowym plikiem SQLite. Produkcja na Androidzie korzysta z `sqflite`.

## Weryfikacja

`flutter analyze --no-pub` oraz `flutter test --no-pub`.

Test architektury pilnuje kierunków zależności, jawnej listy bibliotek domeny i zakazu bibliotek UI w `data`. Serwis rozmowy, polityka kontekstu i ocena wymagań mają testy niezależne od widgetów. Test wstrzykiwania repozytoriów sprawdza, czy ekrany faktycznie korzystają z przekazanych implementacji.
