(() => {
  const region = document.querySelector('#mozliwosci');
  if (!region) return;
  const track = region.querySelector('.slides');
  const slides = [...region.querySelectorAll('.feature-slide')];
  const dots = [...region.querySelectorAll('.carousel-dots [data-slide]')];
  const controls = region.querySelector('.carousel-controls');
  const status = region.querySelector('#slide-status');
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  let index = 0;
  let scrollTimer;
  let trackWidth = 0;

  function updateSelection(next, announce = false) {
    index = next;
    slides.forEach((slide, i) => { slide.inert = i !== index; });
    dots.forEach((dot, i) => {
      if (i === index) dot.setAttribute('aria-current', 'true');
      else dot.removeAttribute('aria-current');
    });
    const activeDot = dots[index];
    const dotsRow = activeDot?.closest('.carousel-dots');
    if (dotsRow && dotsRow.scrollWidth > dotsRow.clientWidth) {
      const dotLeft = activeDot.getBoundingClientRect().left - dotsRow.getBoundingClientRect().left + dotsRow.scrollLeft;
      dotsRow.scrollTo({
        left: Math.max(0, dotLeft - dotsRow.clientWidth / 2 + activeDot.clientWidth / 2),
        behavior: reducedMotion.matches ? 'instant' : 'smooth',
      });
    }
    if (announce) status.textContent = `Slajd ${index + 1} z ${slides.length}: ${slides[index].querySelector('h3').textContent}`;
  }

  function show(next) {
    updateSelection((next + slides.length) % slides.length, true);
    track.scrollTo({ left: index * track.clientWidth, behavior: reducedMotion.matches ? 'instant' : 'smooth' });
  }

  track.classList.add('slider-ready');
  track.addEventListener('scroll', () => {
    clearTimeout(scrollTimer);
    scrollTimer = setTimeout(() => {
      const next = Math.max(0, Math.min(slides.length - 1, Math.round(track.scrollLeft / track.clientWidth)));
      if (next !== index) updateSelection(next, true);
    }, 150);
  }, { passive: true });
  region.querySelectorAll('[data-direction]').forEach(button => {
    button.addEventListener('click', () => show(index + Number(button.dataset.direction)));
  });
  dots.forEach((dot, i) => dot.addEventListener('click', () => show(i)));
  region.addEventListener('keydown', event => {
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
    event.preventDefault();
    show(index + (event.key === 'ArrowRight' ? 1 : -1));
  });
  new ResizeObserver(() => {
    if (trackWidth === track.clientWidth) return;
    trackWidth = track.clientWidth;
    track.scrollTo({ left: index * trackWidth, behavior: 'instant' });
  }).observe(track);
  updateSelection(0);
  controls.hidden = false;
})();
