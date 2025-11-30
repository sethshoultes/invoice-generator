/**
 * User profile
 */
export interface User {
  uid: string
  email: string
  plan: 'free' | 'paid'
  usageLimit: number
  createdAt: Date | string
}

/**
 * User usage tracking
 */
export interface UserUsage {
  userId: string
  month: string // YYYY-MM format
  extractionCount: number
  apiCost: number
  lastExtraction: Date | string
}
