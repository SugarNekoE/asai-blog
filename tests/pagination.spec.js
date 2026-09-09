const { test, expect } = require('@playwright/test');

const posts = Array.from({ length: 137 }, (_, index) => ({
  title: `Entry ${String(index + 1).padStart(3, '0')}`,
  description: `Description for entry ${index + 1}`,
  date: new Date(Date.UTC(2025, 0, index + 1)).toISOString().slice(0, 10),
  url: `/posts/entry-${index + 1}/`,
  category: index < 80 ? 'web' : 'notes',
  tags: [index % 2 === 0 ? 'even' : 'odd', 'shared'],
  readingMinutes: 1,
  searchText: `Body of entry ${index + 1}`,
}));

test.beforeEach(async ({ page }) => {
  await page.route('**/api/posts.json', (route) => route.fulfill({ json: { version: 2, posts } }));
});

test('default pages contain at most ten notes with working boundaries and reloads', async ({
  page,
}) => {
  await page.goto('/');
  const rows = page.locator('.post-row');
  const navigation = page.getByRole('navigation', { name: 'Notes pagination', exact: true });
  await expect(rows).toHaveCount(10);
  await expect(rows.first()).toContainText('Entry 137');
  await expect(rows.last()).toContainText('Entry 128');
  await expect(page.getByLabel('Notes per page')).toHaveValue('10');
  await expect(page.locator('.pagination-summary')).toHaveText('1–10 of 137 notes');
  await expect(navigation.getByRole('button', { name: 'Previous', exact: true })).toBeDisabled();
  await expect(page.locator('.notebook-end')).toHaveCount(0);
  await navigation.getByRole('button', { name: 'Next', exact: true }).click();
  await expect(rows.first()).toContainText('Entry 127');
  await expect(rows.first().locator('.post-kicker')).toContainText('NOTE 11');
  await expect(page.locator('.pagination-summary')).toHaveText('11–20 of 137 notes');
  await expect(page.locator('#notebook-heading')).toBeFocused();
  expect(new URL(page.url()).searchParams.get('page')).toBe('2');
  await page.reload();
  await expect(rows.first()).toContainText('Entry 127');
  await navigation.getByRole('button', { name: 'Go to page 14', exact: true }).click();
  await expect(rows).toHaveCount(7);
  await expect(rows.last()).toContainText('Entry 001');
  await expect(navigation.getByRole('button', { name: 'Next', exact: true })).toBeDisabled();
  await expect(page.locator('.notebook-end')).toBeVisible();
  await navigation.getByRole('button', { name: 'Go to page 1', exact: true }).click();
  await expect(rows).toHaveCount(10);
  expect(new URL(page.url()).searchParams.has('page')).toBe(false);
});

test('page-size choices are 10/30/50/100 and reset pagination', async ({ page }) => {
  await page.goto('/?page=4');
  const size = page.getByLabel('Notes per page');
  await expect(size.locator('option')).toHaveText(['10', '30', '50', '100']);
  for (const count of [30, 50, 100, 10]) {
    await size.selectOption(String(count));
    await expect(page.locator('.post-row')).toHaveCount(count);
    await expect(page.locator('.post-row').first()).toContainText('Entry 137');
    await expect(page.getByRole('button', { name: 'Go to page 1', exact: true })).toHaveAttribute(
      'aria-current',
      'page',
    );
    await page.reload();
    await expect(size).toHaveValue(String(count));
    await expect(page.locator('.post-row')).toHaveCount(count);
  }
  await page.setViewportSize({ width: 390, height: 844 });
  await page.locator('.pagination').scrollIntoViewIfNeeded();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.locator('.pagination').screenshot({ path: 'test-results/pagination-mobile.png' });
});

test('pagination applies after category and tags while clear filters preserves category and page size', async ({
  page,
}) => {
  await page.goto('/?category=web&page=3&perPage=30');
  await expect(page.locator('.post-row')).toHaveCount(20);
  await page.locator('.tag-picker > summary').click();
  await page.getByRole('checkbox', { name: 'Select tag even', exact: true }).check();
  await page.locator('.tag-picker > summary').click();
  await expect(page.locator('.post-row')).toHaveCount(30);
  await expect(page.locator('.pagination-summary')).toHaveText('1–30 of 40 notes');
  await page
    .getByRole('navigation', { name: 'Notes pagination', exact: true })
    .getByRole('button', { name: 'Next', exact: true })
    .click();
  await expect(page.locator('.post-row')).toHaveCount(10);
  await page.getByRole('button', { name: 'Clear filters', exact: true }).click();
  await expect(page.locator('.pagination-summary')).toHaveText('1–30 of 80 notes');
  await expect(page.locator('.breadcrumbs .current-category')).toHaveText('web');
  await expect(page.getByLabel('Notes per page')).toHaveValue('30');
  await page.getByRole('searchbox').fill('Entry 001');
  await expect(page.locator('.post-row')).toHaveCount(1);
  await expect(page.locator('.pagination-summary')).toHaveText('1–1 of 1 notes');
  await page.getByRole('searchbox').fill('');
  await page
    .getByRole('navigation', { name: 'Notes pagination', exact: true })
    .getByRole('button', { name: 'Next', exact: true })
    .click();
  await page.getByRole('button', { name: 'Newest first', exact: true }).click();
  await expect(page.locator('.post-row').first()).toContainText('Entry 001');
  await page.reload();
  await expect(page.locator('.post-row').first()).toContainText('Entry 001');
  await expect(page.getByRole('button', { name: 'Oldest first', exact: true })).toBeVisible();
});

test('invalid pagination is bounded and empty results have disabled navigation', async ({
  page,
}) => {
  for (const query of ['page=-1&perPage=20', 'page=oops&perPage=0', 'page=1.5&perPage=999']) {
    await page.goto('/?' + query);
    await expect(page.locator('.post-row')).toHaveCount(10);
    await expect(page.locator('.post-row').first()).toContainText('Entry 137');
    await expect(page.getByLabel('Notes per page')).toHaveValue('10');
  }
  await page.goto('/?page=999&perPage=100');
  await expect(page.locator('.post-row')).toHaveCount(37);
  await expect(page.getByRole('button', { name: 'Go to page 2', exact: true })).toHaveAttribute(
    'aria-current',
    'page',
  );
  await page.getByRole('searchbox').fill('no matching note');
  await expect(page.locator('.post-row')).toHaveCount(0);
  await expect(page.locator('.pagination-summary')).toHaveText('0 notes');
  const navigation = page.getByRole('navigation', { name: 'Notes pagination', exact: true });
  await expect(navigation.getByRole('button', { name: 'Previous', exact: true })).toBeDisabled();
  await expect(navigation.getByRole('button', { name: 'Next', exact: true })).toBeDisabled();
  await expect(page.locator('.notebook-end')).toHaveCount(0);
});
