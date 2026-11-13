# Imagen `nlm` — NotebookLM MCP Remote Server

Entorno precompilado que ejecuta el servidor MCP remoto de **[notebooklm-py](https://github.com/teng-lin/notebooklm-py)** (`notebooklm-mcp --transport http`) en el puerto `9420`, listo para exponerse de forma segura mediante **Cloudflare Tunnel** (`cloudflared`) o consumirse localmente por túnel SSH.

- **Imagen en GHCR:** `ghcr.io/joacohbc/nlm:latest`
- **Módulos incluidos:** `github-cli`, `python` (`uv`), `nodejs`, `pnpm`, `cloudflared`
- **Herramientas preinstaladas:** `notebooklm`, `notebooklm-mcp` (`notebooklm-py[mcp,headless,markdown]`)

---

## 🚀 Inicio rápido

### 1. Registrar y descargar la imagen

```bash
devcontainer-cli image create nlm --remote ghcr.io/joacohbc/nlm:latest
devcontainer-cli image pull nlm
```

### 2. Iniciar el contenedor

**Opción A — Contenedor temporal desechable:**

```bash
# Uso interactivo
devcontainer-cli run --image nlm

# Uso desde un agente autónomo
devcontainer-cli agent run --image nlm
```

**Opción B — Inicializar en un proyecto existente:**

```bash
devcontainer-cli workspace init --mode image --image nlm
devcontainer-cli workspace up
```

---

## 🔐 1. Autenticación con Google (NotebookLM)

El servidor MCP opera en modo headless y reutiliza las credenciales almacenadas en `~/.notebooklm/profiles/default/`. Se recomienda utilizar una **cuenta de Google dedicada** y autenticación mediante **Master Token** (que renueva las cookies automáticamente sin necesidad de abrir un navegador).

### Opción A — Generar `master_token.json` en tu máquina local y copiarlo al contenedor (Recomendado)

1. En una máquina con navegador gráfico, genera el token maestro una única vez:
   ```bash
   uvx --from "notebooklm-py[browser,headless]" notebooklm login --master-token --account tu-cuenta@gmail.com
   ```
   Esto creará el archivo `~/.notebooklm/profiles/default/master_token.json`.

2. Copia el archivo dentro del contenedor:
   ```bash
   devcontainer-cli agent exec -- mkdir -p ~/.notebooklm/profiles/default
   devcontainer-cli agent exec -- tee ~/.notebooklm/profiles/default/master_token.json < ~/.notebooklm/profiles/default/master_token.json >/dev/null
   devcontainer-cli agent exec -- chmod 600 ~/.notebooklm/profiles/default/master_token.json
   ```

3. Verifica y genera la sesión inicial (`storage_state.json`):
   ```bash
   devcontainer-cli agent exec -- notebooklm login --master-token-refresh
   devcontainer-cli agent exec -- notebooklm auth check --test
   ```

### Opción B — Obtener `oauth_token` desde el navegador (sin instalar nada en el host)

Si no quieres instalar `notebooklm-py` ni Playwright en tu máquina local, puedes capturar el `oauth_token` de un solo uso directamente desde tu navegador:

1. Abre en tu navegador: `https://accounts.google.com/EmbeddedSetup`
2. Inicia sesión con la cuenta de Google que usas en NotebookLM.
3. Haz clic en **"I agree"** cuando te lo pida *(es normal que la página quede cargando indefinidamente; puedes ignorarlo)*.
4. Abre las DevTools del navegador (`F12`) → **Application** (o **Storage** en Firefox) → **Cookies** → `https://accounts.google.com` y copia el valor de la cookie **`oauth_token`**.
5. Carga el token dentro del contenedor de una de estas dos formas:
   - **Directo por CLI:**
     ```bash
     devcontainer-cli agent exec -- notebooklm --profile default login \
       --master-token \
       --account tu-cuenta@gmail.com \
       --oauth-token "<OAUTH_TOKEN>"
     ```
   - **Desde el asistente interactivo:** ejecutando `~/post-script/custom-setup-nlm.sh` dentro del contenedor e ingresando tu email y el `oauth_token` cuando te lo solicite.
6. Verifica que la sesión quedó activa:
   ```bash
   devcontainer-cli agent exec -- notebooklm --profile default auth check --test
   ```

> **¿Por qué `EmbeddedSetup` y cómo revocar el acceso?**
> - El `oauth_token` de `EmbeddedSetup` es **de un solo uso**: se intercambia una única vez por un `master_token` (`aas_et/`) guardado en `~/.notebooklm/profiles/default/master_token.json`, que permite renovar las cookies de NotebookLM (`storage_state.json`) en modo headless sin volver a abrir un navegador.
> - **Para revocar el acceso más adelante:**
>   1. En **Cuenta de Google → Seguridad → Tus dispositivos** (`https://myaccount.google.com/security`), busca la sesión **"Android device"** asociada y cierra la sesión / quita el acceso *(cambiar la contraseña de Google también invalida los master tokens existentes)*.
>   2. Limpia las credenciales guardadas en el contenedor:
>      ```bash
>      devcontainer-cli agent exec -- notebooklm --profile default auth logout
>      devcontainer-cli agent exec -- rm -f ~/.notebooklm/profiles/default/master_token.json ~/.notebooklm/profiles/default/storage_state.json
>      ```

---

## ⚙️ 2. Configurar el servidor MCP y Cloudflare Tunnel

Al iniciar el contenedor por primera vez, el servicio `nlm-mcp.sh`:
1. Crea `~/.notebooklm/mcp.env` (permisos `0600`) con un `NOTEBOOKLM_MCP_TOKEN` aleatorio de 32 bytes si aún no existe.
2. Inicia `notebooklm-mcp --transport http --host 0.0.0.0 --port 9420`.

Para personalizar la configuración (token Bearer, token de Cloudflare Tunnel u OAuth para `claude.ai` / ChatGPT), entra al contenedor y ejecuta el asistente manual:

```bash
devcontainer-cli ssh
~/post-script/custom-setup-nlm.sh
```

El asistente te permitirá configurar:
- **Puerto HTTP** (por defecto `9420`).
- **Bearer Token (`NOTEBOOKLM_MCP_TOKEN`)**: para clientes como Claude Code, Claude Desktop o Cursor.
- **Cloudflare Tunnel (`CF_TUNNEL_TOKEN`)**: si ingresas el token de tu túnel de Cloudflare, el servicio iniciará automáticamente `cloudflared tunnel run` en segundo plano. En el panel de Cloudflare (**Networking → Tunnels → Routes**), apunta tu subdominio público a `http://localhost:9420` (ruta completa `/`).
- **OAuth auto-alojado (`NOTEBOOKLM_MCP_OAUTH_BASE_URL` y `NOTEBOOKLM_MCP_OAUTH_PASSWORD`)**: opcional, necesario únicamente para conectar desde los conectores web/móvil de **claude.ai** o **ChatGPT (Developer Mode)**, que exigen flujo OAuth en lugar de header Bearer.

Al finalizar, `custom-setup-nlm.sh` reinicia automáticamente tanto `notebooklm-mcp` como `cloudflared` y muestra en pantalla los datos de conexión.

---

## 🔌 3. Conectar clientes MCP

### Conectar desde Claude Code / Claude Desktop (vía Cloudflare Tunnel)

```bash
claude mcp add --transport http notebooklm \
  https://nlm.tudominio.com/mcp \
  --header "Authorization: Bearer <TU_NOTEBOOKLM_MCP_TOKEN>"
```

### Conectar en local sin Cloudflare Tunnel (vía Port Forwarding de `devcontainer-cli`)

Si no deseas exponer un túnel público, puedes reenviar el puerto `9420` desde el contenedor hacia tu máquina local:

```bash
devcontainer-cli agent forward 9420
```

Y registrar el servidor apuntando a `127.0.0.1`:

```bash
claude mcp add --transport http notebooklm \
  http://127.0.0.1:9420/mcp \
  --header "Authorization: Bearer <TU_NOTEBOOKLM_MCP_TOKEN>"
```

Para consultar el `NOTEBOOKLM_MCP_TOKEN` generado automáticamente en cualquier momento:

```bash
devcontainer-cli agent exec -- grep '^NOTEBOOKLM_MCP_TOKEN=' ~/.notebooklm/mcp.env
```

### Conectar desde `claude.ai` (Web / Mobile) o ChatGPT

1. Ejecuta `~/post-script/custom-setup-nlm.sh` y habilita **OAuth auto-alojado** indicando tu URL base pública (sin `/mcp`, por ejemplo `https://nlm.tudominio.com`).
2. En **claude.ai → Settings / Customize → Connectors → Add custom connector**, ingresa la URL con `/mcp`:
   ```text
   https://nlm.tudominio.com/mcp
   ```
3. Cuando solicite autenticación, ingresa la contraseña `NOTEBOOKLM_MCP_OAUTH_PASSWORD` mostrada por el asistente.

---

## 🔍 Diagnóstico y logs

```bash
# Ver logs del servidor MCP HTTP
devcontainer-cli agent exec -- cat ~/.post-script-state/custom-nlm-mcp.sh.log

# Ver logs de Cloudflare Tunnel (si CF_TUNNEL_TOKEN está configurado)
devcontainer-cli agent exec -- cat ~/.post-script-state/cloudflared-nlm.log

# Verificar estado de autenticación contra Google
devcontainer-cli agent exec -- notebooklm auth check --test
```
