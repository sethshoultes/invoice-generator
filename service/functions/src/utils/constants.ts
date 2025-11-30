/**
 * Application constants
 */

// Usage limits
export const FREE_TIER_LIMIT = 10 // Free extractions per month
export const DEFAULT_PLAN = 'free'

// File upload limits
export const MAX_FILE_SIZE = 10 * 1024 * 1024 // 10 MB in bytes
export const ALLOWED_FILE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']

// File retention
export const UPLOAD_RETENTION_DAYS = 30

// Claude API
export const CLAUDE_MODEL = 'claude-sonnet-4-20250514'
export const CLAUDE_MAX_TOKENS = 4096
