import { Controller } from '@hotwired/stimulus'

// Lexxy's <lexxy-editor>; `contents` is its insertion API.
type LexxyEditor = HTMLElement & { contents: { insertHtml(html: string): void } }

// Opens the "Insert embed" dialog and puts the chosen embed into the editor.
// The dialog's frame loads on open and is reset on close, so every insert
// starts from a fresh search.
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
    this.frameTarget.removeAttribute('src')
    this.frameTarget.replaceChildren()
  }

  // The create response is a <template> holding the attachment markup.
  attachmentTargetConnected(template: HTMLTemplateElement) {
    const html = template.innerHTML
    this.close()
    this.editorTarget.contents.insertHtml(html)
  }
}
