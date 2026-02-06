# WorldMind OS

**Global Data Intelligence Platform** - Production-grade system for web scraping, social media extraction, advanced data analysis, and blockchain oracle integration.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Python](https://img.shields.io/badge/python-3.11+-green)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104-teal)
![React](https://img.shields.io/badge/React-18-61dafb)

## 🌟 Features

### 1. **Data Extraction Layer**
- ✅ Web scraping with auto-extraction and custom CSS selectors
- ✅ Social media connectors (Twitter, Reddit, YouTube, Instagram)
- ✅ Pluggable architecture for easy source addition
- ✅ Automatic deduplication and content hashing
- ✅ Rate limiting and retry logic

### 2. **Analysis & DSA Engine**
- ✅ Comprehensive data profiling (quality scoring, missing data analysis)
- ✅ Sentiment analysis and opinion mining
- ✅ Trend detection and engagement metrics
- ✅ Psychology/keyword analysis
- ✅ Advanced cleaning strategies (auto/conservative/aggressive)
- ✅ Feature engineering (encoding, scaling, PCA, anomaly detection)
- ✅ Correlation analysis and outlier detection

### 3. **Oracle & Decision Layer**
- ✅ Blockchain integration via Web3
- ✅ Automated signal transmission for high-severity events
- ✅ Transaction monitoring and confirmation
- ✅ Support for Ethereum-compatible chains

### 4. **Modern Dashboard**
- ✅ Real-time statistics and metrics
- ✅ Sentiment distribution visualization
- ✅ Source management interface
- ✅ Job monitoring and tracking
- ✅ Insights exploration

## 🏗️ Architecture

```
worldmind-os/
├── backend/                 # FastAPI Backend
│   ├── app/
│   │   ├── api/            # REST API routes
│   │   ├── core/           # Configuration & database
│   │   ├── models/         # SQLAlchemy models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   └── workers/        # Background jobs
│   ├── tests/              # Unit & integration tests
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/               # React Dashboard
│   ├── src/
│   │   ├── pages/         # Page components
│   │   ├── components/    # Reusable components
│   │   └── services/      # API client
│   ├── Dockerfile
│   └── package.json
│
├── oracle/                 # Blockchain Oracle
│   ├── you_ai_oracle.py
│   ├── Dockerfile
│   └── requirements.txt
│
├── scripts/                # Utility scripts
│   ├── init_db.py
│   ├── seed_demo.py
│   └── start_worker.sh
│
├── docker-compose.yml      # Full stack orchestration
├── .env.example
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Python 3.11+ (for local development)
- Node.js 18+ (for frontend development)

### 1. Clone & Configure

```bash
git clone <repository-url>
cd worldmind-os

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### 2. Start with Docker

```bash
# Start all services
docker-compose up -d

# Check service health
docker-compose ps

# View logs
docker-compose logs -f
```

### 3. Initialize Database

```bash
# Run migrations
docker-compose exec api python scripts/init_db.py

# Seed demo data
docker-compose exec api python scripts/seed_demo.py
```

### 4. Access Services

- **API Documentation**: http://localhost:8000/api/docs
- **Frontend Dashboard**: http://localhost:3000
- **API Health**: http://localhost:8000/health

## 📊 Usage

### Create a Data Source

```bash
curl -X POST "http://localhost:8000/api/sources/" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Tech News",
    "type": "web",
    "platform": "news",
    "config": {
      "urls": ["https://news.ycombinator.com"]
    },
    "enabled": true
  }'
```

### Trigger Data Extraction

```bash
# Extract from specific source
curl -X POST "http://localhost:8000/api/sources/1/extract"

# Extract from all enabled sources
curl -X POST "http://localhost:8000/api/sources/extract-all"
```

### Create & Analyze Dataset

```bash
# Create dataset
curl -X POST "http://localhost:8000/api/analysis/datasets" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Dataset",
    "description": "Test dataset",
    "source_ids": [1, 2, 3]
  }'

# Trigger analysis
curl -X POST "http://localhost:8000/api/analysis/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "dataset_id": 1,
    "categories": ["sentiment", "trends", "engagement"]
  }'
```

### View Results

```bash
# Get dashboard stats
curl "http://localhost:8000/api/analysis/dashboard/stats"

# Get analysis results
curl "http://localhost:8000/api/analysis/results"

# Get insights summary
curl "http://localhost:8000/api/analysis/insights/summary"
```

## 🔧 Development

### Backend Development

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn app.main:app --reload --port 8000
```

### Frontend Development

```bash
cd frontend

# Install dependencies
npm install

# Run dev server
npm run dev
```

### Run Workers Locally

```bash
cd backend

# Start RQ worker
rq worker scraping analysis oracle --url redis://localhost:6379/0
```

### Run Tests

```bash
cd backend
pytest tests/ -v --cov=app
```

## 🛡️ Production Deployment

### Environment Variables

**Critical Security Settings:**
```bash
SECRET_KEY=<generate-strong-random-key>
API_KEY=<your-api-key>
DEBUG=false
```

### Database Setup

```bash
# Use managed PostgreSQL in production
DATABASE_URL=postgresql://user:password@prod-db:5432/worldmind
```

### Scaling Workers

```bash
# Scale workers in docker-compose.yml
docker-compose up -d --scale worker=4
```

### Enable Oracle (Blockchain Integration)

```bash
# Configure in .env
ORACLE_ENABLED=true
ETHEREUM_RPC=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
ORACLE_PRIVATE_KEY=your-private-key
GUARDIAN_CONTRACT=0x...
DAO_CONTRACT=0x...
CHAIN_ID=1

# Start oracle service
docker-compose --profile oracle up -d
```

## 📈 Monitoring

### Health Checks

```bash
# API health
curl http://localhost:8000/health

# Database connection
docker-compose exec db pg_isready

# Redis status
docker-compose exec redis redis-cli ping
```

### Job Monitoring

```bash
# View job statistics
curl http://localhost:8000/api/jobs/stats/summary

# List recent jobs
curl "http://localhost:8000/api/jobs/?since_hours=24"
```

### Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api
docker-compose logs -f worker
```

## 🧪 Testing

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=html

# Run specific test
pytest tests/test_scraping.py -v
```

## 🔐 Security Best Practices

1. **Always change default credentials** in `.env`
2. **Use HTTPS** in production
3. **Implement rate limiting** for public APIs
4. **Rotate API keys** regularly
5. **Never commit** `.env` files
6. **Use secrets management** (AWS Secrets Manager, Vault)
7. **Enable CORS** only for trusted origins

## 📚 API Documentation

Full interactive API documentation available at:
- **Swagger UI**: http://localhost:8000/api/docs
- **ReDoc**: http://localhost:8000/api/redoc

### Key Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/sources/` | GET | List all sources |
| `/api/sources/` | POST | Create new source |
| `/api/sources/{id}/extract` | POST | Trigger extraction |
| `/api/jobs/` | GET | List jobs |
| `/api/analysis/datasets` | POST | Create dataset |
| `/api/analysis/analyze` | POST | Trigger analysis |
| `/api/analysis/results` | GET | Get results |
| `/api/analysis/dashboard/stats` | GET | Dashboard stats |

## 🛠️ Troubleshooting

### Database Connection Issues
```bash
# Check database status
docker-compose exec db pg_isready -U worldmind

# Reset database
docker-compose down -v
docker-compose up -d
```

### Worker Not Processing Jobs
```bash
# Check Redis connection
docker-compose exec redis redis-cli ping

# Restart worker
docker-compose restart worker
```

### Port Already in Use
```bash
# Change ports in docker-compose.yml
ports:
  - "8001:8000"  # Use different host port
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- FastAPI for the excellent web framework
- React & TailwindCSS for modern UI
- SQLAlchemy for robust ORM
- RQ for simple job queuing
- Web3.py for blockchain integration

## 📧 Support

For issues and questions:
- Open an issue on GitHub
- Email: support@worldmindos.com
- Documentation: https://docs.worldmindos.com

---

**Built with ❤️ for global data intelligence**
