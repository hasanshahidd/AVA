import json
d=json.load(open('_gov_controls.json'))
C=d['controls']
fw={x['i']:x['fw'] for x in C}
title={x['i']:x['title'] for x in C}

multi = [
 ("Establish and maintain an information security policy",
   [2,120,227,261,359,381,390,354,240]),
 ("Review and update the information security policy at planned intervals",
   [121,228,360,243]),
 ("Define and allocate information security roles and responsibilities",
   [1,111,229,262,370,382,391,167]),
 ("Formally appoint a CISO or senior information security officer",
   [230,223,250,185,399,380]),
 ("Implement a security awareness and training program",
   [3,263,355,375,208]),
 ("Demonstrate management leadership and commitment to information security",
   [109,128,165,209,366,410]),
 ("Establish an information security governance and management framework",
   [0,17,352,289,237,265]),
 ("Conduct information security risk assessments",
   [264,353,367,377,16]),
 ("Develop a risk management strategy",
   [224,186,21]),
 ("Perform independent review and audit of information security",
   [116,373,356,256]),
 ("Establish and maintain contact with relevant authorities",
   [114,371,385]),
 ("Establish and maintain contact with special interest groups",
   [115,372,386]),
 ("Coordinate information security activities across the organization",
   [110,369]),
 ("Address information security in third-party and vendor agreements",
   [119,357,217,14]),
 ("Board oversight and accountability for cyber and technology risk",
   [183,197,239,411]),
 ("Establish an information security management program",
   [108,222,245]),
 ("Establish and maintain the management system",
   [125,156]),
 ("Continual improvement of the management system",
   [127,157]),
 ("Nonconformity and corrective action",
   [126,158]),
 ("Determine resources needed for the management system",
   [134,173]),
 ("Determine competence of persons doing work",
   [135,174]),
 ("Ensure awareness of policy and responsibilities",
   [136,175]),
 ("Determine internal and external communications",
   [137,176,415]),
 ("Establish requirements for documented information",
   [138,177]),
 ("Create and update documented information appropriately",
   [139,178]),
 ("Control of documented information",
   [140,179]),
 ("Understand the organization and its context",
   [122,153]),
 ("Understand needs and expectations of interested parties",
   [123,154]),
 ("Determine the scope of the management system",
   [124,155]),
 ("Determine actions to address risks and opportunities",
   [131,202]),
 ("Establish a top-management policy",
   [129,166]),
 ("Assign organizational roles, responsibilities and authorities",
   [130,412]),
 ("Establish and review an AI policy",
   [150,201]),
 ("Define AI roles, responsibilities and oversight",
   [163,207]),
 ("Maintain an inventory of in-scope systems",
   [234,205]),
 ("Establish acceptable use / rules of behavior policy",
   [231,221]),
 ("Develop and protect system security plans",
   [220,247]),
 ("Establish an authorization process for information assets and systems",
   [225,112,362]),
 ("Communicate with external parties on matters affecting internal control",
   [416,162]),
 ("Establish a project management framework",
   [388,327,387,194]),
 ("Define third-party contingency and dependency processes",
   [218,285]),
]

assigned=set()
clean=[]
dupfw=[]
for tt,mem in multi:
    clean.append((tt,list(mem)))
    frset={}
    for m in mem:
        if m in assigned: print("DUP INDEX",m,"in",tt)
        assigned.add(m)
        frset.setdefault(fw[m],[]).append(m)
    for f,lst in frset.items():
        if len(lst)>1: dupfw.append((tt,f,lst))
print("multi sets:",len(clean))
print("assigned:",len(assigned))
print("dupfw:",dupfw)
missing=sorted(set(range(420))-assigned)
print("standalone count:",len(missing))
print("missing:",missing)
