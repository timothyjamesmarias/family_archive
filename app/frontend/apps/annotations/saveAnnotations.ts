import { csrfHeaders } from '../../shared/csrf'
import type { Annotation } from './types'

/**
 * Replaces every annotation on a file in one request — the endpoint deletes
 * anything absent from the list, so a partial list silently destroys the rest.
 * Always send the file's complete set.
 */
export async function saveAnnotations(
  fileId: number,
  annotations: Annotation[]
): Promise<Annotation[]> {
  const response = await fetch(`/api/artifact-files/${fileId}/annotations`, {
    method: 'PUT',
    headers: csrfHeaders({ 'Content-Type': 'application/json', 'Accept': 'application/json' }),
    credentials: 'same-origin',
    body: JSON.stringify({
      annotations: annotations.map((annotation) => ({
        // `id` is absent on a new annotation; null tells the server to create it.
        id: annotation.id ?? null,
        annotationText: annotation.annotationText,
        xCoord: annotation.xCoord,
        yCoord: annotation.yCoord,
      })),
    }),
  })

  if (!response.ok) {
    const body = await response.text()
    throw new Error(`Failed to save annotations: ${response.status} ${body}`)
  }

  const data = await response.json()
  return data.annotations as Annotation[]
}
