# Implementation Guide

This guide provides a step-by-step roadmap to deploying the simulated Zero Trust Network Architecture in a real-world lab or SMB environment.

## Prerequisites
- A dedicated hardware appliance or VM for pfSense/OPNsense.
- A managed switch and Wi-Fi access point capable of VLAN tagging (802.1Q).
- An Entra ID (Azure AD) tenant (Free tier is okay, Premium P1 is required for Conditional Access).
- A Tailscale account.
- A Linux VM for the Wazuh Manager (Ubuntu 22.04 recommended).
- A domain name managed via Cloudflare.

---

## Phase 1: Identity & Access Management (The Control Plane)

1. **Setup Entra ID:**
   - Create user accounts and groups (`group:admins`, `group:employees`).
   - Enable Multi-Factor Authentication (MFA) for all users.
   - Import the `configs/identity/entra_id_ca_policies.json` logic into your Conditional Access policies to enforce MFA and device compliance.

2. **Configure Tailscale:**
   - Sign up for Tailscale and link your Entra ID tenant as the Identity Provider (SSO).
   - Navigate to the Tailscale admin console -> Access Controls.
   - Paste the contents of `configs/vpn/tailscale_acl.hujson`.
   - Install the Tailscale client on administrator and employee devices.

---

## Phase 2: Network Perimeter & Micro-segmentation (The Underlay)

1. **Deploy pfSense:**
   - Install pfSense on your edge device.
   - Configure the WAN interface to connect to your ISP.
   - Configure the LAN interface as your trunk port to your managed switch.

2. **Configure VLANs:**
   - Reference `configs/network/pfsense_vlan_template.xml`.
   - In pfSense: `Interfaces > Assignments > VLANs`.
   - Create VLAN 10 (DMZ), VLAN 20 (CorpLAN), VLAN 30 (Mgmt), and VLAN 40 (IoT).
   - Assign IP subnets and enable DHCP for each (except perhaps Mgmt/DMZ which may be static).

3. **Implement Strict Firewall Rules:**
   - By default, pfSense denies all cross-VLAN traffic.
   - **IoT VLAN:** Add a rule to block ALL outbound traffic (no internet, no internal access).
   - **CorpLAN:** Allow outbound HTTP/HTTPS to the internet. Block access to DMZ, Mgmt, and IoT.
   - **Mgmt VLAN:** Allow access to all other VLANs for administration.
   - **DMZ:** Allow inbound HTTP/HTTPS from Cloudflare IPs only. Block initiation to CorpLAN and Mgmt.

---

## Phase 3: Edge Security

1. **Configure Cloudflare:**
   - Point your domain's nameservers to Cloudflare.
   - Set up DNS A-records for your public-facing services (e.g., `app.yourdomain.com`) pointing to your pfSense WAN IP.
   - Ensure the proxy status (orange cloud) is ON.
   - In pfSense, restrict port 443 NAT forwarding on the WAN interface to *only* accept connections from Cloudflare's published IP ranges.

---

## Phase 4: Security Operations & Visibility

1. **Deploy Wazuh Manager:**
   - Install the Wazuh Manager on a dedicated server in the Management VLAN (or a secure cloud VPC).
   - Ensure port 1514 (agent comms) and 443 (dashboard) are open.

2. **Deploy Wazuh Agents:**
   - On your endpoints and servers, deploy the agent using the provided script.
   - Edit the `WAZUH_MANAGER_IP` in `scripts/deploy_wazuh_agent.sh`.
   - Run the script: `sudo ./deploy_wazuh_agent.sh`
   - Verify agents appear in the Wazuh dashboard.

3. **Configure Log Forwarding:**
   - In pfSense, go to `Status > System Logs > Settings`.
   - Enable remote logging and point it to the Wazuh Manager IP on port 514 (Syslog).

---

## Phase 5: Verification & Auditing

1. **Run Health Checks:**
   - Execute the Python simulation script to verify that your logical boundaries match your expectations.
   - Run: `python3 scripts/trust_zone_health_check.py`
   - If using a live lab, adapt the script to perform real `ping` or `nc` commands across your VLANs to ensure the firewall is blocking unauthorized flows.

2. **Simulate a Breach (Red Teaming):**
   - Connect a laptop to the IoT VLAN and try to ping the pfSense management IP. (It should fail).
   - Try to SSH into a DMZ server from a regular employee Tailscale account. (It should be blocked by Tailscale ACLs).

By following these steps, you have successfully migrated from a flat, implicitly trusted network to a robust, micro-segmented Zero Trust Architecture.