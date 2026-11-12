(() => {
  const dialog = document.querySelector('#txt-preview');
  const trigger = document.querySelector('[aria-controls="txt-preview"]');
  if (!dialog || !trigger) return;

  trigger.addEventListener('click', () => dialog.showModal());
  dialog.querySelector('[data-close-preview]').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if (event.target !== dialog) return;
    const bounds = dialog.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right ||
        event.clientY < bounds.top || event.clientY > bounds.bottom) dialog.close();
  });
})();
