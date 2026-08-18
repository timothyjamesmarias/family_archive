import { type IndividualRequest } from '../types/mutations'
import { Sex, SEX_LABELS } from '../constants'
import { escapeHtml } from '../../../shared/escape_html'

/**
 * Mode for the person form modal.
 */
export type PersonFormMode = 'create' | 'edit'

/**
 * Data passed when opening the modal.
 */
export interface PersonFormData {
  mode: PersonFormMode
  title: string
  individual?: IndividualRequest & { id?: number }
}

/**
 * Web component for creating or editing a person.
 * Modal with backdrop, form validation, and submit/cancel actions.
 */
export class PersonFormModal extends HTMLElement {
  private formData: PersonFormData | null = null
  private onSubmitCallback: ((data: IndividualRequest) => void | Promise<void>) | null = null

  constructor() {
    super()
  }

  /**
   * Open the modal with specified data.
   *
   * @param data - Form configuration and initial values
   * @param onSubmit - Callback when form is submitted
   */
  open(data: PersonFormData, onSubmit: (data: IndividualRequest) => void | Promise<void>) {
    this.formData = data
    this.onSubmitCallback = onSubmit
    this.render()
    this.style.display = 'flex'

    // Focus first input
    setTimeout(() => {
      const firstInput = this.querySelector('input') as HTMLInputElement
      firstInput?.focus()
    }, 100)
  }

  /**
   * Close the modal.
   */
  close() {
    this.style.display = 'none'
    this.innerHTML = ''
    this.formData = null
    this.onSubmitCallback = null
  }

  private render() {
    if (!this.formData) return

    const { mode, title, individual } = this.formData

    this.innerHTML = `
      <div class="modal-backdrop"></div>
      <div class="modal-container">
        <div class="modal-header">
          <h2 class="modal-title">${escapeHtml(title)}</h2>
          <button class="modal-close" type="button" aria-label="Close">&times;</button>
        </div>
        <form class="modal-form">
          <div class="form-group">
            <label for="givenName">Given Name</label>
            <input
              type="text"
              id="givenName"
              name="givenName"
              value="${escapeHtml(individual?.givenName || '')}"
              placeholder="e.g., John"
            />
          </div>

          <div class="form-group">
            <label for="surname">Surname</label>
            <input
              type="text"
              id="surname"
              name="surname"
              value="${escapeHtml(individual?.surname || '')}"
              placeholder="e.g., Doe"
            />
          </div>

          <div class="form-group">
            <label>Sex</label>
            <div class="radio-group">
              <label class="radio-label">
                <input
                  type="radio"
                  name="sex"
                  value="${Sex.MALE}"
                  ${individual?.sex === Sex.MALE ? 'checked' : ''}
                />
                ${SEX_LABELS[Sex.MALE]}
              </label>
              <label class="radio-label">
                <input
                  type="radio"
                  name="sex"
                  value="${Sex.FEMALE}"
                  ${individual?.sex === Sex.FEMALE ? 'checked' : ''}
                />
                ${SEX_LABELS[Sex.FEMALE]}
              </label>
              <label class="radio-label">
                <input
                  type="radio"
                  name="sex"
                  value=""
                  ${!individual?.sex ? 'checked' : ''}
                />
                Unknown
              </label>
            </div>
          </div>

          <div class="form-section-title">Birth Information</div>

          <div class="form-group">
            <label for="birthDate">Birth Date</label>
            <input
              type="text"
              id="birthDate"
              name="birthDate"
              value="${escapeHtml(individual?.birthDate || '')}"
              placeholder="e.g., 15 Jan 1980"
            />
          </div>

          <div class="form-group">
            <label for="birthPlace">Birth Place</label>
            <input
              type="text"
              id="birthPlace"
              name="birthPlace"
              value="${escapeHtml(individual?.birthPlace || '')}"
              placeholder="e.g., New York, USA"
            />
          </div>

          <div class="form-section-title">Death Information</div>

          <div class="form-group">
            <label for="deathDate">Death Date</label>
            <input
              type="text"
              id="deathDate"
              name="deathDate"
              value="${escapeHtml(individual?.deathDate || '')}"
              placeholder="e.g., 20 Mar 2050"
            />
          </div>

          <div class="form-group">
            <label for="deathPlace">Death Place</label>
            <input
              type="text"
              id="deathPlace"
              name="deathPlace"
              value="${escapeHtml(individual?.deathPlace || '')}"
              placeholder="e.g., Los Angeles, USA"
            />
          </div>

          <div class="form-validation-message"></div>

          <div class="modal-actions">
            <button type="button" class="btn btn-cancel">Cancel</button>
            <button type="submit" class="btn btn-primary">${mode === 'edit' ? 'Save' : 'Create'}</button>
          </div>
        </form>
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

    // Inject global modal styles
    const styleId = 'person-form-modal-styles'
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style')
      style.id = styleId
      style.textContent = `
        .modal-backdrop {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: rgba(0, 0, 0, 0.5);
          backdrop-filter: blur(4px);
        }

        .modal-container {
          position: relative;
          background: white;
          border-radius: 12px;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
          width: 90%;
          max-width: 500px;
          max-height: 90vh;
          overflow-y: auto;
          animation: modalSlideIn 0.2s ease-out;
        }

        @keyframes modalSlideIn {
          from {
            opacity: 0;
            transform: translateY(-20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        .modal-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 20px 24px;
          border-bottom: 1px solid #e0e0e0;
        }

        .modal-title {
          margin: 0;
          font-size: 20px;
          font-weight: 600;
          color: #333;
        }

        .modal-close {
          background: none;
          border: none;
          font-size: 32px;
          line-height: 1;
          color: #666;
          cursor: pointer;
          padding: 0;
          width: 32px;
          height: 32px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 4px;
          transition: background-color 0.2s;
        }

        .modal-close:hover {
          background-color: #f5f5f5;
          color: #333;
        }

        .modal-form {
          padding: 24px;
        }

        .form-group {
          margin-bottom: 20px;
        }

        .form-group label {
          display: block;
          margin-bottom: 6px;
          font-size: 14px;
          font-weight: 500;
          color: #555;
        }

        .form-group input[type="text"] {
          width: 100%;
          padding: 10px 12px;
          font-size: 14px;
          border: 1px solid #ccc;
          border-radius: 6px;
          transition: border-color 0.2s;
          box-sizing: border-box;
        }

        .form-group input[type="text"]:focus {
          outline: none;
          border-color: #2196f3;
          box-shadow: 0 0 0 3px rgba(33, 150, 243, 0.1);
        }

        .radio-group {
          display: flex;
          gap: 16px;
        }

        .radio-label {
          display: flex;
          align-items: center;
          gap: 6px;
          font-size: 14px;
          color: #555;
          cursor: pointer;
        }

        .radio-label input[type="radio"] {
          cursor: pointer;
        }

        .form-section-title {
          font-size: 15px;
          font-weight: 600;
          color: #333;
          margin-top: 20px;
          margin-bottom: 12px;
          padding-bottom: 8px;
          border-bottom: 2px solid #e0e0e0;
        }

        .form-validation-message {
          min-height: 24px;
          padding: 0 4px;
          font-size: 13px;
          color: #d32f2f;
          margin-bottom: 12px;
        }

        .modal-actions {
          display: flex;
          gap: 12px;
          justify-content: flex-end;
          margin-top: 24px;
        }

        .btn {
          padding: 10px 20px;
          font-size: 14px;
          font-weight: 500;
          border: none;
          border-radius: 6px;
          cursor: pointer;
          transition: all 0.2s;
        }

        .btn:active {
          transform: scale(0.98);
        }

        .btn-cancel {
          background: #f5f5f5;
          color: #666;
        }

        .btn-cancel:hover {
          background: #e0e0e0;
          color: #333;
        }

        .btn-primary {
          background: #2196f3;
          color: white;
        }

        .btn-primary:hover {
          background: #1976d2;
        }

        .btn-primary:disabled {
          background: #ccc;
          cursor: not-allowed;
        }
      `
      document.head.appendChild(style)
    }
  }

  private attachEventListeners() {
    // Close button
    const closeBtn = this.querySelector('.modal-close') as HTMLButtonElement
    closeBtn?.addEventListener('click', () => this.close())

    // Cancel button
    const cancelBtn = this.querySelector('.btn-cancel') as HTMLButtonElement
    cancelBtn?.addEventListener('click', () => this.close())

    // Backdrop click
    const backdrop = this.querySelector('.modal-backdrop') as HTMLElement
    backdrop?.addEventListener('click', () => this.close())

    // Form submit
    const form = this.querySelector('.modal-form') as HTMLFormElement
    form?.addEventListener('submit', (e) => this.handleSubmit(e))

    // ESC key to close
    const escListener = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        this.close()
        document.removeEventListener('keydown', escListener)
      }
    }
    document.addEventListener('keydown', escListener)
  }

  private handleSubmit(e: Event) {
    e.preventDefault()

    const form = e.target as HTMLFormElement
    const formData = new FormData(form)

    const givenName = formData.get('givenName') as string
    const surname = formData.get('surname') as string
    const sex = formData.get('sex') as string
    const birthDate = formData.get('birthDate') as string
    const birthPlace = formData.get('birthPlace') as string
    const deathDate = formData.get('deathDate') as string
    const deathPlace = formData.get('deathPlace') as string

    // Validation: at least one name required
    if (!givenName?.trim() && !surname?.trim()) {
      this.showValidationError('Please provide at least a given name or surname')
      return
    }

    const individualRequest: IndividualRequest = {
      givenName: givenName?.trim() || null,
      surname: surname?.trim() || null,
      sex: sex === 'M' || sex === 'F' ? sex : null,
      birthDate: birthDate?.trim() || null,
      birthPlace: birthPlace?.trim() || null,
      deathDate: deathDate?.trim() || null,
      deathPlace: deathPlace?.trim() || null,
    }

    // Call the submit callback
    if (this.onSubmitCallback) {
      this.onSubmitCallback(individualRequest)
    }

    this.close()
  }

  private showValidationError(message: string) {
    const messageEl = this.querySelector('.form-validation-message') as HTMLElement
    if (messageEl) {
      messageEl.textContent = message
      messageEl.style.display = 'block'

      // Clear after 3 seconds
      setTimeout(() => {
        messageEl.textContent = ''
        messageEl.style.display = 'none'
      }, 3000)
    }
  }
}

// Register the custom element
customElements.define('person-form-modal', PersonFormModal)
