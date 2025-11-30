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
- ⏳ Ready to begin Phase 1: Project Setup

## Current Blockers

None - planning phase complete, ready to implement.

## Next Steps (Immediate)

**Phase 1: Project Setup & Infrastructure**
1. Create Firebase project in Google Cloud Console
2. Install Firebase CLI and initialize project
3. Set up directory structure (`service/functions`, `service/frontend`)
4. Configure TypeScript for backend and frontend
5. Store Anthropic API key in Secret Manager
6. Set up ESLint + Prettier
7. Deploy hello-world function to verify setup

**Phase 2-8:** See ROADMAP.md → Milestone 2 for complete checklist

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
