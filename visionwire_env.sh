# VisionWire AI EdTech Suite - Environment Configuration
# Copy this to .env and update with your actual values

# =============================================================================
# APPLICATION SETTINGS
# =============================================================================
NODE_ENV=development
ENVIRONMENT=development
APP_NAME=VisionWire
APP_VERSION=1.0.0
DEBUG=true

# =============================================================================
# BACKEND API SETTINGS
# =============================================================================
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000
API_V1_PREFIX=/api/v1
BACKEND_CORS_ORIGINS=["http://localhost:3000","http://localhost:3001"]

# =============================================================================
# FRONTEND SETTINGS
# =============================================================================
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_WS_URL=ws://localhost:8000

# =============================================================================
# DATABASE - PostgreSQL
# =============================================================================
DATABASE_URL=postgresql://visionwire:visionwire_secure_pass@localhost:5432/visionwire_db
POSTGRES_USER=visionwire
POSTGRES_PASSWORD=visionwire_secure_pass
POSTGRES_DB=visionwire_db
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# Database Pool Settings
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=10
DB_POOL_TIMEOUT=30
DB_POOL_RECYCLE=3600

# =============================================================================
# REDIS CACHE & QUEUE
# =============================================================================
REDIS_URL=redis://localhost:6379/0
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=

# Cache TTL (seconds)
CACHE_TTL_SHORT=300        # 5 minutes
CACHE_TTL_MEDIUM=1800      # 30 minutes
CACHE_TTL_LONG=3600        # 1 hour
CACHE_TTL_EXTENDED=86400   # 24 hours

# =============================================================================
# VECTOR DATABASE - Qdrant
# =============================================================================
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=
QDRANT_COLLECTION_NAME=visionwire_embeddings

# =============================================================================
# ELASTICSEARCH / TYPESENSE (Search)
# =============================================================================
SEARCH_ENGINE=typesense  # Options: elasticsearch, typesense
TYPESENSE_HOST=localhost
TYPESENSE_PORT=8108
TYPESENSE_API_KEY=xyz
TYPESENSE_PROTOCOL=http

# =============================================================================
# AUTHENTICATION & SECURITY
# =============================================================================
# JWT Settings
SECRET_KEY=your-super-secret-key-change-this-in-production-min-32-chars
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30

# Supabase Auth (Optional)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# OAuth Providers (Optional)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=http://localhost:3000/auth/callback/google

# Password Hashing
BCRYPT_ROUNDS=12

# =============================================================================
# AI & LLM SERVICES
# =============================================================================
# Primary LLM Provider (openai, anthropic, ollama, groq)
LLM_PROVIDER=anthropic

# Anthropic Claude
ANTHROPIC_API_KEY=your-anthropic-api-key
ANTHROPIC_MODEL=claude-sonnet-4-20250514
ANTHROPIC_MAX_TOKENS=4096

# OpenAI GPT
OPENAI_API_KEY=your-openai-api-key
OPENAI_MODEL=gpt-4-turbo-preview
OPENAI_MAX_TOKENS=4096

# Ollama (Local)
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama2

# Groq (Fast Inference)
GROQ_API_KEY=your-groq-api-key
GROQ_MODEL=mixtral-8x7b-32768

# Embedding Model
EMBEDDING_MODEL=text-embedding-3-small
EMBEDDING_DIMENSIONS=1536

# AI Generation Settings
AI_TEMPERATURE=0.7
AI_TOP_P=0.9
AI_FREQUENCY_PENALTY=0.0
AI_PRESENCE_PENALTY=0.0

# Content Generation Limits
MAX_NOTES_LENGTH=5000
MAX_QUIZ_QUESTIONS=50
MAX_DIAGRAM_COMPLEXITY=20

# =============================================================================
# OBJECT STORAGE
# =============================================================================
# Storage Provider (s3, r2, minio, local)
STORAGE_PROVIDER=local

# AWS S3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=us-east-1
AWS_S3_BUCKET=visionwire-content

# Cloudflare R2
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=visionwire-content

# MinIO (Self-hosted S3-compatible)
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=visionwire-content
MINIO_SECURE=false

# Local Storage
LOCAL_STORAGE_PATH=/var/visionwire/storage

# CDN
CDN_URL=https://cdn.visionwire.com

# =============================================================================
# EMAIL & NOTIFICATIONS
# =============================================================================
# Email Provider (smtp, sendgrid, ses, postmark)
EMAIL_PROVIDER=smtp

# SMTP Settings
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@visionwire.com
SMTP_FROM_NAME=VisionWire

# SendGrid
SENDGRID_API_KEY=

# AWS SES
SES_REGION=us-east-1
SES_FROM_EMAIL=noreply@visionwire.com

# SMS Provider (twilio, sns)
SMS_PROVIDER=twilio
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_FROM_NUMBER=+1234567890

# Push Notifications (Firebase)
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=

# =============================================================================
# BACKGROUND JOBS & WORKERS
# =============================================================================
# Queue Backend (redis, rabbitmq, sqs)
QUEUE_BACKEND=redis
CELERY_BROKER_URL=redis://localhost:6379/1
CELERY_RESULT_BACKEND=redis://localhost:6379/2

# Worker Settings
WORKER_CONCURRENCY=4
WORKER_MAX_TASKS_PER_CHILD=1000
WORKER_TASK_TIME_LIMIT=3600

# Job Priorities
PRIORITY_HIGH=10
PRIORITY_MEDIUM=5
PRIORITY_LOW=1

# =============================================================================
# CURRICULUM & CONTENT SETTINGS
# =============================================================================
# Supported Boards
SUPPORTED_BOARDS=["CBSE","ICSE","STATE_BOARD","JEE","NEET","SAT","UPSC"]

# Supported Languages
SUPPORTED_LANGUAGES=["en","hi","mr","ta","te","gu"]
DEFAULT_LANGUAGE=en

# Content Format Support
ENABLE_PDF_GENERATION=true
ENABLE_EPUB_GENERATION=true
ENABLE_VIDEO_GENERATION=false
ENABLE_AUDIO_GENERATION=false
ENABLE_DIAGRAM_GENERATION=true

# Curriculum Versioning
CURRICULUM_VERSION=2024.1
AUTO_UPDATE_CURRICULUM=false

# =============================================================================
# ANALYTICS & TRACKING
# =============================================================================
# Analytics Provider (posthog, mixpanel, amplitude, custom)
ANALYTICS_PROVIDER=posthog

# PostHog
NEXT_PUBLIC_POSTHOG_KEY=
NEXT_PUBLIC_POSTHOG_HOST=https://app.posthog.com

# Mixpanel
MIXPANEL_TOKEN=

# Custom Analytics
ANALYTICS_ENDPOINT=

# Feature Flags
ENABLE_FEATURE_FLAGS=true
FEATURE_FLAG_PROVIDER=posthog

# =============================================================================
# MONITORING & LOGGING
# =============================================================================
# Logging Level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
LOG_LEVEL=INFO
LOG_FORMAT=json

# Sentry Error Tracking
SENTRY_DSN=
SENTRY_ENVIRONMENT=development
SENTRY_TRACES_SAMPLE_RATE=0.1

# Prometheus Metrics
ENABLE_METRICS=true
METRICS_PORT=9090

# Health Check
HEALTH_CHECK_INTERVAL=30

# =============================================================================
# RATE LIMITING & SECURITY
# =============================================================================
# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_PER_MINUTE=60
RATE_LIMIT_PER_HOUR=1000
RATE_LIMIT_PER_DAY=10000

# CORS
CORS_ALLOW_CREDENTIALS=true
CORS_ALLOW_METHODS=["GET","POST","PUT","DELETE","PATCH"]
CORS_ALLOW_HEADERS=["*"]

# Security Headers
ENABLE_HELMET=true
ENABLE_CSRF=true
ENABLE_XSS_PROTECTION=true

# Content Security Policy
CSP_ENABLED=true

# =============================================================================
# PAYMENT & MONETIZATION
# =============================================================================
# Payment Provider (stripe, razorpay, paypal)
PAYMENT_PROVIDER=stripe

# Stripe
STRIPE_PUBLISHABLE_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=

# Razorpay
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
RAZORPAY_WEBHOOK_SECRET=

# Subscription Plans
ENABLE_SUBSCRIPTIONS=true
ENABLE_FREEMIUM=true
FREE_TIER_LIMITS={"courses":3,"assessments":10,"storage_mb":100}

# =============================================================================
# FEATURE FLAGS
# =============================================================================
ENABLE_LIVE_CLASSES=false
ENABLE_AI_TUTOR=true
ENABLE_GAMIFICATION=true
ENABLE_COLLABORATIVE_LEARNING=true
ENABLE_PARENT_PORTAL=true
ENABLE_OFFLINE_MODE=true
ENABLE_MULTI_LANGUAGE=true
ENABLE_DARK_MODE=true

# =============================================================================
# DEVELOPMENT & TESTING
# =============================================================================
# Development Tools
ENABLE_DEBUG_TOOLBAR=true
ENABLE_API_DOCS=true
ENABLE_PLAYGROUND=true

# Testing
TEST_DATABASE_URL=postgresql://test_user:test_pass@localhost:5432/test_visionwire_db
MOCK_LLM_RESPONSES=false
SKIP_EMAIL_SENDING=true

# Seeding
SEED_DATABASE=false
SEED_ADMIN_EMAIL=admin@visionwire.com
SEED_ADMIN_PASSWORD=Admin@123

# =============================================================================
# PRODUCTION OVERRIDES
# =============================================================================
# Use these in production deployment
# ENVIRONMENT=production
# DEBUG=false
# DATABASE_URL=postgresql://user:pass@prod-db:5432/visionwire_prod
# REDIS_URL=redis://prod-redis:6379/0
# SECRET_KEY=generate-a-strong-random-key-for-production
# SENTRY_DSN=your-production-sentry-dsn
# CDN_URL=https://cdn.visionwire.com
# NEXT_PUBLIC_API_URL=https://api.visionwire.com
# ENABLE_DEBUG_TOOLBAR=false
# SKIP_EMAIL_SENDING=false