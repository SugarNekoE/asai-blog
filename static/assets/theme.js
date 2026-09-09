try {
  document.documentElement.dataset.theme =
    localStorage.getItem('asai-theme') === 'light' ? 'light' : 'dark';
} catch {
  // Storage may be blocked; retain the theme from the static page.
}
