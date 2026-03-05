# Deimos Project Refactoring Plan

## Executive Summary

The Deimos project is a client-side mobile benchmarking suite for zero-knowledge proofs. The current codebase contains several critical security vulnerabilities, production anti-patterns, code duplication issues, and missing environment configurations that need immediate attention. This refactoring plan addresses these issues systematically to improve security, maintainability, and production readiness.

**Current State:**
- Backend: Node.js/Express with Firebase integration
- Frontend: Next.js website dashboard  
- Benchmarking Suite: Multiple ZK frameworks (Circom, Noir, Cairo-M, MoPro)
- Mobile Apps: Flutter-based benchmarking applications

**Refactoring Goals:**
1. Eliminate security vulnerabilities and hardcoded credentials
2. Remove production anti-patterns and debug code
3. Consolidate duplicate assets and configurations
4. Implement proper environment configuration management
5. Establish production-ready logging and error handling
6. Create comprehensive testing strategy

---

## Critical Issues Identified

### 🔴 Security Vulnerabilities

#### 1. CORS Misconfiguration (High Priority)
**File:** `backend/middleware/cors.js:7`
**Issue:** Default wildcard origin (`'*'`) allows any domain to make requests
```javascript
// VULNERABLE CODE
origin: process.env.CORS_ORIGIN || '*',
```
**Solution:** Implement strict origin validation with environment-specific configuration

#### 2. Firebase Credentials Exposure (High Priority)
**File:** `backend/config/firebase.js:17`
**Issue:** Firebase credentials parsed from environment variable without validation
```javascript
// VULNERABLE CODE
const serviceAccount = JSON.parse(process.env.FIREBASE_ADMINSDK_CREDENTIALS);
```
**Solution:** Add credential validation and secure error handling

#### 3. Missing Environment Files (High Priority)
**Issue:** No `.env.example` templates exist for backend or frontend
**Impact:** Developers cannot properly configure environment variables
**Solution:** Create comprehensive environment templates

### 🟡 Production Anti-Patterns

#### 1. Debug Console Statements (Medium Priority)
**Files:** 
- `backend/controllers/benchmarkResultController.js:12-14`
- `backend/test-api.js` (entire file)
- `backend/populate-dummy-data.js` (multiple statements)
- `backend/utils/logger.js:6` (console.log fallback)

**Issue:** Production console.log statements expose sensitive data and affect performance
```javascript
// PROBLEMATIC CODE
console.log('\n=== Complete Data ===\n');
console.log(JSON.stringify(data, null, 2));
```
**Solution:** Implement proper logging with environment-based levels

#### 2. Hardcoded URLs (Medium Priority)
**Files:** Multiple documentation files contain hardcoded URLs
**Issue:** External URLs not configurable for different environments
**Solution:** Create URL configuration management

### 🟠 Code Duplication Issues

#### 1. Duplicate Assets (Medium Priority)
**Duplicate JSON Files:**
- Input files duplicated across frameworks:
  - `benchmarking-suite/frameworks/circom/inputs/`
  - `benchmarking-suite/frameworks/noir/inputs/`
  - `benchmarking-suite/moPro/mopro-example-app/flutter/inputs/`
- Test vectors duplicated:
  - `benchmarking-suite/moPro/mopro-example-app/flutter/assets/`
  - `benchmarking-suite/moPro/mopro-example-app/test-vectors/`

**Duplicate Images:**
- Framework logos duplicated:
  - `website/public/circom.png` vs `website/src/images/circom.png`
  - Similar duplicates for `flutter.svg`, `mopro.svg`, `noir.png`

#### 2. Configuration Duplication (Low Priority)
**Issue:** Multiple Cargo.toml and package.json files with similar dependencies
**Solution:** Create shared configuration templates

### 🟢 Architectural Improvements

#### 1. Missing Error Boundaries (Low Priority)
**Frontend:** No error boundaries for React components
**Backend:** Limited error handling in controllers

#### 2. No Input Validation (Medium Priority)
**File:** `backend/controllers/benchmarkResultController.js:10`
**Issue:** Request body not validated before processing
**Solution:** Implement request validation middleware

---

## Detailed Refactoring Plan

### Phase 1: Security Hardening (Week 1)

#### 1.1 Fix CORS Configuration
**Priority:** 🔴 High
**Files:** `backend/middleware/cors.js`

**Implementation:**
```javascript
// backend/middleware/cors.js
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, curl)
    if (!origin) return callback(null, true);
    
    const allowedOrigins = process.env.CORS_ORIGINS 
      ? process.env.CORS_ORIGINS.split(',')
      : ['http://localhost:3000', 'http://localhost:5173'];
    
    if (process.env.NODE_ENV === 'development' || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
};
```

#### 1.2 Secure Firebase Configuration
**Priority:** 🔴 High
**Files:** `backend/config/firebase.js`

**Implementation:**
```javascript
// backend/config/firebase.js
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '../.env') });

let admin, db;

try {
  if (!process.env.FIREBASE_ADMINSDK_CREDENTIALS) {
    throw new Error('FIREBASE_ADMINSDK_CREDENTIALS environment variable is not set');
  }

  const serviceAccount = JSON.parse(process.env.FIREBASE_ADMINSDK_CREDENTIALS);
  
  // Validate required Firebase fields
  const requiredFields = ['project_id', 'private_key', 'client_email'];
  for (const field of requiredFields) {
    if (!serviceAccount[field]) {
      throw new Error(`Missing required Firebase field: ${field}`);
    }
  }

  const firebaseAdmin = await import('firebase-admin');
  admin = firebaseAdmin.default;
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  
  db = admin.firestore();
  
} catch (error) {
  console.error('Failed to initialize Firebase:', error.message);
  process.exit(1);
}

export { admin, db };
```

#### 1.3 Create Environment Templates
**Priority:** 🔴 High
**Files:** 
- `backend/.env.example`
- `website/.env.example`

**Backend Environment Template:**
```bash
# backend/.env.example
# Server Configuration
NODE_ENV=development
PORT=5000

# Firebase Configuration
FIREBASE_ADMINSDK_CREDENTIALS='{"type":"service_account","project_id":"your-project-id","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-xxx@your-project-id.iam.gserviceaccount.com"}'

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# Logging Configuration
LOG_LEVEL=info
LOG_FILE_PATH=./logs/app.log

# API Configuration
API_RATE_LIMIT=100
API_TIMEOUT=30000
```

**Frontend Environment Template:**
```bash
# website/.env.example
# Next.js Configuration
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000

# API Configuration
NEXT_PUBLIC_API_BASE_URL=http://localhost:5000/api
NEXT_PUBLIC_API_TIMEOUT=30000

# Analytics (Optional)
NEXT_PUBLIC_GOOGLE_ANALYTICS_ID=
NEXT_PUBLIC_VERCEL_ANALYTICS_ID=

# Feature Flags
NEXT_PUBLIC_ENABLE_BENCHMARKS=true
NEXT_PUBLIC_ENABLE_DOCS=true
```

### Phase 2: Production Code Cleanup (Week 2)

#### 2.1 Remove Debug Console Statements
**Priority:** 🟡 Medium
**Files:** Multiple backend files

**Implementation:**
```javascript
// backend/utils/logger.js (Updated)
import fs from 'fs';
import path from 'path';

class Logger {
  constructor() {
    this.logLevel = process.env.LOG_LEVEL || 'info';
    this.logFile = process.env.LOG_FILE_PATH;
    this.levels = {
      error: 0,
      warn: 1,
      info: 2,
      debug: 3
    };
  }

  writeLog(level, message, ...args) {
    if (this.levels[level] > this.levels[this.logLevel]) {
      return;
    }

    const timestamp = new Date().toISOString();
    const logEntry = `[${level.toUpperCase()}] ${timestamp} - ${message} ${args.length ? JSON.stringify(args) : ''}\n`;

    // Console output for development
    if (process.env.NODE_ENV === 'development') {
      console[level] || console.log(`[${level.toUpperCase()}] ${timestamp} - ${message}`, ...args);
    }

    // File output for production
    if (this.logFile && process.env.NODE_ENV === 'production') {
      try {
        fs.appendFileSync(this.logFile, logEntry);
      } catch (error) {
        console.error('Failed to write to log file:', error);
      }
    }
  }

  info(message, ...args) { this.writeLog('info', message, ...args); }
  error(message, ...args) { this.writeLog('error', message, ...args); }
  warn(message, ...args) { this.writeLog('warn', message, ...args); }
  debug(message, ...args) { this.writeLog('debug', message, ...args); }
}

export const logger = new Logger();
```

#### 2.2 Clean Benchmark Controller
**Priority:** 🟡 Medium
**File:** `backend/controllers/benchmarkResultController.js`

**Implementation:**
```javascript
// backend/controllers/benchmarkResultController.js (Updated)
import { db } from '../config/firebase.js';
import { COLLECTION_NAMES } from '../config/constants.js';
import { logger } from '../utils/logger.js';

/**
 * Validate benchmark data structure
 */
const validateBenchmarkData = (data) => {
  const required = ['circuit', 'framework', 'language', 'deviceInfo'];
  const missing = required.filter(field => !data[field]);
  
  if (missing.length > 0) {
    throw new Error(`Missing required fields: ${missing.join(', ')}`);
  }
  
  // Validate deviceInfo structure
  if (!data.deviceInfo.platform || !data.deviceInfo.model) {
    throw new Error('deviceInfo must contain platform and model');
  }
  
  return true;
};

/**
 * Receive benchmark result data from mobile app
 */
export const receiveBenchmarkResult = async (req, res) => {
  try {
    const data = req.body;

    // Validate input data
    validateBenchmarkData(data);
    
    logger.debug('Received benchmark data', {
      circuit: data.circuit,
      framework: data.framework,
      language: data.language,
      platform: data.deviceInfo.platform
    });

    // Check for duplicate based on combination of circuit, framework, language, and device identifier
    const deviceId = data.deviceInfo?.androidId || data.deviceInfo?.iosId || data.deviceInfo?.deviceId;
    const circuit = data.circuit;
    const framework = data.framework;
    const language = data.language;

    if (deviceId && circuit && framework && language) {
      const existingSnapshot = await db.collection(COLLECTION_NAMES.BENCHMARKS)
        .where('deviceInfo.deviceId', '==', deviceId)
        .where('circuit', '==', circuit)
        .where('framework', '==', framework)
        .where('language', '==', language)
        .limit(1)
        .get();

      if (!existingSnapshot.empty) {
        logger.info(`Duplicate benchmark detected`, {
          circuit, framework, language, deviceId
        });
        
        return res.status(200).json({
          success: false,
          message: 'Benchmark data already exists for this circuit/framework/language/device combination',
          duplicate: true,
          deviceId,
          circuit,
          framework,
          language
        });
      }
    }

    // Add the benchmark data to Firestore
    const docRef = await db.collection(COLLECTION_NAMES.BENCHMARKS).add({
      ...data,
      createdAt: new Date().toISOString(),
      receivedAt: new Date().toISOString()
    });

    logger.info(`Benchmark data saved successfully`, {
      documentId: docRef.id,
      circuit: data.circuit,
      framework: data.framework
    });

    res.status(201).json({
      success: true,
      message: 'Benchmark result received and saved successfully',
      documentId: docRef.id,
      receivedAt: new Date().toISOString()
    });

  } catch (error) {
    logger.error('Error receiving benchmark result', {
      error: error.message,
      stack: error.stack
    });
    
    res.status(500).json({ 
      success: false,
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};
```

#### 2.3 Remove Test Files from Production
**Priority:** 🟡 Medium
**Files:** 
- `backend/test-api.js` (move to tests directory)
- `backend/populate-dummy-data.js` (move to scripts directory)

### Phase 3: Asset Consolidation (Week 3)

#### 3.1 Consolidate Duplicate Images
**Priority:** 🟠 Medium
**Files:** Website image directories

**Implementation:**
```bash
# Remove duplicate images from src/images
rm website/src/images/circom.png
rm website/src/images/flutter.svg
rm website/src/images/mopro.svg
rm website/src/images/noir.png

# Update imports to use public directory
# Update all components to reference /public images
```

#### 3.2 Create Shared Input Data
**Priority:** 🟠 Medium
**Files:** Benchmarking suite input files

**Implementation:**
```bash
# Create shared input directory
mkdir -p benchmarking-suite/shared/inputs

# Move common input files to shared location
mv benchmarking-suite/frameworks/circom/inputs/field_elements/* benchmarking-suite/shared/inputs/
mv benchmarking-suite/frameworks/circom/inputs/bytes/* benchmarking-suite/shared/inputs/

# Create symlinks or copy scripts for framework-specific inputs
```

#### 3.3 Consolidate Test Vectors
**Priority:** 🟠 Medium
**Files:** MoPro test vectors

**Implementation:**
```bash
# Create shared test vectors directory
mkdir -p benchmarking-suite/shared/test-vectors

# Move test vectors to shared location
mv benchmarking-suite/moPro/mopro-example-app/test-vectors/* benchmarking-suite/shared/test-vectors/

# Update references in mobile apps
```

### Phase 4: Input Validation & Error Handling (Week 4)

#### 4.1 Add Request Validation Middleware
**Priority:** 🟡 Medium
**File:** `backend/middleware/validation.js`

**Implementation:**
```javascript
// backend/middleware/validation.js
import Joi from 'joi';
import { logger } from '../utils/logger.js';

// Benchmark data validation schema
const benchmarkSchema = Joi.object({
  circuit: Joi.string().required(),
  framework: Joi.string().required(),
  language: Joi.string().required(),
  provingTime: Joi.number().positive().required(),
  verificationTime: Joi.number().positive().optional(),
  memoryUsage: Joi.number().positive().optional(),
  proofSize: Joi.number().positive().optional(),
  deviceInfo: Joi.object({
    platform: Joi.string().valid('android', 'ios').required(),
    model: Joi.string().required(),
    osVersion: Joi.string().optional(),
    deviceId: Joi.string().optional(),
    androidId: Joi.string().optional(),
    iosId: Joi.string().optional(),
    totalMemory: Joi.number().positive().optional(),
    availableMemory: Joi.number().positive().optional()
  }).required(),
  metadata: Joi.object().optional()
});

export const validateBenchmark = (req, res, next) => {
  const { error } = benchmarkSchema.validate(req.body);
  
  if (error) {
    logger.warn('Validation error', {
      error: error.details[0].message,
      body: req.body
    });
    
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: error.details[0].message
    });
  }
  
  next();
};
```

#### 4.2 Add Error Boundaries to Frontend
**Priority:** 🟢 Low
**File:** `website/src/components/error-boundary.tsx`

**Implementation:**
```typescript
// website/src/components/error-boundary.tsx
'use client';

import React from 'react';
import { logger } from '../lib/logger';

interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
}

interface ErrorBoundaryProps {
  children: React.ReactNode;
  fallback?: React.ComponentType<{ error?: Error; reset: () => void }>;
}

export class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    logger.error('React Error Boundary caught an error', {
      error: error.message,
      stack: error.stack,
      componentStack: errorInfo.componentStack
    });
  }

  reset = () => {
    this.setState({ hasError: false, error: undefined });
  };

  render() {
    if (this.state.hasError) {
      const FallbackComponent = this.props.fallback || DefaultErrorFallback;
      return <FallbackComponent error={this.state.error} reset={this.reset} />;
    }

    return this.props.children;
  }
}

function DefaultErrorFallback({ error, reset }: { error?: Error; reset: () => void }) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-semibold text-red-600 mb-4">
          Something went wrong
        </h2>
        <p className="text-gray-600 mb-4">
          {error?.message || 'An unexpected error occurred'}
        </p>
        <button
          onClick={reset}
          className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
        >
          Try again
        </button>
      </div>
    </div>
  );
}
```

---

## Environment Configuration

### Backend Environment Variables

```bash
# backend/.env.example
# ===========================================
# SERVER CONFIGURATION
# ===========================================
NODE_ENV=development
PORT=5000

# ===========================================
# FIREBASE CONFIGURATION
# ===========================================
# Get this from Firebase Console > Project Settings > Service Accounts
FIREBASE_ADMINSDK_CREDENTIALS='{"type":"service_account","project_id":"your-project-id","private_key":"-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-xxx@your-project-id.iam.gserviceaccount.com","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token"}'

# ===========================================
# CORS CONFIGURATION
# ===========================================
# Comma-separated list of allowed origins
CORS_ORIGINS=http://localhost:3000,http://localhost:5173,https://yourdomain.com

# ===========================================
# LOGGING CONFIGURATION
# ===========================================
LOG_LEVEL=info
LOG_FILE_PATH=./logs/app.log

# ===========================================
# API CONFIGURATION
# ===========================================
API_RATE_LIMIT=100
API_TIMEOUT=30000
API_KEY_REQUIRED=false

# ===========================================
# SECURITY CONFIGURATION
# ===========================================
JWT_SECRET=your-super-secret-jwt-key-here
SESSION_SECRET=your-super-secret-session-key-here

# ===========================================
# MONITORING CONFIGURATION
# ===========================================
SENTRY_DSN=
NEW_RELIC_LICENSE_KEY=
```

### Frontend Environment Variables

```bash
# website/.env.example
# ===========================================
# NEXT.JS CONFIGURATION
# ===========================================
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000

# ===========================================
# API CONFIGURATION
# ===========================================
NEXT_PUBLIC_API_BASE_URL=http://localhost:5000/api
NEXT_PUBLIC_API_TIMEOUT=30000

# ===========================================
# ANALYTICS CONFIGURATION
# ===========================================
NEXT_PUBLIC_GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
NEXT_PUBLIC_VERCEL_ANALYTICS_ID=

# ===========================================
# FEATURE FLAGS
# ===========================================
NEXT_PUBLIC_ENABLE_BENCHMARKS=true
NEXT_PUBLIC_ENABLE_DOCS=true
NEXT_PUBLIC_ENABLE_DARK_MODE=true
NEXT_PUBLIC_ENABLE_ANALYTICS=false

# ===========================================
# THIRD-PARTY SERVICES
# ===========================================
NEXT_PUBLIC_SENTRY_DSN=
NEXT_PUBLIC_ALGOLIA_APP_ID=
NEXT_PUBLIC_ALGOLIA_SEARCH_KEY=

# ===========================================
# DEVELOPMENT CONFIGURATION
# ===========================================
NEXT_PUBLIC_DEBUG_MODE=false
NEXT_PUBLIC_MOCK_API=false
```

---

## Testing Strategy

### Backend Testing

#### 1. Unit Tests
**Framework:** Jest + Supertest
**Coverage Goal:** 80%+

**Test Files:**
- `tests/controllers/benchmarkController.test.js`
- `tests/controllers/benchmarkResultController.test.js`
- `tests/middleware/cors.test.js`
- `tests/middleware/validation.test.js`
- `tests/config/firebase.test.js`

**Example Test:**
```javascript
// tests/controllers/benchmarkResultController.test.js
import request from 'supertest';
import { app } from '../../server.js';
import { db } from '../../config/firebase.js';

describe('Benchmark Result Controller', () => {
  beforeEach(async () => {
    // Clean up test data
    const snapshot = await db.collection('benchmarks').get();
    const deletePromises = snapshot.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
  });

  describe('POST /api/benchmarks', () => {
    it('should save valid benchmark data', async () => {
      const benchmarkData = {
        circuit: 'sha256',
        framework: 'circom',
        language: 'javascript',
        provingTime: 1500,
        deviceInfo: {
          platform: 'android',
          model: 'Pixel 6',
          deviceId: 'test-device-123'
        }
      };

      const response = await request(app)
        .post('/api/benchmarks')
        .send(benchmarkData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.documentId).toBeDefined();
    });

    it('should reject invalid data', async () => {
      const invalidData = {
        circuit: '',
        framework: 'circom',
        language: 'javascript'
      };

      const response = await request(app)
        .post('/api/benchmarks')
        .send(invalidData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should detect duplicates', async () => {
      const benchmarkData = {
        circuit: 'sha256',
        framework: 'circom',
        language: 'javascript',
        provingTime: 1500,
        deviceInfo: {
          platform: 'android',
          model: 'Pixel 6',
          deviceId: 'test-device-123'
        }
      };

      // First submission
      await request(app)
        .post('/api/benchmarks')
        .send(benchmarkData)
        .expect(201);

      // Duplicate submission
      const response = await request(app)
        .post('/api/benchmarks')
        .send(benchmarkData)
        .expect(200);

      expect(response.body.duplicate).toBe(true);
    });
  });
});
```

#### 2. Integration Tests
**Framework:** Jest + Firebase Emulator
**Coverage:** API endpoints, Firebase operations

#### 3. Security Tests
**Tools:** OWASP ZAP, Burp Suite
**Tests:** CORS validation, input sanitization, rate limiting

### Frontend Testing

#### 1. Unit Tests
**Framework:** Jest + React Testing Library
**Coverage Goal:** 70%+

**Test Files:**
- `website/src/components/__tests__/`
- `website/src/app/__tests__/`

#### 2. E2E Tests
**Framework:** Playwright
**Test Scenarios:**
- User navigation
- Benchmark data visualization
- Form submissions

### Benchmarking Suite Testing

#### 1. Circuit Validation
**Framework:** Custom test scripts
**Tests:** Circuit correctness, proof generation/verification

#### 2. Mobile App Testing
**Tools:** Flutter Test, Android Emulator, iOS Simulator
**Tests:** Benchmark execution, data submission, error handling

---

## Success Criteria

### Security Criteria ✅
- [ ] CORS properly configured with environment-specific origins
- [ ] Firebase credentials validated and securely handled
- [ ] All hardcoded credentials moved to environment variables
- [ ] Input validation implemented for all API endpoints
- [ ] Security audit passed (OWASP Top 10)

### Code Quality Criteria ✅
- [ ] All console.log statements removed from production code
- [ ] Debug code eliminated from production builds
- [ ] Code coverage ≥ 80% for backend, ≥ 70% for frontend
- [ ] ESLint/Prettier configurations implemented
- [ ] TypeScript strict mode enabled

### Architecture Criteria ✅
- [ ] Duplicate assets consolidated
- [ ] Shared configurations implemented
- [ ] Error boundaries added to frontend
- [ ] Proper logging implemented with environment-based levels
- [ ] API rate limiting and timeout configurations

### Environment Criteria ✅
- [ ] Complete .env.example templates created
- [ ] Environment-specific configurations implemented
- [ ] Development/staging/production environments differentiated
- [ ] Docker configurations for consistent environments

### Testing Criteria ✅
- [ ] Unit test suite implemented and passing
- [ ] Integration tests covering API endpoints
- [ ] E2E tests for critical user flows
- [ ] Security testing automated
- [ ] Performance testing baseline established

### Documentation Criteria ✅
- [ ] API documentation updated
- [ ] Environment setup guide created
- [ ] Deployment procedures documented
- [ ] Troubleshooting guide implemented

---

## Implementation Timeline

| Week | Phase | Tasks | Priority |
|------|-------|-------|----------|
| 1 | Security Hardening | CORS fix, Firebase security, Environment templates | 🔴 High |
| 2 | Production Cleanup | Console.log removal, Logger implementation, Test file cleanup | 🟡 Medium |
| 3 | Asset Consolidation | Image deduplication, Shared inputs, Test vector consolidation | 🟠 Medium |
| 4 | Validation & Error Handling | Input validation, Error boundaries, Security testing | 🟡 Medium |
| 5 | Testing Implementation | Unit tests, Integration tests, E2E tests | 🟡 Medium |
| 6 | Documentation & Deployment | API docs, Setup guides, Production deployment | 🟢 Low |

---

## Verification Methods

### Automated Verification
```bash
# Security scanning
npm audit
npm run security-scan

# Code quality
npm run lint
npm run typecheck
npm run test:coverage

# Environment validation
npm run validate:env
```

### Manual Verification Checklist
- [ ] CORS behavior tested in different environments
- [ ] Firebase connectivity verified with test credentials
- [ ] Console output verified in production build
- [ ] Asset loading verified after consolidation
- [ ] Error handling tested with invalid inputs

### Performance Monitoring
- [ ] API response time benchmarks
- [ ] Memory usage monitoring
- [ ] Error rate tracking
- [ ] User experience metrics

---

## Rollback Plan

If any refactoring step causes issues:

1. **Immediate Rollback:** Revert to previous commit using git
2. **Partial Rollback:** Disable specific features via environment variables
3. **Gradual Rollback:** Implement feature flags for new functionality
4. **Monitoring:** Enhanced logging during transition period

**Rollback Commands:**
```bash
# Emergency rollback
git revert HEAD --no-edit
git push origin main

# Feature flag rollback
export ENABLE_NEW_VALIDATION=false
export USE_LEGACY_LOGGER=true
```

---

## Post-Refactoring Maintenance

### Regular Tasks
- Weekly dependency updates
- Monthly security scans
- Quarterly performance reviews
- Annual architecture assessments

### Monitoring
- Error rate alerts
- Performance degradation notifications
- Security vulnerability notifications
- Resource usage monitoring

### Documentation Updates
- API changes
- Environment variable updates
- New feature documentation
- Troubleshooting guides

---

*This refactoring plan provides a comprehensive roadmap for improving the Deimos project's security, maintainability, and production readiness. Each phase includes specific implementation details, verification methods, and success criteria to ensure a successful transformation.*