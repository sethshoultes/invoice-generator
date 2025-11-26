# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A browser-based invoice generator that extracts line items from bank/payment statements using Claude's vision API, then generates PDF invoices. The application is a single-page React app that runs entirely in the browser.

## Architecture

### Files

- **invoice-generator.html** - Main application: self-contained HTML file with embedded React/JSX, Tailwind CSS, and html2pdf.js for PDF generation. This is the production-ready version.
- **invoice-generator.jsx** - React component source (for use in bundled React projects). Requires lucide-react icons.
- **invoice-extractor.jsx** - Simpler extraction-only component that outputs CSV for Google Sheets.
- **invoice-automation-plan.md** - Technical design document with API schemas, prompts, and architecture diagrams.

### Flow

1. User uploads bank statement image/PDF
2. Browser sends image to Claude API with tool use for structured extraction
3. Claude returns line items as JSON via `record_invoice_items` tool
4. User reviews/edits extracted items in a table UI
5. User fills invoice metadata (client info, invoice number, dates)
6. User previews and downloads PDF via html2pdf.js

### Key Technical Details

- **No backend required** - API calls made directly from browser (requires `anthropic-dangerous-direct-browser-access` header)
- **API key handling** - User provides their Anthropic API key at runtime; not stored
- **Claude model** - Uses `claude-sonnet-4-20250514` with vision capabilities
- **PDF generation** - html2pdf.js renders the DOM preview to PDF client-side
- **Styling** - Tailwind CSS via CDN, inline styles for PDF-rendered elements

## Features

- **Multi-PDF Upload**: Process multiple bank statements, items are appended
- **API Key Persistence**: Stored obfuscated in localStorage, auto-loads on return
- **Saved Client Profiles**: Save/select/delete clients from dropdown
- **Date Pickers**: Native date inputs for all date fields
- **Auto Invoice Numbers**: Generated as MMDDYYYY-1 format

## Running Locally

Open `invoice-generator.html` directly in a browser. No build step required.

For the JSX components, integrate into a React project with:
- React 18+
- lucide-react for icons
- html2pdf.js loaded via CDN or npm

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
