// Run with Node.js and Playwright available in NODE_PATH (development only).
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');

(async () => {
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  try {
    const page = await browser.newPage();
    await page.addScriptTag({ path: path.join(__dirname, 'move_button_renderer.js') });
    const png = await page.evaluate(() => {
      const tile = document.createElement('canvas');
      tile.width = 296; tile.height = 250;
      const atlas = document.createElement('canvas');
      atlas.width = tile.width * 6; atlas.height = tile.height * 6;
      const ctx = atlas.getContext('2d');
      for (let player = 0; player < 2; player++) {
        for (let frame = 0; frame < 17; frame++) {
          window.renderMoveButton(tile, player, frame / 16);
          const index = player * 17 + frame;
          ctx.drawImage(tile, index % 6 * tile.width, Math.floor(index / 6) * tile.height);
        }
      }
      return atlas.toDataURL('image/png').split(',')[1];
    });
    const output = path.join(__dirname, '../assets/images/move_button.png');
    fs.mkdirSync(path.dirname(output), { recursive: true });
    fs.writeFileSync(output, Buffer.from(png, 'base64'));
    console.log('Generated 34 plunger frames: ' + output);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
