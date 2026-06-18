import crypto from 'crypto';

// Serverless proxy for Claude extraction. The Anthropic API key lives only in
// this function's environment (ANTHROPIC_API_KEY) and never reaches the browser.
// Access is gated by a shared passcode (APP_PASSCODE).

const MODEL = 'claude-sonnet-4-6';

const TOOL = {
  name: 'record_invoice_items',
  description: 'Extract line items from a bank or payment statement',
  input_schema: {
    type: 'object',
    properties: {
      line_items: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            date: { type: 'string', description: 'Transaction date (MM/DD/YYYY format)' },
            description: { type: 'string', description: 'Description of the charge' },
            amount: { type: 'number', description: 'Amount as positive number' }
          },
          required: ['date', 'description', 'amount']
        }
      }
    },
    required: ['line_items']
  }
};

const PROMPT = `Extract ALL charges and fees from this bank/payment statement.

For each charge, capture:
- Date (format as MM/DD/YYYY)
- Description (the merchant name or charge description)
- Amount (as a positive number)

Extract every single line item. Don't skip or summarize any charges.`;

// Constant-time string comparison that doesn't leak length via early return.
function passcodeMatches(provided, expected) {
  const a = Buffer.from(String(provided));
  const b = Buffer.from(String(expected));
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  const expectedPasscode = process.env.APP_PASSCODE;
  if (!apiKey || !expectedPasscode) {
    return res.status(500).json({ error: 'Server is not configured (missing ANTHROPIC_API_KEY or APP_PASSCODE).' });
  }

  const { passcode, base64Data, mediaType } = req.body || {};

  if (!passcode || !passcodeMatches(passcode, expectedPasscode)) {
    return res.status(401).json({ error: 'Invalid passcode.' });
  }
  if (!base64Data || !mediaType) {
    return res.status(400).json({ error: 'Missing base64Data or mediaType.' });
  }

  try {
    const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 4096,
        tools: [TOOL],
        tool_choice: { type: 'tool', name: 'record_invoice_items' },
        messages: [{
          role: 'user',
          content: [
            {
              type: mediaType === 'application/pdf' ? 'document' : 'image',
              source: { type: 'base64', media_type: mediaType, data: base64Data }
            },
            { type: 'text', text: PROMPT }
          ]
        }]
      })
    });

    const data = await anthropicRes.json();

    if (!anthropicRes.ok || data.error) {
      const message = data.error?.message || `Anthropic API error (${anthropicRes.status})`;
      return res.status(502).json({ error: message });
    }

    const toolUse = data.content?.find((block) => block.type === 'tool_use');
    if (!toolUse?.input?.line_items) {
      return res.status(422).json({ error: 'No line items extracted.' });
    }

    return res.status(200).json({ line_items: toolUse.input.line_items });
  } catch (err) {
    return res.status(502).json({ error: err.message || 'Extraction request failed.' });
  }
}
