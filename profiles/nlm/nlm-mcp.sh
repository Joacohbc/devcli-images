#!/usr/bin/env bash
set -euo pipefail

# Asegurar que notebooklm-mcp esté disponible (si ~/.local fue montado como volumen vacío)
if ! command -v notebooklm-mcp >/dev/null 2>&1; then
  uv tool install --python 3.12 --upgrade "notebooklm-py[mcp,headless,markdown]"
fi

NLM_DIR="${NOTEBOOKLM_HOME:-${HOME}/.notebooklm}"
ENV_FILE="${NLM_DIR}/mcp.env"

umask 077
mkdir -p "${NLM_DIR}/profiles/default" "${NLM_DIR}/oauth"

if [ -f "${ENV_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${ENV_FILE}"
  set +a
fi

# Generar un bearer token automáticamente en el primer inicio si no hay auth configurada
if [ -z "${NOTEBOOKLM_MCP_TOKEN:-}" ] && [ -z "${NOTEBOOKLM_MCP_OAUTH_PASSWORD:-}" ]; then
  NOTEBOOKLM_MCP_TOKEN="$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')"
  export NOTEBOOKLM_MCP_TOKEN
  printf 'NOTEBOOKLM_MCP_TOKEN=%s\n' "${NOTEBOOKLM_MCP_TOKEN}" >> "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  echo "==> Bearer token generado automáticamente en ${ENV_FILE}"
fi

export NOTEBOOKLM_MCP_HOST="${NOTEBOOKLM_MCP_HOST:-0.0.0.0}"
export NOTEBOOKLM_MCP_PORT="${NOTEBOOKLM_MCP_PORT:-9420}"
export NOTEBOOKLM_MCP_ALLOW_EXTERNAL_BIND="${NOTEBOOKLM_MCP_ALLOW_EXTERNAL_BIND:-1}"
export NOTEBOOKLM_PROFILE="${NOTEBOOKLM_PROFILE:-default}"

PROFILE_DIR="${NLM_DIR}/profiles/${NOTEBOOKLM_PROFILE}"
mkdir -p "${PROFILE_DIR}"

# Si existe master_token.json pero aún no se generó storage_state.json, inicializar la sesión
if [ -f "${PROFILE_DIR}/master_token.json" ] && [ ! -f "${PROFILE_DIR}/storage_state.json" ]; then
  echo "==> Inicializando sesión desde master_token.json para el perfil '${NOTEBOOKLM_PROFILE}'..."
  notebooklm --profile "${NOTEBOOKLM_PROFILE}" login --master-token-refresh || true
fi

# Si hay token de Cloudflare Tunnel configurado, iniciar cloudflared en segundo plano
if [ -n "${CF_TUNNEL_TOKEN:-}" ] && command -v cloudflared >/dev/null 2>&1; then
  STATE_DIR="${HOME}/.post-script-state"
  mkdir -p "${STATE_DIR}"
  pkill -f "cloudflared tunnel run" 2>/dev/null || true
  nohup cloudflared tunnel run --token "${CF_TUNNEL_TOKEN}" > "${STATE_DIR}/cloudflared-nlm.log" 2>&1 &
  echo "==> Cloudflare Tunnel iniciado (log: ${STATE_DIR}/cloudflared-nlm.log)"
fi

echo "==> Iniciando notebooklm-mcp en ${NOTEBOOKLM_MCP_HOST}:${NOTEBOOKLM_MCP_PORT} (perfil: ${NOTEBOOKLM_PROFILE})"
exec notebooklm-mcp \
  --transport http \
  --host "${NOTEBOOKLM_MCP_HOST}" \
  --port "${NOTEBOOKLM_MCP_PORT}"
