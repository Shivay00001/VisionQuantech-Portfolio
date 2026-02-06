# Ethereum Network Configuration
ETH_RPC_URL=http://localhost:8545
CHAIN_ID=31337

# Contract Addresses (Fill after deployment)
YOU_DAO_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
AI_GUARDIAN_ADDRESS=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
TREASURY_ADDRESS=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

# Oracle Configuration
ORACLE_PRIVATE_KEY=your_oracle_private_key_here
ORACLE_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Deployer Configuration (for contract deployment)
DEPLOYER_PRIVATE_KEY=your_deployer_private_key_here

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# Database Configuration
DB_PATH=oracle.db

# API Configuration
API_PORT=8000
CORS_ORIGINS=http://localhost:3000

# Frontend Configuration
VITE_API_URL=http://localhost:8000

# Testnet Configuration (Optional)
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY
ETHERSCAN_API_KEY=your_etherscan_api_key

# Gas Configuration
MAX_GAS_PRICE_GWEI=50

# Oracle Loop Configuration
LOOP_INTERVAL=30
HEARTBEAT_CHECK_INTERVAL=300