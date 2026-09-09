const { test, expect } = require('@playwright/test');

test('Shift+I widens the article, hides surrounding panels, and restores them', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  const normalWidth = (await page.locator('.prose').boundingBox()).width;
  await page.keyboard.press('i');
  await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
  await page.keyboard.press('Shift+I');
  await expect(page.locator('.workspace')).toHaveClass(/is-immersive/);
  const immersiveHeader = page.locator('.immersive-header');
  await expect(
    immersiveHeader.getByRole('link', { name: 'Asai Blog', exact: true }),
  ).toHaveAttribute('href', '/');
  await expect(immersiveHeader.locator('.brand-mark')).toHaveText('λ');
  await expect(immersiveHeader.getByText('Immersive Mode', { exact: true })).toBeVisible();
  await expect(immersiveHeader.getByRole('button', { name: 'Exit immersive mode' })).toContainText(
    'Shift + I',
  );
  await expect(page.locator('#main')).toBeFocused();
  await expect(page.locator('#main')).toHaveCSS('outline-style', 'none');
  await page.locator('.prose h1').click();
  await expect(page.locator('#main')).toHaveCSS('outline-style', 'none');
  for (const selector of ['.sidebar', '.topbar', '.statusbar', '.prose > .back']) {
    await expect(page.locator(selector)).toBeHidden();
  }
  await expect(page.locator('.page-outline')).toHaveCount(0);
  await expect(page.locator('.reading-layout')).toHaveCount(0);
  expect((await page.locator('.prose').boundingBox()).width).toBeGreaterThan(normalWidth + 100);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.screenshot({ path: 'test-results/immersive-desktop.png' });
  await page.keyboard.press('o');
  await expect(page.locator('.page-outline')).toHaveCount(0);
  await page.keyboard.press('Shift+I');
  await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
  await expect(immersiveHeader).toHaveCount(0);
  for (const selector of ['.sidebar', '.topbar', '.statusbar', '.page-outline', '.prose > .back']) {
    await expect(page.locator(selector)).toBeVisible();
  }
  expect((await page.locator('.prose').boundingBox()).width).toBe(normalWidth);
});

test('immersive header stays reachable on narrow screens and exits with a click', async ({
  page,
}) => {
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('Shift+I');
  const exit = page.getByRole('button', { name: 'Exit immersive mode', exact: true });
  for (const width of [390, 320]) {
    await page.setViewportSize({ width, height: 844 });
    await expect(exit).toBeInViewport();
    await expect(page.locator('.immersive-brand')).toBeInViewport();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(
      true,
    );
  }
  await page.evaluate(() => window.scrollTo({ top: 700, behavior: 'instant' }));
  await expect(exit).toBeInViewport();
  const heading = page.locator('.prose h2[id]').first();
  await heading.evaluate((node) => node.scrollIntoView({ behavior: 'instant', block: 'start' }));
  const headerBox = await page.locator('.immersive-header').boundingBox();
  expect((await heading.boundingBox()).y).toBeGreaterThanOrEqual(headerBox.y + headerBox.height);
  await page.keyboard.press('Tab');
  await exit.focus();
  await expect(exit).toHaveCSS('outline-style', 'solid');
  await page.screenshot({ path: 'test-results/immersive-header-mobile.png' });
  await exit.click();
  await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
  await expect(page.locator('.immersive-header')).toHaveCount(0);
  await expect(page.locator('#main')).toBeFocused();
  await expect(page.locator('#main')).toHaveCSS('outline-style', 'none');
});

test('immersive toggling closes existing panels and hints, while explicit search remains usable', async ({
  page,
}) => {
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('f');
  await expect(page.locator('.link-hint').first()).toBeVisible();
  await page.keyboard.press('Shift+I');
  await expect(page.locator('.workspace')).toHaveClass(/is-immersive/);
  await expect(page.locator('.link-hints')).toHaveCount(0);
  await expect(page.locator('#main')).toBeFocused();
  await page.keyboard.press('/');
  const search = page.getByRole('combobox', { name: 'Search all notes', exact: true });
  await expect(search).toBeFocused();
  await search.press('Shift+I');
  await expect(search).toHaveValue('I');
  await expect(page.locator('.workspace')).toHaveClass(/is-immersive/);
  await page.keyboard.press('Escape');
  await expect(search).not.toBeVisible();
  await expect(page.locator('#main')).toBeFocused();
  await page.keyboard.press('?');
  const keymap = page.getByRole('dialog', { name: 'Keyboard shortcuts', exact: true });
  await expect(keymap).toBeVisible();
  await expect(keymap.getByText('Toggle Immersive Mode on a note', { exact: true })).toBeVisible();
  await page.keyboard.press('Shift+I');
  await expect(keymap).not.toBeVisible();
  await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
  await expect(page.locator('html')).not.toHaveClass(/search-open/);
  await page.keyboard.press('?');
  await expect(keymap).toBeVisible();
  await page.keyboard.press('Shift+I');
  await expect(keymap).not.toBeVisible();
  await expect(page.locator('.workspace')).toHaveClass(/is-immersive/);
});

test('immersive mode preserves the note outline and stays disabled on filtered indexes', async ({
  page,
}) => {
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('o');
  await expect(page.locator('.page-outline')).toHaveCount(0);
  await page.keyboard.press('Shift+I');
  await expect(page.locator('.workspace')).toHaveClass(/is-immersive/);
  await page.keyboard.press('Shift+I');
  await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
  await expect(page.locator('.page-outline')).toHaveCount(0);
  await page.goto('/?category=web&tag=elm&perPage=30');
  const inline = page.getByRole('searchbox');
  await inline.focus();
  await inline.press('Shift+I');
  await expect(inline).toHaveValue('I');
  await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
  await expect(page).toHaveURL(/q=I/);
  const url = page.url();
  await inline.evaluate((node) => node.blur());
  await page.keyboard.press('Shift+I');
  await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
  await expect(page.locator('.immersive-header')).toHaveCount(0);
  await expect(page.locator('.topbar')).toBeVisible();
  await page.setViewportSize({ width: 390, height: 844 });
  await page.keyboard.press('Shift+I');
  await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
  await expect(inline).toHaveValue('I');
  await expect(page.locator('.breadcrumbs .current-category')).toHaveText('web');
  await expect(page.locator('.selected-tag')).toHaveCount(1);
  await expect(page.getByLabel('Notes per page')).toHaveValue('30');
  await expect(page).toHaveURL(url);
});

test('index and error pages ignore immersive shortcuts while panels and hints are open', async ({
  page,
}) => {
  for (const path of ['/', '/?category=web', '/404.html']) {
    await page.goto(path);
    await expect(page.locator('.workspace')).toBeVisible();
    await page.keyboard.press('Shift+I');
    await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
    await page.keyboard.press('?');
    const keymap = page.locator('#keymap-dialog');
    await expect(keymap).toBeVisible();
    await page.keyboard.press('Shift+I');
    await expect(keymap).toBeVisible();
    await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
    await page.keyboard.press('Escape');
    await expect(keymap).not.toBeVisible();
    await page.keyboard.press('f');
    await expect(page.locator('.link-hints')).toBeVisible();
    await page.keyboard.press('Shift+I');
    await expect(page.locator('.link-hints')).toBeVisible();
    await expect(page.locator('.workspace')).not.toHaveClass(/is-immersive/);
    await expect(page.locator('.immersive-header')).toHaveCount(0);
    await page.keyboard.press('Escape');
    await expect(page).toHaveURL(path);
  }
});
