export function connectKeyboard(app) {
  let keys = { page: [], control: [], editing: [] };
  let ready;
  const connected = new Promise((resolve) => {
    ready = resolve;
  });
  app.ports.setKeyboardKeys.subscribe((value) => {
    keys = value;
    ready();
  });
  document.addEventListener('keydown', (event) => {
    if (
      event.defaultPrevented ||
      event.isComposing ||
      event.repeat ||
      event.ctrlKey ||
      event.metaKey ||
      event.altKey
    )
      return;
    const target = event.target;
    const editing =
      target.isContentEditable ||
      target.closest('input, textarea, select, [contenteditable="true"]');
    const context = editing
      ? 'editing'
      : target.closest('a, button, summary, [role="button"]')
        ? 'control'
        : 'page';
    const key = event.shiftKey && event.key.toLowerCase() === 'i' ? 'Shift+I' : event.key;
    if (keys[context].includes(key)) {
      event.preventDefault();
      app.ports.keyboardPressed.send(key);
    }
  });
  return connected;
}
