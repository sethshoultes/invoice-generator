# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## AI-Agent Memory System

**Every session, start by reading these files in order:**
1. `/STATUS.md` - Current state, task, blockers (WHERE are we?)
2. `/ROADMAP.md` - Milestone checklists (WHAT's next?)
3. `/DECISIONS.md` - Decision history (WHY are things this way?)
4. `/JOURNAL.md` - Learnings and patterns (HOW did we solve problems?)

**During work:**
- Update STATUS.md with progress
- Mark ROADMAP.md items complete when done
- Document significant decisions in DECISIONS.md
- Capture learnings in JOURNAL.md

**At session end:**
- Update STATUS.md with current state and next steps
- Commit memory files with code changes

---

## Project Overview

**Invoice Digitization Service** - A platform that allows users to upload handwritten or digital invoices/statements and automatically generate structured digital invoices using Claude's vision API.

**Two Deployment Models:**
1. **Browser-Only (v1)** - Single HTML file, runs entirely in browser, user provides API key
2. **Hosted Service (v2 - IN PROGRESS)** - Firebase-hosted SaaS with backend, authentication, and managed API access

**Current Phase:** Migrating from browser-only to hosted service architecture (see Milestone 2 in ROADMAP.md)

## Architecture

### V1: Browser-Only Architecture (Current Production)

**Files:**
- **invoice-generator.html** - Self-contained HTML file with embedded React, runs entirely in browser
- **invoice-generator.jsx** - React component source (for bundled projects)
- **invoice-extractor.jsx** - Simpler extraction-only component (CSV output)
- **invoice-automation-plan.md** - Original technical design document

**Flow:**
1. User uploads bank statement image/PDF
2. Browser sends image to Claude API with tool use for structured extraction
3. Claude returns line items as JSON via `record_invoice_items` tool
4. User reviews/edits extracted items in a table UI
5. User fills invoice metadata (client info, invoice number, dates)
6. User previews and downloads PDF via html2pdf.js

**Key Details:**
- No backend required - API calls made directly from browser
- User provides their own Anthropic API key
- Claude model: `claude-sonnet-4-20250514` with vision
- PDF generation: html2pdf.js (client-side)
- Storage: localStorage only

### V2: Hosted Service Architecture (IN PROGRESS)

**Stack:**
```
[Frontend]         Firebase Hosting (React SPA)
      ↓
[Backend]          Cloud Functions (Node.js/TypeScript)
      ↓
[Services]         Firebase Auth + Firestore + Cloud Storage
      ↓
[External API]     Claude API (vision + tool use)
```

**Infrastructure:**
- **Frontend**: React SPA deployed to Firebase Hosting
- **Backend**: Cloud Functions for API proxy and business logic
- **Auth**: Firebase Authentication (email/password, Google OAuth)
- **Database**: Firestore (user profiles, invoices, clients, usage tracking)
- **Storage**: Cloud Storage (uploaded images/PDFs)
- **Secrets**: Secret Manager (Anthropic API key)
- **CDN**: Firebase Hosting CDN for global distribution

**API Endpoints:**
```
POST /api/extract-invoice     - Upload image, extract line items
GET  /api/invoices            - List user's invoices
POST /api/invoices            - Save invoice data
GET  /api/invoices/:id        - Get specific invoice
PUT  /api/invoices/:id        - Update invoice
DELETE /api/invoices/:id      - Delete invoice
GET  /api/clients             - List saved clients
POST /api/clients             - Save client profile
DELETE /api/clients/:id       - Delete client
GET  /api/usage               - Get user's usage stats
```

**Firestore Schema:**
```
/users/{userId}
  - email: string
  - createdAt: timestamp
  - usageLimit: number (10 for free tier)
  - plan: string ("free", "paid")

/users/{userId}/invoices/{invoiceId}
  - lineItems: array
  - invoiceData: object
  - createdAt: timestamp
  - updatedAt: timestamp
  - status: string ("draft", "finalized")

/users/{userId}/clients/{clientId}
  - name: string
  - company: string
  - address1: string
  - address2: string
  - createdAt: timestamp

/users/{userId}/usage/{month}
  - month: string (YYYY-MM)
  - extractionCount: number
  - apiCost: number
  - lastExtraction: timestamp
```

**Cloud Storage Structure:**
```
/users/{userId}/uploads/{uploadId}.{ext}
  - Original uploaded images/PDFs
  - Retention: 30 days
```

**Flow:**
1. User authenticates via Firebase Auth
2. User uploads statement → Cloud Storage
3. Frontend calls Cloud Function with upload reference
4. Cloud Function fetches file, calls Claude API
5. Claude extracts line items (tool use)
6. Function returns data + saves to Firestore
7. User edits items in UI
8. User saves invoice to Firestore
9. User downloads PDF (client-side html2pdf.js)

## Features

**V1 (Browser-Only):**
- Multi-PDF Upload: Process multiple bank statements, items are appended
- API Key Persistence: Stored obfuscated in localStorage, auto-loads on return
- Saved Client Profiles: Save/select/delete clients from dropdown
- Date Pickers: Native date inputs for all date fields
- Auto Invoice Numbers: Generated as MMDDYYYY-1 format

**V2 (Hosted Service - MVP):**
- User authentication (email/password)
- Managed Claude API access (no API key required from users)
- Invoice history and retrieval
- Saved client profiles (cloud-synced)
- Usage tracking (10 free extractions/month)
- Secure file upload and storage

---

## Development Principles

All development follows these core principles:

### KISS (Keep It Simple, Stupid)
- Use managed services (Firebase) over custom infrastructure
- Single API endpoint patterns (RESTful)
- Minimize dependencies and moving parts
- Simple, obvious solutions over clever ones

### YAGNI (You Aren't Gonna Need It)
- Build only what's needed for MVP
- No billing system until demand is proven
- No complex dashboards or analytics initially
- No multi-tenant features until needed
- Defer optimization until there's a problem

### DRY (Don't Repeat Yourself)
- Share TypeScript types between frontend and backend
- Reuse UI components from V1 where possible
- Extract common utilities (date formatting, validation)
- Single source of truth for data schemas

### PSR (Coding Standards)
- TypeScript everywhere (strict mode)
- ESLint + Prettier for consistency
- Conventional commits (feat:, fix:, docs:)
- Clear naming: descriptive, not abbreviated
- Error handling: always return structured errors

### LEAN (Build-Measure-Learn)
- Deploy MVP fast, iterate based on usage
- Start with free tier only (no billing complexity)
- Measure: usage tracking from day 1
- Learn: collect feedback before adding features
- Pivot if needed based on real data

---

## Running Locally

**V1 (Browser-Only):**
Open `invoice-generator.html` directly in a browser. No build step required.

**V2 (Hosted Service):**
```bash
# Prerequisites
node >= 18
npm >= 9
Firebase CLI (npm install -g firebase-tools)

# Setup
cd service
npm install

# Configure Firebase
firebase login
firebase use --add  # Select your project

# Set secrets
firebase functions:secrets:set ANTHROPIC_API_KEY

# Run locally
npm run dev  # Starts frontend (Vite) + Firebase emulators

# Deploy
npm run deploy  # Deploys functions + hosting
```

## Claude API Integration

The extraction uses Claude's tool use feature to enforce structured output:

```javascript
tools: [{
  name: 'record_invoice_items',
  input_schema: {
    type: 'object',
    properties: {
      line_items: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            date: { type: 'string' },
            description: { type: 'string' },
            amount: { type: 'number' }
          },
          required: ['date', 'description', 'amount']
        }
      }
    },
    required: ['line_items']
  }
}],
tool_choice: { type: 'tool', name: 'record_invoice_items' }
```

## localStorage Keys

- `anthropic_api_key` - Obfuscated API key (base64 + reversed)
- `saved_clients` - JSON array of saved client profiles

## Default Company Info

Invoice templates are pre-filled with SWS Management Services contact information. Modify `invoiceData` state defaults in the component to change.

## Decision Authority Levels

**✅ Tier 1: Implement Autonomously**
- Bug fixes in existing code
- UI/UX improvements within existing patterns
- Code refactoring (following existing patterns)
- Documentation updates
- Adding new line item fields
- Writing tests for existing functionality
- Performance optimizations (non-breaking)
- Adding TypeScript types
- Updating dependencies (patch versions)

**⚠️ Tier 2: Propose First**
- New features (discuss approach first)
- New API endpoints
- Database schema changes
- New dependencies (libraries, packages)
- Storage changes (new Firestore collections)
- Major UI redesigns
- Authentication flow changes
- Usage limit modifications

**🛑 Tier 3: Always Ask**
- Architecture changes (infrastructure, services)
- Security-related changes (auth, secrets, CORS)
- Breaking changes to API contracts
- Removing existing features
- Billing/payment integration
- Data migration strategies
- Third-party service integrations
- Cost-impacting changes (Firebase quotas)

## Code Standards

### V1 (Browser-Only App)
**Single-file browser app:**
- All React code is in `invoice-generator.html`
- Use React hooks (useState, useEffect, useRef)
- Tailwind CSS for styling
- Inline styles for PDF-critical elements
- No build step required

**Patterns:**
- State management via useState hooks
- localStorage for persistence (obfuscate sensitive data)
- Tool use for Claude API structured output
- html2pdf.js for PDF generation

### V2 (Hosted Service)

**Directory Structure:**
```
service/
├── functions/              # Cloud Functions (backend)
│   ├── src/
│   │   ├── index.ts       # Main entry point
│   │   ├── api/           # API endpoint handlers
│   │   ├── services/      # Business logic (Claude, Firestore)
│   │   ├── middleware/    # Auth, validation, error handling
│   │   ├── types/         # Shared TypeScript types
│   │   └── utils/         # Helpers, constants
│   ├── package.json
│   └── tsconfig.json
│
├── frontend/              # React SPA
│   ├── src/
│   │   ├── components/    # Reusable UI components
│   │   ├── pages/         # Page components (Home, Dashboard, etc.)
│   │   ├── services/      # API client, Firebase SDK
│   │   ├── hooks/         # Custom React hooks
│   │   ├── types/         # Shared types (symlink to functions/src/types)
│   │   ├── utils/         # Client-side helpers
│   │   └── App.tsx        # Root component
│   ├── package.json
│   ├── vite.config.ts
│   └── tsconfig.json
│
├── firebase.json          # Firebase configuration
├── firestore.rules        # Security rules
├── storage.rules          # Storage security rules
└── .firebaserc            # Project aliases
```

**TypeScript Standards:**
```typescript
// Use strict mode
"strict": true,
"noImplicitAny": true,
"strictNullChecks": true

// Naming conventions
interface UserProfile { }      // PascalCase for types/interfaces
type InvoiceStatus = "draft"   // PascalCase for type aliases
const MAX_UPLOADS = 10         // UPPER_SNAKE_CASE for constants
function extractInvoice() { }  // camelCase for functions
const userEmail = ""           // camelCase for variables

// Export patterns
export interface Invoice { }   // Named exports for types
export const createInvoice     // Named exports for functions
export default App             // Default export for components
```

**Error Handling:**
```typescript
// Backend: Always return structured errors
export interface ApiError {
  code: string;           // "AUTH_REQUIRED", "QUOTA_EXCEEDED"
  message: string;        // User-friendly message
  details?: unknown;      // Optional debug info
}

// Frontend: Use try/catch with user feedback
try {
  await api.extractInvoice(file);
} catch (error) {
  showToast(getErrorMessage(error));
}
```

**API Response Format:**
```typescript
// Success
{
  data: T,
  error: null
}

// Error
{
  data: null,
  error: {
    code: string,
    message: string,
    details?: unknown
  }
}
```

**Testing Strategy:**
```
V2 MVP: Manual testing only (YAGNI principle)
Post-MVP: Add tests for critical paths
- Unit tests: Business logic (services/)
- Integration tests: API endpoints
- E2E tests: Key user flows (Playwright)
```

**Commit Messages:**
```
feat: add invoice extraction endpoint
fix: resolve Firestore query pagination issue
docs: update API endpoint documentation
refactor: extract Claude service to separate module
test: add unit tests for usage tracking
chore: update Firebase dependencies
```

**Firebase Security Rules:**
```javascript
// Principle: Users can only access their own data
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

## Master Checklist Reference

For the complete implementation checklist, see **ROADMAP.md → Milestone 2: Hosted Service MVP**

The checklist is organized into phases:
1. **Phase 1: Project Setup** (Firebase, TypeScript, tooling)
2. **Phase 2: Backend Infrastructure** (Cloud Functions, Claude service)
3. **Phase 3: Authentication** (Firebase Auth integration)
4. **Phase 4: Core API** (Invoice extraction, CRUD operations)
5. **Phase 5: Frontend Migration** (React SPA, API integration)
6. **Phase 6: Deployment** (Firebase hosting, production config)
7. **Phase 7: MVP Launch** (Testing, documentation, go-live)

Each phase has detailed sub-tasks with checkbox tracking.

---

## Key Files to Reference

- `/STATUS.md` - Current state (read every session)
- `/ROADMAP.md` - Master checklist and milestones
- `/DECISIONS.md` - Architecture decisions and rationale
- `/JOURNAL.md` - Learnings and patterns
- `/README.md` - User documentation
