(async () => {
  const info = document.querySelector('#release-info');
  const notes = document.querySelector('#release-notes');
  const archive = document.querySelector('#release-archive');
  const more = document.querySelector('#release-more');
  if (!info) return;

  const api = 'https://api.github.com/repos/GHRik/bielik_oneclick_launcher/releases';
  const dateFormat = new Intl.DateTimeFormat('pl-PL', {
    day: 'numeric', month: 'long', year: 'numeric', timeZone: 'Europe/Warsaw',
  });
  const apk = release => release.assets?.find(asset => asset.name === 'bielik-arm64.apk');
  const stable = release => !release.draft && !release.prerelease && apk(release)
    && !Number.isNaN(new Date(release.published_at).getTime());
  const date = release => dateFormat.format(new Date(release.published_at));
  const title = release => {
    const version = release.tag_name.match(/^v(\d+\.\d+\.\d+)-build\.(\d+)\.(\d+)$/);
    return version
      ? `Bielik OneClick ${version[1]} · kompilacja ${version[2]}.${version[3]}`
      : 'Bielik OneClick';
  };
  let polishNotes = {};
  const translations = request('./release-notes.pl.json')
    .then(value => { polishNotes = value; })
    .catch(() => {});
  const seen = new Set();
  let page = 1;
  let latestRequest;

  function currentRelease() {
    if (!latestRequest) {
      latestRequest = request(`${api}/latest`).then(release => {
        if (!stable(release)) throw new Error('No stable APK');
        return release;
      }).catch(error => {
        latestRequest = null;
        throw error;
      });
    }
    return latestRequest;
  }

  function link(label, href) {
    const element = document.createElement('a');
    element.textContent = label;
    element.href = href;
    return element;
  }

  function body(release) {
    const element = document.createElement('div');
    element.className = 'release-body';
    const version = release.tag_name.match(/^v(\d+\.\d+\.\d+)(?:-build\.\d+\.\d+)?$/)?.[1];
    const translated = polishNotes[release.tag_name] ?? polishNotes[version];
    if (typeof translated !== 'string' || !translated.trim()) {
      element.textContent = 'Polski opis zmian nie jest jeszcze dostępny. Angielski opis znajdziesz na GitHubie.';
      return element;
    }
    for (const block of translated.trim().split(/\n\s*\n/)) {
      const lines = block.split('\n').map(line => line.trim()).filter(Boolean);
      if (lines.every(line => /^[•*-]\s+/.test(line))) {
        const list = document.createElement('ul');
        for (const line of lines) {
          const item = document.createElement('li');
          item.textContent = line.replace(/^[•*-]\s+/, '');
          list.append(item);
        }
        element.append(list);
      } else {
        const paragraph = document.createElement('p');
        paragraph.textContent = lines.join(' ');
        element.append(paragraph);
      }
    }
    return element;
  }

  async function request(url) {
    const response = await fetch(url, {
      headers: { Accept: 'application/vnd.github+json' },
      signal: AbortSignal.timeout(8000),
    });
    if (!response.ok) throw new Error('Release request failed');
    return response.json();
  }

  async function latest() {
    try {
      const release = await currentRelease();
      await translations;
      const time = document.createElement('time');
      time.dateTime = release.published_at;
      time.textContent = date(release);
      info.replaceChildren(
        document.createTextNode(`${title(release)} · `), time,
        document.createTextNode(' · '), link('Szczegóły wydania', release.html_url),
      );
      if (notes) {
        const heading = document.createElement('h3');
        heading.textContent = title(release);
        notes.replaceChildren(heading, body(release), link('Opis po angielsku na GitHubie ↗', release.html_url));
      }
    } catch {
      if (notes) notes.textContent = 'Nie udało się pobrać opisu zmian. Sprawdź wydania na GitHubie.';
    }
  }

  async function loadArchive() {
    if (!archive || !more) return;
    more.disabled = true;
    more.textContent = 'Wczytywanie…';
    try {
      const [releases, current] = await Promise.all([
        request(`${api}?per_page=30&page=${page}`), currentRelease(), translations,
      ]);
      for (const release of releases.filter(stable)) {
        if (release.id === current.id || seen.has(release.id)) continue;
        seen.add(release.id);
        const item = document.createElement('details');
        item.className = 'release-entry';
        const summary = document.createElement('summary');
        summary.textContent = `${title(release)} · ${date(release)}`;
        const actions = document.createElement('div');
        actions.className = 'release-links';
        actions.append(
          link('Pobierz APK ↓', apk(release).browser_download_url),
          link('Wydanie na GitHubie ↗', release.html_url),
        );
        item.append(summary, body(release), actions);
        archive.append(item);
      }
      page++;
      more.hidden = releases.length < 30;
      more.textContent = 'Pokaż starsze wydania';
      if (!seen.size && more.hidden) {
        archive.textContent = 'Brak stabilnych wydań APK w archiwum.';
      }
    } catch {
      more.hidden = false;
      more.textContent = 'Ponów wczytywanie archiwum';
    } finally {
      more.disabled = false;
    }
  }

  if (more) {
    more.hidden = false;
    more.addEventListener('click', loadArchive);
  }
  await Promise.allSettled([latest(), loadArchive()]);
})();
