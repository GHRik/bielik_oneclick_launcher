(() => {
  const region = document.querySelector('#mozliwosci');
  if (!region) return;
  const track = region.querySelector('.slides');
  const slides = [...region.querySelectorAll('.feature-slide')];
  const dots = [...region.querySelectorAll('[data-slide]')];
  const controls = region.querySelector('.carousel-controls');
  const pause = region.querySelector('.carousel-pause');
  const status = region.querySelector('#slide-status');
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  let index = 0;
  let paused = reducedMotion.matches;
  let visible = false;
  let hovered = false;
  let scrollTimer;
  let trackWidth = 0;

  function updateHeight() {
    track.style.height = `${slides[index].getBoundingClientRect().height}px`;
  }

  function updatePause() {
    pause.dataset.paused = String(paused);
    const label = paused ? 'Wznów automatyczne slajdy' : 'Wstrzymaj automatyczne slajdy';
    pause.setAttribute('aria-label', label);
    pause.title = label;
  }

  function updateSelection(next, announce = false) {
    index = next;
    updateHeight();
    slides.forEach((slide, i) => { slide.inert = i !== index; });
    dots.forEach((dot, i) => {
      if (i === index) dot.setAttribute('aria-current', 'true');
      else dot.removeAttribute('aria-current');
    });
    if (announce) status.textContent = `Slajd ${index + 1} z ${slides.length}: ${slides[index].querySelector('h3').textContent}`;
  }

  function pauseManually() {
    paused = true;
    updatePause();
  }

  function show(next, manual = false) {
    if (manual) pauseManually();
    updateSelection((next + slides.length) % slides.length, manual);
    track.scrollTo({ left: index * track.clientWidth, behavior: reducedMotion.matches ? 'instant' : 'smooth' });
  }

  track.classList.add('slider-ready');
  track.addEventListener('pointerdown', pauseManually);
  track.addEventListener('wheel', event => {
    if (Math.abs(event.deltaX) > Math.abs(event.deltaY)) pauseManually();
  }, { passive: true });
  track.addEventListener('scroll', () => {
    clearTimeout(scrollTimer);
    scrollTimer = setTimeout(() => {
      const next = Math.max(0, Math.min(slides.length - 1, Math.round(track.scrollLeft / track.clientWidth)));
      if (next !== index) updateSelection(next, true);
    }, 150);
  }, { passive: true });
  region.querySelectorAll('[data-direction]').forEach(button => {
    button.addEventListener('click', () => show(index + Number(button.dataset.direction), true));
  });
  dots.forEach((dot, i) => dot.addEventListener('click', () => show(i, true)));
  pause.addEventListener('click', () => { paused = !paused; updatePause(); });
  region.addEventListener('keydown', event => {
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
    event.preventDefault();
    show(index + (event.key === 'ArrowRight' ? 1 : -1), true);
  });
  region.addEventListener('mouseenter', () => { hovered = true; });
  region.addEventListener('mouseleave', () => { hovered = false; });
  reducedMotion.addEventListener('change', event => {
    if (event.matches) { paused = true; updatePause(); }
  });
  new ResizeObserver(() => {
    if (trackWidth === track.clientWidth) return;
    trackWidth = track.clientWidth;
    updateHeight();
    track.scrollTo({ left: index * trackWidth, behavior: 'instant' });
  }).observe(track);
  const slideObserver = new ResizeObserver(updateHeight);
  slides.forEach(slide => slideObserver.observe(slide));
  new IntersectionObserver(entries => { visible = entries[0].isIntersecting; }, { threshold: 0.25 }).observe(region);
  setInterval(() => {
    if (!paused && visible && !hovered && !document.hidden && !region.contains(document.activeElement)) show(index + 1);
  }, 7000);
  updateSelection(0);
  updatePause();
  controls.hidden = false;
})();
