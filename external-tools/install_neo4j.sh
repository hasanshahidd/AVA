#!/usr/bin/env bash
# Neo4j 4.4 (Java-11 compatible) for bloodhound-mcp. On ext4 (~). Password 'bloodhound'
# to match BloodHound-MCP's default (user neo4j / pass bloodhound).
set -u
N=neo4j-community-4.4.30
cd ~ || exit 1
if [ ! -d ~/"$N" ]; then
  echo "downloading $N ..."
  curl -fsSL "https://dist.neo4j.org/${N}-unix.tar.gz" -o /tmp/neo4j.tgz \
    && tar -xzf /tmp/neo4j.tgz -C ~ || { echo "download/extract FAILED"; exit 1; }
fi
cd ~/"$N" || exit 1
# allow non-localhost off; keep bolt on 127.0.0.1:7687 (default). set initial password.
./bin/neo4j-admin set-initial-password bloodhound 2>&1 | tail -1
echo "starting neo4j ..."
./bin/neo4j start 2>&1 | tail -3
# wait for bolt :7687 to accept connections
for i in $(seq 1 25); do
  if (exec 3<>/dev/tcp/127.0.0.1/7687) 2>/dev/null; then echo "neo4j bolt :7687 UP (after ${i}x3s)"; exec 3>&-; break; fi
  sleep 3
done
(exec 3<>/dev/tcp/127.0.0.1/7687) 2>/dev/null && echo "READY" || echo "NOT READY YET (check ~/$N/logs/neo4j.log)"
