# Frontend del Sistema de Gestión de Biblioteca

Este proyecto es un frontend estático con HTML, CSS y JavaScript vanilla para consumir la API FastAPI del backend.

## Estructura

- `index.html`: interfaz principal
- `styles.css`: estilos de la aplicación
- `app.js`: lógica para consumir la API y renderizar datos

## Cómo abrirlo

1. Asegúrate de que el backend esté ejecutándose en `http://127.0.0.1:8000/api`.
2. Abre la carpeta `frontend` en VS Code.
3. Haz clic derecho en `index.html` y selecciona "Open with Live Server" o usa un servidor local simple como:

   ```bash
   cd "C:\Users\manue\Desktop\Data-Base-Advanced"
   python -m http.server 8001
   ```

4. Luego abre en el navegador:

   ```text
   http://127.0.0.1:8001/sistema_gestion_biblioteca/frontend/index.html
   ```

## Nota

El frontend no requiere Node.js ni npm; solo usa fetch() hacia la API REST del backend.
