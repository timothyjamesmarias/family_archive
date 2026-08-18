import { describe, it, expect, beforeEach } from 'vitest'
import { Renderer } from '../renderer'
import type { PersonNode } from '../../types/node'
import '../person-node'
import '../expand-tree-node'

describe('Renderer', () => {
  let transformGroup: SVGGElement

  beforeEach(async () => {
    transformGroup = document.createElementNS('http://www.w3.org/2000/svg', 'g')

    // Ensure custom elements are defined
    await customElements.whenDefined('person-node')
    await new Promise((resolve) => setTimeout(resolve, 0))
  })

  const createTestPersonNode = (
    id: string,
    givenName: string,
    x: number,
    y: number
  ): PersonNode => ({
    id,
    individual: {
      id: parseInt(id),
      givenName,
      surname: 'Doe',
      sex: 'M',
      birthDate: null,
      birthPlace: null,
      deathDate: null,
      deathPlace: null,
    },
    x,
    y,
  })

  it('should render nodes with correct structure', () => {
    const renderer = new Renderer(transformGroup)
    const testNodes = [createTestPersonNode('1', 'Test', 100, 200)]

    renderer.render(testNodes)

    const nodeWrapper = transformGroup.querySelector('.person-node-wrapper')
    expect(nodeWrapper).toBeTruthy()

    const foreignObject = nodeWrapper?.querySelector('foreignObject')
    expect(foreignObject).toBeTruthy()
  })

  it('should position nodes at correct coordinates', () => {
    const renderer = new Renderer(transformGroup)
    const testNodes = [createTestPersonNode('1', 'Person', 150, 250)]

    renderer.render(testNodes)

    const nodeWrapper = transformGroup.querySelector('.person-node-wrapper')
    const transform = nodeWrapper?.getAttribute('transform')

    // The transform centers the node, so we need to account for NODE_WIDTH/2 and NODE_HEIGHT/2
    // NODE_WIDTH = 180, NODE_HEIGHT = 130
    // translate(150 - 90, 250 - 65) = translate(60, 185)
    expect(transform).toBe('translate(60, 185)')
  })

  it('should render multiple nodes', () => {
    const renderer = new Renderer(transformGroup)
    const testNodes = [
      createTestPersonNode('1', 'Person A', 100, 100),
      createTestPersonNode('2', 'Person B', 200, 200),
      createTestPersonNode('3', 'Person C', 300, 300),
    ]

    renderer.render(testNodes)

    const nodeWrappers = transformGroup.querySelectorAll('.person-node-wrapper')
    expect(nodeWrappers.length).toBe(3)
  })

  it('should render foreignObject for each node', () => {
    const renderer = new Renderer(transformGroup)
    const testNodes = [createTestPersonNode('1', 'Test', 100, 200)]

    renderer.render(testNodes)

    const foreignObject = transformGroup.querySelector('.person-node-wrapper foreignObject')
    expect(foreignObject).toBeTruthy()

    // Check dimensions - NODE_WIDTH = 180, NODE_HEIGHT = 130
    expect(foreignObject?.getAttribute('width')).toBe('180')
    expect(foreignObject?.getAttribute('height')).toBe('130')
  })

  it('should render person-node web component', () => {
    const renderer = new Renderer(transformGroup)
    const testNodes = [createTestPersonNode('1', 'John', 100, 200)]

    renderer.render(testNodes)

    const personNode = transformGroup.querySelector('person-node')
    expect(personNode).toBeTruthy()
  })

  it('should clear existing nodes on re-render', () => {
    const renderer = new Renderer(transformGroup)
    const firstRender = [createTestPersonNode('1', 'Person A', 100, 100)]
    const secondRender = [
      createTestPersonNode('2', 'Person B', 200, 200),
      createTestPersonNode('3', 'Person C', 300, 300),
    ]

    renderer.render(firstRender)
    renderer.render(secondRender)

    const nodeWrappers = transformGroup.querySelectorAll('.person-node-wrapper')
    expect(nodeWrappers.length).toBe(2)

    // Verify the IDs match the second render
    const personNodes = transformGroup.querySelectorAll('person-node')
    expect(personNodes.length).toBe(2)
  })

  it('should handle empty node array', () => {
    const renderer = new Renderer(transformGroup)

    renderer.render([])

    const nodeWrappers = transformGroup.querySelectorAll('.person-node-wrapper')
    expect(nodeWrappers.length).toBe(0)
  })

  it('should render family edges when families are provided', () => {
    const renderer = new Renderer(transformGroup)
    const testNodes = [
      createTestPersonNode('1', 'Parent1', 100, 100),
      createTestPersonNode('2', 'Parent2', 200, 100),
      createTestPersonNode('3', 'Child', 150, 250),
    ]

    const families = [
      {
        familyId: 1,
        parentIds: [1, 2],
        childIds: [3],
      },
    ]

    renderer.render(testNodes, families)

    // Should have marriage line, parent stubs, and child stubs
    const marriageLine = transformGroup.querySelector('.marriage-line')
    expect(marriageLine).toBeTruthy()

    const parentStubs = transformGroup.querySelectorAll('.parent-stub')
    expect(parentStubs.length).toBe(2)
  })
})
