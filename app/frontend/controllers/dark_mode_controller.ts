import { Controller } from '@hotwired/stimulus'

const STORAGE_KEY = 'theme'

export function prefersDark(): boolean {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (stored) return stored === 'dark'
  return window.matchMedia('(prefers-color-scheme: dark)').matches
}

// Applied on import — before Stimulus connects — so the theme is set as early
// as the old shared/darkMode module did and the flash window stays minimal.
document.documentElement.classList.toggle('dark', prefersDark())

export default class extends Controller {
  toggle() {
    const dark = document.documentElement.classList.toggle('dark')
    localStorage.setItem(STORAGE_KEY, dark ? 'dark' : 'light')
  }
}
