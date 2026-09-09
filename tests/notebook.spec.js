const { test, expect } = require('@playwright/test');

async function addTag(page, tag) {
  const picker = page.locator('.tag-picker > summary');
  await picker.click();
  await page.getByRole('checkbox', { name: `Select tag ${tag}`, exact: true }).check();
  await picker.click();
}

test('search, main-index tags, sort, empty state, and persistent theme', async ({ page }) => {
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  await expect(page.locator('.post-row')).toHaveCount(4);
  await page.getByRole('searchbox').focus();
  await page.getByRole('searchbox').fill('algebraic');
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(page.locator('.post-row')).toContainText('Types are a way');
  await page.getByRole('searchbox').fill('unfindable phrase');
  await expect(page.getByText('No notes on this path. Yet.')).toBeVisible();
  await page.getByRole('button', { name: 'Clear search', exact: true }).click();
  await addTag(page, 'elm');
  await expect(page.locator('.post-row')).toHaveCount(1);
  await page.getByRole('button', { name: 'Remove tag elm', exact: true }).click();
  await page.getByRole('button', { name: 'Newest first' }).click();
  await expect(page.locator('.post-row').first()).toContainText('A quieter interface');
  await page.getByRole('button', { name: 'Toggle color theme' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  expect(errors).toEqual([]);
  await page.screenshot({ path: 'test-results/notebook-light.png', fullPage: true });
});

test('article, syntax highlighting, image, wiki heading links, and history', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('link', { name: 'From plain text to a small, personal web' }).click();
  await expect(page.locator('blog-content h1')).toContainText('From plain text');
  await expect(page.locator('.sourceCode').first()).toBeVisible();
  await expect(page.locator('.prose img')).toBeVisible();
  expect(
    await page.locator('.prose img').evaluate((image) => image.complete && image.naturalWidth > 0),
  ).toBe(true);
  await page.screenshot({ path: 'test-results/article.png', fullPage: true });
  await page.getByRole('link', { name: 'A notebook that stays yours', exact: true }).click();
  await page.getByRole('link', { name: 'the publishing pipeline', exact: true }).click();
  await expect(page).toHaveURL(/#one-source-two-outputs$/);
  await expect(page.locator('#one-source-two-outputs')).toBeInViewport();
  await page.goBack();
  await expect(page.locator('h1')).toContainText('A notebook that stays yours');
});

test('mobile navigation and desktop layout fit the viewport', async ({ page }) => {
  for (const width of [390, 768, 1440]) {
    await page.setViewportSize({ width, height: 1000 });
    await page.goto('/');
    await expect(page.locator('.workspace')).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(
      true,
    );
    await page.screenshot({ path: `test-results/notebook-${width}.png`, fullPage: true });
  }
  await page.setViewportSize({ width: 390, height: 844 });
  await page.getByRole('button', { name: 'Toggle navigation' }).click();
  await expect(page.locator('.sidebar')).toBeVisible();
  await page
    .getByRole('navigation', { name: 'Categories', exact: true })
    .getByRole('button', { name: 'notes' })
    .click();
  await expect(page.locator('.sidebar')).toBeHidden();
  await expect(page.locator('.post-row')).toHaveCount(1);
  await page.getByRole('button', { name: 'Toggle navigation' }).click();
  await page.locator('.search-launch').click();
  await expect(page.locator('.sidebar')).toBeHidden();
  await expect(page.getByRole('dialog', { name: 'Search notes', exact: true })).toBeVisible();
  await expect(page.getByRole('combobox', { name: 'Search all notes', exact: true })).toBeFocused();
  await page.keyboard.press('Escape');
});

test('static HTML remains readable with JavaScript disabled', async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  const page = await context.newPage();
  await page.goto('http://127.0.0.1:8765/');
  await expect(page.locator('.fallback nav')).toContainText('All Notes');
  await expect(page.locator('.post-row')).toHaveCount(4);
  await page.getByRole('link', { name: 'From plain text to a small, personal web' }).click();
  await expect(page.locator('h1')).toContainText('From plain text');
  await expect(page.locator('.fallback nav')).toContainText('/ web');
  await expect(page.locator('#one-source-two-outputs')).toBeVisible();
  await context.close();
});

test('unavailable or incompatible JSON keeps the page readable', async ({ page }) => {
  await page.route('**/api/posts.json', (route) => route.abort());
  await page.goto('/');
  await expect(page.locator('#static-content h1')).toBeVisible();
  await page.unroute('**/api/posts.json');
  await page.route('**/api/posts.json', (route) =>
    route.fulfill({ json: { version: 99, posts: [] } }),
  );
  await page.reload();
  await expect(page.locator('.workspace h1')).toBeVisible();
  await expect(page.locator('.post-row')).toHaveCount(4);
});

test('folder categories drive navigation and combine with main-index tag filters', async ({
  page,
}) => {
  await page.goto('/');
  const breadcrumb = page.getByRole('navigation', { name: 'Breadcrumb', exact: true });
  const categories = page.getByRole('navigation', { name: 'Categories', exact: true });
  await expect(breadcrumb.getByRole('link', { name: 'Asai Blog', exact: true })).toBeVisible();
  await expect(breadcrumb.locator('.current-category')).toHaveText('All Notes');
  await expect(page.locator('.tabbar, .active-tab, .tab-dot')).toHaveCount(0);
  await expect(page.getByRole('link', { name: /about/i })).toHaveCount(0);
  await expect(page.locator('.sidebar select, .sidebar .tag, .sidebar .topic')).toHaveCount(0);
  await expect(categories.getByRole('button')).toHaveCount(3);
  await categories.getByRole('button', { name: 'web' }).click();
  await expect(breadcrumb.locator('.current-category')).toHaveText('web');
  await expect(page.locator('.post-row')).toHaveCount(2);
  await addTag(page, 'elm');
  await expect(page.locator('.post-row')).toHaveCount(1);
  await page.getByRole('link', { name: 'From plain text to a small, personal web' }).click();
  await expect(breadcrumb.locator('.current-category')).toHaveText('web');
  await expect(page.locator('.tabbar')).toHaveCount(0);
  await expect(page.locator('.tag-picker')).toHaveCount(0);
  await categories.getByRole('link', { name: 'notes' }).click();
  await expect(page).toHaveURL(/\?category=notes$/);
  await expect(breadcrumb.locator('.current-category')).toHaveText('notes');
  await expect(page.locator('.post-row')).toHaveCount(1);
  await page.reload();
  await expect(page.locator('.post-row')).toHaveCount(1);
  await breadcrumb.getByRole('link', { name: 'Asai Blog', exact: true }).click();
  await expect(page).toHaveURL('/');
  await expect(breadcrumb.locator('.current-category')).toHaveText('All Notes');
  await expect(page.locator('.post-row')).toHaveCount(4);
});

test('direct post URLs display their folder category and index filters accept deep links', async ({
  page,
}) => {
  await page.goto('/posts/types-as-design-tools/');
  await expect(page.locator('.breadcrumbs .current-category')).toHaveText('programming');
  await expect(page.locator('.category-item.active')).toContainText('programming');
  const categoryLink = page
    .getByRole('navigation', { name: 'Breadcrumb', exact: true })
    .getByRole('link', { name: 'programming', exact: true });
  await expect(categoryLink).toHaveAttribute('href', '/?category=programming');
  await categoryLink.click();
  await expect(page).toHaveURL(/\?category=programming$/);
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(page.locator('.post-row')).toContainText('Types are a way to ask better questions');
  await page.goto('/?category=web&tag=notes');
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(page.locator('.post-row')).toContainText('A quieter interface');
  await expect(page.getByRole('button', { name: 'Remove tag notes', exact: true })).toBeVisible();
  await page
    .getByRole('navigation', { name: 'Categories', exact: true })
    .getByRole('button', { name: 'programming' })
    .click();
  await expect(page.locator('.post-row')).toHaveCount(0);
  await page.getByRole('button', { name: 'Clear filters →', exact: true }).click();
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(page.locator('.breadcrumbs .current-category')).toHaveText('programming');
  expect(new URL(page.url()).searchParams.get('category')).toBe('programming');
  expect(new URL(page.url()).searchParams.getAll('tag')).toEqual([]);
});

test('article outline is transparent, stays on the right, and adapts to narrow screens', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/posts/plain-text-to-a-small-web/');
  const outline = page.locator('.main-content > .page-outline');
  await expect(outline).toBeVisible();
  await expect(
    page.locator('.sidebar').getByRole('navigation', { name: 'Table of contents' }),
  ).toHaveCount(0);
  await expect(outline).toHaveCSS('background-color', 'rgba(0, 0, 0, 0)');
  const panel = await outline.boundingBox();
  const article = await page.locator('.prose').boundingBox();
  expect(panel.x).toBeGreaterThan(article.x + article.width);
  expect(panel.x + panel.width).toBeGreaterThan(1380);
  await page.screenshot({ path: 'test-results/outline-desktop.png', fullPage: true });
  await outline.getByRole('link', { name: 'Keep the build disposable', exact: true }).click();
  await expect(page).toHaveURL(/#keep-the-build-disposable$/);
  await expect(page.locator('#keep-the-build-disposable')).toBeInViewport();
  await expect(outline).toBeInViewport();
  expect((await outline.boundingBox()).y).toBeGreaterThanOrEqual(0);
  expect((await outline.boundingBox()).y).toBeLessThanOrEqual(33);

  for (const width of [768, 390]) {
    await page.setViewportSize({ width, height: 900 });
    await page.goto('/posts/plain-text-to-a-small-web/');
    await expect(outline).toBeVisible();
    await expect(outline).toHaveCSS('position', 'static');
    const narrowPanel = await outline.boundingBox();
    const narrowArticle = await page.locator('.prose').boundingBox();
    expect(narrowPanel.y + narrowPanel.height).toBeLessThan(narrowArticle.y);
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(
      true,
    );
  }
  await page.screenshot({ path: 'test-results/outline-mobile.png', fullPage: true });
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  await expect(page.locator('.page-outline')).toHaveCount(0);
});

test('note tags add multiple filters, deduplicate, and persist through reload', async ({
  page,
}) => {
  await page.goto('/');
  const firstPost = page
    .locator('.post-row')
    .filter({ hasText: 'From plain text to a small, personal web' });
  await firstPost.getByRole('button', { name: 'Filter by tag haskell', exact: true }).click();
  await expect(page.locator('.post-row')).toHaveCount(2);
  await firstPost.getByRole('button', { name: 'Filter by tag elm', exact: true }).click();
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(
    page.getByRole('group', { name: 'Selected tags', exact: true }).getByRole('button'),
  ).toHaveCount(2);
  await firstPost.getByRole('button', { name: 'Filter by tag elm', exact: true }).click();
  await expect(page.locator('.selected-tag')).toHaveCount(2);
  expect(new URL(page.url()).searchParams.getAll('tag')).toEqual(['elm', 'haskell']);
  await page.reload();
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(page.locator('.selected-tag')).toHaveCount(2);
  await expect(
    firstPost.getByRole('button', { name: 'Filter by tag elm', exact: true }),
  ).toHaveAttribute('aria-pressed', 'true');
  await page.getByRole('button', { name: 'Remove tag elm', exact: true }).click();
  await expect(page.locator('.post-row')).toHaveCount(2);
  await addTag(page, 'notes');
  await expect(page.locator('.post-row')).toHaveCount(0);
  await page.getByRole('button', { name: 'Clear filters →', exact: true }).click();
  await expect(page.locator('.post-row')).toHaveCount(4);
  expect(new URL(page.url()).search).toBe('');
});

test('tag checkboxes combine with category and search, and repeated URL tags normalize', async ({
  page,
}) => {
  await page.goto('/?category=web&tag=haskell&tag=elm&tag=elm&q=compiler');
  await expect(page.locator('.selected-tag')).toHaveCount(2);
  await expect(page.locator('.post-row')).toHaveCount(1);
  await page.locator('.tag-picker > summary').click();
  await expect(page.getByRole('checkbox', { name: 'Select tag elm', exact: true })).toBeChecked();
  await expect(
    page.getByRole('checkbox', { name: 'Select tag haskell', exact: true }),
  ).toBeChecked();
  await page.getByRole('checkbox', { name: 'Select tag elm', exact: true }).uncheck();
  await page.locator('.tag-picker > summary').click();
  await expect(page.locator('.selected-tag')).toHaveCount(1);
  expect(new URL(page.url()).searchParams.getAll('tag')).toEqual(['haskell']);
  expect(new URL(page.url()).searchParams.get('category')).toBe('web');
  expect(new URL(page.url()).searchParams.get('q')).toBe('compiler');
  await page.getByRole('searchbox').fill('no such phrase');
  await expect(page.locator('.post-row')).toHaveCount(0);
  await page.getByRole('button', { name: 'Clear filters →', exact: true }).click();
  await expect(page.locator('.post-row')).toHaveCount(0);
  await expect(page.getByRole('searchbox')).toHaveValue('no such phrase');
  await expect(page.locator('.breadcrumbs .current-category')).toHaveText('web');
  await expect(page.locator('.selected-tag')).toHaveCount(0);
  await page.getByRole('button', { name: 'Clear search', exact: true }).click();
  await expect(page.locator('.post-row')).toHaveCount(2);
  await page.setViewportSize({ width: 390, height: 844 });
  await addTag(page, 'haskell');
  await addTag(page, 'elm');
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.screenshot({ path: 'test-results/multiple-tags-mobile.png', fullPage: true });
});

test('header clock uses browser-local 24-hour time and updates at minute boundaries', async ({
  browser,
}) => {
  const cases = [
    {
      zone: 'Asia/Shanghai',
      start: '2026-09-09T15:59:59Z',
      before: '2026/09/09 23:59',
      after: '2026/09/10 00:00',
    },
    {
      zone: 'Asia/Kathmandu',
      start: '2026-09-09T14:14:59Z',
      before: '2026/09/09 19:59',
      after: '2026/09/09 20:00',
    },
    {
      zone: 'America/New_York',
      start: '2026-03-08T06:59:59Z',
      before: '2026/03/08 01:59',
      after: '2026/03/08 03:00',
    },
  ];
  for (const sample of cases) {
    const context = await browser.newContext({ timezoneId: sample.zone });
    try {
      const page = await context.newPage();
      await page.clock.install({ time: new Date(Date.parse(sample.start) - 1000) });
      await page.clock.pauseAt(new Date(sample.start));
      await page.goto('http://127.0.0.1:8765/');
      const clock = page.getByLabel('Current local time', { exact: true });
      await expect(clock).toHaveText(sample.before);
      await expect(page.getByText('a corner of the internet', { exact: true })).toHaveCount(0);
      await page.clock.runFor(1100);
      await expect(clock).toHaveText(sample.after);
      await expect(clock).toHaveAttribute(
        'datetime',
        new Date(Date.parse(sample.start) + 1000).toISOString(),
      );
      for (const width of [390, 320]) {
        await page.setViewportSize({ width, height: 844 });
        await expect(clock).toBeVisible();
        expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(
          true,
        );
      }
    } finally {
      await context.close();
    }
  }
});

async function expectPageTimings(page) {
  const footer = page.getByLabel('Page performance', { exact: true });
  await expect(footer).toHaveText(/^loading (0|[1-9]\d*)ms \/ rendered (0|[1-9]\d*)ms$/);
  const measurements = await page.evaluate(() => {
    const navigation = performance.getEntriesByType('navigation')[0];
    const start = performance.getEntriesByName('asai:elm-init')[0];
    const paint = performance.getEntriesByName('asai:first-paint-opportunity')[0];
    return {
      loading: navigation.loadEventStart - navigation.startTime,
      rendering: paint.startTime - start.startTime,
      loadEvent: navigation.loadEventStart,
      elmStart: start.startTime,
      paintOpportunity: paint.startTime,
    };
  });
  const milliseconds = (number) => String(Math.round(number));
  await expect(footer).toHaveText(
    `loading ${milliseconds(measurements.loading)}ms / rendered ${milliseconds(measurements.rendering)}ms`,
  );
  return measurements;
}

test('footer measures navigation load independently of a delayed JSON fetch', async ({ page }) => {
  let releaseIndex;
  const indexReady = new Promise((resolve) => {
    releaseIndex = resolve;
  });
  await page.route('**/api/posts.json', async (route) => {
    await indexReady;
    await route.continue();
  });
  try {
    await page.goto('/');
    await expect(page.locator('.workspace')).toHaveCount(0);
    releaseIndex();
    const measurements = await expectPageTimings(page);
    expect(measurements.elmStart).toBeGreaterThan(measurements.loadEvent);
    expect(measurements.rendering).toBeGreaterThan(0);
    const original = await page.getByLabel('Page performance', { exact: true }).textContent();
    await page.getByRole('searchbox').fill('elm');
    await expect(page.getByLabel('Page performance', { exact: true })).toHaveText(original);
    await expect(page.getByText('a work in progress', { exact: false })).toHaveCount(0);
    await expect(
      page.locator('.sidebar').getByRole('link', { name: 'CC-BY-SA 4.0' }),
    ).toHaveAttribute('href', 'https://creativecommons.org/licenses/by-sa/4.0/');
    await page.setViewportSize({ width: 320, height: 844 });
    await page.getByLabel('Page performance', { exact: true }).scrollIntoViewIfNeeded();
    await expect(page.getByLabel('Page performance', { exact: true })).toBeInViewport();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(
      true,
    );
  } finally {
    releaseIndex();
  }
});

test('startup waits for assets while footer retains navigation and Elm rendering boundaries', async ({
  page,
}) => {
  let releaseImage;
  const imageReady = new Promise((resolve) => {
    releaseImage = resolve;
  });
  await page.route('**/attachments/pipeline.svg', async (route) => {
    await imageReady;
    await route.continue();
  });
  try {
    await page.goto('/posts/plain-text-to-a-small-web/', { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#loading-screen')).toBeVisible();
    await expect(page.locator('#loading-status')).toHaveText('loading assets...');
    await expect(page.locator('.workspace')).toHaveCount(0);
    releaseImage();
    await page.waitForLoadState('load');
    const measurements = await expectPageTimings(page);
    expect(measurements.elmStart).toBeGreaterThanOrEqual(measurements.loadEvent);
    expect(measurements.paintOpportunity).toBeGreaterThan(measurements.elmStart);
  } finally {
    releaseImage();
  }
});

test('clear filters only removes tags and preserves category navigation and search text', async ({
  page,
}) => {
  await page.goto('/?category=web');
  await expect(page.locator('.post-row')).toHaveCount(2);
  await expect(page.getByRole('button', { name: 'Clear filters', exact: true })).toHaveCount(0);
  await expect(page.getByRole('status')).toHaveText('2 notes in web');
  await page.getByRole('searchbox').fill('compiler');
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(page.getByRole('button', { name: 'Clear filters', exact: true })).toHaveCount(0);
  await addTag(page, 'haskell');
  await addTag(page, 'elm');
  await expect(page.locator('.selected-tag')).toHaveCount(2);
  await page.getByRole('button', { name: 'Clear filters', exact: true }).click();
  await expect(page.locator('.selected-tag')).toHaveCount(0);
  await expect(page.getByRole('searchbox')).toHaveValue('compiler');
  await expect(page.locator('.breadcrumbs .current-category')).toHaveText('web');
  await expect(page.locator('.post-row')).toHaveCount(1);
  const params = new URL(page.url()).searchParams;
  expect(params.get('category')).toBe('web');
  expect(params.get('q')).toBe('compiler');
  expect(params.getAll('tag')).toEqual([]);
  await expect(page.getByRole('button', { name: 'Clear filters', exact: true })).toHaveCount(0);
  await page.reload();
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(page.locator('.breadcrumbs .current-category')).toHaveText('web');
});
