/**
 * Individual API Client - HTTP layer for individual-related endpoints
 */

import { type Individual } from '../types/individual'

const BASE_URL = '/api/individuals'

/**
 * Fetches the root individual(s) to start the family tree
 * @returns Promise resolving to an array of individuals
 */
export async function getRootIndividuals(): Promise<Individual[]> {
  const response = await fetch(`${BASE_URL}/root`)

  if (!response.ok) {
    throw new Error(`Failed to fetch root individuals: ${response.statusText}`)
  }

  return (await response.json()) as Individual[]
}

/**
 * Fetches a single individual by ID
 * @param id - The individual's ID
 * @returns Promise resolving to an individual
 */
export async function getIndividual(id: number): Promise<Individual> {
  const response = await fetch(`${BASE_URL}/${id}`)

  if (!response.ok) {
    throw new Error(`Failed to fetch individual ${id}: ${response.statusText}`)
  }

  return (await response.json()) as Individual
}
