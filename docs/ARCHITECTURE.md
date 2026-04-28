# Architecture Deep Dive

This document explains the design decisions, trust zones, and data flows that make up the Zero Trust Network Architecture for our simulated SMB environment.

## The Core Philosophy: "Never Trust, Always Verify"
In traditional network security, anything inside the corporate LAN was implicitly trusted. If an attacker breached the perimeter firewall, they could move laterally without restriction.

In this architecture, we **remove implicit trust**. Every request—whether originating from the internet or the internal network—must be authenticated, authorized, and continuously validated before access is granted.

---

## Trust Zones & Segmentation

We achieve micro-segmentation by strictly defining network boundaries and enforcing policies at the overlay (VPN) and underlay (VLAN) levels.

### 1. Internet Edge (Untrusted)
- **Components:** Cloudflare WAF, Public Internet
- **Rationale:** All inbound traffic is inherently hostile. We use Cloudflare to proxy HTTP/HTTPS traffic, absorbing DDoS attacks, filtering malicious payloads (SQLi, XSS), and challenging suspicious bots before they ever reach our physical firewall.

### 2. Network Perimeter (Verification Boundary)
- **Components:** pfSense / OPNsense Firewall
- **Rationale:** The firewall does not grant "trusted" access. It merely routes packets between highly restricted VLANs and drops everything else by default. It acts as the physical/virtual choke point for all east-west and north-south traffic.

### 3. Micro-Segmented VLANs (Underlay)
To prevent lateral movement, the internal network is divided into isolated VLANs:
- **DMZ (VLAN 10):** Hosts internet-facing services. Can only reply to established connections; cannot initiate connections to the internal network.
- **Corporate LAN (VLAN 20):** Endpoint policy enforcement zone. Employee laptops reside here. They cannot talk to each other directly (client isolation) and can only access necessary internal apps.
- **Management VLAN (VLAN 30):** Strictly for administrative access to infrastructure (firewall GUI, hypervisors, SIEM management). Jump boxes or strict VPN ACLs are required to reach this subnet.
- **IoT VLAN (VLAN 40):** Smart TVs, printers, IP cameras. These devices are notoriously insecure. They are isolated, cannot talk to other VLANs, and are blocked from accessing the public internet.

### 4. Identity & Access Control Plane (Zero Trust Overlay)
- **Components:** Entra ID, Tailscale
- **Rationale:** The network is not the primary perimeter; **Identity is the perimeter**. 
  - **Entra ID:** Enforces MFA and Conditional Access (e.g., denying logins from impossible travel locations or unmanaged devices).
  - **Tailscale:** Creates a WireGuard-encrypted mesh network. Even if a user is physically sitting in the office on the Corporate LAN, they must authenticate through Tailscale to reach internal servers. Tailscale ACLs enforce granular access (e.g., HR can only access the HR app, Admins can access SSH).

### 5. Security Operations (Visibility)
- **Components:** Wazuh SIEM & Agent
- **Rationale:** You cannot secure what you cannot see. Wazuh agents are deployed to all endpoints and servers to collect logs, monitor file integrity, and detect anomalies. Syslog is forwarded from the firewall and Entra ID to provide a unified pane of glass.

---

## Data Flow Examples

### Scenario A: Remote Employee Accessing an Internal App
1. Employee opens laptop at a coffee shop.
2. Tailscale client attempts to connect to the overlay network.
3. Entra ID challenges the user for credentials and MFA.
4. Upon successful authentication, Tailscale evaluates the central ACL policy.
5. The ACL allows the user to access `10.0.10.5:443` (Internal App) but blocks access to `10.0.30.0/24` (Management VLAN).
6. Traffic flows encrypted directly to the app server.

### Scenario B: Attacker Compromises an IoT Printer
1. Attacker exploits a zero-day in a smart printer on VLAN 40.
2. Attacker attempts to scan the local subnet.
3. pfSense firewall drops the traffic because IoT VLAN has a strict "Deny All" outbound rule.
4. Wazuh detects the anomalous port scanning via network flow logs and raises a critical alert.
5. The threat is contained entirely within the isolated IoT segment.

---

## Lessons Learned & Design Decisions

When building this architecture, I made several deliberate choices to optimize for an SMB environment:

- **Tailscale over Traditional IPsec/SSL VPNs:** I chose Tailscale because managing complex firewall rules, NAT traversals, and certificate authorities for a traditional VPN is a massive overhead for a small team. Tailscale uses WireGuard under the hood, is instantly deployable, natively integrates with Entra ID, and handles NAT traversal seamlessly. This allowed me to focus purely on enforcing least privilege rather than wrestling with network connectivity.
- **Wazuh over Splunk:** While Splunk is the industry heavyweight, its pricing model is prohibitive for most SMBs. Wazuh gives us a free, open-source XDR and SIEM solution out-of-the-box. More importantly, the Wazuh agent handles file integrity monitoring, vulnerability detection, and log forwarding all in one, which drastically reduces the endpoint footprint.
- **Micro-segmentation from Day 1:** Rather than a flat network, creating distinct DMZ, CorpLAN, Mgmt, and IoT VLANs upfront saves monumental headaches later. IoT devices are notoriously chatty and insecure, so throwing them into a black-hole VLAN (VLAN 40) is one of the highest ROI security controls an SMB can implement.
