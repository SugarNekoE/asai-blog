export function connectFocus(app) {
  let tabNavigation = false;
  let marked;
  const clearMarker = () => {
    marked?.removeAttribute('data-tab-focus');
    marked = undefined;
  };
  const mark = (element) => {
    clearMarker();
    if (
      tabNavigation &&
      element instanceof Element &&
      element !== document.body &&
      element !== document.documentElement
    ) {
      marked = element;
      marked.setAttribute('data-tab-focus', '');
    }
  };
  document.documentElement.classList.add('focus-managed');
  document.addEventListener(
    'pointerdown',
    () => {
      tabNavigation = false;
      clearMarker();
    },
    true,
  );
  document.addEventListener(
    'keydown',
    (event) => {
      if (
        event.key === 'Tab' &&
        !event.ctrlKey &&
        !event.metaKey &&
        !event.altKey &&
        !event.isComposing
      ) {
        tabNavigation = true;
        mark(document.activeElement);
      }
    },
    true,
  );
  document.addEventListener('focusin', (event) => mark(event.target), true);
  document.addEventListener(
    'focusout',
    (event) => {
      if (event.target === marked) clearMarker();
    },
    true,
  );
  app.ports.clearFocus.subscribe(() => {
    tabNavigation = false;
    clearMarker();
    document.activeElement?.blur();
  });
}
