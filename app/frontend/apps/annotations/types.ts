/**
 * Types for the annotations editor
 */

export interface Annotation {
  id?: number
  annotationText: string
  xCoord: number // Fractional coordinate (0-1)
  yCoord: number // Fractional coordinate (0-1)
}

export interface ArtifactFile {
  id: number
  url: string
  mimeType: string
  fileSequence: number
  annotations: Annotation[]
}

export interface AnnotationEditorState {
  files: ArtifactFile[]
  currentFileId: number | null
  pendingChanges: Map<number, Annotation[]>
}
