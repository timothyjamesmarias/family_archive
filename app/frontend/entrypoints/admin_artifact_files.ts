import { mountUppyFormPicker } from '../shared/uppyFormPicker'
import { MAX_FILE_SIZE, MAX_FILE_SIZE_LABEL, MAX_FILES } from '../shared/uploads'

function init() {
  const root = document.querySelector<HTMLElement>('[data-artifact-add-files]')
  if (!root || root.dataset.mounted) return
  root.dataset.mounted = 'true'

  mountUppyFormPicker({
    root,
    restrictions: { maxFileSize: MAX_FILE_SIZE, maxNumberOfFiles: MAX_FILES },
    note: `Up to ${MAX_FILES} files, ${MAX_FILE_SIZE_LABEL} each. They continue the sequence.`,
    height: 250,
    emptyMessage: 'Choose at least one file to add',
  })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init)
} else {
  init()
}
