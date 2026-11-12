// Usage: node tool/web_audio_smoke.cjs <path-to-playwright-module>
// Tests the release bundle under a subdirectory, with a real browser audio graph.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const {chromium} = require(process.argv[2] || 'playwright');

(async () => {
  const root = path.resolve(__dirname, '../build/web');
  const failures = [], requestedSounds = [], errors = [];
  const mime = {'.js': 'text/javascript', '.html': 'text/html', '.wasm': 'application/wasm',
    '.json': 'application/json', '.png': 'image/png', '.ogg': 'audio/ogg', '.ttf': 'font/ttf'};
  const server = http.createServer((req, res) => {
    const name = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    const relative = name.replace(/^\/game\//, '');
    const file = path.resolve(root, relative || 'index.html');
    if (!file.startsWith(root + path.sep)) { res.writeHead(403).end(); return; }
    fs.readFile(file, (error, bytes) => {
      if (error) { res.writeHead(404).end(); return; }
      res.setHeader('Content-Type', mime[path.extname(file)] || 'application/octet-stream');
      res.end(bytes);
    });
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  let browser;
  try {
    browser = await chromium.launch({channel: 'msedge', headless: true,
      args: ['--autoplay-policy=user-gesture-required']});
    const page = await browser.newPage({viewport: {width: 1024, height: 640}});
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') console.error('Browser:', message.text()); });
    page.on('response', response => {
      if (response.status() >= 400) failures.push(response.url());
    });
    page.on('request', request => {
      if (/\.(ogg|wav|mp3)(\?|$)/i.test(request.url())) requestedSounds.push(request.url());
    });
    await page.addInitScript(() => {
      let api;
      window.__notes = []; window.__ops = [];
      Object.defineProperty(window, 'KuradiMidi', {
        get: () => api,
        set: original => {
          window.__createSynth = original.createSynth;
          api = {createSynth() {
            const synth = original.createSynth();
            const play = synth.play.bind(synth);
            synth.play = (...args) => { window.__notes.push(args); return play(...args); };
            for (const method of ['setVolume', 'stopEffects', 'stopWalking']) {
              const originalMethod = synth[method].bind(synth);
              synth[method] = (...args) => { window.__ops.push([method, ...args]); return originalMethod(...args); };
            }
            window.__synth = synth;
            return synth;
          }};
        },
      });
    });
    await page.goto(`http://127.0.0.1:${server.address().port}/game/`);
    await page.waitForFunction(() => !!window.__synth);
    assert.equal(await page.evaluate(() => window.__synth.context), null);
    await page.waitForTimeout(1500); // Allow preloaded Flame worlds to mount.
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.__synth.context?.state === 'running');
    await page.waitForTimeout(2300); // Menu logo duration.
    // Menu/Pause both use a 320x200 integer-scaled viewport, centered here.
    const clickMode = () => page.mouse.click(32 + 32 * 3, 20 + 107 * 3, {delay: 100});
    await page.screenshot({path: path.join(root, '../web-audio-menu.png')});
    await clickMode(); // Main Menu: MIDI -> MP3.
    await page.waitForTimeout(100);
    await clickMode(); // Restore MIDI for the first gameplay check.
    await page.waitForTimeout(100);
    await page.keyboard.press('l');
    await page.waitForTimeout(400);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(200);
    await page.keyboard.press('Enter');
    await page.waitForTimeout(500);
    await page.keyboard.down('ArrowRight');
    await page.waitForTimeout(500);
    await page.keyboard.up('ArrowRight');
    await page.keyboard.press('Space');
    await page.waitForTimeout(200);
    await page.keyboard.press('e');
    await page.waitForTimeout(150);
    await page.keyboard.press('p');
    const count = await page.evaluate(() => window.__notes.length);
    assert.ok(count > 0, 'gameplay produced MIDI events');
    assert.equal(await page.evaluate(() => window.__synth.voices.size), 0, 'pause releases notes');
    await page.waitForTimeout(500);
    assert.equal(await page.evaluate(() => window.__notes.length), count, 'pause cancels walking');
    const notes = await page.evaluate(() => window.__notes);
    assert.ok(notes.some(n => n[6]), 'ground movement produces footsteps');
    assert.ok(notes.some(n => n[1] === 80), 'jump produces square-lead phrase');
    assert.ok(notes.some(n => n[1] === 81), 'attack produces saw-lead phrase');
    assert.ok(requestedSounds.every(url => /alien_retro_(logo_mfx|intro)\.ogg/.test(url)),
      'MIDI mode requests music recordings only');
    await clickMode(); // Pause: MIDI -> MP3.
    await page.waitForTimeout(150);
    await page.screenshot({path: path.join(root, '../web-audio-mp3.png')});
    await page.keyboard.press('p');
    await page.keyboard.down('ArrowLeft');
    await page.waitForTimeout(650);
    await page.keyboard.up('ArrowLeft');
    await page.keyboard.press('e');
    await page.waitForTimeout(200);
    await page.keyboard.press('p');
    assert.equal(await page.evaluate(() => window.__notes.length), count,
      'MP3 gameplay produces no MIDI notes');
    assert.ok(requestedSounds.some(url => /sfx_kurat_jaan_walk|blockHit1/.test(url)),
      'visible MP3 selector enables original recorded effects');
    await clickMode(); // Pause: MP3 -> MIDI.
    await page.waitForTimeout(150);
    assert.equal(await page.evaluate(() => window.__synth.voices.size), 0,
      'switching while paused remains silent');
    await page.screenshot({path: path.join(root, '../web-audio-smoke.png')});
    await page.keyboard.press('p');
    await page.keyboard.down('ArrowLeft');
    await page.waitForTimeout(600);
    await page.keyboard.up('ArrowLeft');
    await page.keyboard.press('Space');
    await page.waitForTimeout(100);
    assert.ok(await page.evaluate(() => window.__notes.length) > count,
      `switching back restores MIDI gameplay effects; errors=${JSON.stringify(errors)}; operations=${JSON.stringify(await page.evaluate(() => window.__ops))}`);
    await page.keyboard.press('p');

    // Render each supported patch through real Web Audio and verify a finite,
    // nonzero waveform followed by silence after its scheduled note-off.
    const rendered = await page.evaluate(async () => {
      const NativeContext = window.AudioContext;
      const results = [];
      try {
        for (const [channel, program, note] of [[0,80,60], [0,81,55], [9,0,36], [9,0,38], [9,0,76]]) {
          const offline = new OfflineAudioContext(1, 24000, 48000);
          window.AudioContext = function () {
            return new Proxy(offline, {get(target, key) {
              if (key === 'state') return 'running';
              if (key === 'close') return () => Promise.resolve();
              const value = Reflect.get(target, key, target);
              return typeof value === 'function' ? value.bind(target) : value;
            }});
          };
          const synth = window.__createSynth();
          synth.unlock();
          synth.play(channel, program, note, 90, .1, .02, false);
          const buffer = await offline.startRendering();
          const samples = buffer.getChannelData(0);
          let energy = 0, tail = 0;
          for (let i = 0; i < samples.length; i++) {
            if (!Number.isFinite(samples[i])) throw Error('Non-finite audio sample');
            energy += samples[i] * samples[i];
            if (i > 9600) tail += Math.abs(samples[i]);
          }
          results.push({channel, program, note, energy, tail});
          synth.dispose();
        }
      } finally { window.AudioContext = NativeContext; }
      return results;
    });
    assert.ok(rendered.every(r => r.energy > 1 && r.tail === 0), 'patches sound and release to silence');
    assert.deepEqual(errors, []);
    assert.deepEqual(failures, []);
    assert.ok(requestedSounds.some(url => url.includes('alien_retro_logo_mfx')));
    assert.ok(requestedSounds.some(url => url.includes('alien_retro_intro')));
    console.log(JSON.stringify({result: 'PASS', midiEvents: count,
      recordedAudioRequests: requestedSounds.length, patchesRendered: rendered.length,
      modeSwitches: 4,
      browserErrors: errors.length, failedRequests: failures.length}, null, 2));
  } finally {
    if (browser) await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
