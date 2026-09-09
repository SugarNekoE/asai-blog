export function connectLinks(app) {
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
    const hints = links.map(({ link, rect }, id) => {
      targets.set(id, link);
      return {
        id,
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
  app.ports.followLinkHint.subscribe((id) => {
    const link = targets.get(id);
    clear();
    if (link?.isConnected && visibleRect(link)) link.click();
  });
  window.addEventListener('scroll', cancel, true);
  window.addEventListener('resize', cancel);
  window.addEventListener('blur', cancel);
  document.addEventListener('pointerdown', cancel);
}
