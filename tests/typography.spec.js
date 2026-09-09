const { test, expect } = require('@playwright/test');

test('bundled text fonts cover body, italic, code, and CJK without installed fonts', async ({
  page,
}) => {
  const fontRequests = [];
  page.on('request', (request) => {
    if (request.resourceType() === 'font') fontRequests.push(request.url());
  });
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  const samples = [
    { text: 'Asai Blog Æ Ω Ж', family: 'Noto Sans', stack: '--sans' },
    { text: 'Italic words', family: 'Noto Sans', stack: '--sans', style: 'italic' },
    { text: 'const value = 123;', family: 'Noto Sans Mono', stack: '--mono' },
    { text: '简体漢字繁體かなカナ한글', family: 'Noto Sans CJK SC', stack: '--sans' },
    { text: '简体漢字繁體かなカナ한글', family: 'Noto Sans Mono CJK SC', stack: '--mono' },
  ];
  await page.evaluate(async (samples) => {
    for (const [index, sample] of samples.entries()) {
      const node = document.createElement('p');
      node.id = `font-sample-${index}`;
      node.textContent = sample.text;
      node.style.fontFamily = `var(${sample.stack})`;
      node.style.fontStyle = sample.style || 'normal';
      document.body.append(node);
      await document.fonts.load(
        `${sample.style || 'normal'} 400 20px "${sample.family}"`,
        sample.text,
      );
    }
    await document.fonts.ready;
  }, samples);
  const client = await page.context().newCDPSession(page);
  await client.send('DOM.enable');
  await client.send('CSS.enable');
  const { root } = await client.send('DOM.getDocument');
  for (const [index, sample] of samples.entries()) {
    const { nodeId } = await client.send('DOM.querySelector', {
      nodeId: root.nodeId,
      selector: `#font-sample-${index}`,
    });
    const { fonts } = await client.send('CSS.getPlatformFontsForNode', { nodeId });
    expect(fonts.length).toBeGreaterThan(0);
    expect(fonts.every((font) => font.isCustomFont && font.familyName === sample.family)).toBe(
      true,
    );
  }
  expect(fontRequests.some((url) => url.endsWith('NotoSans.woff2'))).toBe(true);
  expect(fontRequests.some((url) => url.includes('NotoSansCJKsc-'))).toBe(true);
  expect(fontRequests.every((url) => new URL(url).origin === new URL(page.url()).origin)).toBe(
    true,
  );
});

test('bundled Noto symbol fonts render icons in aligned containers', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/');
  await expect(page.locator('.workspace')).toBeVisible();
  await page.evaluate(async () => {
    await document.fonts.load('400 20px "Noto Sans Symbols"', '↗');
    await document.fonts.load('400 20px "Noto Sans Symbols 2"', '◐☼');
    await document.fonts.ready;
  });
  const client = await page.context().newCDPSession(page);
  await client.send('DOM.enable');
  await client.send('CSS.enable');
  const { root } = await client.send('DOM.getDocument');
  const themeButton = page.getByRole('button', { name: 'Toggle color theme', exact: true });
  for (const theme of ['dark', 'light']) {
    await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
    const { nodeId } = await client.send('DOM.querySelector', {
      nodeId: root.nodeId,
      selector: '.top-actions .icon-button',
    });
    const { fonts } = await client.send('CSS.getPlatformFontsForNode', { nodeId });
    expect(
      fonts.some((font) => font.isCustomFont && font.familyName.startsWith('Noto Sans Symbols')),
    ).toBe(true);
    const clock = await page.locator('.local-clock').boundingBox();
    const button = await themeButton.boundingBox();
    expect(Math.abs(clock.y + clock.height / 2 - button.y - button.height / 2)).toBeLessThan(1);
    await page.screenshot({ path: `test-results/symbols-${theme}.png`, animations: 'disabled' });
    if (theme === 'dark') await themeButton.click();
  }
  const icon = await page.locator('.search-launch .search-icon').boundingBox();
  const label = await page.locator('.search-launch > span:not(.symbol)').boundingBox();
  expect(Math.abs(icon.y + icon.height / 2 - label.y - label.height / 2)).toBeLessThan(1);
  for (const width of [390, 320]) {
    await page.setViewportSize({ width, height: 844 });
    await expect(themeButton).toBeVisible();
    await expect(page.locator('.local-clock')).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(
      true,
    );
  }
});
