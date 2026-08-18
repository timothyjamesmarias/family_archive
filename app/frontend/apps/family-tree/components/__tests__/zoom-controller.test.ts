import { describe, it, expect, beforeEach, vi } from 'vitest'
import { select } from 'd3-selection'
import { ZoomController } from '../zoom-controller'

describe('ZoomController', () => {
  let svg: SVGSVGElement
  let transformGroup: SVGGElement
  let svgSelection: ReturnType<typeof select<SVGSVGElement, unknown>>

  beforeEach(() => {
    document.body.innerHTML = '<div id="test-container"></div>'
    const container = document.getElementById('test-container')!

    svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
    svg.setAttribute('width', '800')
    svg.setAttribute('height', '600')

    transformGroup = document.createElementNS('http://www.w3.org/2000/svg', 'g')
    transformGroup.setAttribute('id', 'transform-group')

    svg.appendChild(transformGroup)
    container.appendChild(svg)

    svgSelection = select(svg)
  })

  it('should initialize with default transform', () => {
    new ZoomController(svgSelection, transformGroup)

    const transform = transformGroup.getAttribute('transform')
    expect(transform).toBeTruthy()
  })

  it('should call onZoomChange callback when zoom occurs', () => {
    const onZoomChange = vi.fn()

    new ZoomController(svgSelection, transformGroup, { onZoomChange })

    expect(onZoomChange).toHaveBeenCalled()
  })

  it('should pass transform data to callback', () => {
    const onZoomChange = vi.fn()

    new ZoomController(svgSelection, transformGroup, { onZoomChange })

    expect(onZoomChange).toHaveBeenCalledWith(
      expect.objectContaining({
        x: expect.any(Number),
        y: expect.any(Number),
        scale: expect.any(Number),
      })
    )
  })

  it('should initialize with scale of 1', () => {
    const onZoomChange = vi.fn()

    new ZoomController(svgSelection, transformGroup, { onZoomChange })

    expect(onZoomChange).toHaveBeenCalledWith(
      expect.objectContaining({
        scale: 1,
      })
    )
  })

  it('should reset zoom to identity transform', async () => {
    const onZoomChange = vi.fn()
    const controller = new ZoomController(svgSelection, transformGroup, { onZoomChange })

    onZoomChange.mockClear()
    controller.reset(svgSelection)

    await new Promise((resolve) => setTimeout(resolve, 800))

    expect(onZoomChange).toHaveBeenCalledWith(
      expect.objectContaining({
        x: 0,
        y: 0,
        scale: 1,
      })
    )
  })
})
