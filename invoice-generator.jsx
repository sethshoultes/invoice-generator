import React, { useState, useRef } from 'react';
import { Upload, Trash2, Plus, Download, Loader2, Check, AlertCircle, FileText, ChevronRight, ChevronLeft, Eye, Edit3 } from 'lucide-react';

// PDF generation will use html2pdf.js loaded via CDN
// Add this to your HTML: <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>

export default function InvoiceGenerator() {
  const [step, setStep] = useState(1); // 1: Upload, 2: Edit Items, 3: Invoice Details, 4: Preview
  const [status, setStatus] = useState('idle');
  const [error, setError] = useState(null);
  const invoiceRef = useRef(null);
  
  const [lineItems, setLineItems] = useState([]);
  
  const [invoiceData, setInvoiceData] = useState({
    // Your company info (pre-filled)
    companyName: 'SWS Management Services',
    companyAddress1: '1522 Heritage Fields Dr',
    companyAddress2: 'Washington, Utah 84780',
    companyPhone: '(801) 688-8590',
    
    // Invoice metadata
    submittedDate: new Date().toLocaleDateString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' }),
    invoiceFor: '', // e.g., "October Consulting Services"
    
    // Client info
    clientName: '',
    clientCompany: '',
    clientAddress1: '',
    clientAddress2: '',
    
    // Payable to
    payableTo: 'Seth Shoultes',
    project: '',
    
    // Invoice details
    invoiceNumber: '',
    dueDate: '',
    
    // Footer
    adjustments: 0,
    
    // Services summary (optional long description)
    servicesSummary: ''
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
                text: `Extract ALL charges and fees from this bank/payment statement.

For each charge, capture:
- Date (format as MM/DD/YYYY)
- Description (the merchant name or charge description)
- Amount (as a positive number)

Extract every single line item. Don't skip or summarize any charges.`
              }
            ]
          }]
        })
      });

      const data = await response.json();
      
      if (data.error) throw new Error(data.error.message);

      const toolUse = data.content?.find(block => block.type === 'tool_use');
      if (toolUse?.input?.line_items) {
        setLineItems(toolUse.input.line_items.map((item, idx) => ({
          id: Date.now() + idx,
          date: item.date,
          description: item.description,
          qty: 1,
          unitPrice: item.amount,
          totalPrice: item.amount
        })));
        setStatus('done');
        setStep(2);
      } else {
        throw new Error('No line items extracted');
      }
    } catch (err) {
      setError(err.message);
      setStatus('error');
    }
  };

  const handleFileUpload = (e) => {
    const file = e.target.files?.[0] || e.dataTransfer?.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      const base64 = reader.result.split(',')[1];
      extractFromImage(base64, file.type || 'image/png');
    };
    reader.readAsDataURL(file);
  };

  const updateLineItem = (id, field, value) => {
    setLineItems(items => items.map(item => {
      if (item.id !== id) return item;
      const updated = { ...item, [field]: value };
      if (field === 'qty' || field === 'unitPrice') {
        updated.totalPrice = (parseFloat(updated.qty) || 0) * (parseFloat(updated.unitPrice) || 0);
      }
      return updated;
    }));
  };

  const deleteLineItem = (id) => setLineItems(items => items.filter(item => item.id !== id));
  
  const addLineItem = () => {
    setLineItems(items => [...items, {
      id: Date.now(),
      date: new Date().toLocaleDateString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' }),
      description: '',
      qty: 1,
      unitPrice: 0,
      totalPrice: 0
    }]);
  };

  const subtotal = lineItems.reduce((sum, item) => sum + (parseFloat(item.totalPrice) || 0), 0);
  const total = subtotal + (parseFloat(invoiceData.adjustments) || 0);

  const updateInvoiceData = (field, value) => {
    setInvoiceData(prev => ({ ...prev, [field]: value }));
  };

  const generatePDF = async () => {
    if (typeof html2pdf === 'undefined') {
      alert('PDF library not loaded. Add html2pdf.js to your page.');
      return;
    }
    
    const element = invoiceRef.current;
    const opt = {
      margin: 0.5,
      filename: `invoice-${invoiceData.invoiceNumber || 'draft'}.pdf`,
      image: { type: 'jpeg', quality: 0.98 },
      html2canvas: { scale: 2 },
      jsPDF: { unit: 'in', format: 'letter', orientation: 'portrait' }
    };
    
    await html2pdf().set(opt).from(element).save();
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
  };

  // Step 1: Upload
  const renderUpload = () => (
    <div className="max-w-2xl mx-auto">
      <div className="text-center mb-8">
        <h2 className="text-xl font-semibold text-slate-800">Upload Bank Statement</h2>
        <p className="text-slate-500 mt-1">We'll extract the charges automatically</p>
      </div>
      
      <div
        onDrop={(e) => { e.preventDefault(); handleFileUpload(e); }}
        onDragOver={(e) => e.preventDefault()}
        className={`
          border-2 border-dashed rounded-2xl p-16 text-center transition-all cursor-pointer
          ${status === 'error' ? 'border-red-300 bg-red-50' : 'border-slate-300 bg-white hover:border-blue-400 hover:bg-blue-50/30'}
        `}
      >
        <input type="file" accept="image/*,.pdf" onChange={handleFileUpload} className="hidden" id="file-upload" />
        <label htmlFor="file-upload" className="cursor-pointer">
          {status === 'processing' ? (
            <>
              <Loader2 className="w-12 h-12 mx-auto text-blue-500 mb-4 animate-spin" />
              <p className="text-blue-700 font-medium">Extracting charges...</p>
            </>
          ) : status === 'error' ? (
            <>
              <AlertCircle className="w-12 h-12 mx-auto text-red-400 mb-4" />
              <p className="text-red-700 font-medium">Extraction failed</p>
              <p className="text-red-500 text-sm mt-2">{error}</p>
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
      
      <div className="mt-6 text-center">
        <button
          onClick={() => { setLineItems([]); setStep(2); }}
          className="text-sm text-slate-500 hover:text-slate-700 underline"
        >
          Or start with a blank invoice
        </button>
      </div>
    </div>
  );

  // Step 2: Edit Line Items
  const renderLineItems = () => (
    <div className="max-w-4xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-semibold text-slate-800">Line Items</h2>
          <p className="text-slate-500 mt-1">Review and edit the extracted charges</p>
        </div>
        <button onClick={addLineItem} className="flex items-center gap-2 text-sm text-blue-600 hover:text-blue-700 font-medium">
          <Plus className="w-4 h-4" /> Add Item
        </button>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200">
              <th className="text-left text-xs font-semibold text-slate-600 px-4 py-3 w-28">Date</th>
              <th className="text-left text-xs font-semibold text-slate-600 px-4 py-3">Description</th>
              <th className="text-center text-xs font-semibold text-slate-600 px-4 py-3 w-16">Qty</th>
              <th className="text-right text-xs font-semibold text-slate-600 px-4 py-3 w-28">Unit Price</th>
              <th className="text-right text-xs font-semibold text-slate-600 px-4 py-3 w-28">Total</th>
              <th className="w-10"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {lineItems.map((item) => (
              <tr key={item.id} className="group hover:bg-slate-50/50">
                <td className="px-4 py-2">
                  <input
                    type="text"
                    value={item.date}
                    onChange={(e) => updateLineItem(item.id, 'date', e.target.value)}
                    className="w-full px-2 py-1.5 text-sm border border-slate-200 rounded focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
                    placeholder="MM/DD/YYYY"
                  />
                </td>
                <td className="px-4 py-2">
                  <input
                    type="text"
                    value={item.description}
                    onChange={(e) => updateLineItem(item.id, 'description', e.target.value)}
                    className="w-full px-2 py-1.5 text-sm border border-slate-200 rounded focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
                  />
                </td>
                <td className="px-4 py-2">
                  <input
                    type="number"
                    value={item.qty}
                    onChange={(e) => updateLineItem(item.id, 'qty', e.target.value)}
                    className="w-full px-2 py-1.5 text-sm text-center border border-slate-200 rounded focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
                  />
                </td>
                <td className="px-4 py-2">
                  <input
                    type="number"
                    step="0.01"
                    value={item.unitPrice}
                    onChange={(e) => updateLineItem(item.id, 'unitPrice', e.target.value)}
                    className="w-full px-2 py-1.5 text-sm text-right border border-slate-200 rounded focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
                  />
                </td>
                <td className="px-4 py-2 text-right text-sm font-medium text-slate-700">
                  {formatCurrency(item.totalPrice)}
                </td>
                <td className="px-2">
                  <button onClick={() => deleteLineItem(item.id)} className="p-1 text-slate-300 hover:text-red-500 opacity-0 group-hover:opacity-100">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr className="bg-slate-50 border-t-2 border-slate-200">
              <td colSpan="4" className="px-4 py-3 text-right font-semibold text-slate-600">Subtotal</td>
              <td className="px-4 py-3 text-right font-semibold text-slate-800">{formatCurrency(subtotal)}</td>
              <td></td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  );

  // Step 3: Invoice Details
  const renderDetails = () => (
    <div className="max-w-2xl mx-auto">
      <div className="text-center mb-8">
        <h2 className="text-xl font-semibold text-slate-800">Invoice Details</h2>
        <p className="text-slate-500 mt-1">Fill in the client and invoice information</p>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-6">
        {/* Invoice For (service description) */}
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Invoice For (service period/description)</label>
          <input
            type="text"
            value={invoiceData.invoiceFor}
            onChange={(e) => updateInvoiceData('invoiceFor', e.target.value)}
            placeholder="e.g., October Consulting Services"
            className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
          />
        </div>

        <div className="grid grid-cols-2 gap-6">
          {/* Left: Client Info */}
          <div className="space-y-4">
            <h3 className="font-semibold text-slate-800">Bill To</h3>
            <input
              type="text"
              value={invoiceData.clientName}
              onChange={(e) => updateInvoiceData('clientName', e.target.value)}
              placeholder="Client Name"
              className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
            />
            <input
              type="text"
              value={invoiceData.clientCompany}
              onChange={(e) => updateInvoiceData('clientCompany', e.target.value)}
              placeholder="Company Name"
              className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
            />
            <input
              type="text"
              value={invoiceData.clientAddress1}
              onChange={(e) => updateInvoiceData('clientAddress1', e.target.value)}
              placeholder="Street Address"
              className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
            />
            <input
              type="text"
              value={invoiceData.clientAddress2}
              onChange={(e) => updateInvoiceData('clientAddress2', e.target.value)}
              placeholder="City, State ZIP"
              className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
            />
          </div>

          {/* Right: Invoice Info */}
          <div className="space-y-4">
            <h3 className="font-semibold text-slate-800">Invoice Info</h3>
            <div>
              <label className="block text-xs text-slate-500 mb-1">Project</label>
              <input
                type="text"
                value={invoiceData.project}
                onChange={(e) => updateInvoiceData('project', e.target.value)}
                placeholder="Project Name"
                className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
              />
            </div>
            <div>
              <label className="block text-xs text-slate-500 mb-1">Invoice #</label>
              <input
                type="text"
                value={invoiceData.invoiceNumber}
                onChange={(e) => updateInvoiceData('invoiceNumber', e.target.value)}
                placeholder="e.g., 11042025-1"
                className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
              />
            </div>
            <div>
              <label className="block text-xs text-slate-500 mb-1">Due Date</label>
              <input
                type="text"
                value={invoiceData.dueDate}
                onChange={(e) => updateInvoiceData('dueDate', e.target.value)}
                placeholder="MM/DD/YYYY"
                className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
              />
            </div>
            <div>
              <label className="block text-xs text-slate-500 mb-1">Adjustments ($)</label>
              <input
                type="number"
                step="0.01"
                value={invoiceData.adjustments}
                onChange={(e) => updateInvoiceData('adjustments', e.target.value)}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
              />
            </div>
          </div>
        </div>

        {/* Services Summary */}
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Services Summary (optional)</label>
          <textarea
            value={invoiceData.servicesSummary}
            onChange={(e) => updateInvoiceData('servicesSummary', e.target.value)}
            placeholder="Detailed description of services rendered..."
            rows={4}
            className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
          />
        </div>
      </div>
    </div>
  );

  // Step 4: Preview & Export
  const renderPreview = () => (
    <div className="max-w-4xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-semibold text-slate-800">Preview</h2>
          <p className="text-slate-500 mt-1">Review your invoice before exporting</p>
        </div>
        <button
          onClick={generatePDF}
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-lg font-medium transition-colors"
        >
          <Download className="w-4 h-4" />
          Download PDF
        </button>
      </div>

      {/* Invoice Preview */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <div ref={invoiceRef} className="p-8" style={{ fontFamily: 'Arial, sans-serif', fontSize: '11px', lineHeight: '1.4' }}>
          {/* Header */}
          <div style={{ color: '#2563eb', fontSize: '24px', fontWeight: 'bold', marginBottom: '4px' }}>
            {invoiceData.companyName}
          </div>
          <div style={{ color: '#374151', marginBottom: '2px' }}>{invoiceData.companyAddress1}</div>
          <div style={{ color: '#374151', marginBottom: '2px' }}>{invoiceData.companyAddress2}</div>
          <div style={{ color: '#374151', marginBottom: '24px' }}>{invoiceData.companyPhone}</div>

          {/* Invoice Title */}
          <div style={{ fontSize: '36px', fontWeight: 'bold', color: '#1e3a5f', marginBottom: '8px' }}>Invoice</div>
          
          {/* Submitted / For row */}
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '24px' }}>
            <div style={{ color: '#2563eb', fontWeight: 'bold' }}>Submitted on {invoiceData.submittedDate}</div>
            <div><span style={{ fontWeight: 'bold' }}>For:</span> <span style={{ fontStyle: 'italic' }}>{invoiceData.invoiceFor}</span></div>
          </div>

          {/* Info Grid */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px', marginBottom: '24px' }}>
            <div>
              <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>Invoice for</div>
              <div>{invoiceData.clientName}</div>
              <div>{invoiceData.clientCompany}</div>
              <div>{invoiceData.clientAddress1}</div>
              <div>{invoiceData.clientAddress2}</div>
            </div>
            <div>
              <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>Payable to</div>
              <div style={{ marginBottom: '12px' }}>{invoiceData.payableTo}</div>
              <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>Project</div>
              <div>{invoiceData.project}</div>
            </div>
            <div>
              <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>Invoice #</div>
              <div style={{ marginBottom: '12px' }}>{invoiceData.invoiceNumber}</div>
              <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>Due date</div>
              <div>{invoiceData.dueDate}</div>
            </div>
          </div>

          {/* Line Items Table */}
          <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: '24px' }}>
            <thead>
              <tr style={{ borderBottom: '2px solid #1e3a5f' }}>
                <th style={{ textAlign: 'left', padding: '8px 4px', fontWeight: 'bold' }}>Description</th>
                <th style={{ textAlign: 'center', padding: '8px 4px', fontWeight: 'bold', width: '60px' }}>Qty</th>
                <th style={{ textAlign: 'right', padding: '8px 4px', fontWeight: 'bold', width: '100px' }}>Unit price</th>
                <th style={{ textAlign: 'right', padding: '8px 4px', fontWeight: 'bold', width: '100px' }}>Total price</th>
              </tr>
            </thead>
            <tbody>
              {lineItems.map((item, idx) => (
                <tr key={idx} style={{ borderBottom: '1px solid #e5e7eb' }}>
                  <td style={{ padding: '8px 4px' }}>{item.date} {item.description}</td>
                  <td style={{ padding: '8px 4px', textAlign: 'center' }}>{item.qty}</td>
                  <td style={{ padding: '8px 4px', textAlign: 'right' }}>{formatCurrency(item.unitPrice)}</td>
                  <td style={{ padding: '8px 4px', textAlign: 'right' }}>{formatCurrency(item.totalPrice)}</td>
                </tr>
              ))}
              {invoiceData.servicesSummary && (
                <tr style={{ borderBottom: '1px solid #e5e7eb' }}>
                  <td colSpan="4" style={{ padding: '8px 4px', whiteSpace: 'pre-wrap' }}>{invoiceData.servicesSummary}</td>
                </tr>
              )}
            </tbody>
          </table>

          {/* Totals */}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', borderTop: '2px solid #1e3a5f', paddingTop: '12px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', width: '250px', marginBottom: '4px' }}>
              <span>Subtotal</span>
              <span style={{ fontWeight: 'bold' }}>{formatCurrency(subtotal)}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', width: '250px', marginBottom: '8px' }}>
              <span>Adjustments</span>
              <span>{formatCurrency(parseFloat(invoiceData.adjustments) || 0)}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', width: '250px', alignItems: 'baseline' }}>
              <span style={{ color: '#2563eb', fontWeight: 'bold', fontSize: '14px' }}>Total</span>
              <span style={{ color: '#db2777', fontWeight: 'bold', fontSize: '24px' }}>{formatCurrency(total)}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const steps = [
    { num: 1, label: 'Upload' },
    { num: 2, label: 'Line Items' },
    { num: 3, label: 'Details' },
    { num: 4, label: 'Preview' }
  ];

  return (
    <div className="min-h-screen bg-slate-50" style={{ fontFamily: "'Inter', system-ui, sans-serif" }}>
      {/* Header */}
      <div className="bg-white border-b border-slate-200 px-6 py-4">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <FileText className="w-6 h-6 text-blue-600" />
            <span className="font-semibold text-slate-800">Invoice Generator</span>
          </div>
          
          {/* Progress Steps */}
          <div className="flex items-center gap-2">
            {steps.map((s, idx) => (
              <React.Fragment key={s.num}>
                <button
                  onClick={() => setStep(s.num)}
                  className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm transition-colors ${
                    step === s.num ? 'bg-blue-100 text-blue-700 font-medium' : 'text-slate-500 hover:text-slate-700'
                  }`}
                >
                  <span className={`w-5 h-5 rounded-full flex items-center justify-center text-xs ${
                    step === s.num ? 'bg-blue-600 text-white' : step > s.num ? 'bg-green-500 text-white' : 'bg-slate-200'
                  }`}>
                    {step > s.num ? <Check className="w-3 h-3" /> : s.num}
                  </span>
                  {s.label}
                </button>
                {idx < steps.length - 1 && <ChevronRight className="w-4 h-4 text-slate-300" />}
              </React.Fragment>
            ))}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-6">
        {step === 1 && renderUpload()}
        {step === 2 && renderLineItems()}
        {step === 3 && renderDetails()}
        {step === 4 && renderPreview()}
      </div>

      {/* Footer Nav */}
      {step > 1 && (
        <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 px-6 py-4">
          <div className="max-w-4xl mx-auto flex justify-between">
            <button
              onClick={() => setStep(step - 1)}
              className="flex items-center gap-2 px-4 py-2 text-slate-600 hover:text-slate-800"
            >
              <ChevronLeft className="w-4 h-4" /> Back
            </button>
            {step < 4 && (
              <button
                onClick={() => setStep(step + 1)}
                className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2 rounded-lg font-medium"
              >
                Continue <ChevronRight className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
