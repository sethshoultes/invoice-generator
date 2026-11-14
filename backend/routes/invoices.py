"""
Invoice CRUD endpoints
"""
from fastapi import APIRouter, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime

from database import get_supabase
from schemas import (
    Invoice,
    InvoiceCreate,
    InvoiceUpdate,
    InvoiceWithLineItems,
    LineItem,
    LineItemCreate,
    SuccessResponse
)

router = APIRouter(prefix="/api/invoices", tags=["invoices"])


@router.get("", response_model=List[Invoice])
async def list_invoices(
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by payment status")
):
    """
    Get all invoices with optional status filter
    Query params:
    - status: Filter by payment status (unpaid, paid, partial)
    """
    try:
        supabase = get_supabase()

        query = supabase.table("invoices").select("*").order("submitted_date", desc=True)

        if status_filter:
            query = query.eq("payment_status", status_filter)

        response = query.execute()
        return response.data
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch invoices: {str(e)}"
        )


@router.get("/{invoice_id}", response_model=InvoiceWithLineItems)
async def get_invoice(invoice_id: int):
    """
    Get a specific invoice by ID with all line items
    """
    try:
        supabase = get_supabase()

        # Get invoice
        invoice_response = supabase.table("invoices").select("*").eq("id", invoice_id).execute()

        if not invoice_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Invoice with ID {invoice_id} not found"
            )

        invoice = invoice_response.data[0]

        # Get line items
        line_items_response = supabase.table("line_items").select("*").eq("invoice_id", invoice_id).order("line_order").execute()

        invoice["line_items"] = line_items_response.data if line_items_response.data else []

        return invoice
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch invoice: {str(e)}"
        )


@router.post("", response_model=InvoiceWithLineItems, status_code=status.HTTP_201_CREATED)
async def create_invoice(invoice: InvoiceCreate):
    """
    Create a new invoice with line items
    """
    try:
        supabase = get_supabase()

        # Verify client exists
        client_check = supabase.table("clients").select("id").eq("id", invoice.client_id).execute()
        if not client_check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Client with ID {invoice.client_id} not found"
            )

        # Check for duplicate invoice number
        invoice_check = supabase.table("invoices").select("id").eq("invoice_number", invoice.invoice_number).execute()
        if invoice_check.data:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Invoice number {invoice.invoice_number} already exists"
            )

        # Extract line items
        line_items = invoice.line_items
        invoice_data = invoice.model_dump(exclude={"line_items"})

        # Create invoice
        invoice_response = supabase.table("invoices").insert(invoice_data).execute()

        if not invoice_response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create invoice"
            )

        created_invoice = invoice_response.data[0]
        invoice_id = created_invoice["id"]

        # Create line items if provided
        created_line_items = []
        if line_items:
            line_items_data = [
                {**item.model_dump(), "invoice_id": invoice_id}
                for item in line_items
            ]
            line_items_response = supabase.table("line_items").insert(line_items_data).execute()

            if line_items_response.data:
                created_line_items = line_items_response.data

                # Recalculate totals (triggers should handle this, but we'll do it manually)
                subtotal = sum(item["total_price"] for item in created_line_items)
                total = subtotal + created_invoice.get("adjustments", 0)

                update_response = supabase.table("invoices").update({
                    "subtotal": subtotal,
                    "total": total
                }).eq("id", invoice_id).execute()

                if update_response.data:
                    created_invoice = update_response.data[0]

        created_invoice["line_items"] = created_line_items
        return created_invoice

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create invoice: {str(e)}"
        )


@router.put("/{invoice_id}", response_model=Invoice)
async def update_invoice(invoice_id: int, invoice: InvoiceUpdate):
    """
    Update an existing invoice (does not update line items)
    """
    try:
        supabase = get_supabase()

        # Check if invoice exists
        check = supabase.table("invoices").select("id").eq("id", invoice_id).execute()
        if not check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Invoice with ID {invoice_id} not found"
            )

        # Convert Pydantic model to dict, excluding None values
        update_data = invoice.model_dump(exclude_none=True)

        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )

        # Verify client exists if client_id is being updated
        if "client_id" in update_data:
            client_check = supabase.table("clients").select("id").eq("id", update_data["client_id"]).execute()
            if not client_check.data:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Client with ID {update_data['client_id']} not found"
                )

        # Check for duplicate invoice number if being updated
        if "invoice_number" in update_data:
            invoice_check = supabase.table("invoices").select("id").eq("invoice_number", update_data["invoice_number"]).execute()
            if invoice_check.data and invoice_check.data[0]["id"] != invoice_id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Invoice number {update_data['invoice_number']} already exists"
                )

        # Add updated_at timestamp
        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Update invoice
        response = supabase.table("invoices").update(update_data).eq("id", invoice_id).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update invoice"
            )

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update invoice: {str(e)}"
        )


@router.delete("/{invoice_id}", response_model=SuccessResponse)
async def delete_invoice(invoice_id: int):
    """
    Delete an invoice and all associated line items (cascade)
    """
    try:
        supabase = get_supabase()

        # Check if invoice exists
        check = supabase.table("invoices").select("id").eq("id", invoice_id).execute()
        if not check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Invoice with ID {invoice_id} not found"
            )

        # Delete line items first (if cascade is not set up)
        supabase.table("line_items").delete().eq("invoice_id", invoice_id).execute()

        # Delete invoice
        supabase.table("invoices").delete().eq("id", invoice_id).execute()

        return SuccessResponse(
            message=f"Invoice {invoice_id} deleted successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete invoice: {str(e)}"
        )


# ============================================
# Line Items endpoints
# ============================================

@router.post("/{invoice_id}/line-items", response_model=LineItem, status_code=status.HTTP_201_CREATED)
async def add_line_item(invoice_id: int, line_item: LineItemCreate):
    """
    Add a line item to an invoice
    """
    try:
        supabase = get_supabase()

        # Check if invoice exists
        check = supabase.table("invoices").select("id").eq("id", invoice_id).execute()
        if not check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Invoice with ID {invoice_id} not found"
            )

        # Override invoice_id from URL
        line_item_data = line_item.model_dump()
        line_item_data["invoice_id"] = invoice_id

        # Create line item
        response = supabase.table("line_items").insert(line_item_data).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create line item"
            )

        # Recalculate invoice totals
        line_items = supabase.table("line_items").select("total_price").eq("invoice_id", invoice_id).execute()
        subtotal = sum(item["total_price"] for item in line_items.data)

        invoice = supabase.table("invoices").select("adjustments").eq("id", invoice_id).execute()
        adjustments = invoice.data[0].get("adjustments", 0) if invoice.data else 0

        supabase.table("invoices").update({
            "subtotal": subtotal,
            "total": subtotal + adjustments,
            "updated_at": datetime.utcnow().isoformat()
        }).eq("id", invoice_id).execute()

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add line item: {str(e)}"
        )


@router.delete("/{invoice_id}/line-items/{line_item_id}", response_model=SuccessResponse)
async def delete_line_item(invoice_id: int, line_item_id: int):
    """
    Delete a line item from an invoice
    """
    try:
        supabase = get_supabase()

        # Check if line item exists and belongs to the invoice
        check = supabase.table("line_items").select("id").eq("id", line_item_id).eq("invoice_id", invoice_id).execute()
        if not check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Line item {line_item_id} not found for invoice {invoice_id}"
            )

        # Delete line item
        supabase.table("line_items").delete().eq("id", line_item_id).execute()

        # Recalculate invoice totals
        line_items = supabase.table("line_items").select("total_price").eq("invoice_id", invoice_id).execute()
        subtotal = sum(item["total_price"] for item in line_items.data) if line_items.data else 0

        invoice = supabase.table("invoices").select("adjustments").eq("id", invoice_id).execute()
        adjustments = invoice.data[0].get("adjustments", 0) if invoice.data else 0

        supabase.table("invoices").update({
            "subtotal": subtotal,
            "total": subtotal + adjustments,
            "updated_at": datetime.utcnow().isoformat()
        }).eq("id", invoice_id).execute()

        return SuccessResponse(
            message=f"Line item {line_item_id} deleted successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete line item: {str(e)}"
        )
