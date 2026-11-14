# Invoice Generator API Reference

Complete API endpoint documentation for the Invoice Generator backend.

## Base URL

```
http://localhost:8002
```

## Authentication

Currently, the API does not require authentication. All endpoints are publicly accessible.

> Note: For production use, add authentication middleware to protect endpoints.

---

## Endpoints Overview

| Category | Endpoint | Method | Description |
|----------|----------|--------|-------------|
| **Root** | `/` | GET | API information |
| **Health** | `/health` | GET | Health check |
| **Clients** | `/api/clients` | GET | List all clients |
| | `/api/clients` | POST | Create client |
| | `/api/clients/{id}` | GET | Get client |
| | `/api/clients/{id}` | PUT | Update client |
| | `/api/clients/{id}` | DELETE | Delete client |
| **Invoices** | `/api/invoices` | GET | List invoices |
| | `/api/invoices` | POST | Create invoice |
| | `/api/invoices/{id}` | GET | Get invoice |
| | `/api/invoices/{id}` | PUT | Update invoice |
| | `/api/invoices/{id}` | DELETE | Delete invoice |
| | `/api/invoices/{id}/line-items` | POST | Add line item |
| | `/api/invoices/{id}/line-items/{line_id}` | DELETE | Delete line item |
| **Recurring** | `/api/recurring-items` | GET | List recurring items |
| | `/api/recurring-items` | POST | Create recurring item |
| | `/api/recurring-items/{id}` | GET | Get recurring item |
| | `/api/recurring-items/{id}` | PUT | Update recurring item |
| | `/api/recurring-items/{id}` | DELETE | Delete recurring item |
| | `/api/recurring-items/{id}/use` | POST | Increment usage |

---

## Client Endpoints

### List All Clients

```http
GET /api/clients
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "company": "Acme Corp",
    "email": "john@acme.com",
    "phone": "555-1234",
    "address_line1": "123 Main St",
    "address_line2": "Suite 100",
    "city": "San Francisco",
    "state": "CA",
    "zip": "94105",
    "country": "USA",
    "notes": "Primary client",
    "created_at": "2026-01-02T10:00:00Z",
    "updated_at": "2026-01-02T10:00:00Z"
  }
]
```

### Get Client by ID

```http
GET /api/clients/{id}
```

**Response:** Same as single client object above

### Create Client

```http
POST /api/clients
Content-Type: application/json

{
  "name": "Jane Smith",
  "company": "Tech Startup Inc",
  "email": "jane@techstartup.com",
  "phone": "555-5678",
  "address_line1": "456 Oak Ave",
  "city": "Austin",
  "state": "TX",
  "zip": "78701"
}
```

**Response:** Created client object with `id`, `created_at`, and `updated_at`

### Update Client

```http
PUT /api/clients/{id}
Content-Type: application/json

{
  "email": "newemail@techstartup.com",
  "phone": "555-9999"
}
```

**Response:** Updated client object

### Delete Client

```http
DELETE /api/clients/{id}
```

**Response:**
```json
{
  "message": "Client {id} deleted successfully"
}
```

**Note:** Deletion will fail if client has existing invoices (409 Conflict)

---

## Invoice Endpoints

### List All Invoices

```http
GET /api/invoices
```

**Query Parameters:**
- `status` (optional): Filter by payment status (`unpaid`, `paid`, `partial`)

**Examples:**
```http
GET /api/invoices
GET /api/invoices?status=unpaid
GET /api/invoices?status=paid
```

**Response:**
```json
[
  {
    "id": 1,
    "invoice_number": "01022026-1",
    "client_id": 1,
    "invoice_for": "January Consulting Services",
    "project": "Website Development",
    "submitted_date": "2026-01-02",
    "due_date": "2026-01-16",
    "subtotal": 1500.00,
    "adjustments": 0.00,
    "total": 1500.00,
    "payment_status": "unpaid",
    "payment_date": null,
    "payment_method": null,
    "payment_notes": null,
    "created_at": "2026-01-02T10:00:00Z",
    "updated_at": "2026-01-02T10:00:00Z",
    "pdf_generated_at": null
  }
]
```

### Get Invoice with Line Items

```http
GET /api/invoices/{id}
```

**Response:**
```json
{
  "id": 1,
  "invoice_number": "01022026-1",
  "client_id": 1,
  "invoice_for": "January Consulting Services",
  "project": "Website Development",
  "submitted_date": "2026-01-02",
  "due_date": "2026-01-16",
  "subtotal": 1500.00,
  "adjustments": 0.00,
  "total": 1500.00,
  "payment_status": "unpaid",
  "payment_date": null,
  "payment_method": null,
  "payment_notes": null,
  "created_at": "2026-01-02T10:00:00Z",
  "updated_at": "2026-01-02T10:00:00Z",
  "pdf_generated_at": null,
  "line_items": [
    {
      "id": 1,
      "invoice_id": 1,
      "item_date": "2026-01-02",
      "description": "Consulting Services - 10 hours",
      "qty": 10,
      "unit_price": 150.00,
      "total_price": 1500.00,
      "note": "Website consultation and planning",
      "note_in_pdf": true,
      "original_extraction": "01/02 Consulting - 10hrs @ $150",
      "line_order": 0,
      "created_at": "2026-01-02T10:00:00Z",
      "updated_at": "2026-01-02T10:00:00Z"
    }
  ]
}
```

### Create Invoice

```http
POST /api/invoices
Content-Type: application/json

{
  "invoice_number": "01022026-1",
  "client_id": 1,
  "invoice_for": "January Consulting Services",
  "project": "Website Development",
  "submitted_date": "2026-01-02",
  "due_date": "2026-01-16",
  "payment_status": "unpaid",
  "line_items": [
    {
      "item_date": "2026-01-02",
      "description": "Consulting Services",
      "qty": 10,
      "unit_price": 150.00,
      "total_price": 1500.00,
      "line_order": 0
    },
    {
      "item_date": "2026-01-03",
      "description": "Development Work",
      "qty": 5,
      "unit_price": 200.00,
      "total_price": 1000.00,
      "line_order": 1
    }
  ]
}
```

**Response:** Created invoice with line items

**Notes:**
- `subtotal` and `total` are automatically calculated from line items
- `line_items` is optional (can create invoice without items)

### Update Invoice

```http
PUT /api/invoices/{id}
Content-Type: application/json

{
  "payment_status": "paid",
  "payment_date": "2026-01-10",
  "payment_method": "check",
  "payment_notes": "Check #1234"
}
```

**Response:** Updated invoice object

**Note:** This endpoint updates invoice metadata only, not line items

### Delete Invoice

```http
DELETE /api/invoices/{id}
```

**Response:**
```json
{
  "message": "Invoice {id} deleted successfully"
}
```

**Note:** This will also delete all associated line items (cascade)

### Add Line Item to Invoice

```http
POST /api/invoices/{id}/line-items
Content-Type: application/json

{
  "invoice_id": 1,
  "item_date": "2026-01-05",
  "description": "Additional Services",
  "qty": 3,
  "unit_price": 100.00,
  "total_price": 300.00,
  "line_order": 2
}
```

**Response:** Created line item object

**Note:** Invoice totals are automatically recalculated

### Delete Line Item

```http
DELETE /api/invoices/{invoice_id}/line-items/{line_item_id}
```

**Response:**
```json
{
  "message": "Line item {id} deleted successfully"
}
```

**Note:** Invoice totals are automatically recalculated

---

## Recurring Items Endpoints

### List All Recurring Items

```http
GET /api/recurring-items
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Hourly Consulting",
    "description": "Standard consulting rate per hour",
    "default_qty": 1,
    "default_price": 150.00,
    "category": "Services",
    "use_count": 15,
    "last_used_at": "2026-01-01T14:30:00Z",
    "created_at": "2025-12-01T10:00:00Z",
    "updated_at": "2026-01-01T14:30:00Z"
  }
]
```

**Note:** Results are ordered by `use_count` (most used first)

### Get Recurring Item

```http
GET /api/recurring-items/{id}
```

**Response:** Single recurring item object

### Create Recurring Item

```http
POST /api/recurring-items
Content-Type: application/json

{
  "name": "Website Hosting",
  "description": "Monthly website hosting fee",
  "default_qty": 1,
  "default_price": 49.99,
  "category": "Hosting"
}
```

**Response:** Created recurring item with `id`, timestamps, and `use_count: 0`

### Update Recurring Item

```http
PUT /api/recurring-items/{id}
Content-Type: application/json

{
  "default_price": 59.99
}
```

**Response:** Updated recurring item object

### Delete Recurring Item

```http
DELETE /api/recurring-items/{id}
```

**Response:**
```json
{
  "message": "Recurring item {id} deleted successfully"
}
```

### Increment Usage

```http
POST /api/recurring-items/{id}/use
```

**Response:** Updated recurring item with incremented `use_count` and updated `last_used_at`

**Use Case:** Call this endpoint when a recurring item is added to an invoice to track usage statistics

---

## Error Responses

All endpoints return standard HTTP error codes with JSON error details:

### 400 Bad Request

```json
{
  "detail": "No fields to update"
}
```

### 404 Not Found

```json
{
  "detail": "Client with ID 999 not found"
}
```

### 409 Conflict

```json
{
  "detail": "Invoice number 01022026-1 already exists"
}
```

### 500 Internal Server Error

```json
{
  "detail": "Failed to create client: database error message"
}
```

---

## Data Types

### Date Format

All dates use ISO 8601 format: `YYYY-MM-DD`

Example: `"2026-01-02"`

### DateTime Format

All timestamps use ISO 8601 format with UTC timezone: `YYYY-MM-DDTHH:MM:SSZ`

Example: `"2026-01-02T10:30:00Z"`

### Currency

All currency amounts are floats with 2 decimal places

Example: `150.00`

### Payment Status

Valid values: `"unpaid"`, `"paid"`, `"partial"`

---

## Interactive Documentation

Visit these URLs when the server is running:

- **Swagger UI:** http://localhost:8002/docs
- **ReDoc:** http://localhost:8002/redoc

Both provide interactive API testing and detailed schema documentation.

---

## Sample Workflow

### 1. Create a Client

```bash
curl -X POST http://localhost:8002/api/clients \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "company": "Acme Corp",
    "email": "john@acme.com"
  }'
```

### 2. Create an Invoice for the Client

```bash
curl -X POST http://localhost:8002/api/invoices \
  -H "Content-Type: application/json" \
  -d '{
    "invoice_number": "01022026-1",
    "client_id": 1,
    "invoice_for": "January Services",
    "submitted_date": "2026-01-02",
    "due_date": "2026-01-16",
    "payment_status": "unpaid",
    "line_items": [
      {
        "item_date": "2026-01-02",
        "description": "Consulting",
        "qty": 10,
        "unit_price": 150.00,
        "total_price": 1500.00,
        "line_order": 0
      }
    ]
  }'
```

### 3. Mark Invoice as Paid

```bash
curl -X PUT http://localhost:8002/api/invoices/1 \
  -H "Content-Type: application/json" \
  -d '{
    "payment_status": "paid",
    "payment_date": "2026-01-10",
    "payment_method": "check"
  }'
```

### 4. List Unpaid Invoices

```bash
curl http://localhost:8002/api/invoices?status=unpaid
```

---

## Rate Limiting

Currently, no rate limiting is implemented. For production use, consider adding rate limiting middleware.

## CORS

The API allows requests from:
- `http://localhost:3002`
- `http://127.0.0.1:3002`
- `http://localhost:8080`
- `http://127.0.0.1:8080`

To add more origins, edit the `origins` list in `main.py`.
