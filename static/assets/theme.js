try {
  document.documentElement.dataset.theme =
    localStorage.getItem('asai-theme') === 'light' ? 'light' : 'dark';
} catch (_) {}
