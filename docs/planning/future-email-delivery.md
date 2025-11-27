# Future Feature: Email Invoice Delivery

**Status:** Planning (Future)
**Priority:** Low
**Prerequisite:** Invoice History feature complete

---

## Problem

Currently, users must:
1. Download PDF
2. Open email client
3. Attach PDF
4. Type client email
5. Send

This is friction that could be automated.

---

## Solution Options

### Option 1: EmailJS (No Backend)

**How it works:**
- EmailJS is a service that sends emails from browser JavaScript
- No backend required
- User creates free EmailJS account
- Configure email template
- App calls EmailJS API with PDF attachment

**Pros:**
- Stays browser-only
- Free tier: 200 emails/month
- Easy setup

**Cons:**
- Requires EmailJS account
- PDF must be base64 encoded (size limits)
- Another API key to manage

**Implementation:**
```javascript
// EmailJS integration
emailjs.send("service_id", "template_id", {
  to_email: client.email,
  from_name: "SWS Management Services",
  invoice_number: invoice.number,
  amount: invoice.total,
  pdf_attachment: base64Pdf  // May have size limits
});
```

### Option 2: Mailto Link with Instructions

**How it works:**
- Generate mailto: link with pre-filled subject/body
- User clicks, opens email client
- User manually attaches downloaded PDF

**Pros:**
- Zero external dependencies
- Works with any email client
- No account/API needed

**Cons:**
- Can't attach PDF automatically
- Two-step process (download + email)
- Less seamless

**Implementation:**
```javascript
const mailto = `mailto:${client.email}?subject=Invoice ${invoice.number}&body=...`;
window.open(mailto);
```

### Option 3: Backend Service (Future)

**How it works:**
- Add simple backend (Node.js, Python)
- Backend sends email via SendGrid/Mailgun/SES
- More reliable, larger attachments

**Pros:**
- Professional email delivery
- No size limits
- Tracking (opened, clicked)
- Templates

**Cons:**
- Requires backend hosting
- Monthly cost for email service
- More complex architecture

---

## Recommended Approach

**Phase 1: Mailto Link (Quick win)**
- Implement mailto: with pre-filled subject/body
- User downloads PDF, then clicks "Email to Client"
- Opens their email client with draft ready
- They attach the PDF manually

**Phase 2: EmailJS (If demand exists)**
- Add EmailJS integration
- User enters their EmailJS credentials in settings
- One-click send with attachment

**Phase 3: Backend (If scaling)**
- Only if app becomes multi-user SaaS
- Proper email infrastructure

---

## UI Design

### Mailto Approach (Phase 1)

After PDF download, show:
```
┌─────────────────────────────────────────────────────┐
│  Invoice Downloaded!                               │
│                                                     │
│  📄 Invoice-11262025-1.pdf saved                   │
│                                                     │
│  [📧 Email to Client]                              │
│                                                     │
│  Opens your email client with:                     │
│  To: carrie@aplusgaragedoor.com                   │
│  Subject: Invoice #11262025-1 from SWS Management │
│  Body: (pre-filled message)                        │
│                                                     │
│  Don't forget to attach the PDF!                   │
└─────────────────────────────────────────────────────┘
```

### EmailJS Approach (Phase 2)

Settings section:
```
┌─────────────────────────────────────────────────────┐
│  Email Settings                                     │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  EmailJS Service ID: [________________]            │
│  EmailJS Template ID: [________________]           │
│  EmailJS Public Key: [________________]            │
│                                                     │
│  [Test Email Settings]                             │
│                                                     │
│  ℹ️ Get your keys at emailjs.com (free tier: 200/mo)│
└─────────────────────────────────────────────────────┘
```

Preview step with email option:
```
┌─────────────────────────────────────────────────────┐
│  [Download PDF]  [Send via Email]                  │
└─────────────────────────────────────────────────────┘
```

---

## Data Requirements

### Client Email Field

Add email to saved client profiles:
```javascript
{
  "saved_clients": [
    {
      "id": 123,
      "name": "Carrie Kelsch",
      "company": "A Plus Garage Door",
      "email": "carrie@aplusgaragedoor.com",  // NEW
      // ...
    }
  ]
}
```

### Email Template

Default email body:
```
Hi {client_name},

Please find attached Invoice #{invoice_number} for {invoice_for}.

Amount Due: {total}
Due Date: {due_date}

Thank you for your business!

{company_name}
{company_phone}
```

---

## Implementation Checklist

### Phase 1: Mailto
- [ ] Add email field to client profile
- [ ] Generate mailto: link with pre-filled content
- [ ] Show "Email to Client" button after download
- [ ] Track that email was initiated (optional)

### Phase 2: EmailJS
- [ ] Add EmailJS settings to app
- [ ] Implement EmailJS send function
- [ ] Convert PDF to base64 for attachment
- [ ] Handle send success/failure
- [ ] Show delivery status

---

## Timeline

- **Phase 1:** Can be done in 1-2 hours after Invoice History
- **Phase 2:** 2-4 hours, plus user setup time
- **Phase 3:** Separate project (backend development)

---

## Decision Needed

Before implementing, decide:
1. Is mailto: good enough for now?
2. Do we want to add client email field to profiles?
3. Is EmailJS complexity worth it?

**Recommendation:** Start with Phase 1 (mailto:), see if users request more.
