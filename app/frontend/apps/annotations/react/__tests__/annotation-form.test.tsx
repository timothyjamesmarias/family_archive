import { describe, expect, it, vi, afterEach } from 'vitest'
import { render, screen, cleanup, fireEvent } from '@testing-library/react'
import { AnnotationForm, type FormTarget } from '../AnnotationForm'
import type { Annotation } from '../../types'

const existing: Annotation = {
  id: 7,
  annotationText: 'Grandmother',
  xCoord: 0.25,
  yCoord: 0.75,
}

const unsaved: Annotation = { annotationText: '', xCoord: 0.5, yCoord: 0.5 }

const target = (annotation: Annotation): FormTarget => ({
  annotation,
  clientX: 100,
  clientY: 100,
})

const noop = {
  onSubmit: vi.fn(),
  onDelete: vi.fn(),
  onClose: vi.fn(),
}

afterEach(() => {
  cleanup()
  vi.clearAllMocks()
})

describe('AnnotationForm', () => {
  it('stays closed without a target', () => {
    render(<AnnotationForm target={null} mode="create" {...noop} />)
    expect(screen.queryByLabelText('Annotation text')).toBeNull()
  })

  it('opens empty in create mode', () => {
    render(<AnnotationForm target={target(unsaved)} mode="create" {...noop} />)

    expect(screen.getByText('Add annotation')).toBeTruthy()
    expect((screen.getByLabelText('Annotation text') as HTMLInputElement).value).toBe('')
  })

  it('prefills the existing text in edit mode', () => {
    render(<AnnotationForm target={target(existing)} mode="edit" {...noop} />)

    expect(screen.getByText('Edit annotation')).toBeTruthy()
    expect((screen.getByLabelText('Annotation text') as HTMLInputElement).value).toBe('Grandmother')
  })

  it('submits the trimmed text and keeps the coordinates', () => {
    const onSubmit = vi.fn()
    render(<AnnotationForm target={target(unsaved)} mode="create" {...noop} onSubmit={onSubmit} />)

    fireEvent.change(screen.getByLabelText('Annotation text'), {
      target: { value: '  Aunt Mary  ' },
    })
    fireEvent.click(screen.getByText('Add'))

    expect(onSubmit).toHaveBeenCalledTimes(1)
    expect(onSubmit.mock.calls[0][0]).toEqual({
      annotationText: 'Aunt Mary',
      xCoord: 0.5,
      yCoord: 0.5,
    })
  })

  it('refuses to submit empty text', () => {
    const onSubmit = vi.fn()
    const onClose = vi.fn()
    render(
      <AnnotationForm
        target={target(unsaved)}
        mode="create"
        {...noop}
        onSubmit={onSubmit}
        onClose={onClose}
      />
    )

    fireEvent.click(screen.getByText('Add'))

    expect(onSubmit).not.toHaveBeenCalled()
    expect(onClose).not.toHaveBeenCalled()
    expect(screen.getByText('Enter some text')).toBeTruthy()
  })

  it('whitespace alone does not count as text', () => {
    const onSubmit = vi.fn()
    render(<AnnotationForm target={target(unsaved)} mode="create" {...noop} onSubmit={onSubmit} />)

    fireEvent.change(screen.getByLabelText('Annotation text'), { target: { value: '   ' } })
    fireEvent.click(screen.getByText('Add'))

    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('Enter submits', () => {
    const onSubmit = vi.fn()
    render(<AnnotationForm target={target(unsaved)} mode="create" {...noop} onSubmit={onSubmit} />)

    const input = screen.getByLabelText('Annotation text')
    fireEvent.change(input, { target: { value: 'Uncle Bob' } })
    fireEvent.keyDown(input, { key: 'Enter' })

    expect(onSubmit).toHaveBeenCalledTimes(1)
  })

  it('Escape closes without submitting', () => {
    const onSubmit = vi.fn()
    const onClose = vi.fn()
    render(
      <AnnotationForm
        target={target(unsaved)}
        mode="create"
        {...noop}
        onSubmit={onSubmit}
        onClose={onClose}
      />
    )

    const input = screen.getByLabelText('Annotation text')
    fireEvent.change(input, { target: { value: 'discarded' } })
    fireEvent.keyDown(input, { key: 'Escape' })

    expect(onSubmit).not.toHaveBeenCalled()
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('offers no delete in create mode', () => {
    render(<AnnotationForm target={target(unsaved)} mode="create" {...noop} />)
    expect(screen.queryByText('Delete')).toBeNull()
  })

  it('offers no delete for an annotation that was never saved', () => {
    const neverSaved: Annotation = { annotationText: 'pending', xCoord: 0.1, yCoord: 0.1 }
    render(<AnnotationForm target={target(neverSaved)} mode="edit" {...noop} />)
    expect(screen.queryByText('Delete')).toBeNull()
  })

  it('asks before deleting, in the popover rather than a browser dialog', () => {
    const onDelete = vi.fn()
    render(<AnnotationForm target={target(existing)} mode="edit" {...noop} onDelete={onDelete} />)

    fireEvent.click(screen.getByText('Delete'))

    expect(onDelete).not.toHaveBeenCalled()
    expect(screen.getByText('Delete this annotation?')).toBeTruthy()
  })

  it('deletes once confirmed', () => {
    const onDelete = vi.fn()
    const onClose = vi.fn()
    render(
      <AnnotationForm
        target={target(existing)}
        mode="edit"
        {...noop}
        onDelete={onDelete}
        onClose={onClose}
      />
    )

    fireEvent.click(screen.getByText('Delete'))
    // The confirm button replaces the row; pick the one inside the prompt.
    fireEvent.click(screen.getAllByText('Delete').slice(-1)[0])

    expect(onDelete).toHaveBeenCalledWith(7)
    expect(onClose).toHaveBeenCalled()
  })

  it('backing out of the confirmation keeps the annotation', () => {
    const onDelete = vi.fn()
    render(<AnnotationForm target={target(existing)} mode="edit" {...noop} onDelete={onDelete} />)

    fireEvent.click(screen.getByText('Delete'))
    fireEvent.click(screen.getByText('Keep'))

    expect(onDelete).not.toHaveBeenCalled()
    expect(screen.getByText('Update')).toBeTruthy()
  })

  /** The page keys the form on the target so a new one remounts; without that
   * key the field would still show the previous annotation's text. */
  it('re-targeting resets the field instead of showing the previous text', () => {
    const { rerender } = render(
      <AnnotationForm key={existing.id} target={target(existing)} mode="edit" {...noop} />
    )
    expect((screen.getByLabelText('Annotation text') as HTMLInputElement).value).toBe('Grandmother')

    const other: Annotation = { id: 8, annotationText: 'Cousin', xCoord: 0.3, yCoord: 0.3 }
    rerender(<AnnotationForm key={other.id} target={target(other)} mode="edit" {...noop} />)

    expect((screen.getByLabelText('Annotation text') as HTMLInputElement).value).toBe('Cousin')
  })
})
