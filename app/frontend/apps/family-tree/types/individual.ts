import { type RelationshipMetadata } from './mutations'

/**
 * Individual person type - represents a person in the family tree
 */
export interface Individual {
  id: number
  givenName: string | null
  surname: string | null
  sex: 'M' | 'F' | null
  birthDate?: string | null
  birthPlace?: string | null
  deathDate?: string | null
  deathPlace?: string | null
  relationships?: RelationshipMetadata
}
