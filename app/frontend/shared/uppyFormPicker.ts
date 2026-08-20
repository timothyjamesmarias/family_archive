import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import '@uppy/core/css/style.min.css'
import '@uppy/dashboard/css/style.min.css'
import { showToast } from './components/toast'
import { prefersDark } from '../controllers/dark_mode_controller'

interface UppyFormPickerOptions {
  /** Container holding [data-uppy-dashboard], [data-uppy-input], [data-uppy-submit]. */
  root: HTMLElement
  restrictions: {
    maxFileSize: number
    maxNumberOfFiles: number
    allowedFileTypes?: string[]
  }
  note: string
  height: number
  /** Toast shown when submit is clicked with nothing picked. */
  emptyMessage: string
}

/** Uppy's own 'auto' theme follows the system preference, not the site's
 * stored choice. Asking the controller module (rather than the `dark` class)
 * also works when a page entrypoint loads before application.js has applied
 * the class — importing it applies the class as a side effect. */
export function pageTheme(): 'dark' | 'light' {
  return prefersDark() ? 'dark' : 'light'
}

/**
 * Mounts an Uppy dashboard that only picks files: submitting copies them into
 * the form's own hidden file input and submits it, so the classic multipart
 * POST — redirect, flash — is unchanged.
 */
export function mountUppyFormPicker({
  root,
  restrictions,
  note,
  height,
  emptyMessage,
}: UppyFormPickerOptions) {
  const dashboardTarget = root.querySelector<HTMLElement>('[data-uppy-dashboard]')!
  const fileInput = root.querySelector<HTMLInputElement>('[data-uppy-input]')!
  const submitButton = root.querySelector<HTMLButtonElement>('[data-uppy-submit]')!

  const uppy = new Uppy({ restrictions, autoProceed: false })
  uppy.use(Dashboard, {
    inline: true,
    target: dashboardTarget,
    height,
    proudlyDisplayPoweredByUppy: false,
    hideUploadButton: true,
    note,
    theme: pageTheme(),
  })

  submitButton.addEventListener('click', () => {
    const files = uppy.getFiles()
    if (files.length === 0) {
      showToast({ type: 'warning', message: emptyMessage })
      return
    }

    const transfer = new DataTransfer()
    for (const file of files) {
      transfer.items.add(new File([file.data as Blob], file.name, { type: file.type }))
    }
    fileInput.files = transfer.files

    submitButton.disabled = true
    fileInput.form!.requestSubmit()
  })
}
