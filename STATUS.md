# Project Status

**Last Updated:** 2026-02-09
**Current Phase:** Vercel + Supabase Cloud Migration
**Current Task:** Deploy to Vercel with Supabase Cloud backend

## What I'm Working On

Migrating from local Docker Compose (10 containers) to Vercel static hosting + Supabase Cloud. The original local setup is preserved — no changes to `invoice-generator.html`.

## Completed Features

- ✅ **Vercel Deployment Config** (2026-02-09)
  - Created `vercel.json` with build command, rewrites, and security headers
  - Created `scripts/build.sh` that copies HTML to `dist/` and injects Supabase Cloud credentials from env vars
  - Created `supabase/init-cloud.sql` for Supabase Cloud (no sample data or GRANT lines)
  - Updated `.gitignore` for Vercel artifacts (`dist/`, `.vercel/`, `config.js`)
  - Original `invoice-generator.html` is **untouched** — local Docker setup still works

- ✅ **Supabase Database Integration** (2026-01-06)
  - Added Supabase JS client library via CDN
  - Initialized Supabase client with connection to http://127.0.0.1:8002
  - Replaced all localStorage operations with Supabase REST API calls
  - Client management (save, load, delete) now persists to `clients` table
  - Invoice management (save, load, update, delete) now persists to `invoices` and `line_items` tables
  - Payment tracking updates saved to database
  - Export functionality pulls fresh data from Supabase
  - Anthropic API key remains in localStorage (not in database for security)

- ✅ **Phase 1: Data Infrastructure**
  - localStorage schema with STORAGE_KEYS constants (now migrated to Supabase)
  - DATA_VERSION for future migrations
  - Export all data to JSON backup file (now from Supabase)
  - Import data from JSON with merge logic

- ✅ **Phase 2: Invoice History**
  - Auto-save invoice when downloading PDF (now to Supabase)
  - History panel with slide-over UI
  - Search by invoice #, client, project
  - Filter by payment status (All/Unpaid/Paid)
  - View invoice (load into preview)
  - Duplicate invoice (copy with new number)
  - Delete invoice from history (now from Supabase)

- ✅ **Phase 3: Payment Tracking**
  - Payment status (unpaid/paid) (now in Supabase)
  - Toggle paid/unpaid from history panel
  - Date paid auto-set when marking paid

## Remaining Features

- ⏳ Recurring items library
- ⏳ Line item notes (with PDF toggle)
- ⏳ "Invoice like last month" for repeat clients

## Recent Progress

- ✅ Created Vercel deployment config (2026-02-09)
- ✅ Created build script for production HTML generation (2026-02-09)
- ✅ Created cloud-ready SQL init script (2026-02-09)
- ✅ Updated .gitignore for Vercel artifacts (2026-02-09)

## Current Blockers

**Manual steps required to complete deployment:**
1. Create Supabase Cloud project at https://supabase.com/dashboard
2. Run `supabase/init-cloud.sql` in Supabase SQL Editor
3. Run `vercel` CLI to connect repo and deploy
4. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` env vars in Vercel
5. Run `vercel --prod` to deploy to production

## Next Steps

1. Complete manual Supabase Cloud + Vercel deployment steps (see Blockers above)
2. Verify all features work on deployed Vercel URL
3. Optionally export local data and import into cloud
4. Add line item notes with PDF toggle
5. Implement recurring items library
6. Implement "invoice like last month" feature

## Context Links

- [Feature Spec](docs/planning/feature-invoice-management.md)
- [Future Email Delivery](docs/planning/future-email-delivery.md)
- [ROADMAP.md](ROADMAP.md)
- [DECISIONS.md](DECISIONS.md)

## Key Decisions Made

- **Vercel + Supabase Cloud**: Migrated from Docker Compose to Vercel static hosting + Supabase Cloud for anywhere-access
- **Separate local/cloud configs**: Build script generates production HTML; original file untouched for local dev
- **Database Migration**: Migrated from localStorage to Supabase PostgreSQL for persistent, reliable data storage
- **API Key Security**: Kept Anthropic API key in localStorage (not in database) for security
- **Client Auto-Creation**: Invoices automatically create clients if they don't exist
- **Foreign Key Constraints**: Cannot delete clients with existing invoices (database enforces referential integrity)
- **Date Format Conversion**: Frontend uses MM/DD/YYYY, database stores YYYY-MM-DD (ISO format)
- Storage: Supabase database with export to JSON backup
- Notes: Optional toggle per item to include/exclude from PDF
- Payment tracking: Status + date paid + payment method
- Copy previous: Show checkboxes to select which items to copy
