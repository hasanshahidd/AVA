import json, os, re
from collections import Counter, defaultdict, OrderedDict
HERE = os.path.dirname(os.path.abspath(__file__)); SEED = os.path.join(HERE, 'grc', 'seed_data')
PUB = os.path.join(HERE, '..', 'grc-frontend', 'public'); EV = os.path.join(HERE, '_evfix')
D = json.load(open(os.path.join(SEED, 'stage4_all_domains.json'), encoding='utf-8'))['domains']
s3 = json.load(open(os.path.join(SEED, 'stage3_complete.json'), encoding='utf-8'))
def fwshort(c): return c['framework'].split('(')[0].strip()
def nk(s): return re.sub(r'\s+', ' ', re.sub(r'[^a-z0-9 ]', ' ', (s or '').lower())).strip()

# ---------- raw evidence/source index ----------
rawev = defaultdict(list)
for dm in s3['domains']:
    for c in dm['controls']:
        for e in (c.get('evidence') or []):
            rawev[nk(e['name'])].append((fwshort(c), c['control_id']))

# ---------- broadcast artifact catalogs ----------
fwctrls = Counter(); artfreq = defaultdict(Counter)
for dm in s3['domains']:
    for c in dm['controls']:
        f = fwshort(c); fwctrls[f] += 1
        for a in (c.get('artifacts') or []): artfreq[f][a.get('name')] += 1
broadcast = {}
for f, n in fwctrls.items():
    cat = set(name for name, cnt in artfreq[f].items() if name and cnt >= max(3, 0.4 * n))
    if cat: broadcast[f] = cat
def srcfw(src): return src.rsplit(' ', 1)[0]

# ---------- load flagged input + agent outputs ----------
flagged = json.load(open(os.path.join(EV, 'flagged_input.json'), encoding='utf-8'))
ev_fixes = {}   # (di, set_id) -> out
missing = []; bad_cov = []
for i, f in enumerate(flagged):
    p = os.path.join(EV, 'out_%d.json' % i)
    if not os.path.exists(p): missing.append(i); continue
    out = json.load(open(p, encoding='utf-8'))
    rawnames = Counter(nk(r['name']) for r in f['raw_evidence'])
    covered = Counter()
    for g in out.get('groups', []):
        for a in g.get('absorbs', []): covered[nk(a)] += 1
    for x in out.get('excluded', []): covered[nk(x['name'])] += 1
    if covered != rawnames:
        miss = sorted((rawnames - covered).elements()); extra = sorted((covered - rawnames).elements())
        bad_cov.append((i, f['set_id'], miss[:5], extra[:5]))
    ev_fixes[(f['di'], f['set_id'])] = (f, out)
print('agent outputs: present %d / %d | missing %s' % (len(flagged) - len(missing), len(flagged), missing))
if bad_cov:
    print('COVERAGE MISMATCH in %d sets (will keep old evidence for these):' % len(bad_cov))
    for i, sid, miss, extra in bad_cov[:20]: print('  out_%d %s  missing=%s extra=%s' % (i, sid, miss, extra))
bad_set = {(flagged[i]['di'], sid) for i, sid, _, _ in bad_cov}

# ---------- apply EVIDENCE fixes ----------
ev_applied = 0
def build_sources(absorbed_names, member_keys):
    mk = set(member_keys); src = []
    for an in absorbed_names:
        for (fw, cid) in rawev.get(nk(an), []):
            if (fw, cid) in mk and (fw + ' ' + cid) not in src: src.append(fw + ' ' + cid)
    return src
for di, dm in enumerate(D):
    for s in dm['sets']:
        key = (di, s['set_id'])
        if key not in ev_fixes or key in bad_set: continue
        f, out = ev_fixes[key]
        member_keys = [(m['fw'], m['cid']) for m in f['members']]
        ne = []
        for g in out['groups']:
            ab = g['absorbs']
            ne.append({'name': g['name'], 'absorbs': ab, 'sources': build_sources(ab, member_keys)})
        s['normalized_evidence'] = ne
        s['excluded_evidence'] = [{'name': x['name'], 'reason': x.get('reason', '')} for x in out.get('excluded', [])]
        ev_applied += 1
print('evidence re-merge applied to %d sets' % ev_applied)

# ---------- apply ARTIFACT scoping ----------
art_moved = 0; sets_art = 0
for dm in D:
    fw_cat = defaultdict(list)  # framework -> list of broadcast artifacts (domain-level note)
    for s in dm['sets']:
        kept = []; moved = []
        for a in s.get('normalized_artifacts', []):
            srcs = a.get('sources', [])
            pure = len(srcs) > 0 and all(any(srcfw(x) == bf and a['name'] in broadcast[bf] for bf in broadcast) for x in srcs)
            if pure: moved.append(a)
            else: kept.append(a)
        if moved:
            sets_art += 1; art_moved += len(moved)
            for a in moved:
                for x in a.get('sources', []):
                    bf = srcfw(x)
                    if bf in broadcast and a['name'] in broadcast[bf]:
                        if a['name'] not in [z['name'] for z in fw_cat[bf]]:
                            fw_cat[bf].append({'name': a['name'], 'type': a.get('type')})
                        break
        s['normalized_artifacts'] = kept
    dm['framework_catalog_artifacts'] = [{'framework': k, 'note': 'Framework-level artifact catalog attached to most %s controls at source (not requirement-specific)' % k, 'artifacts': v} for k, v in fw_cat.items()]
print('artifacts: moved %d broadcast items to framework-level notes across %d sets' % (art_moved, sets_art))

# ---------- re-verify invariants ----------
total = sum(s['member_count'] for dm in D for s in dm['sets'])
rule_ok = all(len(set(m['framework'] for m in s['members'])) == s['member_count'] for dm in D for s in dm['sets'])
print('INVARIANT total controls:', total, '(expect 3352) | no-same-framework:', 'OK' if rule_ok else 'FAIL')

# ---------- rewrite outputs ----------
json.dump({'domains': D}, open(os.path.join(SEED, 'stage4_all_domains.json'), 'w', encoding='utf-8'), ensure_ascii=False)
for k, dm in enumerate(D):
    json.dump(dm, open(os.path.join(PUB, 'domain_%02d.json' % k), 'w', encoding='utf-8'), ensure_ascii=False)
summaries = []
for k, dm in enumerate(D):
    multi = [s for s in dm['sets'] if s['member_count'] > 1]; single = [s for s in dm['sets'] if s['member_count'] == 1]
    summaries.append({'name': dm['domain'], 'controls': dm['controls_in'], 'frameworks': len(dm['frameworks']),
                      'normalized_sets': len(multi), 'standalone': len(single), 'status': 'normalized', 'file': 'domain_%02d.json' % k})
json.dump({'domains': summaries, 'total_controls': total}, open(os.path.join(PUB, 'library_data.json'), 'w', encoding='utf-8'), ensure_ascii=False)
print('rewrote stage4_all_domains.json + public/library_data.json + domain_00..19.json')
