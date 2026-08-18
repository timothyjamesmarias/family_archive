/**
 * Mobile menu toggle functionality
 */

class MobileMenu {
  private menu: HTMLElement | null = null
  private button: HTMLElement | null = null
  private hamburgerIcon: HTMLElement | null = null
  private closeIcon: HTMLElement | null = null
  private isOpen = false

  constructor() {
    this.init()
  }

  private init(): void {
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.setup())
    } else {
      this.setup()
    }
  }

  private setup(): void {
    this.menu = document.getElementById('mobile-menu')
    this.button = document.getElementById('mobile-menu-button')
    this.hamburgerIcon = document.getElementById('hamburger-icon')
    this.closeIcon = document.getElementById('close-icon')

    if (!this.menu || !this.button || !this.hamburgerIcon || !this.closeIcon) {
      return
    }

    // Close menu when clicking outside
    document.addEventListener('click', (e: MouseEvent) => {
      if (
        this.isOpen &&
        this.menu &&
        this.button &&
        !this.menu.contains(e.target as Node) &&
        !this.button.contains(e.target as Node)
      ) {
        this.close()
      }
    })

    // Close menu on escape key
    document.addEventListener('keydown', (e: KeyboardEvent) => {
      if (e.key === 'Escape' && this.isOpen) {
        this.close()
      }
    })
  }

  public toggle(): void {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  public open(): void {
    if (!this.menu || !this.hamburgerIcon || !this.closeIcon) return

    this.isOpen = true
    this.menu.classList.remove('hidden')
    this.hamburgerIcon.classList.add('hidden')
    this.closeIcon.classList.remove('hidden')
  }

  public close(): void {
    if (!this.menu || !this.hamburgerIcon || !this.closeIcon) return

    this.isOpen = false
    this.menu.classList.add('hidden')
    this.hamburgerIcon.classList.remove('hidden')
    this.closeIcon.classList.add('hidden')
  }
}

// Create global instance
const mobileMenu = new MobileMenu()

// Expose to window for onclick handlers
declare global {
  interface Window {
    mobileMenu: MobileMenu
  }
}

window.mobileMenu = mobileMenu

export default mobileMenu
