# IT Asset Inventory — Missing Parameters

_Gap list for the `ITAsset` model. These are asset **facts** we do not currently
capture; each feeds the asset **risk-posture score**. This is a **separate concept
from the CIS compliance-rules module** (that produces pass/fail benchmark checks —
a different system). Reference: NIST 800-53 CM-8, CIS Controls 1–2. Compiled 2026-08-31._

## Software control (we inventory software, not whether it's allowed)
- Software allowlist (authorized software)
- Software denylist / blacklist (prohibited software)
- Per-app authorization status (authorized / unauthorized / unknown)
- Unauthorized-software-detected flag
- Software license compliance (licensed vs installed)
- End-of-life / unsupported software flag

## Certificates
- Certificate inventory (subject, issuer, key size)
- Certificate expiry / days-to-expiry
- Certificate validity (valid / expired / self-signed / weak)
- Count compliant vs non-compliant

## Patch & OS currency
- Patch status / patch level
- Last-patched date
- Missing-patch count
- Reboot-pending (patch staged, not applied)
- End-of-life / unsupported OS flag

## Vulnerability (on the asset itself)
- Open vulnerability count
- Highest CVSS
- KEV (known-exploited) present flag
- Last vulnerability-scan date

## Exposure / attack surface
- Open ports / listening services
- Remote access exposed (RDP / SSH reachable)
- Insecure protocols enabled (SMBv1, Telnet, FTP, TLS 1.0)
- Public IP / DMZ placement

## Endpoint protection state
- Disk encryption status (on/off, method)
- Host firewall status (on/off)
- AV/EDR definition freshness (not just present)
- MFA enabled on access
- Removable media / USB control

## Accounts on the asset
- Local account inventory
- Privileged / admin account count
- Dormant / inactive accounts
- Shared / generic accounts

## Resilience
- Backup status / last-backup date
- Backup tested / restorable

## Monitoring
- Logging enabled
- Log forwarding to SIEM
- Time sync / NTP configured

## Hardware / firmware
- Firmware / BIOS version
- Secure boot enabled
- TPM present

## Governance
- Tags / labels (free-form / cloud tags)
- Sensitive data found on host (PII / PHI / PCI)
- Managed vs shadow (discovered but unmanaged)

## Cloud assets only
- Public storage bucket exposure
- Security group open to 0.0.0.0/0
- IAM over-permissioning
- Untagged / unowned resource
