import { describe, it, expect } from 'vitest'
import { calculateLayout } from '../layout'
import type { Individual } from '../../types/individual'
import type { FamilyUnit } from '../../types/family-tree'

const person = (id: number): Individual => ({
  id,
  givenName: `P${id}`,
  surname: 'X',
  sex: null,
})

describe('calculateLayout', () => {
  it('positions a two-family tree deterministically', () => {
    const individuals = [1, 2, 3, 4, 5, 6, 7, 8].map(person)
    const families: FamilyUnit[] = [
      { familyId: 100, parentIds: [1, 2], childIds: [3, 4] },
      { familyId: 200, parentIds: [5, 6], childIds: [7, 8] },
    ]
    const nodes = calculateLayout(individuals, families)
    expect(
      nodes.map((n) => ({ id: n.id, x: Math.round(n.x), y: Math.round(n.y) }))
    ).toMatchSnapshot()
  })

  it('handles childless marriages and orphans', () => {
    const individuals = [1, 2, 3].map(person)
    const families: FamilyUnit[] = [{ familyId: 300, parentIds: [1, 2], childIds: [] }]
    const nodes = calculateLayout(individuals, families)
    expect(
      nodes.map((n) => ({ id: n.id, x: Math.round(n.x), y: Math.round(n.y) }))
    ).toMatchSnapshot()
  })
})
