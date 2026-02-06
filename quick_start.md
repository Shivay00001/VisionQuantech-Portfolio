# YOU.PDF - Quick Start Guide (10 Minutes)

Get YOU.PDF running locally in 10 minutes.

## Prerequisites

- Node.js 20+
- Docker Desktop
- Supabase account
- OpenAI API key

## Step 1: Clone & Install (2 min)

```bash
git clone <your-repo>
cd you-pdf
npm install
```

## Step 2: Setup Supabase (3 min)

1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Copy Project URL and anon key
4. Go to SQL Editor, paste this:

```sql
-- Copy entire content from config/supabase/migrations/001_initial.sql
-- and execute
```

5. Go to Storage > Create two buckets:
   - `uploads` (private)
   - `outputs` (private)

## Step 3: Configure Environment (1 min)

```bash
cp .env.example .env
nano .env
```

Minimum required:
```env
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_KEY=eyJhbGc...
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=sk-...
```

## Step 4: Start Services (2 min)

```bash
# Terminal 1: Start Redis + Workers
docker-compose up -d

# Terminal 2: Start Next.js
npm run dev
```

## Step 5: Test (2 min)

1. Open http://localhost:3000
2. Click "Sign Up" - create account
3. Go to "Tools" > "Merge PDF"
4. Upload 2 PDFs
5. Click "Process"
6. Download merged PDF

✅ **Done!** You now have a working local setup.

## Common Commands

```bash
# View worker logs
docker-compose logs -f worker

# Rebuild after changes
npm run build

# Reset database
# In Supabase SQL Editor: DROP SCHEMA public CASCADE; CREATE SCHEMA public;
# Then re-run migration

# Clean everything
docker-compose down -v
npm run clean
rm -rf node_modules
```

## Next Steps

1. **Add Stripe** (for payments)
   - Get test keys from [stripe.com](https://stripe.com)
   - Add to `.env`

2. **Deploy to Production**
   - Follow `DEPLOYMENT.md`

3. **Customize**
   - Edit `apps/web/app/page.tsx` for homepage
   - Add tools in `apps/web/lib/tools-data.ts`
   - Modify worker logic in `apps/workers/src/processor.ts`

## Troubleshooting

**Workers not starting?**
```bash
docker-compose logs worker
# Check for connection errors
```

**Can't upload files?**
- Verify Supabase buckets exist
- Check storage policies in SQL Editor

**AI features failing?**
- Verify OpenAI API key has credits
- Check worker logs for errors

## File Structure Quick Reference

```
you-pdf/
├── apps/
│   ├── web/              # Frontend (Next.js)
│   │   ├── app/          # Pages
│   │   ├── components/   # React components
│   │   └── lib/          # Utils
│   └── workers/          # Background jobs
│       └── src/
│           ├── index.ts      # Worker entry
│           └── processor.ts  # Job processing
├── packages/
│   ├── core/             # Shared types
│   ├── pdf-engine/       # PDF operations
│   ├── ai-engine/        # AI features
│   └── db/               # Database helpers
└── config/
    └── supabase/         # SQL migrations
```

## Key Files to Modify

| Want to... | Edit this file |
|------------|----------------|
| Add a new tool | `apps/web/lib/tools-data.ts` |
| Change homepage | `apps/web/app/page.tsx` |
| Add job processor | `apps/workers/src/processor.ts` |
| Modify PDF logic | `packages/pdf-engine/src/index.ts` |
| Add AI feature | `packages/ai-engine/src/index.ts` |
| Update database | `config/supabase/migrations/*.sql` |

## Support

- 📖 Docs: `README.md`
- 🚀 Deploy: `DEPLOYMENT.md`
- ✅ Checklist: `SETUP_CHECKLIST.md`
- 🐛 Issues: GitHub Issues

Happy coding! 🎉