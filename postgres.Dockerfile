FROM postgres:18-alpine

# Labels OCI standard
LABEL org.opencontainers.image.title="Student Dashboard Database"
LABEL org.opencontainers.image.description="PostgreSQL database with initialization scripts"
LABEL org.opencontainers.image.version="1.0.0"

# Copier les scripts SQL dans le répertoire d'initialisation
# Les scripts sont exécutés dans l'ordre alphabétique au premier démarrage
COPY sqlfiles/*.sql /docker-entrypoint-initdb.d/

# Les scripts doivent être lisibles
RUN chmod 644 /docker-entrypoint-initdb.d/*.sql

EXPOSE 5432
