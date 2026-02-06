#!/bin/bash

# ============================================
# VisionQuantech CRM - Complete Setup Script
# ============================================
# This script sets up the entire CRM platform
# Usage: ./setup.sh [dev|prod]
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Environment
ENVIRONMENT=${1:-dev}

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════╗"
echo "║   VisionQuantech CRM Setup Script             ║"
echo "║   Environment: ${ENVIRONMENT}                          ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================
# Prerequisites Check
# ============================================
check_prerequisites() {
    echo -e "${BLUE}[1/10] Checking prerequisites...${NC}"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js not found. Please install Node.js 18+${NC}"
        exit 1
    fi
    NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "${RED}❌ Node.js version must be 18 or higher (current: $NODE_VERSION)${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Node.js $(node -v)${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker not found. Please install Docker${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker $(docker --version)${NC}"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker Compose $(docker-compose --version)${NC}"
    
    # Check Git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git not found. Please install Git${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Git $(git --version)${NC}"
}

# ============================================
# Create Project Structure
# ============================================
create_structure() {
    echo -e "${BLUE}[2/10] Creating project structure...${NC}"
    
    mkdir -p backend/src/{services,routes,middleware,adapters,database,cache,events,monitoring,utils}
    mkdir -p frontend/{app,components,lib}
    mkdir -p workers/src
    mkdir -p database/{migrations,seeds}
    mkdir -p infrastructure/{docker,kubernetes,terraform}
    mkdir -p monitoring/{prometheus,grafana}
    mkdir -p .github/workflows
    
    echo -e "${GREEN}✓ Project structure created${NC}"
}

# ============================================
# Setup Backend
# ============================================
setup_backend() {
    echo -e "${BLUE}[3/10] Setting up backend...${NC}"
    
    cd backend
    
    # Initialize package.json if not exists
    if [ ! -f "package.json" ]; then
        cat > package.json <<EOF
{
  "name": "@visionquantech/crm-backend",
  "version": "1.0.0",
  "description": "Enterprise CRM Backend",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "migrate": "tsx src/database/migrate.ts"
  }
}
EOF
    fi
    
    # Install dependencies
    echo -e "${YELLOW}Installing backend dependencies...${NC}"
    npm install --silent express cors helmet dotenv pg ioredis kafkajs joi bcrypt jsonwebtoken winston prom-client bull nodemailer twilio aws-sdk uuid date-fns
    npm install --silent -D typescript tsx @types/node @types/express @types/cors @types/bcrypt @types/jsonwebtoken @types/nodemailer @types/uuid ts-jest jest eslint
    
    # Initialize TypeScript
    if [ ! -f "tsconfig.json" ]; then
        npx tsc --init --rootDir src --outDir dist --esModuleInterop --resolveJsonModule --lib es2022 --module commonjs --target es2022 --noImplicitAny --strict
    fi
    
    # Create .env if not exists
    if [ ! -f ".env" ]; then
        cp .env.example .env 2>/dev/null || cat > .env <<EOF
NODE_ENV=${ENVIRONMENT}
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=crm_db
DB_USER=postgres
DB_PASSWORD=postgres
REDIS_HOST=localhost
REDIS_PORT=6379
KAFKA_BROKERS=localhost:9092
JWT_SECRET=$(openssl rand -hex 32)
EOF
    fi
    
    cd ..
    echo -e "${GREEN}✓ Backend setup complete${NC}"
}

# ============================================
# Setup Frontend
# ============================================
setup_frontend() {
    echo -e "${BLUE}[4/10] Setting up frontend...${NC}"
    
    if [ ! -d "frontend/node_modules" ]; then
        cd frontend
        
        # Check if Next.js is initialized
        if [ ! -f "package.json" ]; then
            echo -e "${YELLOW}Initializing Next.js...${NC}"
            npx create-next-app@latest . --typescript --tailwind --app --no-src-dir --import-alias "@/*" --use-npm
        fi
        
        npm install --silent lucide-react
        
        # Create .env.local
        if [ ! -f ".env.local" ]; then
            cat > .env.local <<EOF
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1
EOF
        fi
        
        cd ..
    fi
    
    echo -e "${GREEN}✓ Frontend setup complete${NC}"
}

# ============================================
# Setup Workers
# ============================================
setup_workers() {
    echo -e "${BLUE}[5/10] Setting up workers...${NC}"
    
    cd workers
    
    if [ ! -f "package.json" ]; then
        cat > package.json <<EOF
{
  "name": "@visionquantech/crm-workers",
  "version": "1.0.0",
  "description": "CRM Background Workers",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  }
}
EOF
        npm install --silent bull ioredis dotenv pg
        npm install --silent -D typescript tsx @types/node
    fi
    
    cd ..
    echo -e "${GREEN}✓ Workers setup complete${NC}"
}

# ============================================
# Setup Database
# ============================================
setup_database() {
    echo -e "${BLUE}[6/10] Setting up database...${NC}"
    
    # Wait for PostgreSQL to be ready
    if [ "$ENVIRONMENT" = "dev" ]; then
        echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
        for i in {1..30}; do
            if docker exec crm-postgres pg_isready -U postgres &> /dev/null; then
                break
            fi
            sleep 2
        done
        
        # Run migrations
        echo -e "${YELLOW}Running database migrations...${NC}"
        docker exec -i crm-postgres psql -U postgres -d crm_db < database/schema.sql
        
        echo -e "${GREEN}✓ Database initialized${NC}"
    fi
}

# ============================================
# Setup Docker
# ============================================
setup_docker() {
    echo -e "${BLUE}[7/10] Setting up Docker containers...${NC}"
    
    if [ "$ENVIRONMENT" = "dev" ]; then
        # Pull images
        echo -e "${YELLOW}Pulling Docker images...${NC}"
        docker-compose pull
        
        # Start containers
        echo -e "${YELLOW}Starting Docker containers...${NC}"
        docker-compose up -d
        
        # Wait for services to be healthy
        echo -e "${YELLOW}Waiting for services to be healthy...${NC}"
        sleep 10
        
        # Check health
        docker-compose ps
    fi
    
    echo -e "${GREEN}✓ Docker containers started${NC}"
}

# ============================================
# Create Dockerfiles
# ============================================
create_dockerfiles() {
    echo -e "${BLUE}[8/10] Creating Dockerfiles...${NC}"
    
    # Backend Dockerfile
    cat > backend/Dockerfile <<'EOF'
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./
USER nodejs
EXPOSE 3000
CMD ["node", "dist/index.js"]
EOF

    # Frontend Dockerfile
    cat > frontend/Dockerfile <<'EOF'
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
COPY --from=builder --chown=nodejs:nodejs /app/.next ./.next
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./
COPY --from=builder --chown=nodejs:nodejs /app/public ./public
USER nodejs
EXPOSE 3000
CMD ["npm", "start"]
EOF

    echo -e "${GREEN}✓ Dockerfiles created${NC}"
}

# ============================================
# Initialize Git
# ============================================
init_git() {
    echo -e "${BLUE}[9/10] Initializing Git repository...${NC}"
    
    if [ ! -d ".git" ]; then
        git init
        
        # Create .gitignore
        cat > .gitignore <<EOF
node_modules/
dist/
.next/
.env
.env.local
*.log
coverage/
.DS_Store
EOF
        
        git add .
        git commit -m "Initial commit: VisionQuantech CRM setup"
    fi
    
    echo -e "${GREEN}✓ Git repository initialized${NC}"
}

# ============================================
# Print Summary
# ============================================
print_summary() {
    echo -e "${BLUE}[10/10] Setup complete!${NC}"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Setup Successful! 🎉                 ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo ""
    echo "1. Review and update .env files with your credentials"
    echo "2. Start the services:"
    echo "   ${GREEN}docker-compose up${NC}"
    echo ""
    echo "3. Access the application:"
    echo "   Frontend:  ${BLUE}http://localhost:3001${NC}"
    echo "   Backend:   ${BLUE}http://localhost:3000${NC}"
    echo "   Grafana:   ${BLUE}http://localhost:3002${NC} (admin/admin)"
    echo "   Prometheus: ${BLUE}http://localhost:9090${NC}"
    echo "   MinIO:     ${BLUE}http://localhost:9001${NC} (minioadmin/minioadmin)"
    echo ""
    echo "4. Run database migrations:"
    echo "   ${GREEN}cd backend && npm run migrate${NC}"
    echo ""
    echo -e "${YELLOW}For production deployment:${NC}"
    echo "   ${GREEN}./setup.sh prod${NC}"
    echo ""
}

# ============================================
# Main Execution
# ============================================
main() {
    check_prerequisites
    create_structure
    setup_backend
    setup_frontend
    setup_workers
    create_dockerfiles
    setup_docker
    setup_database
    init_git
    print_summary
}

# Run main function
main