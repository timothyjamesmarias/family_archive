import { describe, expect, it } from 'vitest'
import { pointToFraction } from '../coordinates'

/** happy-dom returns zeroed rects, so build them explicitly. */
const rect = (x: number, y: number, width: number, height: number) =>
  ({ left: x, top: y, width, height, right: x + width, bottom: y + height }) as DOMRect

describe('pointToFraction', () => {
  it('converts a click to a fraction of the image', () => {
    const box = rect(100, 50, 400, 200)

    expect(pointToFraction(300, 150, box)).toEqual({ xCoord: 0.5, yCoord: 0.5 })
    expect(pointToFraction(100, 50, box)).toEqual({ xCoord: 0, yCoord: 0 })
    expect(pointToFraction(500, 250, box)).toEqual({ xCoord: 1, yCoord: 1 })
  })

  it('is the inverse of the marker positioning', () => {
    const box = rect(0, 0, 800, 600)
    const stored = { xCoord: 0.595009, yCoord: 0.299995 }

    // Where the marker renders, given `left: x%` / `top: y%`.
    const clientX = box.left + stored.xCoord * box.width
    const clientY = box.top + stored.yCoord * box.height

    const roundTripped = pointToFraction(clientX, clientY, box)
    expect(roundTripped.xCoord).toBeCloseTo(stored.xCoord, 10)
    expect(roundTripped.yCoord).toBeCloseTo(stored.yCoord, 10)
  })

  it('gives the same fraction regardless of rendered size', () => {
    const large = pointToFraction(400, 300, rect(0, 0, 800, 600))
    const small = pointToFraction(200, 150, rect(0, 0, 400, 300))

    // The same visual point on a resized image must store identically.
    expect(large).toEqual(small)
  })

  it('clamps a click that lands just outside the image', () => {
    const box = rect(100, 50, 400, 200)

    expect(pointToFraction(90, 40, box)).toEqual({ xCoord: 0, yCoord: 0 })
    expect(pointToFraction(510, 260, box)).toEqual({ xCoord: 1, yCoord: 1 })
  })

  it('does not divide by zero before the image has laid out', () => {
    expect(pointToFraction(50, 50, rect(0, 0, 0, 0))).toEqual({ xCoord: 0, yCoord: 0 })
  })
})
