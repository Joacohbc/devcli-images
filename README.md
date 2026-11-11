# devcli-images

Imágenes de devcontainers personalizadas precompiladas para usar directamente con `devcontainer-cli`.

---

## ⚡ Uso rápido con `devcontainer-cli`

### 1. Registrar y descargar la imagen (`image create` & `image pull`)

Para registrar una definición de imagen remota y verificar su compatibilidad en el daemon local:

```bash
# Registrar la definición de imagen remota
devcontainer-cli image create agy-remote --remote ghcr.io/joacohbc/agy-remote:latest

# Descargar la imagen y verificar el contrato de compatibilidad
devcontainer-cli image pull agy-remote
```

*(También se puede registrar `ai-browser` apuntando a `ghcr.io/joacohbc/ai-browser:latest`).*

### 2. Iniciar un contenedor desechable (`run --image`)

Para iniciar un entorno temporal sin generar archivos de proyecto:

```bash
# Iniciar contenedor temporal con la imagen definida
devcontainer-cli run --image agy-remote

# Para agentes autónomos de IA
devcontainer-cli agent run --image agy-remote
```

### 3. Usar en un proyecto de trabajo (`workspace init`)

Para utilizar la imagen dentro de un directorio de proyecto existente:

```bash
# Inicializar el proyecto en modo imagen
devcontainer-cli workspace init --mode image --image agy-remote

# Iniciar el entorno de desarrollo
devcontainer-cli workspace up
```

---

## 📦 Imágenes disponibles

| Imagen | Contenido |
|---|---|
| `ghcr.io/joacohbc/ai-browser:latest` | Python, uv, Node.js, pnpm, Chromium headless, GitHub CLI y Browser Harness con MCP preconfigurado (.claude, .agent, .cursor). |
| `ghcr.io/joacohbc/agy-remote:latest` | Python, SQLite, Node.js, pnpm, GitHub CLI, Antigravity CLI y Cloudflared para sesiones remotas de servicio (`agy remote-control serve`). |

---

## 🛠️ Agregar una nueva imagen

1. Cree la carpeta en `profiles/<id>/profile.yml`:
   ```yaml
   id: mi-imagen
   label: "Mi Entorno Personalizado"
   modules:
     - github-cli
     - nodejs
     - pnpm
     - python
   ```
2. Ejecute `git push`. GitHub Actions la compilará para `amd64`/`arm64` y la publicará automáticamente en:
   ```bash
   ghcr.io/joacohbc/mi-imagen:latest
   ```
