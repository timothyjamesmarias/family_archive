import { describe, expect, it, vi, afterEach } from 'vitest'
import { render, screen, cleanup, fireEvent } from '@testing-library/react'
import { AnnotationMarker } from '../AnnotationMarker'
import type { Annotation } from '../../types'

const annotation: Annotation = {
  id: 7,
  annotationText: 'Grandmother, second from left',
  xCoord: 0.25,
  yCoord: 0.75,
}

afterEach(cleanup)

describe('AnnotationMarker', () => {
  it('positions itself as a percentage of the image, not in pixels', () => {
    render(<AnnotationMarker annotation={annotation} index={1} />)

    const marker = screen.getByTestId('annotation-marker')
    const style = getComputedStyle(marker)
    // Fractions are stored 0–1; percentages keep the marker correct at any
    // rendered image size, which is what makes existing rows keep their place.
    expect(style.left).toBe('25%')
    expect(style.top).toBe('75%')
  })

  it('renders its 1-based index', () => {
    render(<AnnotationMarker annotation={annotation} index={3} />)
    expect(screen.getByText('3')).toBeTruthy()
  })

  it('reports the annotation and its rect when clicked', () => {
    const onSelect = vi.fn()
    render(<AnnotationMarker annotation={annotation} index={1} onSelect={onSelect} />)

    fireEvent.click(screen.getByTestId('annotation-marker'))

    expect(onSelect).toHaveBeenCalledTimes(1)
    const [picked, rect] = onSelect.mock.calls[0]
    expect(picked.id).toBe(7)
    // The edit form is anchored to the marker, so the rect has to come through.
    expect(rect).toBeInstanceOf(DOMRect)
  })

  it('stops the click reaching the image underneath', () => {
    const onImageClick = vi.fn()
    render(
      <div onClick={onImageClick}>
        <AnnotationMarker annotation={annotation} index={1} onSelect={vi.fn()} />
      </div>
    )

    fireEvent.click(screen.getByTestId('annotation-marker'))

    // Otherwise clicking an existing marker would also place a new annotation.
    expect(onImageClick).not.toHaveBeenCalled()
  })

  it('is inert when no handler is given, so the read-only view cannot select', () => {
    render(<AnnotationMarker annotation={annotation} index={1} />)

    const style = getComputedStyle(screen.getByTestId('annotation-marker'))
    expect(style.pointerEvents).toBe('none')
    expect(style.cursor).toBe('default')
  })

  it('marks the selected marker distinctly', () => {
    const { rerender } = render(
      <AnnotationMarker annotation={annotation} index={1} onSelect={vi.fn()} />
    )
    const plain = getComputedStyle(screen.getByTestId('annotation-marker')).borderColor

    rerender(<AnnotationMarker annotation={annotation} index={1} selected onSelect={vi.fn()} />)
    const chosen = getComputedStyle(screen.getByTestId('annotation-marker')).borderColor

    expect(chosen).not.toBe(plain)
  })

  it('handles an unsaved annotation that has no id yet', () => {
    const unsaved: Annotation = { annotationText: 'new', xCoord: 0.5, yCoord: 0.5 }
    const onSelect = vi.fn()
    render(<AnnotationMarker annotation={unsaved} index={2} onSelect={onSelect} />)

    fireEvent.click(screen.getByTestId('annotation-marker'))
    expect(onSelect.mock.calls[0][0].id).toBeUndefined()
  })
})
