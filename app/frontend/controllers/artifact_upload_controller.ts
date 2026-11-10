import { Controller } from '@hotwired/stimulus'
import type Uppy from '@uppy/core'
import { csrfHeaders } from '../shared/csrf'
import { showToast } from '../shared/components/toast'
import { mountDashboard } from '../shared/uppy'
import { MAX_FILE_SIZE, MAX_FILE_SIZE_LABEL, MAX_FILES } from '../shared/uploads'

interface CreatedArtifact {
  data: { id: number }
}

// The admin artifact upload page. Artifacts are created by uploading — the
// first file becomes the primary file, the rest become additional
// artifact_files. "Save and add another" keeps the type (usually a run of the
// same kind) and clears everything else.
export default class ArtifactUploadController extends Controller {
  static targets = ['dashboard', 'type', 'title', 'date', 'error', 'button']
  static values = { createUrl: String, artifactsUrl: String }

  declare readonly dashboardTarget: HTMLElement
  declare readonly typeTarget: HTMLSelectElement
  declare readonly titleTarget: HTMLInputElement
  declare readonly dateTarget: HTMLInputElement
  declare readonly errorTarget: HTMLElement
  declare readonly buttonTargets: HTMLButtonElement[]
  declare readonly createUrlValue: string
  declare readonly artifactsUrlValue: string

  private uppy!: Promise<Uppy>

  connect() {
    this.uppy = mountDashboard(this.dashboardTarget, {
      restrictions: { maxFileSize: MAX_FILE_SIZE, maxNumberOfFiles: MAX_FILES },
      note: `Up to ${MAX_FILES} files, ${MAX_FILE_SIZE_LABEL} each. The first file is the primary one.`,
      height: 320,
    })
  }

  disconnect() {
    // The mount may still be importing Uppy; destroy it once it lands.
    void this.uppy.then((uppy) => uppy.destroy())
  }

  async upload() {
    const created = await this.send()
    if (!created || this.navigatedAway) return

    window.location.assign(`${this.artifactsUrlValue}/${created.data.id}`)
  }

  async addAnother() {
    const created = await this.send()
    if (!created || this.navigatedAway) return

    const uppy = await this.uppy
    uppy.clear()
    this.titleTarget.value = ''
    this.dateTarget.value = ''
    showToast({ type: 'info', message: 'Artifact uploaded — add another' })
  }

  // The upload still lands; only the follow-up belongs to a page that's gone.
  private get navigatedAway() {
    return !this.element.isConnected
  }

  /** Posts the form and files; resolves to the created artifact, or null
   * once the failure has been shown. */
  private async send(): Promise<CreatedArtifact | null> {
    const files = (await this.uppy).getFiles()
    if (files.length === 0) {
      showToast({ type: 'warning', message: 'Choose at least one file' })
      return null
    }

    this.disableButtons()
    this.hideError()

    const body = new FormData()
    body.append('artifact[artifact_type]', this.typeTarget.value)
    if (this.titleTarget.value) body.append('artifact[title]', this.titleTarget.value)
    if (this.dateTarget.value) body.append('artifact[original_date_string]', this.dateTarget.value)
    files.forEach((file) => body.append('files[]', file.data as Blob, file.name))

    try {
      const response = await fetch(this.createUrlValue, {
        method: 'POST',
        headers: csrfHeaders({ Accept: 'application/json' }),
        body,
        credentials: 'same-origin',
      })
      const json = await response.json()
      if (response.ok) return json as CreatedArtifact

      this.fail(json?.errors?.files ?? 'Upload failed')
    } catch (caught) {
      this.fail(caught instanceof Error ? caught.message : 'Upload failed')
    } finally {
      this.enableButtons()
    }
    return null
  }

  private fail(message: string) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove('hidden')
    showToast({ type: 'error', message: 'Upload failed' })
  }

  private hideError() {
    this.errorTarget.textContent = ''
    this.errorTarget.classList.add('hidden')
  }

  private disableButtons() {
    this.buttonTargets.forEach((button) => {
      button.disabled = true
    })
  }

  private enableButtons() {
    this.buttonTargets.forEach((button) => {
      button.disabled = false
    })
  }
}
