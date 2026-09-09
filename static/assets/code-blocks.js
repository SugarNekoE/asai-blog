(() => {
  const resetTimers = new WeakMap();

  const enhance = (root) => {
    for (const block of root.querySelectorAll('.code-block')) {
      const toolbar = block.querySelector('.code-toolbar');
      if (!toolbar || toolbar.querySelector('.code-copy') || !block.querySelector('pre code'))
        continue;
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'code-copy';
      button.textContent = 'Copy';
      button.setAttribute('aria-label', 'Copy code');
      button.setAttribute('aria-live', 'polite');
      toolbar.append(button);
    }
  };

  document.addEventListener('click', async (event) => {
    const button = event.target.closest?.('.code-copy');
    if (!button || button.dataset.state === 'copying') return;
    const code = button.closest('.code-block')?.querySelector('pre code');
    if (!code) return;
    clearTimeout(resetTimers.get(button));
    button.dataset.state = 'copying';
    button.textContent = 'Copying…';
    button.setAttribute('aria-busy', 'true');
    try {
      await navigator.clipboard.writeText(code.textContent);
      button.dataset.state = 'copied';
      button.textContent = 'Copied';
      button.setAttribute('aria-label', 'Code copied');
    } catch (_) {
      button.dataset.state = 'failed';
      button.textContent = 'Copy failed';
      button.setAttribute('aria-label', 'Copy failed. Select the code and copy it manually.');
    }
    button.removeAttribute('aria-busy');
    resetTimers.set(
      button,
      setTimeout(() => {
        delete button.dataset.state;
        button.textContent = 'Copy';
        button.setAttribute('aria-label', 'Copy code');
      }, 2500),
    );
  });

  window.AsaiCodeBlocks = { enhance };
  enhance(document);
})();
