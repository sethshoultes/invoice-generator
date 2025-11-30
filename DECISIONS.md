# Decision Log

## Format

Each decision includes:
- **Date:** When decided
- **Decision:** What was chosen
- **Context:** Why this decision was needed
- **Alternatives:** What else was considered
- **Rationale:** Why this option was chosen
- **Tradeoffs:** What we gave up
- **Status:** Active, Deprecated, Superseded

---

## Decision 001: Browser-Only Architecture (No Backend)

**Date:** 2025-11-26
**Status:** ✅ Active

**Decision:**
Build the invoice generator as a single HTML file with embedded React that runs entirely in the browser, with no backend server.

**Context:**
Need a tool to generate invoices from bank statements. Must decide on architecture:
- Traditional web app (frontend + backend)
- Browser-only app (all client-side)
- Desktop app (Electron, native)

**Alternatives Considered:**

1. **Traditional web app** (React frontend + Node/Python backend)
   - Pros: Secure API key storage, more features possible
   - Cons: Hosting required, complexity, ongoing costs

2. **Browser-only app** (chosen)
   - Pros: Zero hosting, instant deployment (just open HTML), portable
   - Cons: API key in browser (security tradeoff), limited by browser APIs

3. **Desktop app** (Electron)
   - Pros: Native features, secure storage
   - Cons: Complex build, distribution challenges, updates

**Rationale:**
- This is a personal/small business tool, not SaaS
- Zero hosting cost is critical for a simple utility
- Claude API calls from browser work with special header
- User provides their own API key (cost is theirs)
- Simplicity > features for this use case

**Tradeoffs:**
- ❌ API key visible in browser DevTools (mitigated: user's own key)
- ❌ No server-side processing (can't do heavy operations)
- ❌ Can't send emails directly (would need backend)
- ✅ Zero hosting cost
- ✅ Instant deployment (share HTML file)
- ✅ Works offline (after initial load)
- ✅ No user data stored on any server

**Implementation Details:**
- Single `invoice-generator.html` file
- React/Babel loaded via CDN
- Tailwind CSS via CDN
- html2pdf.js for PDF generation
- localStorage for persistence

**Related:**
- Decision 002 (API key storage)
- Decision 003 (Claude API integration)

---

## Decision 002: localStorage for Persistence (Not .env)

**Date:** 2025-11-26
**Status:** ✅ Active

**Decision:**
Use browser localStorage for storing API key and saved data, with obfuscation for the API key.

**Context:**
User asked for API key to be stored in .env file. However, this is a browser-only app with no backend - .env files are for server-side apps.

**Alternatives Considered:**

1. **No persistence** (enter API key every session)
   - Pros: Most secure, no storage
   - Cons: Terrible UX, friction every use

2. **localStorage with obfuscation** (chosen)
   - Pros: Persists between sessions, good UX, still client-side only
   - Cons: Not truly encrypted, can be extracted if browser is compromised

3. **Add backend just for .env** (overkill)
   - Pros: "Proper" API key storage
   - Cons: Defeats browser-only architecture, adds hosting requirement

**Rationale:**
- Browser-only architecture requires browser-based storage
- localStorage is the standard solution for client-side persistence
- Obfuscation (base64 + reverse) prevents casual inspection
- User's own API key, so they accept the risk
- This isn't a SaaS - no need for enterprise security

**Tradeoffs:**
- ❌ Not encrypted (obfuscated only)
- ❌ Accessible to browser extensions
- ✅ Persists between sessions
- ✅ User doesn't re-enter key every time
- ✅ Stays within browser-only architecture

**Implementation Details:**
```javascript
// Obfuscation (not encryption, but not plaintext)
const obfuscate = (str) => btoa(str.split('').reverse().join(''));
const deobfuscate = (str) => atob(str).split('').reverse().join('');

// Storage keys
localStorage.setItem('anthropic_api_key', obfuscate(apiKey));
localStorage.setItem('saved_clients', JSON.stringify(clients));
```

**Related:**
- Decision 001 (browser-only architecture)

---

## Decision 003: Claude Tool Use for Structured Extraction

**Date:** 2025-11-26
**Status:** ✅ Active

**Decision:**
Use Claude's tool use feature (function calling) to extract structured data from bank statements, rather than parsing free-form text responses.

**Context:**
Need to extract line items (date, description, amount) from bank statement images. Must get structured JSON, not prose.

**Alternatives Considered:**

1. **Free-form text + regex parsing**
   - Pros: Simpler prompt
   - Cons: Unreliable parsing, fragile to format changes

2. **JSON in prompt** ("respond only with JSON")
   - Pros: Usually works
   - Cons: Claude sometimes adds explanation text, not guaranteed

3. **Tool use / function calling** (chosen)
   - Pros: Guaranteed JSON schema, reliable structure
   - Cons: Slightly more complex API call

**Rationale:**
- Tool use forces Claude to return exact schema
- No parsing needed - data is already structured
- More reliable than "respond with JSON" prompts
- Schema acts as documentation

**Tradeoffs:**
- ❌ More complex API setup (tool definition)
- ✅ Guaranteed structured output
- ✅ No post-processing/parsing needed
- ✅ Schema validates the response

**Implementation Details:**
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

**Related:**
- Claude API documentation
- invoice-generator.html extractFromImage function

---

## Decision 004: Multi-PDF Upload with Append (Not Replace)

**Date:** 2025-11-26
**Status:** ✅ Active

**Decision:**
When uploading multiple bank statements, append extracted items to the existing list rather than replacing them.

**Context:**
User may have charges across multiple bank statements (checking, credit card, business account). Need to consolidate into one invoice.

**Alternatives Considered:**

1. **Replace items on each upload**
   - Pros: Simple implementation
   - Cons: Can only invoice from one statement at a time

2. **Append items** (chosen)
   - Pros: Consolidate multiple statements into one invoice
   - Cons: User must manually remove duplicates if any

3. **Separate invoices per statement**
   - Pros: Clean separation
   - Cons: Doesn't match user's workflow (one invoice per client per month)

**Rationale:**
- User specifically requested multi-PDF support
- Their workflow: multiple statements → one monthly invoice
- Appending makes this workflow seamless
- User can delete unwanted items in the review step

**Tradeoffs:**
- ❌ No automatic duplicate detection
- ❌ Items from different statements are mixed (but sorted by date helps)
- ✅ Supports multiple sources
- ✅ User reviews all items before finalizing

**Implementation Details:**
```javascript
// After extraction, APPEND items instead of replace
setLineItems(prev => [...prev, ...newItems]);

// Track processed statements for UI feedback
setProcessedStatements(prev => [...prev, {
  id: Date.now(),
  filename: fileName,
  itemCount: newItems.length,
  total: statementTotal
}]);
```

**Related:**
- STATUS.md multi-PDF feature
- User workflow documentation

---

## Decision 005: html2pdf.js for PDF Generation

**Date:** 2025-11-26
**Status:** ✅ Active

**Decision:**
Use html2pdf.js library to generate PDFs by rendering the DOM preview to PDF.

**Context:**
Need to generate downloadable PDF invoices from the browser. Options for client-side PDF generation.

**Alternatives Considered:**

1. **jsPDF** (programmatic PDF building)
   - Pros: Full control over PDF layout
   - Cons: Must manually position every element, complex for styled docs

2. **html2pdf.js** (chosen)
   - Pros: Render existing HTML/CSS to PDF, WYSIWYG, much simpler
   - Cons: Limited control, depends on html2canvas

3. **Puppeteer/backend** (server-side rendering)
   - Pros: Perfect rendering, print CSS support
   - Cons: Requires backend, defeats browser-only architecture

**Rationale:**
- html2pdf.js renders exactly what user sees in preview
- No need to manually build PDF structure
- Works entirely in browser
- Supports CSS styling (mostly)

**Tradeoffs:**
- ❌ Some CSS features don't render perfectly
- ❌ Large library (html2canvas + jsPDF bundled)
- ✅ WYSIWYG - what you see is what you get
- ✅ Simple API: `html2pdf().from(element).save()`
- ✅ No backend required

**Implementation Details:**
```javascript
const downloadPDF = () => {
  const element = invoiceRef.current;
  const opt = {
    margin: 0.5,
    filename: `Invoice-${invoiceData.invoiceNumber || 'draft'}.pdf`,
    image: { type: 'jpeg', quality: 0.98 },
    html2canvas: { scale: 2 },
    jsPDF: { unit: 'in', format: 'letter', orientation: 'portrait' }
  };
  html2pdf().set(opt).from(element).save();
};
```

**Related:**
- invoice-generator.html downloadPDF function
- Preview step rendering

---

## Decision 006: Adopt AI-Agent Memory System

**Date:** 2025-11-26
**Status:** ✅ Active

**Decision:**
Implement the AI-Agent Memory System (STATUS.md, ROADMAP.md, DECISIONS.md, JOURNAL.md) for persistent context across AI-assisted development sessions.

**Context:**
AI-assisted development suffers from session amnesia. Need persistent context system.

**Alternatives Considered:**

1. **No system** (re-explain context every session)
   - Pros: No maintenance overhead
   - Cons: Time wasted re-explaining, inconsistent decisions

2. **Long conversation history** (replay old messages)
   - Pros: All context preserved
   - Cons: Grows unbounded, expensive, cluttered

3. **AI-Agent Memory System** (chosen)
   - Pros: Structured, lightweight, human-readable, AI-friendly
   - Cons: Requires discipline to update

**Rationale:**
- Reduces context re-explanation
- Provides persistent memory for AI agents
- Improves session-to-session consistency
- Lightweight (markdown files)
- Human-readable (developer can review/edit)

**Tradeoffs:**
- ⚠️ Requires discipline to update STATUS.md each session
- ✅ Better AI productivity
- ✅ Faster session startup
- ✅ Knowledge preserved for future

**Implementation Details:**
- STATUS.md: Current task, progress, blockers
- ROADMAP.md: Milestone checklists
- DECISIONS.md: This file
- JOURNAL.md: Learning documentation
- CLAUDE.md: Project instructions (already existed)

**Related:**
- See docs/AI-AGENT-MEMORY-SYSTEM.md for full documentation

---

## Decision 007: Migrate to Hosted Service Architecture

**Date:** 2025-11-30
**Status:** ✅ Active (IN PROGRESS)

**Decision:**
Migrate from browser-only architecture to a hosted service on Google Cloud (Firebase) with backend API, authentication, and managed data storage.

**Context:**
User wants to deploy this as a service for users to upload handwritten invoices and generate digital invoices without requiring them to provide their own Anthropic API keys. This requires a fundamental architecture shift from V1.

**Alternatives Considered:**

1. **Keep browser-only, users provide API keys** (current V1)
   - Pros: Zero hosting cost, simple, no backend
   - Cons: Friction for non-technical users, no history/collaboration, no monetization path

2. **Hosted service on Firebase** (chosen)
   - Pros: Managed infrastructure, quick MVP, generous free tier, scalable
   - Cons: Hosting costs, more complexity, ongoing maintenance

3. **Traditional server (AWS/GCP Compute)**
   - Pros: Full control, can optimize costs at scale
   - Cons: More setup, manage infrastructure, higher initial complexity

4. **Serverless (Vercel/Netlify + Supabase)**
   - Pros: Modern stack, good DX
   - Cons: Less integrated than Firebase, more services to manage

**Rationale:**
- Firebase provides all needed services in one ecosystem
- Generous free tier allows testing demand before costs
- Firebase Auth, Firestore, Functions, Hosting all integrated
- Quick to MVP (2-4 weeks vs 4-8 weeks for custom infrastructure)
- Aligns with LEAN principle: deploy fast, measure, learn
- Google Cloud hosting as requested by user

**Tradeoffs:**

**What We Gain:**
- ✅ Better UX for non-technical users (no API key needed)
- ✅ Invoice history and retrieval
- ✅ Multi-device access (cloud-synced)
- ✅ Usage tracking and analytics
- ✅ Monetization potential (free tier + paid plans)
- ✅ Scalability (Firebase auto-scales)
- ✅ Security (API keys in Secret Manager, not browser)

**What We Lose/Add:**
- ❌ Hosting costs (~$10-50/month initially)
- ❌ Increased complexity (frontend + backend + database)
- ❌ Ongoing maintenance (monitoring, updates, support)
- ❌ Must manage user data (privacy, backups, GDPR)
- ⚠️ Need authentication system
- ⚠️ Need usage limits and tracking

**Architecture Changes:**
- **Frontend**: React SPA (Vite) deployed to Firebase Hosting
- **Backend**: Cloud Functions (Node.js/TypeScript) for API
- **Database**: Firestore for user data, invoices, clients
- **Storage**: Cloud Storage for uploaded images/PDFs
- **Auth**: Firebase Authentication (email/password, Google OAuth)
- **Secrets**: Secret Manager for Anthropic API key

**MVP Scope (Following YAGNI):**
- Authentication (email/password only)
- Invoice extraction via Claude API
- Save/retrieve invoices and clients
- Usage limits (10 free extractions/month)
- Basic dashboard
- PDF generation (still client-side)

**NOT in MVP (defer until proven need):**
- ❌ Billing/payments (just free tier initially)
- ❌ Multiple invoice templates
- ❌ Team collaboration
- ❌ Email delivery
- ❌ Advanced analytics
- ❌ Mobile apps

**Development Principles:**
This migration follows:
- **KISS**: Use managed services, simple architecture
- **YAGNI**: Build only what's needed for MVP
- **DRY**: Reuse V1 components, share types
- **PSR**: TypeScript strict mode, ESLint, consistent naming
- **LEAN**: Deploy fast, measure usage, iterate based on data

**Cost Analysis:**
**Your Costs (Service Provider):**
- Firebase free tier: 10K monthly active users, 50K reads, 20K writes
- Cloud Functions free tier: 2M invocations/month
- Estimated costs with 100 users, 10 invoices each/month:
  - Claude API: ~$20 (1000 extractions × $0.02)
  - Firebase overages: ~$5-10
  - Total: ~$25-30/month

**Monetization Options (not in MVP):**
- Free tier: 10 extractions/month
- Paid tier: $10-20/month unlimited
- Or: $0.10-0.25 per extraction

**Success Metrics:**
- [ ] 10+ active users in first month
- [ ] >50% of users return for 2nd invoice
- [ ] <1% error rate on extractions
- [ ] <2s average extraction time
- [ ] Costs <$50/month initially

**Related:**
- Decision 001 (browser-only architecture) - superseded for V2
- ROADMAP.md Milestone 2 (implementation checklist)
- CLAUDE.md (architecture documentation)

**Notes:**
- V1 (browser-only) remains available for power users who want to use their own API keys
- V2 does not replace V1, they coexist for different user segments
- This is a MAJOR architectural change (Tier 3 decision) approved by user
