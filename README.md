# devcli-images

Repositorio de pipelines para compilar y publicar imágenes de devcontainers personalizadas en **GitHub Packages (GHCR)** utilizando `devcontainer-cli`.

---

## 🚀 ¿Cómo funciona?

1. **Definición de Perfiles**:
   Cada imagen personalizada se define dentro del directorio `profiles/`.
   - Puede ser un directorio `profiles/<id>/profile.yml` (recomendado si lleva scripts o archivos auxiliares).
   - O un archivo simple `profiles/<id>.yml`.

2. **Pipeline automatizado (`.github/workflows/build-images.yml`)**:
   - Detecta automáticamente todos los perfiles en `profiles/`.
   - Descarga la última versión de `devcontainer-cli` desde `Joacohbc/my-devcontainer-installer`.
   - Genera el `Dockerfile` optimizado y el contexto de build en modo headless (`--no-interactive --no-build`).
   - Compila la imagen multi-arquitectura (`linux/amd64` y `linux/arm64`) utilizando Docker Buildx.
   - Publica la imagen en GitHub Packages (`ghcr.io/<owner>/<profile>:latest` y tag por SHA).

---

## 📦 Agregar un nuevo perfil / imagen

Para agregar cualquier nueva configuración o perfil en el futuro:

1. Crea una carpeta dentro de `profiles/` con el identificador deseado:
   ```bash
   mkdir -p profiles/mi-nuevo-entorno
   ```

2. Agrega el archivo `profiles/mi-nuevo-entorno/profile.yml` (y cualquier script `.sh` referenciado en la misma carpeta):
   ```yaml
   id: mi-nuevo-entorno
   label: "Node.js + Python + Herramientas"
   modules:
     - github-cli
     - nodejs
     - pnpm
     - python
   scripts:
     - file: custom-setup.sh
       when: start
   ```

3. Haz `git commit` y `git push`. El pipeline detectará la nueva imagen en una matriz paralela y la publicará automáticamente en GHCR.

---

## 🛠️ Ejecución manual (Workflow Dispatch)

Puedes disparar el workflow manualmente desde la pestaña **Actions**:
- Filtrar para compilar únicamente un perfil en particular (ej. `ai-browser`).
- Seleccionar una versión específica de `devcontainer-cli` si no se desea usar `latest`.

---

## 🚢 Usar las imágenes publicadas

Una vez publicada en GitHub Packages:

```bash
docker pull ghcr.io/<tu-usuario>/<id-perfil>:latest
```

O directamente referenciarla en tus configuraciones de `devcontainer-cli` o `devcontainer.json`.
