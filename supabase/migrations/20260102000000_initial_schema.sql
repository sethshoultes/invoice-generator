-- ============================================
-- Invoice Generator - Initial Database Schema
-- Migration: 20260102000000
-- Description: Creates core tables for invoice management
-- ============================================

-- ============================================
-- Core Tables
-- ============================================

-- API Keys (obfuscated)
CREATE TABLE api_keys (
    id BIGSERIAL PRIMARY KEY,
    provider VARCHAR(50) NOT NULL,  -- 'anthropic', 'openai', etc.
    key_hash VARCHAR(255) NOT NULL,  -- Encrypted/hashed key
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Clients
CREATE TABLE clients (
    id BIGSERIAL PRIMARY KEY,
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_client_name_company UNIQUE(name, company)
);

-- Invoices
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    client_id BIGINT NOT NULL,

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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    pdf_generated_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT fk_invoice_client FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT
);

CREATE INDEX idx_invoices_client_id ON invoices(client_id);
CREATE INDEX idx_invoices_payment_status ON invoices(payment_status);
CREATE INDEX idx_invoices_submitted_date ON invoices(submitted_date);

-- Line Items
CREATE TABLE line_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL,

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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_line_item_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

CREATE INDEX idx_line_items_invoice_id ON line_items(invoice_id);

-- Recurring Items Library
CREATE TABLE recurring_items (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,  -- Display name
    description VARCHAR(500) NOT NULL,
    default_qty INTEGER DEFAULT 1,
    default_price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),

    -- Usage tracking
    use_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Source Statements (track which PDFs were uploaded)
CREATE TABLE source_statements (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    file_size INTEGER,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_source_statement_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Data Version (for migrations)
CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
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
GROUP BY i.id, c.id
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
-- Functions for Automatic Updates
-- ============================================

-- Function to update invoice totals
CREATE OR REPLACE FUNCTION update_invoice_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE invoices
    SET
        subtotal = (
            SELECT COALESCE(SUM(total_price), 0)
            FROM line_items
            WHERE invoice_id = COALESCE(NEW.invoice_id, OLD.invoice_id)
        ),
        total = (
            SELECT COALESCE(SUM(total_price), 0)
            FROM line_items
            WHERE invoice_id = COALESCE(NEW.invoice_id, OLD.invoice_id)
        ) + COALESCE(adjustments, 0),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Triggers for Automatic Updates
-- ============================================

-- Update invoice totals when line items change
CREATE TRIGGER trigger_update_invoice_totals_insert
AFTER INSERT ON line_items
FOR EACH ROW
EXECUTE FUNCTION update_invoice_totals();

CREATE TRIGGER trigger_update_invoice_totals_update
AFTER UPDATE ON line_items
FOR EACH ROW
EXECUTE FUNCTION update_invoice_totals();

CREATE TRIGGER trigger_update_invoice_totals_delete
AFTER DELETE ON line_items
FOR EACH ROW
EXECUTE FUNCTION update_invoice_totals();

-- Auto-update timestamps
CREATE TRIGGER trigger_update_clients_timestamp
BEFORE UPDATE ON clients
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_invoices_timestamp
BEFORE UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_line_items_timestamp
BEFORE UPDATE ON line_items
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_recurring_items_timestamp
BEFORE UPDATE ON recurring_items
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Row Level Security (RLS) Setup
-- ============================================

-- Enable RLS on all tables
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE source_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Default policies (allow all for now - can be restricted later with auth)
CREATE POLICY "Allow all access to api_keys" ON api_keys FOR ALL USING (true);
CREATE POLICY "Allow all access to clients" ON clients FOR ALL USING (true);
CREATE POLICY "Allow all access to invoices" ON invoices FOR ALL USING (true);
CREATE POLICY "Allow all access to line_items" ON line_items FOR ALL USING (true);
CREATE POLICY "Allow all access to recurring_items" ON recurring_items FOR ALL USING (true);
CREATE POLICY "Allow all access to source_statements" ON source_statements FOR ALL USING (true);
CREATE POLICY "Allow all access to settings" ON settings FOR ALL USING (true);

-- ============================================
-- Indexes for Performance
-- ============================================

-- Additional indexes for common queries
CREATE INDEX idx_clients_name ON clients(name);
CREATE INDEX idx_clients_company ON clients(company);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX idx_line_items_item_date ON line_items(item_date);
CREATE INDEX idx_recurring_items_use_count ON recurring_items(use_count DESC);

-- ============================================
-- Comments for Documentation
-- ============================================

COMMENT ON TABLE clients IS 'Client contact information and billing addresses';
COMMENT ON TABLE invoices IS 'Invoice headers with totals and payment tracking';
COMMENT ON TABLE line_items IS 'Individual line items for each invoice';
COMMENT ON TABLE recurring_items IS 'Library of frequently used line items';
COMMENT ON TABLE source_statements IS 'Tracks which bank statement PDFs were uploaded for each invoice';
COMMENT ON TABLE api_keys IS 'Encrypted API keys for external services';
COMMENT ON TABLE settings IS 'Application settings and configuration';

COMMENT ON VIEW invoice_summary IS 'Summary view of invoices with client details and line item counts';
COMMENT ON VIEW client_invoice_history IS 'Aggregate statistics for each client';
