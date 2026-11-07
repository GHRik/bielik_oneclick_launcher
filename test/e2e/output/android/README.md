# Wyniki Android E2E

Katalog na lokalne artefakty ręcznych uruchomień. Wygenerowana zawartość jest ignorowana przez Git; ten opis pozostaje w repozytorium.

Planowany układ pojedynczego uruchomienia:

```text
<run-id>/
├── report.json
├── flutter.log
├── logcat.txt
└── screenshots/
```

`run-id` powinien zawierać datę, godzinę oraz scenariusz, np. `2026-11-07_180000_cpu-generation`. Dzięki temu kolejne uruchomienie nie nadpisze poprzednich wyników.

To przygotowane miejsce na wyniki. Obecny szkielet nie generuje jeszcze raportów, logów ani zrzutów; zapis artefaktów będzie zadaniem przyszłego runnera.

Logi i zrzuty mogą zawierać treść rozmów. Do testów używaj rozmów testowych.
