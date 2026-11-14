// Checks every text/background pairing used by the SkillBridge design system
// against WCAG 2.2 contrast minimums. Run: node design/tools/check-contrast.mjs
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const tokens = JSON.parse(readFileSync(join(here, '..', 'tokens', 'skillbridge.tokens.json'), 'utf8'));

const lum = (hex) => {
  const n = hex.replace('#', '');
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(n.slice(i, i + 2), 16) / 255)
    .map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const ratio = (a, b) => {
  const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
};

// [foreground, background, minimum, purpose]
const pairs = [
  ['text', 'canvas', 4.5, 'body text on page'],
  ['text', 'surface', 4.5, 'body text on card'],
  ['text', 'surfaceSunken', 4.5, 'body text on sunken field'],
  ['textSecondary', 'canvas', 4.5, 'secondary text on page'],
  ['textSecondary', 'surface', 4.5, 'secondary text on card'],
  ['textSecondary', 'surfaceSunken', 4.5, 'secondary text on sunken'],
  ['primary', 'surface', 4.5, 'link / quiet button text'],
  ['primary', 'canvas', 4.5, 'link on page'],
  ['onPrimary', 'primary', 4.5, 'primary button label'],
  ['onPrimary', 'primaryHover', 4.5, 'primary button hover'],
  ['onPrimarySubtle', 'primarySubtle', 4.5, 'selected chip / info badge'],
  ['onAccent', 'accent', 4.5, 'text on amber fill'],
  ['onAccentSubtle', 'accentSubtle', 4.5, 'amber badge'],
  ['success', 'surface', 4.5, 'verified text on card'],
  ['onSuccess', 'success', 4.5, 'success button'],
  ['onSuccessSubtle', 'successSubtle', 4.5, 'verified badge'],
  ['warning', 'surface', 4.5, 'warning text'],
  ['onWarningSubtle', 'warningSubtle', 4.5, 'warning badge'],
  ['error', 'surface', 4.5, 'error text / field error'],
  ['onError', 'error', 4.5, 'destructive button'],
  ['onErrorSubtle', 'errorSubtle', 4.5, 'error badge / banner'],
  ['borderInput', 'surface', 3.0, 'input border (non-text UI)'],
  ['borderInput', 'canvas', 3.0, 'input border on page'],
  ['focusRing', 'surface', 3.0, 'focus ring'],
  ['focusRing', 'canvas', 3.0, 'focus ring on page'],
  ['accent', 'surface', 1.0, 'amber decoration (not text — informational)'],
];

let failures = 0;
for (const mode of ['light', 'dark']) {
  const c = tokens.color[mode];
  console.log(`\n${mode.toUpperCase()}`);
  for (const [fg, bg, min, why] of pairs) {
    const r = ratio(c[fg], c[bg]);
    const ok = r >= min;
    if (!ok) failures++;
    console.log(`${ok ? 'PASS' : 'FAIL'}  ${r.toFixed(2).padStart(5)}:1  (min ${min})  ${fg} on ${bg} — ${why}`);
  }
  for (const [name, v] of Object.entries(tokens.color.category)) {
    if (name.startsWith('$')) continue;
    const [bg, fg] = v[mode];
    const r = ratio(fg, bg);
    const ok = r >= 4.5;
    if (!ok) failures++;
    console.log(`${ok ? 'PASS' : 'FAIL'}  ${r.toFixed(2).padStart(5)}:1  (min 4.5)  category.${name}`);
  }
}
console.log(failures ? `\n${failures} pairing(s) below minimum.` : '\nAll pairings meet WCAG 2.2 AA.');
process.exit(failures ? 1 : 0);
