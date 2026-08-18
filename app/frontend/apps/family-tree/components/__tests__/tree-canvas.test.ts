import { describe, it, expect, beforeEach } from 'vitest'
import '../tree-canvas'
import { type TreeCanvas } from '../tree-canvas'

describe('TreeCanvas', () => {
  let canvas: TreeCanvas

  beforeEach(async () => {
    canvas = document.createElement('tree-canvas') as TreeCanvas
    document.body.appendChild(canvas)
    await customElements.whenDefined('tree-canvas')
    await new Promise((resolve) => setTimeout(resolve, 0))
  })

  it('should render SVG element', () => {
    const svg = canvas.querySelector('svg')
    expect(svg).toBeTruthy()
  })

  it('should render transform group inside SVG', () => {
    const transformGroup = canvas.querySelector('svg g')
    expect(transformGroup).toBeTruthy()
  })

  it('should return transform group', () => {
    const transformGroup = canvas.getTransformGroup()
    expect(transformGroup).toBeTruthy()
    expect(transformGroup?.tagName).toBe('g')
  })

  it('should return SVG selection', () => {
    const svgSelection = canvas.getSvgSelection()
    expect(svgSelection).toBeTruthy()
  })

  it('should set display style to block', () => {
    expect(canvas.style.display).toBe('block')
  })

  it('should set width to 100%', () => {
    expect(canvas.style.width).toBe('100%')
  })

  it('should set height to 100%', () => {
    expect(canvas.style.height).toBe('100%')
  })

  it('should set SVG dimensions to 100%', () => {
    const svg = canvas.querySelector('svg')
    expect(svg?.style.width).toBe('100%')
    expect(svg?.style.height).toBe('100%')
  })
})
