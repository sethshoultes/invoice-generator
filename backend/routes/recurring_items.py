"""
Recurring Items CRUD endpoints
"""
from fastapi import APIRouter, HTTPException, status
from typing import List
from datetime import datetime

from database import get_supabase
from schemas import RecurringItem, RecurringItemCreate, RecurringItemUpdate, SuccessResponse

router = APIRouter(prefix="/api/recurring-items", tags=["recurring-items"])


@router.get("", response_model=List[RecurringItem])
async def list_recurring_items():
    """
    Get all recurring items ordered by use count (most used first)
    """
    try:
        supabase = get_supabase()
        response = supabase.table("recurring_items").select("*").order("use_count", desc=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch recurring items: {str(e)}"
        )


@router.get("/{item_id}", response_model=RecurringItem)
async def get_recurring_item(item_id: int):
    """
    Get a specific recurring item by ID
    """
    try:
        supabase = get_supabase()
        response = supabase.table("recurring_items").select("*").eq("id", item_id).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Recurring item with ID {item_id} not found"
            )

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch recurring item: {str(e)}"
        )


@router.post("", response_model=RecurringItem, status_code=status.HTTP_201_CREATED)
async def create_recurring_item(item: RecurringItemCreate):
    """
    Create a new recurring item
    """
    try:
        supabase = get_supabase()

        # Convert Pydantic model to dict
        item_data = item.model_dump()

        # Insert recurring item
        response = supabase.table("recurring_items").insert(item_data).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create recurring item"
            )

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        # Check for unique constraint violation
        if "duplicate" in str(e).lower() or "unique" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Recurring item with this name already exists"
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create recurring item: {str(e)}"
        )


@router.put("/{item_id}", response_model=RecurringItem)
async def update_recurring_item(item_id: int, item: RecurringItemUpdate):
    """
    Update an existing recurring item
    """
    try:
        supabase = get_supabase()

        # Check if item exists
        check = supabase.table("recurring_items").select("id").eq("id", item_id).execute()
        if not check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Recurring item with ID {item_id} not found"
            )

        # Convert Pydantic model to dict, excluding None values
        update_data = item.model_dump(exclude_none=True)

        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )

        # Add updated_at timestamp
        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Update item
        response = supabase.table("recurring_items").update(update_data).eq("id", item_id).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update recurring item"
            )

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update recurring item: {str(e)}"
        )


@router.delete("/{item_id}", response_model=SuccessResponse)
async def delete_recurring_item(item_id: int):
    """
    Delete a recurring item
    """
    try:
        supabase = get_supabase()

        # Check if item exists
        check = supabase.table("recurring_items").select("id").eq("id", item_id).execute()
        if not check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Recurring item with ID {item_id} not found"
            )

        # Delete item
        supabase.table("recurring_items").delete().eq("id", item_id).execute()

        return SuccessResponse(
            message=f"Recurring item {item_id} deleted successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete recurring item: {str(e)}"
        )


@router.post("/{item_id}/use", response_model=RecurringItem)
async def increment_usage(item_id: int):
    """
    Increment the use count for a recurring item and update last_used_at
    Call this endpoint when a recurring item is added to an invoice
    """
    try:
        supabase = get_supabase()

        # Check if item exists
        check = supabase.table("recurring_items").select("id, use_count").eq("id", item_id).execute()
        if not check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Recurring item with ID {item_id} not found"
            )

        current_use_count = check.data[0].get("use_count", 0)

        # Update use count and last_used_at
        response = supabase.table("recurring_items").update({
            "use_count": current_use_count + 1,
            "last_used_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        }).eq("id", item_id).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update recurring item usage"
            )

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to increment usage: {str(e)}"
        )
