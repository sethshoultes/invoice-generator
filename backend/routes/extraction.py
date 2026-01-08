"""
Invoice extraction routes using Claude API
"""
from fastapi import APIRouter, UploadFile, File, HTTPException
from anthropic import Anthropic
import base64
import os
from typing import List, Dict, Any

router = APIRouter()

# Initialize Anthropic client
anthropic_api_key = os.getenv('ANTHROPIC_API_KEY')
if not anthropic_api_key or anthropic_api_key == 'your-anthropic-api-key-here':
    raise ValueError("ANTHROPIC_API_KEY not configured in .env file")

client = Anthropic(api_key=anthropic_api_key)


@router.post('/api/extract-invoice-items')
async def extract_invoice_items(file: UploadFile = File(...)):
    """
    Extract line items from a bank statement or invoice image using Claude Vision API

    Args:
        file: Image file (PNG, JPG, JPEG, WEBP, GIF) or PDF

    Returns:
        JSON with extracted line items in format:
        {
            "line_items": [
                {"date": "12/19/2024", "description": "Web hosting", "amount": 29.99},
                ...
            ]
        }
    """
    try:
        # Read file content
        content = await file.read()

        # Determine media type
        media_type_map = {
            'png': 'image/png',
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'webp': 'image/webp',
            'gif': 'image/gif'
        }

        file_ext = file.filename.split('.')[-1].lower() if file.filename else 'png'
        media_type = media_type_map.get(file_ext, 'image/png')

        # Encode to base64
        base64_content = base64.standard_b64encode(content).decode('utf-8')

        # Call Claude API
        message = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=4096,
            tools=[{
                "name": "record_invoice_items",
                "description": "Record extracted line items from the statement",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "line_items": {
                            "type": "array",
                            "description": "List of line items extracted from the statement",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "date": {
                                        "type": "string",
                                        "description": "Transaction date (format: MM/DD/YYYY or MM/DD/YY)"
                                    },
                                    "description": {
                                        "type": "string",
                                        "description": "Description of the service or item"
                                    },
                                    "amount": {
                                        "type": "number",
                                        "description": "Transaction amount in dollars"
                                    }
                                },
                                "required": ["date", "description", "amount"]
                            }
                        }
                    },
                    "required": ["line_items"]
                }
            }],
            tool_choice={"type": "tool", "name": "record_invoice_items"},
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": media_type,
                            "data": base64_content
                        }
                    },
                    {
                        "type": "text",
                        "text": """Extract all line items from this bank statement or payment statement.

For each transaction, extract:
- Date (in MM/DD/YYYY or MM/DD/YY format)
- Description (the service or item purchased)
- Amount (in dollars, as a positive number)

Skip:
- Headers, footers, account summaries
- Balance information
- Fees or charges not related to services rendered
- Duplicate entries

Focus on billable services and transactions that would appear on an invoice."""
                    }
                ]
            }]
        )

        # Extract the tool use response
        for block in message.content:
            if block.type == "tool_use" and block.name == "record_invoice_items":
                return block.input

        # If no tool use found, return empty result
        return {"line_items": []}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error extracting invoice items: {str(e)}")
