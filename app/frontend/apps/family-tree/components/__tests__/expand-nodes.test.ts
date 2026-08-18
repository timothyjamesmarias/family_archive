import { describe, it, expect, beforeEach } from 'vitest'
import { Renderer } from '../renderer'
import { type ExpandTreeNode as ExpandTreeNodeData, type PersonNode } from '../../types/node'
import { type Individual } from '../../types/individual'
import { type ExpandTreeNode } from '../expand-tree-node'

describe('Expand Nodes Rendering', () => {
  let transformGroup: SVGGElement
  let renderer: Renderer

  beforeEach(() => {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
    transformGroup = document.createElementNS('http://www.w3.org/2000/svg', 'g')
    svg.appendChild(transformGroup)
    document.body.appendChild(svg)

    renderer = new Renderer(transformGroup)
  })

  it('should render expand nodes', () => {
    const individual: Individual = {
      id: 1,
      givenName: 'John',
      surname: 'Doe',
      sex: 'M',
      birthDate: null,
      birthPlace: null,
      deathDate: null,
      deathPlace: null,
      relationships: {
        childFamilyIds: [],
        spouseFamilyIds: [],
        hasUnloadedAncestors: true,
        hasUnloadedDescendants: true,
        hasUnloadedSiblings: false,
      },
    }

    const personNode: PersonNode = {
      id: '1',
      individual,
      x: 200,
      y: 200,
    }

    const expandNodeAncestors: ExpandTreeNodeData = {
      id: 'expand-ancestors-1',
      direction: 'up',
      individualId: 1,
      generations: 1,
      x: 200,
      y: 95, // 200 - 105
    }

    const expandNodeDescendants: ExpandTreeNodeData = {
      id: 'expand-descendants-1',
      direction: 'down',
      individualId: 1,
      generations: 1,
      x: 200,
      y: 305, // 200 + 105
    }

    const nodes = [personNode, expandNodeAncestors, expandNodeDescendants]

    renderer.render(nodes, [])

    const expandNodeElements = transformGroup.querySelectorAll('expand-tree-node')

    expect(expandNodeElements.length).toBe(2)
  })

  it('should create expand nodes with correct data', () => {
    const expandNode: ExpandTreeNodeData = {
      id: 'expand-test',
      direction: 'up',
      individualId: 42,
      generations: 1,
      x: 100,
      y: 50,
    }

    renderer.render([expandNode], [])

    const expandElement = transformGroup.querySelector<ExpandTreeNode>('expand-tree-node')
    expect(expandElement).toBeTruthy()

    if (expandElement) {
      const data = expandElement.data
      expect(data).not.toBeNull()
      expect(data?.direction).toBe('up')
      expect(data?.individualId).toBe(42)
    }
  })
})
