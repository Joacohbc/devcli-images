#!/usr/bin/env bash
set -euo pipefail

# Asegurar que browser-harness esté disponible (si ~/.local fue montado como volumen vacío)
if ! command -v browser-harness >/dev/null 2>&1; then
  uv tool install --python 3.12 --upgrade "browser-harness[mcp]"
fi
browser-harness telemetry disable 2>/dev/null || true

WORKSPACE_DIR="${WORKSPACE:-/workspaces}"

# 1. Configuración MCP para Claude (.claude/mcp.json)
mkdir -p "${WORKSPACE_DIR}/.claude"
cat << 'EOF' > "${WORKSPACE_DIR}/.claude/mcp.json"
{
  "mcpServers": {
    "browser-harness": {
      "command": "uvx",
      "args": ["--from", "browser-harness[mcp]", "browser-harness-mcp"]
    }
  }
}
EOF

# 2. Configuración MCP para Antigravity (.agent/mcp.json)
mkdir -p "${WORKSPACE_DIR}/.agent"
cat << 'EOF' > "${WORKSPACE_DIR}/.agent/mcp.json"
{
  "mcpServers": {
    "browser-harness": {
      "command": "uvx",
      "args": ["--from", "browser-harness[mcp]", "browser-harness-mcp"]
    }
  }
}
EOF

# 3. Configuración MCP para Cursor (.cursor/mcp.json)
mkdir -p "${WORKSPACE_DIR}/.cursor"
cat << 'EOF' > "${WORKSPACE_DIR}/.cursor/mcp.json"
{
  "mcpServers": {
    "browser-harness": {
      "type": "stdio",
      "command": "uvx",
      "args": ["--from", "browser-harness[mcp]", "browser-harness-mcp"]
    }
  }
}
EOF
