import { Controller } from '@hotwired/stimulus'

const STORAGE_KEY = 'theme'

export function prefersDark(): boolean {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (stored) return stored === 'dark'
  return window.matchMedia('(prefers-color-scheme: dark)').matches
}

// The pre-paint application lives in shared/_theme_boot.html.erb (inline in
// both layouts — a deferred module runs too late and flashes). This re-apply
// on import only covers a page that lost the boot script.
document.documentElement.classList.toggle('dark', prefersDark())

export default class extends Controller {
  toggle() {
    const dark = document.documentElement.classList.toggle('dark')
    localStorage.setItem(STORAGE_KEY, dark ? 'dark' : 'light')
  }
}
