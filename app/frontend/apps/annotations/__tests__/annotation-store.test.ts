import { describe, expect, it } from 'vitest'
import { AnnotationStore } from '../useAnnotationStore'
import type { ArtifactFile } from '../types'

function files(): ArtifactFile[] {
  return [
    {
      id: 1,
      url: '/rails/blobs/a.png',
      mimeType: 'image/png',
      fileSequence: 1,
      annotations: [{ id: 10, annotationText: 'one', xCoord: 0.1, yCoord: 0.2 }],
    },
    { id: 2, url: '/rails/blobs/b.png', mimeType: 'image/png', fileSequence: 2, annotations: [] },
  ]
}

describe('AnnotationStore (useSyncExternalStore bridge)', () => {
  it('the snapshot is referentially stable between changes', () => {
    const store = new AnnotationStore()
    store.subscribe(() => {})

    const first = store.getSnapshot()
    expect(store.getSnapshot()).toBe(first)
  })

  it('subscribe does not fire on registration, only on change', () => {
    const store = new AnnotationStore()
    let calls = 0
    store.subscribe(() => {
      calls += 1
    })

    expect(calls).toBe(0)

    store.run((manager) => manager.initialize(files()))
    expect(calls).toBe(1)
  })

  it('the snapshot changes identity after a mutation', () => {
    const store = new AnnotationStore()
    store.subscribe(() => {})
    store.run((manager) => manager.initialize(files()))

    const before = store.getSnapshot()
    store.run((manager) => manager.setCurrentFile(1))
    const after = store.getSnapshot()

    expect(before).not.toBe(after)
    expect(after.currentFileId).toBe(1)
  })

  it('mutating through run() keeps the cached snapshot in step', () => {
    const store = new AnnotationStore()
    store.subscribe(() => {})
    store.run((manager) => manager.initialize(files()))
    store.run((manager) => manager.setCurrentFile(1))

    store.run((manager) =>
      manager.addAnnotation(1, { annotationText: 'two', xCoord: 0.5, yCoord: 0.5 })
    )

    expect(store.getSnapshot().pendingChanges.get(1)!).toHaveLength(2)
  })

  it('unsubscribing stops notifications', () => {
    const store = new AnnotationStore()
    let calls = 0
    const unsubscribe = store.subscribe(() => {
      calls += 1
    })

    store.run((manager) => manager.initialize(files()))
    expect(calls).toBe(1)

    unsubscribe()
    store.run((manager) => manager.setCurrentFile(2))
    expect(calls).toBe(1)
  })

  it('dirty tracking is per file and clears on save', () => {
    const store = new AnnotationStore()
    store.subscribe(() => {})
    store.run((manager) => manager.initialize(files()))

    expect(store.manager.hasChanges(1)).toBe(false)

    store.run((manager) =>
      manager.addAnnotation(1, { annotationText: 'new', xCoord: 0.3, yCoord: 0.3 })
    )
    expect(store.manager.hasChanges(1)).toBe(true)
    // editing file 1 must not dirty file 2
    expect(store.manager.hasChanges(2)).toBe(false)

    store.run((manager) =>
      manager.markSaved(1, [
        { id: 10, annotationText: 'one', xCoord: 0.1, yCoord: 0.2 },
        { id: 11, annotationText: 'new', xCoord: 0.3, yCoord: 0.3 },
      ])
    )
    expect(store.manager.hasChanges(1)).toBe(false)
  })

  it('resetChanges restores the original annotations', () => {
    const store = new AnnotationStore()
    store.subscribe(() => {})
    store.run((manager) => manager.initialize(files()))

    store.run((manager) => manager.deleteAnnotation(1, 10))
    expect(store.manager.hasChanges(1)).toBe(true)

    store.run((manager) => manager.resetChanges(1))
    expect(store.manager.hasChanges(1)).toBe(false)
    expect(store.getSnapshot().pendingChanges.get(1)!).toHaveLength(1)
  })
})
