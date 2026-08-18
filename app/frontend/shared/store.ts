/**
 * Simple singleton store for global application state.
 * Manages authentication state and provides reactive updates via callbacks.
 */

/**
 * Edit mode enum for type-safe mode switching.
 */
export enum EditMode {
  /** View-only mode - no mutations allowed */
  VIEW = 'VIEW',
  /** Edit mode - mutations allowed (requires authentication) */
  EDIT = 'EDIT',
}

export interface AppState {
  /** Whether the current user is authenticated */
  isAuthenticated: boolean
  /** Optional user information (can be extended later) */
  user?: {
    username?: string
    roles?: string[]
  }
  /** Current edit mode */
  mode: EditMode
}

type StateChangeCallback = (state: AppState) => void

class Store {
  private state: AppState = {
    isAuthenticated: false,
    mode: EditMode.VIEW,
  }

  private listeners: Set<StateChangeCallback> = new Set()

  /**
   * Initialize the store by reading auth state from the DOM.
   * Call this once on app initialization.
   *
   * @param rootElement - The root element with data-auth attribute
   */
  initialize(rootElement: HTMLElement): void {
    const authAttribute = rootElement.getAttribute('data-auth')
    this.state.isAuthenticated = authAttribute === 'true'

    // Could also read user info from data attributes if needed
    // const username = rootElement.getAttribute('data-username')
    // this.state.user = { username }

    this.notifyListeners()
  }

  /**
   * Get the current state (immutable snapshot).
   */
  getState(): Readonly<AppState> {
    return { ...this.state }
  }

  /**
   * Check if the user is authenticated.
   */
  isAuthenticated(): boolean {
    return this.state.isAuthenticated
  }

  /**
   * Get the current edit mode.
   */
  getMode(): EditMode {
    return this.state.mode
  }

  /**
   * Check if edit mode is enabled.
   */
  isEditMode(): boolean {
    return this.state.mode === EditMode.EDIT
  }

  /**
   * Check if mutations are allowed (authenticated + edit mode).
   */
  canEdit(): boolean {
    return this.state.isAuthenticated && this.state.mode === EditMode.EDIT
  }

  /**
   * Toggle between VIEW and EDIT modes.
   * Only allowed if user is authenticated.
   *
   * @returns The new edit mode
   */
  toggleEditMode(): EditMode {
    if (!this.state.isAuthenticated) {
      console.warn('Cannot enable edit mode: user not authenticated')
      return EditMode.VIEW
    }

    this.state.mode = this.state.mode === EditMode.EDIT ? EditMode.VIEW : EditMode.EDIT
    this.notifyListeners()
    return this.state.mode
  }

  /**
   * Set edit mode explicitly.
   *
   * @param mode - The mode to set (VIEW or EDIT)
   * @returns The new edit mode (VIEW if not authenticated and trying to set EDIT)
   */
  setMode(mode: EditMode): EditMode {
    if (!this.state.isAuthenticated && mode === EditMode.EDIT) {
      console.warn('Cannot enable edit mode: user not authenticated')
      return EditMode.VIEW
    }

    this.state.mode = mode
    this.notifyListeners()
    return this.state.mode
  }

  /**
   * Subscribe to state changes.
   * Callback will be called immediately with current state and on every change.
   *
   * @param callback - Function to call when state changes
   * @returns Unsubscribe function
   *
   * @example
   * ```typescript
   * const unsubscribe = store.subscribe((state) => {
   *   if (state.mode === EditMode.EDIT) {
   *     showEditButtons()
   *   } else {
   *     hideEditButtons()
   *   }
   * })
   *
   * // Later, to unsubscribe:
   * unsubscribe()
   * ```
   */
  subscribe(callback: StateChangeCallback): () => void {
    this.listeners.add(callback)

    // Call immediately with current state
    callback(this.getState())

    // Return unsubscribe function
    return () => {
      this.listeners.delete(callback)
    }
  }

  /**
   * Notify all listeners of state change.
   */
  private notifyListeners(): void {
    const currentState = this.getState()
    this.listeners.forEach((callback) => callback(currentState))
  }

  /**
   * Update state (for advanced use cases).
   * Prefer using specific methods like setEditMode() instead.
   *
   * @param updates - Partial state updates
   */
  setState(updates: Partial<AppState>): void {
    this.state = { ...this.state, ...updates }
    this.notifyListeners()
  }
}

/**
 * Global singleton store instance.
 * Import this to access app state from anywhere.
 *
 * @example
 * ```typescript
 * import { store } from './common/store'
 *
 * // Initialize on app load
 * const root = document.getElementById('family-tree-root')
 * store.initialize(root)
 *
 * // Check auth state
 * if (store.isAuthenticated()) {
 *   // Show login button
 * }
 *
 * // Subscribe to changes
 * store.subscribe((state) => {
 *   console.log('Edit mode:', state.mode)
 * })
 * ```
 */
export const store = new Store()
