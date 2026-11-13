import { Controller } from '@hotwired/stimulus'

const MIN_SCALE = 0.1
const MAX_SCALE = 3
const STEP = 1.25

// Pan and zoom for the family-tree stage, the way the v1 canvas behaved: the
// stage carries a translate/scale transform, the wheel zooms about the
// pointer, dragging anywhere pans, the buttons zoom about the centre. The
// view lives in values on the frame, which Turbo keeps across a frame swap,
// so expanding a card does not move the chart under you.
export default class TreeZoomController extends Controller {
  static targets = ['viewport', 'stage', 'level', 'root']
  static values = {
    x: { type: Number, default: 0 },
    y: { type: Number, default: 0 },
    scale: { type: Number, default: 1 },
  }

  declare readonly viewportTarget: HTMLElement
  declare readonly stageTarget: HTMLElement
  declare readonly levelTarget: HTMLElement
  declare readonly hasRootTarget: boolean
  declare readonly rootTarget: HTMLElement
  declare xValue: number
  declare yValue: number
  declare scaleValue: number

  private drag: { pointerX: number; pointerY: number; x: number; y: number } | null = null

  connect() {
    this.viewportTarget.addEventListener('wheel', this.wheel, { passive: false })
    this.viewportTarget.addEventListener('pointerdown', this.startDrag)
    this.viewportTarget.addEventListener('pointermove', this.moveDrag)
    this.viewportTarget.addEventListener('pointerup', this.endDrag)
    this.viewportTarget.addEventListener('pointercancel', this.endDrag)
  }

  disconnect() {
    this.viewportTarget.removeEventListener('wheel', this.wheel)
    this.viewportTarget.removeEventListener('pointerdown', this.startDrag)
    this.viewportTarget.removeEventListener('pointermove', this.moveDrag)
    this.viewportTarget.removeEventListener('pointerup', this.endDrag)
    this.viewportTarget.removeEventListener('pointercancel', this.endDrag)
  }

  // A frame swap brings a new stage; show it where the old one was, then
  // bring the card named in the URL into view, since the page cannot scroll
  // a transformed stage to an anchor itself.
  stageTargetConnected() {
    this.render()
    const anchored = location.hash && this.stageTarget.querySelector<HTMLElement>(location.hash)
    if (anchored) this.centreOn(anchored)
  }

  in() {
    this.zoomAbout(this.scaleValue * STEP, this.viewportCentre())
  }

  out() {
    this.zoomAbout(this.scaleValue / STEP, this.viewportCentre())
  }

  // Offset sizes ignore the transform, so the stage reports its true size.
  fit() {
    const { clientWidth, clientHeight } = this.viewportTarget
    const { offsetWidth, offsetHeight } = this.stageTarget
    const scale = this.clamp(Math.min(clientWidth / offsetWidth, clientHeight / offsetHeight, 1))
    this.set((clientWidth - offsetWidth * scale) / 2, (clientHeight - offsetHeight * scale) / 2, scale)
  }

  centre() {
    if (this.hasRootTarget) this.centreOn(this.rootTarget)
  }

  private wheel = (event: WheelEvent) => {
    event.preventDefault()
    const factor = Math.exp(-event.deltaY * (event.deltaMode === 1 ? 0.05 : event.deltaMode ? 1 : 0.002))
    const rect = this.viewportTarget.getBoundingClientRect()
    this.zoomAbout(this.scaleValue * factor, { x: event.clientX - rect.left, y: event.clientY - rect.top })
  }

  // Scale while keeping the stage point under `about` (viewport coordinates) still.
  private zoomAbout(scale: number, about: { x: number; y: number }) {
    const next = this.clamp(scale)
    const ratio = next / this.scaleValue
    this.set(about.x - (about.x - this.xValue) * ratio, about.y - (about.y - this.yValue) * ratio, next)
  }

  private centreOn(card: HTMLElement) {
    const centre = this.viewportCentre()
    const cardX = card.offsetLeft + card.offsetWidth / 2
    const cardY = card.offsetTop + card.offsetHeight / 2
    this.set(centre.x - cardX * this.scaleValue, centre.y - cardY * this.scaleValue, this.scaleValue)
  }

  // Links on a card still click; anything else on the canvas drags.
  private startDrag = (event: PointerEvent) => {
    if ((event.target as HTMLElement).closest('a, button')) return
    this.drag = { pointerX: event.clientX, pointerY: event.clientY, x: this.xValue, y: this.yValue }
    this.viewportTarget.setPointerCapture(event.pointerId)
  }

  private moveDrag = (event: PointerEvent) => {
    if (!this.drag) return
    this.set(
      this.drag.x + (event.clientX - this.drag.pointerX),
      this.drag.y + (event.clientY - this.drag.pointerY),
      this.scaleValue,
    )
  }

  private endDrag = () => {
    this.drag = null
  }

  private set(x: number, y: number, scale: number) {
    this.xValue = x
    this.yValue = y
    this.scaleValue = scale
    this.render()
  }

  private render() {
    this.stageTarget.style.transform = `translate(${this.xValue}px, ${this.yValue}px) scale(${this.scaleValue})`
    this.levelTarget.textContent = `${Math.round(this.scaleValue * 100)}%`
  }

  private viewportCentre() {
    return { x: this.viewportTarget.clientWidth / 2, y: this.viewportTarget.clientHeight / 2 }
  }

  private clamp(scale: number) {
    return Math.min(Math.max(scale, MIN_SCALE), MAX_SCALE)
  }
}
