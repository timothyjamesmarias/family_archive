import { type Individual } from './individual'

/**
 * Response object containing individuals and their family units in a family tree
 */
export interface FamilyTreeResponse {
  individuals: Individual[]
  families: FamilyUnit[]
}

/**
 * Represents a family unit (marriage/partnership with children).
 * Parents are connected by a marriage line, and children branch from that union.
 */
export interface FamilyUnit {
  familyId: number
  parentIds: number[] // Usually 2 (mother/father), but could be 1 (single parent) or 0 (orphaned children)
  childIds: number[] // All children in this family
}
