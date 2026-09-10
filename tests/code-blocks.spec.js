const { test, expect } = require('@playwright/test');

const article = '/posts/plain-text-to-a-small-web/';

test('Elm copy controls isolate pending requests and ignore stale reset timers', async ({
  page,
}) => {
  await page.clock.install();
  await page.addInitScript(() => {
    window.copyRequests = [];
    Object.defineProperty(navigator, 'clipboard', {
      value: {
        writeText: (text) =>
          new Promise((resolve) => {
            window.copyRequests.push({ text, resolve, active: navigator.userActivation.isActive });
          }),
      },
    });
  });
  await page.goto(article);
  await expect(page.locator('.workspace')).toBeVisible();
  const blocks = page.locator('.code-block');
  const first = blocks.nth(0).locator('.code-copy');
  const second = blocks.nth(1).locator('.code-copy');
  await blocks.nth(0).hover();
  await first.click();
  await expect(first).toHaveText('Copying…');
  await first.click();
  expect(await page.evaluate(() => window.copyRequests.length)).toBe(1);
  await blocks.nth(1).hover();
  await second.click();
  await expect(second).toHaveText('Copying…');
  expect(await page.evaluate(() => window.copyRequests.map((request) => request.active))).toEqual([
    true,
    true,
  ]);
  expect(await page.evaluate(() => window.copyRequests.map((request) => request.text))).toEqual(
    await blocks.locator('pre code').allTextContents(),
  );
  await page.evaluate(() => window.copyRequests[0].resolve());
  await expect(first).toHaveText('Copied');
  await expect(second).toHaveText('Copying…');
  await page.clock.fastForward(2000);
  await first.click();
  await expect(first).toHaveText('Copying…');
  await page.clock.fastForward(600);
  await expect(first).toHaveText('Copying…');
  await page.evaluate(() => {
    window.copyRequests[1].resolve();
    window.copyRequests[2].resolve();
  });
  await expect(blocks.locator('.code-copy')).toHaveText(['Copied', 'Copied']);
  await page.clock.runFor(2600);
  await expect(blocks.locator('.code-copy')).toHaveText(['Copy', 'Copy']);
});

test('Elm copy controls work on the static article when index loading fails', async ({ page }) => {
  await page.route('**/api/posts.json', (route) => route.abort());
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'clipboard', {
      value: {
        writeText: async (text) => {
          window.copiedCode = text;
        },
      },
    });
  });
  await page.goto(article);
  await expect(page.locator('#static-content')).toBeVisible();
  await expect(page.locator('.workspace')).toHaveCount(0);
  const block = page.locator('.code-block').first();
  await block.hover();
  await block.getByRole('button', { name: 'Copy code', exact: true }).click();
  await expect(block.locator('.code-copy')).toHaveText('Copied');
  expect(await page.evaluate(() => window.copiedCode)).toBe(
    await block.locator('pre code').textContent(),
  );
});

test('code toolbars label languages and copy only the selected highlighted code', async ({
  page,
  context,
}) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.goto(article);
  await expect(page.locator('.workspace')).toBeVisible();
  const blocks = page.locator('.code-block');
  await expect(blocks.locator('.code-language')).toHaveText(['haskell', 'elm']);
  await expect(blocks.locator('.code-copy')).toHaveCount(2);
  const first = blocks.first();
  const copy = first.getByRole('button', { name: 'Copy code', exact: true });
  await expect(copy).toHaveCSS('opacity', '0');
  await first.hover();
  await expect(copy).toHaveCSS('opacity', '1');
  await page.screenshot({ path: 'test-results/code-toolbar-desktop.png' });
  for (const block of await blocks.all()) {
    const text = await block.locator('pre code').textContent();
    await block.hover();
    await block.getByRole('button', { name: 'Copy code', exact: true }).click();
    await expect(block.locator('.code-copy')).toHaveText('Copied');
    expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(text);
  }
  await page.keyboard.press('t');
  await page.keyboard.press('Shift+I');
  await expect(page.locator('.workspace')).toHaveClass(/is-immersive/);
  await expect(blocks.locator('.code-copy')).toHaveCount(2);
  await page.emulateMedia({ media: 'print' });
  for (const toolbar of await blocks.locator('.code-toolbar').all())
    await expect(toolbar).toBeHidden();
  await expect(first.locator('pre code')).toBeVisible();
});

test('copy is keyboard accessible and reports clipboard failure without claiming success', async ({
  page,
}) => {
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'clipboard', {
      value: {
        writeText: async () => {
          throw new Error('Clipboard denied');
        },
      },
    });
  });
  await page.goto(article);
  await expect(page.locator('.workspace')).toBeVisible();
  const copy = page.locator('.code-copy').first();
  await page.keyboard.press('Tab');
  await copy.focus();
  await expect(copy).toHaveCSS('opacity', '1');
  await expect(copy).toHaveCSS('outline-style', 'solid');
  await copy.press('Enter');
  await expect(copy).toHaveText('Copy failed');
  await expect(copy).toHaveAccessibleName('Copy failed. Select the code and copy it manually.');
  await expect(copy).toHaveText('Copy', { timeout: 4000 });
});

test('touch toolbars remain visible while long code scrolls independently', async ({
  browser,
  baseURL,
}) => {
  const context = await browser.newContext({
    baseURL,
    viewport: { width: 320, height: 844 },
    isMobile: true,
    hasTouch: true,
  });
  try {
    const page = await context.newPage();
    await page.goto(article);
    await expect(page.locator('.workspace')).toBeVisible();
    const block = page.locator('.code-block').first();
    const copy = block.locator('.code-copy');
    await expect(copy).toHaveCSS('opacity', '1');
    await block.scrollIntoViewIfNeeded();
    const position = await copy.boundingBox();
    await block.locator('pre').evaluate((node) => {
      node.scrollLeft = node.scrollWidth;
    });
    expect((await copy.boundingBox()).x).toBe(position.x);
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(
      true,
    );
    await page.screenshot({ path: 'test-results/code-toolbar-mobile.png' });
  } finally {
    await context.close();
  }
});

test('static articles keep language labels without showing inactive copy buttons', async ({
  browser,
  baseURL,
}) => {
  const context = await browser.newContext({ baseURL, javaScriptEnabled: false });
  try {
    const page = await context.newPage();
    await page.goto(article);
    await expect(page.locator('.code-language')).toHaveText(['haskell', 'elm']);
    for (const copy of await page.locator('.code-copy').all()) await expect(copy).toBeHidden();
    await expect(page.locator('pre code').first()).toBeVisible();
  } finally {
    await context.close();
  }
});
