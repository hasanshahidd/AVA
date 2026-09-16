# Ava — Client Device Onboarding Model

**Purpose:** how Ava brings a client's devices into inventory *at scale*, without configuring machines one by one.

---

## How onboarding works (the pipeline)

1. **Discover** — a network sweep of the client's CIDR(s) finds every device by **IP + MAC**. This works even through firewalls, because it uses ARP (layer 2) — a silent, firewalled host still shows up as an address + MAC + vendor.
2. **Connect** — Ava authenticates to each host over its management service (**WinRM** for Windows, **SSH** for Linux) with a saved credential, and reads OS, software, and configuration.
3. **Inventory** — connected hosts become managed assets; everything else is adopted as **evidence-only** (IP / MAC / vendor).

## The one rule that governs everything

Agentless authenticated onboarding needs two things **on each target**:

- a **login service listening** — WinRM (5985/5986) or SSH (22), and
- a **valid credential**.

**Ava cannot force into a machine that offers no service — by design** (doing so would be malware, not a scanner). So the fleet has to *offer* a door. The universal way to make every machine offer one is the client's **own management system** (Active Directory GPO, Intune, or SCCM) — which every enterprise client already has.

> This is the key insight: you never enable remote management device-by-device. You push it fleet-wide from the client's existing management tooling. Enabling WinRM on one machine by hand (e.g. `Enable-PSRemoting`) is exactly what a GPO does to the whole domain at once.

## Universal onboarding by device type

| Device type | Universal onboarding — one action, whole fleet | Per-device work |
|---|---|---|
| **Domain Windows** | 1 GPO enables WinRM + firewall on all machines; 1 domain credential connects all | none |
| **Linux fleet** | SSH enabled + a key/credential deployed via config-mgmt (Ansible / Satellite) | none |
| **No service / non-domain / IoT** | push the **Ava endpoint agent** fleet-wide via GPO / Intune / SCCM (each phones home, outbound only) | none |
| **Truly unmanaged one-offs** | adopt as **evidence-only** (tracked by IP / MAC / vendor) | none |

## Windows fleet — enable WinRM everywhere with one GPO

In Group Policy Management, create/edit a GPO linked to the target OUs:

1. **WinRM service auto-start** — Computer Configuration → Policies → Windows Settings → Security Settings → System Services → **Windows Remote Management (WS-Management)** → *Automatic*.
2. **Allow remote management** — Computer Configuration → Policies → Administrative Templates → Windows Components → Windows Remote Management (WinRM) → WinRM Service → **Allow remote server management through WinRM = Enabled**, IPv4/IPv6 filter = `*`.
3. **Firewall exception (LAN only)** — Computer Configuration → Policies → Windows Settings → Security Settings → Windows Defender Firewall with Advanced Security → Inbound → allow **TCP 5985** (and 5986 for HTTPS) from the management subnet only.
4. *(Equivalent shortcut)* a GPO **startup script** running `Enable-PSRemoting -Force` achieves the same at each boot.

Result: every domain-joined machine has WinRM on — the same thing we enabled by hand on one test PC, applied fleet-wide with **zero per-device work**.

## Credential — one login for the fleet (Ava side)

In Ava → Discover → **Connect** → Add login:

- Add a **domain admin** (or a least-privileged domain service account with remote-management rights) as a **WinRM** credential.
- **Scope it to the client's subnet** (e.g. `10.50.0.0/24`), **not a single IP** — so it applies to every host in range and survives DHCP changes.
- Ava automatically tries the best subnet-matching credential against every discovered Windows host.

For Linux: add an **SSH** credential (key or password) scoped to the Linux subnet.

## Devices that can't do WinRM/SSH — the agent

For endpoints where a management service can't be enabled (non-domain machines, appliances, strict hosts), deploy the **Ava endpoint agent** through the client's existing tooling (**GPO / Intune / SCCM**). It installs once per machine via policy, dials **outbound only** to Ava, and reports in — no inbound access and no per-device work.

## Remote clients — over the VPN

For a client Ava reaches over the site-to-site tunnel (IPsec to a FortiGate, or WireGuard):

1. Stand up the tunnel (Ava droplet ↔ the client's gateway).
2. The client applies the **WinRM GPO** (or deploys the **agent**) across their fleet.
3. Ava sweeps the client's subnet **over the tunnel** and connects every host with the domain credential.

## Set expectations honestly

- A device with **no** management service *and* no management tooling to push one **cannot** be authenticated agentlessly — adopt it as evidence-only, or install the agent on it manually.
- Enabling remote management is a **client-side action** (their GPO / Intune / config-mgmt), not something Ava does to their machines. **Ava consumes access; it does not create it.**

---

### Quick reference — the two universal levers
1. **Make the fleet offer a door:** GPO (Windows WinRM) / SSH via config-mgmt (Linux) / push an agent (everything else).
2. **One credential for the fleet:** a domain (or subnet-scoped) admin login — Ava applies it to every matching host automatically.
