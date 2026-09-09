const { test, expect } = require('@playwright/test');
const fs = require('node:fs');

test('tag mappings are shared by badges, chips, picker labels, and launcher results in both themes', async ({
  page,
}) => {
  await page.goto('/');
  const badge = page.locator('.post-row .tag[data-tag="elm"]');
  await badge.click();
  await page.mouse.move(0, 0);
  for (const [theme, color] of [
    ['dark', 'rgb(120, 220, 232)'],
    ['light', 'rgb(37, 112, 123)'],
  ]) {
    await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
    await expect(badge).toHaveCSS('color', color);
    await expect(page.locator('.selected-tag[data-tag="elm"]')).toHaveCSS('color', color);
    await expect(page.locator('.tag-option[data-tag="elm"]')).toHaveCSS('color', color);
    await page.locator('.search-launch').click();
    await expect(page.getByRole('dialog', { name: 'Search notes', exact: true })).toBeVisible();
    await expect(page.locator('.launcher-tag[data-tag="elm"]')).toHaveCSS('color', color);
    await page.keyboard.press('Escape');
    await page.screenshot({ path: `test-results/colors-${theme}.png`, animations: 'disabled' });
    if (theme === 'dark')
      await page.getByRole('button', { name: 'Toggle color theme', exact: true }).click();
  }
});

test('editing only the color config remaps tags and accents, including special-character tags', async ({
  page,
}) => {
  const original = fs.readFileSync('static/assets/colors.css', 'utf8');
  const custom =
    original
      .replace('--tag-color: var(--monokai-pro-blue);', '--tag-color: var(--monokai-pro-red);')
      .replace('--accent: var(--monokai-pro-green);', '--accent: var(--monokai-pro-blue);') +
    '\n[data-tag="c++"] { --tag-color: var(--monokai-pro-orange); }\n';
  await page.route('**/assets/colors.css*', (route) =>
    route.fulfill({ body: custom, contentType: 'text/css' }),
  );
  const data = JSON.parse(fs.readFileSync('_site/api/posts.json', 'utf8'));
  data.posts[0].tags.push('c++', 'unmapped');
  await page.route('**/api/posts.json', (route) => route.fulfill({ json: data }));
  await page.goto('/');
  const elm = page.locator('.post-row .tag[data-tag="elm"]');
  await expect(elm).toHaveCSS('color', 'rgb(255, 97, 136)');
  await expect(page.locator('.intro em')).toHaveCSS('color', 'rgb(120, 220, 232)');
  await expect(page.locator('.tag[data-tag="c++"]')).toHaveCSS('color', 'rgb(252, 152, 103)');
  await expect(page.locator('.tag[data-tag="unmapped"]')).toHaveCSS('color', 'rgb(171, 157, 242)');
  const darkTint = await elm.evaluate((node) => getComputedStyle(node).backgroundColor);
  const darkBorder = await elm.evaluate((node) => getComputedStyle(node).borderTopColor);
  expect(darkTint).not.toBe('rgba(0, 0, 0, 0)');
  await elm.click();
  await expect(page.locator('.selected-tag[data-tag="elm"]')).toHaveCSS(
    'color',
    'rgb(255, 97, 136)',
  );
  await page.getByRole('button', { name: 'Toggle color theme', exact: true }).click();
  await expect(elm).toHaveCSS('color', 'rgb(181, 53, 91)');
  await expect(page.locator('.intro em')).toHaveCSS('color', 'rgb(37, 112, 123)');
  expect(await elm.evaluate((node) => getComputedStyle(node).backgroundColor)).not.toBe(darkTint);
  expect(await elm.evaluate((node) => getComputedStyle(node).borderTopColor)).not.toBe(darkBorder);
});
