export function connectDialogs(app) {
  document.addEventListener('click', (event) => {
    for (const picker of document.querySelectorAll('.tag-picker[open]')) {
      if (!picker.contains(event.target)) picker.open = false;
    }
  });
  const searchDialog = document.getElementById('search-dialog');
  const keymapDialog = document.getElementById('keymap-dialog');
  for (const [dialog, focusId] of [
    [searchDialog, 'launcher-search'],
    [keymapDialog, 'keymap-close'],
  ]) {
    dialog.addEventListener('focusin', (event) => {
      if (
        dialog.open &&
        !event.target.isContentEditable &&
        !event.target.closest(
          'button, input, select, textarea, a[href], summary, [contenteditable="true"]',
        )
      ) {
        document.getElementById(focusId)?.focus({ preventScroll: true });
      }
    });
    dialog.addEventListener('keydown', (event) => {
      if (event.key !== 'Tab') return;
      const controls = [
        ...dialog.querySelectorAll('button, input, select, textarea, a[href], [tabindex]'),
      ].filter((node) => !node.disabled && node.tabIndex >= 0 && node.getClientRects().length);
      const first = controls[0];
      const last = controls[controls.length - 1];
      if (!controls.includes(document.activeElement)) {
        event.preventDefault();
        (event.shiftKey ? last : first)?.focus();
      } else if (event.shiftKey && document.activeElement === first) {
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
  app.ports.setKeymapOpen.subscribe((isOpen) => setPanelOpen(keymapDialog, isOpen, 'keymap-close'));
  app.ports.setImmersiveMode.subscribe(() => {
    if (activeDialog) setPanelOpen(activeDialog, false);
    document.querySelectorAll('.tag-picker[open]').forEach((picker) => {
      picker.open = false;
    });
    requestAnimationFrame(() => document.getElementById('main')?.focus({ preventScroll: true }));
  });
  app.ports.scrollSearchResult.subscribe((index) => {
    requestAnimationFrame(() => {
      if (searchDialog.open) {
        document.getElementById('launcher-search')?.focus({ preventScroll: true });
        document.getElementById(`search-result-${index}`)?.scrollIntoView({ block: 'nearest' });
      }
    });
  });
  app.ports.scrollNotebook.subscribe(() => {
    requestAnimationFrame(() => {
      const heading = document.getElementById('notebook-heading');
      heading?.scrollIntoView({ block: 'start' });
      heading?.focus({ preventScroll: true });
    });
  });
}
