(() => {
  const root = document.documentElement;
  const system = window.matchMedia('(prefers-color-scheme: dark)');
  const apply = (value) => {
    const preference = value === 'light' || value === 'dark' ? value : 'auto';
    root.dataset.themePreference = preference;
    root.dataset.theme = preference === 'auto' ? (system.matches ? 'dark' : 'light') : preference;
  };

  let saved;
  try {
    saved = localStorage.getItem('asai-theme');
  } catch {
    // Follow the system when storage is unavailable.
  }
  apply(saved);

  system.addEventListener('change', () => {
    if (root.dataset.themePreference === 'auto') apply('auto');
  });

  window.AsaiTheme = {
    set(preference) {
      apply(preference);
      try {
        localStorage.setItem('asai-theme', root.dataset.themePreference);
      } catch {
        // Apply the choice for this page even when it cannot be saved.
      }
    },
  };
})();
