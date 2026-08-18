/** Rails renders the CSRF token in a meta tag; echo it back on writes. Never
 * set Content-Type alongside a FormData body — the browser has to set the
 * multipart boundary itself. */
export function csrfHeaders(extra: Record<string, string> = {}): Record<string, string> {
  const token =
    document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? null
  return token ? { ...extra, 'X-CSRF-Token': token } : { ...extra }
}
