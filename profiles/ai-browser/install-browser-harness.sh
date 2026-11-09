#!/usr/bin/env bash
set -euo pipefail

# Pre-instalar browser-harness con soporte MCP en la imagen durante el docker build
uv tool install --python 3.12 --upgrade "browser-harness[mcp]"
browser-harness telemetry disable 2>/dev/null || true
