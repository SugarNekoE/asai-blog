import './browser/content.js';
import { pageLoaded, firstPaintOpportunity, fontsReady } from './browser/assets.js';
import { connectDialogs } from './browser/dialogs.js';
import { connectFocus } from './browser/focus.js';
import { connectKeyboard } from './browser/keyboard.js';
import { connectLinks } from './browser/links.js';

(async () => {
  const loading = window.AsaiLoading;
  const fallback = document.getElementById('app');
  const content = document.getElementById('static-content');
  if (!window.Elm || !content || loading?.expired) {
    loading?.finish();
    return;
  }
  let app;
  try {
    const pending = new Set(['fonts', 'notes', 'assets']);
    const showStage = () => {
      const next = ['fonts', 'notes', 'assets'].find((stage) => pending.has(stage));
      loading?.stage(next ? `loading ${next}...` : 'rendering page...');
    };
    const track = (stage, promise) =>
      promise.finally(() => {
        pending.delete(stage);
        showStage();
      });
    showStage();
    const fonts = fontsReady(fallback.textContent);
    const notes = fetch('/api/posts.json').then((response) => {
      if (!response.ok) throw new Error('Index unavailable');
      return response.json();
    });
    const [, index] = await Promise.all([
      track('fonts', fonts),
      track('notes', notes),
      track('assets', pageLoaded),
    ]);
    if (loading?.expired) return;
    const mount = document.createElement('div');
    // Mount separately so any failure leaves the static site readable.
    fallback.before(mount);
    try {
      const clock = new Date();
      const flags = {
        index,
        clock: { now: clock.getTime(), offset: clock.getTimezoneOffset() },
        article: content.innerHTML,
        page: document.body.dataset.page,
        category: document.body.dataset.category || '',
        theme: document.documentElement.dataset.theme,
        search: location.search,
        headings: JSON.parse(document.getElementById('article-headings')?.textContent || '[]'),
      };
      performance.mark('asai:elm-init');
      app = window.Elm.Main.init({ node: mount, flags });
    } catch (error) {
      mount.remove();
      throw error;
    }
    const refreshClock = () => app.ports.clockRefreshRequested.send(null);
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') refreshClock();
    });
    window.addEventListener('pageshow', refreshClock);
    app.ports.setTheme.subscribe((theme) => {
      document.documentElement.dataset.theme = theme;
      try {
        localStorage.setItem('asai-theme', theme);
      } catch {
        // Storage may be blocked; the selected theme still applies to this page.
      }
    });
    connectFocus(app);
    connectDialogs(app);
    app.ports.replaceQuery.subscribe((query) => {
      history.replaceState(null, '', location.pathname + query + location.hash);
    });
    connectLinks(app);
    const keyboardReady = connectKeyboard(app);
    app.ports.browserReady.send(null);
    await keyboardReady;
    fallback.remove();
    loading?.finish();
    Promise.all([pageLoaded, firstPaintOpportunity()]).then(([loading, rendering]) => {
      app.ports.timingsChanged.send({ loading, rendering });
    });
    if (location.hash)
      requestAnimationFrame(() => {
        document.getElementById(decodeURIComponent(location.hash.slice(1)))?.scrollIntoView();
      });
  } catch (error) {
    if (app) document.querySelector('.workspace')?.remove();
    loading?.finish();
    console.warn('Interactive notebook unavailable; using the static page.', error);
  }
})();
