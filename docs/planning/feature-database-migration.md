# Feature: Database Migration (localStorage → SQL)

**Status:** Planning
**Created:** 2025-12-09
**Priority:** High (foundational for multi-device, data integrity)

---

## Problem Statement

Current localStorage-based storage has limitations:
- **Browser-specific** - Data trapped in single browser/device
- **No backup safety** - Can be cleared by user or browser
- **No concurrent access** - Can't share data across devices
- **Size limits** - 5-10MB localStorage cap
- **No relationships** - Hard to enforce data integrity
- **No queries** - Limited search/filter capabilities

## Solution Overview

Migrate from localStorage to SQL database for persistent, multi-device storage.

---

## Architecture Decision Matrix

### Option 1: SQLite + Local Backend (Recommended for MVP)

**Pros:**
- ✅ Simplest migration path
- ✅ Single-file database (portable)
- ✅ No hosting costs
- ✅ Works offline
- ✅ Fast development
- ✅ Easy backup (copy one file)

**Cons:**
- ❌ Still single-device (unless file synced)
- ❌ Requires local backend server
- ❌ No built-in multi-user support

**Best for:** Personal use, testing SQL migration before cloud deployment

---

### Option 2: PostgreSQL + Cloud Backend

**Pros:**
- ✅ Multi-device access
- ✅ True persistence
- ✅ Robust querying
- ✅ Scalable
- ✅ Industry standard

**Cons:**
- ❌ Requires hosting ($5-20/month)
- ❌ More complex setup
- ❌ Network dependency
- ❌ Privacy concerns (data on cloud)

**Best for:** Production use, multiple devices, sharing with team

---

### Option 3: Hybrid Approach (localStorage + Optional Sync)

**Pros:**
- ✅ Works offline (localStorage first)
- ✅ Optional cloud sync for multi-device
- ✅ User controls data location
- ✅ Best privacy + convenience balance

**Cons:**
- ❌ Most complex to implement
- ❌ Sync conflicts to handle
- ❌ Two storage systems to maintain

**Best for:** Users who want offline-first with optional cloud backup

---

## Recommended Path: Phased Migration

### Phase 1: SQLite + Local Backend (Start Here)
- Migrate localStorage → SQLite
- Add lightweight backend (FastAPI/Express)
- Keep browser UI mostly unchanged
- Test SQL schema with real data

### Phase 2: Optional Cloud Sync
- Add PostgreSQL cloud option
- User chooses: local-only or cloud sync
- Implement sync logic

### Phase 3: Full Cloud Migration
- Default to cloud database
- Keep local cache for offline
- Multi-device by default

---

## SQL Schema Design

### Database: `invoice_generator.db`

```sql
-- ============================================
-- Core Tables
-- ============================================

-- API Keys (obfuscated)
CREATE TABLE api_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider VARCHAR(50) NOT NULL,  -- 'anthropic', 'openai', etc.
    key_hash VARCHAR(255) NOT NULL,  -- Encrypted/hashed key
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clients
CREATE TABLE clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(name, company)  -- Prevent duplicate clients
);

-- Invoices
CREATE TABLE invoices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    client_id INTEGER NOT NULL,

    -- Invoice details
    invoice_for VARCHAR(255),  -- "October Consulting Services"
    project VARCHAR(255),
    submitted_date DATE NOT NULL,
    due_date DATE,

    -- Totals
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    adjustments DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,

    -- Payment tracking
    payment_status VARCHAR(20) DEFAULT 'unpaid',  -- unpaid, paid, partial
    payment_date DATE,
    payment_method VARCHAR(50),  -- check, ach, card, cash, other
    payment_notes TEXT,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pdf_generated_at TIMESTAMP,

    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT
);

CREATE INDEX idx_invoices_client_id ON invoices(client_id);
CREATE INDEX idx_invoices_payment_status ON invoices(payment_status);
CREATE INDEX idx_invoices_submitted_date ON invoices(submitted_date);

-- Line Items
CREATE TABLE line_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER NOT NULL,

    -- Item details
    item_date DATE NOT NULL,
    description VARCHAR(500) NOT NULL,
    qty INTEGER DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,

    -- Notes
    note TEXT,
    note_in_pdf BOOLEAN DEFAULT FALSE,
    original_extraction VARCHAR(500),  -- Original bank statement text

    -- Ordering
    line_order INTEGER DEFAULT 0,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

CREATE INDEX idx_line_items_invoice_id ON line_items(invoice_id);

-- Recurring Items Library
CREATE TABLE recurring_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255) NOT NULL UNIQUE,  -- Display name
    description VARCHAR(500) NOT NULL,
    default_qty INTEGER DEFAULT 1,
    default_price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),

    -- Usage tracking
    use_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Source Statements (track which PDFs were uploaded)
CREATE TABLE source_statements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER NOT NULL,
    filename VARCHAR(255) NOT NULL,
    file_size INTEGER,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

CREATE INDEX idx_source_statements_invoice_id ON source_statements(invoice_id);

-- ============================================
-- Supporting Tables
-- ============================================

-- App Settings
CREATE TABLE settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT,
    data_type VARCHAR(20) DEFAULT 'string',  -- string, number, boolean, json
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Data Version (for migrations)
CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(255)
);

-- Insert initial version
INSERT INTO schema_migrations (version, description)
VALUES (1, 'Initial schema creation');

-- ============================================
-- Views for Common Queries
-- ============================================

-- Invoice Summary View
CREATE VIEW invoice_summary AS
SELECT
    i.id,
    i.invoice_number,
    i.invoice_for,
    i.project,
    i.submitted_date,
    i.due_date,
    i.total,
    i.payment_status,
    i.payment_date,
    c.name as client_name,
    c.company as client_company,
    COUNT(li.id) as line_item_count,
    i.created_at,
    i.updated_at
FROM invoices i
JOIN clients c ON i.client_id = c.id
LEFT JOIN line_items li ON i.id = li.invoice_id
GROUP BY i.id
ORDER BY i.submitted_date DESC;

-- Client Invoice History
CREATE VIEW client_invoice_history AS
SELECT
    c.id as client_id,
    c.name as client_name,
    c.company as client_company,
    COUNT(i.id) as total_invoices,
    SUM(CASE WHEN i.payment_status = 'paid' THEN 1 ELSE 0 END) as paid_invoices,
    SUM(CASE WHEN i.payment_status = 'unpaid' THEN 1 ELSE 0 END) as unpaid_invoices,
    SUM(i.total) as total_billed,
    SUM(CASE WHEN i.payment_status = 'paid' THEN i.total ELSE 0 END) as total_paid,
    MAX(i.submitted_date) as last_invoice_date
FROM clients c
LEFT JOIN invoices i ON c.id = i.client_id
GROUP BY c.id;

-- ============================================
-- Triggers for Automatic Updates
-- ============================================

-- Update invoice totals when line items change
CREATE TRIGGER update_invoice_totals
AFTER INSERT ON line_items
BEGIN
    UPDATE invoices
    SET
        subtotal = (
            SELECT SUM(total_price)
            FROM line_items
            WHERE invoice_id = NEW.invoice_id
        ),
        total = (
            SELECT SUM(total_price)
            FROM line_items
            WHERE invoice_id = NEW.invoice_id
        ) + COALESCE(adjustments, 0),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.invoice_id;
END;

CREATE TRIGGER update_invoice_totals_on_delete
AFTER DELETE ON line_items
BEGIN
    UPDATE invoices
    SET
        subtotal = COALESCE((
            SELECT SUM(total_price)
            FROM line_items
            WHERE invoice_id = OLD.invoice_id
        ), 0),
        total = COALESCE((
            SELECT SUM(total_price)
            FROM line_items
            WHERE invoice_id = OLD.invoice_id
        ), 0) + COALESCE(adjustments, 0),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = OLD.invoice_id;
END;

-- Auto-update timestamps
CREATE TRIGGER update_clients_timestamp
AFTER UPDATE ON clients
BEGIN
    UPDATE clients SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_invoices_timestamp
AFTER UPDATE ON invoices
BEGIN
    UPDATE invoices SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_line_items_timestamp
AFTER UPDATE ON line_items
BEGIN
    UPDATE line_items SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
```

---

## Data Migration Strategy

### Step 1: Export Current localStorage

```javascript
// Export existing data before migration
function exportLocalStorageData() {
  const data = {
    version: 1,
    exportDate: new Date().toISOString(),
    apiKey: localStorage.getItem('anthropic_api_key'),
    clients: JSON.parse(localStorage.getItem('saved_clients') || '[]'),
    invoices: JSON.parse(localStorage.getItem('invoice_history') || '[]'),
    recurringItems: JSON.parse(localStorage.getItem('recurring_items') || '[]')
  };

  // Download as JSON backup
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `invoice-data-backup-${Date.now()}.json`;
  a.click();

  return data;
}
```

### Step 2: Migration Script (Python/FastAPI)

```python
import sqlite3
import json
from datetime import datetime

def migrate_localStorage_to_sqlite(data_file, db_path):
    """
    Migrate localStorage JSON export to SQLite database
    """
    # Load localStorage export
    with open(data_file, 'r') as f:
        data = json.load(f)

    # Connect to SQLite
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Execute schema creation (schema.sql)
    with open('schema.sql', 'r') as f:
        cursor.executescript(f.read())

    # Migrate clients
    client_id_map = {}  # localStorage ID → SQLite ID
    for client in data.get('clients', []):
        cursor.execute('''
            INSERT INTO clients (name, company, address_line1, address_line2)
            VALUES (?, ?, ?, ?)
        ''', (
            client['name'],
            client.get('company', ''),
            client.get('address1', ''),
            client.get('address2', '')
        ))
        client_id_map[client['id']] = cursor.lastrowid

    # Migrate invoices
    for invoice in data.get('invoices', []):
        # Insert invoice
        cursor.execute('''
            INSERT INTO invoices (
                invoice_number, client_id, invoice_for, project,
                submitted_date, due_date, subtotal, total,
                payment_status, payment_date, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            invoice['invoiceNumber'],
            client_id_map[invoice['client']['id']],  # Map to new client ID
            invoice.get('invoiceFor', ''),
            invoice.get('project', ''),
            invoice['submittedDate'],
            invoice.get('dueDate'),
            invoice['subtotal'],
            invoice['total'],
            invoice.get('payment', {}).get('status', 'unpaid'),
            invoice.get('payment', {}).get('datePaid'),
            invoice['createdAt']
        ))
        invoice_id = cursor.lastrowid

        # Insert line items
        for item in invoice.get('lineItems', []):
            cursor.execute('''
                INSERT INTO line_items (
                    invoice_id, item_date, description, qty,
                    unit_price, total_price, note, note_in_pdf,
                    original_extraction, line_order
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                invoice_id,
                item['date'],
                item['description'],
                item.get('qty', 1),
                item.get('unitPrice', item['totalPrice']),
                item['totalPrice'],
                item.get('note'),
                item.get('noteInPdf', False),
                item.get('originalExtraction'),
                item.get('id', 0)  # Use original ID as line_order
            ))

    # Migrate recurring items
    for item in data.get('recurringItems', []):
        cursor.execute('''
            INSERT INTO recurring_items (
                name, description, default_qty, default_price,
                use_count, last_used_at
            ) VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            item['name'],
            item['description'],
            item.get('defaultQty', 1),
            item['defaultPrice'],
            item.get('useCount', 0),
            item.get('lastUsed')
        ))

    conn.commit()
    conn.close()

    print(f"✅ Migration complete! Migrated:")
    print(f"   - {len(data.get('clients', []))} clients")
    print(f"   - {len(data.get('invoices', []))} invoices")
    print(f"   - {len(data.get('recurringItems', []))} recurring items")

# Run migration
if __name__ == '__main__':
    migrate_localStorage_to_sqlite(
        'invoice-data-backup.json',
        'invoice_generator.db'
    )
```

### Step 3: Verify Migration

```sql
-- Check record counts
SELECT 'clients' as table_name, COUNT(*) as count FROM clients
UNION ALL
SELECT 'invoices', COUNT(*) FROM invoices
UNION ALL
SELECT 'line_items', COUNT(*) FROM line_items
UNION ALL
SELECT 'recurring_items', COUNT(*) FROM recurring_items;

-- Verify invoice totals match
SELECT
    invoice_number,
    subtotal as calculated_subtotal,
    (SELECT SUM(total_price) FROM line_items WHERE invoice_id = invoices.id) as actual_subtotal
FROM invoices
WHERE subtotal != (SELECT SUM(total_price) FROM line_items WHERE invoice_id = invoices.id);

-- Should return empty if all totals match
```

---

## Backend Architecture

### Option A: FastAPI Backend (Python)

**Tech Stack:**
- Python 3.11+
- FastAPI (web framework)
- SQLite3 (database)
- Pydantic (data validation)
- CORS enabled for browser access

**File Structure:**
```
backend/
├── main.py                 # FastAPI app entry
├── database.py             # SQLite connection
├── models.py               # SQLAlchemy models
├── schemas.py              # Pydantic schemas
├── routes/
│   ├── invoices.py        # Invoice CRUD
│   ├── clients.py         # Client CRUD
│   ├── line_items.py      # Line items
│   └── recurring_items.py # Recurring library
├── migrations/
│   └── migrate_localStorage.py
└── invoice_generator.db   # SQLite database
```

**Minimal FastAPI Example:**

```python
# main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import sqlite3
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# Enable CORS for browser access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8000"],  # Your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database connection
def get_db():
    conn = sqlite3.connect('invoice_generator.db')
    conn.row_factory = sqlite3.Row
    return conn

# Pydantic models
class Client(BaseModel):
    id: Optional[int] = None
    name: str
    company: Optional[str] = None
    address_line1: Optional[str] = None
    address_line2: Optional[str] = None

class Invoice(BaseModel):
    id: Optional[int] = None
    invoice_number: str
    client_id: int
    invoice_for: Optional[str] = None
    project: Optional[str] = None
    submitted_date: str
    due_date: Optional[str] = None
    total: float
    payment_status: str = 'unpaid'

# Routes
@app.get("/api/clients")
def list_clients():
    db = get_db()
    cursor = db.execute("SELECT * FROM clients ORDER BY name")
    clients = [dict(row) for row in cursor.fetchall()]
    db.close()
    return clients

@app.post("/api/clients")
def create_client(client: Client):
    db = get_db()
    cursor = db.execute(
        "INSERT INTO clients (name, company, address_line1, address_line2) VALUES (?, ?, ?, ?)",
        (client.name, client.company, client.address_line1, client.address_line2)
    )
    db.commit()
    client_id = cursor.lastrowid
    db.close()
    return {"id": client_id, **client.dict()}

@app.get("/api/invoices")
def list_invoices(status: Optional[str] = None):
    db = get_db()
    query = "SELECT * FROM invoice_summary"
    if status:
        query += f" WHERE payment_status = ?"
        cursor = db.execute(query, (status,))
    else:
        cursor = db.execute(query)

    invoices = [dict(row) for row in cursor.fetchall()]
    db.close()
    return invoices

@app.get("/api/invoices/{invoice_id}")
def get_invoice(invoice_id: int):
    db = get_db()

    # Get invoice
    cursor = db.execute("SELECT * FROM invoices WHERE id = ?", (invoice_id,))
    invoice = cursor.fetchone()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    # Get line items
    cursor = db.execute(
        "SELECT * FROM line_items WHERE invoice_id = ? ORDER BY line_order",
        (invoice_id,)
    )
    line_items = [dict(row) for row in cursor.fetchall()]

    db.close()

    return {
        **dict(invoice),
        "line_items": line_items
    }

@app.post("/api/invoices")
def create_invoice(invoice: Invoice):
    # Implementation here
    pass

@app.put("/api/invoices/{invoice_id}")
def update_invoice(invoice_id: int, invoice: Invoice):
    # Implementation here
    pass

@app.delete("/api/invoices/{invoice_id}")
def delete_invoice(invoice_id: int):
    db = get_db()
    db.execute("DELETE FROM invoices WHERE id = ?", (invoice_id,))
    db.commit()
    db.close()
    return {"status": "deleted"}

# Health check
@app.get("/health")
def health_check():
    return {"status": "ok"}
```

**Run locally:**
```bash
pip install fastapi uvicorn
uvicorn main:app --reload --port 8000
```

---

### Option B: Express.js Backend (Node.js)

**Tech Stack:**
- Node.js 18+
- Express.js
- better-sqlite3
- CORS enabled

**Minimal Express Example:**

```javascript
// server.js
const express = require('express');
const cors = require('cors');
const Database = require('better-sqlite3');

const app = express();
const db = new Database('invoice_generator.db');

app.use(cors());
app.use(express.json());

// List clients
app.get('/api/clients', (req, res) => {
  const clients = db.prepare('SELECT * FROM clients ORDER BY name').all();
  res.json(clients);
});

// Create client
app.post('/api/clients', (req, res) => {
  const { name, company, address_line1, address_line2 } = req.body;
  const result = db.prepare(
    'INSERT INTO clients (name, company, address_line1, address_line2) VALUES (?, ?, ?, ?)'
  ).run(name, company, address_line1, address_line2);

  res.json({ id: result.lastInsertRowid, ...req.body });
});

// List invoices
app.get('/api/invoices', (req, res) => {
  const { status } = req.query;
  let query = 'SELECT * FROM invoice_summary';

  if (status) {
    query += ' WHERE payment_status = ?';
    const invoices = db.prepare(query).all(status);
    res.json(invoices);
  } else {
    const invoices = db.prepare(query).all();
    res.json(invoices);
  }
});

// Get single invoice with line items
app.get('/api/invoices/:id', (req, res) => {
  const invoice = db.prepare('SELECT * FROM invoices WHERE id = ?').get(req.params.id);

  if (!invoice) {
    return res.status(404).json({ error: 'Invoice not found' });
  }

  const lineItems = db.prepare(
    'SELECT * FROM line_items WHERE invoice_id = ? ORDER BY line_order'
  ).all(req.params.id);

  res.json({ ...invoice, line_items: lineItems });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(8000, () => {
  console.log('Backend running on http://localhost:8000');
});
```

**Run:**
```bash
npm install express cors better-sqlite3
node server.js
```

---

## Frontend Changes

### Update API Calls

Replace localStorage with API calls:

```javascript
// Before (localStorage)
const clients = JSON.parse(localStorage.getItem('saved_clients') || '[]');

// After (API)
const response = await fetch('http://localhost:8000/api/clients');
const clients = await response.json();
```

### API Client Wrapper

```javascript
// api.js
const API_BASE = 'http://localhost:8000';

export const api = {
  // Clients
  async getClients() {
    const res = await fetch(`${API_BASE}/api/clients`);
    return res.json();
  },

  async createClient(client) {
    const res = await fetch(`${API_BASE}/api/clients`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(client)
    });
    return res.json();
  },

  async deleteClient(clientId) {
    await fetch(`${API_BASE}/api/clients/${clientId}`, {
      method: 'DELETE'
    });
  },

  // Invoices
  async getInvoices(status = null) {
    const url = status
      ? `${API_BASE}/api/invoices?status=${status}`
      : `${API_BASE}/api/invoices`;
    const res = await fetch(url);
    return res.json();
  },

  async getInvoice(invoiceId) {
    const res = await fetch(`${API_BASE}/api/invoices/${invoiceId}`);
    return res.json();
  },

  async createInvoice(invoice) {
    const res = await fetch(`${API_BASE}/api/invoices`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(invoice)
    });
    return res.json();
  },

  async updateInvoice(invoiceId, updates) {
    const res = await fetch(`${API_BASE}/api/invoices/${invoiceId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates)
    });
    return res.json();
  },

  async deleteInvoice(invoiceId) {
    await fetch(`${API_BASE}/api/invoices/${invoiceId}`, {
      method: 'DELETE'
    });
  }
};
```

### Update React Component

```javascript
// In InvoiceGenerator component
import { api } from './api';

// Replace localStorage calls
useEffect(() => {
  // Before
  // const clients = JSON.parse(localStorage.getItem('saved_clients') || '[]');

  // After
  api.getClients().then(setSavedClients);
}, []);

// Save client
const saveCurrentClient = async () => {
  const newClient = {
    name: invoiceData.clientName || invoiceData.clientCompany,
    company: invoiceData.clientCompany,
    address_line1: invoiceData.clientAddress1,
    address_line2: invoiceData.clientAddress2
  };

  const saved = await api.createClient(newClient);
  setSavedClients([...savedClients, saved]);
};
```

---

## Implementation Checklist

### Phase 1: Local SQLite Backend (MVP)

**Backend Setup:**
- [ ] Choose backend framework (FastAPI or Express)
- [ ] Create `backend/` directory
- [ ] Set up SQLite database
- [ ] Create `schema.sql` with all tables
- [ ] Implement basic CRUD routes:
  - [ ] Clients (GET, POST, DELETE)
  - [ ] Invoices (GET, POST, PUT, DELETE)
  - [ ] Line Items (GET, POST, PUT, DELETE)
  - [ ] Recurring Items (GET, POST, DELETE)
- [ ] Enable CORS for browser access
- [ ] Add health check endpoint

**Migration:**
- [ ] Create localStorage export function
- [ ] Export current data to JSON
- [ ] Write migration script (Python/Node)
- [ ] Test migration with sample data
- [ ] Verify all records migrated correctly

**Frontend Updates:**
- [ ] Create `api.js` wrapper for all endpoints
- [ ] Replace localStorage calls with API calls
- [ ] Update client management to use API
- [ ] Update invoice history to use API
- [ ] Update recurring items to use API
- [ ] Test all features work with backend

**Testing:**
- [ ] Test all CRUD operations
- [ ] Test with large dataset (100+ invoices)
- [ ] Test invoice totals calculation
- [ ] Test payment status updates
- [ ] Test search/filter functionality
- [ ] Verify data integrity (foreign keys, cascades)

**Documentation:**
- [ ] Update README with backend setup
- [ ] Add backend API documentation
- [ ] Document migration process
- [ ] Update CLAUDE.md with new architecture

---

### Phase 2: Cloud PostgreSQL (Optional)

- [ ] Set up PostgreSQL database (Supabase, Neon, Railway)
- [ ] Convert SQLite schema to PostgreSQL
- [ ] Update backend to use PostgreSQL driver
- [ ] Add authentication (JWT, sessions)
- [ ] Implement user accounts
- [ ] Deploy backend to cloud (Render, Fly.io, Railway)
- [ ] Update frontend to use cloud API
- [ ] Test multi-device access

---

### Phase 3: Hybrid Sync (Advanced)

- [ ] Keep localStorage as cache
- [ ] Implement sync logic (push/pull)
- [ ] Handle conflict resolution
- [ ] Add offline detection
- [ ] Queue operations when offline
- [ ] Sync when back online

---

## Deployment Options

### Local-Only (SQLite)

**Pros:**
- Free, no hosting
- Complete privacy
- Fast

**Setup:**
```bash
# Backend
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000

# Frontend (existing)
# Open invoice-generator.html in browser
```

---

### Cloud Hosting (PostgreSQL)

#### Backend Options:

1. **Render.com** (Free tier)
   - PostgreSQL included
   - Auto-deploy from GitHub
   - $0/month for starter

2. **Railway.app** (Free tier)
   - PostgreSQL plugin
   - Easy deployment
   - $5/month usage credit

3. **Fly.io**
   - PostgreSQL addon
   - Global edge deployment
   - Pay-as-you-go

#### Database Options:

1. **Supabase** (Free tier)
   - PostgreSQL + Auth + Storage
   - 500MB database
   - Free forever tier

2. **Neon** (Free tier)
   - Serverless PostgreSQL
   - Auto-scale to zero
   - 512MB storage free

3. **PlanetScale** (Free tier)
   - MySQL-compatible
   - 5GB storage
   - Branching support

---

## Security Considerations

### API Key Storage

**Current:** Obfuscated in localStorage (weak)

**Improved:** Hash + encrypt in database

```python
import hashlib
import os
from cryptography.fernet import Fernet

# Generate encryption key (store securely, NOT in code)
ENCRYPTION_KEY = os.getenv('ENCRYPTION_KEY')
cipher = Fernet(ENCRYPTION_KEY)

def encrypt_api_key(key: str) -> str:
    return cipher.encrypt(key.encode()).decode()

def decrypt_api_key(encrypted: str) -> str:
    return cipher.decrypt(encrypted.encode()).decode()
```

### Database Access

- ✅ Use environment variables for DB credentials
- ✅ Never commit `.env` file
- ✅ Use prepared statements (prevents SQL injection)
- ✅ Add rate limiting to API endpoints
- ✅ Validate all inputs with Pydantic/Joi

### CORS Configuration

```python
# Production CORS (restrict to your domain)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

---

## Rollback Plan

If migration fails or issues arise:

1. **Backup exists** - localStorage export saved as JSON
2. **Restore function**:

```javascript
function restoreFromBackup(backupFile) {
  const data = JSON.parse(backupFile);
  localStorage.setItem('saved_clients', JSON.stringify(data.clients));
  localStorage.setItem('invoice_history', JSON.stringify(data.invoices));
  localStorage.setItem('recurring_items', JSON.stringify(data.recurringItems));
  alert('Data restored from backup!');
}
```

3. **Keep old version** - Tag current commit before migration
4. **Gradual rollout** - Test with copy of data first

---

## Cost Estimate

### Local SQLite (Recommended Start)
- **Backend:** Free (run locally)
- **Database:** Free (SQLite file)
- **Total:** $0/month

### Cloud Deployment (Production)
- **Backend:** $0-7/month (Render/Railway free tier)
- **Database:** $0-5/month (Supabase/Neon free tier)
- **Domain:** $12/year (optional)
- **Total:** $0-12/month

---

## Open Questions

1. **Multi-user support?** Do you need multiple users accessing the same data?
2. **Deployment preference?** Local-only or cloud-hosted?
3. **Budget?** Free tier only or willing to pay for hosting?
4. **Privacy requirements?** Must data stay local or cloud OK?
5. **Timeline?** When do you need this migration complete?

---

## Next Steps

**Immediate:**
1. Review this plan and decide: Local SQLite or Cloud PostgreSQL?
2. Answer open questions above
3. Export current localStorage data (backup)

**Then:**
1. Set up backend (1-2 days)
2. Run migration script (1 hour)
3. Update frontend API calls (1-2 days)
4. Test thoroughly (1 day)
5. Deploy (if cloud) or run locally

**Estimated Timeline:**
- **Local SQLite MVP:** 3-5 days
- **Cloud PostgreSQL:** 7-10 days
- **Hybrid Sync:** 14-21 days

---

## Success Criteria

✅ All localStorage data successfully migrated to SQL
✅ No data loss during migration
✅ All existing features work with new backend
✅ Invoice totals calculate correctly
✅ Search/filter works on large datasets
✅ Backend runs reliably (local or cloud)
✅ Clear rollback path if needed

---

**Ready to proceed?** Choose architecture (SQLite/PostgreSQL) and I'll create implementation tasks.
