import { select } from 'd3-selection'
import type { ZoomBehavior } from 'd3-zoom'

const CANVAS_ID = 'tree-canvas'
const TRANSFORM_GROUP_ID = 'tree-transform-group'

export class TreeCanvas extends HTMLElement {
  private svg: SVGSVGElement | null = null
  private transformGroup: SVGGElement | null = null

  connectedCallback() {
    this.render()
  }

  getTransformGroup(): SVGGElement | null {
    return this.transformGroup
  }

  getSvgSelection() {
    if (!this.svg) return null
    return select(this.svg)
  }

  attachZoomBehavior(zoomBehavior: ZoomBehavior<SVGSVGElement, unknown>) {
    if (!this.svg) return

    select(this.svg).call(zoomBehavior)
  }

  private render() {
    this.style.display = 'block'
    this.style.width = '100%'
    this.style.height = '100%'

    this.innerHTML = `
      <svg id="${CANVAS_ID}">
        <g id="${TRANSFORM_GROUP_ID}"></g>
      </svg>
    `

    this.svg = this.querySelector(`#${CANVAS_ID}`)
    this.transformGroup = this.querySelector(`#${TRANSFORM_GROUP_ID}`)

    if (this.svg) {
      this.svg.style.width = '100%'
      this.svg.style.height = '100%'
      this.svg.style.display = 'block'
    }
  }
}

customElements.define('tree-canvas', TreeCanvas)
