# Threat Model

This document outlines the threat modeling for our Zero Trust Network Architecture using the STRIDE methodology. It identifies potential attack vectors and explains the mitigations implemented to protect the environment.

## Overview
In a Zero Trust Architecture, we assume that the network is always hostile and that internal and external threats exist. Our goal is to minimize the blast radius of any successful compromise.

## STRIDE Analysis

| Threat Type | Description in our Context | Mitigations in Place |
|-------------|----------------------------|----------------------|
| **Spoofing** | An attacker attempts to spoof an IP address or user identity to gain access to internal resources. | - **Identity:** Entra ID enforces MFA, rendering stolen passwords useless without the second factor.<br>- **Network:** Tailscale enforces cryptographic identity (WireGuard keypairs) linked to the IdP. IP spoofing at the underlay level is blocked by pfSense anti-spoofing rules. |
| **Tampering** | An attacker modifies data in transit or alters configuration files on endpoints. | - **In Transit:** All overlay traffic is end-to-end encrypted via Tailscale/WireGuard. External web traffic is enforced over HTTPS via Cloudflare.<br>- **At Rest:** Wazuh File Integrity Monitoring (FIM) detects unauthorized changes to critical files and configurations on servers and endpoints. |
| **Repudiation** | A malicious insider performs unauthorized actions and denies doing so. | - **Logging:** Centralized log aggregation via Wazuh. Syslog is sent from pfSense, endpoints, and Entra ID. Logs are immutable once ingested by the SIEM.<br>- **Identity:** Actions are tied to heavily authenticated identities, not just IP addresses. |
| **Information Disclosure** | Sensitive data is intercepted or accessed by unauthorized users. | - **Network:** VLAN isolation prevents packet sniffing across broadcast domains.<br>- **Access:** Least privilege Tailscale ACLs ensure users only have access to the specific apps they need. IoT devices cannot query internal DNS or corporate servers. |
| **Denial of Service** | An attacker floods the network or services to disrupt business operations. | - **Edge:** Cloudflare absorbs volumetric DDoS attacks before they hit the pfSense firewall.<br>- **Internal:** Rate limiting and strict stateful firewall rules prevent internal broadcast storms or localized DoS from compromised devices (e.g., IoT). |
| **Elevation of Privilege** | An attacker gains basic user access and attempts to escalate to an admin role or access the management plane. | - **Micro-segmentation:** Regular users (and compromised endpoints) have no network path to the Management VLAN (VLAN 30).<br>- **Access:** SSH/RDP requires explicit Tailscale tag ownership (`tag:mgmt`) which is only granted to the `group:admins`. Entra ID PIM (Privileged Identity Management) can be used for just-in-time admin access. |

## Key Attack Surfaces & Defenses

### 1. Phishing & Credential Theft
- **Risk:** High. The most common entry point.
- **Defense:** Entra ID Conditional Access requires phishing-resistant MFA (e.g., FIDO2 keys or Authenticator App with number matching). Even with credentials, the attacker cannot connect to the VPN without the enrolled device or fulfilling CA policies.

### 2. Compromised IoT Device
- **Risk:** Medium. IoT devices are rarely updated and easily exploited.
- **Defense:** IoT devices are placed on VLAN 40. The pfSense firewall explicitly drops all traffic originating from VLAN 40 destined for VLAN 10, 20, 30, and the Internet. The device is effectively quarantined.

### 3. Supply Chain Attack (Compromised Endpoint Software)
- **Risk:** High. An employee installs malicious software that attempts lateral movement.
- **Defense:** Client isolation on the Corporate LAN prevents the malware from scanning other employee laptops. Tailscale ACLs prevent the device from accessing the management plane. Wazuh agent detects malicious processes or registry changes and alerts SecOps.