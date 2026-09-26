#!/usr/bin/env bash
# Start Neo4j DETACHED (setsid+nohup) so it survives the launching WSL session, then confirm
# bloodhound-mcp enumerates against it.
cd ~/neo4j-community-4.4.30 || exit 1
./bin/neo4j stop >/dev/null 2>&1; sleep 2
setsid nohup ./bin/neo4j console >/tmp/neo4j_console.log 2>&1 &
echo "neo4j launching (detached) ..."
up=0
for i in $(seq 1 25); do
  if (exec 3<>/dev/tcp/127.0.0.1/7687) 2>/dev/null; then exec 3>&-; up=1; echo "bolt :7687 UP (${i}x3s)"; break; fi
  sleep 3
done
[ "$up" -eq 1 ] || { echo "neo4j NOT up; log tail:"; tail -6 /tmp/neo4j_console.log; exit 1; }
sleep 5
echo "=== verify bloodhound enumerates (needs mcp<2 + neo4j) ==="
cd /mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/ava-pentest-engine || exit 1
PYTHONPATH=. timeout 30 python3 -c "
from ava_pentest.mcp.executor import LaneExecutor
ex = LaneExecutor('bloodhound').connect()
try:
    print('bloodhound:', len(ex.tools()), 'tools')
finally:
    ex.close()
" 2>&1 | tail -4
