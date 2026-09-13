import json, glob, os
from collections import Counter
import openpyxl
from openpyxl.styles import Font, PatternFill, Border, Side, Alignment

FW_DIR = os.path.join(os.path.dirname(__file__), 'grc', 'seed_data', 'frameworks')
slot_count = 0
name_fw = Counter()
for fn in sorted(glob.glob(os.path.join(FW_DIR, '*.json'))):
    d = json.load(open(fn, encoding='utf-8'))
    cats = set((c.get('domain') or '').strip() for c in (d.get('controls') or []))
    cats.discard('')
    slot_count += len(cats)
    for cat in cats:
        name_fw[cat] += 1
distinct = set(name_fw)

MASTER = {
 '01 Governance, Leadership & Policy': ['Governance', 'GOVERN (Function)', 'Leadership', 'Internal Organization', 'Context of the Organization', 'Organization of Information Security', 'Organization of Information Security Management', 'Information Security Management Program', 'Information Security Policy', 'Security Policy', 'AI Policy', 'AI Lifecycle', 'Use of AI Systems', 'Align, Plan and Organize', 'Evaluate, Direct and Monitor', 'Planning', 'Support', 'Improvement', 'Manage and Oversee', 'Cyber security within the organization', 'Procedural Roles and Responsibilities', 'Implementation - Roles and Responsibilities', 'Universal Stakeholder Participation', 'Information for Interested Parties', 'Entity-Level Controls', 'Program Management', 'Information Systems Acceptable Use', 'Organizational Requirements', 'Resources for AI Systems'],
 '02 Risk Management': ['Risk', 'Risk Management', 'Risk Assessment', 'ICT Risk Management', 'Cyber security in the Risk department', 'Impact Assessment', 'MAP (Function)', 'MEASURE (Function)', 'MANAGE (Function)'],
 '03 Compliance & Legal': ['Compliance', 'Compliance with QCB circular', 'Cyber security in the Legal and Compliance department', 'Remedies, Liability and Penalties', 'Freedom of Information', 'Financial Close Controls'],
 '04 Audit & Assurance': ['Audit', 'Monitor, Evaluate and Assess', 'Assessment, Authorization, and Monitoring', 'Performance Evaluation', 'Implementation - Monitoring and Evaluation'],
 '05 Access Control & Identity': ['Access', 'Access Control', 'Access Control Management', 'Access to Programs and Data', 'Account Management', 'Authentication', 'Identification and Authentication', 'Identity Management', 'Know and Limit Access', 'Segregation of Duties'],
 '06 Data Protection & Privacy': ['Data', 'Data Protection', 'Data Management', 'Data Governance', 'Data Classification', 'Data Quality', 'Data Operations', 'Data Catalog and Metadata', 'Data Architecture and Modeling', 'Data Security and Protection', 'Data Sharing and Interoperability', 'Data Transfer', 'Data Value Realization', 'Reference and Master Data Management', 'Document and Content Management', 'Business Intelligence and Analytics', 'Open Data', 'Personal Data Protection', 'Privacy', 'Privacy Practices', 'Privacy Rule', 'Principles', 'Controller and Processor', 'Rights of Data Subjects', 'Transfers of Personal Data', 'Confidentiality', 'PII Processing and Transparency', 'Processing Integrity', 'Health Information and Security', 'Universal Patient Participation'],
 '07 Cryptography': ['Cryptography'],
 '08 Network & Communications Security': ['Network', 'Network Security', 'Network Infrastructure Management', 'Network Monitoring and Defense', 'Communications', 'Communications Security', 'Internet and E-mail Security', 'Email and Web Browser Protections', 'Malware Defenses', 'Malware Protection', 'Secure your Environment', 'System and Communications Protection'],
 '09 Application & Software Security': ['Application Security', 'Application Software Security', 'Business applications', 'Program Development / SDLC', 'Systems Acquisition, Development and Maintenance', 'Information Systems Acquisition, Development, and Maintenance', 'System and Services Acquisition', 'Penetration Testing', 'Security Testing'],
 '10 Configuration & Change Management': ['Change Management', 'Program Changes / Change Management', 'Configuration Management', 'Secure Configuration of Enterprise Assets and Software', 'Build, Acquire and Implement'],
 '11 Asset Management': ['Asset', 'Asset Management', 'Information Asset Management', 'Inventory and Control of Enterprise Assets', 'Inventory and Control of Software Assets', 'Media Protection'],
 '12 Logging, Monitoring & Detection': ['Logging and Monitoring', 'Monitoring', 'Audit Log Management', 'Audit and Accountability', 'Detect', 'Detect and Respond', 'System and Information Integrity'],
 '13 Incident Management': ['Incident', 'Incident Management', 'Incident Reporting', 'Incident Response', 'Incident Response Management', 'ICT Incident Management', 'Information Security Incident Management', 'Breach Notification', 'Respond', 'Fraud', 'Implementation - Escalation and Enforcement', 'Share and Prepare'],
 '14 Business Continuity & Resilience': ['BCP', 'Business Continuity', 'Business Continuity Management', 'Business continuity management', 'Information Systems Continuity Management', 'Contingency Planning', 'Data Recovery', 'Recover', 'Digital Operational Resilience Testing', 'Availability'],
 '15 Physical & Environmental Security': ['Physical', 'Physical Controls', 'Physical Safeguards', 'Physical Security', 'Physical and Environmental Protection', 'Physical and Environmental Security'],
 '16 Human Resources Security': ['HR', 'Human Resource Security', 'Human Resources Security', 'Human Security', 'People Controls', 'Personnel Security', 'Cyber security in the Human Resources (HR) department'],
 '17 Awareness & Training': ['Awareness and Training', 'Security Awareness and Skills Training'],
 '18 Third-Party / Supply Chain': ['Vendor', 'Third Parties', 'Third Party Security', 'Third-Party Management', 'Supply Chain', 'Supply Chain Risk Management', 'ICT Third-Party Risk Management', 'Service Provider Management', 'Cloud', 'Cyber security in the Procurement department', 'Customer'],
 '19 Vulnerability & Threat Management': ['Vulnerability Management', 'Continuous Vulnerability Management', 'Information Sharing'],
 '20 Operations & IT Service Management': ['Operations', 'Operational', 'Operations Management', 'Operations Security', 'Operation', 'Computer Operations', 'IT operations', 'Communications and Operations Management', 'Deliver, Service and Support', 'Maintenance', 'End-User Computing'],
 '21 BROAD - must be split in Stage 3': ['Security', 'Enterprise security', 'Systems Security', 'Protect', 'Identify', 'Technical Safeguards', 'Technological Controls', 'Organizational Controls', 'Administrative Safeguards'],
}

mapped = [n for lst in MASTER.values() for n in lst]
missing = sorted(distinct - set(mapped))
assert not missing, ('UNMAPPED: ' + str(missing))
n_master = sum(1 for k in MASTER if not k.startswith('21'))
n_broad = len(MASTER['21 BROAD - must be split in Stage 3'])

LOGIC = [
 "HOW 306 BECOMES 20 - ONE single merge:",
 "",
 "306 = every category from all 30 frameworks, added up (each framework has 4-20 categories).",
 "      306 is FULL of repeats and look-alikes: 'Governance' appears in 11 frameworks,",
 "      'Access Control' in 8, 'Risk' in 7, 'Incident' in 6, and so on.",
 "",
 "20  = master domains. We do ONE merge - group every category that is the SAME thing:",
 "        - SAME NAME across frameworks  (e.g. 'Governance' x 11 frameworks), AND",
 "        - SAME MEANING in different words (e.g. 'Governance' = 'Leadership' = 'GOVERN' =",
 "          'Internal Organization').",
 "      Name-match and context-match are the SAME action: 'same topic -> one box.'",
 "      (No in-between step - matching by name and by meaning happen together, in one pass.)",
 "",
 "WHY it drops so far (306 -> 20): because 30 frameworks all describe the SAME ~20 security",
 "      topics over and over, each in their own words. Merge the repeats + the synonyms",
 "      together in one go, and 306 entries fold into ~20 real domains.",
 "",
 "9 BROAD categories (Security, Enterprise security, Systems Security, Protect, Identify,",
 "      Technical/Technological/Organizational Controls, Administrative Safeguards) are too",
 "      broad to drop in one box (one label hides many topics) - they get SPLIT by their",
 "      controls in Stage 3, not merged here.",
 "",
 "FUNNEL (one merge):   306 category-entries  ->  20 master domains  (+9 broad to split)",
]

# ---------- JSON (for system) ----------
master_json = []
for mc in sorted(MASTER):
    real = [n for n in MASTER[mc] if n in distinct]
    master_json.append({
        'id': mc[:2], 'name': mc[3:],
        'category_slots_merged': sum(name_fw[n] for n in real),
        'distinct_category_names': len(real),
        'is_broad_bucket': mc.startswith('21'),
        'merged_from': [{'name': n, 'frameworks_using_it': name_fw[n]} for n in real],
    })
out_json = {
    'stage': 2,
    'title': 'Stage 2 - Master categories merged from framework categories',
    'logic': LOGIC,
    'counts': {
        'category_slots_with_repeats': slot_count,
        'distinct_category_names': len(distinct),
        'master_categories': n_master,
        'broad_to_split_in_stage3': n_broad,
        'frameworks': 30, 'controls': 3419,
    },
    'reconciliation': '306 slots (each framework counted) -> 200 distinct names (dedup spelling) -> 20 master categories (merge by meaning) + 9 broad to split',
    'master_categories': master_json,
}
jpath = os.path.join(os.path.dirname(__file__), 'grc', 'seed_data', 'stage2_master_categories.json')
json.dump(out_json, open(jpath, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

# ---------- Excel (for human) ----------
wb = openpyxl.Workbook()
hd = Font(bold=True, color='FFFFFF'); fill = PatternFill('solid', fgColor='2E7D6B'); thin = Side(style='thin', color='DDDDDD')

# Sheet 1: Logic & counts
s0 = wb.active; s0.title = 'Logic & Counts'
s0.column_dimensions['A'].width = 110
s0.cell(1, 1, 'STAGE 2 - MASTER CATEGORIES').font = Font(bold=True, size=14)
r = 3
s0.cell(r, 1, 'COUNTS:').font = Font(bold=True); r += 1
for label, val in [('Category-slots (with repeats)', slot_count), ('Distinct category names', len(distinct)),
                   ('Master categories', n_master), ('Broad - to split in Stage 3', n_broad)]:
    c = s0.cell(r, 1, '   ' + label + ':  ' + str(val)); r += 1
r += 1
for line in LOGIC:
    cc = s0.cell(r, 1, line)
    if line.endswith(':'):
        cc.font = Font(bold=True)
    r += 1

# Sheet 2: Master category summary (one merge: slots -> 20)
s1 = wb.create_sheet('Master Categories')
heads = ['Master Domain', '# entries merged (slots)', '# distinct names', 'Reason / what merged in (name x #frameworks)']
for j, h in enumerate(heads, 1):
    cc = s1.cell(1, j, h); cc.font = hd; cc.fill = fill; cc.alignment = Alignment(vertical='center', wrap_text=True)
r = 2
tot_slots = 0
for mc in sorted(MASTER):
    real = [n for n in MASTER[mc] if n in distinct]
    slots = sum(name_fw[n] for n in real)
    tot_slots += slots
    s1.cell(r, 1, mc); s1.cell(r, 2, slots); s1.cell(r, 3, len(real))
    s1.cell(r, 4, ' | '.join(n + ' x' + str(name_fw[n]) for n in real))
    for col in range(1, 5):
        s1.cell(r, col).border = Border(bottom=thin)
    r += 1
s1.cell(r, 1, 'TOTAL (= all 306 category-entries)').font = Font(bold=True)
s1.cell(r, 2, tot_slots).font = Font(bold=True)
s1.cell(r, 3, len(distinct)).font = Font(bold=True)
s1.freeze_panes = 'A2'
for col, w in zip('ABCD', [42, 22, 16, 120]): s1.column_dimensions[col].width = w

# Sheet 3: every category mapped (200 rows)
s2 = wb.create_sheet('All 200 Mapped')
for j, h in enumerate(['Original Category', '# Frameworks using it', 'Merges into Master Category'], 1):
    cc = s2.cell(1, j, h); cc.font = hd; cc.fill = fill
r = 2
rev = {}
for mc, lst in MASTER.items():
    for n in lst:
        rev[n] = mc
for n in sorted(distinct, key=lambda x: x.lower()):
    s2.cell(r, 1, n); s2.cell(r, 2, name_fw[n]); s2.cell(r, 3, rev.get(n, '?'))
    for col in range(1, 4):
        s2.cell(r, col).border = Border(bottom=thin)
    r += 1
s2.freeze_panes = 'A2'
for col, w in zip('ABC', [50, 20, 42]): s2.column_dimensions[col].width = w

xpath = os.path.expanduser('~/OneDrive/Desktop/STAGE2_master_categories.xlsx')
try:
    wb.save(xpath)
except PermissionError:
    xpath = os.path.expanduser('~/OneDrive/Desktop/STAGE2_master_categories_v2.xlsx'); wb.save(xpath)

print('JSON  (system):', os.path.abspath(jpath))
print('EXCEL (you)   :', xpath)
print('slots=%d  distinct=%d  master=%d  broad=%d  (all 200 mapped, 0 missing)' % (slot_count, len(distinct), n_master, n_broad))
