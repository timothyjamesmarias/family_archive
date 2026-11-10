import { Controller } from '@hotwired/stimulus'
import type Uppy from '@uppy/core'
import { showToast } from '../shared/components/toast'
import { mountDashboard } from '../shared/uppy'
import { MAX_FILE_SIZE, MAX_FILES } from '../shared/uploads'

// Uppy only picks the files: submit copies them into the form's own hidden
// file input and submits it natively, so the classic multipart POST —
// redirect, flash — is unchanged.
export default class UppyPickerController extends Controller<HTMLFormElement> {
  static targets = ['input', 'dashboard', 'submit']
  static values = {
    maxFiles: { type: Number, default: MAX_FILES },
    maxFileSize: { type: Number, default: MAX_FILE_SIZE },
    allowedTypes: Array,
    note: String,
    emptyMessage: String,
    height: Number,
  }

  declare readonly inputTarget: HTMLInputElement
  declare readonly dashboardTarget: HTMLElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly maxFilesValue: number
  declare readonly maxFileSizeValue: number
  declare readonly allowedTypesValue: string[]
  declare readonly noteValue: string
  declare readonly emptyMessageValue: string
  declare readonly heightValue: number

  private uppy!: Promise<Uppy>

  connect() {
    this.uppy = mountDashboard(this.dashboardTarget, {
      restrictions: {
        maxFileSize: this.maxFileSizeValue,
        maxNumberOfFiles: this.maxFilesValue,
        // Uppy rejects every file when given an empty list.
        allowedFileTypes: this.allowedTypesValue.length > 0 ? this.allowedTypesValue : null,
      },
      note: this.noteValue,
      height: this.heightValue,
    })
  }

  disconnect() {
    // The mount may still be importing Uppy; destroy it once it lands.
    void this.uppy.then((uppy) => uppy.destroy())
  }

  async submit() {
    const files = (await this.uppy).getFiles()
    if (files.length === 0) {
      showToast({ type: 'warning', message: this.emptyMessageValue })
      return
    }

    const transfer = new DataTransfer()
    files
      .map((file) => new File([file.data as Blob], file.name, { type: file.type }))
      .forEach((file) => transfer.items.add(file))
    this.inputTarget.files = transfer.files

    this.submitTarget.disabled = true
    this.element.requestSubmit()
  }
}
