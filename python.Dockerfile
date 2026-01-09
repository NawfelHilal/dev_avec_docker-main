FROM python:3.9-slim-bookworm

# Labels OCI standard
LABEL org.opencontainers.image.title="Student Dashboard API"
LABEL org.opencontainers.image.description="FastAPI backend for Student Dashboard"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="M2 Ynov"

# Variables d'environnement Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Installer curl pour le healthcheck (utilisé par docker-compose)
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Créer un utilisateur système non-root
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /server

# Copier et installer les dépendances (optimisation cache Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code source
COPY postgres-test.py .

# Changer les permissions
RUN chown -R appuser:appgroup /server

# Passer à l'utilisateur non-root
USER appuser

EXPOSE 8000

CMD ["uvicorn", "postgres-test:app", "--host", "0.0.0.0", "--port", "8000"]