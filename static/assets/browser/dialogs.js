export function connectDialogs(app) {
  for (const dialog of document.querySelectorAll('dialog[data-panel-focus]')) {
    dialog.addEventListener('focusin', (event) => {
      if (
        dialog.open &&
        !event.target.isContentEditable &&
        !event.target.closest(
          'button, input, select, textarea, a[href], summary, [contenteditable="true"]',
        )
      ) {
        document.getElementById(dialog.dataset.panelFocus)?.focus({ preventScroll: true });
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
  app.ports.setPanel.subscribe(({ id, focusId }) => {
    cancelAnimationFrame(panelFrame);
    const dialog = document.getElementById(id);
    if (dialog) {
      if (!activeDialog) panelOpener = document.activeElement;
      if (activeDialog && activeDialog !== dialog) activeDialog.close();
      activeDialog = dialog;
      panelFrame = requestAnimationFrame(() => {
        if (!dialog.open) dialog.showModal();
        document.documentElement.classList.add('search-open');
        document.getElementById(focusId).focus();
      });
    } else {
      activeDialog?.close();
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
  });
  app.ports.positionPage.subscribe(({ id, focusId, block }) => {
    requestAnimationFrame(() => {
      document.getElementById(focusId)?.focus({ preventScroll: true });
      document.getElementById(id)?.scrollIntoView({ block });
    });
  });
}
