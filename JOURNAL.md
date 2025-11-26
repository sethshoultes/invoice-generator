# Development Journal

## 2025-11-26: Claude API Direct Browser Access

**Discovery:**
Claude's API normally blocks direct browser requests (CORS). However, Anthropic provides a special header to allow browser-to-API calls for prototyping/personal tools.

**Solution:**
Add the `anthropic-dangerous-direct-browser-access` header to API requests:

```javascript
headers: {
  'Content-Type': 'application/json',
  'x-api-key': apiKey,
  'anthropic-version': '2023-06-01',
  'anthropic-dangerous-direct-browser-access': 'true'  // <-- This header
}
```

**Learning:**
This header enables browser-only apps to call Claude directly, but comes with tradeoffs:
- API key is visible in browser DevTools
- Only appropriate for personal tools / prototypes
- Not suitable for production SaaS (use backend proxy instead)

**When to Use:**
- ✅ Personal tools (your own API key)
- ✅ Prototypes and demos
- ✅ Local development
- ❌ Production SaaS (expose user API keys)
- ❌ Shared tools (multiple users, one key)

**Related:**
- Decision 001 (browser-only architecture)
- Claude API documentation

---

## 2025-11-26: Tool Use Guarantees Structured Output

**Discovery:**
Using Claude's tool use (function calling) feature is more reliable than asking for JSON in the prompt.

**Problem:**
Initial approach was to ask Claude to "respond with JSON only", but occasionally:
- Claude would add explanatory text before/after JSON
- JSON format would vary slightly
- Parsing was fragile

**Solution:**
Use tool use with `tool_choice: { type: 'tool', name: 'record_invoice_items' }`:

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
tool_choice: { type: 'tool', name: 'record_invoice_items' }  // Force this tool
```

**Learning:**
- `tool_choice` with specific tool name guarantees that tool is called
- Response is always valid JSON matching the schema
- No need for regex parsing or error handling for malformed JSON
- Schema acts as documentation for expected output

**Pattern to Reuse:**
For any task requiring structured data extraction:
1. Define a tool with explicit input_schema
2. Use `tool_choice: { type: 'tool', name: 'your_tool' }`
3. Extract data from `response.content[].input`

**Related:**
- Decision 003 (tool use for extraction)
- Claude API tool use documentation

---

## 2025-11-26: Base64 Encoding for File Upload

**Discovery:**
To send images/PDFs to Claude's vision API from the browser, files must be base64 encoded.

**Implementation:**
```javascript
const handleFileUpload = (e) => {
  const file = e.target.files?.[0] || e.dataTransfer?.files?.[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = () => {
    // reader.result is "data:image/png;base64,XXXXXX"
    const base64 = reader.result.split(',')[1];  // Get just the base64 part
    extractFromImage(base64, file.type);
  };
  reader.readAsDataURL(file);
};
```

**API Call:**
```javascript
messages: [{
  role: 'user',
  content: [
    {
      type: file.type === 'application/pdf' ? 'document' : 'image',
      source: {
        type: 'base64',
        media_type: file.type,  // 'image/png', 'application/pdf', etc.
        data: base64Data        // Just the base64 string, no prefix
      }
    },
    {
      type: 'text',
      text: 'Extract line items from this statement...'
    }
  ]
}]
```

**Gotcha:**
- FileReader.readAsDataURL returns `data:mime;base64,XXXX`
- Claude API expects just the base64 part (after the comma)
- PDFs use `type: 'document'`, images use `type: 'image'`

**Related:**
- Claude vision API documentation
- invoice-generator.html handleFileUpload

---

## 2025-11-26: html2pdf.js Requires Inline Styles for Reliable Rendering

**Discovery:**
When using html2pdf.js to generate PDFs from HTML, Tailwind CSS classes don't always render correctly. The library uses html2canvas which captures the visual state, but some styles don't transfer.

**Problem:**
- Font sizes inconsistent in PDF
- Colors sometimes wrong
- Layout shifts between preview and PDF

**Solution:**
For elements that must render perfectly in PDF, use inline styles in addition to Tailwind classes:

```jsx
// Instead of just Tailwind classes
<h1 className="text-2xl text-blue-600 font-bold">Invoice</h1>

// Add inline styles for PDF-critical elements
<h1
  className="text-2xl text-blue-600 font-bold"
  style={{ fontSize: '28px', color: '#2563eb', fontWeight: '700' }}
>
  Invoice
</h1>
```

**Learning:**
- html2canvas snapshots the visual DOM state
- Tailwind's responsive/computed styles sometimes don't capture
- Inline styles are most reliable for PDF output
- Use inline styles for: fonts, colors, spacing in the invoice preview div

**Pattern:**
```jsx
// The invoice preview div uses ref for PDF generation
<div ref={invoiceRef}>
  {/* Use inline styles for reliable PDF rendering */}
  <div style={{ fontSize: '24px', color: '#1e40af', fontWeight: '700' }}>
    {invoiceData.companyName}
  </div>
</div>
```

**Related:**
- Decision 005 (html2pdf.js)
- invoice-generator.html renderPreview function

---

## 2025-11-26: localStorage Obfuscation Pattern

**Discovery:**
For browser-only apps storing sensitive data (like API keys), we need some protection even though true encryption is impractical.

**Solution:**
Simple obfuscation that prevents casual inspection:

```javascript
// Obfuscation helpers (not encryption, but not plaintext)
const obfuscate = (str) => btoa(str.split('').reverse().join(''));
const deobfuscate = (str) => {
  try {
    return atob(str).split('').reverse().join('');
  } catch (e) {
    return '';  // Invalid stored value
  }
};

// Usage
localStorage.setItem('anthropic_api_key', obfuscate(apiKey));
const savedKey = deobfuscate(localStorage.getItem('anthropic_api_key'));
```

**What This Does:**
1. Reverses the string: `sk-ant-xxx` → `xxx-tna-ks`
2. Base64 encodes: `xxx-tna-ks` → `eHh4LXRuYS1rcw==`

**What This Doesn't Do:**
- Not encryption (easily reversible)
- Doesn't protect against determined attackers
- Doesn't hide from browser DevTools (Application → localStorage)

**Why It's Still Useful:**
- Prevents accidental exposure in console/screenshots
- Not immediately recognizable as an API key
- Stops casual shoulder-surfing
- Better than plaintext

**Learning:**
For personal tools where the user owns the API key, obfuscation is a reasonable tradeoff between security and usability. For production apps, use a backend proxy.

**Related:**
- Decision 002 (localStorage persistence)
- invoice-generator.html obfuscation functions
