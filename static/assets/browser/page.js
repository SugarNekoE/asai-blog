export function readPage() {
  const fallback = document.getElementById('app');
  const content = document.getElementById('static-content');
  const bootstrap = JSON.parse(document.getElementById('site-bootstrap').textContent);
  return {
    fallback,
    sample: fallback.textContent,
    indexUrl: bootstrap.indexUrl,
    flags: {
      ...bootstrap,
      article: content.innerHTML,
      theme: document.documentElement.dataset.theme,
      search: location.search,
      fragment: location.hash,
    },
  };
}

export function mountInterface(program, page, posts) {
  const mount = document.createElement('div');
  // Keep the static page intact if initialization fails.
  page.fallback.before(mount);
  try {
    const clock = new Date();
    performance.mark('asai:elm-init');
    return program.init({
      node: mount,
      flags: {
        ...page.flags,
        posts,
        clock: { now: clock.getTime(), offset: clock.getTimezoneOffset() },
      },
    });
  } catch (error) {
    mount.remove();
    throw error;
  }
}

export function connectPage(app) {
  window.addEventListener('pageshow', () => app.ports.clockRefreshRequested.send(null));
  app.ports.setTheme.subscribe((theme) => {
    document.documentElement.dataset.theme = theme;
    try {
      localStorage.setItem('asai-theme', theme);
    } catch {
      // Storage may be blocked; the selected theme still applies to this page.
    }
  });
  app.ports.replaceQuery.subscribe((query) => {
    history.replaceState(null, '', location.pathname + query + location.hash);
  });
}
