import { zoom, zoomIdentity } from 'd3-zoom'
import type { Selection } from 'd3-selection'
import type { ZoomBehavior, D3ZoomEvent } from 'd3-zoom'

/** Imported for the side effect: d3-transition augments Selection with
 * `.transition()`, which `reset()` below relies on. */
import 'd3-transition'

const MIN_ZOOM = 0.1
const MAX_ZOOM = 3
const INITIAL_ZOOM = 1

interface ZoomConfig {
  onZoomChange?: (transform: { x: number; y: number; scale: number }) => void
}

export class ZoomController {
  private zoomBehavior: ZoomBehavior<SVGSVGElement, unknown>
  private transformGroup: SVGGElement

  constructor(
    svgSelection: Selection<SVGSVGElement, unknown, null, undefined>,
    transformGroup: SVGGElement,
    config: ZoomConfig = {}
  ) {
    this.transformGroup = transformGroup
    this.zoomBehavior = this.createZoomBehavior(config)
    this.attachToSvg(svgSelection)
    this.initializeTransform(svgSelection)
  }

  reset(svgSelection: Selection<SVGSVGElement, unknown, null, undefined>) {
    svgSelection.transition().duration(750).call(this.zoomBehavior.transform, zoomIdentity)
  }

  private createZoomBehavior(config: ZoomConfig) {
    return zoom<SVGSVGElement, unknown>()
      .scaleExtent([MIN_ZOOM, MAX_ZOOM])
      .on('zoom', (event) => this.handleZoom(event, config))
  }

  private attachToSvg(svgSelection: Selection<SVGSVGElement, unknown, null, undefined>) {
    svgSelection.call(this.zoomBehavior)
  }

  private initializeTransform(svgSelection: Selection<SVGSVGElement, unknown, null, undefined>) {
    svgSelection.call(this.zoomBehavior.transform, zoomIdentity.scale(INITIAL_ZOOM))
  }

  private handleZoom(event: D3ZoomEvent<SVGSVGElement, unknown>, config: ZoomConfig) {
    this.transformGroup.setAttribute('transform', String(event.transform))

    if (config.onZoomChange) {
      config.onZoomChange({
        x: event.transform.x,
        y: event.transform.y,
        scale: event.transform.k,
      })
    }
  }
}
