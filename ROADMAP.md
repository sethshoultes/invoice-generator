# Roadmap

## Milestone 1: Core Invoice Generator ✅ (Complete)

**Goal:** Browser-based invoice generator that extracts charges from bank statements using Claude API

### Prerequisites
- [x] Anthropic API key with Claude Sonnet access
- [x] Modern browser with JavaScript enabled

### Features
- [x] Bank statement upload (PNG, JPEG, PDF)
- [x] Claude API integration with vision capabilities
- [x] Structured extraction via tool use (record_invoice_items)
- [x] Editable line items table (date, description, qty, price)
- [x] Invoice details form (client info, project, dates)
- [x] PDF preview and export via html2pdf.js
- [x] Pre-filled company information (SWS Management Services)

### Enhancements
- [x] Multi-PDF upload (process multiple statements, append items)
- [x] API key persistence (obfuscated in localStorage)
- [x] Saved client profiles (save/select/delete from dropdown)
- [x] Native date pickers for all date fields
- [x] Auto-generated invoice numbers (MMDDYYYY-1 format)
- [x] Submitted date editable

### Documentation
- [x] README.md with usage guide
- [x] CLAUDE.md for AI agent context
- [x] GitHub repository setup

**Completed:** 2025-11-26
**Outcome:** Fully functional invoice generator ready for daily use

---

## Milestone 2: Hosted Service MVP (IN PROGRESS)

**Goal:** Deploy invoice digitization as a hosted service on Google Cloud (Firebase)

**Architecture:** Firebase Hosting + Cloud Functions + Firestore + Firebase Auth

**Principles:** KISS, YAGNI, DRY, PSR, LEAN

---

### Phase 1: Project Setup & Infrastructure ⏳

**Goal:** Set up Firebase project and development environment

- [ ] Create Firebase project in Google Cloud Console
- [ ] Install Firebase CLI (`npm install -g firebase-tools`)
- [ ] Initialize Firebase in project (`firebase init`)
  - [ ] Enable Firestore
  - [ ] Enable Cloud Functions
  - [ ] Enable Hosting
  - [ ] Enable Cloud Storage
  - [ ] Enable Authentication
- [ ] Create `service/` directory structure
  - [ ] `service/functions/` (backend)
  - [ ] `service/frontend/` (React SPA)
- [ ] Set up TypeScript configuration
  - [ ] `functions/tsconfig.json` (Node.js target)
  - [ ] `frontend/tsconfig.json` (browser target)
- [ ] Set up shared types directory
- [ ] Configure ESLint + Prettier
- [ ] Add `package.json` scripts for dev/build/deploy
- [ ] Store Anthropic API key in Secret Manager
  - [ ] `firebase functions:secrets:set ANTHROPIC_API_KEY`

**Deliverable:** Clean project structure with Firebase initialized

---

### Phase 2: Backend - Cloud Functions Setup ⏳

**Goal:** Create API foundation with authentication middleware

- [ ] Create `functions/src/index.ts` entry point
- [ ] Set up Express.js for HTTP functions
- [ ] Create middleware:
  - [ ] `authenticate.ts` - Verify Firebase Auth tokens
  - [ ] `errorHandler.ts` - Structured error responses
  - [ ] `validateRequest.ts` - Request validation
- [ ] Define shared TypeScript types in `functions/src/types/`:
  - [ ] `Invoice.ts` - Invoice data structure
  - [ ] `LineItem.ts` - Line item structure
  - [ ] `Client.ts` - Client profile structure
  - [ ] `User.ts` - User profile structure
  - [ ] `ApiResponse.ts` - Standard API response format
  - [ ] `ApiError.ts` - Error response format
- [ ] Create `functions/src/utils/`:
  - [ ] `constants.ts` - Usage limits, defaults
  - [ ] `dateHelpers.ts` - Date formatting utilities
- [ ] Test basic function deployment
  - [ ] Deploy hello-world function
  - [ ] Verify function is callable

**Deliverable:** Working Cloud Functions with middleware and types

---

### Phase 3: Backend - Claude Service Integration ⏳

**Goal:** Implement Claude API service for invoice extraction

- [ ] Create `functions/src/services/claudeService.ts`
  - [ ] Initialize Anthropic SDK with API key from secrets
  - [ ] Implement `extractInvoiceItems(base64Image, mimeType)` function
  - [ ] Use tool use pattern from V1 (`record_invoice_items`)
  - [ ] Handle errors (API failures, rate limits)
  - [ ] Return structured line items
- [ ] Create `functions/src/services/firestoreService.ts`
  - [ ] `createUser(userId, email)` - Initialize user profile
  - [ ] `getUser(userId)` - Get user data
  - [ ] `getUserUsage(userId, month)` - Get usage stats
  - [ ] `incrementUsage(userId, apiCost)` - Track usage
  - [ ] `checkUsageLimit(userId)` - Verify under limit
- [ ] Create `functions/src/services/storageService.ts`
  - [ ] `uploadFile(userId, file)` - Save to Cloud Storage
  - [ ] `getFileUrl(userId, fileId)` - Get signed URL
  - [ ] `deleteFile(userId, fileId)` - Remove file
- [ ] Test Claude extraction with sample images
  - [ ] Test with bank statement image
  - [ ] Test with PDF
  - [ ] Verify structured output matches schema

**Deliverable:** Working Claude extraction service with Firestore/Storage integration

---

### Phase 4: Backend - Core API Endpoints ⏳

**Goal:** Implement all RESTful API endpoints

#### Extraction Endpoint
- [ ] `POST /api/extract-invoice`
  - [ ] Authenticate user
  - [ ] Check usage limit
  - [ ] Upload file to Cloud Storage
  - [ ] Call Claude service
  - [ ] Track usage in Firestore
  - [ ] Return extracted line items
  - [ ] Handle errors (quota exceeded, invalid file, API failure)

#### Invoice CRUD
- [ ] `GET /api/invoices`
  - [ ] Authenticate user
  - [ ] Query user's invoices from Firestore
  - [ ] Support pagination (limit, offset)
  - [ ] Return invoice list
- [ ] `POST /api/invoices`
  - [ ] Authenticate user
  - [ ] Validate invoice data
  - [ ] Save to Firestore (`/users/{userId}/invoices/{id}`)
  - [ ] Return saved invoice with ID
- [ ] `GET /api/invoices/:id`
  - [ ] Authenticate user
  - [ ] Verify ownership
  - [ ] Return invoice data
- [ ] `PUT /api/invoices/:id`
  - [ ] Authenticate user
  - [ ] Verify ownership
  - [ ] Update invoice in Firestore
  - [ ] Return updated invoice
- [ ] `DELETE /api/invoices/:id`
  - [ ] Authenticate user
  - [ ] Verify ownership
  - [ ] Delete from Firestore
  - [ ] Return success

#### Client CRUD
- [ ] `GET /api/clients`
  - [ ] Authenticate user
  - [ ] Query user's clients from Firestore
  - [ ] Return client list
- [ ] `POST /api/clients`
  - [ ] Authenticate user
  - [ ] Validate client data
  - [ ] Save to Firestore (`/users/{userId}/clients/{id}`)
  - [ ] Return saved client with ID
- [ ] `DELETE /api/clients/:id`
  - [ ] Authenticate user
  - [ ] Verify ownership
  - [ ] Delete from Firestore
  - [ ] Return success

#### Usage Tracking
- [ ] `GET /api/usage`
  - [ ] Authenticate user
  - [ ] Get current month usage
  - [ ] Return extraction count, limit, remaining

**Deliverable:** Complete RESTful API with all CRUD operations

---

### Phase 5: Frontend - React SPA Migration ⏳

**Goal:** Build React frontend with authentication and API integration

#### Setup
- [ ] Create React app with Vite in `service/frontend/`
  - [ ] Install dependencies (React, React Router, Tailwind)
  - [ ] Configure Tailwind CSS
  - [ ] Set up Firebase SDK (auth, firestore)
- [ ] Create API client (`src/services/api.ts`)
  - [ ] Fetch wrapper with auth token injection
  - [ ] Error handling
  - [ ] Type-safe endpoints
- [ ] Create authentication context (`src/contexts/AuthContext.tsx`)
  - [ ] Firebase Auth integration
  - [ ] Login/signup/logout functions
  - [ ] Current user state

#### Pages
- [ ] **Landing Page** (`src/pages/Landing.tsx`)
  - [ ] Product description
  - [ ] Sign up / Log in buttons
  - [ ] No authentication required
- [ ] **Login Page** (`src/pages/Login.tsx`)
  - [ ] Email/password form
  - [ ] Firebase Auth sign in
  - [ ] Redirect to dashboard on success
- [ ] **Sign Up Page** (`src/pages/SignUp.tsx`)
  - [ ] Email/password form
  - [ ] Firebase Auth create user
  - [ ] Initialize user profile in Firestore
  - [ ] Redirect to dashboard
- [ ] **Dashboard Page** (`src/pages/Dashboard.tsx`)
  - [ ] Protected route (requires auth)
  - [ ] Upload invoice button
  - [ ] List of recent invoices
  - [ ] Usage meter (X/10 extractions used)
  - [ ] Saved clients list
- [ ] **Invoice Creator** (`src/pages/InvoiceCreator.tsx`)
  - [ ] Reuse V1 components where possible
  - [ ] File upload (call `/api/extract-invoice`)
  - [ ] Line items table (editable)
  - [ ] Invoice details form
  - [ ] Client selector (saved clients)
  - [ ] Save draft button (call `/api/invoices`)
  - [ ] PDF preview and download (html2pdf.js)

#### Components (Reuse from V1)
- [ ] `LineItemsTable.tsx` - Editable table from V1
- [ ] `InvoicePreview.tsx` - PDF preview from V1
- [ ] `ClientSelector.tsx` - Dropdown with saved clients
- [ ] `UsageMeter.tsx` - Progress bar showing usage
- [ ] `ProtectedRoute.tsx` - Auth wrapper for routes

**Deliverable:** Fully functional React SPA with authentication and API integration

---

### Phase 6: Security & Configuration ⏳

**Goal:** Lock down security and configure production settings

- [ ] Write Firestore security rules (`firestore.rules`)
  - [ ] Users can only read/write their own data
  - [ ] Enforce authentication on all paths
- [ ] Write Cloud Storage security rules (`storage.rules`)
  - [ ] Users can only access their own uploads
  - [ ] Set file size limits (10 MB)
  - [ ] Restrict file types (images, PDFs only)
- [ ] Configure CORS for Cloud Functions
  - [ ] Allow requests from Firebase Hosting domain
  - [ ] Block other origins
- [ ] Set up environment variables
  - [ ] Frontend: Firebase config (public)
  - [ ] Backend: Secrets in Secret Manager (private)
- [ ] Configure Firebase quotas and limits
  - [ ] Set Cloud Functions timeout (60s)
  - [ ] Set max file upload size (10 MB)
  - [ ] Review free tier limits

**Deliverable:** Production-ready security configuration

---

### Phase 7: Deployment & Testing ⏳

**Goal:** Deploy MVP and verify functionality

#### Deploy
- [ ] Deploy Cloud Functions
  - [ ] `firebase deploy --only functions`
  - [ ] Verify all endpoints are live
- [ ] Deploy React frontend
  - [ ] Build production bundle (`npm run build`)
  - [ ] Deploy to Firebase Hosting (`firebase deploy --only hosting`)
  - [ ] Verify site is accessible
- [ ] Deploy Firestore rules
  - [ ] `firebase deploy --only firestore:rules`
- [ ] Deploy Storage rules
  - [ ] `firebase deploy --only storage`

#### Testing
- [ ] Test authentication flow
  - [ ] Sign up new user
  - [ ] Log in existing user
  - [ ] Log out
- [ ] Test invoice extraction
  - [ ] Upload bank statement image
  - [ ] Verify line items extracted correctly
  - [ ] Edit line items
  - [ ] Save invoice
- [ ] Test saved clients
  - [ ] Add new client
  - [ ] Select client from dropdown
  - [ ] Delete client
- [ ] Test usage limits
  - [ ] Extract 10 invoices (free tier limit)
  - [ ] Verify 11th attempt is blocked
  - [ ] Check usage meter shows 10/10
- [ ] Test invoice history
  - [ ] View saved invoices
  - [ ] Edit saved invoice
  - [ ] Delete invoice
- [ ] Test PDF generation
  - [ ] Generate PDF
  - [ ] Verify formatting matches preview

#### Documentation
- [ ] Update README.md with hosted service instructions
- [ ] Add API documentation (endpoints, request/response formats)
- [ ] Create user guide (how to use the service)
- [ ] Document deployment process
- [ ] Update STATUS.md with launch date

**Deliverable:** Live MVP service on Firebase

---

### Phase 8: Post-MVP Monitoring ⏳

**Goal:** Monitor usage and collect feedback

- [ ] Set up Firebase Analytics
  - [ ] Track page views
  - [ ] Track invoice extractions
  - [ ] Track user signups
- [ ] Monitor Cloud Functions logs
  - [ ] Check for errors
  - [ ] Monitor response times
- [ ] Track costs
  - [ ] Cloud Functions invocations
  - [ ] Firestore reads/writes
  - [ ] Cloud Storage usage
  - [ ] Claude API costs
- [ ] Collect user feedback
  - [ ] Add feedback form
  - [ ] Monitor support requests
- [ ] Identify improvements for next iteration

**Deliverable:** Monitoring dashboard and feedback collection system

---

**Milestone 2 Estimated Timeline:** 2-4 weeks for experienced developer

**Success Criteria:**
- ✅ Users can sign up and log in
- ✅ Users can upload invoices and extract line items
- ✅ Users can save and retrieve invoices
- ✅ Users can manage client profiles
- ✅ Free tier limit (10 extractions/month) enforced
- ✅ All data properly isolated per user
- ✅ No exposed API keys or security issues

---

## Milestone 3: Templates & Customization (Not started)

**Goal:** Support multiple invoice templates and company profiles

### Features
- [ ] Multiple invoice templates (professional, minimal, detailed)
- [ ] Custom company profile management
- [ ] Logo upload and placement
- [ ] Color scheme customization
- [ ] Custom payment terms/notes

### Prerequisites
- [ ] Milestone 1 complete ✅
- [ ] User feedback on template needs

---

## Milestone 4: Cloud Integration (Future)

**Goal:** Optional cloud storage for invoices and data

**BLOCKED UNTIL:** User demand identified

### Features
- [ ] Save invoices to Google Drive
- [ ] Save invoices to Dropbox
- [ ] Invoice history/archive
- [ ] Cloud sync for client profiles

### Prerequisites
- [ ] Milestone 2 complete
- [ ] OAuth integration for cloud providers
- [ ] Privacy/security review

---

## Milestone 5: Automation & Recurring (Future)

**Goal:** Automate recurring invoices

**BLOCKED UNTIL:** Cloud integration (Milestone 4)

### Features
- [ ] Recurring invoice templates
- [ ] Scheduled invoice generation
- [ ] Automatic statement import (bank API integration)
- [ ] Payment tracking

### Prerequisites
- [ ] Milestone 4 complete
- [ ] Backend service for scheduling
- [ ] Bank API access (Plaid, etc.)

---

## Decision Gates

After each milestone, ask:
- [ ] **Is this solving the problem?** - Does it save time vs. manual invoicing?
- [ ] **Is it worth continuing?** - ROI of development time vs. usage
- [ ] **What's missing?** - User feedback drives next priorities
