// Self-check for parseServerDate. Run: node scripts/reportDates.selfcheck.mjs (Node 22.18+).
// Every assertion is timezone-stable (epoch ms via Date.UTC, or LOCAL calendar getters),
// so it passes regardless of the machine's TZ — the point of the fix.
import assert from 'node:assert/strict';
import { parseServerDate } from '../src/app/(dashboard)/reports/dates.ts';

// Naive server datetime (SQLAlchemy utcnow, no zone) must be read as UTC, not local.
assert.equal(
  parseServerDate('2026-10-20 20:03:28').getTime(),
  Date.UTC(2026, 9, 20, 20, 3, 28),
  'naive datetime not treated as UTC — the "saved 21 Oct shows 20 Oct" bug',
);
// Fractional seconds + a T separator, still naive → UTC.
assert.equal(parseServerDate('2026-10-20T20:03:28.305').getTime(), Date.UTC(2026, 9, 20, 20, 3, 28, 305));

// Pure calendar date → that exact LOCAL day (no UTC-midnight shift).
const d = parseServerDate('2026-10-21');
assert.equal(d.getFullYear(), 2026);
assert.equal(d.getMonth(), 9);   // October
assert.equal(d.getDate(), 21);   // stays the 21st in every timezone

// Already-zoned strings are left exactly as-is.
assert.equal(parseServerDate('2026-10-20T20:03:28Z').getTime(), Date.UTC(2026, 9, 20, 20, 3, 28));
assert.equal(parseServerDate('2026-10-20T20:03:28+05:00').getTime(), Date.UTC(2026, 9, 20, 15, 3, 28));

// Empty / bad input → null (fmtDate renders '-').
assert.equal(parseServerDate(''), null);
assert.equal(parseServerDate(null), null);
assert.equal(parseServerDate('not-a-date'), null);

console.log('reportDates.selfcheck OK');
