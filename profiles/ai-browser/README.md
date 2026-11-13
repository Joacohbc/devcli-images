# Imagen `ai-browser` — Python + Chromium + Browser Harness MCP

Entorno de desarrollo precompilado con **Chromium headless** y **[Browser Harness](https://pypi.org/project/browser-harness/)** preinstalado y configurado como servidor MCP (`stdio`) para agentes de IA (Claude Code, Antigravity y Cursor).

- **Imagen en GHCR:** `ghcr.io/joacohbc/ai-browser:latest`
- **Módulos incluidos:** `github-cli`, `nodejs`, `pnpm`, `python` (`uv`), `chrome` (Chromium multi-arquitectura en `/usr/bin/chromium`)
- **Herramienta preinstalada:** `browser-harness[mcp]` (instalado vía `uv tool` con Python 3.12)

---

## Inicio rápido

### 1. Registrar y descargar la imagen

```bash
devcontainer-cli image create ai-browser --remote ghcr.io/joacohbc/ai-browser:latest
devcontainer-cli image pull ai-browser
```

### 2. Iniciar el contenedor

**Opción A — Contenedor temporal desechable:**

```bash
# Uso interactivo
devcontainer-cli run --image ai-browser

# Uso desde un agente autónomo
devcontainer-cli agent run --image ai-browser
```

**Opción B — Inicializar en un proyecto existente:**

```bash
devcontainer-cli workspace init --mode image --image ai-browser
devcontainer-cli workspace up
```

---

## ¿Qué configura automáticamente al iniciar?

Al arrancar el contenedor por primera vez, el script de inicio (`setup-browser-harness-mcp.sh`) verifica la instalación de `browser-harness`, desactiva la telemetría y genera automáticamente los archivos de configuración MCP en el directorio del workspace:

| Cliente / Agente | Archivo generado | Transporte |
|---|---|---|
| **Claude Code** | `.claude/mcp.json` | `stdio` (`uvx --from browser-harness[mcp] browser-harness-mcp`) |
| **Antigravity** | `.agent/mcp.json` | `stdio` (`uvx --from browser-harness[mcp] browser-harness-mcp`) |
| **Cursor** | `.cursor/mcp.json` | `stdio` (`uvx --from browser-harness[mcp] browser-harness-mcp`) |

De esta manera, cualquier agente que se ejecute dentro del proyecto detecta y utiliza las herramientas de navegación de `browser-harness` sin configuración manual adicional.

---

## Uso dentro del contenedor

### Uso desde CLI

Puedes invocar `browser-harness` directamente dentro del contenedor:

```bash
# Desde una sesión interactiva (devcontainer-cli ssh)
browser-harness --help

# O ejecutando un comando puntual desde el host
devcontainer-cli agent exec -w -- browser-harness --help
```

### Uso de Chromium headless con otras librerías (Playwright / Puppeteer / Selenium)

El binario del sistema se encuentra en `/usr/bin/chromium`. Al no existir servidor gráfico en el contenedor, siempre debe ejecutarse en modo headless (`--headless=new --no-sandbox`).

Si utilizas Playwright, Puppeteer o Selenium en tu propio código, apunta al binario del sistema en lugar de descargar un navegador adicional:

```python
# Ejemplo en Python con Playwright
browser = p.chromium.launch(
    executable_path="/usr/bin/chromium",
     headless=True,
    args=["--no-sandbox"],
)
```

---

## Diagnóstico

Si necesitas verificar el log del script de configuración inicial:

```bash
devcontainer-cli agent exec -- cat ~/.post-script-state/90-custom-setup-browser-harness-mcp.sh.log
```
