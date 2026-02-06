# WorldMind OS - Complete Setup Guide

## 📋 Table of Contents
1. [System Requirements](#system-requirements)
2. [Local Development Setup](#local-development-setup)
3. [Docker Deployment](#docker-deployment)
4. [Production Deployment](#production-deployment)
5. [Configuration Guide](#configuration-guide)
6. [Testing Guide](#testing-guide)
7. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 20GB
- **OS**: Linux, macOS, or Windows with WSL2

### Recommended for Production
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Storage**: 50GB+ SSD
- **OS**: Ubuntu 22.04 LTS

### Software Requirements
- Docker 24.0+
- Docker Compose 2.20+
- Python 3.11+ (for local development)
- Node.js 18+ (for frontend development)
- PostgreSQL 15+ (if not using Docker)
- Redis 7+ (if not using Docker)

---

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/worldmind-os.git
cd worldmind-os
```

### 2. Setup Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp ../.env.example .env

# Edit .env with your settings
nano .env

# Initialize database
python scripts/init_db.py

# Seed demo data (optional)
python scripts/seed_demo.py

# Run backend
uvicorn app.main:app --reload --port 8000
```

### 3. Setup Frontend

```bash
cd frontend

# Install dependencies
npm install

# Create .env.local
echo "VITE_API_URL=http://localhost:8000" > .env.local

# Run frontend
npm run dev
```

### 4. Setup Workers

```bash
cd backend

# Activate venv if not already active
source venv/bin/activate

# Ensure Redis is running
docker run -d -p 6379:6379 redis:7-alpine

# Start worker
rq worker scraping analysis oracle --url redis://localhost:6379/0
```

### 5. Access Application

- **Frontend**: http://localhost:3000
- **API Docs**: http://localhost:8000/api/docs
- **Health Check**: http://localhost:8000/health

---

## Docker Deployment

### 1. Quick Start (All Services)

```bash
# Clone repository
git clone https://github.com/your-org/worldmind-os.git
cd worldmind-os

# Configure environment
cp .env.example .env
nano .env  # Edit configuration

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 2. Initialize Database

```bash
# Run migrations
docker-compose exec api python scripts/init_db.py

# Seed demo data
docker-compose exec api python scripts/seed_demo.py
```

### 3. Scale Workers

```bash
# Scale to 4 worker instances
docker-compose up -d --scale worker=4

# Check worker status
docker-compose ps worker
```

### 4. Enable Oracle Service

```bash
# Configure oracle in .env
ORACLE_ENABLED=true
ETHEREUM_RPC=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
ORACLE_PRIVATE_KEY=your-private-key
GUARDIAN_CONTRACT=0x...
DAO_CONTRACT=0x...

# Start with oracle profile
docker-compose --profile oracle up -d
```

### 5. Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v
```

---

## Production Deployment

### 1. Infrastructure Setup

#### AWS/Cloud Setup

```bash
# Provision infrastructure
# - RDS PostgreSQL instance (db.t3.medium)
# - ElastiCache Redis cluster
# - ECS/EKS for containers
# - Application Load Balancer
# - CloudWatch for monitoring

# Example RDS connection
DATABASE_URL=postgresql://worldmind:password@prod-db.region.rds.amazonaws.com:5432/worldmind
REDIS_URL=redis://prod-cache.region.cache.amazonaws.com:6379/0
```

#### VPS/Dedicated Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Setup firewall
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

### 2. Security Configuration

```bash
# Generate strong keys
SECRET_KEY=$(openssl rand -hex 32)
API_KEY=$(openssl rand -hex 32)

# Update .env
cat > .env << EOF
# Production Settings
DEBUG=false
SECRET_KEY=${SECRET_KEY}
API_KEY=${API_KEY}

# Database (use managed service)
DATABASE_URL=postgresql://user:pass@prod-db:5432/worldmind

# Redis (use managed service)
REDIS_URL=redis://prod-cache:6379/0

# CORS (restrict to production domains)
CORS_ORIGINS=https://app.yourdomain.com,https://dashboard.yourdomain.com

# Workers
WORKER_CONCURRENCY=8

# Logging
LOG_LEVEL=WARNING
EOF
```

### 3. SSL/TLS Setup (Nginx Reverse Proxy)

```nginx
# /etc/nginx/sites-available/worldmind-os

server {
    listen 80;
    server_name api.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 443 ssl http2;
    server_name app.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/app.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 4. Monitoring & Logging

```bash
# Install monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# Services:
# - Prometheus (metrics)
# - Grafana (dashboards)
# - Loki (log aggregation)
# - AlertManager (alerts)
```

### 5. Backup Strategy

```bash
# Database backup script
#!/bin/bash
BACKUP_DIR="/backups/worldmind"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup database
docker-compose exec -T db pg_dump -U worldmind worldmind | gzip > "${BACKUP_DIR}/db_${DATE}.sql.gz"

# Backup Redis
docker-compose exec -T redis redis-cli --rdb /data/dump.rdb
docker cp worldmind_redis:/data/dump.rdb "${BACKUP_DIR}/redis_${DATE}.rdb"

# Retention (keep last 7 days)
find ${BACKUP_DIR} -type f -mtime +7 -delete

echo "Backup completed: ${DATE}"
```

### 6. Auto-restart & Health Checks

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  api:
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  worker:
    restart: always
    deploy:
      replicas: 4
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  db:
    restart: always
    volumes:
      - /mnt/data/postgres:/var/lib/postgresql/data

  redis:
    restart: always
    volumes:
      - /mnt/data/redis:/data
```

---

## Configuration Guide

### Environment Variables Reference

```bash
# ============================================
# Application Settings
# ============================================
APP_NAME=WorldMind OS
DEBUG=false                    # Set to false in production
SECRET_KEY=<random-64-char>    # Generate: openssl rand -hex 32
API_KEY=<random-64-char>       # API authentication key

# ============================================
# Database Configuration
# ============================================
DATABASE_URL=postgresql://user:password@host:5432/dbname

# Connection Pool Settings
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20
DB_POOL_TIMEOUT=30

# ============================================
# Redis Configuration
# ============================================
REDIS_URL=redis://host:6379/0
REDIS_MAX_CONNECTIONS=50

# ============================================
# CORS Settings
# ============================================
CORS_ORIGINS=https://app.example.com,https://dashboard.example.com

# ============================================
# Worker Settings
# ============================================
WORKER_CONCURRENCY=4
JOB_TIMEOUT=3600
RATE_LIMIT_DELAY=1.0

# ============================================
# Scraping Settings
# ============================================
USER_AGENT=WorldMindOS/1.0
REQUEST_TIMEOUT=30
MAX_RETRIES=3

# ============================================
# Analysis Settings
# ============================================
MIN_DATASET_SIZE=10
SENTIMENT_THRESHOLD=0.6
OUTLIER_THRESHOLD=3.0

# ============================================
# Oracle/Blockchain Settings
# ============================================
ORACLE_ENABLED=false
ETHEREUM_RPC=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
ORACLE_PRIVATE_KEY=your-private-key-without-0x-prefix
GUARDIAN_CONTRACT=0xGuardianContractAddress
DAO_CONTRACT=0xDAOContractAddress
CHAIN_ID=1

# ============================================
# Logging
# ============================================
LOG_LEVEL=INFO  # DEBUG, INFO, WARNING, ERROR, CRITICAL
```

---

## Testing Guide

### Unit Tests

```bash
cd backend

# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=html

# Run specific test file
pytest tests/test_scraping_service.py -v

# Run with markers
pytest -m "not slow" -v
```

### Integration Tests

```bash
# Start test database
docker-compose -f docker-compose.test.yml up -d

# Run integration tests
pytest tests/integration/ -v

# Cleanup
docker-compose -f docker-compose.test.yml down -v
```

### API Tests

```bash
# Install httpie
pip install httpie

# Test health endpoint
http GET http://localhost:8000/health

# Test API with authentication
http GET http://localhost:8000/api/sources/ "Authorization: Bearer ${API_KEY}"

# Create source
http POST http://localhost:8000/api/sources/ \
  name="Test Source" \
  type="web" \
  platform="news" \
  config:='{"urls":["https://example.com"]}' \
  enabled:=true
```

### Load Testing

```bash
# Install locust
pip install locust

# Create locustfile.py
cat > locustfile.py << 'EOF'
from locust import HttpUser, task, between

class WorldMindUser(HttpUser):
    wait_time = between(1, 3)
    
    @task
    def get_dashboard_stats(self):
        self.client.get("/api/analysis/dashboard/stats")
    
    @task
    def list_sources(self):
        self.client.get("/api/sources/")
EOF

# Run load test
locust -f locustfile.py --host=http://localhost:8000
```

---

## Troubleshooting

### Common Issues

#### 1. Database Connection Error

```bash
# Check if database is running
docker-compose ps db

# Check database logs
docker-compose logs db

# Test connection
docker-compose exec db psql -U worldmind -d worldmind -c "SELECT 1;"

# Reset database
docker-compose down -v
docker-compose up -d db
docker-compose exec api python scripts/init_db.py
```

#### 2. Redis Connection Error

```bash
# Check Redis status
docker-compose ps redis

# Test connection
docker-compose exec redis redis-cli ping

# Flush Redis (WARNING: clears all data)
docker-compose exec redis redis-cli FLUSHALL
```

#### 3. Worker Not Processing Jobs

```bash
# Check worker logs
docker-compose logs -f worker

# Check job queue
docker-compose exec redis redis-cli KEYS "rq:*"

# Restart workers
docker-compose restart worker

# Scale workers
docker-compose up -d --scale worker=4
```

#### 4. High Memory Usage

```bash
# Check container stats
docker stats

# Limit container memory
# Add to docker-compose.yml:
services:
  api:
    deploy:
      resources:
        limits:
          memory: 2G
```

#### 5. Slow API Response

```bash
# Check database query performance
docker-compose exec db psql -U worldmind -d worldmind -c "
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;"

# Add database indexes if needed
# Check app/models/*.py for Index definitions
```

### Debugging Tips

```bash
# Enable debug mode temporarily
docker-compose exec api python -c "
from app.core.config import settings
print(f'DEBUG: {settings.DEBUG}')
print(f'DATABASE_URL: {settings.DATABASE_URL}')
"

# Check API logs
docker-compose logs -f api | grep ERROR

# Interactive Python shell
docker-compose exec api python
>>> from app.core.db import SessionLocal
>>> from app.models.source import Source
>>> db = SessionLocal()
>>> sources = db.query(Source).all()
>>> print(sources)
```

---

## Performance Optimization

### Database Optimization

```sql
-- Add indexes for frequently queried columns
CREATE INDEX idx_raw_events_source_platform ON raw_events(source_id, platform);
CREATE INDEX idx_analysis_results_category_severity ON analysis_results(category, severity);
CREATE INDEX idx_jobs_type_status ON jobs(type, status);

-- Analyze tables
ANALYZE raw_events;
ANALYZE analysis_results;
ANALYZE jobs;
```

### Caching Strategy

```python
# Add Redis caching for dashboard stats
# In routes_analysis.py:

from functools import lru_cache
import json

@router.get("/dashboard/stats")
async def get_dashboard_stats(db: Session = Depends(get_db)):
    cache_key = "dashboard:stats"
    
    # Try cache first
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Calculate stats
    stats = calculate_stats(db)
    
    # Cache for 5 minutes
    redis_client.setex(cache_key, 300, json.dumps(stats))
    
    return stats
```

---

## Support & Resources

- **Documentation**: https://docs.worldmindos.com
- **GitHub Issues**: https://github.com/your-org/worldmind-os/issues
- **Discord Community**: https://discord.gg/worldmindos
- **Email Support**: support@worldmindos.com

---

**Last Updated**: 2024-11-23
**Version**: 1.0.0
