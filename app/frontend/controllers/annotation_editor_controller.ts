import { Controller } from '@hotwired/stimulus'

// Set globally by @hotwired/turbo-rails, which ships no types.
declare const Turbo: { visit(location: string, options: object): void }

// Says where the annotation popover goes and when it closes. The form is
// server-rendered into the annotation_form frame; nothing here builds HTML.
export default class AnnotationEditorController extends Controller {
  static targets = ['frame', 'stage']
  static values = { newUrl: String }

  declare readonly frameTarget: HTMLElement
  declare readonly stageTarget: HTMLElement
  declare readonly newUrlValue: string

  place(event: MouseEvent) {
    const image = (event.currentTarget as HTMLElement).getBoundingClientRect()
    const url = new URL(this.newUrlValue, window.location.href)
    url.searchParams.set('x', String(fraction(event.clientX - image.left, image.width)))
    url.searchParams.set('y', String(fraction(event.clientY - image.top, image.height)))
    this.position(event.clientX, event.clientY)
    this.frameTarget.setAttribute('src', url.toString())
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

  // The form submits inside the frame so a 422 stays there. On success the
  // frame has already fetched the redirected editor page; rendering that same
  // response as a replace visit morphs the page and shows its flash.
  async refresh(event: CustomEvent) {
    const { success, fetchResponse } = event.detail
    if (!success) return
    const responseHTML = await fetchResponse.responseHTML
    Turbo.visit(fetchResponse.location.href, {
      action: 'replace',
      response: { statusCode: fetchResponse.statusCode, redirected: true, responseHTML },
    })
  }

  private position(clientX: number, clientY: number) {
    const origin = this.stageTarget.getBoundingClientRect()
    this.frameTarget.style.left = `${clientX - origin.left}px`
    this.frameTarget.style.top = `${clientY - origin.top + 10}px`
  }
}

// Inverse of the marker's `left: x * 100%`. Clamped: a click on the border can
// land a hair outside the image, and a marker beyond it would render off it.
function fraction(offset: number, size: number): number {
  return size === 0 ? 0 : Math.min(1, Math.max(0, offset / size))
}
