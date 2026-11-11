#!/usr/bin/env bash
set -euo pipefail

HOSTNAME_INPUT="${1:-}"

# Si no se pasó por parámetro, solicitar interactivamente o usar valor por defecto
if [ -z "${HOSTNAME_INPUT}" ]; then
  read -r -p "Ingrese el nombre de la máquina para Remote Control [rbpi16gb-docker]: " read_name || true
  HOSTNAME_INPUT="${read_name:-rbpi16gb-docker}"
fi

CONFIG_DIR="${HOME}/.gemini/config"
CONFIG_FILE="${CONFIG_DIR}/config.json"

mkdir -p "${CONFIG_DIR}"

if [ -f "${CONFIG_FILE}" ] && command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq \
    --arg host "${HOSTNAME_INPUT}" \
    '.plugins = (.plugins // {}) |
     .plugins.swarm = (.plugins.swarm // {}) |
     .plugins.swarm.enabled = true |
     .userSettings = (.userSettings // {}) |
     .userSettings.cliRemoteControlHostname = $host' \
    "${CONFIG_FILE}" > "${tmp}" && mv "${tmp}" "${CONFIG_FILE}"
else
  cat << EOF > "${CONFIG_FILE}"
{
  "plugins": {
    "swarm": {
      "enabled": true
    }
  },
  "userSettings": {
    "cliRemoteControlHostname": "${HOSTNAME_INPUT}"
  }
}
EOF
fi

echo "==> Antigravity Remote Control configurado con hostname: ${HOSTNAME_INPUT}"
