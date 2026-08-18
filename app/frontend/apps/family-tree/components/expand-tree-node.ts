import { type ExpandTreeNode as ExpandTreeNodeData } from '../types/node'

export const EXPAND_NODE_WIDTH = 140
export const EXPAND_NODE_HEIGHT = 40

/**
 * Web component for rendering an expansion control in the family tree
 * Allows users to load more generations (ancestors or descendants)
 */
export class ExpandTreeNode extends HTMLElement {
  private expandData: ExpandTreeNodeData | null = null

  constructor() {
    super()
  }

  set data(node: ExpandTreeNodeData) {
    this.expandData = node
    this.render()
  }

  get data(): ExpandTreeNodeData | null {
    return this.expandData
  }

  private render() {
    if (!this.expandData) return

    const label = this.getLabel()
    const icon = this.getIcon()

    this.innerHTML = `
      <div class="expand-node-button">
        ${icon} ${label}
      </div>
    `

    this.applyStyles()
    this.attachEventListeners()
  }

  private getLabel(): string {
    if (!this.expandData) return ''
    return this.expandData.direction === 'up' ? 'Show ancestors' : 'Show descendants'
  }

  private getIcon(): string {
    if (!this.expandData) return ''
    return this.expandData.direction === 'up' ? '↑' : '↓'
  }

  private applyStyles() {
    this.style.cssText = `
      display: block;
      width: ${EXPAND_NODE_WIDTH}px;
      height: ${EXPAND_NODE_HEIGHT}px;
    `

    const button = this.querySelector('.expand-node-button') as HTMLElement
    if (button) {
      button.style.cssText = `
        width: 100%;
        height: 100%;
        background: #10b981;
        border: 2px solid #059669;
        border-radius: 6px;
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
        box-sizing: border-box;
        user-select: none;
      `

      button.addEventListener('mouseenter', () => {
        button.style.background = '#059669'
        button.style.transform = 'scale(1.05)'
      })

      button.addEventListener('mouseleave', () => {
        button.style.background = '#10b981'
        button.style.transform = 'scale(1)'
      })

      button.addEventListener('mousedown', () => {
        button.style.transform = 'scale(0.98)'
      })

      button.addEventListener('mouseup', () => {
        button.style.transform = 'scale(1.05)'
      })
    }
  }

  private attachEventListeners() {
    const button = this.querySelector('.expand-node-button') as HTMLElement
    if (!button || !this.expandData) return

    button.addEventListener('click', (e) => {
      e.stopPropagation()
      this.handleExpand()
    })
  }

  private handleExpand() {
    if (!this.expandData) return

    // Dispatch custom event with expansion parameters
    const event = new CustomEvent('expand-tree', {
      detail: {
        individualId: this.expandData.individualId,
        direction: this.expandData.direction,
        generations: this.expandData.generations,
      },
      bubbles: true,
      composed: true,
    })

    this.dispatchEvent(event)
  }
}

customElements.define('expand-tree-node', ExpandTreeNode)
