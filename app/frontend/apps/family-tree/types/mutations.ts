/**
 * TypeScript types for mutation operations (create, update, delete, relationships).
 * These match the backend DTOs exactly.
 */

import { type ParentRole } from '../constants'

/**
 * Request to create or update an individual.
 */
export interface IndividualRequest {
  givenName?: string | null
  surname?: string | null
  sex?: 'M' | 'F' | null
  gedcomId?: string | null
  birthDate?: string | null
  birthPlace?: string | null
  deathDate?: string | null
  deathPlace?: string | null
}

/**
 * Response for an individual (includes relationship metadata).
 */
export interface IndividualResponse {
  id: number
  givenName: string | null
  surname: string | null
  sex: 'M' | 'F' | null
  relationships: RelationshipMetadata
  birthDate: string | null
  birthPlace: string | null
  deathDate: string | null
  deathPlace: string | null
}

/**
 * Metadata about an individual's relationships.
 */
export interface RelationshipMetadata {
  childFamilyIds: number[]
  spouseFamilyIds: number[]
  hasUnloadedAncestors: boolean
  hasUnloadedDescendants: boolean
  hasUnloadedSiblings: boolean
}

/**
 * Validation result (for delete checks).
 */
export interface ValidationResult {
  valid: boolean
  reason?: string | null
}

/**
 * Request to add a child to a person/family.
 */
export interface AddChildRequest {
  parentId: number
  parentFamilyId?: number | null
  childData: IndividualRequest
}

/**
 * Request to add a spouse to a person.
 */
export interface AddSpouseRequest {
  personId: number
  spouseData: IndividualRequest
  marriageData?: {
    marriageDateString?: string | null
    divorceDateString?: string | null
  } | null
}

/**
 * Request to add a parent to a child.
 */
export interface AddParentRequest {
  childId: number
  parentData: IndividualRequest
  role: ParentRole
}

/**
 * Request to add a sibling to a person.
 */
export interface AddSiblingRequest {
  personId: number
  siblingData: IndividualRequest
}

/**
 * Request to link an existing person as a parent to a child.
 */
export interface LinkExistingParentRequest {
  childId: number
  existingParentId: number
  role: ParentRole
}
