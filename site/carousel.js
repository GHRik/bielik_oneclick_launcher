(() => {
  const region = document.querySelector('#mozliwosci');
  if (!region) return;
  const track = region.querySelector('.slides');
  const slides = [...region.querySelectorAll('.feature-slide')];
  const dots = [...region.querySelectorAll('.carousel-dots [data-slide]')];
  const controls = region.querySelector('.carousel-controls');
  const pause = region.querySelector('.carousel-pause');
  const status = region.querySelector('#slide-status');
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const hoverPause = matchMedia('(hover: hover) and (pointer: fine)');
  let index = 0;
  let paused = reducedMotion.matches;
  let hovered = false;
  let scrollTimer;
  let trackWidth = 0;

  function updatePause() {
    pause.dataset.paused = String(paused);
    const label = paused ? 'Wznów automatyczne slajdy' : 'Wstrzymaj automatyczne slajdy';
    pause.setAttribute('aria-label', label);
    pause.title = label;
  }

  function updateSelection(next, announce = false) {
    index = next;
    slides.forEach((slide, i) => { slide.inert = i !== index; });
    dots.forEach((dot, i) => {
      if (i === index) dot.setAttribute('aria-current', 'true');
      else dot.removeAttribute('aria-current');
    });
    const activeDot = dots[index];
    if (activeDot && controls) {
      const dotsRow = activeDot.closest('.carousel-dots');
      if (dotsRow) {
        const dotLeft = activeDot.offsetLeft - dotsRow.clientWidth / 2 + activeDot.clientWidth / 2;
        dotsRow.scrollTo({ left: Math.max(0, dotLeft), behavior: reducedMotion.matches ? 'instant' : 'smooth' });
      }
    }
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
    if (manual) {
      const { top, bottom } = region.getBoundingClientRect();
      const vh = window.innerHeight;
      if (top < 0 || bottom > vh) region.scrollIntoView({ block: 'nearest', behavior: reducedMotion.matches ? 'instant' : 'smooth' });
    }
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
  pause.addEventListener('click', () => {
    paused = !paused;
    hovered = false;
    updatePause();
  });
  region.addEventListener('keydown', event => {
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
    event.preventDefault();
    show(index + (event.key === 'ArrowRight' ? 1 : -1), true);
  });
  if (hoverPause.matches) {
    region.addEventListener('mouseenter', () => { hovered = true; });
    region.addEventListener('mouseleave', () => { hovered = false; });
  }
  reducedMotion.addEventListener('change', event => {
    if (event.matches) { paused = true; updatePause(); }
  });
  new ResizeObserver(() => {
    if (trackWidth === track.clientWidth) return;
    trackWidth = track.clientWidth;
    track.scrollTo({ left: index * trackWidth, behavior: 'instant' });
  }).observe(track);
  new IntersectionObserver(entries => {
    const visible = entries[0].isIntersecting;
    region.dataset.carouselVisible = String(visible);
  }, { threshold: 0.25 }).observe(region);
  setInterval(() => {
    if (paused || document.hidden || region.dataset.carouselVisible !== 'true') return;
    if (hoverPause.matches && hovered) return;
    if (region.contains(document.activeElement)) return;
    show(index + 1);
  }, 7000);
  updateSelection(0);
  updatePause();
  controls.hidden = false;
})();
