/**
 * Generic modal component - a "dumb" wrapper for modal dialogs.
 * Handles backdrop, positioning, and close behavior.
 * Content should be provided by the caller.
 */
export class Modal extends HTMLElement {
  private onCloseCallback: (() => void) | null = null
  private isClosing: boolean = false

  constructor() {
    super()
  }

  /**
   * Open the modal with given content.
   *
   * @param config - Modal configuration
   */
  open(config: ModalConfig) {
    this.onCloseCallback = config.onClose || null
    this.render(config)
    this.style.display = 'flex'

    // Focus first input if requested
    if (config.autoFocus !== false) {
      setTimeout(() => {
        const firstInput = this.querySelector('input, textarea, select') as HTMLElement
        firstInput?.focus()
      }, 100)
    }
  }

  /**
   * Close the modal.
   */
  close() {
    if (this.isClosing) return // Prevent double-close
    this.isClosing = true

    // Call the callback before hiding
    const callback = this.onCloseCallback
    this.onCloseCallback = null

    this.style.display = 'none'
    this.innerHTML = ''

    // Call callback after clearing state to prevent circular calls
    if (callback) {
      callback()
    }

    this.isClosing = false
  }

  private render(config: ModalConfig) {
    this.innerHTML = `
      <div class="modal-backdrop"></div>
      <div class="modal-container" style="max-width: ${config.maxWidth || '500px'};">
        ${
          config.showHeader !== false
            ? `
          <div class="modal-header">
            <h2 class="modal-title">${config.title || ''}</h2>
            ${config.showCloseButton !== false ? '<button class="modal-close" type="button" aria-label="Close">&times;</button>' : ''}
          </div>
        `
            : ''
        }
        <div class="modal-content">
          ${config.content || ''}
        </div>
      </div>
    `

    this.applyStyles()
    this.attachEventListeners(config)
  }

  private applyStyles() {
    // Component container styles
    this.style.cssText = `
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      z-index: 2000;
      align-items: center;
      justify-content: center;
    `

    // Inject global modal styles if not already present
    const styleId = 'generic-modal-styles'
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style')
      style.id = styleId
      style.textContent = `
        .modal-backdrop {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: rgba(0, 0, 0, 0.5);
          backdrop-filter: blur(2px);
        }

        .modal-container {
          position: relative;
          background: white;
          border-radius: 12px;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
          max-height: 90vh;
          overflow: hidden;
          display: flex;
          flex-direction: column;
          z-index: 1;
        }

        .modal-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 20px 24px;
          border-bottom: 1px solid #e5e7eb;
          flex-shrink: 0;
        }

        .modal-title {
          margin: 0;
          font-size: 20px;
          font-weight: 600;
          color: #111827;
        }

        .modal-close {
          background: none;
          border: none;
          font-size: 32px;
          line-height: 1;
          color: #6b7280;
          cursor: pointer;
          padding: 0;
          width: 32px;
          height: 32px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 6px;
          transition: all 0.2s;
        }

        .modal-close:hover {
          background: #f3f4f6;
          color: #111827;
        }

        .modal-content {
          padding: 24px;
          overflow-y: auto;
          flex: 1;
        }
      `
      document.head.appendChild(style)
    }
  }

  private attachEventListeners(config: ModalConfig) {
    // Close button
    if (config.showCloseButton !== false) {
      const closeBtn = this.querySelector('.modal-close') as HTMLButtonElement
      closeBtn?.addEventListener('click', () => this.close())
    }

    // Backdrop click (if enabled)
    if (config.closeOnBackdropClick !== false) {
      const backdrop = this.querySelector('.modal-backdrop') as HTMLElement
      backdrop?.addEventListener('click', () => this.close())
    }

    // ESC key to close (if enabled)
    if (config.closeOnEscape !== false) {
      const escListener = (e: KeyboardEvent) => {
        if (e.key === 'Escape') {
          this.close()
          document.removeEventListener('keydown', escListener)
        }
      }
      document.addEventListener('keydown', escListener)
    }
  }
}

export interface ModalConfig {
  /** Modal title (shown in header) */
  title?: string

  /** HTML content to display in modal body */
  content: string

  /** Maximum width of modal (default: 500px) */
  maxWidth?: string

  /** Show the header section (default: true) */
  showHeader?: boolean

  /** Show close button in header (default: true) */
  showCloseButton?: boolean

  /** Close modal when clicking backdrop (default: true) */
  closeOnBackdropClick?: boolean

  /** Close modal when pressing ESC key (default: true) */
  closeOnEscape?: boolean

  /** Auto-focus first input on open (default: true) */
  autoFocus?: boolean

  /** Callback when modal is closed */
  onClose?: () => void
}

// Register the custom element
customElements.define('generic-modal', Modal)
