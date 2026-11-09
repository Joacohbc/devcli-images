# devcli-images

Imágenes de devcontainers personalizadas precompiladas para usar directamente con `devcontainer-cli`.

---

## ⚡ Uso rápido con `devcontainer-cli`

Para iniciar un devcontainer usando directamente una de estas imágenes sin compilar localmente:

```bash
# Iniciar contenedor con la imagen precompilada
devcontainer-cli up --image ghcr.io/joacohbc/ai-browser:latest
```

O para inicializar la configuración en tu proyecto actual:

```bash
devcontainer-cli init --image ghcr.io/joacohbc/ai-browser:latest
```

---

## 📦 Imágenes disponibles

| Imagen | Contenido |
|---|---|
| `ghcr.io/joacohbc/ai-browser:latest` | Python, uv, Node.js, pnpm, Chromium headless, GitHub CLI y Browser Harness con MCP preconfigurado (.claude, .agent, .cursor). |

---

## 🛠️ Agregar una nueva imagen

1. Crea la carpeta en `profiles/<id>/profile.yml`:
   ```yaml
   id: mi-imagen
   label: "Mi Entorno Personalizado"
   modules:
     - github-cli
     - nodejs
     - pnpm
     - python
   ```
2. Haz `git push`. GitHub Actions la compilará para `amd64`/`arm64` y la publicará automáticamente en:
   ```bash
   ghcr.io/joacohbc/mi-imagen:latest
   ```
