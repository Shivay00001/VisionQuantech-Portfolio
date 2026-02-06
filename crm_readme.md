# 🚀 VisionQuantech Enterprise CRM

**Production-Grade, Scalable, Multi-Tenant CRM Platform**

Built with Node.js, TypeScript, Next.js 15, PostgreSQL, Redis, Kafka, and Elasticsearch.

---

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Environment Configuration](#environment-configuration)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Database Migrations](#database-migrations)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Contributing](#contributing)

---

## ✨ Features

### Core Features
- ✅ **Lead Management** - Capture, score, and route leads automatically
- ✅ **Contact Management** - 360° view of customer relationships
- ✅ **Pipeline Management** - Customizable sales pipelines
- ✅ **Activity Tracking** - Emails, calls, meetings, notes
- ✅ **Analytics & Reporting** - Real-time dashboards and custom reports
- ✅ **Workflow Automation** - Trigger-based actions and workflows
- ✅ **Multi-Tenant Support** - Complete data isolation per organization
- ✅ **Role-Based Access Control (RBAC)** - Granular permissions
- ✅ **Audit Logging** - Complete activity trail for compliance
- ✅ **Integrations** - Email, SMS, WhatsApp, Calendar, External CRMs

### Technical Features
- 🚀 **Microservices Architecture** - Independently scalable services
- ⚡ **Sub-200ms Response Times** - Redis caching + optimized queries
- 🔄 **Event-Driven** - Kafka/NATS for async processing
- 🗄️ **Database Sharding** - Horizontal scaling across 16 shards
- 🔍 **Full-Text Search** - Elasticsearch integration
- 📊 **Real-Time Metrics** - Prometheus + Grafana dashboards
- 🔐 **Enterprise Security** - JWT auth, encryption at rest, GDPR compliance
- 🌍 **Multi-Region Support** - Active-active deployment

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     CDN / WAF Layer                      │
│              (Cloudflare / CloudFront)                   │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                   API Gateway                            │
│            (Kong / Traefik + Auth)                       │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──────┐ ┌──▼──────┐ ┌──▼─────────┐
│ Lead Service │ │ Contact │ │ Pipeline   │
│              │ │ Service │ │ Service    │
└──────┬───────┘ └────┬────┘ └─────┬──────┘
       │              │            │
       └──────────────┼────────────┘
                      │
         ┌────────────▼────────────┐
         │   Event Bus (Kafka)     │
         └────────────┬────────────┘
                      │
         ┌────────────▼────────────┐
         │   Background Workers    │
         │  - Lead Dispatch        │
         │  - Batch Processor      │
         │  - Watchlist Scheduler  │
         └─────────────────────────┘
```

---

## 📦 Prerequisites

- **Node.js** 18+ and npm/yarn
- **Docker** & Docker Compose
- **Git**
- **PostgreSQL** 15+ (or use Docker)
- **Redis** 7+ (or use Docker)

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/visionquantech/crm-platform.git
cd crm-platform
```

### 2. Create Project Structure

```bash
mkdir -p backend frontend workers infrastructure database monitoring
```

### 3. Setup Backend

```bash
cd backend
npm init -y
npm install express cors helmet dotenv pg ioredis kafkajs joi bcrypt jsonwebtoken winston prom-client bull nodemailer twilio aws-sdk uuid date-fns
npm install -D typescript tsx @types/node @types/express @types/cors @types/bcrypt @types/jsonwebtoken @types/nodemailer @types/uuid ts-jest jest eslint

# Copy the artifacts into respective files:
# - package.json → backend/package.json
# - .env.example → backend/.env
# - src/index.ts → backend/src/index.ts
# - src/services/lead.service.ts → backend/src/services/lead.service.ts

# Initialize TypeScript
npx tsc --init
```

### 4. Setup Frontend

```bash
cd ../frontend
npx create-next-app@latest . --typescript --tailwind --app --no-src-dir
npm install lucide-react

# Copy app/page.tsx from the artifact
```

### 5. Setup Database

```bash
cd ../database

# Copy schema.sql from the artifact
# Copy seed.sql (create sample data)
```

### 6. Setup Infrastructure

```bash
cd ../infrastructure

# Copy docker-compose.yml from the artifact
```

### 7. Environment Variables

Create `.env` files in each service:

**backend/.env**
```bash
cp backend/.env.example backend/.env
# Edit with your actual values
```

---

## 🐳 Running the Application

### Using Docker Compose (Recommended for Development)

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Service URLs:
- **Frontend**: http://localhost:3001
- **Backend API**: http://localhost:3000
- **Grafana**: http://localhost:3002 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)

### Manual Setup (Without Docker)

**1. Start PostgreSQL**
```bash
psql -U postgres
CREATE DATABASE crm_db;
\q
psql -U postgres -d crm_db -f database/schema.sql
```

**2. Start Redis**
```bash
redis-server
```

**3. Start Backend**
```bash
cd backend
npm run dev
```

**4. Start Frontend**
```bash
cd frontend
npm run dev
```

**5. Start Workers**
```bash
cd workers
npm run dev
```

---

## 📁 Project Structure

```
visionquantech-crm/
├── backend/
│   ├── src/
│   │   ├── index.ts              # Main entry point
│   │   ├── services/             # Business logic
│   │   │   ├── lead.service.ts
│   │   │   ├── contact.service.ts
│   │   │   ├── pipeline.service.ts
│   │   │   └── activity.service.ts
│   │   ├── routes/               # API routes
│   │   ├── middleware/           # Express middleware
│   │   ├── adapters/             # Python module adapters
│   │   ├── database/             # DB connection
│   │   ├── cache/                # Redis manager
│   │   ├── events/               # Kafka manager
│   │   ├── monitoring/           # Metrics
│   │   └── utils/                # Helper functions
│   ├── package.json
│   ├── tsconfig.json
│   └── Dockerfile
│
├── frontend/
│   ├── app/
│   │   ├── page.tsx              # Dashboard
│   │   ├── leads/                # Lead pages
│   │   ├── contacts/             # Contact pages
│   │   ├── pipelines/            # Pipeline pages
│   │   └── layout.tsx            # Root layout
│   ├── components/               # Reusable components
│   ├── lib/                      # API client
│   ├── package.json
│   └── Dockerfile
│
├── workers/
│   ├── src/
│   │   ├── lead-dispatch.worker.ts
│   │   ├── batch-processor.worker.ts
│   │   └── watchlist-scheduler.worker.ts
│   └── package.json
│
├── database/
│   ├── schema.sql                # Database schema
│   ├── seed.sql                  # Sample data
│   └── migrations/               # Version migrations
│
├── infrastructure/
│   ├── docker-compose.yml        # Local dev stack
│   ├── kubernetes/               # K8s manifests
│   │   ├── backend.yaml
│   │   ├── frontend.yaml
│   │   └── workers.yaml
│   └── terraform/                # IaC for cloud
│
└── monitoring/
    ├── prometheus.yml
    ├── grafana-dashboards/
    └── alerts.yml
```

---

## 🔌 API Documentation

### Authentication
All API requests require a JWT token in the Authorization header:

```bash
Authorization: Bearer <your-jwt-token>
```

### Base URL
```
http://localhost:3000/api/v1
```

### Key Endpoints

#### Leads
```bash
# Create Lead
POST /leads
{
  "first_name": "Rajesh",
  "last_name": "Kumar",
  "email": "rajesh@example.com",
  "company": "Tech Corp",
  "phone": "+91-9876543210"
}

# List Leads
GET /leads?status=new&page=1&limit=50

# Get Lead
GET /leads/{leadId}

# Update Lead
PATCH /leads/{leadId}

# Delete Lead
DELETE /leads/{leadId}

# Bulk Import
POST /leads/bulk-import
```

#### Contacts
```bash
POST /contacts
GET /contacts
GET /contacts/{contactId}
PATCH /contacts/{contactId}
DELETE /contacts/{contactId}
```

#### Pipelines & Deals
```bash
POST /pipelines
GET /pipelines
POST /deals
GET /deals
PATCH /deals/{dealId}/stage
```

#### Analytics
```bash
GET /analytics/leads/stats
GET /analytics/deals/revenue
GET /analytics/funnel
```

---

## 🗄️ Database Migrations

```bash
# Run migrations
npm run migrate

# Rollback
npm run migrate:rollback

# Seed data
npm run seed
```

---

## 🚀 Deployment

### Production Checklist

- [ ] Set strong `JWT_SECRET` and `REFRESH_TOKEN_SECRET`
- [ ] Use managed PostgreSQL (AWS RDS / GCP Cloud SQL)
- [ ] Use managed Redis (ElastiCache / Memorystore)
- [ ] Enable SSL/TLS for all connections
- [ ] Set up monitoring alerts
- [ ] Configure backup strategy (daily snapshots)
- [ ] Enable audit logging
- [ ] Set up CDN for static assets
- [ ] Configure rate limiting
- [ ] Enable CORS for production domains only

### Kubernetes Deployment

```bash
# Apply manifests
kubectl apply -f infrastructure/kubernetes/

# Check status
kubectl get pods -n crm

# View logs
kubectl logs -f deployment/crm-backend -n crm
```

### Terraform (AWS Example)

```bash
cd infrastructure/terraform/aws
terraform init
terraform plan
terraform apply
```

---

## 📊 Monitoring

### Grafana Dashboards
- **Lead Metrics**: Conversion rates, lead scores, sources
- **API Performance**: Request rates, latency, errors
- **Database Health**: Query times, connection pools
- **Worker Status**: Queue depths, processing times

### Prometheus Metrics
- `crm_leads_created_total`
- `crm_api_request_duration_seconds`
- `crm_db_query_duration_seconds`
- `crm_cache_hit_rate`

### Jaeger Tracing
Track distributed transactions across microservices at http://localhost:16686

---

## 🧪 Testing

```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# Load testing
npm run test:load
```

---

## 🔒 Security

- ✅ JWT-based authentication
- ✅ Bcrypt password hashing (12 rounds)
- ✅ Rate limiting (100 req/min per IP)
- ✅ Helmet.js security headers
- ✅ SQL injection prevention (parameterized queries)
- ✅ XSS protection
- ✅ CSRF tokens
- ✅ Data encryption at rest
- ✅ Audit logging

---

## 📝 License

MIT License - see LICENSE file

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📞 Support

- **Email**: support@visionquantech.com
- **Docs**: https://docs.visionquantech.com
- **Issues**: https://github.com/visionquantech/crm/issues

---

## 🎯 Roadmap

### Q1 2025
- [ ] Mobile app (React Native)
- [ ] Advanced AI lead scoring
- [ ] Video call integration
- [ ] WhatsApp Business API

### Q2 2025
- [ ] Multi-language support (10+ languages)
- [ ] Advanced forecasting
- [ ] CPQ (Configure, Price, Quote)
- [ ] Partner portal

---

**Built with ❤️ by VisionQuantech Team**