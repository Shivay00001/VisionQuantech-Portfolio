# YOU.PDF Deployment Guide

Complete step-by-step guide to deploy YOU.PDF vX to production.

## 📋 Prerequisites

Before starting, ensure you have:
- [ ] GitHub account
- [ ] Vercel account
- [ ] Railway account (or alternative: Render, Fly.io)
- [ ] Supabase project
- [ ] OpenAI API key with credits
- [ ] Stripe account
- [ ] Domain name (optional)

## Phase 1: Local Setup & Testing

### Step 1: Clone and Install

```bash
# Clone repository
git clone <your-repo>
cd you-pdf

# Install dependencies
npm install

# Build packages
npm run build
```

### Step 2: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your credentials
nano .env
```

Required variables:
```env
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_KEY=eyJhbGc...
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=sk-...
CLOUDCONVERT_API_KEY=xxx (optional)
NEXT_PUBLIC_STRIPE_PUBLIC_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
```

### Step 3: Database Setup

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link project
supabase link --project-ref your-project-ref

# Apply migrations
supabase db push
```

Alternatively, run SQL manually in Supabase SQL Editor:
1. Go to Supabase Dashboard > SQL Editor
2. Copy contents of `config/supabase/migrations/001_initial.sql`
3. Execute

### Step 4: Create Storage Buckets

In Supabase Dashboard > Storage:

1. Create bucket `uploads`:
   - Public: No
   - File size limit: 500MB
   - Allowed MIME types: application/pdf, image/*

2. Create bucket `outputs`:
   - Public: No
   - File size limit: 500MB
   - Allowed MIME types: *

### Step 5: Local Testing

```bash
# Start Redis and Workers
docker-compose up -d

# In separate terminal, start Next.js
npm run dev

# Open http://localhost:3000
```

Test checklist:
- [ ] Homepage loads
- [ ] Can signup/signin
- [ ] Can upload a PDF
- [ ] Job is created
- [ ] Worker processes job
- [ ] Can download result

## Phase 2: Stripe Setup

### Step 1: Create Products

In Stripe Dashboard > Products:

1. **Pro Plan**
   - Name: "YOU.PDF Pro"
   - Monthly: $19/month (save price ID)
   - Yearly: $199/year (save price ID)

2. **Business Plan**
   - Name: "YOU.PDF Business"
   - Monthly: $99/month (save price ID)
   - Yearly: $999/year (save price ID)

### Step 2: Configure Webhook

1. Go to Stripe Dashboard > Developers > Webhooks
2. Add endpoint: `https://your-domain.com/api/stripe/webhook`
3. Select events:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.paid`
   - `invoice.payment_failed`
4. Copy webhook secret to `.env`

### Step 3: Update Environment

```env
STRIPE_PRICE_PRO_MONTHLY=price_xxx
STRIPE_PRICE_PRO_YEARLY=price_xxx
STRIPE_PRICE_BUSINESS_MONTHLY=price_xxx
STRIPE_PRICE_BUSINESS_YEARLY=price_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

## Phase 3: Deploy Workers (Railway)

### Step 1: Prepare Docker Image

```bash
# Test Docker build locally
docker build -t youpdf-workers -f apps/workers/Dockerfile .
docker run --env-file .env youpdf-workers

# Tag for registry
docker tag youpdf-workers yourusername/youpdf-workers:latest

# Push to Docker Hub
docker login
docker push yourusername/youpdf-workers:latest
```

### Step 2: Deploy to Railway

1. Go to Railway Dashboard
2. Create new project "YOU-PDF-Workers"

3. Add Redis service:
   - Click "New"
   - Select "Database" > "Redis"
   - Note the connection URL

4. Add Worker service:
   - Click "New"
   - Select "Docker Image"
   - Enter: `yourusername/youpdf-workers:latest`

5. Set environment variables in worker service:
   ```
   REDIS_URL=<from Redis service>
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_SERVICE_KEY=eyJhbGc...
   OPENAI_API_KEY=sk-...
   CLOUDCONVERT_API_KEY=xxx
   ```

6. Deploy!

### Step 3: Verify Workers

Check Railway logs:
```
✨ Worker is ready and listening for jobs...
```

Test by creating a job from your local frontend pointing to Railway Redis.

## Phase 4: Deploy Frontend (Vercel)

### Step 1: Connect Repository

1. Go to Vercel Dashboard
2. "Add New" > "Project"
3. Import your GitHub repository
4. Select root directory: `apps/web`

### Step 2: Configure Build Settings

- Framework Preset: `Next.js`
- Root Directory: `apps/web`
- Build Command: `cd ../.. && npm run build -w apps/web`
- Output Directory: `.next`

### Step 3: Set Environment Variables

Add all variables from `.env`:
```
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_KEY=...
REDIS_URL=<Railway Redis URL>
OPENAI_API_KEY=...
CLOUDCONVERT_API_KEY=...
NEXT_PUBLIC_STRIPE_PUBLIC_KEY=...
STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...
STRIPE_PRICE_PRO_MONTHLY=...
STRIPE_PRICE_PRO_YEARLY=...
STRIPE_PRICE_BUSINESS_MONTHLY=...
STRIPE_PRICE_BUSINESS_YEARLY=...
NEXT_PUBLIC_APP_URL=https://your-domain.vercel.app
```

### Step 4: Deploy

Click "Deploy" and wait.

Once deployed, test:
- [ ] Homepage loads
- [ ] All routes work
- [ ] Can signup/signin
- [ ] Can create jobs
- [ ] Jobs are processed
- [ ] Can download results

## Phase 5: Configure CI/CD

### Step 1: Add GitHub Secrets

In your GitHub repo > Settings > Secrets and variables > Actions:

```
VERCEL_TOKEN=<from Vercel Settings>
VERCEL_ORG_ID=<from Vercel Settings>
VERCEL_PROJECT_ID=<from Vercel Project Settings>

DOCKER_USERNAME=<your Docker Hub username>
DOCKER_PASSWORD=<your Docker Hub password>

RAILWAY_WEBHOOK_URL=<from Railway service settings>

NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

### Step 2: Test Workflow

```bash
# Make a change
git add .
git commit -m "test: CI/CD"
git push origin main

# Check GitHub Actions tab
```

Workflow should:
1. Run tests and lint
2. Deploy frontend to Vercel
3. Build and push Docker image
4. Trigger Railway deployment

## Phase 6: Custom Domain (Optional)

### For Vercel (Frontend)

1. Vercel Dashboard > Project > Settings > Domains
2. Add your domain: `app.youpdf.com`
3. Add DNS records as instructed
4. Wait for SSL certificate

### For Railway (Workers)

Workers don't need a custom domain (internal service).

## Phase 7: Post-Deployment

### Update Stripe Webhook URL

Change from localhost to production:
```
https://app.youpdf.com/api/stripe/webhook
```

### Update Supabase Auth URLs

In Supabase Dashboard > Authentication > URL Configuration:
- Site URL: `https://app.youpdf.com`
- Redirect URLs: `https://app.youpdf.com/auth/callback`

### Test Production

Complete end-to-end test:
1. Sign up new account
2. Upload test PDF
3. Process with multiple tools
4. Download results
5. Upgrade to Pro (test Stripe)
6. Verify tier upgrade works
7. Test AI features

### Set Up Monitoring

1. **Vercel**: Enable Analytics in project settings
2. **Railway**: Monitor service metrics in dashboard
3. **Supabase**: Monitor database usage
4. **Stripe**: Monitor payments and subscriptions

### Optional: Error Tracking

Add Sentry for error tracking:

```bash
npm install @sentry/nextjs
npx @sentry/wizard -i nextjs
```

## 🐛 Troubleshooting

### Workers Not Processing Jobs

**Problem**: Jobs stuck in "pending" status

**Solutions**:
1. Check Railway logs for errors
2. Verify Redis URL is correct
3. Check Supabase service key permissions
4. Ensure worker service is running
5. Test Redis connection:
   ```bash
   redis-cli -u $REDIS_URL ping
   ```

### File Upload Fails

**Problem**: Files don't upload to Supabase

**Solutions**:
1. Verify storage buckets exist
2. Check bucket policies:
   ```sql
   SELECT * FROM storage.policies WHERE bucket_id = 'uploads';
   ```
3. Test upload from SQL Editor:
   ```sql
   SELECT storage.upload('uploads', 'test.pdf', decode('test', 'base64'));
   ```

### Authentication Issues

**Problem**: Can't login or signup

**Solutions**:
1. Check Supabase Auth settings
2. Verify redirect URLs
3. Check email service is configured
4. Test with password recovery
5. Check browser console for errors

### Stripe Webhook Not Working

**Problem**: Subscriptions don't update user tier

**Solutions**:
1. Verify webhook URL is correct
2. Check webhook secret matches
3. View webhook logs in Stripe Dashboard
4. Test webhook locally with Stripe CLI:
   ```bash
   stripe listen --forward-to localhost:3000/api/stripe/webhook
   ```

### Rate Limiting Not Working

**Problem**: Users exceed tier limits

**Solutions**:
1. Verify `daily_usage` is incrementing
2. Check `usage_reset_at` logic
3. Test rate limit enforcement:
   ```sql
   SELECT id, email, tier, daily_usage, usage_reset_at 
   FROM users 
   WHERE id = 'user-id';
   ```

### AI Features Timeout

**Problem**: AI tools fail or timeout

**Solutions**:
1. Increase worker timeout (Railway settings)
2. Check OpenAI API key and credits
3. Monitor OpenAI API status
4. Reduce input text length
5. Add retry logic with exponential backoff

## 📊 Monitoring Checklist

Daily:
- [ ] Check Railway worker logs
- [ ] Monitor Stripe payments
- [ ] Review Supabase database size
- [ ] Check Redis memory usage

Weekly:
- [ ] Review error logs
- [ ] Monitor API response times
- [ ] Check user growth
- [ ] Review failed jobs

Monthly:
- [ ] Database backup
- [ ] Security audit
- [ ] Performance optimization
- [ ] User feedback review

## 🎉 Launch Checklist

Before public launch:
- [ ] All features working
- [ ] Payment flow tested
- [ ] Error handling complete
- [ ] Security audit done
- [ ] Legal pages complete (Privacy, Terms)
- [ ] Support email configured
- [ ] Documentation complete
- [ ] Marketing site ready
- [ ] Social media accounts
- [ ] Monitoring dashboards
- [ ] Backup strategy
- [ ] Scaling plan ready

---

**Congratulations! 🚀 Your production-grade SaaS is now live!**