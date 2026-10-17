#!/usr/bin/env node
/*
 * Security guard — added after the Oct 2026 postcss supply-chain incident.
 * Aborts `next build` if postcss.config.js is not the clean config. The loader
 * hid an obfuscated require()-based blob appended after the clean stub and
 * SELF-PROPAGATED during the build (phoned home + re-wrote itself). Any build
 * with an infected config re-seeds it, so we refuse to build one.
 */
const fs = require('fs');

const FILE = 'postcss.config.js';
let src = '';
try {
  src = fs.readFileSync(FILE, 'utf8');
} catch (e) {
  console.error('[guard-postcss] cannot read ' + FILE + ': ' + e.message);
  process.exit(1);
}

const infected =
  src.length > 256 ||
  /global\.o\s*=|_\$_\d|_\$jsoPow|fromCharCode\(\s*127\s*\)/.test(src);

if (infected) {
  console.error(
    '\n[guard-postcss] SECURITY: ' + FILE + ' looks INFECTED (' + src.length +
    ' bytes). Build aborted. Restore the clean ~83-byte config and re-run.\n'
  );
  process.exit(1);
}
console.log('[guard-postcss] ' + FILE + ' clean (' + src.length + ' bytes).');
