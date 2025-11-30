/**
 * Date utility functions
 */

/**
 * Get current month in YYYY-MM format
 */
export function getCurrentMonth(): string {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  return `${year}-${month}`
}

/**
 * Get today's date in YYYY-MM-DD format
 */
export function getTodayISO(): string {
  return new Date().toISOString().split('T')[0]
}

/**
 * Convert MM/DD/YYYY to YYYY-MM-DD
 */
export function toISODate(displayDate: string): string {
  if (!displayDate) return ''
  const parts = displayDate.split('/')
  if (parts.length !== 3) return ''
  const [month, day, year] = parts
  return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`
}

/**
 * Convert YYYY-MM-DD to MM/DD/YYYY
 */
export function toDisplayDate(isoDate: string): string {
  if (!isoDate) return ''
  const [year, month, day] = isoDate.split('-')
  return `${month}/${day}/${year}`
}
