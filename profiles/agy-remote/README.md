# Imagen `agy-remote` — Antigravity CLI Remote Session

Entorno precompilado diseñado para ejecutar sesiones remotas persistentes de **Antigravity CLI** (`agy remote-control serve`) como servicio en segundo plano, con soporte integrado para **Cloudflare Tunnel** (`cloudflared`).

- **Imagen en GHCR:** `ghcr.io/joacohbc/agy-remote:latest`
- **Módulos incluidos:** `github-cli`, `python` (`uv`), `sqlite`, `nodejs`, `pnpm`, `antigravity-cli` (`agy`), `cloudflared`

---

## Inicio rápido

### 1. Registrar y descargar la imagen

```bash
devcontainer-cli image create agy-remote --remote ghcr.io/joacohbc/agy-remote:latest
devcontainer-cli image pull agy-remote
```

### 2. Iniciar el contenedor

**Opción A — Contenedor temporal desechable:**

```bash
# Uso interactivo
devcontainer-cli run --image agy-remote

# Uso desde un agente autónomo
devcontainer-cli agent run --image agy-remote
```

**Opción B — Inicializar en un proyecto existente:**

```bash
devcontainer-cli workspace init --mode image --image agy-remote
devcontainer-cli workspace up
```

---

## Configuración y puesta en marcha

### 1. Configurar el nombre del host para Remote Control

Dentro del contenedor se incluye un asistente manual en `~/post-script/custom-setup-remote-name.sh` que habilita el plugin `swarm` y define `cliRemoteControlHostname` en `~/.gemini/config/config.json` (persistido en el volumen compartido `devcontainer-shared-config`).

Puedes ejecutarlo de forma interactiva o pasando el nombre directamente como argumento:

```bash
# Pasando el nombre por parámetro desde el host
devcontainer-cli agent exec -- ~/post-script/custom-setup-remote-name.sh mi-servidor-remoto

# O de forma interactiva entrando por SSH
devcontainer-cli ssh
~/post-script/custom-setup-remote-name.sh
```

### 2. Autenticación de Antigravity CLI

Si aún no has iniciado sesión con `agy` en el volumen compartido de configuración (`~/.gemini` / `~/.antigravity`), inicia sesión una única vez dentro del contenedor:

```bash
devcontainer-cli ssh
agy auth login
```

### 3. Servicio `agy remote-control serve`

El script de servicio (`agy-remote.sh`) se ejecuta automáticamente en segundo plano cada vez que el contenedor inicia:

```bash
agy remote-control serve
```

Si cambiaste el nombre del host o acabas de autenticarte, puedes reiniciar el contenedor o relanzar el servicio:

```bash
devcontainer-cli workspace restart
```

---

## Diagnóstico y logs

Para consultar la salida del servicio `agy remote-control serve`:

```bash
devcontainer-cli agent exec -- cat ~/.post-script-state/custom-agy-remote.sh.log
```

Para seguir los logs en tiempo real dentro del contenedor:

```bash
devcontainer-cli agent exec -- tail -f ~/.post-script-state/custom-agy-remote.sh.log
```
