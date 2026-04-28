# Configuration Templates

This directory contains simulated configuration files and snippets used in our Zero Trust SMB Architecture. They are designed to be deployed in a home lab or small business environment.

## 📂 Directory Contents

### `/network/pfsense_vlan_template.xml`
This XML snippet outlines the logical interfaces and VLAN definitions for pfSense. 
**Usage:** You can manually replicate these VLAN IDs (10, 20, 30, 40) and subnets in the pfSense GUI under **Interfaces -> Assignments -> VLANs**, or use it as a reference for your infrastructure-as-code automation.

### `/vpn/tailscale_acl.hujson`
This Human JSON (HuJSON) file enforces the principle of least privilege across the Tailscale overlay network.
**Usage:** Copy and paste the contents into your Tailscale Admin Console under the **Access Controls** tab. It defines tags, groups, and explicit allow-rules, ensuring that regular employees cannot access the management VLAN, and IoT devices are fully isolated.

### `/identity/entra_id_ca_policies.json`
This JSON file represents the logic used in an Entra ID (Azure AD) Conditional Access policy.
**Usage:** Due to the complexity of Microsoft Graph API, this is best used as a structural reference. To implement this, navigate to **Entra ID -> Security -> Conditional Access** and create a new policy requiring MFA for all users, excluding your "break-glass" emergency access account.

## ⚠️ Security Warning
Do not blindly copy/paste configurations into a production environment. Ensure you replace any placeholder emails, IPs, or groups with your organization's specific values, and always test changes in a safe environment first.