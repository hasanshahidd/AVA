import json, os, re
from collections import Counter, defaultdict
HERE = os.path.dirname(os.path.abspath(__file__)); SEED = os.path.join(HERE, 'grc', 'seed_data')
PUB = os.path.join(HERE, '..', 'grc-frontend', 'public'); EV = os.path.join(HERE, '_evfix2')
D = json.load(open(os.path.join(SEED, 'stage4_all_domains.json'), encoding='utf-8'))['domains']
s3 = json.load(open(os.path.join(SEED, 'stage3_complete.json'), encoding='utf-8'))
def fwshort(c): return c['framework'].split('(')[0].strip()
def nk(s): return re.sub(r'\s+', ' ', re.sub(r'[^a-z0-9 ]', ' ', (s or '').lower())).strip()
def srcfw(x): return x.rsplit(' ', 1)[0]
rawev = defaultdict(list)
for dm in s3['domains']:
    for c in dm['controls']:
        for e in (c.get('evidence') or []): rawev[nk(e['name'])].append((fwshort(c), c['control_id']))

# ---------- EVIDENCE re-merge splice ----------
inp = json.load(open(os.path.join(EV, 'input.json'), encoding='utf-8'))
fixes = {}; missing = []; bad = []
for i, f in enumerate(inp):
    p = os.path.join(EV, 'out_%d.json' % i)
    if not os.path.exists(p): missing.append(i); continue
    out = json.load(open(p, encoding='utf-8'))
    rawnames = Counter(nk(r['name']) for r in f['raw_evidence'])
    cov = Counter()
    for g in out.get('groups', []):
        for a in g.get('absorbs', []): cov[nk(a)] += 1
    for x in out.get('excluded', []): cov[nk(x['name'])] += 1
    if cov != rawnames:
        bad.append((i, f['set_id'])); continue
    fixes[(f['di'], f['set_id'])] = (f, out)
print('evidence outputs present %d/%d | missing %s | coverage-bad %s' % (len(inp) - len(missing), len(inp), missing[:10], [b[1] for b in bad][:10]))
def build_sources(names, mkeys):
    mk = set(mkeys); src = []
    for an in names:
        for (fw, cid) in rawev.get(nk(an), []):
            if (fw, cid) in mk and (fw + ' ' + cid) not in src: src.append(fw + ' ' + cid)
    return src
applied = 0
for di, dm in enumerate(D):
    for s in dm['sets']:
        key = (di, s['set_id'])
        if key not in fixes: continue
        f, out = fixes[key]
        mkeys = [(m['fw'], m['cid']) for m in f['members']]
        s['normalized_evidence'] = [{'name': g['name'], 'absorbs': g['absorbs'], 'sources': build_sources(g['absorbs'], mkeys)} for g in out['groups']]
        s['excluded_evidence'] = [{'name': x['name'], 'reason': x.get('reason', '')} for x in out.get('excluded', [])]
        applied += 1
print('evidence re-merge applied to %d sets' % applied)

# ---------- EXTENDED ARTIFACT lift (live-data broadcast detection) ----------
art_sets = defaultdict(list); art_fw = defaultdict(lambda: defaultdict(int)); art_doms = defaultdict(set)
for dm in D:
    for s in dm['sets']:
        for a in s.get('normalized_artifacts', []):
            nm = a.get('name'); art_sets[nm].append(1); art_doms[nm].add(dm['domain'])
            for x in a.get('sources', []): art_fw[nm][srcfw(x)] += 1
broadcast_dom = {}
for nm in art_sets:
    tot = sum(art_fw[nm].values())
    if tot == 0: continue
    fw, n = max(art_fw[nm].items(), key=lambda x: x[1])
    if len(art_doms[nm]) >= 4 and n / tot >= 0.90 and len(art_sets[nm]) >= 6:
        broadcast_dom[nm] = fw
print('extended broadcast catalogs detected:', len(broadcast_dom))
moved = 0; sets_touched = 0
for dm in D:
    cat = defaultdict(list)
    for c in dm.get('framework_catalog_artifacts', []):  # seed existing
        cat[c['framework']] = list(c.get('artifacts', []))
    for s in dm['sets']:
        kept = []; t = 0
        for a in s.get('normalized_artifacts', []):
            nm = a.get('name'); srcs = a.get('sources', [])
            if nm in broadcast_dom and srcs and all(srcfw(x) == broadcast_dom[nm] for x in srcs):
                fw = broadcast_dom[nm]
                if nm not in [z['name'] for z in cat[fw]]: cat[fw].append({'name': nm, 'type': a.get('type')})
                moved += 1; t += 1
            else: kept.append(a)
        if t: sets_touched += 1
        s['normalized_artifacts'] = kept
    dm['framework_catalog_artifacts'] = [{'framework': k, 'note': 'Framework-level artifact catalog attached to most %s controls at source (not requirement-specific)' % k, 'artifacts': v} for k, v in cat.items() if v]
print('artifacts: moved %d more broadcast items across %d sets' % (moved, sets_touched))

# ---------- verify ----------
total = sum(s['member_count'] for dm in D for s in dm['sets'])
rule = all(len(set(m['framework'] for m in s['members'])) == s['member_count'] for dm in D for s in dm['sets'])
# zero silent drops across ALL sets
rawev_byctrl = defaultdict(list)
for dm in s3['domains']:
    for c in dm['controls']: rawev_byctrl[(fwshort(c), c['control_id'])] = [e['name'] for e in (c.get('evidence') or [])]
silent = 0
for dm in D:
    for s in dm['sets']:
        if s['member_count'] < 2: continue
        ab = set(nk(a) for e in s['normalized_evidence'] for a in e.get('absorbs', []))
        ex = set(nk(x['name']) for x in s.get('excluded_evidence', []))
        for m in s['members']:
            for evn in rawev_byctrl.get((m['framework'], m['control_id']), []):
                if nk(evn) not in ab and nk(evn) not in ex: silent += 1
print('INVARIANT total %d (expect 3352) | no-same-framework %s | silent drops %d' % (total, 'OK' if rule else 'FAIL', silent))

# ---------- write ----------
json.dump({'domains': D}, open(os.path.join(SEED, 'stage4_all_domains.json'), 'w', encoding='utf-8'), ensure_ascii=False)
for k, dm in enumerate(D): json.dump(dm, open(os.path.join(PUB, 'domain_%02d.json' % k), 'w', encoding='utf-8'), ensure_ascii=False)
summaries = []
for k, dm in enumerate(D):
    multi = [s for s in dm['sets'] if s['member_count'] > 1]; single = [s for s in dm['sets'] if s['member_count'] == 1]
    summaries.append({'name': dm['domain'], 'controls': dm['controls_in'], 'frameworks': len(dm['frameworks']), 'normalized_sets': len(multi), 'standalone': len(single), 'status': 'normalized', 'file': 'domain_%02d.json' % k})
json.dump({'domains': summaries, 'total_controls': total}, open(os.path.join(PUB, 'library_data.json'), 'w', encoding='utf-8'), ensure_ascii=False)
print('rewrote stage4 + public files')
