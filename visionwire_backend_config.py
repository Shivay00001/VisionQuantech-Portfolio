"""
VisionWire EdTech - Configuration and Database Setup
Files: backend/app/config.py and backend/app/database.py
"""

# ============================================================================
# FILE 1: backend/app/config.py
# ============================================================================

from pydantic_settings import BaseSettings
from typing import List, Optional
import os
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # Application
    APP_NAME: str = "VisionWire AI EdTech"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"
    
    # Backend
    BACKEND_HOST: str = "0.0.0.0"
    BACKEND_PORT: int = 8000
    BACKEND_URL: str = "http://localhost:8000"
    API_V1_PREFIX: str = "/api/v1"
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:3000"]
    
    # Database
    DATABASE_URL: str = "postgresql://visionwire:visionwire_secure_pass@localhost:5432/visionwire_db"
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 10
    DB_POOL_TIMEOUT: int = 30
    DB_POOL_RECYCLE: int = 3600
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
    REDIS_PASSWORD: Optional[str] = None
    
    # Cache TTL
    CACHE_TTL_SHORT: int = 300
    CACHE_TTL_MEDIUM: int = 1800
    CACHE_TTL_LONG: int = 3600
    CACHE_TTL_EXTENDED: int = 86400
    
    # Security
    SECRET_KEY: str = "your-super-secret-key-change-this-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    BCRYPT_ROUNDS: int = 12
    
    # AI & LLM
    LLM_PROVIDER: str = "anthropic"  # anthropic, openai, ollama, groq
    ANTHROPIC_API_KEY: Optional[str] = None
    ANTHROPIC_MODEL: str = "claude-sonnet-4-20250514"
    ANTHROPIC_MAX_TOKENS: int = 4096
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_MODEL: str = "gpt-4-turbo-preview"
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama2"
    GROQ_API_KEY: Optional[str] = None
    GROQ_MODEL: str = "mixtral-8x7b-32768"
    
    # AI Generation Settings
    AI_TEMPERATURE: float = 0.7
    AI_TOP_P: float = 0.9
    AI_FREQUENCY_PENALTY: float = 0.0
    AI_PRESENCE_PENALTY: float = 0.0
    MAX_NOTES_LENGTH: int = 5000
    MAX_QUIZ_QUESTIONS: int = 50
    
    # Embeddings
    EMBEDDING_MODEL: str = "text-embedding-3-small"
    EMBEDDING_DIMENSIONS: int = 1536
    
    # Vector Database
    QDRANT_URL: str = "http://localhost:6333"
    QDRANT_API_KEY: Optional[str] = None
    QDRANT_COLLECTION_NAME: str = "visionwire_embeddings"
    
    # Search
    SEARCH_ENGINE: str = "typesense"
    TYPESENSE_HOST: str = "localhost"
    TYPESENSE_PORT: int = 8108
    TYPESENSE_API_KEY: str = "xyz"
    TYPESENSE_PROTOCOL: str = "http"
    
    # Storage
    STORAGE_PROVIDER: str = "local"  # s3, r2, minio, local
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None
    AWS_REGION: str = "us-east-1"
    AWS_S3_BUCKET: str = "visionwire-content"
    LOCAL_STORAGE_PATH: str = "/var/visionwire/storage"
    CDN_URL: Optional[str] = None
    
    # Email
    EMAIL_PROVIDER: str = "smtp"
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    SMTP_FROM: str = "noreply@visionwire.com"
    SMTP_FROM_NAME: str = "VisionWire"
    
    # Background Jobs
    QUEUE_BACKEND: str = "redis"
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"
    WORKER_CONCURRENCY: int = 4
    
    # Curriculum
    SUPPORTED_BOARDS: List[str] = ["CBSE", "ICSE", "STATE_BOARD", "JEE", "NEET"]
    SUPPORTED_LANGUAGES: List[str] = ["en", "hi"]
    DEFAULT_LANGUAGE: str = "en"
    CURRICULUM_VERSION: str = "2024.1"
    
    # Features
    ENABLE_PDF_GENERATION: bool = True
    ENABLE_EPUB_GENERATION: bool = True
    ENABLE_VIDEO_GENERATION: bool = False
    ENABLE_DIAGRAM_GENERATION: bool = True
    ENABLE_AI_TUTOR: bool = True
    ENABLE_GAMIFICATION: bool = True
    
    # Rate Limiting
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_PER_HOUR: int = 1000
    
    # Monitoring
    SENTRY_DSN: Optional[str] = None
    SENTRY_ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"
    ENABLE_METRICS: bool = True
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


settings = get_settings()


# ============================================================================
# FILE 2: backend/app/database.py
# ============================================================================

from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import QueuePool
from typing import Generator
import logging

from app.config import settings

logger = logging.getLogger(__name__)

# Create SQLAlchemy engine with connection pooling
engine = create_engine(
    settings.DATABASE_URL,
    poolclass=QueuePool,
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    pool_timeout=settings.DB_POOL_TIMEOUT,
    pool_recycle=settings.DB_POOL_RECYCLE,
    pool_pre_ping=True,  # Test connections before using
    echo=settings.DEBUG,  # Log SQL queries in debug mode
)

# Create SessionLocal class
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


# Event listeners for connection management
@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_conn, connection_record):
    """Set connection-level settings"""
    if settings.DATABASE_URL.startswith("sqlite"):
        cursor = dbapi_conn.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()


def get_db() -> Generator[Session, None, None]:
    """
    Dependency to get database session
    Usage in FastAPI:
        @app.get("/items")
        def read_items(db: Session = Depends(get_db)):
            return db.query(Item).all()
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Initialize database - create all tables"""
    from app.models import Base
    
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database initialized successfully")
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {e}")
        raise


def reset_db():
    """Reset database - drop and recreate all tables (USE WITH CAUTION!)"""
    from app.models import Base
    
    if settings.ENVIRONMENT == "production":
        raise Exception("Cannot reset database in production!")
    
    try:
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database reset successfully")
    except Exception as e:
        logger.error(f"❌ Database reset failed: {e}")
        raise


# ============================================================================
# FILE 3: backend/app/core/cache.py
# ============================================================================

import redis.asyncio as redis
from typing import Optional, Any
import json
import pickle
from functools import wraps

from app.config import settings

# Global Redis client
redis_client: Optional[redis.Redis] = None


async def init_redis():
    """Initialize Redis connection"""
    global redis_client
    try:
        redis_client = redis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=False  # We'll handle encoding ourselves
        )
        await redis_client.ping()
        logger.info("✅ Redis connected successfully")
    except Exception as e:
        logger.error(f"❌ Redis connection failed: {e}")
        redis_client = None


async def close_redis():
    """Close Redis connection"""
    global redis_client
    if redis_client:
        await redis_client.close()


async def get_cache(key: str) -> Optional[Any]:
    """Get value from cache"""
    if not redis_client:
        return None
    
    try:
        value = await redis_client.get(key)
        if value:
            # Try JSON first, fallback to pickle
            try:
                return json.loads(value)
            except:
                return pickle.loads(value)
    except Exception as e:
        logger.error(f"Cache get error: {e}")
    
    return None


async def set_cache(key: str, value: Any, ttl: int = None) -> bool:
    """Set value in cache"""
    if not redis_client:
        return False
    
    try:
        # Try JSON first, fallback to pickle
        try:
            serialized = json.dumps(value)
        except:
            serialized = pickle.dumps(value)
        
        if ttl:
            await redis_client.setex(key, ttl, serialized)
        else:
            await redis_client.set(key, serialized)
        
        return True
    except Exception as e:
        logger.error(f"Cache set error: {e}")
        return False


async def delete_cache(key: str) -> bool:
    """Delete value from cache"""
    if not redis_client:
        return False
    
    try:
        await redis_client.delete(key)
        return True
    except Exception as e:
        logger.error(f"Cache delete error: {e}")
        return False


def cache_result(ttl: int = 300, key_prefix: str = ""):
    """
    Decorator to cache function results
    
    Usage:
        @cache_result(ttl=600, key_prefix="user")
        async def get_user(user_id: int):
            return await db.query(User).filter(User.id == user_id).first()
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key
            cache_key = f"{key_prefix}:{func.__name__}:{str(args)}:{str(kwargs)}"
            
            # Try to get from cache
            cached = await get_cache(cache_key)
            if cached is not None:
                return cached
            
            # Call function
            result = await func(*args, **kwargs)
            
            # Save to cache
            await set_cache(cache_key, result, ttl)
            
            return result
        
        return wrapper
    return decorator


# ============================================================================
# FILE 4: backend/app/core/exceptions.py
# ============================================================================

from fastapi import status
from typing import Optional, Dict, Any


class VisionWireException(Exception):
    """Base exception for VisionWire application"""
    
    def __init__(
        self,
        message: str,
        error_code: str = "VISIONWIRE_ERROR",
        status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR,
        details: Optional[Dict[str, Any]] = None
    ):
        self.message = message
        self.error_code = error_code
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)


class AuthenticationError(VisionWireException):
    """Authentication related errors"""
    def __init__(self, message: str = "Authentication failed", details: Optional[Dict] = None):
        super().__init__(
            message=message,
            error_code="AUTHENTICATION_ERROR",
            status_code=status.HTTP_401_UNAUTHORIZED,
            details=details
        )


class AuthorizationError(VisionWireException):
    """Authorization related errors"""
    def __init__(self, message: str = "Access denied", details: Optional[Dict] = None):
        super().__init__(
            message=message,
            error_code="AUTHORIZATION_ERROR",
            status_code=status.HTTP_403_FORBIDDEN,
            details=details
        )


class NotFoundError(VisionWireException):
    """Resource not found errors"""
    def __init__(self, resource: str = "Resource", details: Optional[Dict] = None):
        super().__init__(
            message=f"{resource} not found",
            error_code="NOT_FOUND",
            status_code=status.HTTP_404_NOT_FOUND,
            details=details
        )


class ValidationError(VisionWireException):
    """Data validation errors"""
    def __init__(self, message: str = "Validation failed", details: Optional[Dict] = None):
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details=details
        )


class ContentGenerationError(VisionWireException):
    """AI content generation errors"""
    def __init__(self, message: str = "Content generation failed", details: Optional[Dict] = None):
        super().__init__(
            message=message,
            error_code="CONTENT_GENERATION_ERROR",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            details=details
        )


class RateLimitError(VisionWireException):
    """Rate limit exceeded errors"""
    def __init__(self, message: str = "Rate limit exceeded", details: Optional[Dict] = None):
        super().__init__(
            message=message,
            error_code="RATE_LIMIT_EXCEEDED",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            details=details
        )