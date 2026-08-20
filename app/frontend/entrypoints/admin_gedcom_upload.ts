import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import '@uppy/core/css/style.min.css'
import '@uppy/dashboard/css/style.min.css'
import { showToast } from '../shared/components/toast'
import { MAX_FILE_SIZE, MAX_FILE_SIZE_LABEL } from '../shared/uploads'

/**
 * The GEDCOM import page. Uppy only picks the file; submitting hands it to the
 * form's own file input, so the plain multipart POST — redirect, flash, result
 * panel — is unchanged.
 */
function init() {
  const root = document.querySelector<HTMLElement>('[data-gedcom-upload]')
  if (!root || root.dataset.mounted) return
  root.dataset.mounted = 'true'

  const dashboardTarget = root.querySelector<HTMLElement>('[data-uppy-dashboard]')!
  const fileInput = root.querySelector<HTMLInputElement>('[data-gedcom-file]')!
  const importButton = root.querySelector<HTMLButtonElement>('[data-import]')!

  const uppy = new Uppy({
    restrictions: {
      maxFileSize: MAX_FILE_SIZE,
      maxNumberOfFiles: 1,
      allowedFileTypes: ['.ged'],
    },
    autoProceed: false,
  })
  uppy.use(Dashboard, {
    inline: true,
    target: dashboardTarget,
    height: 300,
    proudlyDisplayPoweredByUppy: false,
    hideUploadButton: true,
    note: `A single GEDCOM (.ged) file, up to ${MAX_FILE_SIZE_LABEL}`,
  })

  importButton.addEventListener('click', () => {
    const files = uppy.getFiles()
    if (files.length === 0) {
      showToast({ type: 'warning', message: 'Choose a .ged file to import' })
      return
    }

    const picked = files[0]
    const transfer = new DataTransfer()
    transfer.items.add(new File([picked.data as Blob], picked.name, { type: picked.type }))
    fileInput.files = transfer.files

    importButton.disabled = true
    fileInput.form!.requestSubmit()
  })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init)
} else {
  init()
}
