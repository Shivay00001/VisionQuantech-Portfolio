"""
Configuration management using Pydantic Settings
Loads from environment variables with validation
"""
from pydantic_settings import BaseSettings
from pydantic import Field, validator
from typing import List, Optional
from functools import lru_cache

class Settings(BaseSettings):
    """Application settings with environment variable support"""
    
    # App Settings
    APP_NAME: str = "WorldMind OS"
    DEBUG: bool = Field(default=False, env="DEBUG")
    VERSION: str = "1.0.0"
    
    # API Settings
    API_PREFIX: str = "/api"
    SECRET_KEY: str = Field(..., env="SECRET_KEY")
    API_KEY: str = Field(..., env="API_KEY")
    
    # CORS Settings
    CORS_ORIGINS: List[str] = Field(
        default=["http://localhost:3000", "http://localhost:5173"],
        env="CORS_ORIGINS"
    )
    
    # Database Settings
    DATABASE_URL: str = Field(
        default="postgresql://worldmind:worldmind123@db:5432/worldmind",
        env="DATABASE_URL"
    )
    
    # Redis Settings
    REDIS_URL: str = Field(
        default="redis://redis:6379/0",
        env="REDIS_URL"
    )
    
    # Scraping Settings
    USER_AGENT: str = "WorldMindOS/1.0 (Data Intelligence Platform)"
    REQUEST_TIMEOUT: int = 30
    MAX_RETRIES: int = 3
    RATE_LIMIT_DELAY: float = 1.0
    
    # Analysis Settings
    MIN_DATASET_SIZE: int = 10
    SENTIMENT_THRESHOLD: float = 0.6
    OUTLIER_THRESHOLD: float = 3.0
    
    # Worker Settings
    WORKER_CONCURRENCY: int = Field(default=4, env="WORKER_CONCURRENCY")
    JOB_TIMEOUT: int = 3600  # 1 hour
    
    # Oracle Settings (Optional)
    ORACLE_ENABLED: bool = Field(default=False, env="ORACLE_ENABLED")
    ETHEREUM_RPC: Optional[str] = Field(default=None, env="ETHEREUM_RPC")
    ORACLE_PRIVATE_KEY: Optional[str] = Field(default=None, env="ORACLE_PRIVATE_KEY")
    GUARDIAN_CONTRACT: Optional[str] = Field(default=None, env="GUARDIAN_CONTRACT")
    DAO_CONTRACT: Optional[str] = Field(default=None, env="DAO_CONTRACT")
    CHAIN_ID: int = Field(default=1, env="CHAIN_ID")
    
    # Logging
    LOG_LEVEL: str = Field(default="INFO", env="LOG_LEVEL")
    
    @validator("CORS_ORIGINS", pre=True)
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()

settings = get_settings()
