const { test, expect } = require('@playwright/test');

test('mouse-focused categories and page-size controls do not gain Tab outlines from shortcuts', async ({
  page,
}) => {
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  const category = page.getByRole('button', { name: /^programming\b/ });
  await page.keyboard.press('Tab');
  await category.focus();
  await expect(category).toHaveCSS('outline-style', 'solid');
  await category.click();
  await expect(category).toBeFocused();
  await expect(category).toHaveCSS('outline-style', 'none');
  await page.keyboard.press('f');
  await expect(page.locator('.link-hints')).toBeVisible();
  await expect(category).toBeFocused();
  await expect(category).toHaveCSS('outline-style', 'none');
  await page.keyboard.press('Escape');
  await expect(page.locator('.link-hints')).toHaveCount(0);
  const size = page.getByLabel('Notes per page');
  await size.click();
  await page.keyboard.press('Escape');
  await expect(size).toHaveCSS('outline-style', 'none');
  await size.selectOption('30');
  await expect(page.locator('#notebook-heading')).toBeFocused();
  await expect(page.locator('#notebook-heading')).toHaveCSS('outline-style', 'none');
  await page.keyboard.press('Tab');
  await size.focus();
  await expect(size).toHaveCSS('outline-style', 'solid');
  await page.keyboard.press('Escape');
  await expect(size).not.toBeFocused();
  await expect(page.locator('[data-tab-focus]')).toHaveCount(0);
});

test('Tab shows focus when a dialog traps focus on the same mouse-focused button', async ({
  page,
}) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Keyboard shortcuts', exact: true }).click();
  const dialog = page.locator('#keymap-dialog');
  const close = dialog.getByRole('button', { name: 'Close keyboard shortcuts', exact: true });
  await expect(close).toBeFocused();
  await expect(close).toHaveCSS('outline-style', 'none');
  await page.keyboard.press('Tab');
  await expect(close).toBeFocused();
  await expect(close).toHaveCSS('outline-style', 'solid');
  await dialog.locator('#keymap-title').click();
  await page.keyboard.press('ArrowDown');
  await expect(close).toBeFocused();
  await expect(close).toHaveCSS('outline-style', 'none');
  await expect(dialog).toHaveCSS('outline-style', 'none');
  await page.keyboard.press('Shift+Tab');
  await expect(close).toHaveCSS('outline-style', 'solid');
});

test('Elm assigns unambiguous hint labels across the three-letter boundary', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.evaluate(() => {
    const links = document.createElement('nav');
    links.setAttribute('aria-label', 'Hint fixture');
    Object.assign(links.style, {
      position: 'fixed',
      inset: '80px 20px auto 270px',
      zIndex: '10',
      display: 'grid',
      gridTemplateColumns: 'repeat(10, 1fr)',
    });
    for (let index = 0; index < 100; index++) {
      const link = document.createElement('a');
      link.href = `/?target=${index}`;
      link.textContent = `Target ${index}`;
      link.style.padding = '4px';
      links.append(link);
    }
    document.body.append(links);
  });
  await page.keyboard.press('f');
  const target = page.locator('.link-hint[title="Target 99"]');
  await expect(target).toBeVisible();
  const labels = await page
    .locator('.link-hint')
    .evaluateAll((nodes) => nodes.map((node) => node.dataset.hint));
  expect(labels.length).toBeGreaterThan(81);
  expect(new Set(labels).size).toBe(labels.length);
  expect(labels.every((label) => label.length === 3)).toBe(true);
  const key = await target.getAttribute('data-hint');
  await page.keyboard.type(key.slice(0, 2));
  await expect(page).toHaveURL('/');
  await page.keyboard.type(key.slice(2));
  await expect(page).toHaveURL('/?target=99');
});

test('note highlighting follows only its own row and clears when the pointer leaves', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  const rows = page.locator('.post-row');
  const titles = rows.locator('h3 a');
  const normal = await page.locator('body').evaluate((node) => getComputedStyle(node).color);
  const accent = await page.locator('.brand-mark').evaluate((node) => getComputedStyle(node).color);
  await page.locator('.intro h1').hover();
  for (const title of await titles.all()) await expect(title).toHaveCSS('color', normal);
  await rows.first().locator('p').hover();
  await expect(titles.first()).toHaveCSS('color', accent);
  await expect(titles.nth(1)).toHaveCSS('color', normal);
  await rows.nth(1).locator('p').hover();
  await expect(titles.first()).toHaveCSS('color', normal);
  await expect(titles.nth(1)).toHaveCSS('color', accent);
  await page.locator('.intro h1').hover();
  for (const title of await titles.all()) await expect(title).toHaveCSS('color', normal);
  await page.mouse.move(1, 1);
  await page.keyboard.press('Tab');
  await titles.first().focus();
  await expect(titles.first()).toHaveCSS('color', accent);
  await titles.first().press('Escape');
  await expect(titles.first()).toHaveCSS('color', normal);
});

test('Escape clears control outlines and input focus without changing page state', async ({
  page,
}) => {
  await page.goto('/?tag=haskell');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('Tab');
  const theme = page.getByRole('button', { name: 'Toggle color theme', exact: true });
  await theme.focus();
  await expect(theme).toHaveCSS('outline-style', 'solid');
  await theme.press('Escape');
  await expect(theme).not.toBeFocused();
  await expect(theme).toHaveCSS('outline-style', 'none');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.keyboard.press('Tab');
  await expect(page.locator(':focus-visible')).toHaveCSS('outline-style', 'solid');
  const inline = page.getByRole('searchbox');
  await inline.fill('plain');
  await expect(page).toHaveURL(/q=plain/);
  const url = page.url();
  await inline.press('Escape');
  await expect(inline).not.toBeFocused();
  await expect(inline).toHaveValue('plain');
  await expect(page.locator('.selected-tag')).toHaveCount(1);
  await expect(page).toHaveURL(url);
  const note = page.locator('.post-row').first().getByRole('link');
  await note.focus();
  await note.press('Escape');
  await expect(note).not.toBeFocused();
  await expect(page).toHaveURL(url);
});

test('Escape closes panels and hints before clearing focus, including immersive controls', async ({
  page,
}) => {
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  const launcher = page.getByRole('button', { name: /Search notes/ });
  await launcher.click();
  await expect(page.locator('#launcher-search')).toBeFocused();
  await page.keyboard.press('Escape');
  await expect(page.locator('#search-dialog')).not.toBeVisible();
  await expect(launcher).toBeFocused();
  await page.keyboard.press('Escape');
  await expect(launcher).not.toBeFocused();
  await launcher.focus();
  await page.keyboard.press('f');
  await expect(page.locator('.link-hint').first()).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(page.locator('.link-hints')).toHaveCount(0);
  await expect(launcher).toBeFocused();
  await page.keyboard.press('Escape');
  await expect(launcher).not.toBeFocused();
  await page.keyboard.press('Shift+I');
  const exit = page.getByRole('button', { name: 'Exit immersive mode', exact: true });
  await exit.focus();
  await exit.press('Escape');
  await expect(exit).not.toBeFocused();
  await expect(exit).toHaveCSS('outline-style', 'none');
  await expect(page.locator('.workspace')).toHaveClass(/is-immersive/);
  const copy = page.locator('.code-copy').first();
  await copy.focus();
  await copy.press('Escape');
  await expect(copy).not.toBeFocused();
  await expect(copy).toHaveCSS('outline-style', 'none');
});

test('t toggles theme and o hides and restores the reading outline', async ({ page }) => {
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('t');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('o');
  await expect(page.locator('.page-outline')).toHaveCount(0);
  await expect(page.locator('.reading-layout')).toHaveCount(0);
  await page.keyboard.press('o');
  await expect(page.locator('.page-outline')).toBeVisible();
  await expect(page.locator('.reading-layout')).toBeVisible();
  await page.keyboard.press('?');
  const keymap = page.getByRole('dialog', { name: 'Keyboard shortcuts', exact: true });
  for (const key of ['t', 'o', 'f', 'Enter']) {
    await expect(keymap.locator('kbd').filter({ hasText: new RegExp(`^${key}$`) })).toHaveCount(1);
  }
  await page.keyboard.press('t');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
});

test('Enter opens the selected index note without hijacking native controls', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('.post-row.is-selected')).toContainText('From plain text');
  await page.locator('.post-row').nth(1).hover();
  await expect(page.locator('.post-row.is-selected')).toContainText('Types are a way');
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\/posts\/types-as-design-tools\/index.html$/);
  await page.goto('/?tag=notes');
  await expect(page.locator('.post-row.is-selected')).toContainText('A notebook that stays yours');
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\/posts\/a-notebook-that-stays-yours\/index.html$/);
  await page.goto('/');
  const theme = page.getByRole('button', { name: 'Toggle color theme', exact: true });
  await theme.focus();
  await theme.press('Enter');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await expect(page).toHaveURL('/');
  const title = page.locator('.post-row').last().getByRole('link');
  await title.focus();
  await expect(page.locator('.post-row.is-selected')).toContainText('A quieter interface');
  await title.press('Enter');
  await expect(page).toHaveURL(/\/posts\/a-quieter-interface\/index.html$/);
  await page.goto('/?q=unfindable');
  await expect(page.locator('.post-row')).toHaveCount(0);
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\?q=unfindable$/);
});

test('page keys do not interrupt typing or the search launcher', async ({ page }) => {
  await page.goto('/');
  const inline = page.getByRole('searchbox');
  await inline.fill('');
  await inline.press('t');
  await inline.press('o');
  await inline.press('f');
  await expect(inline).toHaveValue('tof');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await expect(page.locator('.link-hints')).toHaveCount(0);
  await inline.press('Enter');
  await expect(page).toHaveURL(/q=tof/);
  await page.locator('.search-launch').click();
  const search = page.getByRole('combobox', { name: 'Search all notes', exact: true });
  await search.fill('');
  await search.press('t');
  await search.press('o');
  await search.press('f');
  await expect(search).toHaveValue('tof');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await expect(page.locator('.link-hints')).toHaveCount(0);
});

test('f displays prefix-free link hints and follows a chosen visible link', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.evaluate(() => document.fonts.ready);
  await page.keyboard.press('f');
  await expect(page.locator('.link-hint').first()).toBeVisible();
  const labels = await page
    .locator('.link-hint')
    .evaluateAll((nodes) => nodes.map((node) => node.dataset.hint));
  expect(new Set(labels).size).toBe(labels.length);
  expect(new Set(labels.map((label) => label.length)).size).toBe(1);
  expect(labels.length).toBeGreaterThan(9);
  const categoryHint = page.locator('.link-hint[title="web"]');
  const key = await categoryHint.getAttribute('data-hint');
  await page.screenshot({ path: 'test-results/link-hints-desktop.png' });
  await page.keyboard.press('t');
  await expect(page.locator('.link-hint')).toHaveCount(0);
  await expect(page.locator('.link-hint-status')).toContainText('No matching hints');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.keyboard.press('Backspace');
  await expect(page.locator('.link-hint')).toHaveCount(labels.length);
  await page.keyboard.type(key[0]);
  await expect(page).toHaveURL(/\/posts\/plain-text-to-a-small-web\/$/);
  await expect(page.locator('.link-hint-status')).toContainText(
    `Open link: ${key[0].toUpperCase()}`,
  );
  const narrowed = await page
    .locator('.link-hint')
    .evaluateAll((nodes) => nodes.map((node) => node.dataset.hint));
  expect(narrowed.every((label) => label.startsWith(key[0]))).toBe(true);
  await page.keyboard.type(key.slice(1));
  await expect(page).toHaveURL(/\?category=web$/);
  await expect(page.locator('.post-row')).toHaveCount(2);
});

test('hint mode cancels on Escape and viewport changes', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('f');
  await expect(page.locator('.link-hint').first()).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(page.locator('.link-hints')).toHaveCount(0);
  await page.keyboard.press('f');
  await expect(page.locator('.link-hint').first()).toBeVisible();
  await page.evaluate(() => window.scrollBy(0, 100));
  await expect(page.locator('.link-hints')).toHaveCount(0);
  await page.keyboard.press('f');
  await expect(page.locator('.link-hint').first()).toBeVisible();
  await page.setViewportSize({ width: 1280, height: 900 });
  await expect(page.locator('.link-hints')).toHaveCount(0);
  await page.keyboard.press('?');
  await expect(page.getByRole('dialog', { name: 'Keyboard shortcuts', exact: true })).toBeVisible();
  await page.keyboard.press('f');
  await expect(page.locator('.link-hints')).toHaveCount(0);
});

test('index category buttons are hint targets and preserve tag filters', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/?tag=haskell');
  await expect(page.locator('.post-row')).toHaveCount(2);
  await page.keyboard.press('f');
  for (const category of ['notes', 'programming', 'web']) {
    await expect(page.locator(`.link-hint[title="${category}"]`)).toBeVisible();
  }
  const key = await page.locator('.link-hint[title="programming"]').getAttribute('data-hint');
  await page.keyboard.type(key);
  await expect(page.locator('.link-hints')).toHaveCount(0);
  await expect(page.locator('.breadcrumbs .current-category')).toHaveText('programming');
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(page.locator('.post-row')).toContainText('Types are a way to ask better questions');
  expect(new URL(page.url()).searchParams.get('category')).toBe('programming');
  expect(new URL(page.url()).searchParams.getAll('tag')).toEqual(['haskell']);
  await page.keyboard.press('f');
  const next = await page.locator('.link-hint[title="web"]').getAttribute('data-hint');
  await page.keyboard.type(next);
  await expect(page.locator('.breadcrumbs .current-category')).toHaveText('web');
  await expect(page.locator('.post-row')).toContainText('From plain text to a small, personal web');
});
