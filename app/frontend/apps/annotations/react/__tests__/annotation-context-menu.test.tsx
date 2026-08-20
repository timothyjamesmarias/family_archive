import { describe, expect, it, vi, afterEach } from 'vitest'
import { render, screen, cleanup, fireEvent } from '@testing-library/react'
import { AnnotationContextMenu } from '../AnnotationContextMenu'

afterEach(cleanup)

describe('AnnotationContextMenu', () => {
  it('stays closed without an anchor', () => {
    render(<AnnotationContextMenu anchor={null} onAdd={vi.fn()} onClose={vi.fn()} />)
    expect(screen.queryByText('Add annotation')).toBeNull()
  })

  it('opens at the anchor position', () => {
    render(
      <AnnotationContextMenu
        anchor={{ clientX: 120, clientY: 80 }}
        onAdd={vi.fn()}
        onClose={vi.fn()}
      />
    )
    expect(screen.getByText('Add annotation')).toBeTruthy()
    expect(screen.getByText('Cancel')).toBeTruthy()
  })

  it('reports the add choice and then closes', () => {
    const onAdd = vi.fn()
    const onClose = vi.fn()
    render(
      <AnnotationContextMenu
        anchor={{ clientX: 10, clientY: 10 }}
        onAdd={onAdd}
        onClose={onClose}
      />
    )

    fireEvent.click(screen.getByText('Add annotation'))

    expect(onAdd).toHaveBeenCalledTimes(1)
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('cancel closes without adding', () => {
    const onAdd = vi.fn()
    const onClose = vi.fn()
    render(
      <AnnotationContextMenu
        anchor={{ clientX: 10, clientY: 10 }}
        onAdd={onAdd}
        onClose={onClose}
      />
    )

    fireEvent.click(screen.getByText('Cancel'))

    expect(onAdd).not.toHaveBeenCalled()
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('closes on Escape', () => {
    const onClose = vi.fn()
    render(
      <AnnotationContextMenu
        anchor={{ clientX: 10, clientY: 10 }}
        onAdd={vi.fn()}
        onClose={onClose}
      />
    )

    fireEvent.keyDown(screen.getByText('Add annotation'), { key: 'Escape', code: 'Escape' })

    expect(onClose).toHaveBeenCalled()
  })
})
