import { type Individual } from './types/individual'
import { type FamilyUnit, type FamilyTreeResponse } from './types/family-tree'

export interface TreeState {
  individuals: Individual[]
  families: FamilyUnit[]
}

type TreeStateListener = (state: TreeState) => void

class FamilyTreeStore {
  private state: TreeState = {
    individuals: [],
    families: [],
  }

  private listeners: TreeStateListener[] = []

  getState(): TreeState {
    return { ...this.state }
  }

  setTreeData(data: FamilyTreeResponse): void {
    this.state = {
      individuals: data.individuals,
      families: data.families,
    }
    this.notifyListeners()
  }

  mergeTreeData(newData: FamilyTreeResponse): void {
    const existingIndividualIds = new Set(this.state.individuals.map((i) => i.id))
    const existingFamilyMap = new Map(this.state.families.map((f) => [f.familyId, f]))

    // Add only new individuals (don't update existing ones)
    const newIndividuals = newData.individuals.filter(
      (individual) => !existingIndividualIds.has(individual.id)
    )

    // Merge families: combine parent and child IDs from both old and new data
    const mergedFamilies = new Map(existingFamilyMap)

    newData.families.forEach((newFamily) => {
      const existingFamily = mergedFamilies.get(newFamily.familyId)

      if (existingFamily) {
        // Merge parent and child IDs (union of both sets)
        const mergedParentIds = Array.from(
          new Set([...existingFamily.parentIds, ...newFamily.parentIds])
        )
        const mergedChildIds = Array.from(
          new Set([...existingFamily.childIds, ...newFamily.childIds])
        )

        mergedFamilies.set(newFamily.familyId, {
          familyId: newFamily.familyId,
          parentIds: mergedParentIds,
          childIds: mergedChildIds,
        })
      } else {
        // New family, just add it
        mergedFamilies.set(newFamily.familyId, newFamily)
      }
    })

    this.state = {
      individuals: [...this.state.individuals, ...newIndividuals],
      families: Array.from(mergedFamilies.values()),
    }

    this.notifyListeners()
  }

  updateIndividual(updatedIndividual: Individual): void {
    this.state = {
      ...this.state,
      individuals: this.state.individuals.map((individual) =>
        individual.id === updatedIndividual.id ? updatedIndividual : individual
      ),
    }
    this.notifyListeners()
  }

  removeIndividual(individualId: number): void {
    this.state = {
      ...this.state,
      individuals: this.state.individuals.filter((individual) => individual.id !== individualId),
    }
    this.notifyListeners()
  }

  getIndividualById(id: number): Individual | undefined {
    return this.state.individuals.find((individual) => individual.id === id)
  }

  subscribe(listener: TreeStateListener): () => void {
    this.listeners.push(listener)
    return () => {
      this.listeners = this.listeners.filter((l) => l !== listener)
    }
  }

  private notifyListeners(): void {
    this.listeners.forEach((listener) => listener(this.state))
  }
}

export const familyTreeStore = new FamilyTreeStore()
