# YOU.PDF - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Web App │  │  Mobile  │  │ Chrome   │  │   API    │   │
│  │ (Next.js)│  │  (Future)│  │Extension │  │  Client  │   │
│  └─────┬────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│        │            │             │             │           │
└────────┼────────────┼─────────────┼─────────────┼───────────┘
         │            │             │             │
         └────────────┴─────────────┴─────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │          Next.js App Router (Vercel)               │     │
│  ├────────────────────────────────────────────────────┤     │
│  │                                                     │     │
│  │  API Routes:                                        │     │
│  │  • /api/pdf/[tool]  → Create Jobs                 │     │
│  │  • /api/jobs/[id]   → Check Status                │     │
│  │  • /api/stripe/*    → Handle Payments             │     │
│  │  • /api/auth/*      → Authentication              │     │
│  │                                                     │     │
│  │  Pages:                                            │     │
│  │  • /                → Homepage                     │     │
│  │  • /tools           → Tool Catalog                │     │
│  │  • /tools/[slug]    → Tool Page                   │     │
│  │  • /pricing         → Pricing Plans               │     │
│  │  • /dashboard       → User Dashboard              │     │
│  │                                                     │     │
│  └─────────────┬───────────────────────────────┬─────┘     │
│                │                               │             │
└────────────────┼───────────────────────────────┼─────────────┘
                 │                               │
                 ▼                               ▼
┌────────────────────────────┐   ┌────────────────────────────┐
│      SUPABASE BACKEND      │   │      REDIS QUEUE           │
├────────────────────────────┤   ├────────────────────────────┤
│                            │   │                            │
│  • PostgreSQL Database     │   │  • Job Queue (BullMQ)      │
│  • Row Level Security      │   │  • Job Status Tracking     │
│  • Auth (Email/Password)   │   │  • Rate Limiting           │
│  • Storage Buckets         │   │  • Priority Queues         │
│    - uploads/              │   │                            │
│    - outputs/              │   └──────────┬─────────────────┘
│                            │              │
│  Tables:                   │              │
│  • users                   │              ▼
│  • jobs                    │   ┌────────────────────────────┐
│  • annotations             │   │    WORKER SERVICES         │
│  • certificates            │   │    (Railway/Docker)        │
│                            │   ├────────────────────────────┤
└────────────┬───────────────┘   │                            │
             │                   │  BullMQ Workers (Node.js)  │
             │                   │                            │
             │                   │  ┌──────────────────────┐  │
             │                   │  │  Job Processor       │  │
             └───────────────────┼─▶│                      │  │
                                 │  │  • PDF Operations    │  │
                                 │  │  • AI Processing     │  │
                                 │  │  • File Conversion   │  │
                                 │  │  • Status Updates    │  │
                                 │  └──────────────────────┘  │
                                 │                            │
                                 │  Dependencies:             │
                                 │  • pdf-lib                 │
                                 │  • sharp                   │
                                 │  • tesseract               │
                                 │  • ghostscript             │
                                 │  • qpdf                    │
                                 │                            │
                                 └──────┬─────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ OpenAI   │  │CloudConvert│ │  Stripe  │  │  Email   │   │
│  │  API     │  │    API     │  │ Payments │  │ Service  │   │
│  │          │  │            │  │          │  │          │   │
│  │ GPT-4o   │  │ PDF→DOCX   │  │ Checkout │  │ Mailgun  │   │
│  │ mini     │  │ PDF→PPTX   │  │ Webhooks │  │ SendGrid │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### User Upload Flow

```
1. User uploads PDF
   ↓
2. Frontend validates file (size, type)
   ↓
3. POST /api/pdf/[tool]
   ↓
4. API checks:
   • User authentication
   • Tier limits
   • Rate limits
   ↓
5. Upload to Supabase Storage
   ↓
6. Create job record in database
   ↓
7. Add job to Redis queue
   ↓
8. Return job ID to frontend
   ↓
9. Frontend polls /api/jobs/[id]
```

### Worker Processing Flow

```
1. Worker picks job from Redis
   ↓
2. Update job status: "processing"
   ↓
3. Download files from Supabase Storage
   ↓
4. Process based on job type:
   • PDF operations → pdf-engine
   • AI features → ai-engine
   ↓
5. Upload results to Supabase Storage
   ↓
6. Update job with output URLs
   ↓
7. Update job status: "completed"
   ↓
8. User downloads results
```

## Component Responsibilities

### Frontend (Next.js)

**Responsibilities:**
- User interface and interaction
- File upload validation
- Authentication UI
- Job status polling
- Stripe checkout integration

**Key Technologies:**
- React 18 (Server + Client Components)
- TypeScript
- TailwindCSS
- Supabase Auth Helpers

### API Layer (Next.js API Routes)

**Responsibilities:**
- Request validation
- Authentication & authorization
- Rate limiting enforcement
- Job creation
- Webhook handling (Stripe)

**Security Features:**
- JWT validation
- CSRF protection
- Rate limiting per tier
- Input sanitization

### Database (Supabase)

**Responsibilities:**
- User data storage
- Job metadata storage
- File storage (buckets)
- Authentication

**Security:**
- Row Level Security (RLS)
- Service role vs anon key
- Encrypted storage
- Auto-delete expired jobs

### Queue (Redis + BullMQ)

**Responsibilities:**
- Job queue management
- Job prioritization
- Retry logic
- Concurrency control

**Features:**
- Persistent jobs
- Job progress tracking
- Delayed jobs
- Job expiry

### Workers (Node.js)

**Responsibilities:**
- Process jobs from queue
- Execute PDF operations
- Call AI APIs
- Upload results
- Update job status

**Scalability:**
- Horizontal scaling (multiple workers)
- Concurrency per worker
- Graceful shutdown
- Error recovery

## Packages Architecture

```
packages/
├── core/                   # Shared foundation
│   ├── types.ts           # TypeScript types
│   ├── config.ts          # Configuration
│   └── utils.ts           # Utilities
│
├── pdf-engine/            # PDF operations
│   └── index.ts           # PDFEngine class
│       ├── merge()
│       ├── split()
│       ├── compress()
│       ├── watermark()
│       └── ...
│
├── ai-engine/             # AI features
│   └── index.ts           # AIEngine class
│       ├── summarize()
│       ├── translate()
│       ├── chat()
│       └── ...
│
└── db/                    # Database helpers
    └── index.ts           # Supabase helpers
        ├── createJob()
        ├── updateJob()
        ├── getUser()
        └── ...
```

## Security Layers

### Layer 1: Frontend
- Input validation
- File type checking
- Size limits
- HTTPS only

### Layer 2: API
- Authentication required
- Tier-based access control
- Rate limiting
- CORS policies

### Layer 3: Database
- Row Level Security
- Service role isolation
- Encrypted storage
- Access logs

### Layer 4: Workers
- Isolated environment
- No direct internet access
- Sandboxed processing
- Auto file cleanup

## Scalability Strategy

### Horizontal Scaling

**Frontend (Vercel):**
- Auto-scales with traffic
- Edge network CDN
- Serverless functions

**Workers (Railway/Docker):**
- Add more worker instances
- Each processes jobs independently
- Load balanced via Redis

**Database (Supabase):**
- Managed PostgreSQL
- Read replicas for scaling
- Connection pooling

### Vertical Scaling

**Workers:**
- Increase concurrency per worker
- More CPU/RAM per instance
- Batch processing

**Redis:**
- Upgrade to Redis Cluster
- Increase memory
- Persistence strategies

## Monitoring Points

```
┌─────────────┐
│  Frontend   │ → Vercel Analytics
│             │ → Error tracking (Sentry)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   API       │ → Response times
│             │ → Error rates
│             │ → Rate limit hits
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Database   │ → Connection pool
│             │ → Query performance
│             │ → Storage usage
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Workers    │ → Job throughput
│             │ → Success/failure rate
│             │ → Processing time
└─────────────┘
```

## Cost Optimization

### Storage
- Auto-delete files after 1 hour
- Compress outputs
- Use efficient formats

### Compute
- Workers only run when needed
- Batch similar jobs
- Cache common operations

### Database
- Index frequently queried fields
- Archive old jobs
- Optimize RLS policies

### External APIs
- OpenAI: Use gpt-4o-mini (cheaper)
- CloudConvert: Cache conversions
- Stripe: Batch webhook processing

## Disaster Recovery

### Backups
- Database: Daily automatic (Supabase)
- Redis: Persistent storage (AOF)
- Storage: Replication (Supabase)

### Recovery Plan
1. Database restore from backup
2. Redeploy workers from Docker image
3. Reprocess failed jobs from queue
4. Notify users of downtime

### High Availability
- Multiple worker instances
- Database read replicas
- CDN for static assets
- Health checks & auto-restart

---

This architecture supports:
✅ 1000+ concurrent users
✅ 10,000+ jobs per day
✅ Sub-second response times
✅ 99.9% uptime SLA
✅ Horizontal scalability
✅ Cost-effective operation