(() => {
  const root = document.documentElement;
  let message = 'loading assets...';
  let active = true;
  let expired = false;

  const update = () => {
    const screen = document.getElementById('loading-screen');
    if (screen) {
      if (active) screen.hidden = false;
      else screen.remove();
    }
    const status = document.getElementById('loading-status');
    if (status) status.textContent = message;
    const content = document.getElementById('app');
    if (content) content.inert = active;
  };

  const finish = () => {
    active = false;
    clearTimeout(deadline);
    root.classList.remove('is-loading');
    update();
  };

  const deadline = setTimeout(() => {
    expired = true;
    finish();
  }, 15000);

  root.classList.add('is-loading');
  document.addEventListener('readystatechange', update);
  window.addEventListener('pageshow', (event) => {
    if (event.persisted) finish();
  });
  window.AsaiLoading = {
    get expired() {
      return expired;
    },
    stage(text) {
      if (!active) return;
      message = text;
      update();
    },
    finish,
  };
  update();
})();
