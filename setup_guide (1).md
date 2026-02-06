# YOU.DAO Immortal Execution System - Complete Setup Guide

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Node.js 18+ installed (`node --version`)
- [ ] Python 3.11+ installed (`python --version`)
- [ ] Docker & Docker Compose installed
- [ ] Git installed
- [ ] At least 10 GB free disk space
- [ ] Ethereum wallet with some test ETH (for testnet)

## 🚀 Step-by-Step Setup

### Step 1: Project Setup

```bash
# Create project directory
mkdir you-dao-immortal-execution
cd you-dao-immortal-execution

# Initialize git (if cloning, skip this)
git init

# Create folder structure
mkdir -p contracts oracle api frontend scripts test abis
```

### Step 2: Install Node Dependencies

```bash
# Install Hardhat and dependencies
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts dotenv

# Initialize Hardhat (select "Create a TypeScript project")
npx hardhat init

# Install additional dependencies
npm install ethers@^6.4.0
```

### Step 3: Add Smart Contracts

Place these contracts in the `contracts/` folder:
- `YOUDAO.sol` - Core governance contract
- `YOUAIGuardian.sol` - AI Guardian contract
- `TreasuryMultiSig.sol` - Treasury contract

### Step 4: Configure Hardhat

Create/update `hardhat.config.ts`:

```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    hardhat: { chainId: 31337 },
    localhost: { url: "http://127.0.0.1:8545" }
  }
};

export default config;
```

### Step 5: Setup Python Oracle

```bash
cd oracle

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Mac/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

cd ..
```

### Step 6: Setup API

```bash
cd api

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

cd ..
```

### Step 7: Setup Frontend

```bash
cd frontend

# Initialize Vite React project
npm create vite@latest . -- --template react-ts

# Install dependencies
npm install
npm install react-router-dom recharts axios
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

cd ..
```

### Step 8: Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your values
nano .env
```

Required environment variables:
```bash
# Ethereum
ETH_RPC_URL=http://localhost:8545
CHAIN_ID=31337

# Oracle (generate a new private key for testing)
ORACLE_PRIVATE_KEY=0x...

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Database
DB_PATH=oracle.db
```

### Step 9: Deploy Smart Contracts

```bash
# Terminal 1: Start local Ethereum node
npx hardhat node

# Terminal 2: Compile and deploy contracts
npx hardhat compile
npx hardhat run scripts/deploy.ts --network localhost
```

**Important**: Copy the deployed contract addresses from the output!

Example output:
```
✓ TreasuryMultiSig deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
✓ YOUDAO deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
✓ YOUAIGuardian deployed to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

### Step 10: Update Configuration Files

Update `.env` with deployed addresses:
```bash
YOU_DAO_ADDRESS=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
AI_GUARDIAN_ADDRESS=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
TREASURY_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
```

Update `oracle/config.yaml`:
```yaml
contracts:
  you_dao_address: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
  ai_guardian_address: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
```

### Step 11: Start Services with Docker

```bash
# Build all containers
docker-compose build

# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f oracle
docker-compose logs -f api
docker-compose logs -f frontend
```

### Step 12: Verify Everything is Running

```bash
# Check service status
docker-compose ps

# Should show:
# - youdao_redis (running)
# - youdao_postgres (running)
# - youdao_oracle (running)
# - youdao_api (running)
# - youdao_frontend (running)

# Test API
curl http://localhost:8000/api/health

# Access frontend
open http://localhost:3000
```

## 🧪 Testing the System

### 1. Test Smart Contracts

```bash
# Run contract tests
npx hardhat test

# Check test coverage
npx hardhat coverage
```

### 2. Create a Test Proposal

```bash
# Using Hardhat console
npx hardhat console --network localhost

# In console:
const YOUDAO = await ethers.getContractFactory("YOUDAO");
const dao = await YOUDAO.attach("YOUR_DAO_ADDRESS");

# Stake first
await dao.stake({ value: ethers.parseEther("0.1") });

# Create proposal
await dao.createProposal(
  "Fund Research Initiative",
  "Allocate 1 ETH for AI research",
  ethers.parseEther("1"),
  "0xYourRecipientAddress",
  0 // Research category
);
```

### 3. Verify Oracle is Processing

```bash
# Check oracle logs
docker-compose logs -f oracle

# Should see:
# - "Processing Proposal #1"
# - AI analysis and decision
# - Transaction submission
```

### 4. View in Dashboard

Open http://localhost:3000 and verify:
- Dashboard shows metrics
- Governance page shows your proposal
- AI decision is recorded

## 🔧 Troubleshooting

### Issue: Oracle can't connect to Ethereum node

**Solution**: 
```bash
# Check if Hardhat node is running
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545

# If using Docker, use host.docker.internal instead of localhost
ETH_RPC_URL=http://host.docker.internal:8545
```

### Issue: Oracle has insufficient gas

**Solution**:
```bash
# Fund oracle address
npx hardhat console --network localhost

# Send ETH to oracle
await ethers.provider.getSigner(0).sendTransaction({
  to: "YOUR_ORACLE_ADDRESS",
  value: ethers.parseEther("1.0")
});
```

### Issue: Redis connection failed

**Solution**:
```bash
# Check if Redis is running
docker-compose ps redis

# Restart Redis
docker-compose restart redis

# Check Redis logs
docker-compose logs redis
```

### Issue: API can't find database

**Solution**:
```bash
# Check if oracle has created the database
ls -la oracle/oracle.db

# If missing, run oracle once manually
cd oracle
python you_ai_oracle.py
# Press Ctrl+C after initialization
```

### Issue: Frontend can't connect to API

**Solution**:
```bash
# Check API is running
curl http://localhost:8000/api/health

# Check CORS settings in api_server.py
# Verify VITE_API_URL in frontend/.env
```

## 🌐 Deploying to Testnet (Sepolia)

### 1. Get Testnet ETH

Visit https://sepoliafaucet.com/ and get some test ETH

### 2. Configure Testnet

Add to `.env`:
```bash
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
DEPLOYER_PRIVATE_KEY=your_deployer_key
ORACLE_PRIVATE_KEY=your_oracle_key
```

### 3. Deploy to Sepolia

```bash
npx hardhat run scripts/deploy.ts --network sepolia
```

### 4. Update Oracle Config

Update `oracle/config.yaml` with Sepolia settings:
```yaml
ethereum:
  rpc_url: "https://sepolia.infura.io/v3/YOUR_KEY"
  chain_id: 11155111
  is_poa: false
```

### 5. Restart Services

```bash
docker-compose down
docker-compose up -d
```

## 📊 Monitoring

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f oracle
docker-compose logs -f api
docker-compose logs -f frontend
```

### Check System Health

```bash
# API health
curl http://localhost:8000/api/health

# Check metrics
curl http://localhost:8000/api/metrics

# View proposals
curl http://localhost:8000/api/proposals
```

### Database Queries

```bash
# Connect to oracle database
sqlite3 oracle/oracle.db

# View decisions
SELECT * FROM decisions ORDER BY decision_timestamp DESC LIMIT 10;

# View proposals
SELECT * FROM proposals_cache;

# Exit
.exit
```

## 🎓 Next Steps

1. **Explore the Dashboard**: Navigate through all pages
2. **Create Test Proposals**: Try different categories
3. **Test Founder Heartbeat**: Stop sending heartbeats and see AI take over
4. **Issue Test Licenses**: Create IP licenses and pay royalties
5. **Add Council Members**: Test governance features
6. **Train Successors**: Add and certify successors

## 🔐 Production Checklist

Before going to production:

- [ ] Professional smart contract audit
- [ ] Comprehensive testing on testnet
- [ ] Security review of oracle code
- [ ] API rate limiting and authentication
- [ ] Frontend security headers
- [ ] Backup strategies for database
- [ ] Monitoring and alerting setup
- [ ] Disaster recovery plan
- [ ] Legal review of IP licensing
- [ ] Gas optimization
- [ ] Load testing
- [ ] Documentation complete

## 📚 Additional Resources

- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://react.dev/)
- [Docker Documentation](https://docs.docker.com/)

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review logs: `docker-compose logs -f`
3. Check GitHub Issues
4. Join our Discord community
5. Email: support@youdao.ai

---

**Congratulations! 🎉 Your YOU.DAO Immortal Execution System is now running!**
