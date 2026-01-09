FROM nginx:1.25-alpine

# Labels OCI standard
LABEL org.opencontainers.image.title="Student Dashboard Frontend"
LABEL org.opencontainers.image.description="Nginx serving static frontend files"
LABEL org.opencontainers.image.version="1.0.0"

# Supprimer la configuration par défaut
RUN rm -rf /etc/nginx/conf.d/default.conf

# Copier la configuration Nginx personnalisée
COPY nginx/default.conf /etc/nginx/conf.d/

# Copier les fichiers statiques du frontend
COPY frontend/ /usr/share/nginx/html/

EXPOSE 80
