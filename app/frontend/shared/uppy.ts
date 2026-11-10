import type Uppy from '@uppy/core'
import { prefersDark } from '../controllers/dark_mode_controller'
import { showToast } from './components/toast'

interface DashboardOptions {
  restrictions: {
    maxFileSize: number
    maxNumberOfFiles: number
    allowedFileTypes?: string[] | null
  }
  note: string
  height: number
}

/** Uppy's own 'auto' theme follows the system preference, not the site's
 * stored choice. */
export function pageTheme(): 'dark' | 'light' {
  return prefersDark() ? 'dark' : 'light'
}

/**
 * Mounts an inline Uppy dashboard that only collects files — callers decide
 * how to send them. Uppy is imported here rather than at the top so it
 * downloads only on the pages that mount it, though the admin bundle
 * registers every controller up front.
 */
export async function mountDashboard(
  target: HTMLElement,
  { restrictions, note, height }: DashboardOptions,
): Promise<Uppy> {
  const [{ default: Uppy }, { default: Dashboard }] = await Promise.all([
    import('@uppy/core'),
    import('@uppy/dashboard'),
    import('@uppy/core/css/style.min.css'),
    import('@uppy/dashboard/css/style.min.css'),
  ]).catch((error: unknown) => {
    // Otherwise the page just shows no dashboard and the buttons do nothing.
    showToast({ type: 'error', message: 'The uploader failed to load — reload the page' })
    throw error
  })

  // Controllers destroy their dashboard on disconnect, before Turbo clones
  // the page for its cache; should a snapshot still carry one, mount in its
  // place rather than beside it.
  target.replaceChildren()

  const uppy = new Uppy({ restrictions, autoProceed: false })
  uppy.use(Dashboard, {
    inline: true,
    target,
    height,
    proudlyDisplayPoweredByUppy: false,
    hideUploadButton: true,
    note,
    theme: pageTheme(),
  })
  return uppy
}
