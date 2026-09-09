// Only assign HTML generated from trusted repository Markdown.
class BlogContent extends HTMLElement {
  set html(value) {
    if (value !== this._html) {
      this._html = value;
      this.innerHTML = value;
      window.AsaiCodeBlocks?.enhance(this);
    }
  }
}
customElements.define('blog-content', BlogContent);

function browserClock() {
  const now = new Date();
  const pad = (value) => String(value).padStart(2, '0');
  return {
    label: `${now.getFullYear()}/${pad(now.getMonth() + 1)}/${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`,
    iso: now.toISOString(),
  };
}

// Register before fetching JSON: the load event may fire while it is pending.
const pageLoaded = new Promise((resolve) => {
  const navigation = performance.getEntriesByType('navigation')[0];
  if (navigation && navigation.loadEventStart > 0) {
    resolve(navigation.loadEventStart - navigation.startTime);
  } else {
    window.addEventListener(
      'load',
      () => {
        const entry = performance.getEntriesByType('navigation')[0];
        resolve(entry ? entry.loadEventStart - entry.startTime : performance.now());
      },
      { once: true },
    );
  }
});

function firstPaintOpportunity() {
  return new Promise((resolve) => {
    // Two frames allow a paint opportunity; this does not measure GPU completion.
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        performance.mark('asai:first-paint-opportunity');
        const measure = performance.measure(
          'asai:initial-render',
          'asai:elm-init',
          'asai:first-paint-opportunity',
        );
        resolve(measure.duration);
      });
    });
  });
}

function createLinkHints(app) {
  const alphabet = 'asdfghjkl';
  let targets = new Map();
  let active = false;
  const clear = () => {
    active = false;
    targets.clear();
  };
  const cancel = () => {
    if (active) app.ports.hintKey.send('Escape');
  };
  const visibleRect = (link) => {
    const style = getComputedStyle(link);
    if (
      style.visibility !== 'visible' ||
      style.opacity === '0' ||
      link.closest('[inert], [aria-hidden="true"]')
    )
      return null;
    return [...link.getClientRects()].find((rect) => {
      const left = Math.max(0, rect.left);
      const right = Math.min(innerWidth, rect.right);
      const top = Math.max(0, rect.top);
      const bottom = Math.min(innerHeight, rect.bottom);
      if (right <= left || bottom <= top) return false;
      const hit = document.elementFromPoint((left + right) / 2, (top + bottom) / 2);
      return hit === link || link.contains(hit);
    });
  };
  app.ports.collectLinkHints.subscribe(() => {
    clear();
    active = true;
    const links = [...document.querySelectorAll('a[href], button[data-link-hint]')]
      .filter(
        (link) =>
          (link instanceof HTMLAnchorElement || link instanceof HTMLButtonElement) &&
          !link.disabled &&
          link.getAttribute('aria-disabled') !== 'true',
      )
      .map((link) => ({ link, rect: visibleRect(link) }))
      .filter(({ rect }) => rect);
    let length = 1;
    while (alphabet.length ** length < links.length) length++;
    const hints = links.map(({ link, rect }, index) => {
      let number = index;
      let key = '';
      for (let digit = 0; digit < length; digit++) {
        key = alphabet[number % alphabet.length] + key;
        number = Math.floor(number / alphabet.length);
      }
      targets.set(key, link);
      return {
        key,
        label:
          link.getAttribute('data-link-hint') ||
          link.getAttribute('aria-label') ||
          link.textContent.trim() ||
          link.href,
        x: Math.max(4, Math.min(innerWidth - 40, rect.left)),
        y: Math.max(4, Math.min(innerHeight - 24, rect.top)),
      };
    });
    app.ports.linkHintsReady.send(hints);
  });
  app.ports.clearLinkHints.subscribe(clear);
  app.ports.followLinkHint.subscribe((key) => {
    const link = targets.get(key);
    clear();
    if (link?.isConnected && visibleRect(link)) link.click();
  });
  window.addEventListener('scroll', cancel, true);
  window.addEventListener('resize', cancel);
  window.addEventListener('blur', cancel);
  document.addEventListener('pointerdown', cancel);
  return { isActive: () => active };
}

(async () => {
  const loading = window.AsaiLoading;
  const fallback = document.getElementById('app');
  const content = document.getElementById('static-content');
  if (!window.Elm || !content || loading?.expired) {
    loading?.finish();
    return;
  }
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
    const fontSample = fallback.textContent;
    const cjkSample = fontSample.replace(/[\u0000-\u2fff]/g, '');
    const fonts = document.fonts
      ? Promise.allSettled([
          document.fonts.load('400 16px "Noto Sans"', fontSample),
          document.fonts.load('italic 400 16px "Noto Sans"', fontSample),
          document.fonts.load('400 16px "Noto Sans Mono"', fontSample),
          document.fonts.load('400 16px "Noto Sans CJK SC"', cjkSample),
          document.fonts.load('400 16px "Noto Sans Mono CJK SC"', cjkSample),
          document.fonts.load('400 20px "Noto Sans Symbols"', '↗'),
          document.fonts.load('400 20px "Noto Sans Symbols 2"', '◐☼'),
        ]).then(() => document.fonts.ready)
      : Promise.resolve();
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
    const params = new URLSearchParams(location.search);
    const requestedPage = Number(params.get('page') || 1);
    const requestedSize = Number(params.get('perPage') || 10);
    const mount = document.createElement('div');
    // Mount separately so any failure leaves the static site readable.
    fallback.before(mount);
    let app;
    try {
      const flags = {
        index,
        clock: browserClock(),
        article: content.innerHTML,
        page: document.body.dataset.page,
        category:
          document.body.dataset.page === 'index'
            ? params.get('category') || ''
            : document.body.dataset.category || '',
        theme: document.documentElement.dataset.theme,
        selectedTags: params.getAll('tag'),
        query: params.get('q') || '',
        indexPage:
          Number.isInteger(requestedPage) && requestedPage > 0 && requestedPage <= 2147483647
            ? requestedPage
            : 1,
        pageSize: [10, 30, 50, 100].includes(requestedSize) ? requestedSize : 10,
        oldest: params.get('sort') === 'oldest',
        headings: Array.from(content.querySelectorAll('h2[id], h3[id]')).map((node) => ({
          id: node.id,
          label: node.textContent,
        })),
      };
      performance.mark('asai:elm-init');
      app = Elm.Main.init({ node: mount, flags });
    } catch (error) {
      mount.remove();
      throw error;
    }
    fallback.remove();
    loading?.finish();
    Promise.all([pageLoaded, firstPaintOpportunity()]).then(([loading, rendering]) => {
      app.ports.timingsChanged.send({ loading, rendering });
    });
    let clockTimer;
    const updateClock = () => {
      clearTimeout(clockTimer);
      app.ports.clockChanged.send(browserClock());
      clockTimer = setTimeout(updateClock, 60000 - (Date.now() % 60000));
    };
    updateClock();
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') updateClock();
    });
    window.addEventListener('pageshow', updateClock);
    app.ports.setTheme.subscribe((theme) => {
      document.documentElement.dataset.theme = theme;
      try {
        localStorage.setItem('asai-theme', theme);
      } catch (_) {}
    });
    const searchDialog = document.getElementById('search-dialog');
    const keymapDialog = document.getElementById('keymap-dialog');
    for (const dialog of [searchDialog, keymapDialog]) {
      dialog.addEventListener('keydown', (event) => {
        if (event.key !== 'Tab') return;
        const controls = [
          ...dialog.querySelectorAll('button, input, select, textarea, a[href], [tabindex]'),
        ].filter((node) => !node.disabled && node.tabIndex >= 0 && node.getClientRects().length);
        const first = controls[0];
        const last = controls[controls.length - 1];
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault();
          last.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first.focus();
        }
      });
    }
    let activeDialog;
    let panelOpener;
    let panelFrame;
    const setPanelOpen = (dialog, isOpen, focusId) => {
      cancelAnimationFrame(panelFrame);
      if (isOpen) {
        if (!activeDialog) panelOpener = document.activeElement;
        if (activeDialog && activeDialog !== dialog) activeDialog.close();
        activeDialog = dialog;
        panelFrame = requestAnimationFrame(() => {
          if (!dialog.open) dialog.showModal();
          document.documentElement.classList.add('search-open');
          document.getElementById(focusId).focus();
        });
      } else if (activeDialog === dialog) {
        dialog.close();
        activeDialog = null;
        document.documentElement.classList.remove('search-open');
        const opener =
          panelOpener?.isConnected &&
          panelOpener.tabIndex >= 0 &&
          !panelOpener.closest('dialog') &&
          panelOpener.getClientRects().length
            ? panelOpener
            : [...document.querySelectorAll('.mobile-toggle, .search-launch')].find(
                (node) => node.getClientRects().length,
              );
        opener?.focus({ preventScroll: true });
      }
    };
    app.ports.setSearchOpen.subscribe((isOpen) =>
      setPanelOpen(searchDialog, isOpen, 'launcher-search'),
    );
    app.ports.setKeymapOpen.subscribe((isOpen) =>
      setPanelOpen(keymapDialog, isOpen, 'keymap-close'),
    );
    app.ports.setImmersiveMode.subscribe(() => {
      if (activeDialog) setPanelOpen(activeDialog, false);
      document.querySelectorAll('.tag-picker[open]').forEach((picker) => {
        picker.open = false;
      });
      requestAnimationFrame(() => document.getElementById('main')?.focus({ preventScroll: true }));
    });
    app.ports.scrollSearchResult.subscribe((index) => {
      requestAnimationFrame(() => {
        if (searchDialog.open)
          document.getElementById(`search-result-${index}`)?.scrollIntoView({ block: 'nearest' });
      });
    });
    app.ports.scrollNotebook.subscribe(() => {
      requestAnimationFrame(() => {
        const heading = document.getElementById('notebook-heading');
        heading?.scrollIntoView({ block: 'start' });
        heading?.focus({ preventScroll: true });
      });
    });
    app.ports.persistFilters.subscribe(({ tags, category, query, indexPage, pageSize, oldest }) => {
      if (document.body.dataset.page !== 'index') return;
      const url = new URL(location.href);
      url.searchParams.delete('tag');
      tags.forEach((tag) => url.searchParams.append('tag', tag));
      for (const [key, value] of [
        ['category', category],
        ['q', query],
        ['page', indexPage > 1 ? String(indexPage) : ''],
        ['perPage', pageSize !== 10 ? String(pageSize) : ''],
        ['sort', oldest ? 'oldest' : ''],
      ]) {
        if (value) url.searchParams.set(key, value);
        else url.searchParams.delete(key);
      }
      history.replaceState(null, '', url);
    });
    const linkHints = createLinkHints(app);
    document.addEventListener('keydown', (event) => {
      if (event.defaultPrevented || event.isComposing || event.repeat) return;
      const editing =
        event.target.isContentEditable ||
        event.target.closest('input, textarea, select, [contenteditable="true"]');
      if (
        event.key.toLowerCase() === 'i' &&
        event.shiftKey &&
        !editing &&
        !event.ctrlKey &&
        !event.metaKey &&
        !event.altKey
      ) {
        event.preventDefault();
        app.ports.pageCommand.send('immersive');
        return;
      }
      if (linkHints.isActive()) {
        if (
          !event.ctrlKey &&
          !event.metaKey &&
          !event.altKey &&
          (event.key === 'Escape' || event.key === 'Backspace' || /^[a-z]$/i.test(event.key))
        ) {
          event.preventDefault();
          app.ports.hintKey.send(event.key);
        }
        return;
      }
      if (
        event.key === 'Escape' &&
        !activeDialog &&
        !event.ctrlKey &&
        !event.metaKey &&
        !event.altKey
      ) {
        event.preventDefault();
        document.activeElement?.blur();
        return;
      }
      const shortcut =
        event.key === '/' && !editing && !event.ctrlKey && !event.metaKey && !event.altKey;
      if (event.key === '?' && !editing && !event.ctrlKey && !event.metaKey && !event.altKey) {
        event.preventDefault();
        app.ports.keymapRequested.send(null);
      }
      if (shortcut) {
        event.preventDefault();
        if (searchDialog.open) document.getElementById('launcher-search').focus();
        else app.ports.searchRequested.send(null);
        return;
      }
      if (editing || activeDialog || event.ctrlKey || event.metaKey || event.altKey) return;
      const command = { t: 'theme', o: 'outline', f: 'hints' }[event.key];
      if (command) {
        event.preventDefault();
        app.ports.pageCommand.send(command);
      } else if (
        event.key === 'Enter' &&
        !event.target.closest('a, button, summary, [role="button"]')
      ) {
        event.preventDefault();
        app.ports.pageCommand.send('open-note');
      }
    });
    if (params.has('search')) app.ports.searchRequested.send(null);
    if (location.hash)
      requestAnimationFrame(() => {
        document.getElementById(decodeURIComponent(location.hash.slice(1)))?.scrollIntoView();
      });
  } catch (error) {
    loading?.finish();
    console.warn('Interactive notebook unavailable; using the static page.', error);
  }
})();
