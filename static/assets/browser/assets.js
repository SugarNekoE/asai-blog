// Register before fetching JSON: the load event may fire while it is pending.
export const pageLoaded = new Promise((resolve) => {
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

export function firstPaintOpportunity() {
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

export function fontsReady(sample) {
  if (!document.fonts) return Promise.resolve();
  const cjk = sample.replace(/[^\u3000-\uffff]/g, '');
  return Promise.allSettled([
    document.fonts.load('400 16px "Noto Sans"', sample),
    document.fonts.load('italic 400 16px "Noto Sans"', sample),
    document.fonts.load('400 16px "Noto Sans Mono"', sample),
    document.fonts.load('400 16px "Noto Sans CJK SC"', cjk),
    document.fonts.load('400 16px "Noto Sans Mono CJK SC"', cjk),
    document.fonts.load('400 20px "Noto Sans Symbols"', '↗'),
    document.fonts.load('400 20px "Noto Sans Symbols 2"', '◐☼'),
  ]).then(() => document.fonts.ready);
}
