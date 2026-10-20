// Self-check for the asset roll-up helpers. Run: node scripts/domains.selfcheck.mjs (Node 22.18+).
// Guards the invariant behind the inventory count fix: rollupAssets(x) is the LIST
// whose length equals rollupCounts(x).total, so every register filter chip (counted
// over rollupAssets) can never exceed the folded total.
import assert from 'node:assert/strict';
import { rollupAssets, rollupCounts } from '../src/lib/domains.ts';

// 2 internal (flat) + one external apex with 3 subdomains (fold to 1) + another apex.
const fixture = [
  { id: 1, name: 'pc1.local', internet_facing: false },        // internal
  { id: 2, name: 'db.local', internet_facing: false },         // internal
  { id: 3, name: 'example.com', internet_facing: true },       // external apex
  { id: 4, name: 'www.example.com', internet_facing: true },   // sub → folds under example.com
  { id: 5, name: 'api.example.com', internet_facing: true },   // sub → folds
  { id: 6, name: 'mail.example.com', internet_facing: true },  // sub → folds
  { id: 7, name: 'other.org', internet_facing: true },         // another external apex
];

const roll = rollupCounts(fixture);
const logical = rollupAssets(fixture);

// Core invariant: the list form's length is exactly the rolled-up total.
assert.equal(logical.length, roll.total, `length ${logical.length} != total ${roll.total}`);
// 2 internal + 2 external apexes (example.com, other.org) = 4 logical assets.
assert.equal(roll.total, 4);
assert.equal(logical.length, 4);

// THE BUG this fixes: a chip counted over the RAW array (5 internet-facing rows)
// exceeds the folded total (4) — "Internet-facing 5" over "Total 4". Counted over
// the logical set it collapses to 2 and can never exceed the total.
assert.equal(fixture.filter((a) => a.internet_facing).length, 5); // old (raw) count
const internet = logical.filter((a) => a.internet_facing).length;
assert.equal(internet, 2);                                        // new (logical) count
assert.ok(internet <= logical.length, `chip ${internet} exceeds total ${logical.length}`);

// The apex row is the representative, not a subdomain.
assert.ok(logical.some((a) => a.name === 'example.com'), 'apex representative missing');
assert.ok(!logical.some((a) => a.name === 'www.example.com'), 'subdomain leaked as a logical asset');

console.log('domains.selfcheck OK');
