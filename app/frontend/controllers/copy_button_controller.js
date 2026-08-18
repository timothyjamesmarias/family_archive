import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String, confirmDuration: { type: Number, default: 1500 } }
  static targets = [ "label" ]

  connect() {
    this.originalLabel = this.labelTarget.textContent
  }

  disconnect() {
    clearTimeout(this.resetTimeout)
  }

  async copy() {
    await navigator.clipboard.writeText(this.textValue)

    this.labelTarget.textContent = "Copied"
    clearTimeout(this.resetTimeout)
    this.resetTimeout = setTimeout(() => {
      this.labelTarget.textContent = this.originalLabel
    }, this.confirmDurationValue)
  }
}