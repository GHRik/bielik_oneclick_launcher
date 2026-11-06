# Architektura aplikacji

Kod aplikacji znajduje się w `lib/src/`. `lib/main.dart` uruchamia aplikację, a widoczne pliki ustawień są w `lib/configuration/`: `bielik_models.dart` zawiera katalog modeli, `llm_configuration.dart` domyślne parametry LLM i nadpisania według nazwy pliku GGUF. Konfiguracja jest przekazywana przez punkt składania aplikacji; warstwy domeny, danych i widoku nie importują tego katalogu.

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

`ConfiguredModelCatalogRepository` otrzymuje katalog z `configuration/bielik_models.dart` i udostępnia go przez kontrakt domeny. Dane `PreviewStatisticsRepository` są zachowane do podglądów i testów; produkcja wstrzykuje `LocalStatisticsRepository`.

`Conversation` jest modelem domenowym. `ConversationController` przechowuje kontroler biblioteki czatu, szkic wiadomości i stan widoku. `ChatWorkspace` zarządza wyborem i cyklem życia rozmów.

`ModelFilesRepository` definiuje pobieranie i usuwanie modeli. `FlutterModelDownloadDataSource` przekazuje transfer do `flutter_downloader`, który zapisuje zadania i wykonuje je na Androidzie przez WorkManager. `main.dart` inicjalizuje plugin przed uruchomieniem widoków. `LocalModelFilesRepository` odczytuje stan zapisanych zadań, mierzy przyrost pliku dla prędkości i ETA oraz weryfikuje rozmiar i SHA-256 przed zmianą nazwy `.part` na docelową. Zamknięcie widoku nie anuluje zadania. Po ponownym wyborze modelu kontroler dołącza do istniejącego zadania, również gdy transfer zakończył się podczas nieobecności aplikacji; weryfikacja odbywa się wtedy po jej otwarciu. Gotowe pliki pozostają w prywatnym katalogu aplikacji. Usuwanie kasuje również powiązane zadania pluginu.

`DeviceResourcesRepository` udostępnia dostępny i całkowity RAM oraz wolne miejsce w bajtach. `LocalDeviceResourcesRepository` korzysta z `DeviceResourcesDataSource` i kanału `bielik/device_resources`. Androidowy `DeviceResourcesChannel` odczytuje `ActivityManager.MemoryInfo` oraz `StatFs` dla katalogu aplikacji, w którym przechowujemy modele; pracuje w kolejce tła. Nie wymaga dodatkowych uprawnień. `DeviceResourcesController` odświeża dane przy otwarciu, wznowieniu aplikacji, powrocie z czatu oraz po pobraniu lub usunięciu modelu. Brak obsługi platformy lub błąd daje brak danych. Implementację dla laptopa można dodać przez ten sam kontrakt, bez zmiany widoku. GB oznacza tutaj miliard bajtów, zgodnie z rozmiarami modeli.

`ModelRequirements.evaluate` jest wspólną regułą domenową oceniającą RAM i miejsce. Zwraca stany zasobów oraz decyzję `requiresConfirmation`. Widgety tylko wyświetlają wyniki i otwierają okno potwierdzenia.

## Pomiary statystyk

`SamplingStatisticsRepository` rozszerza kontrakt statystyk o asynchroniczny pomiar. `LocalStatisticsRepository` łączy `StatisticsDataSource` i domenowy rejestr `GenerationMetrics`, utrzymując maksymalnie 61 próbek z ostatnich 60 sekund. `StatisticsController` pobiera dane co sekundę na pierwszym planie, także podczas generowania i przed otwarciem statystyk; zatrzymuje timer w tle i przy usuwaniu kontrolera. Wykresy korzystają z rzeczywistych odstępów czasowych, pokazują przerwy dla brakujących pomiarów i nie wypełniają historii sztucznymi zerami. Historia nie jest zapisywana do SQLite.

Androidowy `DeviceStatisticsReader` działa w kolejce tła istniejącego kanału platformowego. Zwraca PSS procesu (RAM aplikacji), CPU procesu z różnicy liczników czasu (procent łącznej mocy rdzeni), temperaturę baterii i temperaturę CPU, jeśli system na to pozwala. Odmowa dostępu do temperatury CPU daje brak danych, a nie temperaturę baterii pod inną nazwą.

`GpuStatisticsReader` rozszerza ten sam adapter o temperaturę GPU z `HardwarePropertiesManager` i odczyty `GpuSysfsReader`. Źródła sysfs są tylko odczytywane: Adreno KGSL (`gpu_busy_percentage`, `gpubusy`), liczniki `utilisation` urządzeń GPU/Mali w devfreq i strefy thermal oznaczone jako GPU. Temperatura stref thermal jest przeliczana z milistopni Celsjusza. Nie odczytujemy temperatury baterii jako temperatury GPU i nie wyliczamy obciążenia z częstotliwości zegara. Brak pliku, odmowa dostępu, niepoprawna wartość lub brak sensownego mianownika daje brak danych. Pomiar użycia dotyczy całego GPU, a nie procesu aplikacji. Repozytorium przechowuje obie metryki w tej samej historii, a ekran wyświetla je z danych zamiast dodawać puste karty.

Android ogranicza dostęp do [HardwarePropertiesManager](https://developer.android.com/reference/android/os/HardwarePropertiesManager). Formaty liczników są zgodne ze źródłami [KGSL](https://android.googlesource.com/kernel/msm/+/730cf84987cc34f1f0e53cbdd4153a2227563dc7/drivers/gpu/msm/kgsl_pwrctrl.c) i [Mali](https://nest-open-source.googlesource.com/manifest_repos/mali-driver/+/268e43036ceb1097d004fa09786438f2319a2a0e/midgard/r13p0/kernel/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_devfreq.c). Dostępność tych ścieżek zależy od telefonu.

`LocalLlmRepository` rejestruje czas do pierwszego tekstu od rozpoczęcia żądania LLM, razem z ładowaniem. Liczbę tokenów oraz średnią prędkość tokeny / czas żądania pobiera z końcowego raportu silnika, bez utożsamiania fragmentów tekstu z tokenami. Te dwie metryki opisują ostatnie zakończone żądanie i sumę raportowanych tokenów sesji. Przerwane żądanie bez raportu nie zwiększa licznika.

## Konfiguracja modeli

`LlmConfiguration` w domenie jest niemutowalnym zestawem parametrów CPU i generowania. `main.dart` wstrzykuje do `LocalLlmRepository` funkcję `llmConfigurationFor`, która wybiera nadpisanie z `modelLlmConfigurations` lub wartości domyślne. `CpuRuntimeAdapter` zachowuje jawne `ComputeDevice.cpu`, `GpuBackend.cpu` i 0 warstw GPU. Oddzielny `GpuInferenceAdapter` mapuje konfigurację GPU na Vulkan/OpenCL i sprawdza raport backendu oraz warstw przed generowaniem. `ComputeRoutingLlmRepository` ma niezależne instancje silnika dla CPU i GPU; tworzy GPU dopiero na jawne żądanie. Zmiana trybu zwalnia poprzedni model. Błąd GPU zwalnia jego silnik i nie powoduje automatycznego ponowienia na CPU. Nie ma zmian globalnych zmiennych środowiskowych Vulkan. GPU pozostaje ustawieniem bieżącej sesji, domyślnie wyłączonym. APK zawiera backendy CPU, Vulkan i OpenCL; opcjonalna biblioteka OpenCL producenta jest deklarowana w manifeście. Ścieżka GPU jest eksperymentalna i nie została sprawdzona na urządzeniu. Zmiana pliku lub profilu przeładowuje silnik. `LlmRuntimeInfo` przekazuje raport działania do widoku. Formularz pod zębatką przechowuje szkic w prezentacji i waliduje pola przed zapisem. `LlmSettingsRepository` oddziela trwałe ustawienia od UI. Implementacja SQLite zapisuje cały profil atomowo w tabeli `settings`; migracja v1 → v2 zachowuje rozmowy. Composition root odczytuje profil przy starcie, a po udanym zapisie podmienia konfigurację używaną przez silnik. Nowy profil obowiązuje przy kolejnym otwarciu czatu. Brak zapisanego profilu zachowuje konfigurację poszczególnych modeli z plików.

## Lokalny LLM w czacie

`LlmRepository` w domenie definiuje strumień odpowiedzi, zatrzymanie i zwolnienie modelu. `LocalLlmRepository` korzysta z `llamadart` / `llama.cpp`, otwierając lokalny GGUF wybrany na ekranie głównym. Jeden model pozostaje w pamięci podczas pracy w czacie. Generowanie domyślnie używa CPU, a po jawnym wyborze osobnej instancji GPU, domyślnie z kontekstem 2048 tokenów i limitem odpowiedzi 512 tokenów. `ChatContextPolicy` w domenie scala kolejne wiadomości tej samej roli i wybiera najnowsze tury mieszczące się w budżecie. Adapter LLM dostarcza liczenie tokenów na podstawie rzeczywistego szablonu modelu. Pełna historia w bazie nie jest przycinana.

`ChatService` w domenie prowadzi wysłanie: tworzy tytuł, zapisuje użytkownika, uruchamia LLM oraz okresowo i na końcu utrwala odpowiedź. Serializuje zapisy ze szkicami i emituje zdarzenia `ChatMessageSaved` / `ChatMessageUpdated`. Nie zna kontrolerów Fluttera ani biblioteki czatu. `ChatWorkspace` przekazuje polecenia i mapuje zdarzenia na stan widoku oraz właściwy `ConversationController`, także po przełączeniu rozmowy. Usunięcie aktywnej rozmowy czeka na zatrzymanie generowania. Wyjście z czatu lub przejście do tła zatrzymuje generowanie i zwalnia silnik po zakończeniu zapisu.

## SQLite — trwała historia rozmów

`AppDatabase` w `data/datasources/local/` otwiera prywatny plik `bielik.db` przy ładowaniu historii. Interfejs może pokazać błąd otwarcia bazy i pozwolić ponowić próbę. Schemat w wersji 2 zawiera tabelę ustawień i tworzy tabele `conversations` i `messages`, indeks wiadomości oraz klucz obcy z `ON DELETE CASCADE`. Rozmowa ma też miejsce na szkic wiadomości. Czas jest przechowywany jako liczba milisekund od epoki UTC.

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
