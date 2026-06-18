-- Invoice Generator Database Schema (Supabase Cloud)
-- Run this in the Supabase Dashboard SQL Editor.
-- This version omits sample data and GRANT statements
-- (Supabase Cloud manages permissions automatically).

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Core Tables
-- ============================================

-- Clients
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT unique_client UNIQUE(name, company)
);

-- Invoices
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE RESTRICT,

    -- Invoice details
    invoice_for VARCHAR(255),
    project VARCHAR(255),
    submitted_date DATE NOT NULL,
    due_date DATE,

    -- Totals
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    adjustments DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,

    -- Payment tracking
    payment_status VARCHAR(20) DEFAULT 'unpaid',
    payment_date DATE,
    payment_method VARCHAR(50),
    payment_notes TEXT,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    pdf_generated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_invoices_client_id ON public.invoices(client_id);
CREATE INDEX idx_invoices_payment_status ON public.invoices(payment_status);
CREATE INDEX idx_invoices_submitted_date ON public.invoices(submitted_date);

-- Line Items
CREATE TABLE IF NOT EXISTS public.line_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,

    -- Item details
    item_date DATE NOT NULL,
    description VARCHAR(500) NOT NULL,
    qty INTEGER DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,

    -- Notes
    note TEXT,
    note_in_pdf BOOLEAN DEFAULT FALSE,
    original_extraction VARCHAR(500),

    -- Ordering
    line_order INTEGER DEFAULT 0,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_line_items_invoice_id ON public.line_items(invoice_id);

-- Recurring Items Library
CREATE TABLE IF NOT EXISTS public.recurring_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(500) NOT NULL,
    default_qty INTEGER DEFAULT 1,
    default_price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),

    -- Usage tracking
    use_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Source Statements (track which PDFs were uploaded)
CREATE TABLE IF NOT EXISTS public.source_statements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    file_size INTEGER,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_source_statements_invoice_id ON public.source_statements(invoice_id);

-- App Settings
CREATE TABLE IF NOT EXISTS public.settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT,
    data_type VARCHAR(20) DEFAULT 'string',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- Views for Common Queries
-- ============================================

-- Invoice Summary View
CREATE OR REPLACE VIEW public.invoice_summary AS
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
FROM public.invoices i
JOIN public.clients c ON i.client_id = c.id
LEFT JOIN public.line_items li ON i.id = li.invoice_id
GROUP BY i.id, c.id
ORDER BY i.submitted_date DESC;

-- Client Invoice History
CREATE OR REPLACE VIEW public.client_invoice_history AS
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
FROM public.clients c
LEFT JOIN public.invoices i ON c.id = i.client_id
GROUP BY c.id;

-- ============================================
-- Functions for Automatic Updates
-- ============================================

-- Update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for automatic timestamp updates
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON public.clients
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_line_items_updated_at BEFORE UPDATE ON public.line_items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_recurring_items_updated_at BEFORE UPDATE ON public.recurring_items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Update invoice totals when line items change
CREATE OR REPLACE FUNCTION public.update_invoice_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.invoices
    SET
        subtotal = (
            SELECT COALESCE(SUM(total_price), 0)
            FROM public.line_items
            WHERE invoice_id = COALESCE(NEW.invoice_id, OLD.invoice_id)
        ),
        total = (
            SELECT COALESCE(SUM(total_price), 0)
            FROM public.line_items
            WHERE invoice_id = COALESCE(NEW.invoice_id, OLD.invoice_id)
        ) + COALESCE(adjustments, 0),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_invoice_totals_on_insert AFTER INSERT ON public.line_items
    FOR EACH ROW EXECUTE FUNCTION public.update_invoice_totals();

CREATE TRIGGER update_invoice_totals_on_update AFTER UPDATE ON public.line_items
    FOR EACH ROW EXECUTE FUNCTION public.update_invoice_totals();

CREATE TRIGGER update_invoice_totals_on_delete AFTER DELETE ON public.line_items
    FOR EACH ROW EXECUTE FUNCTION public.update_invoice_totals();

-- ============================================
-- Row Level Security (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recurring_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.source_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- Allow all operations via anon key (no auth required)
-- The Vercel URL is treated as private/unlisted
CREATE POLICY "Allow all operations" ON public.clients
    FOR ALL USING (true);

CREATE POLICY "Allow all operations" ON public.invoices
    FOR ALL USING (true);

CREATE POLICY "Allow all operations" ON public.line_items
    FOR ALL USING (true);

CREATE POLICY "Allow all operations" ON public.recurring_items
    FOR ALL USING (true);

CREATE POLICY "Allow all operations" ON public.source_statements
    FOR ALL USING (true);

CREATE POLICY "Allow all operations" ON public.settings
    FOR ALL USING (true);
