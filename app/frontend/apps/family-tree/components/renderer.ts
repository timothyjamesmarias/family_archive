import { select, type Selection } from 'd3-selection'
import {
  type PersonNode as PersonNodeData,
  type ExpandTreeNode as ExpandTreeNodeData,
  type RenderableNode,
} from '../types/node'
import { type FamilyUnit } from '../types/family-tree'
import { NODE_WIDTH, NODE_HEIGHT, type PersonNode } from './person-node'
import { EXPAND_NODE_WIDTH, EXPAND_NODE_HEIGHT, type ExpandTreeNode } from './expand-tree-node'
import './person-node'
import './expand-tree-node'

const EDGE_STROKE_COLOR = '#94a3b8'
const EDGE_STROKE_WIDTH = 2
const MARRIAGE_LINE_COLOR = '#94a3b8'
const MARRIAGE_LINE_WIDTH = 2
const PARENT_STUB_LENGTH = 20 // Vertical space between parent node and marriage line
const CHILD_STUB_LENGTH = 20 // Vertical space between child node and family line

/**
 * Type guard to check if a node is a PersonNode
 */
function isPersonNode(node: RenderableNode): node is PersonNodeData {
  return 'individual' in node
}

/**
 * Type guard to check if a node is an ExpandTreeNode
 */
function isExpandTreeNode(node: RenderableNode): node is ExpandTreeNodeData {
  return 'direction' in node
}

export class Renderer {
  private transformGroup: SVGGElement

  constructor(transformGroup: SVGGElement) {
    this.transformGroup = transformGroup
  }

  render(nodes: RenderableNode[], families: FamilyUnit[] = []) {
    this.clear()

    // Separate person nodes and expand nodes
    const personNodes = nodes.filter(isPersonNode)
    const expandNodes = nodes.filter(isExpandTreeNode)

    this.renderFamilyEdges(families, personNodes)

    // Render all nodes (both person and expand nodes)
    this.renderNodes([...personNodes, ...expandNodes])
  }

  private clear() {
    select(this.transformGroup).selectAll('*').remove()
  }

  /**
   * Render family tree edges with proper family structure:
   * - Horizontal marriage line between parents
   * - Vertical line from marriage midpoint down to children
   * - Horizontal line across children
   * - Vertical lines from horizontal to each child
   */
  private renderFamilyEdges(families: FamilyUnit[], nodes: PersonNodeData[]) {
    if (families.length === 0) {
      return
    }

    const nodeMap = this.createNodeMap(nodes)
    const group = select(this.transformGroup)

    families.forEach((family) => {
      const parents = this.getNodesById(family.parentIds, nodeMap)
      const children = this.getNodesById(family.childIds, nodeMap)

      if (this.hasNoMembers(parents, children)) {
        return
      }

      const marriagePoint = this.calculateMarriagePoint(parents, children)

      if (parents.length === 2) {
        this.drawMarriageLine(group, parents, marriagePoint.y)
      } else if (parents.length === 1) {
        this.drawParentStub(group, parents[0], marriagePoint.y)
      }

      if (children.length > 0) {
        this.drawChildrenLines(group, marriagePoint, children)
      }
    })
  }

  private createNodeMap(nodes: PersonNodeData[]): Map<string, PersonNodeData> {
    const nodeMap = new Map<string, PersonNodeData>()
    nodes.forEach((node) => nodeMap.set(node.id, node))
    return nodeMap
  }

  private getNodesById(ids: number[], nodeMap: Map<string, PersonNodeData>): PersonNodeData[] {
    return ids.map((id) => nodeMap.get(id.toString())).filter(Boolean) as PersonNodeData[]
  }

  private hasNoMembers(parents: PersonNodeData[], children: PersonNodeData[]): boolean {
    return parents.length === 0 && children.length === 0
  }

  private calculateMarriagePoint(
    parents: PersonNodeData[],
    children: PersonNodeData[]
  ): { x: number; y: number } {
    if (parents.length === 2) {
      return this.calculateMarriagePointForCouples(parents)
    }

    if (parents.length === 1) {
      return this.calculateMarriagePointForSingleParent(parents[0])
    }

    return this.calculateMarriagePointForOrphans(children)
  }

  private calculateMarriagePointForCouples(parents: PersonNodeData[]): { x: number; y: number } {
    const [parent1, parent2] = parents
    const leftParent = parent1.x < parent2.x ? parent1 : parent2
    const rightParent = parent1.x < parent2.x ? parent2 : parent1
    const y = Math.max(leftParent.y, rightParent.y) + NODE_HEIGHT / 2 + PARENT_STUB_LENGTH

    return {
      x: (leftParent.x + rightParent.x) / 2,
      y,
    }
  }

  private calculateMarriagePointForSingleParent(parent: PersonNodeData): { x: number; y: number } {
    return {
      x: parent.x,
      y: parent.y + NODE_HEIGHT / 2 + PARENT_STUB_LENGTH,
    }
  }

  private calculateMarriagePointForOrphans(children: PersonNodeData[]): { x: number; y: number } {
    const ORPHAN_LINE_OFFSET = 60
    const childrenY = Math.min(...children.map((c) => c.y))
    const averageX = children.reduce((sum, c) => sum + c.x, 0) / children.length

    return {
      x: averageX,
      y: childrenY - ORPHAN_LINE_OFFSET,
    }
  }

  private drawMarriageLine(
    group: Selection<SVGGElement, unknown, null, undefined>,
    parents: PersonNodeData[],
    marriageY: number
  ): void {
    const [parent1, parent2] = parents
    const leftParent = parent1.x < parent2.x ? parent1 : parent2
    const rightParent = parent1.x < parent2.x ? parent2 : parent1

    // Draw vertical stubs from each parent down to marriage line
    this.drawParentStub(group, leftParent, marriageY)
    this.drawParentStub(group, rightParent, marriageY)

    // Draw horizontal marriage line connecting the stubs
    group
      .append('line')
      .attr('class', 'marriage-line')
      .attr('x1', leftParent.x)
      .attr('y1', marriageY)
      .attr('x2', rightParent.x)
      .attr('y2', marriageY)
      .attr('stroke', MARRIAGE_LINE_COLOR)
      .attr('stroke-width', MARRIAGE_LINE_WIDTH)
  }

  private drawParentStub(
    group: Selection<SVGGElement, unknown, null, undefined>,
    parent: PersonNodeData,
    marriageY: number
  ): void {
    const parentBottomY = parent.y + NODE_HEIGHT / 2

    group
      .append('line')
      .attr('class', 'parent-stub')
      .attr('x1', parent.x)
      .attr('y1', parentBottomY)
      .attr('x2', parent.x)
      .attr('y2', marriageY)
      .attr('stroke', EDGE_STROKE_COLOR)
      .attr('stroke-width', EDGE_STROKE_WIDTH)
  }

  private drawChildrenLines(
    group: Selection<SVGGElement, unknown, null, undefined>,
    marriagePoint: { x: number; y: number },
    children: PersonNodeData[]
  ): void {
    // Children bar Y position - above child stubs
    const childrenBarY = Math.min(...children.map((c) => c.y)) - NODE_HEIGHT / 2 - CHILD_STUB_LENGTH

    this.drawVerticalLineToChildren(group, marriagePoint, childrenBarY)

    if (children.length === 1) {
      this.drawSingleChildStub(group, marriagePoint.x, childrenBarY, children[0])
    } else {
      this.drawMultipleChildrenLines(group, childrenBarY, children)
    }
  }

  private drawVerticalLineToChildren(
    group: Selection<SVGGElement, unknown, null, undefined>,
    marriagePoint: { x: number; y: number },
    childrenY: number
  ): void {
    group
      .append('line')
      .attr('class', 'family-line')
      .attr('x1', marriagePoint.x)
      .attr('y1', marriagePoint.y)
      .attr('x2', marriagePoint.x)
      .attr('y2', childrenY)
      .attr('stroke', EDGE_STROKE_COLOR)
      .attr('stroke-width', EDGE_STROKE_WIDTH)
  }

  private drawSingleChildStub(
    group: Selection<SVGGElement, unknown, null, undefined>,
    marriageX: number,
    childrenBarY: number,
    child: PersonNodeData
  ): void {
    const childTopY = child.y - NODE_HEIGHT / 2

    // If child is not directly under marriage point, draw horizontal connection first
    if (Math.abs(child.x - marriageX) > 1) {
      // Draw horizontal line from marriage X to child X
      group
        .append('line')
        .attr('class', 'child-connector')
        .attr('x1', marriageX)
        .attr('y1', childrenBarY)
        .attr('x2', child.x)
        .attr('y2', childrenBarY)
        .attr('stroke', EDGE_STROKE_COLOR)
        .attr('stroke-width', EDGE_STROKE_WIDTH)
    }

    // Draw vertical stub from bar to child
    group
      .append('line')
      .attr('class', 'child-stub')
      .attr('x1', child.x)
      .attr('y1', childrenBarY)
      .attr('x2', child.x)
      .attr('y2', childTopY)
      .attr('stroke', EDGE_STROKE_COLOR)
      .attr('stroke-width', EDGE_STROKE_WIDTH)
  }

  private drawMultipleChildrenLines(
    group: Selection<SVGGElement, unknown, null, undefined>,
    childrenY: number,
    children: PersonNodeData[]
  ): void {
    const leftmostChildX = Math.min(...children.map((c) => c.x))
    const rightmostChildX = Math.max(...children.map((c) => c.x))

    this.drawChildrenBar(group, childrenY, leftmostChildX, rightmostChildX)
    this.drawIndividualChildLines(group, childrenY, children)
  }

  private drawChildrenBar(
    group: Selection<SVGGElement, unknown, null, undefined>,
    y: number,
    leftX: number,
    rightX: number
  ): void {
    group
      .append('line')
      .attr('class', 'children-bar')
      .attr('x1', leftX)
      .attr('y1', y)
      .attr('x2', rightX)
      .attr('y2', y)
      .attr('stroke', EDGE_STROKE_COLOR)
      .attr('stroke-width', EDGE_STROKE_WIDTH)
  }

  private drawIndividualChildLines(
    group: Selection<SVGGElement, unknown, null, undefined>,
    childrenBarY: number,
    children: PersonNodeData[]
  ): void {
    children.forEach((child) => {
      const childTopY = child.y - NODE_HEIGHT / 2

      // Draw vertical stub from children bar down to child node
      group
        .append('line')
        .attr('class', 'child-stub')
        .attr('x1', child.x)
        .attr('y1', childrenBarY)
        .attr('x2', child.x)
        .attr('y2', childTopY)
        .attr('stroke', EDGE_STROKE_COLOR)
        .attr('stroke-width', EDGE_STROKE_WIDTH)
    })
  }

  private renderNodes(nodes: RenderableNode[]) {
    const group = select(this.transformGroup)

    // Bind data and create positioned groups
    const nodeGroups = group
      .selectAll('g.tree-node-wrapper')
      .data(nodes)
      .enter()
      .append('g')
      .attr('class', (d) => this.getNodeClass(d))
      .attr('transform', (d) => this.getNodeTransform(d))

    // Create foreignObject to embed HTML content in SVG
    const foreignObjects = nodeGroups
      .append('foreignObject')
      .attr('width', (d) => this.getNodeWidth(d))
      .attr('height', (d) => this.getNodeHeight(d))

    // Create appropriate web component based on node type
    foreignObjects.each(function (d: RenderableNode) {
      if (isPersonNode(d)) {
        const personNode = document.createElement('person-node') as unknown as PersonNode
        personNode.data = d
        this.appendChild(personNode)
      } else if (isExpandTreeNode(d)) {
        const expandNode = document.createElement('expand-tree-node') as unknown as ExpandTreeNode
        expandNode.data = d
        this.appendChild(expandNode)
      }
    })
  }

  private getNodeClass(node: RenderableNode): string {
    if (isPersonNode(node)) return 'person-node-wrapper'
    if (isExpandTreeNode(node)) return 'expand-node-wrapper'
    return 'tree-node-wrapper'
  }

  private getNodeTransform(node: RenderableNode): string {
    const width = this.getNodeWidth(node)
    const height = this.getNodeHeight(node)
    return `translate(${node.x - width / 2}, ${node.y - height / 2})`
  }

  private getNodeWidth(node: RenderableNode): number {
    if (isPersonNode(node)) return NODE_WIDTH
    if (isExpandTreeNode(node)) return EXPAND_NODE_WIDTH
    return 0
  }

  private getNodeHeight(node: RenderableNode): number {
    if (isPersonNode(node)) return NODE_HEIGHT
    if (isExpandTreeNode(node)) return EXPAND_NODE_HEIGHT
    return 0
  }
}
