(() => {
  const allowed = ['light', 'dark', 'contrast'];
  const root = document.documentElement;
  let theme = matchMedia('(prefers-contrast: more)').matches ? 'contrast' : 'dark';
  try {
    const saved = localStorage.getItem('bielik-theme');
    if (allowed.includes(saved)) theme = saved;
  } catch {}

  function apply(value) {
    if (!allowed.includes(value)) return;
    root.dataset.theme = value;
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.content = { light: '#f5f2e9', dark: '#151613', contrast: '#000000' }[value];
    document.querySelectorAll('[data-theme-choice]').forEach(button => {
      button.setAttribute('aria-pressed', String(button.dataset.themeChoice === value));
    });
  }

  apply(theme);
  document.addEventListener('DOMContentLoaded', () => {
    const group = document.querySelector('.theme-picker');
    if (!group) return;
    apply(theme);
    group.hidden = false;
    group.querySelectorAll('[data-theme-choice]').forEach(button => {
      button.addEventListener('click', () => {
        theme = button.dataset.themeChoice;
        apply(theme);
        try { localStorage.setItem('bielik-theme', theme); } catch {}
      });
    });
  });
})();
