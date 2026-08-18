import { type Individual } from './individual'

/**
 * Base interface for any node that can be rendered on the canvas
 */
export interface RenderableNode {
  id: string
  x: number
  y: number
}

/**
 * A person node that wraps an Individual with rendering data
 */
export interface PersonNode extends RenderableNode {
  individual: Individual
}

/**
 * An expansion control node that allows users to load more generations
 * Displayed at the boundaries of the tree (above ancestors, below descendants)
 */
export interface ExpandTreeNode extends RenderableNode {
  direction: 'up' | 'down' // 'up' = load ancestors, 'down' = load descendants
  individualId: number // ID of the person to expand from
  generations: number // Number of generations to fetch (default: 1)
}
