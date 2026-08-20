/**
 * State manager for the annotations editor
 * Simple reactive state management with subscriber pattern
 */

import type { Annotation, AnnotationEditorState, ArtifactFile } from './types'

type StateChangeCallback = (state: AnnotationEditorState) => void

export class AnnotationEditorStateManager {
  private state: AnnotationEditorState = {
    files: [],
    currentFileId: null,
    pendingChanges: new Map(),
  }

  private listeners: Set<StateChangeCallback> = new Set()

  /**
   * Initialize state with files data from the server
   */
  initialize(files: ArtifactFile[]): void {
    this.state.files = files

    // Initialize pending changes map with current annotations
    files.forEach((file) => {
      this.state.pendingChanges.set(file.id, [...file.annotations])
    })

    this.notifyListeners()
  }

  /**
   * Get current state snapshot (immutable)
   */
  getState(): Readonly<AnnotationEditorState> {
    return {
      ...this.state,
      pendingChanges: new Map(this.state.pendingChanges),
    }
  }

  /**
   * Get all files
   */
  getFiles(): ArtifactFile[] {
    return this.state.files
  }

  /**
   * Get currently selected file
   */
  getCurrentFile(): ArtifactFile | null {
    if (this.state.currentFileId === null) return null
    return this.state.files.find((f) => f.id === this.state.currentFileId) || null
  }

  /**
   * Set the currently active file
   */
  setCurrentFile(fileId: number): void {
    this.state.currentFileId = fileId
    this.notifyListeners()
  }

  /**
   * Clear current file selection
   */
  clearCurrentFile(): void {
    this.state.currentFileId = null
    this.notifyListeners()
  }

  /**
   * Get annotations for a specific file (from pending changes)
   */
  getAnnotations(fileId: number): Annotation[] {
    return this.state.pendingChanges.get(fileId) || []
  }

  /**
   * Get annotations for the current file
   */
  getCurrentAnnotations(): Annotation[] {
    if (this.state.currentFileId === null) return []
    return this.getAnnotations(this.state.currentFileId)
  }

  /**
   * Add a new annotation to a file
   */
  addAnnotation(fileId: number, annotation: Annotation): void {
    const annotations = this.state.pendingChanges.get(fileId) || []
    this.state.pendingChanges.set(fileId, [...annotations, annotation])
    this.notifyListeners()
  }

  /**
   * Update an existing annotation
   */
  updateAnnotation(fileId: number, annotationId: number, updates: Partial<Annotation>): void {
    const annotations = this.state.pendingChanges.get(fileId) || []
    const updatedAnnotations = annotations.map((a) =>
      a.id === annotationId ? { ...a, ...updates } : a
    )
    this.state.pendingChanges.set(fileId, updatedAnnotations)
    this.notifyListeners()
  }

  /**
   * Delete an annotation
   */
  deleteAnnotation(fileId: number, annotationId: number): void {
    const annotations = this.state.pendingChanges.get(fileId) || []
    const filteredAnnotations = annotations.filter((a) => a.id !== annotationId)
    this.state.pendingChanges.set(fileId, filteredAnnotations)
    this.notifyListeners()
  }

  /**
   * Check if a file has unsaved changes
   */
  hasChanges(fileId: number): boolean {
    const file = this.state.files.find((f) => f.id === fileId)
    if (!file) return false

    const currentAnnotations = this.state.pendingChanges.get(fileId) || []

    // Compare lengths first
    if (file.annotations.length !== currentAnnotations.length) return true

    // Deep compare annotations
    const originalIds = new Set(file.annotations.map((a) => a.id).filter(Boolean))
    const currentIds = new Set(currentAnnotations.map((a) => a.id).filter(Boolean))

    // Check if any IDs are different (added/removed)
    if (originalIds.size !== currentIds.size) return true
    for (const id of originalIds) {
      if (!currentIds.has(id)) return true
    }

    // Check if any annotation data changed
    for (const current of currentAnnotations) {
      if (!current.id) return true // New annotation

      const original = file.annotations.find((a) => a.id === current.id)
      if (!original) return true

      if (
        original.annotationText !== current.annotationText ||
        original.xCoord !== current.xCoord ||
        original.yCoord !== current.yCoord
      ) {
        return true
      }
    }

    return false
  }

  /**
   * Reset pending changes for a file back to original state
   */
  resetChanges(fileId: number): void {
    const file = this.state.files.find((f) => f.id === fileId)
    if (file) {
      this.state.pendingChanges.set(fileId, [...file.annotations])
      this.notifyListeners()
    }
  }

  /**
   * Mark a file's changes as saved (update original state)
   */
  markSaved(fileId: number, savedAnnotations: Annotation[]): void {
    const fileIndex = this.state.files.findIndex((f) => f.id === fileId)
    if (fileIndex !== -1) {
      this.state.files[fileIndex].annotations = savedAnnotations
      this.state.pendingChanges.set(fileId, [...savedAnnotations])
      this.notifyListeners()
    }
  }

  /**
   * Subscribe to state changes
   * Returns unsubscribe function
   */
  subscribe(callback: StateChangeCallback): () => void {
    this.listeners.add(callback)

    // Call immediately with current state
    callback(this.getState())

    // Return unsubscribe function
    return () => {
      this.listeners.delete(callback)
    }
  }

  /**
   * Notify all listeners of state change
   */
  private notifyListeners(): void {
    const currentState = this.getState()
    this.listeners.forEach((callback) => callback(currentState))
  }
}
