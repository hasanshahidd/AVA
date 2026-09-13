import json, os, re
from collections import OrderedDict, defaultdict, Counter
HERE = os.path.dirname(__file__); SEED = os.path.join(HERE, 'grc', 'seed_data')
s3 = json.load(open(os.path.join(SEED, 'stage3_controls_by_domain.json'), encoding='utf-8'))

def fwshort(c): return c['framework'].split('(')[0].strip()
def nk(s): return re.sub(r'\s+', ' ', re.sub(r'[^a-z0-9 ]', ' ', (s or '').lower())).strip()

collapsed_report = Counter()
out_domains = []
before = after = 0
for dom in s3['domains']:
    groups = OrderedDict()  # (framework, control_id) -> [controls]
    for c in dom['controls']:
        before += 1
        groups.setdefault((c['framework'], c['control_id']), []).append(c)
    clean = []
    for (fw, cid), members in groups.items():
        if len(members) == 1:
            clean.append(members[0]); continue
        # collapse: junk duplicate clause (same framework + control_id within one domain)
        collapsed_report[fwshort(members[0])] += len(members) - 1
        ev = OrderedDict()
        for m in members:
            for e in (m.get('evidence') or []):
                k = nk(e.get('name'))
                if k and k not in ev: ev[k] = e
        art = OrderedDict()
        for m in members:
            for a in (m.get('artifacts') or []):
                k = (nk(a.get('name')), (a.get('type') or '').lower())
                if k[0] and k not in art: art[k] = a
        base = dict(members[0])
        base['evidence'] = list(ev.values()); base['artifacts'] = list(art.values())
        base['collapsed_variants'] = [m['title'] for m in members]
        base['collapsed_count'] = len(members)
        clean.append(base)
    after += len(clean)
    out_domains.append({'domain': dom['domain'], 'controls': clean})

json.dump({'domains': out_domains}, open(os.path.join(SEED, 'stage3_clean.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('Phase 0 dedup complete')
print('  controls before:', before, ' -> after:', after, ' (collapsed', before - after, 'junk duplicate rows)')
print('  collapsed by framework:')
for fw, n in collapsed_report.most_common(): print('     -%-3d  %s' % (n, fw))
print()
print('  per-domain after dedup:')
for d in out_domains:
    diff = ''
    orig = next(x for x in s3['domains'] if x['domain'] == d['domain'])
    if len(orig['controls']) != len(d['controls']): diff = '   (was %d, -%d)' % (len(orig['controls']), len(orig['controls']) - len(d['controls']))
    print('     %-42s %4d%s' % (d['domain'][:42], len(d['controls']), diff))
