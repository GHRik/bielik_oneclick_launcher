(() => {
  const screenshots = document.querySelectorAll('#mozliwosci .feature-slide figure img');
  if (!screenshots.length || typeof HTMLDialogElement === 'undefined') return;

  const dialog = document.createElement('dialog');
  dialog.className = 'screenshot-zoom';
  dialog.setAttribute('aria-label', 'Powiększony ekran aplikacji');
  dialog.innerHTML = '<button class="screenshot-zoom-close" type="button" aria-label="Zamknij powiększenie" autofocus>×</button><div class="screenshot-zoom-content"></div>';
  document.body.append(dialog);
  const content = dialog.querySelector('.screenshot-zoom-content');
  dialog.querySelector('button').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if (event.target !== dialog) return;
    const bounds = dialog.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right ||
        event.clientY < bounds.top || event.clientY > bounds.bottom) dialog.close();
  });
  dialog.addEventListener('close', () => {
    if (dialog.open) return;
    document.body.classList.remove('screenshot-zoom-open');
    content.replaceChildren();
  });

  screenshots.forEach(image => {
    const screen = image.closest('.annotated-screen') || image;
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'screenshot-zoom-trigger';
    button.setAttribute('aria-label', 'Powiększ: ' + image.alt);
    button.setAttribute('aria-haspopup', 'dialog');
    screen.before(button);
    button.append(screen);
    button.addEventListener('click', () => {
      const enlarged = screen.cloneNode(true);
      const enlargedImage = enlarged.matches('img') ? enlarged : enlarged.querySelector('img');
      enlargedImage.loading = 'eager';
      content.style.width = `min(86vw, calc((100dvh - 100px) * ${image.width / image.height}))`;
      content.replaceChildren(enlarged);
      dialog.showModal();
      document.body.classList.add('screenshot-zoom-open');
    });
  });
})();
