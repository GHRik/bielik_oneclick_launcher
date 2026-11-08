(() => {
  const video = document.querySelector('#generation-preview');
  if (!video) return;
  const motion = matchMedia('(prefers-reduced-motion: reduce)');
  let userPaused = motion.matches;
  let visible = false;
  video.muted = true;
  video.tabIndex = 0;
  video.setAttribute('role', 'button');

  function updateLabel() {
    video.setAttribute('aria-label', video.paused ? 'Odtwórz nagranie rozmowy' : 'Wstrzymaj nagranie rozmowy');
  }

  function updatePlayback() {
    if (userPaused || !visible || document.hidden) video.pause();
    else video.play().catch(updateLabel);
  }

  function togglePlayback() {
    userPaused = !video.paused;
    updatePlayback();
  }

  video.addEventListener('click', togglePlayback);
  video.addEventListener('keydown', event => {
    if (event.key !== 'Enter' && event.key !== ' ') return;
    event.preventDefault();
    togglePlayback();
  });
  video.addEventListener('play', updateLabel);
  video.addEventListener('pause', updateLabel);
  document.addEventListener('visibilitychange', updatePlayback);
  motion.addEventListener('change', event => {
    if (event.matches) userPaused = true;
    updatePlayback();
  });
  new IntersectionObserver(entries => {
    visible = entries[0].isIntersecting;
    updatePlayback();
  }, { threshold: 0.2 }).observe(video);
  updateLabel();
})();
