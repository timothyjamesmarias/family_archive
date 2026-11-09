import { Controller } from '@hotwired/stimulus'

// Set globally by @hotwired/turbo-rails, which ships no types.
declare const Turbo: { visit(location: string, options: object): void }

// Says where the annotation popover goes and when it closes. The form is
// server-rendered into the annotation_form frame; nothing here builds HTML.
export default class AnnotationEditorController extends Controller {
  static targets = ['frame', 'stage', 'image']
  static values = { newUrl: String }

  declare readonly frameTarget: HTMLElement
  declare readonly stageTarget: HTMLElement
  declare readonly imageTarget: HTMLElement
  declare readonly newUrlValue: string

  place(event: MouseEvent) {
    const image = (event.currentTarget as HTMLElement).getBoundingClientRect()
    const url = new URL(this.newUrlValue, window.location.href)
    url.searchParams.set('x', String(fraction(event.clientX - image.left, image.width)))
    url.searchParams.set('y', String(fraction(event.clientY - image.top, image.height)))
    this.position(event.clientX, event.clientY)
    this.frameTarget.setAttribute('src', url.toString())
  }

  // "Add annotation" places the new dot at the photo's centre; its own form
  // loads the new form into the frame.
  center() {
    const image = this.imageTarget.getBoundingClientRect()
    this.position(image.left + image.width / 2, image.top + image.height / 2)
  }

  // The marker's own link loads the edit form into the frame.
  anchor(event: Event) {
    const marker = (event.currentTarget as HTMLElement).getBoundingClientRect()
    this.position(marker.left, marker.bottom)
  }

  close() {
    this.frameTarget.removeAttribute('src')
    this.frameTarget.replaceChildren()
  }

  dismiss(event: Event) {
    if (!this.stageTarget.contains(event.target as Node)) this.close()
  }

  // Forms submit inside the frame so a 422 stays there. A save redirects to
  // the editor page, which the frame has already fetched; rendering that same
  // response as a replace visit morphs the page and shows its flash. Other
  // submissions (loading the new form) don't redirect and are left alone.
  async refresh(event: CustomEvent) {
    const { success, fetchResponse } = event.detail
    if (!success || !fetchResponse.redirected) return
    const responseHTML = await fetchResponse.responseHTML
    Turbo.visit(fetchResponse.location.href, {
      action: 'replace',
      response: { statusCode: fetchResponse.statusCode, redirected: true, responseHTML },
    })
  }

  // Offsets are from the stage's padding box (inside its border), which is
  // what absolute positioning measures from. Clamped so the popover never
  // spills past the panel's edge.
  private position(clientX: number, clientY: number) {
    const stage = this.stageTarget
    const origin = stage.getBoundingClientRect()
    const left = Math.min(clientX - origin.left - stage.clientLeft, stage.clientWidth - this.frameTarget.offsetWidth)
    this.frameTarget.style.left = `${Math.max(0, left)}px`
    this.frameTarget.style.top = `${clientY - origin.top - stage.clientTop + 10}px`
  }
}

// Inverse of the marker's `left: x * 100%`. Clamped: a click on the border can
// land a hair outside the image, and a marker beyond it would render off it.
function fraction(offset: number, size: number): number {
  return size === 0 ? 0 : Math.min(1, Math.max(0, offset / size))
}
