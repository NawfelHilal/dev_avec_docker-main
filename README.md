# Student Dashboard - Docker Stack M2

Stack Docker complète avec frontend, API Python/FastAPI, PostgreSQL et Redis.

## 🚀 Démarrage rapide

```bash
# 1. Cloner le projet
git clone <url-du-repo>
cd dev_avec_docker-main

# 2. Configurer l'environnement
cp .env.example .env
# Éditer .env avec vos valeurs

# 3. Lancer la stack
docker compose up --build -d

# 4. Accéder au dashboard
# Frontend: http://localhost:8080
# API: http://localhost:8000
# Health check: http://localhost:8000/health
```

## 📦 Architecture

| Service  | Port  | Description |
|----------|-------|-------------|
| frontend | 8080  | Dashboard Nginx |
| api      | 8000  | FastAPI Python |
| db       | -     | PostgreSQL (interne) |
| redis    | -     | Cache Redis (interne) |
| adminer  | -     | Admin DB (interne) |

## 🔒 Sécurité

- **Moindre privilège** : API tourne en utilisateur non-root
- **Isolation réseau** : DB et Redis non exposés sur l'hôte
- **Secrets** : Variables d'environnement via `.env` (exclu du git)

## 🛡️ Résilience

- Retry automatique pour connexion PostgreSQL au démarrage
- Graceful degradation si Redis indisponible (views = 0)
- Health check endpoint `/health`

## 📁 Structure

```
├── docker-compose.yml     # Orchestration des services
├── python.Dockerfile      # Image API (non-root)
├── nginx.Dockerfile       # Image Frontend
├── postgres.Dockerfile    # Image DB avec migrations
├── postgres-test.py       # Code API FastAPI
├── requirements.txt       # Dépendances Python
├── frontend/              # Fichiers statiques
├── nginx/                 # Configuration Nginx
├── sqlfiles/              # Scripts SQL d'initialisation
├── .env.example           # Template configuration
└── .gitignore             # Fichiers exclus
```

## 🧪 Tests

```bash
# Vérifier les services
docker compose ps

# Health check
curl http://localhost:8000/health

# Tester graceful degradation
docker stop dev_avec_docker-main-redis-1
curl http://localhost:8000  # views = 0
```
