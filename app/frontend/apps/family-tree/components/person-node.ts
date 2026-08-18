import { type PersonNode as PersonNodeData } from '../types/node'
import { store, EditMode } from '../../../shared/store'
import { escapeHtml } from '../../../shared/escape_html'

export const NODE_WIDTH = 180
export const NODE_HEIGHT = 130

/**
 * Web component for rendering a person node in the family tree
 */
export class PersonNode extends HTMLElement {
  private personData: PersonNodeData | null = null
  private unsubscribe: (() => void) | null = null
  private isEditMode: boolean = false

  constructor() {
    super()
  }

  connectedCallback() {
    // Subscribe to edit mode changes
    this.unsubscribe = store.subscribe((state) => {
      const wasEditMode = this.isEditMode
      this.isEditMode = state.mode === EditMode.EDIT

      // Re-render if edit mode changed
      if (wasEditMode !== this.isEditMode && this.personData) {
        this.render()
      }
    })
  }

  disconnectedCallback() {
    // Clean up subscription
    if (this.unsubscribe) {
      this.unsubscribe()
      this.unsubscribe = null
    }
  }

  set data(node: PersonNodeData) {
    this.personData = node
    this.render()
  }

  get data(): PersonNodeData | null {
    return this.personData
  }

  private render() {
    if (!this.personData) return

    const name = this.formatName()
    const birthInfo = this.formatBirthInfo()
    const deathInfo = this.formatDeathInfo()

    this.innerHTML = `
      <div class="person-node-card">
        ${this.isEditMode ? '<button class="person-node-action" type="button" aria-label="Actions">⋮</button>' : ''}
        <div class="person-node-name">${escapeHtml(name)}</div>
        ${birthInfo ? `<div class="person-node-dates">${birthInfo}</div>` : ''}
        ${deathInfo ? `<div class="person-node-dates">${deathInfo}</div>` : ''}
      </div>
    `

    this.applyStyles()
    this.attachEventListeners()
  }

  private formatBirthInfo(): string {
    const { individual } = this.personData!
    if (!individual.birthDate && !individual.birthPlace) return ''

    let result = 'b.'
    if (individual.birthDate) {
      result += ` ${escapeHtml(individual.birthDate)}`
    }
    if (individual.birthPlace) {
      // Add line break if we have both date and place for better readability
      if (individual.birthDate) {
        result += `<br>&nbsp;&nbsp;&nbsp;${escapeHtml(individual.birthPlace)}`
      } else {
        result += ` ${escapeHtml(individual.birthPlace)}`
      }
    }

    return result
  }

  private formatDeathInfo(): string {
    const { individual } = this.personData!
    if (!individual.deathDate && !individual.deathPlace) return ''

    let result = 'd.'
    if (individual.deathDate) {
      result += ` ${escapeHtml(individual.deathDate)}`
    }
    if (individual.deathPlace) {
      // Add line break if we have both date and place for better readability
      if (individual.deathDate) {
        result += `<br>&nbsp;&nbsp;&nbsp;${escapeHtml(individual.deathPlace)}`
      } else {
        result += ` ${escapeHtml(individual.deathPlace)}`
      }
    }

    return result
  }

  private applyStyles() {
    this.style.cssText = `
      display: block;
      width: ${NODE_WIDTH}px;
      height: ${NODE_HEIGHT}px;
    `

    const card = this.querySelector('.person-node-card') as HTMLElement
    if (card) {
      card.style.cssText = `
        position: relative;
        width: 100%;
        height: 100%;
        background: #4f46e5;
        border: 2px solid #312e81;
        border-radius: 8px;
        color: white;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 8px;
        box-sizing: border-box;
        cursor: pointer;
        transition: transform 0.2s, box-shadow 0.2s;
      `
    }

    const actionBtn = this.querySelector('.person-node-action') as HTMLElement
    if (actionBtn) {
      actionBtn.style.cssText = `
        position: absolute;
        top: 4px;
        right: 4px;
        background: rgba(255, 255, 255, 0.2);
        border: none;
        color: white;
        width: 20px;
        height: 20px;
        border-radius: 4px;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 16px;
        line-height: 1;
        padding: 0;
        transition: background 0.2s;
        z-index: 10;
      `

      // Add hover effect
      actionBtn.addEventListener('mouseenter', () => {
        actionBtn.style.background = 'rgba(255, 255, 255, 0.3)'
      })
      actionBtn.addEventListener('mouseleave', () => {
        actionBtn.style.background = 'rgba(255, 255, 255, 0.2)'
      })
    }

    const nameEl = this.querySelector('.person-node-name') as HTMLElement
    if (nameEl) {
      nameEl.style.cssText = `
        font-size: 14px;
        font-weight: bold;
        margin-bottom: 4px;
        text-align: center;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        width: 100%;
      `
    }

    const idEl = this.querySelector('.person-node-id') as HTMLElement
    if (idEl) {
      idEl.style.cssText = `
        font-size: 10px;
        opacity: 0.8;
        text-align: center;
      `
    }

    const sexEl = this.querySelector('.person-node-sex') as HTMLElement
    if (sexEl) {
      sexEl.style.cssText = `
        font-size: 10px;
        opacity: 0.8;
        margin-top: 2px;
        text-align: center;
      `
    }

    const dateEls = this.querySelectorAll<HTMLElement>('.person-node-dates')
    dateEls.forEach((dateEl) => {
      dateEl.style.cssText = `
        font-size: 9px;
        opacity: 0.9;
        margin-top: 3px;
        text-align: left;
        line-height: 1.3;
        width: 100%;
        padding: 0 4px;
        box-sizing: border-box;
      `
    })
  }

  private attachEventListeners() {
    const actionBtn = this.querySelector('.person-node-action') as HTMLButtonElement
    if (actionBtn) {
      actionBtn.addEventListener('click', (e) => this.handleActionClick(e))
    }
  }

  private handleActionClick(e: Event) {
    e.stopPropagation() // Don't trigger card click

    if (!this.personData) return

    // Get the button's position on screen
    const button = e.target as HTMLElement
    const rect = button.getBoundingClientRect()

    // Dispatch custom event with position and individual data
    this.dispatchEvent(
      new CustomEvent('action-menu-open', {
        bubbles: true,
        detail: {
          individualId: this.personData.individual.id,
          position: {
            x: rect.right,
            y: rect.top,
          },
          // Pass metadata if available (from Individual type)
          metadata: this.personData.individual.relationships!,
        },
      })
    )
  }

  private formatName(): string {
    if (!this.personData) return ''

    const { individual } = this.personData
    const parts: string[] = []
    if (individual.givenName) parts.push(individual.givenName)
    if (individual.surname) parts.push(individual.surname)
    return parts.length > 0 ? parts.join(' ') : `Individual ${individual.id}`
  }
}

customElements.define('person-node', PersonNode)
