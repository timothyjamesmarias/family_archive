// Dark mode utility
// Handles theme switching and persistence via localStorage

export class DarkModeToggle {
  private readonly storageKey = 'theme'

  constructor() {
    this.init()
  }

  private init() {
    // Check localStorage or system preference
    if (
      localStorage.getItem(this.storageKey) === 'dark' ||
      (!localStorage.getItem(this.storageKey) &&
        window.matchMedia('(prefers-color-scheme: dark)').matches)
    ) {
      this.enable()
    } else {
      this.disable()
    }
  }

  enable() {
    document.documentElement.classList.add('dark')
    localStorage.setItem(this.storageKey, 'dark')
  }

  disable() {
    document.documentElement.classList.remove('dark')
    localStorage.setItem(this.storageKey, 'light')
  }

  toggle() {
    if (document.documentElement.classList.contains('dark')) {
      this.disable()
    } else {
      this.enable()
    }
  }

  isDark(): boolean {
    return document.documentElement.classList.contains('dark')
  }
}

// Initialize dark mode on page load (before content renders to avoid flash)
const darkMode = new DarkModeToggle()

// Make it globally available
declare global {
  interface Window {
    darkMode: DarkModeToggle
  }
}
window.darkMode = darkMode

export default darkMode
