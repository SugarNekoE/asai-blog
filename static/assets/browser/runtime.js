import './content.js';
import { pageLoaded, firstPaintOpportunity, observeAssets } from './assets.js';
import { registerClipboard } from './clipboard.js';
import { connectDialogs } from './dialogs.js';
import { connectFocus } from './focus.js';
import { connectKeyboard } from './keyboard.js';
import { connectLinkTargets } from './link-targets.js';
import { readPage, mountInterface, connectPage } from './page.js';

export function start(Elm) {
  const loading = window.AsaiLoading;
  const recover = (error) => {
    document.querySelector('.workspace')?.remove();
    loading?.finish();
    if (error) console.warn('Interactive notebook unavailable; using the static page.', error);
  };
  const activate = async (page, posts) => {
    if (loading?.expired) return;
    const app = mountInterface(Elm.Main, page, posts);
    connectPage(app);
    connectFocus(app);
    connectDialogs(app);
    connectLinkTargets(app);
    const keyboardReady = connectKeyboard(app);
    app.ports.browserReady.send(null);
    await keyboardReady;
    if (loading?.expired) return recover();
    page.fallback.remove();
    loading?.finish();
    Promise.all([pageLoaded, firstPaintOpportunity()]).then(([loading, rendering]) => {
      app.ports.timingsChanged.send({ loading, rendering });
    });
  };
  try {
    if (!Elm?.Startup || !Elm.Main) return recover();
    registerClipboard(Elm.CodeBlock);
    if (loading?.expired) return;
    const page = readPage();
    const startup = Elm.Startup.init({ flags: page.indexUrl });
    startup.ports.startupStage.subscribe((stage) => loading?.stage(stage));
    startup.ports.startupFailed.subscribe(() => recover());
    // Drain the startup worker's effects before initializing another Elm program.
    startup.ports.startupReady.subscribe((posts) =>
      Promise.resolve()
        .then(() => activate(page, posts))
        .catch(recover),
    );
    observeAssets(startup);
    startup.ports.startupBegin.send(page.sample);
  } catch (error) {
    recover(error);
  }
}
