import { type FamilyTreeResponse, type FamilyUnit } from './types/family-tree'
import { type Individual } from './types/individual'
import {
  type RelationshipMetadata,
  type IndividualRequest,
  type AddChildRequest,
  type AddSpouseRequest,
  type AddParentRequest,
  type AddSiblingRequest,
  type LinkExistingParentRequest,
} from './types/mutations'
import * as FamilyTreeAPI from './api/family-tree-api'
import * as IndividualAPI from './api/individual-api'
import { ParentRole, Sex, MAX_PARENTS_PER_FAMILY } from './constants'

export class FamilyTreeService {
  async loadInitialTree(): Promise<FamilyTreeResponse> {
    const tree = await FamilyTreeAPI.getInitialTree()
    return tree
  }

  async expandTree(params: {
    personId: number
    generationsUp?: number
    generationsDown?: number
    includeSiblings?: boolean
  }): Promise<FamilyTreeResponse> {
    const tree = await FamilyTreeAPI.expandTree(params)
    return tree
  }

  async loadIndividual(id: number): Promise<Individual> {
    const individual = await IndividualAPI.getIndividual(id)
    return individual
  }

  async createIndividual(request: IndividualRequest): Promise<Individual> {
    const response = await FamilyTreeAPI.createIndividual(request)
    return this.convertResponseToIndividual(response)
  }

  async updateIndividual(id: number, request: IndividualRequest): Promise<Individual> {
    const response = await FamilyTreeAPI.updateIndividual(id, request)
    return this.convertResponseToIndividual(response)
  }

  async deleteIndividual(id: number): Promise<void> {
    await FamilyTreeAPI.deleteIndividual(id)
  }

  async canDeleteIndividual(id: number): Promise<boolean> {
    const result = await FamilyTreeAPI.canDeleteIndividual(id)
    return result.valid
  }

  async addChild(request: AddChildRequest): Promise<FamilyTreeResponse> {
    return await FamilyTreeAPI.addChild(request)
  }

  async addSpouse(request: AddSpouseRequest): Promise<FamilyTreeResponse> {
    return await FamilyTreeAPI.addSpouse(request)
  }

  async addParent(request: AddParentRequest): Promise<FamilyTreeResponse> {
    return await FamilyTreeAPI.addParent(request)
  }

  async addSibling(request: AddSiblingRequest): Promise<FamilyTreeResponse> {
    return await FamilyTreeAPI.addSibling(request)
  }

  async linkExistingParent(request: LinkExistingParentRequest): Promise<FamilyTreeResponse> {
    return await FamilyTreeAPI.linkExistingParent(request)
  }

  determineAvailableParentRoles(
    metadata: RelationshipMetadata,
    individuals: Individual[],
    families: FamilyUnit[]
  ): ParentRole[] {
    const availableRoles: ParentRole[] = []

    if (!metadata?.childFamilyIds || metadata.childFamilyIds.length === 0) {
      return [ParentRole.FATHER, ParentRole.MOTHER]
    }

    const childFamilyId = metadata.childFamilyIds[0]
    const family = families.find((f) => f.familyId === childFamilyId)

    if (!family) {
      return [ParentRole.FATHER, ParentRole.MOTHER]
    }

    const hasFather = family.parentIds.some((parentId) => {
      const parent = individuals.find((i) => i.id === parentId)
      return parent?.sex === Sex.MALE
    })

    const hasMother = family.parentIds.some((parentId) => {
      const parent = individuals.find((i) => i.id === parentId)
      return parent?.sex === Sex.FEMALE
    })

    if (!hasFather) availableRoles.push(ParentRole.FATHER)
    if (!hasMother) availableRoles.push(ParentRole.MOTHER)

    if (availableRoles.length === 0 && family.parentIds.length < MAX_PARENTS_PER_FAMILY) {
      availableRoles.push(ParentRole.FATHER, ParentRole.MOTHER)
    }

    return availableRoles
  }

  private convertResponseToIndividual(response: {
    id: number
    givenName: string | null
    surname: string | null
    sex: 'M' | 'F' | null
    birthDate: string | null
    birthPlace: string | null
    deathDate: string | null
    deathPlace: string | null
    relationships: RelationshipMetadata
  }): Individual {
    return {
      id: response.id,
      givenName: response.givenName,
      surname: response.surname,
      sex: response.sex,
      birthDate: response.birthDate,
      birthPlace: response.birthPlace,
      deathDate: response.deathDate,
      deathPlace: response.deathPlace,
      relationships: response.relationships,
    }
  }
}
