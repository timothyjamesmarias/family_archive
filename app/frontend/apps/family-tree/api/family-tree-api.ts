import { type FamilyTreeResponse } from '../types/family-tree'
import {
  type IndividualRequest,
  type IndividualResponse,
  type ValidationResult,
  type AddChildRequest,
  type AddSpouseRequest,
  type AddParentRequest,
  type AddSiblingRequest,
  type LinkExistingParentRequest,
} from '../types/mutations'
import { csrfHeaders } from '../../../shared/csrf'

const BASE_URL = '/api/family-tree'

/**
 * Get the initial family tree starting from configured root individuals.
 * Returns root individuals plus 1 generation of ancestors and their siblings.
 */
export async function getInitialTree(): Promise<FamilyTreeResponse> {
  const response = await fetch(`${BASE_URL}/initial`)

  if (!response.ok) {
    throw new Error(`Failed to fetch initial tree: ${response.statusText}`)
  }

  return (await response.json()) as FamilyTreeResponse
}

/**
 * Expand the family tree from a specific person.
 *
 * @param personId - The ID of the person to expand from
 * @param generationsUp - Number of ancestor generations to fetch (default: 0)
 * @param generationsDown - Number of descendant generations to fetch (default: 0)
 * @param includeSiblings - Whether to include siblings of the root person (default: false)
 */
export async function expandTree(params: {
  personId: number
  generationsUp?: number
  generationsDown?: number
  includeSiblings?: boolean
}): Promise<FamilyTreeResponse> {
  const queryParams = new URLSearchParams({
    personId: params.personId.toString(),
    ...(params.generationsUp !== undefined && { generationsUp: params.generationsUp.toString() }),
    ...(params.generationsDown !== undefined && {
      generationsDown: params.generationsDown.toString(),
    }),
    ...(params.includeSiblings !== undefined && {
      includeSiblings: params.includeSiblings.toString(),
    }),
  })

  const response = await fetch(`${BASE_URL}/expand?${queryParams}`)

  if (!response.ok) {
    throw new Error(`Failed to expand tree: ${response.statusText}`)
  }

  return (await response.json()) as FamilyTreeResponse
}

// ==================== INDIVIDUAL CRUD OPERATIONS ====================

/**
 * Create a new individual.
 *
 * @param request - Individual data (at least givenName or surname required)
 * @returns The created individual with metadata
 * @throws Error if validation fails or request fails
 */
export async function createIndividual(request: IndividualRequest): Promise<IndividualResponse> {
  const response = await fetch(`${BASE_URL}/individuals`, {
    method: 'POST',
    headers: csrfHeaders({
      'Content-Type': 'application/json',
    }),
    body: JSON.stringify(request),
    credentials: 'same-origin',
  })

  if (!response.ok) {
    if (response.status === 400) {
      throw new Error('Invalid individual data - at least givenName or surname is required')
    }
    throw new Error(`Failed to create individual: ${response.statusText}`)
  }

  return (await response.json()) as IndividualResponse
}

/**
 * Update an existing individual.
 *
 * @param id - The individual's ID
 * @param request - Updated individual data
 * @returns The updated individual with metadata
 * @throws Error if individual not found or request fails
 */
export async function updateIndividual(
  id: number,
  request: IndividualRequest
): Promise<IndividualResponse> {
  const response = await fetch(`${BASE_URL}/individuals/${id}`, {
    method: 'PUT',
    headers: csrfHeaders({
      'Content-Type': 'application/json',
    }),
    body: JSON.stringify(request),
    credentials: 'same-origin',
  })

  if (!response.ok) {
    if (response.status === 403) {
      throw new Error('Access forbidden - Please ensure you are logged in')
    }
    if (response.status === 404) {
      throw new Error('Individual not found')
    }
    if (response.status === 400) {
      throw new Error('Invalid individual data')
    }
    throw new Error(`Failed to update individual: ${response.statusText}`)
  }

  return (await response.json()) as IndividualResponse
}

/**
 * Check if an individual can be deleted.
 * An individual can only be deleted if they are a leaf node (no descendants).
 *
 * @param id - The individual's ID
 * @returns Validation result with reason if deletion is not allowed
 */
export async function canDeleteIndividual(id: number): Promise<ValidationResult> {
  const response = await fetch(`${BASE_URL}/individuals/${id}/can-delete`)

  if (!response.ok) {
    throw new Error(`Failed to check delete eligibility: ${response.statusText}`)
  }

  return (await response.json()) as ValidationResult
}

/**
 * Delete an individual (soft delete).
 * Only allows deletion of leaf nodes (no descendants).
 *
 * @param id - The individual's ID
 * @throws Error if individual has descendants or request fails
 */
export async function deleteIndividual(id: number): Promise<void> {
  const response = await fetch(`${BASE_URL}/individuals/${id}`, {
    method: 'DELETE',
    headers: csrfHeaders(),
    credentials: 'same-origin',
  })

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error('Individual not found')
    }
    if (response.status === 409) {
      throw new Error('Cannot delete individual - they have descendants')
    }
    throw new Error(`Failed to delete individual: ${response.statusText}`)
  }
}

// ==================== RELATIONSHIP OPERATIONS ====================

/**
 * Add a child to a person/family.
 *
 * @param request - Child data and parent/family information
 * @returns Updated tree segment including the new child and family context
 * @throws Error if parent not found or validation fails
 */
export async function addChild(request: AddChildRequest): Promise<FamilyTreeResponse> {
  const response = await fetch(`${BASE_URL}/relationships/child`, {
    method: 'POST',
    headers: csrfHeaders({
      'Content-Type': 'application/json',
    }),
    body: JSON.stringify(request),
    credentials: 'same-origin',
  })

  if (!response.ok) {
    if (response.status === 400) {
      throw new Error('Invalid child data - parent not found or data incomplete')
    }
    if (response.status === 409) {
      throw new Error('Conflict adding child')
    }
    throw new Error(`Failed to add child: ${response.statusText}`)
  }

  return (await response.json()) as FamilyTreeResponse
}

/**
 * Add a spouse to a person.
 * Creates a new family record for the marriage.
 *
 * @param request - Spouse data and optional marriage information
 * @returns Updated tree segment including the new spouse and family
 * @throws Error if person not found or validation fails
 */
export async function addSpouse(request: AddSpouseRequest): Promise<FamilyTreeResponse> {
  const response = await fetch(`${BASE_URL}/relationships/spouse`, {
    method: 'POST',
    headers: csrfHeaders({
      'Content-Type': 'application/json',
    }),
    body: JSON.stringify(request),
    credentials: 'same-origin',
  })

  if (!response.ok) {
    if (response.status === 400) {
      throw new Error('Invalid spouse data - person not found or data incomplete')
    }
    if (response.status === 409) {
      throw new Error('Conflict adding spouse')
    }
    throw new Error(`Failed to add spouse: ${response.statusText}`)
  }

  return (await response.json()) as FamilyTreeResponse
}

/**
 * Add a parent to a child.
 * Finds or creates the child's parent family.
 *
 * @param request - Parent data, child ID, and role (FATHER/MOTHER)
 * @returns Updated tree segment including the new parent and family
 * @throws Error if child not found, role taken, or validation fails
 */
export async function addParent(request: AddParentRequest): Promise<FamilyTreeResponse> {
  const response = await fetch(`${BASE_URL}/relationships/parent`, {
    method: 'POST',
    headers: csrfHeaders({
      'Content-Type': 'application/json',
    }),
    body: JSON.stringify(request),
    credentials: 'same-origin',
  })

  if (!response.ok) {
    if (response.status === 400) {
      throw new Error('Invalid parent data - child not found or data incomplete')
    }
    if (response.status === 409) {
      throw new Error('Conflict adding parent - role may already be taken or family has 2 parents')
    }
    throw new Error(`Failed to add parent: ${response.statusText}`)
  }

  return (await response.json()) as FamilyTreeResponse
}

/**
 * Add a sibling to a person.
 * Adds the new sibling to the person's parent family.
 *
 * @param request - Sibling data and person ID
 * @returns Updated tree segment including the new sibling and family
 * @throws Error if person has no parent family or validation fails
 */
export async function addSibling(request: AddSiblingRequest): Promise<FamilyTreeResponse> {
  const response = await fetch(`${BASE_URL}/relationships/sibling`, {
    method: 'POST',
    headers: csrfHeaders({
      'Content-Type': 'application/json',
    }),
    body: JSON.stringify(request),
    credentials: 'same-origin',
  })

  if (!response.ok) {
    if (response.status === 400) {
      throw new Error('Invalid sibling data - person not found or data incomplete')
    }
    if (response.status === 409) {
      throw new Error('Cannot add sibling - person has no parent family')
    }
    throw new Error(`Failed to add sibling: ${response.statusText}`)
  }

  return (await response.json()) as FamilyTreeResponse
}

/**
 * Link an existing person as a parent to a child.
 * This is used when you want to assign an existing person in the database
 * as the parent of another person, rather than creating a new parent.
 *
 * @param request - Child ID, existing parent ID, and role (FATHER/MOTHER)
 * @returns Updated tree segment including the child, parent, and their connections
 * @throws Error if child or parent not found, role taken, or validation fails
 */
export async function linkExistingParent(
  request: LinkExistingParentRequest
): Promise<FamilyTreeResponse> {
  const response = await fetch(`${BASE_URL}/relationships/link-existing-parent`, {
    method: 'POST',
    headers: csrfHeaders({
      'Content-Type': 'application/json',
    }),
    body: JSON.stringify(request),
    credentials: 'same-origin',
  })

  if (!response.ok) {
    if (response.status === 400) {
      throw new Error('Invalid request - child or parent not found')
    }
    if (response.status === 409) {
      throw new Error('Conflict - role may already be taken or person already in family')
    }
    throw new Error(`Failed to link existing parent: ${response.statusText}`)
  }

  return (await response.json()) as FamilyTreeResponse
}
