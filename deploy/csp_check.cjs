// Checks a Flutter web build against the CSP in deploy/nginx.conf.
//
//   flutter build web --release -t lib/main_admin.dart --no-web-resources-cdn
//   NODE_PATH=$(npm root -g) node deploy/csp_check.cjs build/web deploy/nginx.conf
//
// Copies the build to a temp dir, injects the policy as a <meta> tag (so
// frame-ancestors is dropped), serves it on 127.0.0.1:5173, loads it in
// headless Chromium (needs the `playwright` package) and prints every
// "violates the following Content Security Policy" error plus the sha256 of
// every inline <script> on the page - paste new hashes into nginx.conf after
// editing web/index.html or upgrading the firebase_* plugins. Without network
// access, Firebase/font requests fail; only CSP errors matter here.
const fs = require('fs'), http = require('http'), os = require('os'), path = require('path');
const { chromium } = require('playwright');

const [build, confPath] = process.argv.slice(2);
if (!build || !confPath) {
  console.error('usage: node csp_check.cjs <build/web> <nginx.conf>');
  process.exit(2);
}
const csp = fs.readFileSync(confPath, 'utf8').match(/default "(default-src[^"]+)"/)[1]
  .replace(/;\s*frame-ancestors[^;]*/, '');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'csp-check-'));
fs.cpSync(build, root, { recursive: true });
const idx = path.join(root, 'index.html');
fs.writeFileSync(idx, fs.readFileSync(idx, 'utf8').replace('<meta charset="UTF-8">',
  `<meta charset="UTF-8">\n  <meta http-equiv="Content-Security-Policy" content="${csp}">`));

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.wasm': 'application/wasm', '.json': 'application/json', '.png': 'image/png' };
const server = http.createServer((req, res) => {
  let p = path.join(root, decodeURIComponent(req.url.split('?')[0]));
  if (!p.startsWith(root) || !fs.existsSync(p) || fs.statSync(p).isDirectory()) p = idx;
  res.writeHead(200, { 'Content-Type': types[path.extname(p)] || 'application/octet-stream' });
  fs.createReadStream(p).pipe(res);
}).listen(5173, '127.0.0.1', async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const violations = [];
  page.on('console', (m) => {
    if (/Content Security Policy|Refused to/i.test(m.text())) violations.push(m.text());
  });
  await page.goto('http://127.0.0.1:5173/', { waitUntil: 'load' });
  await page.waitForTimeout(15000);
  const inline = await page.evaluate(() => Promise.all([...document.querySelectorAll('script:not([src])')]
    .map(async (s) => {
      const d = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s.textContent));
      const h = btoa(String.fromCharCode(...new Uint8Array(d)));
      return `'sha256-${h}'  ${s.textContent.trim().slice(0, 70).replace(/\s+/g, ' ')}`;
    })));
  await browser.close();
  server.close();
  fs.rmSync(root, { recursive: true, force: true });
  console.log('Inline scripts on the page:');
  inline.forEach((l) => console.log('  ' + l));
  console.log(`CSP violations: ${violations.length}`);
  violations.forEach((v) => console.log('  ' + v));
  process.exit(violations.length ? 1 : 0);
});
