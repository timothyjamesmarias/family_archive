/**
 * Conversion between a click on the rendered image and the fractional
 * coordinates stored on an annotation.
 *
 * Coordinates are stored as fractions of the image (0–1), never pixels, so a
 * marker keeps its place at any rendered size. This is the exact inverse of the
 * marker's `left: ${x * 100}%` positioning — the two must stay in step or
 * annotations land somewhere other than where they were placed.
 */

export interface Fraction {
  xCoord: number
  yCoord: number
}

/** Clamped to 0–1: a click on the border can land a hair outside the rect, and
 * a stored value beyond the image would render the marker off it. */
export function pointToFraction(clientX: number, clientY: number, rect: DOMRect): Fraction {
  if (rect.width === 0 || rect.height === 0) return { xCoord: 0, yCoord: 0 }
  return {
    xCoord: clamp((clientX - rect.left) / rect.width),
    yCoord: clamp((clientY - rect.top) / rect.height),
  }
}

function clamp(value: number): number {
  if (Number.isNaN(value)) return 0
  return Math.min(1, Math.max(0, value))
}
