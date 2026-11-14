# Bank Statement → Invoice Automation

## Overview

Automatically extract line items from bank/payment processor statements and populate invoice fields using Claude's vision API with structured outputs.

## User Flow

1. User uploads bank statement (PDF or screenshot)
2. System sends image to Claude API
3. Claude extracts charges as structured data
4. Data populates invoice template
5. User reviews and sends invoice

---

## Data Schema

Based on a typical monthly services invoice:

```typescript
interface InvoiceData {
  // Extracted from statement
  lineItems: Array<{
    date: string;           // "2025-11-15"
    description: string;    // "Stripe processing fee"
    amount: number;         // 45.67
    category?: string;      // "Payment Processing", "Software", etc.
  }>;
  
  // Calculated
  subtotal: number;
  
  // May need manual entry or pulled from statement
  statementPeriod: {
    start: string;          // "2025-11-01"
    end: string;            // "2025-11-30"
  };
  
  // Optional: if visible on statement
  accountReference?: string;
}
```

---

## Claude API Implementation

### Using Tool Use (Structured Outputs)

```python
import anthropic
import base64

client = anthropic.Anthropic()

def extract_invoice_data(image_path: str) -> dict:
    """
    Extract invoice line items from a bank statement image or PDF.
    """
    
    # Read and encode the image
    with open(image_path, "rb") as f:
        image_data = base64.standard_b64encode(f.read()).decode("utf-8")
    
    # Determine media type
    if image_path.endswith(".pdf"):
        media_type = "application/pdf"
    elif image_path.endswith(".png"):
        media_type = "image/png"
    else:
        media_type = "image/jpeg"
    
    # Define the extraction tool (this enforces structured output)
    extraction_tool = {
        "name": "record_invoice_items",
        "description": "Record extracted line items from a bank or payment statement for invoice generation",
        "input_schema": {
            "type": "object",
            "properties": {
                "statement_period": {
                    "type": "object",
                    "properties": {
                        "start_date": {
                            "type": "string",
                            "description": "Start date of statement period (YYYY-MM-DD)"
                        },
                        "end_date": {
                            "type": "string",
                            "description": "End date of statement period (YYYY-MM-DD)"
                        }
                    },
                    "required": ["start_date", "end_date"]
                },
                "line_items": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "date": {
                                "type": "string",
                                "description": "Transaction date (YYYY-MM-DD)"
                            },
                            "description": {
                                "type": "string",
                                "description": "Description of the charge or service"
                            },
                            "amount": {
                                "type": "number",
                                "description": "Charge amount as a positive number"
                            },
                            "category": {
                                "type": "string",
                                "enum": [
                                    "Payment Processing",
                                    "Software/SaaS",
                                    "Hosting/Infrastructure",
                                    "Marketing",
                                    "Professional Services",
                                    "Other"
                                ],
                                "description": "Category of the expense"
                            }
                        },
                        "required": ["date", "description", "amount"]
                    }
                },
                "subtotal": {
                    "type": "number",
                    "description": "Sum of all line item amounts"
                },
                "notes": {
                    "type": "string",
                    "description": "Any relevant notes or observations about the statement"
                }
            },
            "required": ["line_items", "subtotal"]
        }
    }
    
    # Make the API call
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        tools=[extraction_tool],
        tool_choice={"type": "tool", "name": "record_invoice_items"},
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": media_type,
                            "data": image_data
                        }
                    },
                    {
                        "type": "text",
                        "text": """Extract all charges/fees from this bank or payment processor statement.

For each charge, capture:
- The date of the transaction
- A clear description of what the charge is for
- The amount (as a positive number)
- A category if you can determine it

Also identify the statement period if visible.

Extract ALL line items you can see - don't summarize or skip any charges."""
                    }
                ]
            }
        ]
    )
    
    # Extract the structured data from the tool call
    for block in response.content:
        if block.type == "tool_use":
            return block.input
    
    raise ValueError("No structured data returned")


# Example usage
if __name__ == "__main__":
    result = extract_invoice_data("november_statement.png")
    
    print(f"Statement Period: {result.get('statement_period', 'Not detected')}")
    print(f"Subtotal: ${result['subtotal']:.2f}")
    print(f"\nLine Items:")
    for item in result['line_items']:
        print(f"  {item['date']} | {item['description'][:40]:<40} | ${item['amount']:>8.2f}")
```

---

## Handling Different Statement Formats

Different banks/processors have different layouts. Here's how to handle common sources:

### Stripe
- Usually shows: Date, Description, Amount, Fee, Net
- Extract the "Fee" column for processing charges
- May need to filter out payouts vs charges

### PayPal
- Shows: Date, Name, Type, Amount
- Filter for "Fee" type transactions

### Bank Statements
- More varied formats
- Look for "Service Charge", "Monthly Fee", etc.

### Prompt Adjustments by Source

```python
PROMPTS_BY_SOURCE = {
    "stripe": """Extract all Stripe fees from this statement.
Focus on the 'Fee' column - these are the processing charges.
Ignore payout rows - only capture fee/charge rows.""",
    
    "paypal": """Extract all PayPal fees from this statement.
Look for rows where Type is 'Fee' or similar.
Capture the fee amount for each transaction.""",
    
    "bank": """Extract all bank charges and fees from this statement.
Look for: monthly fees, service charges, wire fees, etc.
Ignore regular deposits and withdrawals - only capture bank-charged fees.""",
    
    "generic": """Extract all charges/fees from this statement.
Capture every line item that represents a cost or fee.
Include the date, description, and amount for each."""
}
```

---

## Building the Full System

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Frontend (React)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Upload Zone │  │ Preview &   │  │ Invoice Template    │  │
│  │ (drag/drop) │→ │ Extraction  │→ │ (editable fields)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      Backend API                             │
│  POST /api/extract-statement                                 │
│  - Receives image/PDF                                        │
│  - Calls Claude API                                          │
│  - Returns structured invoice data                           │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      Claude API                              │
│  - Vision: reads the statement image                         │
│  - Tool Use: returns structured JSON                         │
└─────────────────────────────────────────────────────────────┘
```

### Backend Endpoint (FastAPI Example)

```python
from fastapi import FastAPI, UploadFile, HTTPException
from pydantic import BaseModel
import anthropic
import base64

app = FastAPI()
client = anthropic.Anthropic()

class LineItem(BaseModel):
    date: str
    description: str
    amount: float
    category: str | None = None

class ExtractionResult(BaseModel):
    line_items: list[LineItem]
    subtotal: float
    statement_period: dict | None = None
    notes: str | None = None

@app.post("/api/extract-statement", response_model=ExtractionResult)
async def extract_statement(
    file: UploadFile,
    source_type: str = "generic"  # stripe, paypal, bank, generic
):
    # Validate file type
    allowed_types = ["image/png", "image/jpeg", "application/pdf"]
    if file.content_type not in allowed_types:
        raise HTTPException(400, "File must be PNG, JPEG, or PDF")
    
    # Read and encode
    contents = await file.read()
    image_data = base64.standard_b64encode(contents).decode("utf-8")
    
    # Get source-specific prompt
    prompt = PROMPTS_BY_SOURCE.get(source_type, PROMPTS_BY_SOURCE["generic"])
    
    # Call Claude (using the extraction function from above)
    result = call_claude_extraction(image_data, file.content_type, prompt)
    
    return ExtractionResult(**result)
```

### Frontend Component (React)

```jsx
import React, { useState, useCallback } from 'react';
import { Upload, FileText, Check, AlertCircle, Loader2 } from 'lucide-react';

export default function StatementExtractor({ onExtracted }) {
  const [status, setStatus] = useState('idle'); // idle, uploading, processing, done, error
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const handleDrop = useCallback(async (e) => {
    e.preventDefault();
    const file = e.dataTransfer?.files[0] || e.target.files[0];
    if (!file) return;

    setStatus('uploading');
    setError(null);

    const formData = new FormData();
    formData.append('file', file);
    formData.append('source_type', 'generic'); // or detect from filename

    try {
      setStatus('processing');
      
      const response = await fetch('/api/extract-statement', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Extraction failed');
      }

      const data = await response.json();
      setResult(data);
      setStatus('done');
      onExtracted?.(data);
      
    } catch (err) {
      setError(err.message);
      setStatus('error');
    }
  }, [onExtracted]);

  return (
    <div className="space-y-4">
      {/* Upload Zone */}
      <div
        onDrop={handleDrop}
        onDragOver={(e) => e.preventDefault()}
        className={`
          border-2 border-dashed rounded-xl p-8 text-center transition-colors
          ${status === 'idle' ? 'border-slate-300 hover:border-violet-400' : ''}
          ${status === 'processing' ? 'border-violet-400 bg-violet-50' : ''}
          ${status === 'done' ? 'border-emerald-400 bg-emerald-50' : ''}
          ${status === 'error' ? 'border-red-400 bg-red-50' : ''}
        `}
      >
        <input
          type="file"
          accept="image/*,.pdf"
          onChange={handleDrop}
          className="hidden"
          id="statement-upload"
        />
        
        <label htmlFor="statement-upload" className="cursor-pointer">
          {status === 'idle' && (
            <>
              <Upload className="w-10 h-10 mx-auto text-slate-400 mb-3" />
              <p className="text-slate-600 font-medium">Drop statement here</p>
              <p className="text-sm text-slate-400 mt-1">PNG, JPEG, or PDF</p>
            </>
          )}
          
          {status === 'processing' && (
            <>
              <Loader2 className="w-10 h-10 mx-auto text-violet-500 mb-3 animate-spin" />
              <p className="text-violet-700 font-medium">Extracting charges...</p>
              <p className="text-sm text-violet-500 mt-1">Claude is reading your statement</p>
            </>
          )}
          
          {status === 'done' && (
            <>
              <Check className="w-10 h-10 mx-auto text-emerald-500 mb-3" />
              <p className="text-emerald-700 font-medium">
                Extracted {result.line_items.length} items
              </p>
              <p className="text-sm text-emerald-500 mt-1">
                Total: ${result.subtotal.toFixed(2)}
              </p>
            </>
          )}
          
          {status === 'error' && (
            <>
              <AlertCircle className="w-10 h-10 mx-auto text-red-500 mb-3" />
              <p className="text-red-700 font-medium">Extraction failed</p>
              <p className="text-sm text-red-500 mt-1">{error}</p>
            </>
          )}
        </label>
      </div>

      {/* Results Preview */}
      {result && (
        <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
          <div className="px-4 py-3 bg-slate-50 border-b border-slate-200">
            <h3 className="font-medium text-slate-800">Extracted Line Items</h3>
          </div>
          <div className="divide-y divide-slate-100">
            {result.line_items.map((item, idx) => (
              <div key={idx} className="px-4 py-3 flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-slate-800">{item.description}</p>
                  <p className="text-xs text-slate-500">{item.date}</p>
                </div>
                <span className="text-sm font-medium text-slate-700">
                  ${item.amount.toFixed(2)}
                </span>
              </div>
            ))}
          </div>
          <div className="px-4 py-3 bg-slate-50 border-t border-slate-200 flex justify-between">
            <span className="font-medium text-slate-600">Subtotal</span>
            <span className="font-semibold text-slate-800">${result.subtotal.toFixed(2)}</span>
          </div>
        </div>
      )}
    </div>
  );
}
```

---

## Cost Estimation

Claude API pricing for this use case:

| Component | Cost |
|-----------|------|
| Input (image) | ~$0.01-0.03 per statement (depends on size) |
| Input (prompt) | ~$0.001 |
| Output (structured data) | ~$0.005-0.01 |
| **Total per extraction** | **~$0.02-0.05** |

For monthly invoicing (1-2 statements/month), this is essentially free.

---

## Edge Cases to Handle

1. **Multi-page PDFs**: Claude can handle these, but may need to specify "extract from all pages"

2. **Poor image quality**: Add validation and prompt user to retake if confidence is low

3. **Ambiguous charges**: The `notes` field can capture uncertainty ("Description unclear - verify manually")

4. **Currency symbols**: Prompt should specify expected currency, or extract it

5. **Credits/refunds**: May appear as negative amounts - decide how to handle in invoice

---

## Next Steps

1. **Prototype**: Start with the Python script to test extraction accuracy on your actual statements

2. **Refine prompt**: Adjust based on your specific statement formats

3. **Build UI**: Create the upload → preview → invoice flow

4. **Invoice template**: Integrate with your existing invoice format (Word doc? PDF generator? Web form?)

5. **Validation step**: Always show extracted data for human review before finalizing invoice

---

## Questions to Consider

- What format do you currently use for invoices? (This affects how we populate the template)
- Do you need to store historical extractions?
- Should line items be editable after extraction?
- Do you want to auto-detect the statement source (Stripe vs PayPal vs bank)?
