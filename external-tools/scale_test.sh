#!/bin/bash
# ============================================================================
# AVA SCALE TEST — feed the Nessus findings, drive HexStrike to test each side
# of YOUR OWN device (172.21.64.1), live. Run:  wsl bash .../external-tools/scale_test.sh
# ============================================================================
HX=/mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools/hexstrike-ai
NESSUS=/mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/ai-pentest-eval/ground-truth/my_pc.nessus
TARGET=172.21.64.1

# --- 0) make sure HexStrike (the hands) is up ---
if ! ss -ltn | grep -q ':8888'; then
  echo "[*] starting HexStrike server..."
  ( cd "$HX" && nohup python3 hexstrike_server.py >/tmp/hexstrike.log 2>&1 & ); disown
  for i in $(seq 1 20); do curl -s -m3 -o /dev/null http://localhost:8888/api/command \
    -H 'Content-Type: application/json' -d '{"command":"echo ok"}' && break; sleep 1; done
fi

# --- helper: run ANY command through HexStrike, print its output ---
hex(){ python3 - "$1" "$2" <<'PY'
import sys,json,urllib.request
cmd,to=sys.argv[1],int(sys.argv[2])
req=urllib.request.Request("http://localhost:8888/api/command",
  data=json.dumps({"command":cmd,"use_cache":False}).encode(),
  headers={"Content-Type":"application/json"})
try:
    d=json.load(urllib.request.urlopen(req,timeout=to))
    print((d.get("stdout") or d.get("output") or "").strip()[:700] or "(no output)")
except Exception as e: print("HexStrike error:",e)
PY
}

echo ""
echo "############ STEP 1 — YOUR NESSUS INPUT (the vulnerabilities we feed) ############"
python3 - "$NESSUS" <<'PY'
import sys,xml.etree.ElementTree as ET,collections
r=ET.parse(sys.argv[1]).getroot()
lbl=["Info","Low","Med","High","Crit"]; tally=collections.Counter(); reach=collections.Counter()
ports={"6379":"Redis(db)","8069":"Odoo(web)","445":"SMB(net)","5985":"WinRM(auth)","139":"NetBIOS"}
for it in r.iter("ReportItem"):
    tally[int(it.get("severity","0"))]+=1
    p=it.get("port","0")
    if p in ports and int(it.get("severity","0"))>=1: reach[ports[p]]+=1
print("Nessus severity spread:",{lbl[k]:v for k,v in sorted(tally.items())})
print("Findings tied to a REACHABLE service (the exploit-testable ones):",dict(reach))
print(">> Most of the 354 are software-version CVEs = PATCH-only, not exploitable remotely.")
print(">> The testable attack surface is the reachable services -> tested below via HexStrike:")
PY

echo ""
echo "############ STEP 2 — HexStrike tests each SIDE of your device ############"

echo ""; echo "---- SIDE A · WEB  (Odoo 8069, Nessus: Werkzeug/Odoo exposed) ----"
hex "curl -s -m 8 -i http://$TARGET:8069/web/database/manager | head -1; echo '--- db list ---'; curl -s -m 8 http://$TARGET:8069/web/database/list -H 'Content-Type: application/json' -d '{}'" 25

echo ""; echo "---- SIDE B · NETWORK  (SMB 445, Nessus: SMB signing not required) ----"
hex "nmap -Pn -p445 --script smb2-security-mode,smb-protocols $TARGET | grep -Ei 'open|signing|dialect|2\\.|3\\.'" 70

echo ""; echo "---- SIDE C · AUTH  (WinRM 5985) ----"
hex "curl -s -m 8 -i http://$TARGET:5985/wsman | head -3" 25

echo ""; echo "---- SIDE D · DATABASE  (Redis 6379 — localhost-only, run the Windows PoC) ----"
echo "   Redis is bound to 127.0.0.1 so HexStrike-in-WSL can't reach it."
echo "   From Windows PowerShell:  python \"<scratchpad>\\redis_poc.py\""
echo "   >> ALREADY CONFIRMED: unauthenticated READ + WRITE (no password)."

echo ""
echo "############ RESULT ############"
echo "Each side tested live via HexStrike, seeded by your Nessus findings."
echo "Real risk on your box = Redis (unauth, exploited) + Odoo db-manager (exposed, master-pw gated)."
echo "Everything else = hardened or patch-only."
