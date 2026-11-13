#!/usr/bin/env bash
set -euo pipefail

NLM_DIR="${NOTEBOOKLM_HOME:-${HOME}/.notebooklm}"
ENV_FILE="${NLM_DIR}/mcp.env"
PROFILE_NAME="${NOTEBOOKLM_PROFILE:-default}"
PROFILE_DIR="${NLM_DIR}/profiles/${PROFILE_NAME}"

umask 077
mkdir -p "${PROFILE_DIR}" "${NLM_DIR}/oauth"

if [ -f "${ENV_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${ENV_FILE}"
  set +a
fi

gen_secret() {
  python3 -c "import secrets; print(secrets.token_urlsafe($1))"
}

CURRENT_TOKEN="${NOTEBOOKLM_MCP_TOKEN:-$(gen_secret 32)}"
CURRENT_PORT="${NOTEBOOKLM_MCP_PORT:-9420}"
CURRENT_CF_TOKEN="${CF_TUNNEL_TOKEN:-}"
CURRENT_OAUTH_URL="${NOTEBOOKLM_MCP_OAUTH_BASE_URL:-}"
CURRENT_OAUTH_PW="${NOTEBOOKLM_MCP_OAUTH_PASSWORD:-}"

echo "=== Configuración de NotebookLM MCP Remote Server ==="
echo ""

read -r -p "Puerto HTTP para notebooklm-mcp [${CURRENT_PORT}]: " input_port || true
MCP_PORT="${input_port:-${CURRENT_PORT}}"

read -r -p "Bearer token (Enter para mantener el actual o 'new' para regenerar): " input_token || true
if [ "${input_token}" = "new" ]; then
  MCP_TOKEN="$(gen_secret 32)"
elif [ -n "${input_token}" ]; then
  MCP_TOKEN="${input_token}"
else
  MCP_TOKEN="${CURRENT_TOKEN}"
fi

read -r -p "Token de Cloudflare Tunnel (CF_TUNNEL_TOKEN, opcional — apuntar ruta a http://localhost:${MCP_PORT}): " input_cf || true
CF_TOKEN="${input_cf:-${CURRENT_CF_TOKEN}}"

read -r -p "¿Habilitar OAuth auto-alojado para claude.ai / ChatGPT? [y/N]: " want_oauth || true
OAUTH_URL=""
OAUTH_PW=""
TRUST_PROXY=""
case "${want_oauth}" in
  y|Y|yes|YES)
    read -r -p "URL pública HTTPS base (sin /mcp, ej. https://nlm.tudominio.com) [${CURRENT_OAUTH_URL}]: " input_url || true
    OAUTH_URL="${input_url:-${CURRENT_OAUTH_URL}}"
    OAUTH_URL="${OAUTH_URL%/}"
    DEFAULT_PW="${CURRENT_OAUTH_PW:-$(gen_secret 24)}"
    read -r -p "Contraseña OAuth (>=16 caracteres, Enter para usar generada/actual): " input_pw || true
    OAUTH_PW="${input_pw:-${DEFAULT_PW}}"
    if [ -n "${CF_TOKEN}" ]; then
      TRUST_PROXY="1"
    fi
    ;;
  *)
    if [ -n "${CURRENT_OAUTH_URL}" ] && [ -n "${CURRENT_OAUTH_PW}" ]; then
      read -r -p "¿Conservar la configuración OAuth existente (${CURRENT_OAUTH_URL})? [Y/n]: " keep_oauth || true
      case "${keep_oauth}" in
        n|N|no|NO) ;;
        *)
          OAUTH_URL="${CURRENT_OAUTH_URL}"
          OAUTH_PW="${CURRENT_OAUTH_PW}"
          TRUST_PROXY="${NOTEBOOKLM_MCP_TRUST_PROXY:-}"
          ;;
      esac
    fi
    ;;
esac

{
  printf '# Generado por setup-nlm.sh. Tratar como secreto (0600).\n'
  printf 'NOTEBOOKLM_PROFILE=%s\n' "${PROFILE_NAME}"
  printf 'NOTEBOOKLM_MCP_HOST=0.0.0.0\n'
  printf 'NOTEBOOKLM_MCP_PORT=%s\n' "${MCP_PORT}"
  printf 'NOTEBOOKLM_MCP_ALLOW_EXTERNAL_BIND=1\n'
  printf 'NOTEBOOKLM_MCP_TOKEN=%s\n' "${MCP_TOKEN}"
  printf 'CF_TUNNEL_TOKEN=%s\n' "${CF_TOKEN}"
  if [ -n "${OAUTH_URL}" ] && [ -n "${OAUTH_PW}" ]; then
    printf 'NOTEBOOKLM_MCP_OAUTH_BASE_URL=%s\n' "${OAUTH_URL}"
    printf 'NOTEBOOKLM_MCP_OAUTH_PASSWORD=%s\n' "${OAUTH_PW}"
    printf 'NOTEBOOKLM_MCP_OAUTH_STATE_PATH=%s/oauth/oauth_state.json\n' "${NLM_DIR}"
    if [ -n "${TRUST_PROXY}" ]; then
      printf 'NOTEBOOKLM_MCP_TRUST_PROXY=1\n'
    fi
  fi
} > "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

echo ""
echo "==> Configuración guardada en ${ENV_FILE}"

if [ ! -f "${PROFILE_DIR}/master_token.json" ] && [ ! -f "${PROFILE_DIR}/storage_state.json" ]; then
  echo ""
  echo "No se encontraron credenciales de Google en ${PROFILE_DIR}."
  read -r -p "¿Desea inicializar master_token ahora con un oauth_token? [y/N]: " want_login || true
  case "${want_login}" in
    y|Y|yes|YES)
      read -r -p "Cuenta de Google (email): " google_email || true
      read -r -p "OAuth token de un solo uso (--oauth-token): " google_oauth_token || true
      if [ -n "${google_email}" ] && [ -n "${google_oauth_token}" ]; then
        notebooklm --profile "${PROFILE_NAME}" login --master-token --account "${google_email}" --oauth-token "${google_oauth_token}"
      fi
      ;;
    *)
      echo "Puede copiar su master_token.json o storage_state.json a: ${PROFILE_DIR}/"
      ;;
  esac
fi

# Reiniciar el servicio en segundo plano para aplicar los cambios
STATE_DIR="${HOME}/.post-script-state"
mkdir -p "${STATE_DIR}"
pkill -f "notebooklm-mcp" 2>/dev/null || true
pkill -f "cloudflared tunnel run" 2>/dev/null || true

SERVICE_SCRIPT="${HOME}/post-script/services.d/custom-nlm-mcp.sh"
if [ -x "${SERVICE_SCRIPT}" ]; then
  nohup bash -l "${SERVICE_SCRIPT}" > "${STATE_DIR}/custom-nlm-mcp.sh.log" 2>&1 &
  echo "==> Servicio notebooklm-mcp reiniciado (log: ${STATE_DIR}/custom-nlm-mcp.sh.log)"
fi

echo ""
echo "=== Resumen de conexión ==="
echo "  Puerto local:  http://127.0.0.1:${MCP_PORT}/mcp"
echo "  Bearer Token:  ${MCP_TOKEN}"
if [ -n "${OAUTH_URL}" ]; then
  echo "  URL pública:   ${OAUTH_URL}/mcp"
  echo "  OAuth Pass:    ${OAUTH_PW}"
fi
echo ""
echo "Para conectar desde Claude Code:"
echo "  claude mcp add --transport http notebooklm ${OAUTH_URL:-http://127.0.0.1:${MCP_PORT}}/mcp --header \"Authorization: Bearer ${MCP_TOKEN}\""
