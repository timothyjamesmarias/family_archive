import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest'
import { saveAnnotations } from '../saveAnnotations'
import type { Annotation } from '../types'

const ok = (annotations: unknown[]) =>
  Promise.resolve({
    ok: true,
    status: 200,
    json: () => Promise.resolve({ annotations }),
  } as Response)

beforeEach(() => {
  document.head.innerHTML = '<meta name="csrf-token" content="rails-token">'
})

afterEach(() => {
  vi.restoreAllMocks()
})

describe('saveAnnotations', () => {
  it('PUTs the whole set to the file endpoint', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockImplementation(() => ok([]))

    await saveAnnotations(42, [])

    const [url, init] = fetchSpy.mock.calls[0]
    expect(url).toBe('/api/artifact-files/42/annotations')
    expect(init?.method).toBe('PUT')
  })

  it('sends the CSRF token from the meta tag', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockImplementation(() => ok([]))

    await saveAnnotations(1, [])

    const headers = fetchSpy.mock.calls[0][1]?.headers as Record<string, string>
    expect(headers['X-CSRF-Token']).toBe('rails-token')
  })

  it('sends null for an annotation that has never been saved', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockImplementation(() => ok([]))
    const fresh: Annotation = { annotationText: 'new', xCoord: 0.1, yCoord: 0.2 }

    await saveAnnotations(1, [fresh])

    const body = JSON.parse(fetchSpy.mock.calls[0][1]?.body as string)
    // `undefined` would be dropped by JSON.stringify and the server would never
    // see the field; null is what tells it to create the row.
    expect(body.annotations[0].id).toBeNull()
  })

  it('preserves ids and coordinates of existing annotations', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockImplementation(() => ok([]))
    const existing: Annotation = {
      id: 7,
      annotationText: 'Grandmother',
      xCoord: 0.595009,
      yCoord: 0.299995,
    }

    await saveAnnotations(1, [existing])

    const body = JSON.parse(fetchSpy.mock.calls[0][1]?.body as string)
    expect(body.annotations[0]).toEqual({
      id: 7,
      annotationText: 'Grandmother',
      xCoord: 0.595009,
      yCoord: 0.299995,
    })
  })

  it('sends an empty list when every annotation was removed', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockImplementation(() => ok([]))

    await saveAnnotations(1, [])

    const body = JSON.parse(fetchSpy.mock.calls[0][1]?.body as string)
    // The endpoint replaces wholesale, so [] is how "delete them all" is expressed.
    expect(body.annotations).toEqual([])
  })

  it('returns what the server saved, so new rows pick up their ids', async () => {
    vi.spyOn(globalThis, 'fetch').mockImplementation(() =>
      ok([{ id: 11, annotationText: 'new', xCoord: 0.1, yCoord: 0.2 }])
    )

    const saved = await saveAnnotations(1, [{ annotationText: 'new', xCoord: 0.1, yCoord: 0.2 }])

    expect(saved[0].id).toBe(11)
  })

  it('throws with the response body when the save fails', async () => {
    vi.spyOn(globalThis, 'fetch').mockImplementation(() =>
      Promise.resolve({
        ok: false,
        status: 404,
        text: () => Promise.resolve('{"error":"Artifact file not found: 1"}'),
      } as Response)
    )

    await expect(saveAnnotations(1, [])).rejects.toThrow(/404/)
  })
})
