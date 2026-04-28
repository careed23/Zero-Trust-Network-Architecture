#!/bin/bash
# 
# Wazuh Agent Deployment Script
# 
# This script deploys the Wazuh SIEM agent to an endpoint.
# In a Zero Trust environment, endpoints are assumed compromised until proven otherwise.
# We require constant telemetry (logs, FIM, vulnerability scanning) to evaluate the 
# trust state of the device before granting access to resources.
#

set -e # Exit immediately if a command exits with a non-zero status

# Configuration - ideally passed via environment variables in production
WAZUH_MANAGER_IP=${WAZUH_MANAGER_IP:-"10.0.30.50"}
WAZUH_AGENT_VERSION="4.7.1-1"

echo "[*] Starting Wazuh Agent Deployment..."

# Security Rationale: We verify the integrity of the downloaded package via GPG keys.
# We cannot trust a binary just because it comes from an HTTPS source. "Never Trust, Always Verify."
echo "[*] Importing Wazuh GPG key..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg

# Security Rationale: Adding the official repository using the verified keyring.
echo "[*] Adding Wazuh repository..."
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list > /dev/null

echo "[*] Updating apt cache..."
apt-get update -q

# Security Rationale: Pinning the version ensures deterministic builds and prevents 
# malicious/accidental downgrades or unverified upgrades.
echo "[*] Installing Wazuh Agent version $WAZUH_AGENT_VERSION..."
env WAZUH_MANAGER="$WAZUH_MANAGER_IP" apt-get install -y wazuh-agent="$WAZUH_AGENT_VERSION"

# Security Rationale: We drop permissions or run services as least privileged users where possible.
# Wazuh configures itself automatically, but we ensure the service starts securely.
echo "[*] Enabling and starting the Wazuh agent service..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

echo "[+] Wazuh agent installed and reporting to $WAZUH_MANAGER_IP"
echo "[+] Endpoint telemetry is now active for continuous trust evaluation."