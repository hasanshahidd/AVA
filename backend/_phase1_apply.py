import json, os
from collections import Counter
HERE = os.path.dirname(__file__); SEED = os.path.join(HERE, 'grc', 'seed_data')
s3 = json.load(open(os.path.join(SEED, 'stage3_clean.json'), encoding='utf-8'))
broad = [d for d in s3['domains'] if d['domain'].startswith('BROAD')][0]['controls']
real = {d['domain']: list(d['controls']) for d in s3['domains'] if not d['domain'].startswith('BROAD')}
valid = set(real.keys())

# combine the 4 split files
amap = {}
for fn in ['_broad_split_000_146.json', '_broad_split_147_293.json', '_broad_split_294_440.json', '_broad_split_441_584.json']:
    for it in json.load(open(os.path.join(HERE, fn), encoding='utf-8'))['items']:
        amap[it['i']] = it['domain']

# verify coverage + valid domains
miss = [i for i in range(len(broad)) if i not in amap]
badd = sorted({d for d in amap.values() if d not in valid})
print('BROAD controls:', len(broad), '| assigned:', len(amap), '| missing:', miss[:8] if miss else 'none', '| invalid domains:', badd if badd else 'none')

# apply: append each BROAD control to its assigned domain
moved = Counter()
def fwshort(c): return c['framework'].split('(')[0].strip()
for i, c in enumerate(broad):
    dom = amap.get(i)
    if dom in real:
        real[dom].append(c); moved[dom] += 1

# build complete dataset (order = original 20)
order = [d['domain'] for d in s3['domains'] if not d['domain'].startswith('BROAD')]
out = {'domains': [{'domain': n, 'controls': real[n]} for n in order]}
total = sum(len(real[n]) for n in order)
print('total controls after split:', total, '(clean had 3352)')
json.dump(out, open(os.path.join(SEED, 'stage3_complete.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

print()
print('%-42s %5s %5s %6s'%('DOMAIN','ctrls','+BROAD','#fw'))
print('-'*62)
for n in order:
    nfw = len(set(fwshort(c) for c in real[n]))
    print('%-42s %5d %5d %6d'%(n[:42], len(real[n]), moved.get(n,0), nfw))
gov = real['Governance, Leadership & Policy']
print()
print('GOVERNANCE now:', len(gov), 'controls from', len(set(fwshort(c) for c in gov)), 'frameworks')
print('  frameworks:', sorted(set(fwshort(c) for c in gov)))
