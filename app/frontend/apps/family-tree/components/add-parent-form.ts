import { type Modal } from '../../../shared/components/modal'
import { type IndividualRequest } from '../types/mutations'
import { ParentRole, PARENT_ROLE_LABELS, PARENT_ROLE_TO_SEX, ANIMATION_TIMING } from '../constants'
import { escapeHtml } from '../../../shared/escape_html'

/**
 * Two-step form for adding a parent.
 * Step 1: Select parent role (Father/Mother)
 * Step 2: Enter parent details
 */
export class AddParentForm extends HTMLElement {
  private selectedRole: ParentRole | null = null
  private modal: Modal | null = null
  private onSubmitCallback:
    ((data: IndividualRequest, role: ParentRole) => void | Promise<void>) | null = null
  private childName: string = ''
  private isClosing: boolean = false

  constructor() {
    super()
  }

  /**
   * Open the add parent form.
   *
   * @param childName - Name of the child for context
   * @param onSubmit - Callback when form is submitted
   */
  open(
    childName: string,
    onSubmit: (data: IndividualRequest, role: ParentRole) => void | Promise<void>
  ) {
    this.childName = childName
    this.onSubmitCallback = onSubmit
    this.selectedRole = null

    // Always create a fresh modal
    this.modal = document.createElement('generic-modal') as Modal
    this.appendChild(this.modal)

    this.renderStep1()
  }

  /**
   * Close the form and modal.
   */
  close() {
    if (this.isClosing) return // Prevent double-close
    this.isClosing = true

    if (this.modal) {
      this.modal.close()
      this.modal.remove()
      this.modal = null
    }
    this.selectedRole = null
    this.onSubmitCallback = null
    this.isClosing = false
  }

  private renderStep1() {
    if (!this.modal) return

    const content = `
      <div class="add-parent-step1">
        <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.5; color: #374151;">
          Adding parent to <strong>${escapeHtml(this.childName)}</strong>
        </p>
        <p style="margin: 0 0 16px 0; font-size: 14px; color: #6b7280;">
          Select which parent role:
        </p>
        <div class="parent-role-options" style="
          display: flex;
          flex-direction: column;
          gap: 12px;
        ">
          <button class="role-option" data-role="${ParentRole.FATHER}" style="
            padding: 16px;
            border: 2px solid #e5e7eb;
            background: white;
            border-radius: 8px;
            cursor: pointer;
            text-align: left;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            gap: 12px;
          ">
            <span style="font-size: 24px;">👨</span>
            <div>
              <div style="font-size: 15px; font-weight: 600; color: #111827;">${PARENT_ROLE_LABELS[ParentRole.FATHER]}</div>
              <div style="font-size: 13px; color: #6b7280;">Add male parent</div>
            </div>
          </button>
          <button class="role-option" data-role="${ParentRole.MOTHER}" style="
            padding: 16px;
            border: 2px solid #e5e7eb;
            background: white;
            border-radius: 8px;
            cursor: pointer;
            text-align: left;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            gap: 12px;
          ">
            <span style="font-size: 24px;">👩</span>
            <div>
              <div style="font-size: 15px; font-weight: 600; color: #111827;">${PARENT_ROLE_LABELS[ParentRole.MOTHER]}</div>
              <div style="font-size: 13px; color: #6b7280;">Add female parent</div>
            </div>
          </button>
        </div>
      </div>
    `

    this.modal.open({
      title: 'Add Parent - Step 1 of 2',
      content,
      maxWidth: '450px',
      closeOnBackdropClick: true,
      onClose: () => this.close(),
    })

    // Attach event listeners
    setTimeout(() => {
      const roleOptions = this.modal?.querySelectorAll(
        '.role-option'
      ) as NodeListOf<HTMLButtonElement>
      roleOptions?.forEach((btn) => {
        btn.addEventListener('click', () => {
          const role = btn.getAttribute('data-role') as ParentRole
          this.selectRole(role)
        })

        // Hover effects
        btn.addEventListener('mouseenter', () => {
          btn.style.borderColor = '#3b82f6'
          btn.style.background = '#eff6ff'
        })
        btn.addEventListener('mouseleave', () => {
          btn.style.borderColor = '#e5e7eb'
          btn.style.background = 'white'
        })
      })
    }, ANIMATION_TIMING.EVENT_LISTENER_DELAY)
  }

  private selectRole(role: ParentRole) {
    this.selectedRole = role
    this.renderStep2()
  }

  private renderStep2() {
    if (!this.modal || !this.selectedRole) return

    const sex = PARENT_ROLE_TO_SEX[this.selectedRole]
    const roleLabel = PARENT_ROLE_LABELS[this.selectedRole]

    const content = `
      <form class="parent-details-form">
        <div style="margin-bottom: 20px;">
          <label style="display: block; font-size: 14px; font-weight: 500; color: #374151; margin-bottom: 6px;">
            Given Name
          </label>
          <input
            type="text"
            name="givenName"
            placeholder="Enter given name"
            style="
              width: 100%;
              padding: 10px 12px;
              border: 1px solid #d1d5db;
              border-radius: 6px;
              font-size: 14px;
              box-sizing: border-box;
            "
          />
        </div>

        <div style="margin-bottom: 20px;">
          <label style="display: block; font-size: 14px; font-weight: 500; color: #374151; margin-bottom: 6px;">
            Surname
          </label>
          <input
            type="text"
            name="surname"
            placeholder="Enter surname"
            style="
              width: 100%;
              padding: 10px 12px;
              border: 1px solid #d1d5db;
              border-radius: 6px;
              font-size: 14px;
              box-sizing: border-box;
            "
          />
        </div>

        <div style="margin-bottom: 24px;">
          <label style="display: block; font-size: 14px; font-weight: 500; color: #374151; margin-bottom: 6px;">
            Sex
          </label>
          <input
            type="text"
            name="sex"
            value="${sex}"
            readonly
            style="
              width: 100%;
              padding: 10px 12px;
              border: 1px solid #e5e7eb;
              border-radius: 6px;
              font-size: 14px;
              background: #f9fafb;
              color: #6b7280;
              box-sizing: border-box;
            "
          />
          <p style="margin: 4px 0 0 0; font-size: 12px; color: #6b7280;">
            Sex is automatically set based on ${roleLabel} role
          </p>
        </div>

        <div class="validation-error" style="
          display: none;
          padding: 12px;
          background: #fee2e2;
          border: 1px solid #fecaca;
          border-radius: 6px;
          color: #991b1b;
          font-size: 14px;
          margin-bottom: 16px;
        "></div>

        <div style="display: flex; gap: 12px; justify-content: space-between;">
          <button type="button" class="btn-back" style="
            padding: 10px 20px;
            border: 1px solid #d1d5db;
            background: white;
            color: #374151;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
          ">← Back</button>
          <button type="submit" class="btn-submit" style="
            padding: 10px 20px;
            border: none;
            background: #3b82f6;
            color: white;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
          ">Add ${roleLabel}</button>
        </div>
      </form>
    `

    this.modal.open({
      title: `Add ${roleLabel} - Step 2 of 2`,
      content,
      maxWidth: '450px',
      closeOnBackdropClick: false,
      autoFocus: true,
      onClose: () => this.close(),
    })

    // Attach event listeners
    setTimeout(() => {
      const form = this.modal?.querySelector('.parent-details-form') as HTMLFormElement
      const backBtn = this.modal?.querySelector('.btn-back') as HTMLButtonElement
      const submitBtn = this.modal?.querySelector('.btn-submit') as HTMLButtonElement

      backBtn?.addEventListener('click', () => {
        this.renderStep1()
      })

      form?.addEventListener('submit', (e) => this.handleSubmit(e))

      // Hover effects
      backBtn?.addEventListener('mouseenter', () => {
        backBtn.style.background = '#f3f4f6'
      })
      backBtn?.addEventListener('mouseleave', () => {
        backBtn.style.background = 'white'
      })

      submitBtn?.addEventListener('mouseenter', () => {
        submitBtn.style.background = '#2563eb'
      })
      submitBtn?.addEventListener('mouseleave', () => {
        submitBtn.style.background = '#3b82f6'
      })
    }, ANIMATION_TIMING.EVENT_LISTENER_DELAY)
  }

  private handleSubmit(e: Event) {
    e.preventDefault()

    const form = e.target as HTMLFormElement
    const formData = new FormData(form)

    const givenName = (formData.get('givenName') as string)?.trim()
    const surname = (formData.get('surname') as string)?.trim()

    // Validation: at least one name required
    if (!givenName && !surname) {
      this.showValidationError('Please provide at least a given name or surname')
      return
    }

    if (!this.selectedRole) {
      this.showValidationError('Parent role not selected')
      return
    }

    // Clear validation error
    this.hideValidationError()

    // Create request object
    const request: IndividualRequest = {
      givenName: givenName || null,
      surname: surname || null,
      sex: PARENT_ROLE_TO_SEX[this.selectedRole],
    }

    // Call callback
    if (this.onSubmitCallback) {
      this.onSubmitCallback(request, this.selectedRole)
    }

    this.close()
  }

  private showValidationError(message: string) {
    const errorDiv = this.modal?.querySelector('.validation-error') as HTMLElement
    if (errorDiv) {
      errorDiv.textContent = message
      errorDiv.style.display = 'block'
    }
  }

  private hideValidationError() {
    const errorDiv = this.modal?.querySelector('.validation-error') as HTMLElement
    if (errorDiv) {
      errorDiv.style.display = 'none'
    }
  }
}

// Register the custom element
customElements.define('add-parent-form', AddParentForm)
