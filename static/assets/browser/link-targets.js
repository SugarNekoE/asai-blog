export function connectLinkTargets(app) {
  const targets = new Map();
  const hit = ({ id, hitX, hitY }) => {
    const node = targets.get(id);
    const element = document.elementFromPoint(hitX, hitY);
    return Boolean(node?.isConnected && (element === node || node.contains(element)));
  };
  app.ports.collectLinkHints.subscribe(() => {
    targets.clear();
    const nodes = [...document.querySelectorAll('a[href], button[data-link-hint]')].filter(
      (node) => node instanceof HTMLAnchorElement || node instanceof HTMLButtonElement,
    );
    app.ports.linkTargetsCollected.send({
      width: innerWidth,
      height: innerHeight,
      targets: nodes.map((node, id) => {
        targets.set(id, node);
        const style = getComputedStyle(node);
        return {
          id,
          hint: node.getAttribute('data-link-hint') || '',
          ariaLabel: node.getAttribute('aria-label') || '',
          text: node.textContent,
          href: node.href || '',
          disabled: Boolean(node.disabled),
          ariaDisabled: node.getAttribute('aria-disabled') || '',
          inert: Boolean(node.closest('[inert], [aria-hidden="true"]')),
          visibility: style.visibility,
          opacity: Number(style.opacity),
          rects: [...node.getClientRects()].map(({ left, right, top, bottom }) => ({
            left,
            right,
            top,
            bottom,
          })),
        };
      }),
    });
  });
  app.ports.probeLinkTargets.subscribe((candidates) => {
    app.ports.linkHintsReady.send(
      candidates.map((candidate) => ({ candidate, hit: hit(candidate) })),
    );
  });
  app.ports.clearLinkHints.subscribe(() => targets.clear());
  app.ports.followLinkHint.subscribe((candidate) => {
    const node = targets.get(candidate.id);
    if (hit(candidate) && !node.disabled && node.getAttribute('aria-disabled') !== 'true')
      node.click();
    targets.clear();
  });
  const changed = () => app.ports.linkTargetsChanged.send(null);
  window.addEventListener('scroll', changed, true);
  window.addEventListener('blur', changed);
  document.addEventListener('pointerdown', changed);
}
