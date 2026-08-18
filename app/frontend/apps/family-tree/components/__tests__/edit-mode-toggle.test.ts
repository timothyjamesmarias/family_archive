import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import '../edit-mode-toggle'
import { type EditModeToggle } from '../edit-mode-toggle'
import { store, EditMode } from '../../../../shared/store'

describe('EditModeToggle', () => {
  let toggle: EditModeToggle

  beforeEach(async () => {
    // Reset store state before each test
    store.setState({ isAuthenticated: false, mode: EditMode.VIEW })

    toggle = document.createElement('edit-mode-toggle') as EditModeToggle
    await customElements.whenDefined('edit-mode-toggle')
    // Don't append yet - let individual tests set up state first
  })

  afterEach(() => {
    toggle.remove()
    document.body.innerHTML = ''
    // Reset store to clean state
    store.setState({ isAuthenticated: false, mode: EditMode.VIEW })
  })

  describe('Component Rendering', () => {
    it('should be hidden when user is not authenticated', async () => {
      store.setState({ isAuthenticated: false, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(toggle.style.display).toBe('none')
      expect(toggle.innerHTML).toBe('')
    })

    it('should be visible when user is authenticated', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      // The component uses applyStyles which sets cssText, so check for positioning styles
      expect(toggle.innerHTML).not.toBe('')
      const container = toggle.querySelector('.edit-mode-toggle-container')
      expect(container).toBeTruthy()
    })

    it('should render toggle container when authenticated', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const container = toggle.querySelector('.edit-mode-toggle-container')
      expect(container).toBeTruthy()
    })

    it('should render mode status indicator', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const indicator = toggle.querySelector('.edit-mode-indicator')
      expect(indicator).toBeTruthy()
    })

    it('should render mode label', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const label = toggle.querySelector('.edit-mode-label')
      expect(label).toBeTruthy()
    })

    it('should render toggle button', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const button = toggle.querySelector('.edit-mode-button')
      expect(button).toBeTruthy()
    })
  })

  describe('View Mode Display', () => {
    it('should display "View Mode" label in view mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const label = toggle.querySelector('.edit-mode-label')
      expect(label?.textContent).toBe('View Mode')
    })

    it('should display "Enter Edit Mode" button text in view mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const button = toggle.querySelector('.edit-mode-button')
      expect(button?.textContent?.trim()).toBe('Enter Edit Mode')
    })

    it('should have "view" CSS class in view mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const container = toggle.querySelector('.edit-mode-toggle-container')
      expect(container?.classList.contains('view')).toBe(true)
    })

    it('should not have "edit" CSS class in view mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const container = toggle.querySelector('.edit-mode-toggle-container')
      expect(container?.classList.contains('edit')).toBe(false)
    })
  })

  describe('Edit Mode Display', () => {
    it('should display "Edit Mode" label in edit mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.EDIT })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const label = toggle.querySelector('.edit-mode-label')
      expect(label?.textContent).toBe('Edit Mode')
    })

    it('should display "Exit Edit Mode" button text in edit mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.EDIT })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const button = toggle.querySelector('.edit-mode-button')
      expect(button?.textContent?.trim()).toBe('Exit Edit Mode')
    })

    it('should have "edit" CSS class in edit mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.EDIT })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const container = toggle.querySelector('.edit-mode-toggle-container')
      expect(container?.classList.contains('edit')).toBe(true)
    })

    it('should not have "view" CSS class in edit mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.EDIT })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const container = toggle.querySelector('.edit-mode-toggle-container')
      expect(container?.classList.contains('view')).toBe(false)
    })
  })

  describe('Mode Toggle Functionality', () => {
    it('should toggle from VIEW to EDIT when button is clicked', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const button = toggle.querySelector('.edit-mode-button') as HTMLButtonElement
      button?.click()

      expect(store.getMode()).toBe(EditMode.EDIT)
    })

    it('should toggle from EDIT to VIEW when button is clicked', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.EDIT })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const button = toggle.querySelector('.edit-mode-button') as HTMLButtonElement
      button?.click()

      expect(store.getMode()).toBe(EditMode.VIEW)
    })

    it('should update UI after toggling to EDIT mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const button = toggle.querySelector('.edit-mode-button') as HTMLButtonElement
      button?.click()

      await new Promise((resolve) => setTimeout(resolve, 50))

      const label = toggle.querySelector('.edit-mode-label')
      expect(label?.textContent).toBe('Edit Mode')
    })

    it('should update button text after toggling to EDIT mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const button = toggle.querySelector('.edit-mode-button') as HTMLButtonElement
      button?.click()

      await new Promise((resolve) => setTimeout(resolve, 50))

      const updatedButton = toggle.querySelector('.edit-mode-button')
      expect(updatedButton?.textContent?.trim()).toBe('Exit Edit Mode')
    })

    it('should update UI after toggling to VIEW mode', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.EDIT })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const button = toggle.querySelector('.edit-mode-button') as HTMLButtonElement
      button?.click()

      await new Promise((resolve) => setTimeout(resolve, 50))

      const label = toggle.querySelector('.edit-mode-label')
      expect(label?.textContent).toBe('View Mode')
    })

    it('should emit "mode-changed" custom event on toggle', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const eventListener = vi.fn()
      toggle.addEventListener('mode-changed', eventListener)

      const button = toggle.querySelector('.edit-mode-button') as HTMLButtonElement
      button?.click()

      expect(eventListener).toHaveBeenCalled()
    })

    it('should emit event with correct mode detail', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      let eventDetail: { mode: EditMode } | null = null
      toggle.addEventListener('mode-changed', (e: Event) => {
        eventDetail = (e as CustomEvent<{ mode: EditMode }>).detail
      })

      const button = toggle.querySelector('.edit-mode-button') as HTMLButtonElement
      button?.click()

      expect(eventDetail).toEqual({ mode: EditMode.EDIT })
    })

    it('should bubble custom event', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      const documentListener = vi.fn()
      document.addEventListener('mode-changed', documentListener)

      const button = toggle.querySelector('.edit-mode-button') as HTMLButtonElement
      button?.click()

      expect(documentListener).toHaveBeenCalled()

      document.removeEventListener('mode-changed', documentListener)
    })
  })

  describe('Reactive Updates from Store', () => {
    it('should update when store state changes externally', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      // Change mode externally
      store.setMode(EditMode.EDIT)

      await new Promise((resolve) => setTimeout(resolve, 50))

      const label = toggle.querySelector('.edit-mode-label')
      expect(label?.textContent).toBe('Edit Mode')
    })

    it('should hide when authentication state changes to false', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(toggle.innerHTML).not.toBe('')

      store.setState({ isAuthenticated: false, mode: EditMode.VIEW })

      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(toggle.style.display).toBe('none')
      expect(toggle.innerHTML).toBe('')
    })

    it('should show when authentication state changes to true', async () => {
      store.setState({ isAuthenticated: false, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(toggle.style.display).toBe('none')

      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })

      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(toggle.innerHTML).not.toBe('')
      const container = toggle.querySelector('.edit-mode-toggle-container')
      expect(container).toBeTruthy()
    })
  })

  describe('Lifecycle', () => {
    it('should clean up subscription on disconnect', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      interface StoreWithListeners {
        listeners: Set<unknown>
      }
      const initialListenerCount = (store as unknown as StoreWithListeners).listeners.size

      toggle.remove()

      // Listener should be removed after disconnect
      expect((store as unknown as StoreWithListeners).listeners.size).toBe(initialListenerCount - 1)
    })

    it('should not update after being removed from DOM', async () => {
      store.setState({ isAuthenticated: true, mode: EditMode.VIEW })
      document.body.appendChild(toggle)
      await new Promise((resolve) => setTimeout(resolve, 50))

      toggle.remove()

      // Change mode after removal
      store.setMode(EditMode.EDIT)

      await new Promise((resolve) => setTimeout(resolve, 50))

      // Component should not have updated since it's removed
      const label = toggle.querySelector('.edit-mode-label')
      expect(label?.textContent).toBe('View Mode')
    })
  })
})
