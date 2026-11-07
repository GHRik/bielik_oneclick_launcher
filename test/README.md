# Testy

## Testy jednostkowe przy klasach

UT są w katalogu `ut` bezpośrednio obok testowanych plików produkcyjnych. Plik `test_<nazwa_pliku>.dart` sprawdza wyłącznie klasę lub funkcje z odpowiadającego mu pliku. Zależności zewnętrzne zastępują prywatne atrapy.

```text
lib/src/data/datasources/
├── device_resources_datasource.dart
├── gpu_inference_adapter.dart
├── llm_runtime_adapter.dart
└── ut/
    ├── test_device_resources_datasource.dart
    ├── test_gpu_inference_adapter.dart
    ├── test_llm_runtime_adapter.dart
    └── analysis_options.yaml
```

| Katalog UT | Testowane klasy lub funkcje |
| --- | --- |
| `lib/configuration/ut/` | Funkcje wyboru konfiguracji LLM; nie model domenowy |
| `lib/src/data/datasources/ut/` | `DeviceResourcesDataSource`, `GpuInferenceAdapter`, `CpuRuntimeAdapter` z pliku `llm_runtime_adapter.dart` |
| `lib/src/data/repositories_impl/ut/` | `LocalDeviceResourcesRepository`, `ComputeRoutingLlmRepository`, `ConfiguredModelCatalogRepository` |
| `lib/src/domain/models/ut/` | `ChatMessage`, `DeviceResources`, `LlmConfiguration`, `ModelRequirements`, `ResourceRequirement` |
| `lib/src/domain/services/ut/` | `ChatService`, `ChatContextPolicy` |
| `lib/src/presentation/controllers/ut/` | `DeviceResourcesController`, `LlmSettingsDraft`, `ModelDownloadController` |
| `lib/src/presentation/formatters/ut/` | `StorageSizeFormatter` |

To wykaz klas objętych obecnymi UT, nie deklaracja pełnego pokrycia wszystkich klas aplikacji. Interfejsy bez implementacji nie potrzebują pustych testów.

Przykładowo:
- `test_device_resources_datasource.dart` sprawdza wywołanie kanału, argumenty, wynik i przekazywanie błędu; kanały platformowe są atrapami.
- `test_local_device_resources_repository.dart` sprawdza konwersję danych z atrapą źródła.
- `test_device_resources_controller.dart` sprawdza odświeżanie i powiadomienia z atrapą repozytorium.

Wspólny plik `analysis_options_ut.yaml` w głównym katalogu dziedziczy ustawienia projektu i wyłącza wyłącznie regułę `depend_on_referenced_packages`, aby UT w `lib` mogły używać `flutter_test` z zależności deweloperskich. Każdy `ut/analysis_options.yaml` zawiera tylko jednolinijkowy `include` wskazujący tę wspólną konfigurację. Pozostałe reguły i wykrywanie błędów pozostają aktywne.

## Pozostałe poziomy

| Katalog | Co sprawdza |
| --- | --- |
| `test/component/` | Widoki i współpracę rzeczywistych komponentów, np. workspace, serwisu, kontrolerów i wykresów. Zewnętrzny zapis, LLM i pomiary są zastępowane. |
| `test/integration/` | Rzeczywisty lokalny SQLite i pliki tymczasowe. Transfer oraz silnik LLM nadal są atrapami. |
| `test/integration/native/android/` | Samodzielny test Java odczytu GPU ze sztucznego drzewa sysfs. |
| `test/architecture/` | Zależności warstw, brak importowania UT przez produkcję i kompletność rejestru UT. |
| `test/support/` | Wspólne atrapy testów komponentowych; UT mają własne prywatne atrapy. |

Próby porównujące dwa adaptery CPU/GPU są w komponentowych. O poziomie decyduje zakres i zależności, nie samo użycie `test()` lub `testWidgets()`.

Szkielet Android E2E jest w [e2e/README.md](e2e/README.md). Zawiera trzy oczekujące scenariusze: trwałość rozmów, pobranie/usunięcie modelu i generowanie na CPU. Pliki mają końcówkę `_scenario.dart`, aby zwykłe `flutter test` ich nie wykrywało. Uruchamianie E2E jest ręczne przez `flutter drive`; miejsce na przyszłe artefakty to `test/e2e/output/android/`.

## Uruchamianie

Z głównego katalogu projektu, po `flutter pub get`:

```sh
flutter test --no-pub
flutter test --no-pub test/ut_test.dart
flutter test --no-pub lib/src/data/datasources/ut/test_device_resources_datasource.dart
flutter test --no-pub test/component
flutter test --no-pub test/integration
flutter test --no-pub test/architecture
flutter analyze --no-pub
```

`test/ut_test.dart` rejestruje wszystkie UT z katalogów przy klasach. Dzięki niemu zwykłe `flutter test` i istniejący workflow GitHub Actions nadal je uruchamiają. Po dodaniu nowego pliku UT dopisz jego import oraz wywołanie `main` w tym rejestrze. Test architektury wykrywa brak rejestracji.

Nazwy `test_*.dart` nie są automatycznie wyszukiwane jak standardowe `*_test.dart`, dlatego pojedynczy plik uruchamiaj przez pełną ścieżkę lub rejestr.

Java, z JDK w PATH:

```sh
javac -d .agent-staging/native-tests android/app/src/main/java/bielik/ai/bielik_oneclick_launcher/GpuSysfsReader.java test/integration/native/android/GpuSysfsReaderTest.java
java -cp .agent-staging/native-tests bielik.ai.bielik_oneclick_launcher.GpuSysfsReaderTest
```

## Zasady i platformy

- Jeden przypadek testuje jedno zachowanie wskazanej klasy; kilka asercji może opisywać ten sam wynik.
- Każdy przypadek dostaje własny stan. Tymczasowe bazy i pliki są sprzątane po próbie.
- Testy działają lokalnie z Flutter SDK; Java wymaga JDK, a SQLite sprawnego FFI.
- Atrapy kanałów, downloadera i LLM nie potwierdzają działania Android API, pobierania ani modelu na urządzeniu.
- Testy end-to-end na Androidzie, iOS lub desktopie wymagają osobnej weryfikacji na docelowej platformie.
