import { useCallback, useMemo, useState, useSyncExternalStore } from 'react'
import { AnnotationEditorStateManager } from './AnnotationEditorState'
import type { Annotation, AnnotationEditorState, ArtifactFile } from './types'

/**
 * Adapts `AnnotationEditorStateManager` to `useSyncExternalStore`, which the
 * manager violates in two ways:
 *
 *  - `getState()` builds a fresh object (and Map) per call, so using it as
 *    `getSnapshot` directly would hand React a new reference each render and
 *    loop forever. The snapshot is cached and refreshed only on notify.
 *  - `subscribe()` fires its callback synchronously on registration, which the
 *    hook's contract forbids. The first invocation is swallowed.
 */
export class AnnotationStore {
  readonly manager = new AnnotationEditorStateManager()

  #snapshot: Readonly<AnnotationEditorState> = this.manager.getState()

  subscribe = (onStoreChange: () => void): (() => void) => {
    let primed = false
    return this.manager.subscribe(() => {
      // Drop the synchronous call `subscribe` makes on registration.
      if (!primed) {
        primed = true
        return
      }
      this.#snapshot = this.manager.getState()
      onStoreChange()
    })
  }

  getSnapshot = (): Readonly<AnnotationEditorState> => this.#snapshot

  /** Mutations go through here so the cached snapshot cannot drift from the
   * store when a caller reaches for the manager directly. */
  run(mutate: (manager: AnnotationEditorStateManager) => void): void {
    mutate(this.manager)
    this.#snapshot = this.manager.getState()
  }
}

export interface AnnotationStoreApi {
  files: ArtifactFile[]
  currentFileId: number | null
  currentFile: ArtifactFile | null
  annotations: Annotation[]
  hasChanges: (fileId: number) => boolean
  isDirty: boolean
  initialize: (files: ArtifactFile[]) => void
  setCurrentFile: (fileId: number) => void
  addAnnotation: (fileId: number, annotation: Annotation) => void
  updateAnnotation: (fileId: number, annotationId: number, updates: Partial<Annotation>) => void
  deleteAnnotation: (fileId: number, annotationId: number) => void
  resetChanges: (fileId: number) => void
  markSaved: (fileId: number, saved: Annotation[]) => void
}

export function useAnnotationStore(): AnnotationStoreApi {
  /** Lazy initialiser, so the store is constructed once per mount rather than
   * on every render. */
  const [store] = useState(() => new AnnotationStore())

  const state = useSyncExternalStore(store.subscribe, store.getSnapshot, store.getSnapshot)

  const currentFile = useMemo(
    () =>
      state.currentFileId === null
        ? null
        : (state.files.find((file) => Number(file.id) === Number(state.currentFileId)) ?? null),
    [state.files, state.currentFileId]
  )

  const annotations = useMemo(
    () =>
      state.currentFileId === null ? [] : (state.pendingChanges.get(state.currentFileId) ?? []),
    [state.pendingChanges, state.currentFileId]
  )

  const hasChanges = useCallback((fileId: number) => store.manager.hasChanges(fileId), [store])

  const isDirty = useMemo(
    () => state.files.some((file) => store.manager.hasChanges(file.id)),
    [state, store]
  )

  return {
    files: state.files,
    currentFileId: state.currentFileId,
    currentFile,
    annotations,
    hasChanges,
    isDirty,
    initialize: useCallback((files) => store.run((manager) => manager.initialize(files)), [store]),
    setCurrentFile: useCallback(
      (fileId) => store.run((manager) => manager.setCurrentFile(fileId)),
      [store]
    ),
    addAnnotation: useCallback(
      (fileId, annotation) => store.run((manager) => manager.addAnnotation(fileId, annotation)),
      [store]
    ),
    updateAnnotation: useCallback(
      (fileId, annotationId, updates) =>
        store.run((manager) => manager.updateAnnotation(fileId, annotationId, updates)),
      [store]
    ),
    deleteAnnotation: useCallback(
      (fileId, annotationId) =>
        store.run((manager) => manager.deleteAnnotation(fileId, annotationId)),
      [store]
    ),
    resetChanges: useCallback(
      (fileId) => store.run((manager) => manager.resetChanges(fileId)),
      [store]
    ),
    markSaved: useCallback(
      (fileId, saved) => store.run((manager) => manager.markSaved(fileId, saved)),
      [store]
    ),
  }
}
