import { Controller } from '@hotwired/stimulus'

// Lexxy's <lexxy-editor>; `contents` is its insertion API.
type LexxyEditor = HTMLElement & { contents: { insertHtml(html: string): void } }

// Opens the "Insert embed" dialog and puts the chosen embed into the editor.
// The dialog's frame loads on open and is reset whenever the dialog closes
// (Close, Escape, or an insert), so every insert starts fresh.
export default class EmbedPickerController extends Controller {
  static targets = ['editor', 'dialog', 'frame', 'attachment']

  declare readonly editorTarget: LexxyEditor
  declare readonly dialogTarget: HTMLDialogElement
  declare readonly frameTarget: HTMLElement

  open() {
    this.frameTarget.setAttribute('src', this.frameTarget.dataset.src!)
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  // Bound to the dialog's native `close` event, which Escape fires too.
  reset() {
    this.frameTarget.removeAttribute('src')
    this.frameTarget.replaceChildren()
  }

  // The create response is a <template> holding the attachment markup. One
  // that lands after the dialog was dismissed is a cancelled insert.
  attachmentTargetConnected(template: HTMLTemplateElement) {
    if (!this.dialogTarget.open) return this.reset()

    const html = template.innerHTML
    this.close()
    this.editorTarget.contents.insertHtml(html)
  }
}
