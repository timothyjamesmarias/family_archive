import { Controller } from '@hotwired/stimulus'

// Keeps the photo's markers and the annotation list in step: selecting
// either side highlights both, the switch hides the markers, and the stage
// can go full screen. Everything is server-rendered; this only syncs state.
export default class PhotoAnnotationsController extends Controller {
  static targets = ['marker', 'row', 'switch', 'stage']

  declare readonly markerTargets: HTMLElement[]
  declare readonly rowTargets: HTMLElement[]
  declare readonly switchTarget: HTMLElement
  declare readonly hasSwitchTarget: boolean
  declare readonly stageTarget: HTMLElement

  select(event: Event) {
    const id = (event.currentTarget as HTMLElement).dataset.annotationId
    const fromMarker = this.markerTargets.includes(event.currentTarget as HTMLElement)

    this.markerTargets.forEach((marker) =>
      marker.classList.toggle('annotation-dot-selected', marker.dataset.annotationId === id))
    this.rowTargets.forEach((row) => {
      const selected = row.dataset.annotationId === id
      row.classList.toggle('annotation-row-selected', selected)
      if (selected && fromMarker) row.scrollIntoView({ block: 'nearest' })
    })
  }

  toggle() {
    if (!this.hasSwitchTarget) return
    const showing = this.switchTarget.getAttribute('aria-checked') !== 'false'
    this.switchTarget.setAttribute('aria-checked', showing ? 'false' : 'true')
    this.markerTargets.forEach((marker) => marker.classList.toggle('hidden', showing))
  }

  fullscreen() {
    this.stageTarget.requestFullscreen?.()
  }
}
