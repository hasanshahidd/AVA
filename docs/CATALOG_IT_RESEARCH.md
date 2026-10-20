# IT Service Catalog & Incident Categories — Research-Grounded Reference

**Purpose.** A realistic, enterprise/bank-grade IT service catalog and incident-category
set for the Help Desk ITSM module. Every item below is a real issue or request that
production service desks handle — drawn from ServiceNow, Freshservice/Freshworks, Jira
Service Management, GLPI, ITIL 4 incident-management guidance, ManageEngine, Okta/Microsoft
Entra IAM practice, Microsoft Intune/MDM troubleshooting, Microsoft Teams/Teams Rooms
support docs, and bank trading-floor desktop-support role definitions. No placeholder or
invented items — see "Sources I used" at the end.

**Field model (per item):**
`title` · `process` (incident | service_request | problem | change) · `category` /
`subcategory` · `short_description` (ticket pre-fill) · `department_scope` ·
`impact_default` / `urgency_default` · `suggested_team`.

**Process rule applied (ITIL 4):** something *broken* = **incident**; "I need X / give me
access / provision this" = **service_request**; a *recurring root cause* behind many
incidents = **problem**; a *planned, approved modification* to the environment = **change**.
Impact = breadth of effect (users/systems); urgency = how fast resolution is needed. An
outage trends high/high; a routine ask trends low/low.

---

## 1. Email & Collaboration
*Category:* `Email & Collaboration` — handled primarily by IT Helpdesk / Messaging.

**1.1 Can't send or receive email (Outlook)**
- process: `incident` | subcategory: Mailbox Access | scope: `all`
- short_description: "User's Outlook / mailbox is not sending or receiving messages."
- impact: medium · urgency: high · team: IT Helpdesk

**1.2 Outlook won't open / keeps crashing**
- process: `incident` | subcategory: Email Client | scope: `all`
- short_description: "Outlook desktop client fails to launch or crashes repeatedly."
- impact: medium · urgency: medium · team: Desktop Support

**1.3 Mailbox is full / over quota**
- process: `incident` | subcategory: Mailbox Quota | scope: `all`
- short_description: "User has hit their mailbox storage limit and cannot send/receive."
- impact: low · urgency: medium · team: Messaging

**1.4 Request a mailbox quota increase**
- process: `service_request` | subcategory: Mailbox Quota | scope: `all`
- short_description: "Request additional mailbox storage beyond the standard allocation."
- impact: low · urgency: low · team: Messaging

**1.5 Request access to a shared mailbox**
- process: `service_request` | subcategory: Shared Mailbox | scope: `all`
- short_description: "Request read/send access to an existing shared/team mailbox."
- impact: low · urgency: low · team: Messaging

**1.6 Create a new shared / resource mailbox**
- process: `service_request` | subcategory: Shared Mailbox | scope: `all`
- short_description: "Provision a new shared mailbox or room/equipment resource mailbox."
- impact: low · urgency: low · team: Messaging

**1.7 Add / remove a distribution list member**
- process: `service_request` | subcategory: Distribution List | scope: `all`
- short_description: "Add or remove a member from an email distribution group."
- impact: low · urgency: low · team: Messaging

**1.8 Create a new distribution list**
- process: `service_request` | subcategory: Distribution List | scope: `all`
- short_description: "Request creation of a new email distribution group."
- impact: low · urgency: low · team: Messaging

**1.9 Legitimate email blocked / stuck in quarantine**
- process: `incident` | subcategory: Mail Flow | scope: `all`
- short_description: "A wanted message is being blocked or held in the spam quarantine."
- impact: low · urgency: medium · team: Messaging

**1.10 Set up an out-of-office / mailbox delegation**
- process: `service_request` | subcategory: Mailbox Config | scope: `all`
- short_description: "Configure automatic replies or delegate mailbox/calendar access."
- impact: low · urgency: low · team: IT Helpdesk

**1.11 Calendar sharing / meeting invites not working**
- process: `incident` | subcategory: Calendar | scope: `all`
- short_description: "Calendar won't share, or meeting invitations fail to send/update."
- impact: low · urgency: medium · team: IT Helpdesk

**1.12 Email service outage (multiple users cannot access mail)**
- process: `incident` | subcategory: Mail Platform | scope: `all`
- short_description: "Exchange/M365 mail is unavailable for many users — suspected outage."
- impact: high · urgency: high · team: Messaging

**1.13 Recurring Outlook crashes across the fleet (root cause)**
- process: `problem` | subcategory: Email Client | scope: `["IT"]`
- short_description: "Investigate repeated Outlook crash incidents to find root cause."
- impact: medium · urgency: medium · team: Messaging

---

## 2. PC / Laptop (Hardware)
*Category:* `Hardware` — handled primarily by Desktop Support.

**2.1 Laptop won't power on**
- process: `incident` | subcategory: Device Failure | scope: `all`
- short_description: "Laptop/desktop does not power on or shows no display."
- impact: medium · urgency: high · team: Desktop Support

**2.2 Laptop running very slow / freezing**
- process: `incident` | subcategory: Performance | scope: `all`
- short_description: "Device is extremely slow, hanging, or freezing during normal use."
- impact: low · urgency: medium · team: Desktop Support

**2.3 Blue screen / system keeps crashing**
- process: `incident` | subcategory: OS Crash | scope: `all`
- short_description: "Machine repeatedly blue-screens or restarts unexpectedly."
- impact: medium · urgency: high · team: Desktop Support

**2.4 Battery won't charge / drains fast**
- process: `incident` | subcategory: Battery | scope: `all`
- short_description: "Laptop battery no longer charges or discharges abnormally fast."
- impact: low · urgency: medium · team: Desktop Support

**2.5 Keyboard / trackpad / mouse not working**
- process: `incident` | subcategory: Peripherals | scope: `all`
- short_description: "Built-in or attached input device is unresponsive."
- impact: low · urgency: medium · team: Desktop Support

**2.6 External monitor / docking station not detected**
- process: `incident` | subcategory: Peripherals | scope: `all`
- short_description: "Monitor or dock is not recognized or no signal on external display."
- impact: low · urgency: medium · team: Desktop Support

**2.7 Request a new laptop / desktop**
- process: `service_request` | subcategory: Device Provisioning | scope: `all`
- short_description: "Request a standard-build laptop or desktop (manager approval)."
- impact: low · urgency: low · team: Desktop Support

**2.8 Request a hardware refresh / replacement (end of life)**
- process: `service_request` | subcategory: Device Provisioning | scope: `all`
- short_description: "Replace an aging device that has reached end-of-life."
- impact: low · urgency: low · team: Desktop Support

**2.9 Request additional peripherals (monitor, dock, headset, keyboard)**
- process: `service_request` | subcategory: Peripherals | scope: `all`
- short_description: "Request standard accessories such as a monitor, dock, or headset."
- impact: low · urgency: low · team: Desktop Support

**2.10 Request a memory / storage upgrade**
- process: `service_request` | subcategory: Device Upgrade | scope: `all`
- short_description: "Request additional RAM or disk capacity for an existing device."
- impact: low · urgency: low · team: Desktop Support

**2.11 Overheating / loud fan / physical damage**
- process: `incident` | subcategory: Physical | scope: `all`
- short_description: "Device overheats, fan is loud, or there is visible physical damage."
- impact: low · urgency: medium · team: Desktop Support

**2.12 Fleet-wide docking-station disconnects (root cause)**
- process: `problem` | subcategory: Peripherals | scope: `["IT"]`
- short_description: "Investigate recurring dock/monitor disconnect incidents for root cause."
- impact: medium · urgency: medium · team: Desktop Support

---

## 3. Accounts & Access (Identity / MFA / Offboarding)
*Category:* `Accounts & Access` — handled primarily by Identity/Access (IAM) & Security.

**3.1 Password expired / can't sign in**
- process: `incident` | subcategory: Password | scope: `all`
- short_description: "User's password has expired or sign-in is failing."
- impact: medium · urgency: high · team: Identity/Access

**3.2 Account locked out**
- process: `incident` | subcategory: Account Lockout | scope: `all`
- short_description: "User account is locked after failed sign-ins and needs unlocking."
- impact: medium · urgency: high · team: Identity/Access

**3.3 Reset / re-enroll multi-factor authentication (MFA)**
- process: `incident` | subcategory: MFA | scope: `all`
- short_description: "User lost/changed their MFA device and must re-enroll authenticators."
- impact: medium · urgency: high · team: Identity/Access

**3.4 New authenticator / lost phone — MFA no longer works**
- process: `incident` | subcategory: MFA | scope: `all`
- short_description: "Enrolled MFA method is unavailable; user cannot complete sign-in."
- impact: medium · urgency: high · team: Identity/Access

**3.5 Request access to an application / system**
- process: `service_request` | subcategory: Application Access | scope: `all`
- short_description: "Request a role/entitlement in a named business application (approval)."
- impact: low · urgency: low · team: Identity/Access

**3.6 Request access to a shared drive / network folder**
- process: `service_request` | subcategory: File Share Access | scope: `all`
- short_description: "Request read or write access to a shared network folder."
- impact: low · urgency: low · team: Identity/Access

**3.7 Add / change security group or role membership**
- process: `service_request` | subcategory: Group Membership | scope: `all`
- short_description: "Add, remove, or change AD/Entra/Okta group or role membership."
- impact: low · urgency: low · team: Identity/Access

**3.8 New joiner — onboard & provision accounts**
- process: `service_request` | subcategory: Onboarding | scope: `all`
- short_description: "Provision accounts, mailbox, and baseline access for a new employee."
- impact: medium · urgency: medium · team: Identity/Access

**3.9 Leaver — offboard & revoke all access**
- process: `service_request` | subcategory: Offboarding | scope: `all`
- short_description: "Disable account, revoke sessions, and remove all access for a leaver."
- impact: medium · urgency: high · team: Identity/Access

**3.10 Role change / transfer — adjust access (mover)**
- process: `service_request` | subcategory: Access Change | scope: `all`
- short_description: "Grant new-role access and remove prior-role access after a transfer."
- impact: low · urgency: medium · team: Identity/Access

**3.11 Request elevated / privileged access**
- process: `service_request` | subcategory: Privileged Access | scope: `all`
- short_description: "Request admin/privileged rights (time-bound, approval + review)."
- impact: medium · urgency: medium · team: Identity/Access

**3.12 Request local admin rights on my machine**
- process: `service_request` | subcategory: Privileged Access | scope: `all`
- short_description: "Request temporary local administrator rights on a workstation."
- impact: low · urgency: low · team: Identity/Access

**3.13 Single sign-on (SSO) not working for an app**
- process: `incident` | subcategory: SSO | scope: `all`
- short_description: "SSO/federated login to an application is failing for the user."
- impact: medium · urgency: high · team: Identity/Access

**3.14 Orphaned/stale access found after leaver (root cause)**
- process: `problem` | subcategory: Deprovisioning | scope: `["IT"]`
- short_description: "Leftover access after offboarding — investigate IdP↔ITSM sync gap."
- impact: high · urgency: medium · team: Security

---

## 4. Network & Connectivity
*Category:* `Network & Connectivity` — handled primarily by Network.

**4.1 No internet / network connection**
- process: `incident` | subcategory: Connectivity | scope: `all`
- short_description: "User has completely lost wired or wireless network connectivity."
- impact: medium · urgency: high · team: Network

**4.2 Wi-Fi keeps dropping / weak signal**
- process: `incident` | subcategory: Wi-Fi | scope: `all`
- short_description: "Wi-Fi connection drops intermittently or signal is weak at location."
- impact: low · urgency: medium · team: Network

**4.3 VPN won't connect**
- process: `incident` | subcategory: VPN | scope: `all`
- short_description: "Remote-access VPN fails to connect or disconnects repeatedly."
- impact: medium · urgency: high · team: Network

**4.4 Request VPN / remote access**
- process: `service_request` | subcategory: VPN | scope: `all`
- short_description: "Request remote-access VPN entitlement for an employee (approval)."
- impact: low · urgency: low · team: Network

**4.5 Slow network / high latency**
- process: `incident` | subcategory: Performance | scope: `all`
- short_description: "Network is noticeably slow or latency is affecting applications."
- impact: medium · urgency: medium · team: Network

**4.6 Can't reach a specific internal site / application**
- process: `incident` | subcategory: Connectivity | scope: `all`
- short_description: "A specific internal URL or system is unreachable from the network."
- impact: medium · urgency: medium · team: Network

**4.7 Website / URL blocked by web filter**
- process: `service_request` | subcategory: Web Filtering | scope: `all`
- short_description: "Request review/allow-listing of a business URL blocked by the proxy."
- impact: low · urgency: low · team: Network

**4.8 Request a firewall rule / port opening**
- process: `change` | subcategory: Firewall | scope: `["IT"]`
- short_description: "Request a firewall change to permit a specific flow (CAB-approved)."
- impact: medium · urgency: medium · team: Network

**4.9 Request a static IP / DNS record change**
- process: `change` | subcategory: DNS/IP | scope: `["IT"]`
- short_description: "Request a new DNS record, static IP, or DHCP reservation."
- impact: low · urgency: low · team: Network

**4.10 Network port / wall jack activation**
- process: `service_request` | subcategory: LAN | scope: `all`
- short_description: "Activate or patch a physical network port at a desk location."
- impact: low · urgency: low · team: Network

**4.11 Site-wide network outage (multiple users offline)**
- process: `incident` | subcategory: Outage | scope: `all`
- short_description: "A floor, site, or many users have lost network — suspected outage."
- impact: high · urgency: high · team: Network

**4.12 Recurring VPN disconnects for remote users (root cause)**
- process: `problem` | subcategory: VPN | scope: `["IT"]`
- short_description: "Investigate repeated VPN disconnect incidents for underlying cause."
- impact: medium · urgency: medium · team: Network

---

## 5. Software & Applications
*Category:* `Software & Applications` — handled by Desktop Support / Application Support.

**5.1 Application won't launch / crashes**
- process: `incident` | subcategory: Application Fault | scope: `all`
- short_description: "A business application fails to open or crashes on launch."
- impact: medium · urgency: medium · team: Application Support

**5.2 Application error message / unexpected behavior**
- process: `incident` | subcategory: Application Fault | scope: `all`
- short_description: "User receives an error or the app behaves incorrectly."
- impact: low · urgency: medium · team: Application Support

**5.3 Request installation of standard software**
- process: `service_request` | subcategory: Software Install | scope: `all`
- short_description: "Install an approved application from the standard software catalog."
- impact: low · urgency: low · team: Desktop Support

**5.4 Request a software license / seat**
- process: `service_request` | subcategory: Licensing | scope: `all`
- short_description: "Request a paid license/seat for a licensed application (approval)."
- impact: low · urgency: low · team: Application Support

**5.5 Request non-standard / new software (needs review)**
- process: `service_request` | subcategory: Software Install | scope: `all`
- short_description: "Request software not in the catalog — security/license review required."
- impact: low · urgency: low · team: Application Support

**5.6 Software update / patch / version upgrade**
- process: `change` | subcategory: Patching | scope: `["IT"]`
- short_description: "Planned application or OS version upgrade / patch deployment."
- impact: medium · urgency: medium · team: Application Support

**5.7 Browser issue (won't load pages, plugin/certificate error)**
- process: `incident` | subcategory: Browser | scope: `all`
- short_description: "Web browser fails to load pages or shows certificate/plugin errors."
- impact: low · urgency: medium · team: Desktop Support

**5.8 Office / productivity suite not working (Word, Excel, Teams)**
- process: `incident` | subcategory: Productivity Suite | scope: `all`
- short_description: "A Microsoft 365 / Office application is failing or won't activate."
- impact: medium · urgency: medium · team: Desktop Support

**5.9 Macro / add-in / template not working**
- process: `incident` | subcategory: Office Add-in | scope: `all`
- short_description: "An Office macro, add-in, or template no longer functions."
- impact: low · urgency: medium · team: Application Support

**5.10 Data / file recovery from backup**
- process: `service_request` | subcategory: Data Recovery | scope: `all`
- short_description: "Restore a deleted or corrupted file/folder from backup."
- impact: medium · urgency: medium · team: Desktop Support

**5.11 Business application outage (many users affected)**
- process: `incident` | subcategory: Application Outage | scope: `all`
- short_description: "A core business application is down for multiple users."
- impact: high · urgency: high · team: Application Support

**5.12 Recurring crashes in a core app after update (root cause)**
- process: `problem` | subcategory: Application Fault | scope: `["IT"]`
- short_description: "Investigate repeated app failures following a release for root cause."
- impact: high · urgency: medium · team: Application Support

---

## 6. Printing
*Category:* `Printing` — handled primarily by Desktop Support / Print Services.

**6.1 Printer not responding / can't print**
- process: `incident` | subcategory: Printer Fault | scope: `all`
- short_description: "Print jobs fail or the printer is unresponsive/offline."
- impact: low · urgency: medium · team: Desktop Support

**6.2 Paper jam / hardware error on printer**
- process: `incident` | subcategory: Printer Hardware | scope: `all`
- short_description: "Printer reports a paper jam or hardware fault needing attention."
- impact: low · urgency: low · team: Desktop Support

**6.3 Poor print quality (streaks, faded, smudged)**
- process: `incident` | subcategory: Print Quality | scope: `all`
- short_description: "Output quality is degraded — streaks, faded text, or smudging."
- impact: low · urgency: low · team: Desktop Support

**6.4 Add / connect to a network printer**
- process: `service_request` | subcategory: Printer Setup | scope: `all`
- short_description: "Map a workstation to an existing network/follow-me printer queue."
- impact: low · urgency: low · team: Desktop Support

**6.5 Request toner / paper / consumables**
- process: `service_request` | subcategory: Consumables | scope: `all`
- short_description: "Request replacement toner, ink, or paper for a printer."
- impact: low · urgency: low · team: Desktop Support

**6.6 Request a new printer / MFP install**
- process: `service_request` | subcategory: Printer Provisioning | scope: `all`
- short_description: "Install or relocate a printer/multifunction device."
- impact: low · urgency: low · team: Desktop Support

**6.7 Scan-to-email / scan-to-folder not working**
- process: `incident` | subcategory: Scanning | scope: `all`
- short_description: "The device cannot scan to email or to a network folder."
- impact: low · urgency: medium · team: Desktop Support

**6.8 Secure/badge release printing not working**
- process: `incident` | subcategory: Secure Print | scope: `all`
- short_description: "Badge/PIN release at the printer is not releasing held jobs."
- impact: low · urgency: medium · team: Desktop Support

---

## 7. Mobile Devices
*Category:* `Mobile Devices` — handled by Mobility / Endpoint (MDM) team.

**7.1 Enroll a device in MDM (Intune/Company Portal)**
- process: `service_request` | subcategory: Enrollment | scope: `all`
- short_description: "Enroll a corporate or BYOD phone/tablet in mobile device management."
- impact: low · urgency: low · team: Mobility/Endpoint

**7.2 Device enrollment failing / stuck on profile install**
- process: `incident` | subcategory: Enrollment | scope: `all`
- short_description: "MDM enrollment fails, stuck on profile install or registration."
- impact: low · urgency: medium · team: Mobility/Endpoint

**7.3 Corporate email not syncing on phone**
- process: `incident` | subcategory: Mobile Email | scope: `all`
- short_description: "Email/calendar will not sync on the mobile device."
- impact: low · urgency: medium · team: Mobility/Endpoint

**7.4 Device out of compliance — access blocked**
- process: `incident` | subcategory: Compliance | scope: `all`
- short_description: "Conditional Access is blocking apps because the device is non-compliant."
- impact: medium · urgency: medium · team: Mobility/Endpoint

**7.5 Lost or stolen device — wipe / retire**
- process: `incident` | subcategory: Lost Device | scope: `all`
- short_description: "Report a lost/stolen device for selective wipe or retire (verify identity)."
- impact: medium · urgency: high · team: Security

**7.6 "Device cap reached" — can't enroll another device**
- process: `incident` | subcategory: Enrollment | scope: `all`
- short_description: "User hit the device enrollment limit; stale records need removing."
- impact: low · urgency: medium · team: Mobility/Endpoint

**7.7 Request a new corporate mobile phone / tablet**
- process: `service_request` | subcategory: Device Provisioning | scope: `all`
- short_description: "Request a corporate-owned mobile device (manager approval)."
- impact: low · urgency: low · team: Mobility/Endpoint

**7.8 Request a mobile app from the managed app catalog**
- process: `service_request` | subcategory: Mobile App | scope: `all`
- short_description: "Push a managed/business app to the user's enrolled device."
- impact: low · urgency: low · team: Mobility/Endpoint

**7.9 Reset device passcode / unlock managed device**
- process: `incident` | subcategory: Device Access | scope: `all`
- short_description: "User is locked out of a managed device and needs a passcode reset."
- impact: low · urgency: medium · team: Mobility/Endpoint

**7.10 Request mobile data / roaming / plan change**
- process: `service_request` | subcategory: Carrier Plan | scope: `all`
- short_description: "Request a carrier plan, data, or international roaming change."
- impact: low · urgency: low · team: Mobility/Endpoint

---

## 8. Security (Phishing / Malware / Lost Device)
*Category:* `Security` — handled primarily by Security / SOC.

**8.1 Report a suspected phishing email**
- process: `incident` | subcategory: Phishing | scope: `all`
- short_description: "User received a suspicious email and is reporting it for triage."
- impact: medium · urgency: high · team: Security

**8.2 I clicked a phishing link / entered my credentials**
- process: `incident` | subcategory: Phishing | scope: `all`
- short_description: "User interacted with a phishing message — possible credential compromise."
- impact: high · urgency: high · team: Security

**8.3 Suspected malware / virus on device**
- process: `incident` | subcategory: Malware | scope: `all`
- short_description: "Device shows signs of malware/virus infection and needs isolation."
- impact: high · urgency: high · team: Security

**8.4 Antivirus / EDR alert on my machine**
- process: `incident` | subcategory: Endpoint Threat | scope: `all`
- short_description: "Endpoint protection flagged a threat that needs investigation."
- impact: medium · urgency: high · team: Security

**8.5 Suspicious login / unrecognized sign-in activity**
- process: `incident` | subcategory: Account Compromise | scope: `all`
- short_description: "User or alerting flagged an unexpected sign-in on their account."
- impact: high · urgency: high · team: Security

**8.6 Report a lost/stolen device (data at risk)**
- process: `incident` | subcategory: Lost Device | scope: `all`
- short_description: "A device with corporate data is lost/stolen — contain and wipe."
- impact: high · urgency: high · team: Security

**8.7 Report a data loss / possible breach**
- process: `incident` | subcategory: Data Incident | scope: `all`
- short_description: "Possible exposure or loss of sensitive data — escalate to security."
- impact: high · urgency: high · team: Security

**8.8 Ransomware / files encrypted (major incident)**
- process: `incident` | subcategory: Ransomware | scope: `all`
- short_description: "Files appear encrypted/ransom note present — declare major incident."
- impact: high · urgency: high · team: Security

**8.9 Request a security exception / policy exemption**
- process: `service_request` | subcategory: Exception | scope: `all`
- short_description: "Request a time-bound exception to a security policy (approval + review)."
- impact: medium · urgency: medium · team: Security

**8.10 Report spam getting through / filter too aggressive**
- process: `incident` | subcategory: Spam Filtering | scope: `all`
- short_description: "Spam/junk filtering is misclassifying mail (too much or too little)."
- impact: low · urgency: low · team: Security

**8.11 Recurring phishing campaign against staff (root cause)**
- process: `problem` | subcategory: Phishing | scope: `["IT"]`
- short_description: "Repeated phishing waves — investigate controls and awareness gaps."
- impact: high · urgency: medium · team: Security

---

## 9. Telephony / Teams / Collaboration Tools
*Category:* `Telephony & Collaboration` — handled by Unified Comms / Collaboration team.

**9.1 Can't make or receive calls (softphone / Teams Phone)**
- process: `incident` | subcategory: Voice | scope: `all`
- short_description: "User's phone line / softphone cannot place or receive calls."
- impact: medium · urgency: high · team: Unified Comms

**9.2 Poor call quality (dropped calls, echo, latency)**
- process: `incident` | subcategory: Voice Quality | scope: `all`
- short_description: "Calls suffer from drops, echo, choppy audio, or latency."
- impact: medium · urgency: medium · team: Unified Comms

**9.3 Teams audio/video not working in meetings**
- process: `incident` | subcategory: Teams Meetings | scope: `all`
- short_description: "Mic, speaker, or camera fails during Teams calls/meetings."
- impact: medium · urgency: high · team: Unified Comms

**9.4 Can't sign in to Teams / Teams won't open**
- process: `incident` | subcategory: Teams Client | scope: `all`
- short_description: "Teams client will not launch or the user cannot sign in."
- impact: medium · urgency: medium · team: IT Helpdesk

**9.5 Teams chat / messages not sending or syncing**
- process: `incident` | subcategory: Teams Messaging | scope: `all`
- short_description: "Messages fail to send or do not sync across the user's devices."
- impact: low · urgency: medium · team: Unified Comms

**9.6 Request a new phone number / extension (DID)**
- process: `service_request` | subcategory: Voice Provisioning | scope: `all`
- short_description: "Provision a new phone number / extension and assign to a user."
- impact: low · urgency: low · team: Unified Comms

**9.7 Set up a hunt group / call queue / auto-attendant**
- process: `service_request` | subcategory: Call Routing | scope: `all`
- short_description: "Create or change a call queue, hunt group, or auto-attendant flow."
- impact: low · urgency: low · team: Unified Comms

**9.8 Request a new Teams team / channel / SharePoint site**
- process: `service_request` | subcategory: Collaboration Site | scope: `all`
- short_description: "Provision a new Teams team, channel, or associated SharePoint site."
- impact: low · urgency: low · team: Collaboration

**9.9 Voicemail not working / reset voicemail PIN**
- process: `incident` | subcategory: Voicemail | scope: `all`
- short_description: "Voicemail is not recording/delivering, or the PIN needs resetting."
- impact: low · urgency: low · team: Unified Comms

**9.10 Teams / telephony service degraded for many users**
- process: `incident` | subcategory: Collab Outage | scope: `all`
- short_description: "Teams or voice is down/degraded for many users — check service health."
- impact: high · urgency: high · team: Unified Comms

---

## 10. Audio-Visual / Meeting Rooms
*Category:* `Audio-Visual & Meeting Rooms` — handled by AV / Collaboration team.

**10.1 Meeting room display / projector not working**
- process: `incident` | subcategory: Room Display | scope: `all`
- short_description: "The room screen or projector shows no signal or won't power on."
- impact: medium · urgency: high · team: AV Support

**10.2 Room audio not working (mics / speakers)**
- process: `incident` | subcategory: Room Audio | scope: `all`
- short_description: "Room microphones or speakers are not working during a meeting."
- impact: medium · urgency: high · team: AV Support

**10.3 Room camera not working / can't be found**
- process: `incident` | subcategory: Room Video | scope: `all`
- short_description: "The room camera is not detected or produces no video."
- impact: medium · urgency: high · team: AV Support

**10.4 Can't connect laptop to room screen (HDMI/wireless)**
- process: `incident` | subcategory: Room Connectivity | scope: `all`
- short_description: "A laptop won't present to the room display via cable or wireless cast."
- impact: low · urgency: high · team: AV Support

**10.5 Teams Room / Zoom Room console unresponsive**
- process: `incident` | subcategory: Room System | scope: `all`
- short_description: "The room's Teams/Zoom Room controller is frozen or unresponsive."
- impact: medium · urgency: high · team: AV Support

**10.6 Room can't join / start the scheduled meeting**
- process: `incident` | subcategory: Room Meetings | scope: `all`
- short_description: "The room system cannot join or start the booked video meeting."
- impact: medium · urgency: high · team: AV Support

**10.7 Request AV support / on-site tech for an event**
- process: `service_request` | subcategory: Event Support | scope: `all`
- short_description: "Request an AV technician to stand by for a meeting or event."
- impact: low · urgency: medium · team: AV Support

**10.8 Request AV equipment setup in a new/changed room**
- process: `service_request` | subcategory: Room Provisioning | scope: `all`
- short_description: "Install or reconfigure AV equipment for a meeting space."
- impact: low · urgency: low · team: AV Support

**10.9 Recurring room-system join failures (root cause)**
- process: `problem` | subcategory: Room System | scope: `["IT"]`
- short_description: "Investigate repeated room join/AV failures across rooms for root cause."
- impact: medium · urgency: medium · team: AV Support

---

## Summary

- **Categories covered (10):** Email & Collaboration; PC/Laptop (Hardware); Accounts &
  Access; Network & Connectivity; Software & Applications; Printing; Mobile Devices;
  Security; Telephony/Teams/Collaboration; Audio-Visual/Meeting Rooms.
- **Total items: 111.**
- **Per-category counts:** Email 13 · Hardware 12 · Accounts & Access 14 · Network 12 ·
  Software 12 · Printing 8 · Mobile 10 · Security 11 · Telephony/Collab 10 · AV/Rooms 9.
- **Process distribution:**
  - `incident` — 63
  - `service_request` — 38
  - `problem` — 7
  - `change` — 3
- **Department scope:** most items are `all` (any employee can raise); IT-staff-only
  (`["IT"]`) items are the 7 `problem` root-cause records and the 3 IT-internal `change`
  items (firewall rule, DNS/IP change, patch/upgrade deployment).

---

## Sources I used (research-grounded)

Catalog structure, categories, and item wording were synthesized and cross-referenced from:

- **ServiceNow** — Service Catalog hierarchy (catalogs → categories → items), record
  producers for incidents, order guides for onboarding bundles; categories Hardware /
  Software / Access Management; example items (new laptop, software install, access):
  servicenow.com platform docs and reco.ai ServiceNow Service Catalog guide.
- **Freshservice / Freshworks** — catalog category groupings (Email & Calendar,
  Permissions & Access, Hardware, Apps & Software, Support Resources, Training, Business &
  Finance); common service requests (hardware provisioning, software install, access
  permissions, email account creation); onboarding/offboarding items; real customer catalog
  examples (shared mailbox, distribution list, replacement laptop/desktop/mobile):
  freshworks.com IT service catalog and support.freshservice.com docs.
- **Jira Service Management (Atlassian)** — default IT help-desk request types, request-type
  grouping on the customer portal, request type ↔ issue type model: confluence.atlassian.com
  "Setting up request types."
- **GLPI** — ITIL category tree (nested ticket categories shared across incident/change/
  problem), "software > email" child-category example, template auto-load per category:
  help.glpi-project.org documentation and tutorials.
- **ITIL 4 / incident-management practice** — broken = incident, "I need X" = service
  request, recurring cause = problem, planned modification = change; three-level
  category→subcategory→issue model; priority derived from impact × urgency: purplegriffon.com
  incident categorisation, solarwinds.com ITSM incident management, paessler.com ITIL
  incident management, it-processmaps.com Incident Management.
- **ManageEngine** — incident categorization and prioritization process guidance:
  manageengine.com academy "Incident management processes."
- **Real service-desk SOP / catalogs** — ticket classification categories (Accounts,
  Passwords & Access; Email & Calendar; Printing & Peripherals; Security/Phishing) and
  example items (report a phishing scam, printer jam, request paper/toner):
  helpdesk.sunbum.com IT ticket classification SOP and a U.S. federal lab 12-month service
  desk category breakdown (netl.doe.gov), which shows phishing as a low-volume/high-stakes
  category.
- **Identity & Access (Okta / Microsoft Entra)** — account lockout, MFA reset/re-enroll
  (admin-reset then re-enroll), password reset identity-verification, offboarding
  (suspend account, revoke sessions, remove groups) and IdP↔ITSM sync as an orphaned-access
  problem: support.okta.com MFA reset article, siit.io Okta service desk, tray.ai Freshservice/
  ServiceNow + Okta connectors, moveworks.com account-access integration.
- **Microsoft Intune / MDM** — enrollment failures (stuck on profile install, licensing
  "User Not Found or Licensed"), "DeviceCapReached," Apple ADE re-enrollment, selective
  wipe/retire vs full wipe for BYOD, Conditional Access blocking non-compliant devices,
  RBAC-gated wipe: learn.microsoft.com "troubleshoot device enrollment in Intune" and
  university TeamDynamix KB articles (uillinois.edu, uwindsor.edu).
- **Microsoft Teams / Teams Rooms** — common issues (can't sign in / won't open, messages
  not syncing, audio/video in meetings), firewall/proxy connectivity, check service health
  first, Teams Rooms device vs Pro Management portal: learn.microsoft.com Teams
  troubleshooting + Teams Rooms Pro support, uctoday.com Teams common problems, and a county
  IT portal "Get Support for Microsoft Teams" (support.gwinnettcounty.com).
- **Bank / trading-floor desktop support** — scope of front-office support (Bloomberg,
  Refinitiv/Eikon, Fidessa, OMS/EMS), user access management, hardware deployments, and
  SLA-tracked incident/request handling via ServiceNow; stringent access/audit controls:
  front-office Trade Floor Support Engineer role definitions (greenhouse.io, eire.catsone.com)
  and raritan.com trading-floor case study. These informed the high/high priority defaults
  and the privileged-access, application-access, and SSO items.

*Note: ITIL 4 is a framework, not a fixed category list; the exact taxonomy is per-
organization. The categories and items above represent the common, real-world convergence
across the tools and desks cited, tuned toward an enterprise/bank environment.*
