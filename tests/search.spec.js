const { test, expect } = require('@playwright/test');

test('opening search again resets its query and focuses the input', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('/');
  const dialog = page.locator('#search-dialog');
  const search = dialog.getByRole('combobox');
  await search.fill('compiler');
  await dialog.getByRole('button', { name: 'Close search', exact: true }).focus();
  await page.keyboard.press('/');
  await expect(search).toBeFocused();
  await expect(search).toHaveValue('');
  await expect(dialog.getByRole('option')).toHaveCount(4);
});

test('search navigation survives pointer selection and keeps focus off panel containers', async ({
  page,
}) => {
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('/');
  const dialog = page.locator('#search-dialog');
  const search = dialog.getByRole('combobox');
  const results = dialog.getByRole('option');
  await expect(search).toBeFocused();
  await dialog.locator('#search-dialog-title').click();
  await expect(search).toBeFocused();
  await results.nth(1).hover();
  await expect(results.nth(1)).toHaveAttribute('aria-selected', 'true');
  for (const index of [2, 3, 0]) {
    await page.keyboard.press('ArrowDown');
    await expect(results.nth(index)).toHaveAttribute('aria-selected', 'true');
    await expect(search).toBeFocused();
    await expect(dialog).not.toBeFocused();
    await expect(dialog).toHaveCSS('outline-style', 'none');
  }
  await page.mouse.move(0, 0);
  await results.nth(2).focus();
  await expect(results.nth(2)).toHaveAttribute('aria-selected', 'true');
  await page.keyboard.press('ArrowUp');
  await expect(results.nth(1)).toHaveAttribute('aria-selected', 'true');
  await expect(search).toBeFocused();
  await dialog.locator('.launcher-results').evaluate((node) => node.focus());
  await expect(search).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\/posts\/types-as-design-tools\/index.html$/);
});

test('keymap containers never keep focus and native close-button keys still work', async ({
  page,
}) => {
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('?');
  const dialog = page.locator('#keymap-dialog');
  const close = dialog.getByRole('button', { name: 'Close keyboard shortcuts', exact: true });
  await expect(close).toBeFocused();
  await dialog.locator('#keymap-title').click();
  await expect(close).toBeFocused();
  await dialog.locator('.keymap-row dd').first().click();
  await expect(close).toBeFocused();
  for (const key of ['ArrowDown', 'ArrowUp', 'Tab', 'Shift+Tab']) {
    await page.keyboard.press(key);
    await expect(close).toBeFocused();
    await expect(dialog).not.toBeFocused();
    await expect(dialog).toHaveCSS('outline-style', 'none');
  }
  await dialog.evaluate((node) => node.focus());
  await expect(close).toBeFocused();
  await close.press('Enter');
  await expect(dialog).not.toBeVisible();
  await page.keyboard.press('/');
  const searchDialog = page.locator('#search-dialog');
  const closeSearch = searchDialog.getByRole('button', { name: 'Close search', exact: true });
  await closeSearch.focus();
  await closeSearch.press('Enter');
  await expect(searchDialog).not.toBeVisible();
  await expect(page).toHaveURL('/');
});

test('search launcher finds title/description words, tags, categories, and combinations', async ({
  page,
}) => {
  await page.goto('/?tag=notes');
  await expect(page.locator('.post-row')).toHaveCount(2);
  await page.locator('.search-launch').click();
  const dialog = page.getByRole('dialog', { name: 'Search notes', exact: true });
  const search = dialog.getByRole('combobox', { name: 'Search all notes', exact: true });
  const results = dialog.getByRole('option');
  await expect(search).toBeFocused();
  await expect(results).toHaveCount(4);
  for (const [query, count, title] of [
    ['TYPES', 1, 'Types are a way to ask better questions'],
    ['algebraic', 1, 'Types are a way to ask better questions'],
    ['#HAS', 2],
    ['#haskell #elm', 1, 'From plain text to a small, personal web'],
    ['/prog', 1, 'Types are a way to ask better questions'],
    ['/web #elm compiler', 1, 'From plain text to a small, personal web'],
    ['/notes', 1, 'A notebook that stays yours'],
    ['#', 4],
    ['/', 4],
    ['RefreshFailed', 0],
    ['#unknown', 0],
  ]) {
    await search.fill(query);
    await expect(results).toHaveCount(count);
    if (title) await expect(results.first()).toContainText(title);
  }
  await expect(dialog.getByText('No notes match.', { exact: false })).toBeVisible();
  await search.fill('#haskell');
  await page.screenshot({ path: 'test-results/search-launcher-desktop.png' });
  await page.keyboard.press('Escape');
  await expect(dialog).not.toBeVisible();
  await expect(page.locator('.post-row')).toHaveCount(2);
  await expect(page).toHaveURL(/\?tag=notes$/);
});

test('launcher is modal, darkens the background, traps focus, and restores it on dismissal', async ({
  page,
}) => {
  await page.goto('/');
  const opener = page.locator('.search-launch');
  await opener.click();
  const dialog = page.locator('#search-dialog');
  await expect(dialog).toBeVisible();
  expect(await dialog.evaluate((node) => node.matches(':modal'))).toBe(true);
  expect(
    await dialog.evaluate((node) => getComputedStyle(node, '::backdrop').backgroundColor),
  ).toBe('rgba(0, 0, 0, 0.7)');
  await expect(page.locator('html')).toHaveCSS('overflow', 'hidden');
  for (let step = 0; step < 5; step++) {
    await page.keyboard.press('Tab');
    expect(
      await page.evaluate(() => Boolean(document.activeElement.closest('#search-dialog'))),
    ).toBe(true);
  }
  await page.keyboard.press('Escape');
  await expect(dialog).not.toBeVisible();
  await expect(opener).toBeFocused();
  await expect(page.locator('html')).not.toHaveClass(/search-open/);
  await opener.click();
  await expect(dialog).toBeVisible();
  await page.mouse.click(8, 8);
  await expect(dialog).not.toBeVisible();
  await expect(opener).toBeFocused();
  await opener.click();
  await dialog.getByRole('button', { name: 'Close search', exact: true }).click();
  await expect(dialog).not.toBeVisible();
});

test('launcher opens on article pages and supports arrow keys and Enter', async ({ page }) => {
  await page.goto('/posts/a-notebook-that-stays-yours/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('/');
  const dialog = page.locator('#search-dialog');
  await expect(dialog).toBeVisible();
  await expect(page).toHaveURL(/\/posts\/a-notebook-that-stays-yours\/$/);
  const search = dialog.getByRole('combobox');
  await expect(search).toBeFocused();
  await search.fill('/web');
  await expect(dialog.getByRole('option')).toHaveCount(2);
  await search.press('ArrowDown');
  await expect(search).toHaveAttribute('aria-activedescendant', 'search-result-1');
  await expect(dialog.getByRole('option').nth(1)).toHaveAttribute('aria-selected', 'true');
  await search.press('ArrowDown');
  await expect(search).toHaveAttribute('aria-activedescendant', 'search-result-0');
  await search.press('ArrowUp');
  await expect(search).toHaveAttribute('aria-activedescendant', 'search-result-1');
  await search.press('Enter');
  await expect(page).toHaveURL(/\/posts\/a-quieter-interface\/index.html$/);
  await expect(page.locator('blog-content h1')).toHaveText('A quieter interface for a noisier web');
  await page.locator('.search-launch').click();
  await dialog.getByRole('combobox').fill('#elm');
  await dialog.getByRole('option').click();
  await expect(page).toHaveURL(/\/posts\/plain-text-to-a-small-web\/index.html$/);
});

test('launcher works on mobile and opens from a direct search URL', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/?search=1');
  const dialog = page.locator('#search-dialog');
  await expect(dialog).toBeVisible();
  await expect(dialog.getByRole('combobox')).toBeFocused();
  const box = await dialog.boundingBox();
  expect(box.x).toBeGreaterThanOrEqual(0);
  expect(box.x + box.width).toBeLessThanOrEqual(390);
  expect(box.y + box.height).toBeLessThanOrEqual(844);
  await dialog.getByRole('combobox').fill('/web');
  await expect(dialog.getByRole('option')).toHaveCount(2);
  await page.screenshot({ path: 'test-results/search-launcher-mobile.png' });
  await page.keyboard.press('Escape');
  await page.getByRole('button', { name: 'Toggle navigation' }).click();
  await page.locator('.search-launch').click();
  await expect(dialog).toBeVisible();
  await expect(page.locator('.sidebar')).toBeHidden();
  await page.keyboard.press('Escape');
  await expect(page.getByRole('button', { name: 'Toggle navigation' })).toBeFocused();
  await page.keyboard.press('/');
  await expect(dialog).toBeVisible();
});

test('question mark opens the keymap and slash switches exclusively to search', async ({
  page,
}) => {
  await page.goto('/posts/types-as-design-tools/');
  await expect(page.locator('.workspace')).toBeVisible();
  const sidebarLinks = await page.locator('.sidebar-links').boundingBox();
  const helpButton = await page.locator('.sidebar-bottom .keymap-trigger').boundingBox();
  expect(helpButton.x).toBeGreaterThan(sidebarLinks.x + sidebarLinks.width);
  expect(
    Math.abs(helpButton.y + helpButton.height / 2 - sidebarLinks.y - sidebarLinks.height / 2),
  ).toBeLessThan(1);
  await expect(page.locator('.statusbar .keymap-trigger')).toHaveCount(0);
  await page.keyboard.press('?');
  const keymap = page.getByRole('dialog', { name: 'Keyboard shortcuts', exact: true });
  const search = page.getByRole('dialog', { name: 'Search notes', exact: true });
  await expect(keymap).toBeVisible();
  await expect(keymap.locator('kbd').filter({ hasText: /^\?$/ })).toHaveCount(1);
  await expect(keymap.locator('kbd').filter({ hasText: /^\/$/ })).toHaveCount(1);
  await expect(page.locator('dialog:modal')).toHaveCount(1);
  for (let index = 0; index < 4; index++) {
    await page.keyboard.press('Tab');
    expect(
      await page.evaluate(() => Boolean(document.activeElement.closest('#keymap-dialog'))),
    ).toBe(true);
  }
  await page.keyboard.press('/');
  await expect(keymap).not.toBeVisible();
  await expect(search).toBeVisible();
  await expect(search.getByRole('combobox')).toBeFocused();
  await expect(page.locator('dialog:modal')).toHaveCount(1);
  await search.getByRole('combobox').press('?');
  await expect(search.getByRole('combobox')).toHaveValue('?');
  await expect(keymap).not.toBeVisible();
  await page.keyboard.press('Escape');
  await expect(page.locator('dialog:modal')).toHaveCount(0);
  await page.keyboard.press('?');
  await expect(keymap).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(keymap).not.toBeVisible();
  await expect(page).toHaveURL(/\/posts\/types-as-design-tools\/$/);
});

test('keymap is available on mobile and typing question marks leaves text fields alone', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  const inlineSearch = page.getByRole('searchbox');
  await inlineSearch.fill('why');
  await inlineSearch.press('?');
  await expect(inlineSearch).toHaveValue('why?');
  await expect(page.locator('dialog:modal')).toHaveCount(0);
  const menu = page.getByRole('button', { name: 'Toggle navigation', exact: true });
  await menu.click();
  const opener = page
    .locator('.sidebar-bottom')
    .getByRole('button', { name: 'Keyboard shortcuts', exact: true });
  await opener.click();
  const keymap = page.getByRole('dialog', { name: 'Keyboard shortcuts', exact: true });
  await expect(keymap).toBeVisible();
  const box = await keymap.boundingBox();
  expect(box.x).toBeGreaterThanOrEqual(0);
  expect(box.x + box.width).toBeLessThanOrEqual(390);
  expect(box.y + box.height).toBeLessThanOrEqual(844);
  await page.screenshot({ path: 'test-results/keymap-mobile.png' });
  await page.mouse.click(8, 8);
  await expect(keymap).not.toBeVisible();
  await expect(menu).toBeFocused();
  await expect(page.locator('html')).not.toHaveClass(/search-open/);
  await menu.click();
  await opener.click();
  await expect(keymap.getByRole('button', { name: 'Open search /', exact: true })).toHaveCount(0);
  await page.keyboard.press('/');
  await expect(keymap).not.toBeVisible();
  await expect(page.getByRole('dialog', { name: 'Search notes', exact: true })).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(menu).toBeFocused();
});
