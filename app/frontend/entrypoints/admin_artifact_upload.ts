import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import '@uppy/core/css/style.min.css'
import '@uppy/dashboard/css/style.min.css'
import { csrfHeaders } from '../shared/csrf'
import { showToast } from '../shared/components/toast'
import { MAX_FILE_SIZE, MAX_FILE_SIZE_LABEL, MAX_FILES } from '../shared/uploads'

/**
 * The admin artifact upload page. Artifacts are created by uploading — the
 * first file becomes the primary file, the rest become additional
 * artifact_files. "Save and add another" keeps the type (usually a run of the
 * same kind) and clears everything else.
 */
function init() {
  const root = document.querySelector<HTMLElement>('[data-artifact-upload]')
  if (!root || root.dataset.mounted) return
  root.dataset.mounted = 'true'

  const dashboardTarget = root.querySelector<HTMLElement>('[data-uppy-dashboard]')!
  const typeSelect = root.querySelector<HTMLSelectElement>('[data-field-type]')!
  const titleInput = root.querySelector<HTMLInputElement>('[data-field-title]')!
  const dateInput = root.querySelector<HTMLInputElement>('[data-field-date]')!
  const errorBox = root.querySelector<HTMLElement>('[data-upload-error]')!
  const buttons = root.querySelectorAll<HTMLButtonElement>('[data-submit]')

  const uppy = new Uppy({
    restrictions: { maxFileSize: MAX_FILE_SIZE, maxNumberOfFiles: MAX_FILES },
    autoProceed: false,
  })
  uppy.use(Dashboard, {
    inline: true,
    target: dashboardTarget,
    height: 320,
    proudlyDisplayPoweredByUppy: false,
    hideUploadButton: true,
    note: `Up to ${MAX_FILES} files, ${MAX_FILE_SIZE_LABEL} each. The first file is the primary one.`,
  })

  const setBusy = (busy: boolean) => {
    buttons.forEach((button) => {
      button.disabled = busy
    })
  }

  const showError = (message: string | null) => {
    errorBox.textContent = message ?? ''
    errorBox.classList.toggle('hidden', message === null)
  }

  const submit = async (addAnother: boolean) => {
    const files = uppy.getFiles()
    if (files.length === 0) {
      showToast({ type: 'warning', message: 'Choose at least one file' })
      return
    }

    setBusy(true)
    showError(null)

    const body = new FormData()
    body.append('artifact[artifact_type]', typeSelect.value)
    if (titleInput.value) body.append('artifact[title]', titleInput.value)
    if (dateInput.value) body.append('artifact[original_date_string]', dateInput.value)
    for (const file of files) body.append('files[]', file.data as Blob, file.name)

    try {
      const response = await fetch(root.dataset.createUrl!, {
        method: 'POST',
        headers: csrfHeaders({ Accept: 'application/json' }),
        body,
        credentials: 'same-origin',
      })
      const json = await response.json()

      if (!response.ok) {
        showError(json?.errors?.files ?? 'Upload failed')
        showToast({ type: 'error', message: 'Upload failed' })
        return
      }

      if (addAnother) {
        uppy.clear()
        titleInput.value = ''
        dateInput.value = ''
        showToast({ type: 'info', message: 'Artifact uploaded — add another' })
        return
      }

      window.location.assign(`${root.dataset.artifactsUrl}/${json.data.id}`)
    } catch (caught) {
      showError(caught instanceof Error ? caught.message : 'Upload failed')
      showToast({ type: 'error', message: 'Upload failed' })
    } finally {
      setBusy(false)
    }
  }

  buttons.forEach((button) => {
    button.addEventListener('click', () => {
      void submit(button.dataset.submit === 'add-another')
    })
  })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init)
} else {
  init()
}
