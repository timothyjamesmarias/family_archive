import { Controller } from '@hotwired/stimulus'

// Zoom and pan for the family-tree stage. CSS `zoom` scales the stage and the
// scroll extents follow, so panning is plain scrolling, by scrollbar or by
// dragging the canvas. The stage's unscaled size comes from the server so
// "fit" needs no measuring.
export default class TreeZoomController extends Controller {
  static targets = ['viewport', 'stage', 'level', 'root']
  static values = { level: { type: Number, default: 1 }, width: Number, height: Number }

  declare readonly viewportTarget: HTMLElement
  declare readonly stageTarget: HTMLElement
  declare readonly levelTarget: HTMLElement
  declare readonly hasRootTarget: boolean
  declare readonly rootTarget: HTMLElement
  declare levelValue: number
  declare readonly widthValue: number
  declare readonly heightValue: number

  private dragFrom: { x: number; y: number; left: number; top: number } | null = null

  connect() {
    this.viewportTarget.addEventListener('pointerdown', this.startDrag)
    this.viewportTarget.addEventListener('pointermove', this.drag)
    this.viewportTarget.addEventListener('pointerup', this.endDrag)
    this.viewportTarget.addEventListener('pointercancel', this.endDrag)
  }

  disconnect() {
    this.viewportTarget.removeEventListener('pointerdown', this.startDrag)
    this.viewportTarget.removeEventListener('pointermove', this.drag)
    this.viewportTarget.removeEventListener('pointerup', this.endDrag)
    this.viewportTarget.removeEventListener('pointercancel', this.endDrag)
  }

  in() {
    this.levelValue = Math.min(this.levelValue * 1.25, 3)
  }

  out() {
    this.levelValue = Math.max(this.levelValue / 1.25, 0.2)
  }

  fit() {
    const { clientWidth, clientHeight } = this.viewportTarget
    this.levelValue = Math.min(clientWidth / this.widthValue, clientHeight / this.heightValue, 1)
  }

  centre() {
    if (this.hasRootTarget) this.rootTarget.scrollIntoView({ block: 'center', inline: 'center' })
  }

  levelValueChanged() {
    this.stageTarget.style.zoom = String(this.levelValue)
    this.levelTarget.textContent = `${Math.round(this.levelValue * 100)}%`
  }

  // Dragging starts on the canvas itself, never on a card or its links, so
  // clicks and text selection on cards keep working.
  private startDrag = (event: PointerEvent) => {
    if ((event.target as HTMLElement).closest('.tree-card')) return
    this.dragFrom = {
      x: event.clientX,
      y: event.clientY,
      left: this.viewportTarget.scrollLeft,
      top: this.viewportTarget.scrollTop,
    }
    this.viewportTarget.setPointerCapture(event.pointerId)
  }

  private drag = (event: PointerEvent) => {
    if (!this.dragFrom) return
    this.viewportTarget.scrollLeft = this.dragFrom.left - (event.clientX - this.dragFrom.x)
    this.viewportTarget.scrollTop = this.dragFrom.top - (event.clientY - this.dragFrom.y)
  }

  private endDrag = () => {
    this.dragFrom = null
  }
}
