// Renders places-promo.html frame by frame with headless Edge and pipes the frames to ffmpeg.
//   npm i puppeteer-core ffmpeg-static   (anywhere; run with NODE_PATH pointing at that node_modules)
//   node render.js stills 0.5,2.4,7.8 out-dir        → PNG frames for review
//   node render.js video out.mp4 [fps=60] [sub=3]    → H.264, `sub` sub-frames blended per frame (motion blur)
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const puppeteer = require('puppeteer-core');
const ffmpeg = require('ffmpeg-static');

const EDGE = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';
const PAGE = 'file:///' + path.join(__dirname, 'places-promo.html').replace(/\\/g, '/');
const DURATION = 15;

(async () => {
  const [mode, a, b, c] = process.argv.slice(2);
  const browser = await puppeteer.launch({
    executablePath: EDGE, headless: true,
    args: ['--allow-file-access-from-files', '--force-color-profile=srgb', '--hide-scrollbars', '--disable-gpu-vsync'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080, deviceScaleFactor: 1 });
  page.on('pageerror', (e) => console.error('page error:', e.message));
  await page.goto(PAGE, { waitUntil: 'load' });
  await page.evaluate(() => window.ready);

  if (mode === 'stills') {
    fs.mkdirSync(b, { recursive: true });
    for (const t of a.split(',').map(Number)) {
      await page.evaluate((t) => window.seek(t), t);
      await page.screenshot({ path: path.join(b, `t${t.toFixed(2)}.png`) });
    }
  } else {
    const fps = Number(b || 60), sub = Number(c || 3), rate = fps * sub;
    const blend = sub > 1 ? `tmix=frames=${sub},` : '';
    const ff = spawn(ffmpeg, ['-y', '-f', 'image2pipe', '-framerate', String(rate), '-i', '-',
      '-vf', `${blend}fps=${fps},format=yuv420p`, '-c:v', 'libx264', '-preset', 'slow', '-crf', '16',
      '-movflags', '+faststart', a], { stdio: ['pipe', 'inherit', 'inherit'] });
    const total = DURATION * rate, start = Date.now();
    for (let i = 0; i < total; i++) {
      // centre the sub-frames on each output frame so the blur is symmetric
      await page.evaluate((t) => window.seek(t), Math.max(0, (i - (sub - 1) / 2) / rate));
      const buf = await page.screenshot({ type: 'jpeg', quality: 95 });
      if (!ff.stdin.write(buf)) await new Promise((r) => ff.stdin.once('drain', r));
      if (i % 60 === 0) console.log(`${i}/${total}  ${((Date.now() - start) / 1000).toFixed(0)}s`);
    }
    ff.stdin.end();
    await new Promise((r) => ff.on('close', r));
  }
  await browser.close();
})();
