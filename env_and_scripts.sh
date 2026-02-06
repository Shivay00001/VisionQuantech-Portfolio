# ============================================
# .env.example
# ============================================

# Application
APP_NAME=WorldMind OS
DEBUG=false
SECRET_KEY=change-this-to-a-random-secure-key-in-production
API_KEY=your-api-key-here

# Database
DATABASE_URL=postgresql://worldmind:worldmind123@db:5432/worldmind

# Redis
REDIS_URL=redis://redis:6379/0

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# Workers
WORKER_CONCURRENCY=4

# Logging
LOG_LEVEL=INFO

# Oracle (Optional - Blockchain Integration)
ORACLE_ENABLED=false
ETHEREUM_RPC=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
ORACLE_PRIVATE_KEY=your-private-key-here
GUARDIAN_CONTRACT=0x...
DAO_CONTRACT=0x...
CHAIN_ID=1

# ============================================
# scripts/init_db.py - Database Initialization
# ============================================

"""
Database initialization script
Run this to create all tables
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.db import engine, Base
from app.models.source import Source
from app.models.raw_event import RawEvent
from app.models.dataset import Dataset
from app.models.analysis_result import AnalysisResult
from app.models.job import Job
from app.models.oracle_signal import OracleSignal
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_database():
    """Initialize database tables"""
    try:
        logger.info("Creating database tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("✓ Database tables created successfully")
        
    except Exception as e:
        logger.error(f"✗ Error creating database tables: {e}")
        raise

if __name__ == "__main__":
    init_database()

# ============================================
# scripts/seed_demo.py - Demo Data Seeding
# ============================================

"""
Seed demo data for testing
"""
import sys
import os
import asyncio

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.db import SessionLocal
from app.models.source import Source
from app.models.dataset import Dataset
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def seed_demo_data():
    """Seed demo sources and datasets"""
    db = SessionLocal()
    
    try:
        logger.info("Seeding demo data...")
        
        # Create demo sources
        demo_sources = [
            Source(
                name="Tech News Scraper",
                type="web",
                platform="news",
                config={
                    "urls": [
                        "https://news.ycombinator.com",
                        "https://techcrunch.com"
                    ]
                },
                enabled=True
            ),
            Source(
                name="Twitter AI Discussion",
                type="social",
                platform="twitter",
                config={
                    "query": "#AI",
                    "count": 100
                },
                enabled=True
            ),
            Source(
                name="Reddit r/technology",
                type="social",
                platform="reddit",
                config={
                    "subreddit": "technology",
                    "limit": 100
                },
                enabled=True
            ),
            Source(
                name="YouTube AI Videos",
                type="social",
                platform="youtube",
                config={
                    "search_query": "artificial intelligence",
                    "max_results": 50
                },
                enabled=True
            )
        ]
        
        for source in demo_sources:
            existing = db.query(Source).filter(Source.name == source.name).first()
            if not existing:
                db.add(source)
                logger.info(f"✓ Added source: {source.name}")
        
        db.commit()
        
        # Create demo dataset
        sources = db.query(Source).all()
        source_ids = [s.id for s in sources]
        
        demo_dataset = Dataset(
            name="Global Tech Sentiment Dataset",
            description="Combined dataset of tech news and social media discussions",
            source_ids=source_ids,
            row_count=0
        )
        
        existing_dataset = db.query(Dataset).filter(
            Dataset.name == demo_dataset.name
        ).first()
        
        if not existing_dataset:
            db.add(demo_dataset)
            db.commit()
            logger.info(f"✓ Added dataset: {demo_dataset.name}")
        
        logger.info("✓ Demo data seeded successfully")
        
    except Exception as e:
        logger.error(f"✗ Error seeding demo data: {e}")
        db.rollback()
        raise
        
    finally:
        db.close()

if __name__ == "__main__":
    seed_demo_data()

# ============================================
# scripts/start_worker.sh - Worker Startup Script
# ============================================

#!/bin/bash
echo "Starting WorldMind OS Workers..."

# Wait for Redis
echo "Waiting for Redis..."
while ! nc -z redis 6379; do
  sleep 1
done
echo "✓ Redis is ready"

# Wait for Database
echo "Waiting for Database..."
while ! nc -z db 5432; do
  sleep 1
done
echo "✓ Database is ready"

# Start RQ workers
echo "Starting RQ workers..."
rq worker scraping analysis oracle --url redis://redis:6379/0 --verbose

# ============================================
# scripts/run_tests.sh - Test Runner
# ============================================

#!/bin/bash
echo "Running WorldMind OS Tests..."

# Set test environment
export DATABASE_URL="postgresql://worldmind:worldmind123@localhost:5432/worldmind_test"
export REDIS_URL="redis://localhost:6379/1"

# Run pytest
pytest tests/ -v --cov=app --cov-report=html --cov-report=term

echo "✓ Tests completed"
