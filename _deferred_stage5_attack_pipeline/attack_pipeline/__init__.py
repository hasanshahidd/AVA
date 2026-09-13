"""Fable attack pipeline — the run → device → scanner → vuln → exploit flow.

Continues from Asset Discovery: a discovered device feeds Fable, which picks the
scanner (MCP/capability) for its type, runs it with the tenant's stored
credential, and returns the vulnerabilities (Stage 1). Stage 2 (build + run the
exploit) is a later portion. Today only the Nessus capability is real; HexStrike,
Shodan, Prowler and VirusTotal slot in as more Capability subclasses.
"""
