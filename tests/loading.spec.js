const { test, expect } = require('@playwright/test');
const fs = require('node:fs/promises');

async function captureLoading(page, path) {
  const session = await page.context().newCDPSession(page);
  const { data } = await session.send('Page.captureScreenshot', { format: 'png' });
  await fs.writeFile(path, Buffer.from(data, 'base64'));
  await session.detach();
}

test('loading screen displays font progress before revealing the page', async ({ page }) => {
  let releaseFonts;
  const ready = new Promise((resolve) => {
    releaseFonts = resolve;
  });
  await page.route('**/assets/fonts/*', async (route) => {
    await ready;
    await route.continue();
  });
  try {
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await expect(
      page.getByRole('heading', { name: 'Please Be Patient', exact: true }),
    ).toBeVisible();
    await expect(page.locator('#loading-status')).toHaveText('loading fonts...');
    await expect(page.locator('#app')).toHaveJSProperty('inert', true);
    await captureLoading(page, 'test-results/loading-desktop.png');
    await page.setViewportSize({ width: 390, height: 844 });
    await expect(page.locator('#loading-screen')).toBeInViewport();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(
      true,
    );
    await captureLoading(page, 'test-results/loading-mobile.png');
    releaseFonts();
    await expect(page.locator('.workspace')).toBeVisible();
    await expect(page.locator('#loading-screen')).toHaveCount(0);
    await expect(page.locator('html')).not.toHaveClass(/is-loading/);
  } finally {
    releaseFonts();
  }
});

test('loader is visible while the Elm bundle downloads', async ({ page }) => {
  let releaseScript;
  const ready = new Promise((resolve) => {
    releaseScript = resolve;
  });
  await page.route('**/assets/elm.js*', async (route) => {
    await ready;
    await route.continue();
  });
  try {
    await page.goto('/', { waitUntil: 'commit' });
    await expect(page.locator('#loading-screen')).toBeVisible();
    await expect(page.locator('#loading-status')).toHaveText('loading assets...');
    releaseScript();
    await expect(page.locator('.workspace')).toBeVisible();
    await expect(page.locator('#loading-screen')).toHaveCount(0);
  } finally {
    releaseScript();
  }
});

test('loader reports pending notes and recovers from font failures', async ({ page }) => {
  let releaseIndex;
  const ready = new Promise((resolve) => {
    releaseIndex = resolve;
  });
  await page.route('**/api/posts.json', async (route) => {
    await ready;
    await route.continue();
  });
  await page.route('**/assets/fonts/*', (route) => route.abort());
  try {
    await page.goto('/');
    await expect(page.locator('#loading-status')).toHaveText('loading notes...');
    releaseIndex();
    await expect(page.locator('.workspace')).toBeVisible();
    await expect(page.locator('#loading-screen')).toHaveCount(0);
  } finally {
    releaseIndex();
  }
});

test('failed startup reveals readable static HTML', async ({ page }) => {
  await page.route('**/api/posts.json', (route) =>
    route.fulfill({ status: 503, body: 'unavailable' }),
  );
  await page.goto('/');
  await expect(page.locator('#static-content')).toBeVisible();
  await expect(page.locator('#app')).toHaveJSProperty('inert', false);
  await expect(page.locator('#loading-screen')).toHaveCount(0);
  await page.unroute('**/api/posts.json');
  await page.route('**/assets/elm.js*', (route) => route.abort());
  await page.reload();
  await expect(page.locator('#static-content')).toBeVisible();
  await expect(page.locator('#app')).toHaveJSProperty('inert', false);
  await expect(page.locator('#loading-screen')).toHaveCount(0);
});

test('stalled startup times out to the static page without a late takeover', async ({ page }) => {
  await page.clock.install();
  let releaseScript;
  const ready = new Promise((resolve) => {
    releaseScript = resolve;
  });
  await page.route('**/assets/elm.js*', async (route) => {
    await ready;
    await route.continue();
  });
  try {
    await page.goto('/', { waitUntil: 'commit' });
    await expect(page.locator('#loading-screen')).toBeVisible();
    await page.clock.fastForward(16000);
    await expect(page.locator('#static-content')).toBeVisible();
    await expect(page.locator('#app')).toHaveJSProperty('inert', false);
    await expect(page.locator('#loading-screen')).toHaveCount(0);
    releaseScript();
    await page.waitForLoadState('load');
    await expect(page.locator('.workspace')).toHaveCount(0);
  } finally {
    releaseScript();
  }
});

test('invalid index contracts reveal the static article instead of mounting Elm', async ({
  page,
}) => {
  for (const index of [
    { version: 99, posts: [] },
    { version: 2, posts: 'invalid' },
  ]) {
    await page.route('**/api/posts.json', (route) => route.fulfill({ json: index }));
    await page.goto('/posts/plain-text-to-a-small-web/');
    await expect(page.locator('#static-content h1')).toHaveText(
      'From plain text to a small, personal web',
    );
    await expect(page.locator('#static-content')).toBeVisible();
    await expect(page.locator('#loading-screen')).toHaveCount(0);
    await expect(page.locator('#app')).toHaveJSProperty('inert', false);
    await expect(page.locator('.workspace')).toHaveCount(0);
    await page.unroute('**/api/posts.json');
  }
});

test('a late Elm HTTP response cannot replace the fallback after startup expires', async ({
  page,
}) => {
  await page.clock.install();
  let releaseIndex;
  const ready = new Promise((resolve) => {
    releaseIndex = resolve;
  });
  await page.route('**/api/posts.json', async (route) => {
    await ready;
    await route.continue();
  });
  try {
    await page.goto('/');
    await expect(page.locator('#loading-status')).toHaveText('loading notes...');
    await page.clock.fastForward(16000);
    await expect(page.locator('#static-content')).toBeVisible();
    await expect(page.locator('#app')).toHaveJSProperty('inert', false);
    const response = page.waitForResponse('**/api/posts.json');
    releaseIndex();
    await response;
    await page.clock.runFor(100);
    await expect(page.locator('.workspace')).toHaveCount(0);
    expect(await page.evaluate(() => performance.getEntriesByName('asai:elm-init'))).toEqual([]);
  } finally {
    releaseIndex();
  }
});
