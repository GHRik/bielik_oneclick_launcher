# Strona Bielik OneClick

Statyczna strona reklamowa: `index.html` i `styles.css`. Bez instalowania zależności i bez kroku budowania. Podgląd lokalny: otwórz `index.html` w przeglądarce.

## Podmiana podglądów na obrazy

Trzy ilustracje są celowo schematyczne, a podpisy oznaczają je jako podglądy:

| Obraz | Miejsce |
| --- | --- |
| `assets/chat-preview.svg` | Telefon w pierwszej sekcji |
| `assets/models-preview.svg` | Wybór i pobieranie modelu |
| `assets/settings-preview.svg` | Rozmowy i ustawienia |

Dodaj swoje PNG/WebP do `assets/`, a następnie zmień odpowiednie `src` w `index.html` i opis `alt`. Dla pionowego ekranu telefonu zachowaj proporcje około 340 × 650. Podglądy w pozostałych sekcjach mają proporcje 4:3. Dostosuj podpisy po wstawieniu rzeczywistych zrzutów. Wszystkie ścieżki są względne, więc działają pod adresem repozytorium GitHub Pages.

Przyciski pobierania prowadzą do listy wydań, ponieważ workflow APK tworzy wydania testowe oznaczone jako prerelease, bez znacznika latest.

## GitHub Pages

1. W repozytorium otwórz **Settings → Pages → Build and deployment → Source → GitHub Actions**.
2. Wypchnij stronę oraz workflow `.github/workflows/deploy-pages.yml` na `master`.
3. Workflow publikuje tylko katalog `site/`. Można go też uruchomić ręcznie w Actions.
4. Adres domyślny: https://ghrik.github.io/bielik_oneclick_launcher/ — będzie aktywny po poprawnym wdrożeniu.

Zmiany w aplikacji i budowanie APK nie są wymagane do wdrożenia strony.
