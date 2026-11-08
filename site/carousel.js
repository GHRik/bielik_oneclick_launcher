(() => {
  const region = document.querySelector('#mozliwosci');
  if (!region) return;
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

  function updatePause() {
    pause.textContent = paused ? 'Wznów' : 'Wstrzymaj';
    pause.setAttribute('aria-label', paused ? 'Wznów automatyczne slajdy' : 'Wstrzymaj automatyczne slajdy');
  }

  function show(next, manual = false) {
    index = (next + slides.length) % slides.length;
    slides.forEach((slide, i) => { slide.hidden = i !== index; });
    dots.forEach((dot, i) => {
      if (i === index) dot.setAttribute('aria-current', 'true');
      else dot.removeAttribute('aria-current');
    });
    if (manual) {
      paused = true;
      updatePause();
      status.textContent = `Slajd ${index + 1} z ${slides.length}: ${slides[index].querySelector('h3').textContent}`;
    }
  }

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
  new IntersectionObserver(entries => { visible = entries[0].isIntersecting; }, { threshold: 0.25 }).observe(region);
  setInterval(() => {
    if (!paused && visible && !hovered && !document.hidden && !region.contains(document.activeElement)) show(index + 1);
  }, 7000);
  show(0);
  updatePause();
  controls.hidden = false;
})();
