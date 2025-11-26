import React, { useState, useCallback } from 'react';
import { Upload, Trash2, Plus, Download, Loader2, Check, AlertCircle, FileSpreadsheet, Copy, Edit3 } from 'lucide-react';

export default function InvoiceExtractor() {
  const [status, setStatus] = useState('idle'); // idle, processing, done, error
  const [lineItems, setLineItems] = useState([]);
  const [error, setError] = useState(null);
  const [copied, setCopied] = useState(false);
  const [invoiceMeta, setInvoiceMeta] = useState({
    clientName: '',
    invoiceNumber: '',
    invoiceDate: new Date().toISOString().split('T')[0],
    dueDate: '',
    notes: 'Thank you for your business!'
  });

  const extractFromImage = async (base64Data, mediaType) => {
    setStatus('processing');
    setError(null);

    try {
      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 4096,
          tools: [{
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
                      date: { type: 'string', description: 'Transaction date (YYYY-MM-DD)' },
                      description: { type: 'string', description: 'Description of the charge' },
                      amount: { type: 'number', description: 'Amount as positive number' }
                    },
                    required: ['date', 'description', 'amount']
                  }
                },
                statement_period: {
                  type: 'object',
                  properties: {
                    start: { type: 'string' },
                    end: { type: 'string' }
                  }
                }
              },
              required: ['line_items']
            }
          }],
          tool_choice: { type: 'tool', name: 'record_invoice_items' },
          messages: [{
            role: 'user',
            content: [
              {
                type: mediaType === 'application/pdf' ? 'document' : 'image',
                source: { type: 'base64', media_type: mediaType, data: base64Data }
              },
              {
                type: 'text',
                text: `Extract ALL charges and fees from this statement. For each charge, get:
- Date (format as YYYY-MM-DD)
- Description (clear, concise description of the charge)
- Amount (as a positive number, no currency symbols)

Include every line item you can see. Don't skip or summarize.`
              }
            ]
          }]
        })
      });

      const data = await response.json();
      
      if (data.error) {
        throw new Error(data.error.message || 'API error');
      }

      const toolUse = data.content?.find(block => block.type === 'tool_use');
      if (toolUse?.input?.line_items) {
        setLineItems(toolUse.input.line_items.map((item, idx) => ({
          id: Date.now() + idx,
          ...item
        })));
        setStatus('done');
      } else {
        throw new Error('No line items extracted');
      }
    } catch (err) {
      setError(err.message);
      setStatus('error');
    }
  };

  const handleFileUpload = useCallback((e) => {
    const file = e.target.files?.[0] || e.dataTransfer?.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      const base64 = reader.result.split(',')[1];
      const mediaType = file.type || 'image/png';
      extractFromImage(base64, mediaType);
    };
    reader.readAsDataURL(file);
  }, []);

  const updateLineItem = (id, field, value) => {
    setLineItems(items => items.map(item => 
      item.id === id ? { ...item, [field]: field === 'amount' ? parseFloat(value) || 0 : value } : item
    ));
  };

  const deleteLineItem = (id) => {
    setLineItems(items => items.filter(item => item.id !== id));
  };

  const addLineItem = () => {
    setLineItems(items => [...items, {
      id: Date.now(),
      date: new Date().toISOString().split('T')[0],
      description: '',
      amount: 0
    }]);
  };

  const subtotal = lineItems.reduce((sum, item) => sum + (item.amount || 0), 0);

  const generateCSV = () => {
    const headers = ['Date', 'Description', 'Amount'];
    const rows = lineItems.map(item => [
      item.date,
      `"${item.description.replace(/"/g, '""')}"`,
      item.amount.toFixed(2)
    ]);
    rows.push(['', 'SUBTOTAL', subtotal.toFixed(2)]);
    
    return [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
  };

  const copyToClipboard = async () => {
    const csv = generateCSV();
    await navigator.clipboard.writeText(csv);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const downloadCSV = () => {
    const csv = generateCSV();
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `invoice-items-${invoiceMeta.invoiceDate}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const reset = () => {
    setStatus('idle');
    setLineItems([]);
    setError(null);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 p-6" style={{ fontFamily: "'Inter', system-ui, sans-serif" }}>
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-semibold text-slate-800">Statement → Invoice</h1>
          <p className="text-slate-500 mt-1">Upload a bank statement to extract charges automatically</p>
        </div>

        {/* Upload Zone - Only show when idle or error */}
        {(status === 'idle' || status === 'error') && (
          <div
            onDrop={(e) => { e.preventDefault(); handleFileUpload(e); }}
            onDragOver={(e) => e.preventDefault()}
            className={`
              border-2 border-dashed rounded-2xl p-12 text-center transition-all cursor-pointer
              ${status === 'error' 
                ? 'border-red-300 bg-red-50 hover:border-red-400' 
                : 'border-slate-300 bg-white hover:border-violet-400 hover:bg-violet-50/30'
              }
            `}
          >
            <input
              type="file"
              accept="image/*,.pdf"
              onChange={handleFileUpload}
              className="hidden"
              id="file-upload"
            />
            <label htmlFor="file-upload" className="cursor-pointer">
              {status === 'error' ? (
                <>
                  <AlertCircle className="w-12 h-12 mx-auto text-red-400 mb-4" />
                  <p className="text-red-700 font-medium text-lg">Extraction failed</p>
                  <p className="text-red-500 text-sm mt-2 mb-4">{error}</p>
                  <span className="text-red-600 underline">Try again</span>
                </>
              ) : (
                <>
                  <Upload className="w-12 h-12 mx-auto text-slate-400 mb-4" />
                  <p className="text-slate-700 font-medium text-lg">Drop your statement here</p>
                  <p className="text-slate-400 text-sm mt-2">PNG, JPEG, or PDF</p>
                </>
              )}
            </label>
          </div>
        )}

        {/* Processing State */}
        {status === 'processing' && (
          <div className="bg-white rounded-2xl border border-violet-200 p-12 text-center">
            <Loader2 className="w-12 h-12 mx-auto text-violet-500 mb-4 animate-spin" />
            <p className="text-violet-700 font-medium text-lg">Reading your statement...</p>
            <p className="text-violet-400 text-sm mt-2">This usually takes 5-10 seconds</p>
          </div>
        )}

        {/* Results */}
        {status === 'done' && (
          <div className="space-y-6">
            {/* Success Banner */}
            <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Check className="w-5 h-5 text-emerald-600" />
                <span className="text-emerald-800 font-medium">
                  Extracted {lineItems.length} line items
                </span>
              </div>
              <button
                onClick={reset}
                className="text-sm text-emerald-700 hover:text-emerald-800 underline"
              >
                Upload different statement
              </button>
            </div>

            {/* Editable Line Items */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Edit3 className="w-4 h-4 text-slate-400" />
                  <h2 className="font-semibold text-slate-800">Line Items</h2>
                  <span className="text-xs text-slate-400">(click to edit)</span>
                </div>
                <button
                  onClick={addLineItem}
                  className="flex items-center gap-1.5 text-sm text-violet-600 hover:text-violet-700 font-medium"
                >
                  <Plus className="w-4 h-4" />
                  Add Item
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="bg-slate-50">
                      <th className="text-left text-xs font-medium text-slate-500 uppercase tracking-wider px-5 py-3 w-32">Date</th>
                      <th className="text-left text-xs font-medium text-slate-500 uppercase tracking-wider px-5 py-3">Description</th>
                      <th className="text-right text-xs font-medium text-slate-500 uppercase tracking-wider px-5 py-3 w-32">Amount</th>
                      <th className="w-12"></th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {lineItems.map((item) => (
                      <tr key={item.id} className="group hover:bg-slate-50/50">
                        <td className="px-5 py-2">
                          <input
                            type="date"
                            value={item.date}
                            onChange={(e) => updateLineItem(item.id, 'date', e.target.value)}
                            className="w-full px-2 py-1.5 text-sm border border-transparent hover:border-slate-200 focus:border-violet-400 focus:ring-1 focus:ring-violet-400 rounded-md outline-none transition-colors bg-transparent"
                          />
                        </td>
                        <td className="px-5 py-2">
                          <input
                            type="text"
                            value={item.description}
                            onChange={(e) => updateLineItem(item.id, 'description', e.target.value)}
                            className="w-full px-2 py-1.5 text-sm border border-transparent hover:border-slate-200 focus:border-violet-400 focus:ring-1 focus:ring-violet-400 rounded-md outline-none transition-colors bg-transparent"
                            placeholder="Description..."
                          />
                        </td>
                        <td className="px-5 py-2">
                          <div className="relative">
                            <span className="absolute left-2 top-1/2 -translate-y-1/2 text-slate-400 text-sm">$</span>
                            <input
                              type="number"
                              step="0.01"
                              value={item.amount}
                              onChange={(e) => updateLineItem(item.id, 'amount', e.target.value)}
                              className="w-full pl-6 pr-2 py-1.5 text-sm text-right border border-transparent hover:border-slate-200 focus:border-violet-400 focus:ring-1 focus:ring-violet-400 rounded-md outline-none transition-colors bg-transparent tabular-nums"
                            />
                          </div>
                        </td>
                        <td className="px-2 py-2">
                          <button
                            onClick={() => deleteLineItem(item.id)}
                            className="p-1.5 text-slate-300 hover:text-red-500 hover:bg-red-50 rounded-md opacity-0 group-hover:opacity-100 transition-all"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr className="bg-slate-50 border-t-2 border-slate-200">
                      <td className="px-5 py-3"></td>
                      <td className="px-5 py-3 text-right font-semibold text-slate-700">Subtotal</td>
                      <td className="px-5 py-3 text-right font-semibold text-slate-800 tabular-nums">
                        ${subtotal.toFixed(2)}
                      </td>
                      <td></td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </div>

            {/* Export Actions */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
              <h3 className="font-semibold text-slate-800 mb-4 flex items-center gap-2">
                <FileSpreadsheet className="w-4 h-4 text-slate-400" />
                Export for Google Sheets
              </h3>
              <div className="flex gap-3">
                <button
                  onClick={copyToClipboard}
                  className={`
                    flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-xl font-medium transition-all
                    ${copied 
                      ? 'bg-emerald-100 text-emerald-700 border border-emerald-200' 
                      : 'bg-violet-600 hover:bg-violet-700 text-white'
                    }
                  `}
                >
                  {copied ? (
                    <>
                      <Check className="w-4 h-4" />
                      Copied!
                    </>
                  ) : (
                    <>
                      <Copy className="w-4 h-4" />
                      Copy as CSV
                    </>
                  )}
                </button>
                <button
                  onClick={downloadCSV}
                  className="flex items-center justify-center gap-2 px-4 py-3 rounded-xl font-medium border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors"
                >
                  <Download className="w-4 h-4" />
                  Download CSV
                </button>
              </div>
              <p className="text-xs text-slate-400 mt-3 text-center">
                Copy and paste directly into your Google Sheet, or download as a file
              </p>
            </div>
          </div>
        )}

        {/* Instructions */}
        {status === 'idle' && (
          <div className="mt-8 text-center">
            <h3 className="text-sm font-medium text-slate-500 mb-3">How it works</h3>
            <div className="flex justify-center gap-8 text-sm text-slate-400">
              <div className="flex items-center gap-2">
                <span className="w-6 h-6 rounded-full bg-slate-200 text-slate-600 flex items-center justify-center text-xs font-medium">1</span>
                Upload statement
              </div>
              <div className="flex items-center gap-2">
                <span className="w-6 h-6 rounded-full bg-slate-200 text-slate-600 flex items-center justify-center text-xs font-medium">2</span>
                Review & edit
              </div>
              <div className="flex items-center gap-2">
                <span className="w-6 h-6 rounded-full bg-slate-200 text-slate-600 flex items-center justify-center text-xs font-medium">3</span>
                Paste into Sheets
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
