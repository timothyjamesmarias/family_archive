import { type RelationshipMetadata } from '../types/mutations'
import { Z_INDEX, MENU_PADDING } from '../constants'

/**
 * Action that can be performed on an individual.
 */
export type PersonAction =
  | 'edit'
  | 'delete'
  | 'add-child'
  | 'add-spouse'
  | 'add-parent'
  | 'add-sibling'
  | 'link-existing-parent'

/**
 * Data for opening the action menu.
 */
export interface ActionMenuData {
  individualId: number
  position: { x: number; y: number }
  metadata?: RelationshipMetadata
}

/**
 * Web component for the action menu popup.
 * Displays context menu with available actions for a person.
 */
export class ActionMenuPopup extends HTMLElement {
  private menuData: ActionMenuData | null = null
  private onActionCallback: ((action: PersonAction, individualId: number) => void) | null = null

  constructor() {
    super()
  }

  /**
   * Open the action menu at the specified position.
   *
   * @param data - Menu configuration and position
   * @param onAction - Callback when an action is selected
   */
  open(data: ActionMenuData, onAction: (action: PersonAction, individualId: number) => void) {
    this.menuData = data
    this.onActionCallback = onAction
    this.render()
    this.positionMenu(data.position)
    this.style.display = 'block'

    // Add click-outside listener
    setTimeout(() => {
      document.addEventListener('click', this.handleClickOutside)
      document.addEventListener('keydown', this.handleEscKey)
    }, 0)
  }

  /**
   * Close the action menu.
   */
  close() {
    this.style.display = 'none'
    this.innerHTML = ''
    this.menuData = null
    this.onActionCallback = null

    document.removeEventListener('click', this.handleClickOutside)
    document.removeEventListener('keydown', this.handleEscKey)
  }

  private handleClickOutside = (e: MouseEvent) => {
    if (!this.contains(e.target as Node)) {
      this.close()
    }
  }

  private handleEscKey = (e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      this.close()
    }
  }

  disconnectedCallback() {
    document.removeEventListener('click', this.handleClickOutside)
    document.removeEventListener('keydown', this.handleEscKey)
  }

  private render() {
    if (!this.menuData) return

    const { metadata } = this.menuData

    // Determine which actions are available
    const canAddSibling = metadata ? metadata.childFamilyIds.length > 0 : true
    const canLinkExistingParent = true // Always show for now, we'll validate on the backend

    this.innerHTML = `
      <div class="action-menu">
        <button class="action-item" data-action="edit">
          <span class="action-icon">✏️</span>
          <span class="action-label">Edit Person</span>
        </button>
        <button class="action-item action-delete" data-action="delete">
          <span class="action-icon">🗑️</span>
          <span class="action-label">Delete Person</span>
        </button>
        <div class="action-divider"></div>
        <button class="action-item" data-action="add-child">
          <span class="action-icon">👶</span>
          <span class="action-label">Add Child</span>
        </button>
        <button class="action-item" data-action="add-spouse">
          <span class="action-icon">💑</span>
          <span class="action-label">Add Spouse</span>
        </button>
        <button class="action-item" data-action="add-parent">
          <span class="action-icon">👨</span>
          <span class="action-label">Add Parent</span>
        </button>
        <button
          class="action-item"
          data-action="link-existing-parent"
          ${!canLinkExistingParent ? 'disabled' : ''}
        >
          <span class="action-icon">🔗</span>
          <span class="action-label">Link Existing Parent</span>
        </button>
        <button
          class="action-item"
          data-action="add-sibling"
          ${!canAddSibling ? 'disabled' : ''}
          ${!canAddSibling ? 'title="Person has no parent family"' : ''}
        >
          <span class="action-icon">👥</span>
          <span class="action-label">Add Sibling</span>
        </button>
      </div>
    `

    this.applyStyles()
    this.attachEventListeners()
  }

  private positionMenu(clickPosition: { x: number; y: number }) {
    // Wait for render to get menu dimensions
    requestAnimationFrame(() => {
      const menu = this.querySelector('.action-menu') as HTMLElement
      if (!menu) return

      const menuRect = menu.getBoundingClientRect()
      const viewportWidth = window.innerWidth
      const viewportHeight = window.innerHeight

      let x = clickPosition.x
      let y = clickPosition.y

      // Check if menu fits below
      if (y + menuRect.height + MENU_PADDING < viewportHeight) {
        // Place below
        y = y + MENU_PADDING
      } else if (y - menuRect.height - MENU_PADDING > 0) {
        // Place above
        y = y - menuRect.height - MENU_PADDING
      } else {
        // Center vertically
        y = (viewportHeight - menuRect.height) / 2
      }

      // Check if menu fits to the right
      if (x + menuRect.width + MENU_PADDING < viewportWidth) {
        // Place to the right
        x = x + MENU_PADDING
      } else if (x - menuRect.width - MENU_PADDING > 0) {
        // Place to the left
        x = x - menuRect.width - MENU_PADDING
      } else {
        // Center horizontally
        x = (viewportWidth - menuRect.width) / 2
      }

      // Apply position
      menu.style.left = `${x}px`
      menu.style.top = `${y}px`
    })
  }

  private applyStyles() {
    // Component container styles
    this.style.cssText = `
      display: none;
      position: fixed;
      z-index: ${Z_INDEX.ACTION_MENU};
    `

    // Inject global menu styles
    const styleId = 'action-menu-popup-styles'
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style')
      style.id = styleId
      style.textContent = `
        .action-menu {
          position: fixed;
          background: white;
          border-radius: 8px;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
          padding: 6px 0;
          min-width: 200px;
          animation: menuFadeIn 0.15s ease-out;
        }

        @keyframes menuFadeIn {
          0% {
            opacity: 0;
            transform: scale(0.95);
          }
          100% {
            opacity: 1;
            transform: scale(1);
          }
        }

        .action-item {
          display: flex;
          align-items: center;
          gap: 12px;
          width: 100%;
          padding: 10px 16px;
          background: none;
          border: none;
          text-align: left;
          cursor: pointer;
          transition: background-color 0.15s;
          font-size: 14px;
          color: #333;
        }

        .action-item:hover:not(:disabled) {
          background-color: #f5f5f5;
        }

        .action-item:active:not(:disabled) {
          background-color: #e0e0e0;
        }

        .action-item:disabled {
          opacity: 0.4;
          cursor: not-allowed;
        }

        .action-item.action-delete:hover:not(:disabled) {
          background-color: #ffebee;
          color: #d32f2f;
        }

        .action-icon {
          font-size: 18px;
          line-height: 1;
          flex-shrink: 0;
        }

        .action-label {
          flex: 1;
          font-weight: 500;
        }

        .action-divider {
          height: 1px;
          background: #e0e0e0;
          margin: 6px 0;
        }
      `
      document.head.appendChild(style)
    }
  }

  private attachEventListeners() {
    const actionItems = this.querySelectorAll('.action-item')
    actionItems.forEach((item) => {
      item.addEventListener('click', (e) => {
        const button = e.currentTarget as HTMLButtonElement
        if (button.disabled) return

        const action = button.getAttribute('data-action') as PersonAction
        if (action && this.onActionCallback && this.menuData) {
          this.onActionCallback(action, this.menuData.individualId)
          this.close()
        }
      })
    })
  }
}

// Register the custom element
customElements.define('action-menu-popup', ActionMenuPopup)
