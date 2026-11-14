# Feature: Invoice Management System

**Branch:** `feature/invoice-management`
**Created:** 2025-11-26
**Status:** Planning

---

## Master Checklist

### Phase 1: Data Infrastructure
- [ ] Design localStorage schema for all new data
- [ ] Implement export/import for data backup
- [ ] Add data migration support (version schema)

### Phase 2: Invoice History
- [ ] Save invoices to localStorage on PDF download
- [ ] Invoice list view (sidebar or modal)
- [ ] View past invoice details
- [ ] Delete invoice from history
- [ ] Duplicate invoice (copy to new)

### Phase 3: Payment Tracking
- [ ] Add payment status field (Paid/Unpaid/Partial)
- [ ] Add payment date field
- [ ] Add payment method field
- [ ] Filter invoices by payment status
- [ ] Visual indicator on invoice list

### Phase 4: Recurring Items Library
- [ ] Save items to library from line items table
- [ ] Library management UI (view/edit/delete)
- [ ] Quick-add from library to current invoice
- [ ] Import multiple library items at once

### Phase 5: Line Item Notes
- [ ] Add notes field to line item data model
- [ ] Auto-populate notes with original extraction details
- [ ] Notes input in line items table
- [ ] Toggle: include note in PDF (per item)
- [ ] Render notes in PDF preview when toggled

### Phase 6: "Invoice Like Last Month"
- [ ] Detect client's previous invoices
- [ ] Show "Copy from previous" option when client selected
- [ ] Display previous invoice items as checkboxes
- [ ] Copy selected items to current invoice
- [ ] Increment invoice number automatically

### Phase 7: Testing & Polish
- [ ] Test all localStorage operations
- [ ] Test export/import round-trip
- [ ] Test with large data sets
- [ ] Update documentation
- [ ] Update ROADMAP.md

---

## Feature 1: Data Infrastructure & Export/Import

### Problem
localStorage can be cleared by user or browser. Users need a way to backup and restore their data.

### Solution
- Export all app data as a single JSON file
- Import from JSON file to restore
- Version the schema for future migrations

### localStorage Schema (v1)

```javascript
{
  // Existing
  "anthropic_api_key": "obfuscated_string",
  "saved_clients": [...],

  // New
  "invoice_data_version": 1,
  "invoice_history": [...],
  "recurring_items": [...],
  "app_settings": {...}
}
```

### Invoice History Schema

```javascript
{
  "invoice_history": [
    {
      "id": "inv_1732645200000",
      "invoiceNumber": "11262025-1",
      "createdAt": "2025-11-26T14:30:00Z",
      "updatedAt": "2025-11-26T14:30:00Z",

      // Client info
      "client": {
        "name": "Carrie Kelsch",
        "company": "A Plus Garage Door",
        "address1": "2475 Decker Lake Blvd",
        "address2": "Salt Lake City, Utah 84790"
      },

      // Invoice details
      "invoiceFor": "October Consulting Services",
      "project": "Garage Door Pros",
      "submittedDate": "11/26/2025",
      "dueDate": "12/26/2025",

      // Line items
      "lineItems": [
        {
          "id": 1732645200001,
          "date": "10/02/2025",
          "description": "EPY*COLONIAL GENERAL INSURANCE",
          "qty": 1,
          "unitPrice": 876.57,
          "totalPrice": 876.57,
          "note": "Annual liability insurance renewal",
          "noteInPdf": true,
          "originalExtraction": "EPY*COLONIAL GENERAL I SCOTTSDALE AZ"
        }
      ],

      // Totals
      "subtotal": 4415.81,
      "adjustments": 0,
      "total": 4415.81,

      // Payment tracking
      "payment": {
        "status": "unpaid",  // "paid", "unpaid", "partial"
        "datePaid": null,
        "method": null,      // "check", "ach", "card", "cash", "other"
        "notes": null
      },

      // Metadata
      "sourceStatements": ["statement1.pdf", "statement2.pdf"]
    }
  ]
}
```

### Recurring Items Schema

```javascript
{
  "recurring_items": [
    {
      "id": "rec_1732645200000",
      "name": "Monthly Consulting",  // Display name in library
      "description": "Monthly Consulting Services",
      "defaultQty": 1,
      "defaultPrice": 1500.00,
      "category": null,  // Future: categorization
      "lastUsed": "2025-11-26T14:30:00Z",
      "useCount": 5
    }
  ]
}
```

### Export Format

```javascript
{
  "exportVersion": 1,
  "exportDate": "2025-11-26T14:30:00Z",
  "appVersion": "1.0.0",
  "data": {
    "clients": [...],
    "invoices": [...],
    "recurringItems": [...],
    "settings": {...}
  }
}
```

### UI Changes

**Settings/Data Section (new):**
```
┌─────────────────────────────────────────────────────┐
│  Data Management                              ⚙️    │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  [📥 Export All Data]  [📤 Import Data]            │
│                                                     │
│  Last backup: Never                                 │
│  Invoices: 0 | Clients: 0 | Library items: 0       │
└─────────────────────────────────────────────────────┘
```

---

## Feature 2: Invoice History

### Problem
No record of past invoices. Can't reference or duplicate previous work.

### Solution
Auto-save invoice to history when downloading PDF. Provide list view to browse, view, duplicate, or delete.

### UI: Invoice History Panel

**Access:** Button in header or sidebar icon

```
┌─────────────────────────────────────────────────────┐
│  Invoice History                           [✕]     │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  🔍 [Search invoices...]    [Filter: All ▼]        │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ #11262025-1                        $4,415.81│   │
│  │ A Plus Garage Door                          │   │
│  │ Oct 2025 · 🔴 Unpaid                        │   │
│  │ [View] [Duplicate] [Delete]                 │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ #10262025-1                        $3,200.00│   │
│  │ A Plus Garage Door                          │   │
│  │ Sep 2025 · 🟢 Paid 10/30/2025              │   │
│  │ [View] [Duplicate] [Delete]                 │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Actions

- **View:** Open invoice in preview mode (read-only)
- **Duplicate:** Copy to new invoice (new number, today's date)
- **Delete:** Remove from history (with confirmation)
- **Mark Paid:** Quick action to update payment status

---

## Feature 3: Payment Tracking

### Problem
No way to track which invoices have been paid.

### Solution
Add payment status, date, and method fields. Show status in history list.

### Payment Status Options
- **Unpaid** (red) - Invoice sent, awaiting payment
- **Partial** (yellow) - Some payment received
- **Paid** (green) - Fully paid

### Payment Methods
- Check
- ACH/Bank Transfer
- Credit Card
- Cash
- Other

### UI: Payment Section in Details Step

```
┌─────────────────────────────────────────────────────┐
│  Payment Tracking (optional)                        │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  Status: [Unpaid ▼]                                │
│                                                     │
│  (If Paid or Partial:)                             │
│  Date Paid: [📅 ___________]                       │
│  Method:    [Select method ▼]                      │
│  Notes:     [_________________________]            │
└─────────────────────────────────────────────────────┘
```

---

## Feature 4: Recurring Items Library

### Problem
Manually re-entering common charges every month.

### Solution
Save frequently-used items to a library. Quick-add to current invoice.

### UI: Library Panel

**Access:** "Library" tab or button in Line Items step

```
┌─────────────────────────────────────────────────────┐
│  Recurring Items Library                    [✕]    │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ ☐ Monthly Consulting           $1,500.00   │   │
│  │   "Monthly Consulting Services"             │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ ☐ SEO Services                   $500.00   │   │
│  │   "SEO keyword research and optimization"   │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  [Add Selected to Invoice]                         │
│                                                     │
│  ─────────────────────────────────────────────────  │
│  [+ Add New Item to Library]                       │
└─────────────────────────────────────────────────────┘
```

### Save to Library

From line items table, add "Save to Library" action per row:
```
[Date] [Description] [Qty] [Price] [Total] [Actions]
                                            [🗑️] [💾]
                                                  ↑
                                          Save to Library
```

---

## Feature 5: Line Item Notes

### Problem
Need to add context to charges. Original bank descriptions are often cryptic.

### Solution
Add notes field per line item. Auto-populate with original extraction. Toggle to include in PDF.

### Data Model Addition

```javascript
{
  // Existing fields...
  "note": "Annual liability insurance renewal",
  "noteInPdf": true,  // Toggle: show in PDF
  "originalExtraction": "EPY*COLONIAL GENERAL I SCOTTSDALE AZ"  // Preserved
}
```

### UI: Expandable Note Row

```
┌────────────────────────────────────────────────────────────────┐
│ Date       │ Description                    │ Qty │ Price │ ▼ │
├────────────────────────────────────────────────────────────────┤
│ 10/02/2025 │ Colonial General Insurance     │  1  │ $876  │ ▼ │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ Note: [Annual liability insurance renewal        ]       │  │
│ │ ☑️ Include in PDF                                        │  │
│ │ Original: EPY*COLONIAL GENERAL I SCOTTSDALE AZ          │  │
│ └──────────────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────────────┤
│ 10/06/2025 │ Online Advance                 │  1  │ $1000 │ ► │
└────────────────────────────────────────────────────────────────┘
```

### PDF Rendering (when noteInPdf = true)

```
┌────────────────────────────────────────────────────────────────┐
│ Description                              │ Qty │ Price │ Total │
├────────────────────────────────────────────────────────────────┤
│ 10/02/2025 Colonial General Insurance    │  1  │ $876  │ $876  │
│   └ Annual liability insurance renewal                        │
├────────────────────────────────────────────────────────────────┤
│ 10/06/2025 Online Advance                │  1  │ $1000 │ $1000 │
└────────────────────────────────────────────────────────────────┘
```

---

## Feature 6: "Invoice Like Last Month"

### Problem
Same clients, similar charges every month. Tedious to re-enter.

### Solution
When selecting a saved client, offer to copy items from their last invoice.

### Flow

1. User selects saved client from dropdown
2. System detects previous invoices for this client
3. Shows "Copy from previous invoice?" prompt
4. User selects which items to copy
5. Items added to current invoice with today's date

### UI: Copy from Previous Modal

```
┌─────────────────────────────────────────────────────┐
│  Copy from Previous Invoice?                [✕]    │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  Last invoice for A Plus Garage Door:              │
│  #10262025-1 · Sep 2025 · $3,200.00               │
│                                                     │
│  Select items to copy:                             │
│                                                     │
│  ☑️ Monthly Consulting Services        $1,500.00   │
│  ☑️ SEO Services                         $500.00   │
│  ☐ Colonial General Insurance           $876.57   │
│  ☑️ Google Ads                           $500.00   │
│                                                     │
│  [Select All] [Select None]                        │
│                                                     │
│  [Copy Selected Items]  [Start Fresh]              │
└─────────────────────────────────────────────────────┘
```

### Behavior
- Dates updated to current month
- Invoice number auto-incremented
- Notes and settings preserved
- User can still add/remove items after copying

---

## Implementation Order

1. **Data Infrastructure** - Foundation for everything else
2. **Invoice History** - Core feature, enables everything else
3. **Payment Tracking** - Quick add-on to history
4. **Line Item Notes** - Independent, can parallel with above
5. **Recurring Items Library** - Builds on history data
6. **"Invoice Like Last Month"** - Requires history + client detection

---

## Testing Plan

- [ ] Export empty data, import, verify no errors
- [ ] Export with data, import to fresh browser, verify all restored
- [ ] Create invoice, save, view in history, verify all fields
- [ ] Duplicate invoice, verify new number generated
- [ ] Mark invoice paid, verify status persists
- [ ] Add note to item, toggle PDF inclusion, verify PDF output
- [ ] Save item to library, add from library, verify values
- [ ] Select client with history, copy items, verify correct data

---

## Open Questions

1. **Max history size?** Should we limit to last 100 invoices to prevent localStorage bloat?
2. **Archive old invoices?** Move to separate "archive" after 1 year?
3. **Search in history?** Full-text search or just filter by client/date/status?
