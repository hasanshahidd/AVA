// Self-check for the report-preview KPI helpers. Run: node scripts/reportInsights.selfcheck.mjs (Node 22.18+).
import assert from 'node:assert/strict';
import { breakdownColumns, buildKpis, sliceName, topSlices } from '../src/app/(dashboard)/reports/reportInsights.ts';

const kv = (m) => Object.entries(m).map(([name, value]) => ({ name, value }));
const byLabel = (kpis) => Object.fromEntries(kpis.map((k) => [k.label, k.value]));

const vuln = byLabel(buildKpis('vulnerabilities', 1200, {
  severity: kv({ Critical: 4, High: 10, Medium: 1000, Low: 186 }),
  kev_flag: kv({ Yes: 3, No: 1197 }),
}, []));
assert.deepEqual(vuln, { 'Total findings': '1,200', Critical: '4', High: '10', 'Medium / Low': '1,186', 'Known exploited (KEV)': '3' });

const cis = byLabel(buildKpis('cis_results', 10, { status: kv({ passed: 6, failed: 2, error: 2 }) }, []));
assert.equal(cis['Pass rate'], '75%');
assert.equal(byLabel(buildKpis('cis_results', 0, { status: [] }, []))['Pass rate'], '—');

// External = internet-facing (Yes); origin_source is not groupable server-side. PCI = cde Yes.
const assets = byLabel(buildKpis('assets', 10, { internet_facing: kv({ Yes: 7, No: 3 }), cde_environment: kv({ Yes: 2, No: 8 }) }, []));
assert.deepEqual([assets.External, assets.Internal, assets['PCI scope']], ['7', '3', '2']);

const gen = buildKpis('helpdesk_tickets', 9, { s: kv({ Open: 5, Closed: 3, Hold: 1 }) }, ['s'], 'tickets');
assert.deepEqual(gen.map((k) => k.label), ['Total tickets', 'Open', 'Closed', 'Hold']);

assert.deepEqual(breakdownColumns('vulnerabilities', { severity: 'badge', status: 'badge' }), ['severity', 'status']);
// Curated first, then every remaining badge column (dense grid) — capped at 6.
assert.deepEqual(breakdownColumns('risks', { a: 'text', b: 'badge', c: 'badge', d: 'badge' }), ['b', 'c', 'd']);
assert.deepEqual(
  breakdownColumns('x', { a: 'badge', b: 'badge', c: 'badge', d: 'badge', e: 'badge', f: 'badge', g: 'badge' }).length,
  6,
);
assert.deepEqual([sliceName(null), sliceName(true), sliceName('x')], ['Unknown', 'Yes', 'x']);
const many = topSlices(kv({ a: 5, b: 4, c: 3, d: 2, e: 1 }), 3);
assert.deepEqual(many, [{ name: 'a', value: 5 }, { name: 'b', value: 4 }, { name: 'Other', value: 6 }]);
console.log('reportInsights self-check OK');
