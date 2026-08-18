import { escapeHtml } from '../escape_html'
/**
 * Toast notification component - positioned absolutely in upper right corner.
 * Auto-dismisses after a configurable timeout.
 */
export class Toast extends HTMLElement {
  private static readonly DEFAULT_DURATION = 3000 // 3 seconds
  private static readonly ANIMATION_DURATION = 300 // 0.3 seconds
  private timeoutId: number | null = null

  constructor() {
    super()
  }

  /**
   * Show a toast notification.
   *
   * @param config - Toast configuration
   */
  show(config: ToastConfig) {
    this.render(config)
    this.applyStyles()

    // Trigger slide-in animation
    requestAnimationFrame(() => {
      this.style.transform = 'translateX(0)'
      this.style.opacity = '1'
    })

    // Auto-dismiss after duration
    const duration = config.duration ?? Toast.DEFAULT_DURATION
    if (duration > 0) {
      this.timeoutId = window.setTimeout(() => {
        this.hide()
      }, duration)
    }
  }

  /**
   * Hide the toast with slide-out animation.
   */
  hide() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }

    // Slide out
    this.style.transform = 'translateX(120%)'
    this.style.opacity = '0'

    // Remove from DOM after animation
    setTimeout(() => {
      this.remove()
    }, Toast.ANIMATION_DURATION)
  }

  private render(config: ToastConfig) {
    const icon = this.getIcon(config.type || 'info')
    const bgColor = this.getBackgroundColor(config.type || 'info')

    this.innerHTML = `
      <div class="toast-container" data-type="${config.type || 'info'}">
        <div class="toast-icon">${icon}</div>
        <div class="toast-content">
          ${config.title ? `<div class="toast-title">${escapeHtml(config.title)}</div>` : ''}
          <div class="toast-message">${escapeHtml(config.message)}</div>
        </div>
        ${config.showCloseButton !== false ? '<button class="toast-close" type="button" aria-label="Close">&times;</button>' : ''}
      </div>
    `

    // Set background color
    const container = this.querySelector('.toast-container') as HTMLElement
    if (container) {
      container.style.background = bgColor
    }

    this.attachEventListeners()
  }

  private applyStyles() {
    // Component styles (positioned absolutely in upper right)
    this.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 9999;
      transform: translateX(120%);
      opacity: 0;
      transition: transform ${Toast.ANIMATION_DURATION}ms ease-out,
                  opacity ${Toast.ANIMATION_DURATION}ms ease-out;
    `

    // Inject global toast styles if not already present
    const styleId = 'toast-notification-styles'
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style')
      style.id = styleId
      style.textContent = `
        .toast-container {
          display: flex;
          align-items: flex-start;
          gap: 12px;
          padding: 16px;
          border-radius: 8px;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
          min-width: 300px;
          max-width: 400px;
          color: white;
        }

        .toast-icon {
          font-size: 24px;
          flex-shrink: 0;
          line-height: 1;
        }

        .toast-content {
          flex: 1;
          min-width: 0;
        }

        .toast-title {
          font-weight: 600;
          font-size: 15px;
          margin-bottom: 4px;
        }

        .toast-message {
          font-size: 14px;
          opacity: 0.95;
          word-wrap: break-word;
        }

        .toast-close {
          background: none;
          border: none;
          color: white;
          font-size: 24px;
          line-height: 1;
          cursor: pointer;
          padding: 0;
          width: 24px;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 4px;
          transition: background 0.2s;
          flex-shrink: 0;
          opacity: 0.8;
        }

        .toast-close:hover {
          background: rgba(255, 255, 255, 0.2);
          opacity: 1;
        }
      `
      document.head.appendChild(style)
    }
  }

  private attachEventListeners() {
    const closeBtn = this.querySelector('.toast-close') as HTMLButtonElement
    closeBtn?.addEventListener('click', () => this.hide())
  }

  private getIcon(type: ToastType): string {
    switch (type) {
      case 'success':
        return '✓'
      case 'error':
        return '✕'
      case 'warning':
        return '⚠'
      case 'info':
      default:
        return 'ℹ'
    }
  }

  private getBackgroundColor(type: ToastType): string {
    switch (type) {
      case 'success':
        return '#10b981' // green-500
      case 'error':
        return '#ef4444' // red-500
      case 'warning':
        return '#f59e0b' // amber-500
      case 'info':
      default:
        return '#3b82f6' // blue-500
    }
  }
}

export type ToastType = 'success' | 'error' | 'warning' | 'info'

export interface ToastConfig {
  /** Type of toast (affects color and icon) */
  type?: ToastType

  /** Optional title text (bold) */
  title?: string

  /** Main message text */
  message: string

  /** Duration in milliseconds (0 = no auto-dismiss, default: 3000) */
  duration?: number

  /** Show close button (default: true) */
  showCloseButton?: boolean
}

// Register the custom element
customElements.define('toast-notification', Toast)

/**
 * Helper function to show a toast notification.
 * Creates a new toast element and appends it to the body.
 */
export function showToast(config: ToastConfig): Toast {
  const toast = document.createElement('toast-notification') as Toast
  document.body.appendChild(toast)
  toast.show(config)
  return toast
}
