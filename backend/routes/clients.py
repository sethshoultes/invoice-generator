"""
Client CRUD endpoints
"""
from fastapi import APIRouter, HTTPException, status
from typing import List
from datetime import datetime

from database import get_supabase
from schemas import Client, ClientCreate, ClientUpdate, SuccessResponse

router = APIRouter(prefix="/api/clients", tags=["clients"])


@router.get("", response_model=List[Client])
async def list_clients():
    """
    Get all clients ordered by name
    """
    try:
        supabase = get_supabase()
        response = supabase.table("clients").select("*").order("name").execute()
        return response.data
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch clients: {str(e)}"
        )


@router.get("/{client_id}", response_model=Client)
async def get_client(client_id: int):
    """
    Get a specific client by ID
    """
    try:
        supabase = get_supabase()
        response = supabase.table("clients").select("*").eq("id", client_id).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Client with ID {client_id} not found"
            )

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch client: {str(e)}"
        )


@router.post("", response_model=Client, status_code=status.HTTP_201_CREATED)
async def create_client(client: ClientCreate):
    """
    Create a new client
    """
    try:
        supabase = get_supabase()

        # Convert Pydantic model to dict
        client_data = client.model_dump()

        # Insert client
        response = supabase.table("clients").insert(client_data).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create client"
            )

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        # Check for unique constraint violation
        if "duplicate" in str(e).lower() or "unique" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Client with this name and company already exists"
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create client: {str(e)}"
        )


@router.put("/{client_id}", response_model=Client)
async def update_client(client_id: int, client: ClientUpdate):
    """
    Update an existing client
    """
    try:
        supabase = get_supabase()

        # Check if client exists
        check = supabase.table("clients").select("id").eq("id", client_id).execute()
        if not check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Client with ID {client_id} not found"
            )

        # Convert Pydantic model to dict, excluding None values
        update_data = client.model_dump(exclude_none=True)

        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )

        # Add updated_at timestamp
        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Update client
        response = supabase.table("clients").update(update_data).eq("id", client_id).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update client"
            )

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update client: {str(e)}"
        )


@router.delete("/{client_id}", response_model=SuccessResponse)
async def delete_client(client_id: int):
    """
    Delete a client (only if no invoices exist)
    """
    try:
        supabase = get_supabase()

        # Check if client exists
        check = supabase.table("clients").select("id").eq("id", client_id).execute()
        if not check.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Client with ID {client_id} not found"
            )

        # Check for existing invoices
        invoices = supabase.table("invoices").select("id").eq("client_id", client_id).execute()
        if invoices.data:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Cannot delete client with {len(invoices.data)} existing invoice(s)"
            )

        # Delete client
        supabase.table("clients").delete().eq("id", client_id).execute()

        return SuccessResponse(
            message=f"Client {client_id} deleted successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete client: {str(e)}"
        )
