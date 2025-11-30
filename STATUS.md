# Project Status

**Last Updated:** 2025-11-30
**Current Phase:** Milestone 2 - Hosted Service MVP (IN PROGRESS)
**Current Task:** Planning and documentation phase complete, ready to begin implementation

## What I'm Working On

**Major Architecture Shift:** Migrating from browser-only app (V1) to hosted service (V2) on Google Cloud (Firebase).

**Goal:** Deploy invoice digitization as a SaaS platform where users can:
- Sign up and authenticate (no API key required)
- Upload handwritten/digital invoices
- Extract line items via Claude API
- Save invoice history to cloud
- Manage client profiles (cloud-synced)
- Free tier: 10 extractions/month

**Current Status:** Planning complete, ready for Phase 1 (Project Setup)

## Recent Progress

**V1 (Browser-Only) - COMPLETE ✅**
- ✅ Initial project setup (single-file HTML app with React)
- ✅ Claude API integration with vision + tool use
- ✅ Multi-PDF upload flow (append items from multiple statements)
- ✅ API key persistence with obfuscation in localStorage
- ✅ Saved client profiles (save/select/delete)
- ✅ Date pickers for all date fields
- ✅ Auto-generated invoice numbers (MMDDYYYY-1 format)
- ✅ GitHub repository setup
- ✅ README and CLAUDE.md documentation

**V2 (Hosted Service) - IN PROGRESS ⏳**
- ✅ Architecture design (Firebase stack)
- ✅ Development principles defined (KISS, YAGNI, DRY, PSR, LEAN)
- ✅ Master checklist created (8 phases, ~200 tasks)
- ✅ Decision 007 documented (architecture shift rationale)
- ✅ CLAUDE.md updated with V2 architecture and code standards
- ✅ **Phase 1: Project Setup - 90% Complete**
  - ✅ Firebase CLI installed (v14.26.0)
  - ✅ Directory structure created (`service/functions`, `service/frontend`)
  - ✅ TypeScript configured (backend + frontend)
  - ✅ ESLint + Prettier configured
  - ✅ Firebase config files created (firebase.json, firestore.rules, storage.rules)
  - ✅ Initial TypeScript types created
  - ✅ Utility files and constants defined
  - ✅ Hello-world function created
  - ✅ Basic React app scaffolded
  - ⏳ **USER ACTION REQUIRED:** Create Firebase project in Google Cloud Console
  - ⏳ Install npm dependencies
  - ⏳ Connect to Firebase (`firebase init`)
  - ⏳ Store Anthropic API key in Secret Manager
  - ⏳ Deploy hello-world function

## Current Blockers

**Phase 1 - Waiting on User:**
You need to create a Firebase project in Google Cloud Console before we can proceed.

**See:** `service/SETUP.md` for detailed step-by-step instructions.

## Next Steps (Immediate)

**Complete Phase 1 (User Action Required):**

1. **Create Firebase Project** (15 minutes)
   - Go to https://console.firebase.google.com/
   - Create new project: `invoice-digitization-service`
   - Enable: Authentication (Email/Password), Firestore, Storage, Functions
   - Upgrade to Blaze plan (required for Cloud Functions, generous free tier)

2. **Install Dependencies & Connect** (5 minutes)
   ```bash
   cd service/functions && npm install
   cd ../frontend && npm install
   cd .. && firebase login && firebase init
   ```

3. **Store API Key & Deploy** (5 minutes)
   ```bash
   firebase functions:secrets:set ANTHROPIC_API_KEY
   cd functions && npm run build && cd ..
   firebase deploy --only functions
   ```

4. **Test Deployment**
   - Visit the helloWorld function URL
   - Should see JSON response confirming deployment

**Full instructions:** See `service/SETUP.md`

**Once Phase 1 is complete, we'll move to Phase 2: Backend - Cloud Functions Setup**

## Development Principles

All V2 development follows:
- **KISS**: Managed services, simple architecture
- **YAGNI**: MVP only, defer features until proven need
- **DRY**: Share types, reuse V1 components
- **PSR**: TypeScript strict mode, consistent naming, structured errors
- **LEAN**: Deploy fast, measure usage, iterate based on data

## Architecture Overview

```
[Frontend]     Firebase Hosting (React SPA with Vite)
      ↓
[Backend]      Cloud Functions (Node.js/TypeScript)
      ↓
[Services]     Auth + Firestore + Storage + Secret Manager
      ↓
[External]     Claude API (vision + tool use)
```

**MVP Features:**
- Email/password authentication
- Invoice extraction (Claude API)
- Save/retrieve invoices and clients
- Usage tracking (10 free/month limit)
- Basic dashboard
- PDF generation (client-side, reuse from V1)

**NOT in MVP:**
- ❌ Billing/payments
- ❌ Multiple templates
- ❌ Team collaboration
- ❌ Email delivery
- ❌ Advanced analytics

## Cost Estimates

**With 100 users, 10 invoices each/month:**
- Claude API: ~$20 (1000 extractions × $0.02)
- Firebase overages: ~$5-10
- **Total: ~$25-30/month**

**Monetization (not in MVP):**
- Free tier: 10 extractions/month
- Paid tier: $10-20/month unlimited
- Or: $0.10-0.25 per extraction

## Timeline

**Estimated:** 2-4 weeks for experienced developer
- Week 1: Setup, backend, Claude integration
- Week 2: API endpoints, authentication
- Week 3: Frontend migration, UI components
- Week 4: Security, testing, deployment

## Context Links

- [ROADMAP.md](ROADMAP.md) - Complete Milestone 2 checklist (200+ tasks)
- [DECISIONS.md](DECISIONS.md) - Decision 007 (architecture shift rationale)
- [CLAUDE.md](CLAUDE.md) - V2 architecture and code standards
- [JOURNAL.md](JOURNAL.md) - Learnings and patterns
- [README.md](README.md) - User documentation (needs update post-MVP)
- [GitHub Repository](https://github.com/sethshoultes/invoice-generator)
