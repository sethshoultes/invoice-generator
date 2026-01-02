"""
Pydantic schemas for request/response validation
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date


# ============================================
# Client Schemas
# ============================================

class ClientBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    company: Optional[str] = Field(None, max_length=255)
    email: Optional[str] = Field(None, max_length=255)
    phone: Optional[str] = Field(None, max_length=50)
    address_line1: Optional[str] = Field(None, max_length=255)
    address_line2: Optional[str] = Field(None, max_length=255)
    city: Optional[str] = Field(None, max_length=100)
    state: Optional[str] = Field(None, max_length=50)
    zip: Optional[str] = Field(None, max_length=20)
    country: Optional[str] = Field("USA", max_length=100)
    notes: Optional[str] = None


class ClientCreate(ClientBase):
    pass


class ClientUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    company: Optional[str] = Field(None, max_length=255)
    email: Optional[str] = Field(None, max_length=255)
    phone: Optional[str] = Field(None, max_length=50)
    address_line1: Optional[str] = Field(None, max_length=255)
    address_line2: Optional[str] = Field(None, max_length=255)
    city: Optional[str] = Field(None, max_length=100)
    state: Optional[str] = Field(None, max_length=50)
    zip: Optional[str] = Field(None, max_length=20)
    country: Optional[str] = Field(None, max_length=100)
    notes: Optional[str] = None


class Client(ClientBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================
# Line Item Schemas
# ============================================

class LineItemBase(BaseModel):
    item_date: date
    description: str = Field(..., min_length=1, max_length=500)
    qty: int = Field(1, ge=1)
    unit_price: float = Field(..., ge=0)
    total_price: float = Field(..., ge=0)
    note: Optional[str] = None
    note_in_pdf: bool = False
    original_extraction: Optional[str] = Field(None, max_length=500)
    line_order: int = Field(0, ge=0)


class LineItemCreate(LineItemBase):
    invoice_id: int


class LineItemUpdate(BaseModel):
    item_date: Optional[date] = None
    description: Optional[str] = Field(None, min_length=1, max_length=500)
    qty: Optional[int] = Field(None, ge=1)
    unit_price: Optional[float] = Field(None, ge=0)
    total_price: Optional[float] = Field(None, ge=0)
    note: Optional[str] = None
    note_in_pdf: Optional[bool] = None
    original_extraction: Optional[str] = Field(None, max_length=500)
    line_order: Optional[int] = Field(None, ge=0)


class LineItem(LineItemBase):
    id: int
    invoice_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================
# Invoice Schemas
# ============================================

class InvoiceBase(BaseModel):
    invoice_number: str = Field(..., min_length=1, max_length=50)
    client_id: int
    invoice_for: Optional[str] = Field(None, max_length=255)
    project: Optional[str] = Field(None, max_length=255)
    submitted_date: date
    due_date: Optional[date] = None
    subtotal: float = Field(0.0, ge=0)
    adjustments: float = Field(0.0)
    total: float = Field(0.0, ge=0)
    payment_status: str = Field("unpaid", pattern="^(unpaid|paid|partial)$")
    payment_date: Optional[date] = None
    payment_method: Optional[str] = Field(None, max_length=50)
    payment_notes: Optional[str] = None


class InvoiceCreate(InvoiceBase):
    line_items: Optional[List[LineItemBase]] = []


class InvoiceUpdate(BaseModel):
    invoice_number: Optional[str] = Field(None, min_length=1, max_length=50)
    client_id: Optional[int] = None
    invoice_for: Optional[str] = Field(None, max_length=255)
    project: Optional[str] = Field(None, max_length=255)
    submitted_date: Optional[date] = None
    due_date: Optional[date] = None
    subtotal: Optional[float] = Field(None, ge=0)
    adjustments: Optional[float] = None
    total: Optional[float] = Field(None, ge=0)
    payment_status: Optional[str] = Field(None, pattern="^(unpaid|paid|partial)$")
    payment_date: Optional[date] = None
    payment_method: Optional[str] = Field(None, max_length=50)
    payment_notes: Optional[str] = None


class Invoice(InvoiceBase):
    id: int
    created_at: datetime
    updated_at: datetime
    pdf_generated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class InvoiceWithLineItems(Invoice):
    line_items: List[LineItem] = []


# ============================================
# Recurring Item Schemas
# ============================================

class RecurringItemBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: str = Field(..., min_length=1, max_length=500)
    default_qty: int = Field(1, ge=1)
    default_price: float = Field(..., ge=0)
    category: Optional[str] = Field(None, max_length=100)


class RecurringItemCreate(RecurringItemBase):
    pass


class RecurringItemUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, min_length=1, max_length=500)
    default_qty: Optional[int] = Field(None, ge=1)
    default_price: Optional[float] = Field(None, ge=0)
    category: Optional[str] = Field(None, max_length=100)


class RecurringItem(RecurringItemBase):
    id: int
    use_count: int = 0
    last_used_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================
# Response Schemas
# ============================================

class HealthCheck(BaseModel):
    status: str
    timestamp: datetime
    version: str = "1.0.0"


class SuccessResponse(BaseModel):
    message: str
    data: Optional[dict] = None


class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
