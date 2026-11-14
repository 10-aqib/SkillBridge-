// Real-time screenshot capture through the Chrome DevTools Protocol.
// Use for apps that need real time to start (Flutter web + Firebase), where
// `chrome --screenshot` fires too early.
//
// node design/tools/capture-cdp.mjs <url> <out.png> <width> <height> [waitMs] [light|dark]
import { spawn } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const [, , url, out, w = '412', h = '915', waitMs = '20000', scheme = 'light'] = process.argv;
const chrome = process.env.CHROME ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const port = 9300 + Math.floor(Math.random() * 500);
const profile = mkdtempSync(join(tmpdir(), 'sbcap-'));
const proc = spawn(chrome, [
  '--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
  '--hide-scrollbars', '--no-first-run', '--no-default-browser-check', 'about:blank',
], { stdio: 'ignore' });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function target() {
  for (let i = 0; i < 50; i++) {
    try {
      const list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
      const page = list.find((t) => t.type === 'page');
      if (page) return page.webSocketDebuggerUrl;
    } catch { /* not up yet */ }
    await sleep(200);
  }
  throw new Error('Chrome did not start');
}

let id = 0;
const pending = new Map();
const logs = [];
const ws = new WebSocket(await target());
await new Promise((r) => ws.addEventListener('open', r, { once: true }));
ws.addEventListener('message', (e) => {
  const msg = JSON.parse(e.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
  if (msg.method === 'Runtime.exceptionThrown') logs.push('EXCEPTION ' + (msg.params.exceptionDetails.exception?.description ?? msg.params.exceptionDetails.text).slice(0, 400));
  if (msg.method === 'Runtime.consoleAPICalled' && ['error', 'warning'].includes(msg.params.type)) logs.push(msg.params.type.toUpperCase() + ' ' + msg.params.args.map((a) => a.value ?? a.description ?? '').join(' ').slice(0, 400));
});
const send = (method, params = {}) => new Promise((resolve) => {
  const mid = ++id; pending.set(mid, resolve); ws.send(JSON.stringify({ id: mid, method, params }));
});

try {
  await send('Runtime.enable');
  await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: +w, height: +h, deviceScaleFactor: 1, mobile: +w < 768 });
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: scheme }] });
  // HIVE_THEME=light|dark pre-sets the app's persisted theme choice (the value
  // the in-app theme toggle writes to Hive box "app_settings_cache").
  if (process.env.HIVE_THEME) {
    await send('Page.navigate', { url: new URL(url).origin + '/favicon.png' });
    await sleep(800);
    const seed = `new Promise((res, rej) => { const r = indexedDB.open('app_settings_cache', 1);
      r.onupgradeneeded = () => r.result.createObjectStore('box');
      r.onsuccess = () => { const db = r.result; if (!db.objectStoreNames.contains('box')) { res('nostore'); return; }
        const tx = db.transaction('box', 'readwrite'); tx.objectStore('box').put(${JSON.stringify(process.env.HIVE_THEME)}, 'theme_mode');
        tx.oncomplete = () => { db.close(); res('ok'); }; tx.onerror = () => rej(tx.error); };
      r.onerror = () => rej(r.error); })`;
    const res = await send('Runtime.evaluate', { expression: seed, awaitPromise: true });
    console.log('seed theme:', res.result?.result?.value ?? JSON.stringify(res.result));
  }
  await send('Page.navigate', { url });
  await sleep(+waitMs);
  // CLICKS="x,y;x,y" taps those points in order (like a user), 3 s apart.
  for (const pt of (process.env.CLICKS ?? '').split(';').filter(Boolean)) {
    const [x, y] = pt.split(',').map(Number);
    for (const type of ['mousePressed', 'mouseReleased']) {
      await send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
    }
    await sleep(3000);
  }
  const shot = await send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(out, Buffer.from(shot.result.data, 'base64'));
  console.log(`saved ${out}`);
} finally {
  if (logs.length) console.log(logs.slice(0, 12).join('\n'));
  ws.close();
  proc.kill();
  await sleep(500);
  try { rmSync(profile, { recursive: true, force: true }); } catch { /* locked; temp dir */ }
}
