import { createRoot } from 'react-dom/client'
import { ThemeProvider, createTheme } from '@mui/material/styles'
import { prefersDark } from '../controllers/dark_mode_controller'
import { AnnotationsEditor, type AnnotationsPayload } from '../apps/annotations/AnnotationsEditor'

function mount() {
  const element = document.getElementById('annotations-editor')
  if (!element || element.dataset.mounted) return
  element.dataset.mounted = 'true'

  const payload = JSON.parse(element.dataset.payload ?? 'null') as AnnotationsPayload | null
  if (!payload) return

  // Read once at mount: the page fully reloads on navigation, and MUI cannot
  // follow the class toggle live anyway.
  const mode = prefersDark() ? 'dark' : 'light'
  createRoot(element).render(
    <ThemeProvider theme={createTheme({ palette: { mode } })}>
      <AnnotationsEditor artifact={payload} />
    </ThemeProvider>
  )
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', mount)
} else {
  mount()
}
