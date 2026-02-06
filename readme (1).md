# YOU.PDF vX - Production-Grade SaaS Platform

A complete, production-ready PDF tools SaaS platform with 20+ tools including core PDF operations, conversions, editing, and AI-powered features.

## 🚀 Features

### Core PDF Operations
- Merge, split, compress PDFs
- Rotate, delete, extract pages
- Organize and manipulate documents

### Conversions
- PDF ↔ Word, Excel, PowerPoint
- PDF ↔ Images (JPG, PNG)
- Multiple format support

### Editing & Enhancement
- Add watermarks
- Add page numbers
- Headers & footers
- OCR text extraction

### AI-Powered Tools
- AI Summarize (multiple formats)
- AI Translate (7+ languages)
- Chat with PDF (Q&A)
- Resume analyzer
- Book notes generator
- Quiz & flashcard creator
- Invoice & contract parser

## 🏗️ Tech Stack

- **Frontend**: Next.js 14, React 18, TypeScript, TailwindCSS
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Queue**: BullMQ + Redis
- **Workers**: Node.js with pdf-lib, Sharp, Tesseract
- **AI**: OpenAI GPT-4o-mini
- **Payment**: Stripe
- **Deployment**: Vercel (frontend) + Railway (workers)

## 📦 Project Structure

```
you-pdf/
├── apps/
│   ├── web/              # Next.js frontend
│   │   ├── app/          # App Router pages
│   │   ├── components/   # React components
│   │   └── lib/          # Utilities
│   └── workers/          # BullMQ workers
│       └── src/          # Worker logic
├── packages/
│   ├── core/             # Shared types & config
│   ├── pdf-engine/       # PDF operations
│   ├── ai-engine/        # AI features
│   └── db/               # Database helpers
├── config/
│   └── supabase/         # Migrations & RLS
├── docker-compose.yml    # Local dev setup
└── .github/workflows/    # CI/CD
```

## 🛠️ Setup Instructions

### Prerequisites

- Node.js 20+
- Docker & Docker Compose
- Supabase account
- OpenAI API key
- Stripe account (for payments)
- CloudConvert API key (optional, for advanced conversions)

### 1. Clone & Install

```bash
# Clone the repository
git clone <your-repo-url>
cd you-pdf

# Install dependencies
npm install
```

### 2. Environment Setup

Create `.env` file in the root:

```bash
cp .env.example .env
```

Fill in your credentials:

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key

# Redis
REDIS_URL=redis://localhost:6379

# OpenAI
OPENAI_API_KEY=sk-your-openai-key

# Stripe
NEXT_PUBLIC_STRIPE_PUBLIC_KEY=pk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# CloudConvert (optional)
CLOUDCONVERT_API_KEY=your-key
```

### 3. Database Setup

```bash
# Install Supabase CLI
npm install -g supabase

# Link your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push --db-url "postgresql://..."

# Or manually run the SQL in config/supabase/migrations/001_initial.sql
```

### 4. Local Development

```bash
# Start Redis + Workers
docker-compose up -d

# Start Next.js dev server
npm run dev

# Or start individually:
npm run web:dev      # Frontend
npm run workers:dev  # Workers
```

Visit `http://localhost:3000`

### 5. Build for Production

```bash
# Build all packages
npm run build

# Start production servers
docker-compose -f docker-compose.prod.yml up -d
```

## 🚀 Deployment

### Frontend (Vercel)

1. Connect your GitHub repo to Vercel
2. Set environment variables in Vercel dashboard
3. Deploy automatically on push to main

```bash
# Or deploy manually
cd apps/web
vercel --prod
```

### Workers (Railway/Docker)

1. Build Docker image:

```bash
docker build -t youpdf-workers -f apps/workers/Dockerfile .
docker push your-registry/youpdf-workers:latest
```

2. Deploy to Railway:
   - Create new project
   - Add Redis service
   - Add worker service from Docker image
   - Set environment variables

### CI/CD

GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically:
- Runs tests & linting
- Deploys frontend to Vercel
- Builds & deploys workers to Railway

## 🔐 Security

- Row Level Security (RLS) enabled on all tables
- Files automatically deleted after 1 hour
- Rate limiting per user tier
- Secure file upload/download with Supabase Storage
- API key authentication for programmatic access

## 📊 Monitoring

### Database
- Monitor via Supabase Dashboard
- Check RLS policies are working
- Review slow queries

### Workers
- Monitor Redis queue in BullUI (optional)
- Check worker logs for errors
- Monitor job success/failure rates

### Application
- Use Vercel Analytics
- Monitor API response times
- Track user tier distribution

## 🧪 Testing

```bash
# Run all tests
npm run test

# Lint code
npm run lint

# Format code
npm run format
```

## 📝 API Usage

### Create Job

```typescript
POST /api/pdf/merge-pdf

FormData:
- files: File[]
- options: JSON string

Response:
{
  jobId: "uuid",
  message: "Job created successfully"
}
```

### Check Job Status

```typescript
GET /api/jobs/:id

Response:
{
  job: {
    id: "uuid",
    status: "completed",
    progress: 100,
    output: {
      urls: ["https://..."]
    }
  }
}
```

## 🎯 Tier Limits

| Feature | Free | Pro | Business |
|---------|------|-----|----------|
| Daily Jobs | 10 | 500 | 5,000 |
| Max File Size | 10MB | 100MB | 500MB |
| Files per Job | 5 | 25 | 100 |
| AI Tools | ❌ | ✅ | ✅ |
| API Access | ❌ | ❌ | ✅ |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

- Documentation: `/docs`
- Email: support@youpdf.com
- Discord: [Join our community]

## 🗺️ Roadmap

- [ ] Chrome Extension
- [ ] Desktop App (Electron)
- [ ] Mobile Apps (React Native)
- [ ] Webhook support
- [ ] Custom branding for Business tier
- [ ] Advanced OCR with layout preservation
- [ ] Batch processing API
- [ ] Team collaboration features

---

Built with ❤️ using Next.js, Supabase, and OpenAI