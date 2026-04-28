# Changelog & Roadmap

This document outlines the history of changes to the Zero Trust Network Architecture project, as well as planned future additions.

## [Unreleased] - Roadmap

We are continuously evolving this architecture to make it more robust, automated, and easier to deploy. The following features and improvements are planned for future releases:

- **Terraform / OpenTofu IaC:** Implement Infrastructure as Code to automatically provision the network segments, Cloudflare rules, and basic server VMs.
- **Deployed Lab Screenshots:** Add visual proof of the architecture running in a real Proxmox/ESXi homelab environment.
- **Wazuh Dashboard Integration:** Include screenshots and sample configurations of custom Wazuh SIEM dashboards showing blocked lateral movement attempts.
- **Ansible Playbooks:** Transition from bash scripts to Ansible for deploying the Wazuh agents and configuring endpoints.
- **Advanced Identity Policies:** Document Entra ID PIM (Privileged Identity Management) for Just-In-Time (JIT) admin access.

## [1.0.0] - Initial Release

### Added
- Complete scaffolding of the Zero Trust SMB architecture.
- Mermaid architecture diagram visualizing trust boundaries.
- Core documentation including `ARCHITECTURE.md` and `THREAT-MODEL.md`.
- Implementation guide for practical lab deployment.
- Simulated configuration templates for pfSense (VLANs), Tailscale (ACLs), and Entra ID (Conditional Access).
- Wazuh agent deployment bash script and a Python-based trust zone health check simulator.
- GitHub Actions workflow for validating JSON and script syntax.
