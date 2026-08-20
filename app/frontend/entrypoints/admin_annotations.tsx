import { createRoot } from 'react-dom/client'
import { AnnotationsEditor, type AnnotationsPayload } from '../apps/annotations/AnnotationsEditor'

function mount() {
  const element = document.getElementById('annotations-editor')
  if (!element || element.dataset.mounted) return
  element.dataset.mounted = 'true'

  const payload = JSON.parse(element.dataset.payload ?? 'null') as AnnotationsPayload | null
  if (!payload) return

  createRoot(element).render(<AnnotationsEditor artifact={payload} />)
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', mount)
} else {
  mount()
}
