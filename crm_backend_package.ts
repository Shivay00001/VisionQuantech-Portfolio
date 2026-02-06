{
  "name": "@visionquantech/crm-backend",
  "version": "1.0.0",
  "description": "Enterprise CRM Backend Services",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "lint": "eslint src/**/*.ts",
    "migrate": "tsx src/database/migrate.ts",
    "seed": "tsx src/database/seed.ts"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "dotenv": "^16.3.1",
    "pg": "^8.11.3",
    "ioredis": "^5.3.2",
    "kafkajs": "^2.2.4",
    "joi": "^17.11.0",
    "bcrypt": "^5.1.1",
    "jsonwebtoken": "^9.0.2",
    "winston": "^3.11.0",
    "prom-client": "^15.1.0",
    "bull": "^4.12.0",
    "nodemailer": "^6.9.7",
    "twilio": "^4.19.0",
    "aws-sdk": "^2.1498.0",
    "uuid": "^9.0.1",
    "date-fns": "^2.30.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.0",
    "@types/cors": "^2.8.17",
    "@types/bcrypt": "^5.0.2",
    "@types/jsonwebtoken": "^9.0.5",
    "@types/nodemailer": "^6.4.14",
    "@types/uuid": "^9.0.7",
    "typescript": "^5.3.2",
    "tsx": "^4.7.0",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.10",
    "ts-jest": "^29.1.1",
    "eslint": "^8.54.0",
    "@typescript-eslint/eslint-plugin": "^6.13.1",
    "@typescript-eslint/parser": "^6.13.1"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}