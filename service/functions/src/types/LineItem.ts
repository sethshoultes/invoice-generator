/**
 * Line item extracted from invoice/statement
 */
export interface LineItem {
  date: string // YYYY-MM-DD format
  description: string
  quantity?: number
  price: number
  amount: number
}
