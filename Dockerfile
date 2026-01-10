# Usamos una imagen base de Python ligera
FROM python:3.12-slim-bookworm

# 1. Copiamos el ejecutable de 'uv' desde su imagen oficial
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Configuraciones de entorno para uv
# UV_COMPILE_BYTECODE: Compila los archivos .py a .pyc para un arranque más rápido
# UV_LINK_MODE: Usa copia en lugar de enlaces duros (mejor para Docker)
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Establecemos el directorio de trabajo
WORKDIR /app

# 2. Copiamos los archivos de definición de dependencias primero
# Esto aprovecha la caché de Docker: si no cambian las dependencias, este paso no se repite
COPY pyproject.toml uv.lock ./

# 3. Instalamos las dependencias
# --frozen: Asegura que se instalen exactamente las versiones del uv.lock
# --no-dev: No instalamos dependencias de desarrollo
# --no-install-project: Solo instalamos dependencias, no el proyecto en sí todavía
RUN uv sync --frozen --no-dev --no-install-project

# 4. Agregamos el entorno virtual al PATH
# Esto permite ejecutar 'streamlit' directamente sin prefijo 'uv run'
ENV PATH="/app/.venv/bin:$PATH"

# 5. Copiamos el resto del código de la aplicación
COPY . .

# Exponemos el puerto por defecto de Streamlit
EXPOSE 8501

# Comprobación de salud (Healthcheck) recomendada para Streamlit
#HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health || exit 1
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8501/_stcore/health')" || exit 1

# 6. Comando de ejecución
# Es importante poner --server.address=0.0.0.0 para que sea accesible desde fuera del contenedor
CMD ["streamlit", "run", "main.py", "--server.address=0.0.0.0", "--server.port=8501"]