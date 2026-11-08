(async () => {
  const info = document.querySelector('#release-info');
  if (!info) return;

  try {
    const response = await fetch(
      'https://api.github.com/repos/GHRik/bielik_oneclick_launcher/releases/latest',
      { headers: { Accept: 'application/vnd.github+json' }, signal: AbortSignal.timeout(8000) },
    );
    if (!response.ok) return;

    const release = await response.json();
    if (release.draft || release.prerelease) return;
    const published = new Date(release.published_at);
    if (Number.isNaN(published.getTime())) return;
    if (!release.assets?.some(asset => asset.name === 'bielik-arm64.apk')) return;

    const build = release.body?.match(/^Android version code:\s*(\d+)\s*$/m)?.[1];
    const version = build ? `Wersja APK: ${build}` : `Wydanie: ${release.tag_name}`;
    const date = new Intl.DateTimeFormat('pl-PL', {
      day: 'numeric', month: 'long', year: 'numeric', timeZone: 'Europe/Warsaw',
    }).format(published);

    const label = document.createElement('span');
    label.textContent = `${version} · `;
    const time = document.createElement('time');
    time.dateTime = published.toISOString();
    time.textContent = date;
    const link = document.createElement('a');
    link.href = 'https://github.com/GHRik/bielik_oneclick_launcher/releases/latest';
    link.textContent = 'Szczegóły wydania';
    info.replaceChildren(label, time, document.createTextNode(' · '), link);
  } catch {}
})();
