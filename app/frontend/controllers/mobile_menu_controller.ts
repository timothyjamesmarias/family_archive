import { Controller } from '@hotwired/stimulus'

// The masthead's hamburger menu on narrow screens. A click outside the menu
// and its button, or Escape, closes it.
export default class MobileMenuController extends Controller {
  static targets = ['menu', 'button', 'openIcon', 'closeIcon']

  declare readonly menuTarget: HTMLElement
  declare readonly buttonTarget: HTMLElement
  declare readonly openIconTarget: HTMLElement
  declare readonly closeIconTarget: HTMLElement

  toggle() {
    if (this.isOpen) this.close()
    else this.open()
  }

  open() {
    this.menuTarget.classList.remove('hidden')
    this.openIconTarget.classList.add('hidden')
    this.closeIconTarget.classList.remove('hidden')
    this.buttonTarget.setAttribute('aria-expanded', 'true')
  }

  close() {
    this.menuTarget.classList.add('hidden')
    this.openIconTarget.classList.remove('hidden')
    this.closeIconTarget.classList.add('hidden')
    this.buttonTarget.setAttribute('aria-expanded', 'false')
  }

  closeOutside(event: Event) {
    const target = event.target as Node
    if (this.menuTarget.contains(target) || this.buttonTarget.contains(target)) return
    this.close()
  }

  private get isOpen() {
    return !this.menuTarget.classList.contains('hidden')
  }
}
