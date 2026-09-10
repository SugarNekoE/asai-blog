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

export function observeAssets(startup) {
  pageLoaded.then(() => startup.ports.assetSettled.send('assets'));
  startup.ports.loadFonts.subscribe((requests) => {
    Promise.allSettled(requests.map(({ font, sample }) => document.fonts?.load(font, sample)))
      .then(() => document.fonts?.ready)
      .then(() => startup.ports.assetSettled.send('fonts'));
  });
}
