/**
 * Saved client profile
 */
export interface Client {
  id?: string
  userId: string
  name: string
  company: string
  address1: string
  address2: string
  createdAt: Date | string
}
