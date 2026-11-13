#!/usr/bin/env bash
set -euo pipefail

# Pre-instalar notebooklm-py con soporte MCP, autenticación headless (master-token) y markdown durante el docker build
uv tool install --python 3.12 --upgrade "notebooklm-py[mcp,headless,markdown]"
