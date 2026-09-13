import json, os, re
from collections import OrderedDict, Counter
HERE = os.path.dirname(__file__); SEED = os.path.join(HERE, 'grc', 'seed_data'); ND = os.path.join(HERE, '_norm')
PUB = os.path.join(HERE, '..', 'grc-frontend', 'public')
s3 = json.load(open(os.path.join(SEED, 'stage3_complete.json'), encoding='utf-8'))
allc = [c for dom in s3['domains'] for c in dom['controls']]
order = [d['domain'] for d in s3['domains']]
def fwshort(c): return c['framework'].split('(')[0].strip()
def nk(s): return re.sub(r'\s+', ' ', re.sub(r'[^a-z0-9 ]', ' ', (s or '').lower())).strip()
def own_ev(i):
    g = OrderedDict()
    for e in (allc[i].get('evidence') or []):
        k = nk(e['name'])
        if k and k not in g: g[k] = {'name': e['name'], 'absorbs': [e['name']], 'sources': [fwshort(allc[i]) + ' ' + allc[i]['control_id']]}
    return list(g.values())
def arts(idxs):
    g = OrderedDict()
    for i in idxs:
        for a in (allc[i].get('artifacts') or []):
            k = (nk(a.get('name')), (a.get('type') or '').lower())
            if not k[0]: continue
            if k not in g: g[k] = {'name': a.get('name'), 'type': a.get('type'), 'sources': set()}
            g[k]['sources'].add(fwshort(allc[i]) + ' ' + allc[i]['control_id'])
    return [{'name': v['name'], 'type': v['type'], 'sources': sorted(v['sources'])} for v in g.values()]

all_domains = []; summaries = []; grand_ctrl = 0
for k in range(20):
    ref = json.load(open(os.path.join(ND, 'dom_%02d_refined.json' % k), encoding='utf-8'))
    domn = ref['domain']; absent = ref.get('absent_frameworks', [])
    ev = {s['set_id']: s['normalized_evidence'] for s in json.load(open(os.path.join(ND, 'dom_%02d_ev.json' % k), encoding='utf-8'))['sets']}
    acc = json.load(open(os.path.join(ND, 'dom_%02d_acc.json' % k), encoding='utf-8'))
    loose = {(x['set_id'], x['fw'], x['cid']) for x in acc.get('loose', [])}
    offt = {}
    for x in acc.get('offtopic', []): offt.setdefault(x['set_id'], set()).add(nk(x['evidence_name']))
    out_sets = []
    for s in ref['sets']:
        sid = s['set_id']; idxs = s['members']
        keep = [i for i in idxs if (sid, fwshort(allc[i]), allc[i]['control_id']) not in loose]
        split = [i for i in idxs if i not in keep]
        if len(keep) >= 2:
            ne = ev.get(sid, []) if len(idxs) > 1 else own_ev(keep[0])
            ne = [e for e in ne if nk(e['name']) not in offt.get(sid, set())]
            out_sets.append((keep, s['normalized_title'], ne))
        elif len(keep) == 1:
            split = keep + split  # collapse to standalone
        for i in split:
            out_sets.append(([i], allc[i]['title'], own_ev(i)))
    # build records
    recs = []
    for idxs, title, ne in out_sets:
        recs.append({'normalized_title': title, 'member_count': len(idxs),
                     'frameworks': sorted(set(fwshort(allc[i]) for i in idxs)),
                     'members': [{'framework': fwshort(allc[i]), 'control_id': allc[i]['control_id'], 'original_title': allc[i]['title'], 'reference': allc[i].get('reference', '')} for i in idxs],
                     'normalized_evidence': ne, 'normalized_artifacts': arts(idxs)})
    # verify
    cov = sum(r['member_count'] for r in recs)
    rule = all(len(set(m['framework'] for m in r['members'])) == r['member_count'] for r in recs)
    multi = [r for r in recs if r['member_count'] > 1]; single = [r for r in recs if r['member_count'] == 1]
    recs.sort(key=lambda r: -r['member_count'])
    for j, r in enumerate(recs, 1): r['set_id'] = ('S%03d' % j) if r['member_count'] > 1 else ('U%03d' % j)
    grand_ctrl += cov
    fws = sorted(set(f for r in recs for f in r['frameworks']))
    domdata = {'domain': domn, 'controls_in': cov, 'normalized_sets': len(multi), 'standalone': len(single),
               'frameworks': fws, 'absent_frameworks': absent, 'cov_ok': cov == len(json.load(open(os.path.join(ND, 'dom_%02d.json' % k), encoding='utf-8'))['controls']), 'rule_ok': rule, 'sets': recs}
    all_domains.append(domdata)
    json.dump(domdata, open(os.path.join(PUB, 'domain_%02d.json' % k), 'w', encoding='utf-8'), ensure_ascii=False)
    summaries.append({'name': domn, 'controls': cov, 'frameworks': len(fws), 'normalized_sets': len(multi), 'standalone': len(single), 'status': 'normalized', 'file': 'domain_%02d.json' % k})

bad = [(d['domain'], d['cov_ok'], d['rule_ok']) for d in all_domains if not d['cov_ok'] or not d['rule_ok']]
print('grand total controls across 20 domains:', grand_ctrl, '(expect 3352)')
print('invariant check (coverage + no-same-framework):', 'ALL OK' if not bad else bad)
print('totals: %d normalized sets + %d standalone' % (sum(d['normalized_sets'] for d in all_domains), sum(d['standalone'] for d in all_domains)))
json.dump({'domains': all_domains}, open(os.path.join(SEED, 'stage4_all_domains.json'), 'w', encoding='utf-8'), ensure_ascii=False)
json.dump({'domains': summaries, 'total_controls': grand_ctrl}, open(os.path.join(PUB, 'library_data.json'), 'w', encoding='utf-8'), ensure_ascii=False)
print('wrote: stage4_all_domains.json + public/library_data.json + public/domain_00..19.json')
print()
print('%-40s %5s %5s %6s %3s'%('DOMAIN','sets','stand','#fw','abs'))
for d in all_domains:
    print('%-40s %5d %6d %5d %3d'%(d['domain'][:40], d['normalized_sets'], d['standalone'], len(d['frameworks']), len(d['absent_frameworks'])))
