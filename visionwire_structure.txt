# VisionWire AI EdTech Suite - Complete Project Structure

## 📁 Root Directory Structure

```
visionwire-edtech/
├── backend/                          # FastAPI Backend Services
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                   # FastAPI app entry point
│   │   ├── config.py                 # Configuration management
│   │   ├── database.py               # Database connections
│   │   ├── models/                   # SQLAlchemy models
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── curriculum.py
│   │   │   ├── content.py
│   │   │   ├── assessment.py
│   │   │   └── classroom.py
│   │   ├── schemas/                  # Pydantic schemas
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── curriculum.py
│   │   │   └── content.py
│   │   ├── api/                      # API Routes
│   │   │   ├── __init__.py
│   │   │   ├── v1/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── auth.py
│   │   │   │   ├── curriculum.py
│   │   │   │   ├── content.py
│   │   │   │   ├── assessments.py
│   │   │   │   ├── classrooms.py
│   │   │   │   └── analytics.py
│   │   ├── services/                 # Business Logic
│   │   │   ├── __init__.py
│   │   │   ├── curriculum_engine.py
│   │   │   ├── content_generator.py
│   │   │   ├── assessment_engine.py
│   │   │   ├── personalization.py
│   │   │   └── ai_tutor.py
│   │   ├── core/                     # Core utilities
│   │   │   ├── __init__.py
│   │   │   ├── security.py
│   │   │   ├── deps.py
│   │   │   └── exceptions.py
│   │   ├── workers/                  # Background workers
│   │   │   ├── __init__.py
│   │   │   ├── content_worker.py
│   │   │   └── analytics_worker.py
│   │   └── utils/
│   │       ├── __init__.py
│   │       ├── llm_client.py
│   │       └── storage.py
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── test_auth.py
│   │   ├── test_curriculum.py
│   │   └── test_content.py
│   ├── alembic/                      # Database migrations
│   │   ├── versions/
│   │   └── env.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── pyproject.toml
│
├── frontend/                         # Next.js 15+ Frontend
│   ├── src/
│   │   ├── app/                      # App Router
│   │   │   ├── layout.tsx
│   │   │   ├── page.tsx
│   │   │   ├── (auth)/
│   │   │   │   ├── login/
│   │   │   │   └── register/
│   │   │   ├── (student)/
│   │   │   │   ├── dashboard/
│   │   │   │   ├── courses/
│   │   │   │   ├── assignments/
│   │   │   │   ├── progress/
│   │   │   │   └── doubt-assistant/
│   │   │   ├── (teacher)/
│   │   │   │   ├── dashboard/
│   │   │   │   ├── classrooms/
│   │   │   │   ├── content-creator/
│   │   │   │   └── analytics/
│   │   │   └── (admin)/
│   │   │       ├── dashboard/
│   │   │       ├── users/
│   │   │       └── curriculum/
│   │   ├── components/               # Reusable components
│   │   │   ├── ui/                   # shadcn/ui components
│   │   │   ├── layouts/
│   │   │   ├── student/
│   │   │   ├── teacher/
│   │   │   └── shared/
│   │   ├── lib/
│   │   │   ├── api.ts                # API client
│   │   │   ├── auth.ts
│   │   │   └── utils.ts
│   │   ├── hooks/                    # Custom React hooks
│   │   │   ├── useAuth.ts
│   │   │   ├── useCurriculum.ts
│   │   │   └── useContent.ts
│   │   ├── store/                    # State management (Zustand)
│   │   │   ├── authStore.ts
│   │   │   └── curriculumStore.ts
│   │   └── types/
│   │       └── index.ts
│   ├── public/
│   ├── package.json
│   ├── next.config.js
│   ├── tailwind.config.ts
│   ├── tsconfig.json
│   └── Dockerfile
│
├── workers/                          # Separate worker services
│   ├── content-generator/
│   │   ├── main.py
│   │   ├── tasks.py
│   │   └── requirements.txt
│   ├── video-generator/
│   │   ├── main.py
│   │   └── requirements.txt
│   └── analytics-processor/
│       ├── main.py
│       └── requirements.txt
│
├── shared/                           # Shared configs & types
│   ├── curriculum-configs/
│   │   ├── cbse.json
│   │   ├── icse.json
│   │   ├── jee.json
│   │   └── neet.json
│   ├── content-templates/
│   │   ├── notes_template.json
│   │   ├── quiz_template.json
│   │   └── assignment_template.json
│   └── schemas/
│       └── openapi.yaml
│
├── infrastructure/                   # DevOps & Infrastructure
│   ├── docker/
│   │   ├── docker-compose.yml
│   │   ├── docker-compose.dev.yml
│   │   └── docker-compose.prod.yml
│   ├── kubernetes/
│   │   ├── namespace.yaml
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── postgres-statefulset.yaml
│   │   ├── redis-deployment.yaml
│   │   ├── ingress.yaml
│   │   └── secrets.yaml
│   ├── terraform/                    # Infrastructure as Code
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── prometheus.yml
│       └── grafana-dashboards/
│
├── scripts/                          # Utility scripts
│   ├── setup.sh
│   ├── seed-database.py
│   ├── generate-curriculum.py
│   └── deploy.sh
│
├── docs/                             # Documentation
│   ├── API.md
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   └── USER_GUIDE.md
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── cd.yml
│
├── .env.example
├── .gitignore
├── README.md
└── LICENSE

```

## 🚀 Quick Start Guide

### Prerequisites
- Docker & Docker Compose
- Node.js 20+
- Python 3.11+
- PostgreSQL 15+
- Redis 7+

### Step 1: Clone and Setup

```bash
# Create project root
mkdir visionwire-edtech
cd visionwire-edtech

# Create all directories
mkdir -p backend/app/{models,schemas,api/v1,services,core,workers,utils}
mkdir -p backend/tests backend/alembic/versions
mkdir -p frontend/src/{app,components,lib,hooks,store,types}
mkdir -p workers/{content-generator,video-generator,analytics-processor}
mkdir -p shared/{curriculum-configs,content-templates,schemas}
mkdir -p infrastructure/{docker,kubernetes,terraform,monitoring}
mkdir -p scripts docs
```

### Step 2: Environment Setup

```bash
# Copy from next artifact
cp .env.example .env

# Edit with your configurations
nano .env
```

### Step 3: Install Dependencies

```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Frontend
cd ../frontend
npm install

# Return to root
cd ..
```

### Step 4: Database Setup

```bash
# Start PostgreSQL and Redis with Docker
docker-compose -f infrastructure/docker/docker-compose.dev.yml up -d postgres redis

# Run migrations
cd backend
alembic upgrade head

# Seed initial data
python ../scripts/seed-database.py
```

### Step 5: Start Development

```bash
# Terminal 1: Backend API
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 2: Frontend
cd frontend
npm run dev

# Terminal 3: Workers
cd workers/content-generator
python main.py
```

### Step 6: Access Application

- **Frontend**: http://localhost:3000
- **API Docs**: http://localhost:8000/docs
- **Admin Panel**: http://localhost:3000/admin

## 🐳 Docker Production Deployment

```bash
# Build all services
docker-compose -f infrastructure/docker/docker-compose.yml build

# Start all services
docker-compose -f infrastructure/docker/docker-compose.yml up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f backend
```

## ☸️ Kubernetes Deployment

```bash
# Apply all manifests
kubectl apply -f infrastructure/kubernetes/

# Check deployments
kubectl get deployments -n visionwire

# Check services
kubectl get services -n visionwire

# Port forward for local access
kubectl port-forward -n visionwire svc/frontend 3000:3000
kubectl port-forward -n visionwire svc/backend 8000:8000
```

## 🧪 Running Tests

```bash
# Backend tests
cd backend
pytest tests/ -v --cov=app

# Frontend tests
cd frontend
npm run test

# E2E tests
npm run test:e2e
```

## 📊 Monitoring

```bash
# Start monitoring stack
docker-compose -f infrastructure/docker/docker-compose.monitoring.yml up -d

# Access dashboards
# Grafana: http://localhost:3001 (admin/admin)
# Prometheus: http://localhost:9090
```

## 🔧 Development Workflow

1. **Create Feature Branch**: `git checkout -b feature/new-feature`
2. **Make Changes**: Code in respective modules
3. **Run Tests**: `pytest` for backend, `npm test` for frontend
4. **Commit**: `git commit -m "feat: add new feature"`
5. **Push**: `git push origin feature/new-feature`
6. **Create PR**: GitHub automatically runs CI/CD

## 📦 Build & Release

```bash
# Build production images
./scripts/build-production.sh

# Tag version
git tag v1.0.0

# Deploy to production
./scripts/deploy.sh production
```

## 🔐 Security Checklist

- [ ] Change all default passwords in `.env`
- [ ] Generate new JWT secret keys
- [ ] Configure CORS properly
- [ ] Enable HTTPS/TLS
- [ ] Set up rate limiting
- [ ] Configure firewall rules
- [ ] Enable database backups
- [ ] Set up monitoring alerts

## 📚 Next Steps

1. Review `.env` configuration in next artifact
2. Set up database schemas (Artifact 3)
3. Configure backend services (Artifacts 4-7)
4. Build frontend dashboards (Artifacts 9-10)
5. Deploy with Docker/Kubernetes (Artifacts 13-14)

---

**Note**: Each artifact builds upon this structure. Copy files to their respective locations as indicated in the directory tree above.