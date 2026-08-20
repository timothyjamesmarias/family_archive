import { mountUppyFormPicker } from '../shared/uppyFormPicker'
import { MAX_FILE_SIZE, MAX_FILE_SIZE_LABEL } from '../shared/uploads'

function init() {
  const root = document.querySelector<HTMLElement>('[data-gedcom-upload]')
  if (!root || root.dataset.mounted) return
  root.dataset.mounted = 'true'

  mountUppyFormPicker({
    root,
    restrictions: { maxFileSize: MAX_FILE_SIZE, maxNumberOfFiles: 1, allowedFileTypes: ['.ged'] },
    note: `A single GEDCOM (.ged) file, up to ${MAX_FILE_SIZE_LABEL}`,
    height: 300,
    emptyMessage: 'Choose a .ged file to import',
  })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init)
} else {
  init()
}
