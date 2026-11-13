import { Controller } from '@hotwired/stimulus'

const MIN_SCALE = 0.1
const MAX_SCALE = 3
const STEP = 1.25

// Pan and zoom for the family-tree stage, the way the v1 canvas behaved: the
// stage carries a translate/scale transform, the wheel zooms about the
// pointer, dragging anywhere pans, two fingers pinch, the buttons zoom about
// the centre (the canvas is touch-action: none, so the page never zooms). The
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

  // Every pointer currently down on the canvas, in viewport coordinates. One
  // finger or a mouse button pans; two fingers pan by their midpoint and zoom
  // by their spread.
  private pointers = new Map<number, { x: number; y: number }>()

  // Pointer and wheel handlers are wired as actions on the viewport markup,
  // not here: a frame swap replaces the viewport, and actions come with it.

  // A save replaces the whole page, so the view also lives in sessionStorage
  // (one per chart). Restored in initialize: target callbacks, which render,
  // run before connect.
  initialize() {
    try {
      const saved = sessionStorage.getItem(this.storageKey)
      if (!saved) return
      const { x, y, scale } = JSON.parse(saved)
      this.xValue = x
      this.yValue = y
      this.scaleValue = scale
    } catch {
      // Storage unavailable or unreadable: start at the default view.
    }
  }

  // A frame swap brings a new stage; show it where the old one was, then
  // bring the card named in the URL into view, since the page cannot scroll
  // a transformed stage to an anchor itself.
  stageTargetConnected() {
    this.render()
    const anchored = location.hash && document.getElementById(decodeURIComponent(location.hash.slice(1)))
    if (anchored && this.stageTarget.contains(anchored)) this.centreOn(anchored)
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

  wheel(event: WheelEvent) {
    event.preventDefault()
    const factor = Math.exp(-event.deltaY * (event.deltaMode === 1 ? 0.05 : event.deltaMode ? 1 : 0.002))
    const rect = this.viewportTarget.getBoundingClientRect()
    this.zoomAbout(this.scaleValue * factor, { x: event.clientX - rect.left, y: event.clientY - rect.top })
  }

  // Links, buttons and menus on a card still click; anything else on the
  // canvas drags. Only the primary button: a right-click keeps its context menu.
  startDrag(event: PointerEvent) {
    if (event.button !== 0) return
    if ((event.target as HTMLElement).closest('a, button, details')) return
    this.pointers.set(event.pointerId, this.viewportPoint(event))
    try {
      this.viewportTarget.setPointerCapture(event.pointerId)
    } catch {
      // A synthetic pointer (tests) has no capture; moves still arrive.
    }
  }

  // Pan by how far the pointers' midpoint moved, then zoom by how much the
  // first two spread apart, about that midpoint. With one pointer the spread
  // is zero and this is a plain drag.
  moveDrag(event: PointerEvent) {
    if (!this.pointers.has(event.pointerId)) return
    const before = this.gesture()
    this.pointers.set(event.pointerId, this.viewportPoint(event))
    const after = this.gesture()
    this.set(this.xValue + after.x - before.x, this.yValue + after.y - before.y, this.scaleValue)
    if (before.spread > 0 && after.spread > 0) this.zoomAbout((this.scaleValue * after.spread) / before.spread, after)
  }

  endDrag(event: PointerEvent) {
    this.pointers.delete(event.pointerId)
  }

  private gesture() {
    const points = [...this.pointers.values()]
    const x = points.reduce((sum, p) => sum + p.x, 0) / points.length
    const y = points.reduce((sum, p) => sum + p.y, 0) / points.length
    const spread = points.length > 1 ? Math.hypot(points[1].x - points[0].x, points[1].y - points[0].y) : 0
    return { x, y, spread }
  }

  private viewportPoint(event: PointerEvent) {
    const rect = this.viewportTarget.getBoundingClientRect()
    return { x: event.clientX - rect.left, y: event.clientY - rect.top }
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

  private set(x: number, y: number, scale: number) {
    this.xValue = x
    this.yValue = y
    this.scaleValue = scale
    this.render()
    try {
      sessionStorage.setItem(this.storageKey, JSON.stringify({ x, y, scale }))
    } catch {
      // Private mode or a full store: the view just won't survive a save.
    }
  }

  private get storageKey() {
    return `tree-zoom:${location.pathname}`
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
