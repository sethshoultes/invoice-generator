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

## Milestone 2: Enhanced Export Options (Not started)

**Goal:** Multiple export formats and delivery options

### Features
- [ ] Export to CSV for spreadsheet import
- [ ] Export to Excel (.xlsx) format
- [ ] Email invoice directly to client
- [ ] Copy invoice link (if hosted)

### Prerequisites
- [ ] Milestone 1 complete ✅
- [ ] Evaluate email service options (SendGrid, Mailgun, etc.)

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
