import * as dagre from 'dagre'
import { type Individual } from '../types/individual'
import { type FamilyUnit } from '../types/family-tree'
import { type PersonNode } from '../types/node'
import { NODE_WIDTH, NODE_HEIGHT } from './person-node'
import { TREE_LAYOUT } from '../constants'

export interface LayoutConfig {
  rankdir?: 'TB' | 'BT' | 'LR' | 'RL' // Top to Bottom, Bottom to Top, Left to Right, Right to Left
  nodesep?: number // Horizontal spacing between nodes
  ranksep?: number // Vertical spacing between generations
  marginx?: number
  marginy?: number
}

const DEFAULT_CONFIG: LayoutConfig = {
  rankdir: 'TB',
  nodesep: 150, // Increased from 100: horizontal spacing between nodes in same generation
  ranksep: 180, // Increased from 150: vertical spacing between generations to accommodate taller nodes
  marginx: 50,
  marginy: 50,
}

/**
 * Calculate positions for individuals using dagre graph layout algorithm.
 *
 * @param individuals List of individuals to position
 * @param families Family units containing parent-child relationships
 * @param config Optional layout configuration
 * @returns Array of PersonNodes with calculated x,y positions
 */
export function calculateLayout(
  individuals: Individual[],
  families: FamilyUnit[],
  config: LayoutConfig = {}
): PersonNode[] {
  const mergedConfig = { ...DEFAULT_CONFIG, ...config }

  // Create a new directed graph
  const g = new dagre.graphlib.Graph()

  // Configure the graph layout
  g.setGraph({
    rankdir: mergedConfig.rankdir,
    nodesep: mergedConfig.nodesep,
    ranksep: mergedConfig.ranksep,
    marginx: mergedConfig.marginx,
    marginy: mergedConfig.marginy,
  })

  // Default to assigning a new object as a label for each new edge.
  g.setDefaultEdgeLabel(() => ({}))

  // Add nodes to the graph
  individuals.forEach((individual) => {
    g.setNode(individual.id.toString(), {
      width: NODE_WIDTH,
      height: NODE_HEIGHT,
      label: `${individual.givenName || ''} ${individual.surname || ''}`.trim(),
    })
  })

  // Convert family units to edges for layout purposes
  // For dagre, we still need parent -> child edges to determine generational layers
  const edges: Array<{ from: number; to: number }> = []
  families.forEach((family) => {
    // Add parent→child edges for families with children
    family.parentIds.forEach((parentId) => {
      family.childIds.forEach((childId) => {
        g.setEdge(parentId.toString(), childId.toString())
        edges.push({ from: parentId, to: childId })
      })
    })

    // For childless marriages, create a horizontal constraint to keep spouses together
    // This ensures spouses without children still appear next to each other
    if (family.childIds.length === 0 && family.parentIds.length === 2) {
      const [parent1, parent2] = family.parentIds
      // Set a very short edge weight to keep them close horizontally
      g.setEdge(parent1.toString(), parent2.toString(), { minlen: 0, weight: 100 })
    }
  })

  // Calculate the layout
  dagre.layout(g)

  // Extract positions and create PersonNodes
  const personNodes: PersonNode[] = individuals.map((individual) => {
    const nodeId = individual.id.toString()
    const node = g.node(nodeId)

    if (!node) {
      console.warn(`No layout position found for individual ${nodeId}, using default position`)
      return {
        id: nodeId,
        individual,
        x: 0,
        y: 0,
      }
    }

    return {
      id: nodeId,
      individual,
      x: node.x,
      y: node.y,
    }
  })

  return centerParentsOverChildren(spaceFamilyGroups(personNodes, families), families)
}

/** Child id → the family it is a child of. */
function childFamilies(families: FamilyUnit[]): Map<number, number> {
  return new Map(
    families.flatMap((family) => family.childIds.map((childId) => [childId, family.familyId]))
  )
}

function byIndividualId(nodes: PersonNode[]): Map<number, PersonNode> {
  return new Map(nodes.map((node) => [node.individual.id, node]))
}

/** Rounded so floating-point y values from dagre still group together. */
function byGeneration(nodes: PersonNode[]): Map<number, PersonNode[]> {
  const generations = new Map<number, PersonNode[]>()
  for (const node of nodes) {
    const y = Math.round(node.y)
    generations.set(y, [...(generations.get(y) ?? []), node])
  }
  return generations
}

/**
 * Push each generation's family groups apart horizontally, so siblings read as
 * a group and cousins do not run into them.
 */
function spaceFamilyGroups(personNodes: PersonNode[], families: FamilyUnit[]): PersonNode[] {
  const familyOf = childFamilies(families)
  const shifted = new Map<string, number>()

  for (const generation of byGeneration(personNodes).values()) {
    let offset = 0
    let previousFamilyId: number | undefined

    for (const node of [...generation].sort((a, b) => a.x - b.x)) {
      const familyId = familyOf.get(node.individual.id)
      if (
        familyId !== undefined &&
        previousFamilyId !== undefined &&
        familyId !== previousFamilyId
      ) {
        offset += TREE_LAYOUT.FAMILY_GAP
      }
      shifted.set(node.id, node.x + offset)
      if (familyId !== undefined) previousFamilyId = familyId
    }
  }

  return personNodes.map((node) => ({ ...node, x: shifted.get(node.id) ?? node.x }))
}

/** Re-centre each family's parents over their children once spacing has moved them. */
function centerParentsOverChildren(
  personNodes: PersonNode[],
  families: FamilyUnit[]
): PersonNode[] {
  const nodeMap = byIndividualId(personNodes)
  const offsets = new Map<string, number>()

  for (const family of families) {
    const children = family.childIds
      .map((childId) => nodeMap.get(childId))
      .filter((node) => node !== undefined)
    const parents = family.parentIds
      .map((parentId) => nodeMap.get(parentId))
      .filter((node) => node !== undefined)
    if (children.length === 0 || parents.length === 0) continue

    const childXs = children.map((node) => node.x)
    const childrenCenterX = (Math.min(...childXs) + Math.max(...childXs)) / 2
    const parentCenterX = parents.reduce((sum, node) => sum + node.x, 0) / parents.length

    for (const parent of parents) {
      offsets.set(parent.id, childrenCenterX - parentCenterX)
    }
  }

  return personNodes.map((node) => ({ ...node, x: node.x + (offsets.get(node.id) ?? 0) }))
}
