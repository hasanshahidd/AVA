import json, os, glob
from collections import defaultdict, Counter
HERE = os.path.dirname(os.path.abspath(__file__)); BK = os.path.dirname(HERE)
SEED = os.path.join(BK, 'grc', 'seed_data'); PUB = os.path.join(BK, '..', 'grc-frontend', 'public')
SAMA = 'SAMA Cyber Security Framework'
miss = json.load(open(os.path.join(HERE, 'missing_67.json'), encoding='utf-8'))
cls = {c['i']: c for c in json.load(open(os.path.join(HERE, 'classified.json'), encoding='utf-8'))}
match = {}
import re as _re
for f in glob.glob(os.path.join(HERE, 'match_*.json')):
    if not _re.search(r'match_\d+\.json$', f): continue  # skip match_input.json
    for m in json.load(open(f, encoding='utf-8')): match[m['i']] = m
assert len(match) == 67, 'match decisions: %d (need 67)' % len(match)
S4 = json.load(open(os.path.join(SEED, 'stage4_all_domains.json'), encoding='utf-8'))['domains']
S3 = json.load(open(os.path.join(SEED, 'stage3_complete.json'), encoding='utf-8'))
def sf(f): return f.split('(')[0].strip()
dom_by_name = {d['domain']: d for d in S4}
s3_by_name = {d['domain']: d for d in S3['domains']}

joined = 0; standalone = 0; forced_standalone = 0
for i, c in enumerate(miss):
    dname = cls[i]['domain']; dm = dom_by_name[dname]
    ctrl = {'framework': SAMA, 'control_id': str(c['control_id']), 'original_title': c['title'], 'reference': ''}
    dec = match[i]
    target = None
    if dec.get('decision') == 'join' and dec.get('set_id'):
        target = next((s for s in dm['sets'] if s['set_id'] == dec['set_id'] and s['member_count'] > 1), None)
        if target and any(sf(m['framework']) == SAMA for m in target['members']):
            target = None; forced_standalone += 1  # set already has a SAMA member -> standalone
    if target:
        target['members'].append(ctrl)
        target['member_count'] = len(target['members'])
        target['frameworks'] = sorted(set(sf(m['framework']) for m in target['members']))
        joined += 1
    else:
        dm['sets'].append({'set_id': 'TMP', 'normalized_title': c['title'], 'member_count': 1,
                           'frameworks': [SAMA], 'members': [ctrl], 'normalized_evidence': [], 'normalized_artifacts': []})
        standalone += 1
    # add to stage3 under same domain
    s3d = s3_by_name[dname]
    s3d['controls'].append({'framework': SAMA, 'control_id': str(c['control_id']), 'title': c['title'],
                            'description': c.get('description', ''), 'evidence': [], 'artifacts': []})
print('joined into existing sets: %d | standalone: %d (of which forced by same-fw guard: %d)' % (joined, standalone, forced_standalone))

# renumber set ids per domain + recompute stats + absent frameworks
ALL30 = sorted(set(sf(m['framework']) for dm in S4 for s in dm['sets'] for m in s['members']))
for dm in S4:
    dm['sets'].sort(key=lambda s: -s['member_count'])
    for j, s in enumerate(dm['sets'], 1):
        s['set_id'] = ('S%03d' % j) if s['member_count'] > 1 else ('U%03d' % j)
    multi = [s for s in dm['sets'] if s['member_count'] > 1]; single = [s for s in dm['sets'] if s['member_count'] == 1]
    dm['controls_in'] = sum(s['member_count'] for s in dm['sets'])
    dm['normalized_sets'] = len(multi); dm['standalone'] = len(single)
    present = sorted(set(s_f for s in dm['sets'] for s_f in s['frameworks']))
    dm['frameworks'] = present
    prev = {a['name']: a.get('reason', '') for a in dm.get('absent_frameworks', [])}
    dm['absent_frameworks'] = [{'name': f, 'reason': prev.get(f, 'No controls of this type from this framework.')} for f in ALL30 if f not in present]

# ---- verify ----
total = sum(s['member_count'] for dm in S4 for s in dm['sets'])
rule = all(len(set(sf(m['framework']) for m in s['members'])) == s['member_count'] for dm in S4 for s in dm['sets'])
sama4 = sum(1 for dm in S4 for s in dm['sets'] for m in s['members'] if sf(m['framework']) == SAMA)
sama3 = sum(1 for d in S3['domains'] for c in d['controls'] if sf(c['framework']) == SAMA)
s3tot = sum(len(d['controls']) for d in S3['domains'])
uid = Counter((sf(m['framework']), m['control_id'], m['original_title']) for dm in S4 for s in dm['sets'] for m in s['members'])
print('stage4 total: %d (expect 3419) | no-same-framework: %s' % (total, 'OK' if rule else 'FAIL'))
print('SAMA in stage4: %d | SAMA in stage3: %d (expect 170) | stage3 total: %d (expect 3419)' % (sama4, sama3, s3tot))
print('UID collisions (true dup identity): %d' % sum(1 for v in uid.values() if v > 1))

if total == 3419 and rule and sama4 == 170 and s3tot == 3419:
    json.dump({'domains': S4}, open(os.path.join(SEED, 'stage4_all_domains.json'), 'w', encoding='utf-8'), ensure_ascii=False)
    json.dump(S3, open(os.path.join(SEED, 'stage3_complete.json'), 'w', encoding='utf-8'), ensure_ascii=False)
    for k, dm in enumerate(S4): json.dump(dm, open(os.path.join(PUB, 'domain_%02d.json' % k), 'w', encoding='utf-8'), ensure_ascii=False)
    summaries = [{'name': dm['domain'], 'controls': dm['controls_in'], 'frameworks': len(dm['frameworks']),
                  'normalized_sets': dm['normalized_sets'], 'standalone': dm['standalone'], 'status': 'normalized', 'file': 'domain_%02d.json' % k} for k, dm in enumerate(S4)]
    json.dump({'domains': summaries, 'total_controls': total}, open(os.path.join(PUB, 'library_data.json'), 'w', encoding='utf-8'), ensure_ascii=False)
    print('SAVED stage4 + stage3 + public (now 3419)')
else:
    print('VERIFY FAILED -> NOT saved')
