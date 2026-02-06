# YOU.PDF Setup Checklist

## ✅ Pre-Deployment Checklist

### 1. Development Environment

- [ ] Node.js 20+ installed
- [ ] Docker & Docker Compose installed
- [ ] Git repository initialized
- [ ] Dependencies installed (`npm install`)

### 2. Supabase Setup

- [ ] Created Supabase project
- [ ] Copied project URL and keys to `.env`
- [ ] Ran database migrations (`001_initial.sql`)
- [ ] Created storage buckets:
  - [ ] `uploads` bucket (private)
  - [ ] `outputs` bucket (private)
- [ ] Verified RLS policies are active
- [ ] Tested auth flow (signup/signin)

### 3. External Services

- [ ] OpenAI API key obtained
- [ ] CloudConvert API key obtained (optional)
- [ ] Stripe account created
- [ ] Stripe products & prices created:
  - [ ] Pro Monthly plan
  - [ ] Pro Yearly plan
  - [ ] Business Monthly plan
  - [ ] Business Yearly plan
- [ ] Stripe webhook endpoint configured

### 4. Redis & Workers

- [ ] Redis instance running (local or cloud)
- [ ] Worker Dockerfile builds successfully
- [ ] Workers connect to Redis
- [ ] Workers connect to Supabase
- [ ] Test job processing works

### 5. Frontend

- [ ] Next.js app builds without errors
- [ ] All environment variables set
- [ ] File upload works
- [ ] Job creation works
- [ ] Job progress polling works
- [ ] Download links work

## 🚀 Deployment Checklist

### Vercel (Frontend)

- [ ] Connected GitHub repository
- [ ] Set production environment variables:
  - [ ] `NEXT_PUBLIC_SUPABASE_URL`
  - [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - [ ] `SUPABASE_SERVICE_KEY`
  - [ ] `NEXT_PUBLIC_STRIPE_PUBLIC_KEY`
  - [ ] `STRIPE_SECRET_KEY`
  - [ ] `STRIPE_WEBHOOK_SECRET`
  - [ ] `REDIS_URL`
  - [ ] `OPENAI_API_KEY`
  - [ ] `CLOUDCONVERT_API_KEY`
- [ ] Configured custom domain
- [ ] Deployed successfully
- [ ] Verified all pages load
- [ ] Tested file upload end-to-end

### Railway (Workers)

- [ ] Created Railway project
- [ ] Added Redis service
- [ ] Built and pushed Docker image
- [ ] Deployed worker service
- [ ] Set environment variables (same as above)
- [ ] Verified workers are processing jobs
- [ ] Checked logs for errors

### GitHub Actions

- [ ] Added GitHub secrets:
  - [ ] `VERCEL_TOKEN`
  - [ ] `VERCEL_ORG_ID`
  - [ ] `VERCEL_PROJECT_ID`
  - [ ] `DOCKER_USERNAME`
  - [ ] `DOCKER_PASSWORD`
  - [ ] `RAILWAY_WEBHOOK_URL`
  - [ ] `NEXT_PUBLIC_SUPABASE_URL`
  - [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] Workflow runs successfully on push
- [ ] Frontend deploys automatically
- [ ] Workers deploy automatically

## 🔧 Post-Deployment

### Monitoring

- [ ] Set up Vercel Analytics
- [ ] Monitor Supabase Dashboard
- [ ] Set up error tracking (Sentry/LogRocket)
- [ ] Monitor Redis queue metrics
- [ ] Set up uptime monitoring

### Stripe Integration

- [ ] Test checkout flow
- [ ] Verify webhook events
- [ ] Test subscription creation
- [ ] Test subscription updates
- [ ] Verify tier access control

### Testing

- [ ] Test all 20+ tools
- [ ] Verify file size limits work
- [ ] Test rate limiting
- [ ] Test expired jobs cleanup
- [ ] Test error handling
- [ ] Load test with concurrent jobs

### Security

- [ ] Review RLS policies
- [ ] Audit API endpoints
- [ ] Check CORS settings
- [ ] Verify file upload restrictions
- [ ] Test authentication flows
- [ ] Review security headers

## 📋 Folder Structure Setup

```bash
mkdir -p you-pdf/{apps/{web,workers},packages/{core,pdf-engine,ai-engine,db},config/supabase}

# Copy all artifacts to respective folders:
# - Root files: package.json, turbo.json, .env.example, docker-compose.yml
# - apps/web: Next.js app files
# - apps/workers: Worker files + Dockerfile
# - packages/core: Shared types
# - packages/pdf-engine: PDF operations
# - packages/ai-engine: AI features
# - config/supabase: SQL migrations
# - .github/workflows: CI/CD
```

## 🐛 Common Issues

### Workers not processing jobs

1. Check Redis connection in worker logs
2. Verify environment variables
3. Check Supabase service key has proper permissions
4. Ensure buckets exist and are accessible

### File upload fails

1. Check file size limits in Next.js config
2. Verify Supabase storage buckets exist
3. Check RLS policies on storage
4. Verify CORS settings in Supabase

### AI tools timeout

1. Increase timeout limits in worker config
2. Check OpenAI API key and quotas
3. Add retry logic for API failures
4. Consider using streaming for long responses

### Rate limiting issues

1. Verify user tier in database
2. Check daily_usage counter resets
3. Review getTierLimits logic
4. Test with different user tiers

## 🎉 Launch Checklist

- [ ] All critical bugs fixed
- [ ] Documentation complete
- [ ] Pricing page finalized
- [ ] Payment flow tested
- [ ] Support email configured
- [ ] Terms of Service written
- [ ] Privacy Policy written
- [ ] GDPR compliance reviewed
- [ ] Marketing site ready
- [ ] Social media accounts created
- [ ] Beta users invited
- [ ] Monitoring dashboards set up
- [ ] Backup strategy in place

## 📞 Support Setup

- [ ] Create support email
- [ ] Set up help desk (Intercom/Zendesk)
- [ ] Create Discord community
- [ ] Write FAQ documentation
- [ ] Create video tutorials
- [ ] Set up status page

---

**Ready to launch? Double-check everything above, then hit deploy! 🚀**