# devcli-images

Catálogo de imágenes de devcontainers personalizadas y precompiladas (`linux/amd64` y `linux/arm64`), publicadas en GitHub Container Registry (GHCR) y listas para usar directamente con [`devcontainer-cli`](https://github.com/Joacohbc/my-devcontainer-installer).

Cada perfil en `profiles/<id>/` define sus módulos, scripts de ciclo de vida (`build`, `start`, `service`, `manual`) y se compila automáticamente mediante GitHub Actions.

---

## Imágenes disponibles

| Perfil | Imagen GHCR | Descripción | Guía |
|---|---|---|---|
| **`ai-browser`** | `ghcr.io/joacohbc/ai-browser:latest` | Python (`uv`), Node.js, pnpm, Chromium headless, GitHub CLI y **Browser Harness MCP** preconfigurado (`.claude`, `.agent`, `.cursor`). | [Ver guía](profiles/ai-browser/README.md) |
| **`agy-remote`** | `ghcr.io/joacohbc/agy-remote:latest` | Python (`uv`), SQLite, Node.js, pnpm, GitHub CLI, **Antigravity CLI** y Cloudflared para sesiones remotas (`agy remote-control serve`). | [Ver guía](profiles/agy-remote/README.md) |
| **`nlm`** | `ghcr.io/joacohbc/nlm:latest` | Python (`uv`), Node.js, pnpm, GitHub CLI, Cloudflared y servidor **NotebookLM MCP** remoto (`notebooklm-py[mcp,headless,markdown]`) en HTTP (`:9420`). | [Ver guía](profiles/nlm/README.md) |

---

## Uso rápido con `devcontainer-cli`

Reemplaza `<id>` por cualquiera de los perfiles de la tabla anterior (`ai-browser`, `agy-remote` o `nlm`):

### 1. Registrar y descargar la imagen (`image create` & `image pull`)

```bash
# Registrar la definición de imagen remota
devcontainer-cli image create <id> --remote ghcr.io/joacohbc/<id>:latest

# Descargar la imagen y verificar el contrato de compatibilidad
devcontainer-cli image pull <id>
```

### 2. Iniciar un contenedor desechable (`run --image`)

```bash
# Iniciar contenedor temporal interactivo
devcontainer-cli run --image <id>

# Para agentes autónomos de IA
devcontainer-cli agent run --image <id>
```

### 3. Usar en un proyecto de trabajo (`workspace init`)

```bash
# Inicializar el proyecto actual en modo imagen
devcontainer-cli workspace init --mode image --image <id>

# Levantar el entorno de desarrollo
devcontainer-cli workspace up
```

---

## Agregar una nueva imagen

1. Crea la carpeta `profiles/<id>/profile.yml` (junto con sus scripts `.sh` y su `README.md`):
   ```yaml
   id: mi-imagen
   label: "Mi Entorno Personalizado"
   modules:
     - github-cli
     - nodejs
     - pnpm
     - python
   ```
2. Ejecuta `git push`. GitHub Actions la compilará para `amd64`/`arm64` y la publicará automáticamente en:
   ```bash
   ghcr.io/joacohbc/mi-imagen:latest
   ```
