import psycopg2
import redis
import os
import time
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
origins= ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"])

def get_db_connection():
    """Crée une nouvelle connexion à la base de données PostgreSQL"""
    return psycopg2.connect(
        host=os.getenv("POSTGRES_HOST"),
        port=5432,
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
        database=os.getenv("POSTGRES_DB")
    )

def get_redis_connection():
    """Crée une connexion Redis"""
    return redis.Redis(
        host=os.getenv("REDIS_HOST", "redis"),
        port=6379,
        decode_responses=True,
        socket_timeout=2  # Timeout pour éviter les blocages
    )

def get_views_count():
    """
    Récupère et incrémente le compteur de vues depuis Redis.
    En cas d'erreur Redis, retourne 0 (graceful degradation).
    """
    try:
        r = get_redis_connection()
        return r.incr("page_views")
    except (redis.ConnectionError, redis.TimeoutError) as e:
        print(f"Redis unavailable, using fallback: {e}")
        return 0  # Valeur par défaut si Redis est indisponible

# Attendre que la DB soit prête (obligatoire sauf si SKIP_DB_CHECK est défini)
if os.getenv("SKIP_DB_CHECK", "false").lower() != "true":
    while True:
        try:
            conn = get_db_connection()
            conn.close()
            print("PostgreSQL is ready!")
            break
        except psycopg2.OperationalError as e:
            print(f"Waiting for PostgreSQL: {e}")
            time.sleep(2)
else:
    print("Skipping PostgreSQL startup check as requested.")

# Vérifier Redis au démarrage (non bloquant)
try:
    r = get_redis_connection()
    r.ping()
    print("Redis is ready!")
except redis.ConnectionError as e:
    print(f"Warning: Redis not available at startup: {e}")
    print("API will continue with graceful degradation for Redis.")

@app.get('/')
async def get_students():
    # Connexion PostgreSQL
    conn = get_db_connection()
    
    # Récupération du compteur avec graceful degradation
    views_count = get_views_count()
    
    try:
        cur = conn.cursor()
        cur.execute("SELECT id, nom, prenom, promo FROM students;")
        rows = cur.fetchall()
        
        students = []
        for row in rows:
            students.append({
                "id": row[0],
                "nom": f"{row[2]} {row[1]}" if row[2] else row[1],
                "promo": row[3] or "N/A",
                "views": views_count
            })
        
        return students
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

@app.get('/health')
async def health_check():
    """Endpoint de health check pour vérifier l'état des services"""
    status = {
        "api": "healthy",
        "postgres": "unknown",
        "redis": "unknown"
    }
    
    # Check PostgreSQL
    try:
        conn = get_db_connection()
        conn.close()
        status["postgres"] = "healthy"
    except Exception:
        status["postgres"] = "unhealthy"
    
    # Check Redis
    try:
        r = get_redis_connection()
        r.ping()
        status["redis"] = "healthy"
    except Exception:
        status["redis"] = "unhealthy"
    
    return status
