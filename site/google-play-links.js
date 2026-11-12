(() => {
  const mobile = navigator.userAgentData?.mobile ||
    /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
  if (!mobile) return;

  document.querySelectorAll('[data-google-play-link]').forEach(link => {
    link.href = 'https://play.google.com/store/apps/details?id=bielik.ai';
  });
})();
