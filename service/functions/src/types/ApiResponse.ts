/**
 * Standard API response format
 */
export interface ApiResponse<T> {
  data: T | null
  error: ApiError | null
}

/**
 * API error structure
 */
export interface ApiError {
  code: string
  message: string
  details?: unknown
}

/**
 * Common error codes
 */
export enum ErrorCode {
  AUTH_REQUIRED = 'AUTH_REQUIRED',
  INVALID_TOKEN = 'INVALID_TOKEN',
  QUOTA_EXCEEDED = 'QUOTA_EXCEEDED',
  INVALID_FILE = 'INVALID_FILE',
  FILE_TOO_LARGE = 'FILE_TOO_LARGE',
  NOT_FOUND = 'NOT_FOUND',
  FORBIDDEN = 'FORBIDDEN',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  CLAUDE_API_ERROR = 'CLAUDE_API_ERROR',
}
