import { store, EditMode } from '../../../shared/store'

/**
 * Web component for toggling between VIEW and EDIT modes.
 * Only visible when user is authenticated.
 */
export class EditModeToggle extends HTMLElement {
  private unsubscribe: (() => void) | null = null

  constructor() {
    super()
  }

  connectedCallback() {
    // Subscribe to store changes
    this.unsubscribe = store.subscribe((state) => {
      this.render(state.isAuthenticated, state.mode)
    })
  }

  disconnectedCallback() {
    // Clean up subscription
    if (this.unsubscribe) {
      this.unsubscribe()
      this.unsubscribe = null
    }
  }

  private render(isAuthenticated: boolean, mode: EditMode) {
    // Hide if not authenticated
    if (!isAuthenticated) {
      this.innerHTML = ''
      this.style.display = 'none'
      return
    }

    this.style.display = 'block'

    const isEditMode = mode === EditMode.EDIT
    const buttonText = isEditMode ? 'Exit Edit Mode' : 'Enter Edit Mode'
    const modeLabel = isEditMode ? 'Edit Mode' : 'View Mode'
    const modeClass = isEditMode ? 'edit' : 'view'

    this.innerHTML = `
      <div class="edit-mode-toggle-container ${modeClass}">
        <div class="edit-mode-status">
          <span class="edit-mode-indicator"></span>
          <span class="edit-mode-label">${modeLabel}</span>
        </div>
        <button class="edit-mode-button" type="button">
          ${buttonText}
        </button>
      </div>
    `

    this.applyStyles()
    this.attachEventListeners()
  }

  private applyStyles() {
    // Component container styles - positioned relative to parent container
    this.style.cssText = `
      position: absolute;
      bottom: 20px;
      right: 20px;
      z-index: 1000;
    `

    // Inject styles for inner elements
    const styleId = 'edit-mode-toggle-styles'
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style')
      style.id = styleId
      style.textContent = `
        .edit-mode-toggle-container {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 10px 16px;
          background: white;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
          transition: all 0.2s ease;
        }

        .edit-mode-toggle-container:hover {
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
        }

        .edit-mode-toggle-container.edit {
          background: #fff3e0;
          border: 2px solid #ff9800;
        }

        .edit-mode-toggle-container.view {
          background: #e8f5e9;
          border: 2px solid #4caf50;
        }

        .edit-mode-status {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .edit-mode-indicator {
          display: inline-block;
          width: 10px;
          height: 10px;
          border-radius: 50%;
          transition: background-color 0.2s ease;
        }

        .edit-mode-toggle-container.edit .edit-mode-indicator {
          background-color: #ff9800;
          animation: pulse 2s ease-in-out infinite;
        }

        .edit-mode-toggle-container.view .edit-mode-indicator {
          background-color: #4caf50;
        }

        @keyframes pulse {
          0%, 100% {
            opacity: 1;
          }
          50% {
            opacity: 0.5;
          }
        }

        .edit-mode-label {
          font-size: 14px;
          font-weight: 600;
          color: #333;
        }

        .edit-mode-button {
          padding: 6px 14px;
          font-size: 13px;
          font-weight: 500;
          border: none;
          border-radius: 4px;
          cursor: pointer;
          transition: all 0.2s ease;
          color: white;
        }

        .edit-mode-toggle-container.view .edit-mode-button {
          background-color: #4caf50;
        }

        .edit-mode-toggle-container.view .edit-mode-button:hover {
          background-color: #45a049;
        }

        .edit-mode-toggle-container.edit .edit-mode-button {
          background-color: #ff9800;
        }

        .edit-mode-toggle-container.edit .edit-mode-button:hover {
          background-color: #fb8c00;
        }

        .edit-mode-button:active {
          transform: scale(0.98);
        }

        .edit-mode-button:focus {
          outline: 2px solid #2196f3;
          outline-offset: 2px;
        }
      `
      document.head.appendChild(style)
    }
  }

  private attachEventListeners() {
    const button = this.querySelector('.edit-mode-button') as HTMLButtonElement
    if (button) {
      button.addEventListener('click', () => this.handleToggle())
    }
  }

  private handleToggle() {
    const newMode = store.toggleEditMode()

    // Dispatch custom event for other components to listen to
    this.dispatchEvent(
      new CustomEvent('mode-changed', {
        bubbles: true,
        detail: { mode: newMode },
      })
    )
  }
}

// Register the custom element
customElements.define('edit-mode-toggle', EditModeToggle)
