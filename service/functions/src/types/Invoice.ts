import { LineItem } from './LineItem'

/**
 * Invoice data structure
 */
export interface InvoiceData {
  companyName: string
  companyAddress1: string
  companyAddress2: string
  companyPhone: string
  submittedDate: string
  invoiceFor: string
  clientName: string
  clientCompany: string
  clientAddress1: string
  clientAddress2: string
  payableTo: string
  project: string
  invoiceNumber: string
  dueDate: string
  adjustments: number
  servicesSummary: string
}

/**
 * Complete invoice with line items
 */
export interface Invoice {
  id?: string
  userId: string
  lineItems: LineItem[]
  invoiceData: InvoiceData
  status: 'draft' | 'finalized'
  createdAt: Date | string
  updatedAt: Date | string
}
