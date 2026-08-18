import { escapeHtml } from '../../../shared/escape_html'
/**
 * Data for a family option in the picker.
 */
export interface FamilyOption {
  familyId: number
  spouseName: string | null
}

/**
 * Web component for picking which family to add a child to.
 * Used when a parent has multiple marriages/families.
 */
export class FamilyPickerModal extends HTMLElement {
  private families: FamilyOption[] = []
  private onSelectCallback: ((familyId: number | null) => void) | null = null

  constructor() {
    super()
  }

  /**
   * Open the family picker modal.
   *
   * @param families - List of family options to choose from
   * @param onSelect - Callback when a family is selected (null = create new family)
   */
  open(families: FamilyOption[], onSelect: (familyId: number | null) => void) {
    this.families = families
    this.onSelectCallback = onSelect
    this.render()
    this.style.display = 'flex'
  }

  /**
   * Close the modal.
   */
  close() {
    this.style.display = 'none'
    this.innerHTML = ''
    this.families = []
    this.onSelectCallback = null
  }

  private render() {
    const familyOptions = this.families
      .map((family, index) => {
        const spouseText = family.spouseName || 'Unknown spouse'
        return `
          <label class="family-option">
            <input
              type="radio"
              name="family"
              value="${family.familyId}"
              ${index === 0 ? 'checked' : ''}
            />
            <span class="family-label">Family with ${escapeHtml(spouseText)}</span>
          </label>
        `
      })
      .join('')

    this.innerHTML = `
      <div class="modal-backdrop"></div>
      <div class="modal-container">
        <div class="modal-header">
          <h2 class="modal-title">Which Family?</h2>
          <button class="modal-close" type="button" aria-label="Close">&times;</button>
        </div>
        <div class="modal-content">
          <p class="modal-description">
            This person has multiple families. Which family should the child belong to?
          </p>
          <form class="family-picker-form">
            <div class="family-options">
              ${familyOptions}
              <label class="family-option">
                <input
                  type="radio"
                  name="family"
                  value="new"
                />
                <span class="family-label">Create new family</span>
              </label>
            </div>
            <div class="modal-actions">
              <button type="button" class="btn btn-cancel">Cancel</button>
              <button type="submit" class="btn btn-primary">Continue</button>
            </div>
          </form>
        </div>
      </div>
    `

    this.applyStyles()
    this.attachEventListeners()
  }

  private applyStyles() {
    // Component container styles
    this.style.cssText = `
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      z-index: 2000;
      align-items: center;
      justify-content: center;
    `

    // Inject global modal styles (reuse some from person-form-modal)
    const styleId = 'family-picker-modal-styles'
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style')
      style.id = styleId
      style.textContent = `
        .modal-content {
          padding: 24px;
        }

        .modal-description {
          margin: 0 0 20px 0;
          font-size: 14px;
          color: #666;
          line-height: 1.5;
        }

        .family-picker-form {
          display: flex;
          flex-direction: column;
          gap: 20px;
        }

        .family-options {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .family-option {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 12px 16px;
          border: 2px solid #e0e0e0;
          border-radius: 8px;
          cursor: pointer;
          transition: all 0.2s;
        }

        .family-option:hover {
          border-color: #2196f3;
          background-color: #f5f9ff;
        }

        .family-option:has(input:checked) {
          border-color: #2196f3;
          background-color: #e3f2fd;
        }

        .family-option input[type="radio"] {
          cursor: pointer;
          width: 18px;
          height: 18px;
          flex-shrink: 0;
        }

        .family-label {
          font-size: 14px;
          font-weight: 500;
          color: #333;
          flex: 1;
        }
      `
      document.head.appendChild(style)
    }
  }

  private attachEventListeners() {
    // Close button
    const closeBtn = this.querySelector('.modal-close') as HTMLButtonElement
    closeBtn?.addEventListener('click', () => this.handleCancel())

    // Cancel button
    const cancelBtn = this.querySelector('.btn-cancel') as HTMLButtonElement
    cancelBtn?.addEventListener('click', () => this.handleCancel())

    // Backdrop click
    const backdrop = this.querySelector('.modal-backdrop') as HTMLElement
    backdrop?.addEventListener('click', () => this.handleCancel())

    // Form submit
    const form = this.querySelector('.family-picker-form') as HTMLFormElement
    form?.addEventListener('submit', (e) => this.handleSubmit(e))

    // ESC key to close
    const escListener = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        this.handleCancel()
        document.removeEventListener('keydown', escListener)
      }
    }
    document.addEventListener('keydown', escListener)
  }

  private handleCancel() {
    if (this.onSelectCallback) {
      // Cancel means don't proceed with operation
      this.onSelectCallback(null)
    }
    this.close()
  }

  private handleSubmit(e: Event) {
    e.preventDefault()

    const form = e.target as HTMLFormElement
    const formData = new FormData(form)
    const selectedValue = formData.get('family') as string

    if (selectedValue === 'new') {
      // User wants to create a new family
      if (this.onSelectCallback) {
        this.onSelectCallback(null)
      }
    } else {
      // User selected an existing family
      const familyId = parseInt(selectedValue, 10)
      if (this.onSelectCallback) {
        this.onSelectCallback(familyId)
      }
    }

    this.close()
  }
}

// Register the custom element
customElements.define('family-picker-modal', FamilyPickerModal)
