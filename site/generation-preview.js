(() => {
  const video = document.querySelector('#generation-preview');
  const toggle = document.querySelector('.generation-toggle');
  if (!video || !toggle) return;
  const motion = matchMedia('(prefers-reduced-motion: reduce)');
  let userPaused = motion.matches;
  let visible = false;
  video.muted = true;

  function updateLabel() {
    toggle.textContent = video.paused ? 'Odtwórz animację' : 'Zatrzymaj animację';
  }

  function updatePlayback() {
    if (userPaused || !visible || document.hidden) video.pause();
    else video.play().catch(updateLabel);
  }

  toggle.addEventListener('click', () => {
    userPaused = !video.paused;
    updatePlayback();
  });
  video.addEventListener('play', updateLabel);
  video.addEventListener('pause', updateLabel);
  video.addEventListener('error', () => { toggle.hidden = true; });
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
  toggle.hidden = false;
})();
