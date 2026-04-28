<div align="center">
  <h1>Zero Trust Network Architecture for SMB</h1>
  
  <p>
    <img src="https://img.shields.io/github/actions/workflow/status/careed23/Zero-Trust-Network-Architecture/validate-configs.yml?branch=main" alt="GitHub workflow status" />
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
  </p>
</div>

A comprehensive, production-inspired repository demonstrating how to implement a Zero Trust Network Architecture (ZTNA) for a Small-to-Medium Business (SMB). This project is designed as a portfolio piece to showcase real enterprise-grade security thinking, focusing on the principle of **"Never Trust, Always Verify."**

## 🎯 Project Goals
- **Eliminate the Traditional Perimeter:** Shift from a "trusted internal network" model to micro-segmentation and identity-driven access.
- **Enforce Least Privilege:** Use strict ACLs and Conditional Access to ensure users and devices only access what they explicitly need.
- **Assume Breach:** Design the architecture under the assumption that threat actors may already be inside the network.
- **Continuous Monitoring:** Ensure every authentication request and network flow is logged and analyzed for anomalous behavior.

## 🏗️ Architecture Overview

The architecture is divided into distinct zones, enforcing strict boundaries at every layer. 
We leverage open-source or affordable solutions that an SMB can realistically deploy.

### High-Level Topology

```mermaid
graph TD
    classDef untrusted fill:#fcdbdb,stroke:#c00000,stroke-width:2px,color:#000;
    classDef edge fill:#fff4ce,stroke:#d6b656,stroke-width:2px,stroke-dasharray: 5 5,color:#000;
    classDef verify fill:#e1d5e7,stroke:#9673a6,stroke-width:2px,color:#000;
    classDef secure fill:#d5e8d4,stroke:#82b366,stroke-width:2px,color:#000;
    classDef siem fill:#dae8fc,stroke:#6c8ebf,stroke-width:2px,color:#000;

    Internet((Internet)):::untrusted
    RemoteUser["Remote Employee"]:::untrusted
    
    subgraph IdentityZone ["Identity & Access (Zero Trust Control Plane)"]
        EntraID["Entra ID (Azure AD)<br/>Identity & MFA Enforcer"]:::verify
        Tailscale["Tailscale / WireGuard<br/>ZTNA Overlay"]:::verify
    end

    subgraph EdgeZone ["Internet Edge"]
        CF["Cloudflare WAF<br/>DDoS & Bot Mitigation"]:::edge
    end

    subgraph NetworkPerimeter ["Local Network Boundaries"]
        FW["pfSense / OPNsense Firewall<br/>VLAN Routing & ACLs"]:::verify
    end

    subgraph Segments ["Micro-Segmented Environment"]
        DMZ["DMZ VLAN<br/>Public Services"]:::secure
        CorpLAN["Corporate VLAN<br/>Endpoint Policy Zone"]:::secure
        MgmtVLAN["Management VLAN<br/>Strict Access"]:::secure
        IoTVLAN["IoT VLAN<br/>Isolated, No Internet out"]:::untrusted
    end

    subgraph SecOps ["Security Operations"]
        Wazuh["Wazuh SIEM<br/>Log Aggregation & XDR"]:::siem
    end

    %% Data flows
    RemoteUser -->|1. Auth & MFA| EntraID
    RemoteUser -->|2. Web Traffic| CF
    RemoteUser -->|3. Overlay Tunnel| Tailscale

    CF -->|Filtered HTTP/S| DMZ
    
    Tailscale -.->|Authorized Traffic Only<br/>'Never Trust, Always Verify'| CorpLAN
    Tailscale -.->|Admin Only| MgmtVLAN

    FW --- DMZ
    FW --- CorpLAN
    FW --- MgmtVLAN
    FW --- IoTVLAN

    CorpLAN -.->|Device Telemetry| Wazuh
    FW -.->|Syslog / NetFlow| Wazuh
    EntraID -.->|Audit Logs| Wazuh
```

*(If the Mermaid diagram above does not render, please view the [Architecture Diagram Image](docs/diagrams/zero-trust-architecture.png))*

## 🛠️ Technology Stack
- **Internet Edge:** Cloudflare (WAF, DDoS Protection, Bot Management)
- **Firewall & Routing:** pfSense / OPNsense (VLAN Segmentation, L4/L7 Filtering)
- **Identity Provider (IdP):** Entra ID / Azure AD (SSO, Conditional Access, MFA)
- **Zero Trust Network Access (ZTNA):** Tailscale (WireGuard-based Overlay, Micro-segmentation)
- **Security Operations (SIEM/XDR):** Wazuh (Log Aggregation, FIM, Endpoint Telemetry)

## 📂 Repository Structure

- [`docs/`](docs/) - Core architectural documentation.
  - [Architecture Deep Dive](docs/ARCHITECTURE.md)
  - [Threat Model](docs/THREAT-MODEL.md)
  - [Implementation Guide](docs/IMPLEMENTATION-GUIDE.md)
- [`configs/`](configs/) - Configuration templates demonstrating least privilege.
  - `network/` - pfSense VLAN templates
  - `identity/` - Entra ID Conditional Access JSON exports
  - `vpn/` - Tailscale ACL policies
- [`scripts/`](scripts/) - Automation and deployment scripts.
  - `deploy_wazuh_agent.sh` - Secure agent deployment.
  - `trust_zone_health_check.py` - Auditing script to verify network isolation.

## 🚀 Getting Started

If you want to review the thought process behind this architecture:
1. Start with [ARCHITECTURE.md](docs/ARCHITECTURE.md) to understand the design decisions.
2. Review [THREAT-MODEL.md](docs/THREAT-MODEL.md) to see how we defend against specific attack vectors.
3. Dive into the `configs/` and `scripts/` directories to see how the concepts are applied practically.
4. Read [IMPLEMENTATION-GUIDE.md](docs/IMPLEMENTATION-GUIDE.md) if you want to deploy this in a home lab or small business setting.