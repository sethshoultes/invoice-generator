# Invoice Generator

A browser-based invoice generator that extracts line items from bank/payment statements using Claude's vision API, then generates professional PDF invoices.

## Features

- **AI-Powered Extraction**: Upload bank statements (PNG, JPEG, PDF) and Claude automatically extracts all charges
- **Multi-Statement Support**: Process multiple statements in one session - items are appended, not replaced
- **Saved Client Profiles**: Save frequently-used clients and select from dropdown
- **Date Pickers**: Native date inputs for all date fields
- **Auto Invoice Numbers**: Generated as MMDDYYYY-1 format
- **PDF Export**: Download professional invoices via html2pdf.js
- **No Backend Required**: Runs entirely in the browser

## Quick Start

1. Open `invoice-generator.html` in your browser
2. Enter your [Anthropic API key](https://console.anthropic.com/) (saved locally for future visits)
3. Upload a bank statement screenshot or PDF
4. Review and edit extracted line items
5. Fill in client details (or select a saved client)
6. Preview and download PDF

## How It Works

```
Upload Statement → Claude Extracts Items → Review/Edit → Add Details → Download PDF
```

1. **Upload**: Drop or select a bank statement image/PDF
2. **Extract**: Claude's vision API reads the statement and returns structured data
3. **Review**: Edit dates, descriptions, quantities, and prices
4. **Details**: Fill in client info, invoice number, due date
5. **Export**: Preview and download as PDF

## Screenshots

| Upload | Line Items | Details | Preview |
|--------|------------|---------|---------|
| Drag & drop statements | Edit extracted items | Client info & dates | PDF preview |

## Data Storage

All data stays in your browser using localStorage:

| Key | Description |
|-----|-------------|
| `anthropic_api_key` | Your API key (obfuscated, not plaintext) |
| `saved_clients` | Array of saved client profiles |

No data is sent to any server except the Anthropic API for extraction.

## Technical Details

- **Framework**: React 18 (loaded via CDN)
- **Styling**: Tailwind CSS
- **PDF Generation**: html2pdf.js
- **API**: Claude claude-sonnet-4-20250514 with vision + tool use for structured output

### API Integration

Uses Claude's tool use feature to enforce structured extraction:

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
          }
        }
      }
    }
  }
}]
```

## Customization

### Change Default Company Info

Edit the `invoiceData` state in `invoice-generator.html`:

```javascript
const [invoiceData, setInvoiceData] = useState({
  companyName: 'Your Company Name',
  companyAddress1: '123 Main St',
  companyAddress2: 'City, State ZIP',
  companyPhone: '(555) 123-4567',
  payableTo: 'Your Name',
  // ...
});
```

## Deployment Options

### Option A: Local (Docker + Supabase)

Open `invoice-generator.html` directly in a browser. Uses the local Supabase instance at `http://127.0.0.1:8002`. Requires Docker Compose running the full Supabase stack.

### Option B: Vercel + Supabase Cloud

Deploy as a static site to Vercel with Supabase Cloud for the database.

**1. Create Supabase Cloud project:**
- Go to https://supabase.com/dashboard and create a new project
- Note the project URL (`https://xxxx.supabase.co`) and anon key
- Open the SQL Editor and run the contents of `supabase/init-cloud.sql`

**2. Deploy to Vercel:**
```bash
# Install Vercel CLI if needed
npm i -g vercel

# Connect repo and deploy
vercel --yes

# Set environment variables
vercel env add SUPABASE_URL production
# Enter your Supabase project URL (e.g., https://xxxx.supabase.co)

vercel env add SUPABASE_ANON_KEY production
# Enter your Supabase anon key

# Deploy to production
vercel --prod
```

**3. Verify:**
- Open the Vercel URL
- Enter your Anthropic API key
- Create a client, save an invoice, upload a statement, download PDF
- Reload — verify data persists from Supabase Cloud

**Migrating existing data:**
Use the app's "Export All Data" button on local, then "Import Data" on the Vercel version.

## Requirements

- Modern browser (Chrome, Firefox, Safari, Edge)
- Anthropic API key with access to Claude claude-sonnet-4-20250514

## Cost

Claude API pricing per extraction: ~$0.02-0.05 depending on statement size.

## License

MIT
