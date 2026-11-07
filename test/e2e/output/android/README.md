# Wyniki Android E2E

Każde uruchomienie przez `dart run test/e2e/run_android_e2e.dart` tworzy osobny katalog `<timestamp>_<suite>`. Artefakty są ignorowane przez Git; ten opis pozostaje w repozytorium.

```text
<timestamp>_<suite>/
├── report.json
├── devices.json
└── <phase>/
    ├── flutter.log
    ├── device-report.json
    ├── logcat.txt
    └── screenshots/
```

Fazy pełnego zestawu: `download`, `cpu`, `create`, `verify`, `delete`.

- `report.json`: wynik całości, urządzenie, rewizja kodu i wyniki faz.
- `devices.json`: urządzenia widoczne w chwili startu.
- `flutter.log`: wyjście budowania i wykonywania danej fazy.
- `device-report.json`: pomiary i wynik otrzymany od aplikacji testowej.
- `logcat.txt`: logi filtrowane po UID aplikacji E2E.
- `screenshots/`: próba zapisu zrzutu po błędzie scenariusza.

Raport ze statusem `blocked` oznacza, że testy nie wystartowały, np. przez brak Androida. Samo zbudowanie APK nie jest wynikiem E2E. Przy błędzie budowania lub awarii procesu raport urządzenia i zrzut mogą być niedostępne.

Artefakty zawierają rozmowy testowe. Nie używaj prywatnych danych jako pytań E2E.
