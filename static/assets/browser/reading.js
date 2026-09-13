export function connectReading(app) {
  let headings = [];
  let frame;
  const measure = () => {
    frame = undefined;
    app.ports.readingPositionChanged.send({
      headings: headings.map((heading) => ({
        id: heading.id,
        top: heading.getBoundingClientRect().top,
        scrollMargin: parseFloat(getComputedStyle(heading).scrollMarginTop) || 0,
      })),
      viewportHeight: innerHeight,
      scrollTop: scrollY,
      documentHeight: document.documentElement.scrollHeight,
      scrollPadding: parseFloat(getComputedStyle(document.documentElement).scrollPaddingTop) || 0,
    });
  };
  const schedule = () => {
    if (headings.length && frame === undefined) frame = requestAnimationFrame(measure);
  };
  const resize = new ResizeObserver(schedule);
  app.ports.observeReading.subscribe((ids) => {
    const article = document.querySelector('.workspace .prose');
    headings = ids.map((id) => article?.querySelector(`#${CSS.escape(id)}`)).filter(Boolean);
    resize.disconnect();
    if (article) resize.observe(article);
    schedule();
  });
  app.ports.refreshReading.subscribe(schedule);
  app.ports.revealCurrentHeading.subscribe(() => {
    requestAnimationFrame(() => {
      const nav = document.querySelector('.page-outline nav');
      const link = nav?.querySelector('[aria-current="location"]');
      if (!link) return;
      const viewport = nav.getBoundingClientRect();
      const target = link.getBoundingClientRect();
      if (target.top < viewport.top) nav.scrollTop += target.top - viewport.top;
      else if (target.bottom > viewport.bottom) nav.scrollTop += target.bottom - viewport.bottom;
    });
  });
  window.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('resize', schedule);
}
