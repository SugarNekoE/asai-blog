import './browser/content.js';
import { registerClipboard } from './browser/clipboard.js?v=elm-controls-1';
import {
  pageLoaded,
  firstPaintOpportunity,
  observeAssets,
} from './browser/assets.js?v=elm-startup-1';
import { connectDialogs } from './browser/dialogs.js?v=elm-startup-1';
import { connectFocus } from './browser/focus.js';
import { connectKeyboard } from './browser/keyboard.js';
import { connectLinks } from './browser/links.js';

const loading = window.AsaiLoading;
const fallback = document.getElementById('app');
const content = document.getElementById('static-content');

const recover = (error) => {
  document.querySelector('.workspace')?.remove();
  loading?.finish();
  if (error) console.warn('Interactive notebook unavailable; using the static page.', error);
};

async function mountInterface(bootstrap, posts) {
  if (loading?.expired) return;
  const mount = document.createElement('div');
  // Mount separately so initialization failure leaves the static page readable.
  fallback.before(mount);
  let app;
  try {
    const clock = new Date();
    performance.mark('asai:elm-init');
    app = window.Elm.Main.init({
      node: mount,
      flags: {
        ...bootstrap,
        posts,
        clock: { now: clock.getTime(), offset: clock.getTimezoneOffset() },
        article: content.innerHTML,
        theme: document.documentElement.dataset.theme,
        search: location.search,
      },
    });
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
  if (loading?.expired) return recover();
  fallback.remove();
  loading?.finish();
  Promise.all([pageLoaded, firstPaintOpportunity()]).then(([loading, rendering]) => {
    app.ports.timingsChanged.send({ loading, rendering });
  });
  if (location.hash)
    requestAnimationFrame(() => {
      document.getElementById(decodeURIComponent(location.hash.slice(1)))?.scrollIntoView();
    });
}

try {
  registerClipboard(window.Elm?.CodeBlock);
  if (!window.Elm?.Startup || !window.Elm.Main || !content || loading?.expired) {
    recover();
  } else {
    const bootstrap = JSON.parse(document.getElementById('site-bootstrap').textContent);
    const startup = window.Elm.Startup.init({ flags: bootstrap.indexUrl });
    startup.ports.startupStage.subscribe((stage) => loading?.stage(stage));
    startup.ports.startupFailed.subscribe(() => recover());
    // Let the worker's effect queue drain before initializing another Elm program.
    startup.ports.startupReady.subscribe((posts) =>
      Promise.resolve()
        .then(() => mountInterface(bootstrap, posts))
        .catch(recover),
    );
    observeAssets(startup);
    startup.ports.startupBegin.send(fallback.textContent);
  }
} catch (error) {
  recover(error);
}
