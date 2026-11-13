import { Controller } from '@hotwired/stimulus'

// Set globally by @hotwired/turbo-rails, which ships no types.
declare const Turbo: { visit(location: string, options: object): void }

// The chart's edit dialog. Menu links load their form into the tree_form
// frame inside a <dialog>; the frame arriving opens it. Forms submit inside
// the frame, so a 422 stays in the dialog; a save redirects to the chart,
// and that response is replayed as a replace visit so the page shows the
// change and its flash. Closing empties the frame.
export default class TreeDialogController extends Controller {
  static targets = ['dialog', 'frame']

  declare readonly dialogTarget: HTMLDialogElement
  declare readonly frameTarget: HTMLElement

  open() {
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  clear() {
    this.frameTarget.removeAttribute('src')
    this.frameTarget.replaceChildren()
  }

  async refresh(event: CustomEvent) {
    const { success, fetchResponse } = event.detail
    if (!success || !fetchResponse.redirected) return
    const responseHTML = await fetchResponse.responseHTML
    this.close()
    Turbo.visit(fetchResponse.location.href, {
      action: 'replace',
      response: { statusCode: fetchResponse.statusCode, redirected: true, responseHTML },
    })
  }
}
