const { test, expect } = require('@playwright/test');
const { execFileSync } = require('node:child_process');

function pdfText(path) {
  return execFileSync('pdftotext', [path, '-'], { encoding: 'utf8' });
}

test('print output contains the article without panels, controls, or a dark canvas', async ({
  page,
}) => {
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('?');
  await expect(page.locator('#keymap-dialog')).toBeVisible();
  await page.emulateMedia({ media: 'print' });
  for (const selector of [
    '.sidebar',
    '.topbar',
    '.statusbar',
    '.page-outline',
    '#keymap-dialog',
    '.prose > .back',
    '.end-note',
    '.article-end-divider',
  ]) {
    await expect(page.locator(selector)).toBeHidden();
  }
  await expect(page.locator('.prose h1')).toBeVisible();
  await expect(page.locator('body')).toHaveCSS('background-color', 'rgb(255, 255, 255)');
  await expect(page.locator('html')).toHaveCSS('overflow', 'visible');
  await expect(page.locator('.prose')).toHaveCSS('color', 'rgb(0, 0, 0)');
  await page.evaluate(() => document.fonts.ready);
  const path = 'test-results/article-print.pdf';
  await page.pdf({ path, preferCSSPageSize: true, printBackground: true });
  const text = pdfText(path).replace(/\s+/g, ' ');
  expect(text).toContain('From plain text to a small, personal web');
  expect(text).toContain('Keep the build disposable');
  for (const chrome of [
    'Keyboard shortcuts',
    'ON THIS PAGE',
    'RSS feed',
    'CC-BY-SA',
    'End of file. Keep exploring.',
    'Please Be Patient',
  ]) {
    expect(text).not.toContain(chrome);
  }
  expect(text).not.toMatch(/loading \d+ms/);
  expect(execFileSync('pdfinfo', [path], { encoding: 'utf8' })).toContain('A4');
  await page.emulateMedia({ media: 'screen' });
  await expect(page.locator('#keymap-dialog')).toBeVisible();
  await expect(page.locator('body')).toHaveCSS('background-color', 'rgb(36, 34, 37)');
});

test('long code and tables print completely across multiple pages in immersive mode', async ({
  page,
}) => {
  await page.goto('/posts/plain-text-to-a-small-web/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.keyboard.press('Shift+I');
  await page.evaluate(() => {
    const article = document.querySelector('.prose');
    const pre = document.createElement('pre');
    const code = document.createElement('code');
    code.textContent =
      Array.from(
        { length: 50 },
        (_, index) => `line_${index}: ` + 'UNBROKEN_IDENTIFIER_'.repeat(18),
      ).join('\n') + '\nPRINT_CODE_END';
    pre.append(code);
    article.append(pre);
    const table = document.createElement('table');
    const head = table.createTHead().insertRow();
    for (let column = 0; column < 8; column++) {
      const cell = document.createElement('th');
      cell.textContent = `Column ${column}`;
      head.append(cell);
    }
    const body = table.createTBody();
    for (let row = 0; row < 60; row++) {
      const line = body.insertRow();
      for (let column = 0; column < 8; column++)
        line.insertCell().textContent = `value_${row}_${column}_long`;
    }
    const end = body.insertRow().insertCell();
    end.colSpan = 8;
    end.textContent = 'PRINT_TABLE_END';
    article.append(table);
    const last = document.createElement('p');
    last.textContent = 'PRINT_ARTICLE_END';
    article.append(last);
  });
  await page.emulateMedia({ media: 'print' });
  await expect(page.locator('.main-content')).toHaveCSS('padding-left', '0px');
  await expect(page.locator('.immersive-header')).toBeHidden();
  await expect(page.locator('.prose pre').last()).toHaveCSS('overflow', 'visible');
  await expect(page.locator('.prose table')).toHaveCSS('display', 'table');
  await expect(page.locator('thead')).toHaveCSS('display', 'table-header-group');
  await page.evaluate(() => document.fonts.ready);
  const path = 'test-results/article-long-print.pdf';
  await page.pdf({ path, preferCSSPageSize: true, printBackground: true });
  const text = pdfText(path);
  expect(text.replace(/\s+/g, '').match(/UNBROKEN_IDENTIFIER_/g)).toHaveLength(900);
  expect(text.match(/value_/g)).toHaveLength(480);
  for (const marker of ['PRINT_CODE_END', 'PRINT_TABLE_END', 'PRINT_ARTICLE_END'])
    expect(text).toContain(marker);
  expect(text.split('\f').length - 1).toBeGreaterThan(1);
  await page.emulateMedia({ media: 'screen' });
  await expect(page.locator('.workspace')).toHaveClass(/is-immersive/);
});

test('printing works with JavaScript disabled and hides index controls', async ({
  browser,
  page,
}) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  try {
    const staticPage = await context.newPage();
    await staticPage.goto('http://127.0.0.1:8765/posts/types-as-design-tools/');
    await staticPage.emulateMedia({ media: 'print' });
    await expect(staticPage.locator('.fallback > nav')).toBeHidden();
    await expect(staticPage.locator('.fallback > footer')).toBeHidden();
    await expect(staticPage.locator('.prose h1')).toBeVisible();
    const path = 'test-results/article-static-print.pdf';
    await staticPage.pdf({ path, preferCSSPageSize: true });
    expect(pdfText(path).replace(/\s+/g, ' ')).toContain('Types are a way to ask better questions');
  } finally {
    await context.close();
  }
  await page.goto('/?tag=elm');
  await expect(page.locator('.post-row')).toHaveCount(1);
  await page.emulateMedia({ media: 'print' });
  for (const selector of ['.filterbar', '.search-field', '.pagination', '.notebook-end']) {
    await expect(page.locator(selector)).toBeHidden();
  }
  await expect(page.locator('.post-row')).toBeVisible();
});

test('print styles reveal static content even during startup', async ({ page }) => {
  let release;
  const ready = new Promise((resolve) => {
    release = resolve;
  });
  await page.route('**/assets/elm.js*', async (route) => {
    await ready;
    await route.continue();
  });
  try {
    await page.goto('/posts/types-as-design-tools/', { waitUntil: 'commit' });
    await expect(page.locator('#loading-screen')).toBeVisible();
    await page.emulateMedia({ media: 'print' });
    await expect(page.locator('#loading-screen')).toBeHidden();
    await expect(page.locator('#static-content')).toBeVisible();
    await page.emulateMedia({ media: 'screen' });
    await expect(page.locator('#loading-screen')).toBeVisible();
    release();
    await expect(page.locator('.workspace')).toBeVisible();
  } finally {
    release();
  }
});
