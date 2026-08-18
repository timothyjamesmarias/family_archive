import { describe, it, expect, beforeEach, vi, afterEach, type Mock } from 'vitest'
import '../add-parent-form'
import '../../../../shared/components/modal'
import { type AddParentForm } from '../add-parent-form'
import type { IndividualRequest } from '../../types/mutations'
import type { ParentRole } from '../../constants'

describe('AddParentForm', () => {
  let form: AddParentForm
  let onSubmitCallback: Mock<(data: IndividualRequest, role: ParentRole) => void>

  beforeEach(async () => {
    form = document.createElement('add-parent-form') as AddParentForm
    document.body.appendChild(form)
    await customElements.whenDefined('add-parent-form')
    await customElements.whenDefined('generic-modal')
    await new Promise((resolve) => setTimeout(resolve, 0))
    onSubmitCallback = vi.fn()
  })

  afterEach(() => {
    form.remove()
    document.body.innerHTML = ''
  })

  describe('Form Initialization', () => {
    it('should open with step 1', () => {
      form.open('John Doe', onSubmitCallback)

      const modal = form.querySelector<HTMLElement>('generic-modal')
      expect(modal).toBeTruthy()
      expect(modal?.style.display).toBe('flex')
    })

    it('should display child name in step 1', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const content = modal?.innerHTML || ''
      expect(content).toContain('John Doe')
    })

    it('should escape HTML in child name', async () => {
      form.open('<script>alert("xss")</script>', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const content = modal?.innerHTML || ''
      expect(content).not.toContain('<script>')
      expect(content).toContain('&lt;script&gt;')
    })

    it('should display step 1 title', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const title = modal?.querySelector('.modal-title')
      expect(title?.textContent).toBe('Add Parent - Step 1 of 2')
    })
  })

  describe('Step 1: Role Selection', () => {
    it('should display both role options', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const roleOptions = modal?.querySelectorAll('.role-option')
      expect(roleOptions?.length).toBe(2)
    })

    it('should have Father option with correct data attribute', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]')
      expect(fatherOption).toBeTruthy()
      expect(fatherOption?.textContent).toContain('Father')
    })

    it('should have Mother option with correct data attribute', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const motherOption = modal?.querySelector('[data-role="MOTHER"]')
      expect(motherOption).toBeTruthy()
      expect(motherOption?.textContent).toContain('Mother')
    })

    it('should transition to step 2 when Father is selected', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()

      await new Promise((resolve) => setTimeout(resolve, 100))

      const title = modal?.querySelector('.modal-title')
      expect(title?.textContent).toBe('Add Father - Step 2 of 2')
    })

    it('should transition to step 2 when Mother is selected', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const motherOption = modal?.querySelector('[data-role="MOTHER"]') as HTMLButtonElement
      motherOption?.click()

      await new Promise((resolve) => setTimeout(resolve, 100))

      const title = modal?.querySelector('.modal-title')
      expect(title?.textContent).toBe('Add Mother - Step 2 of 2')
    })
  })

  describe('Step 2: Parent Details Form', () => {
    it('should render form fields in step 2', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()

      await new Promise((resolve) => setTimeout(resolve, 100))

      expect(modal?.querySelector('input[name="givenName"]')).toBeTruthy()
      expect(modal?.querySelector('input[name="surname"]')).toBeTruthy()
      expect(modal?.querySelector('input[name="sex"]')).toBeTruthy()
    })

    it('should set sex to M when Father role is selected', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()

      await new Promise((resolve) => setTimeout(resolve, 100))

      const sexInput = modal?.querySelector('input[name="sex"]') as HTMLInputElement
      expect(sexInput?.value).toBe('M')
    })

    it('should set sex to F when Mother role is selected', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const motherOption = modal?.querySelector('[data-role="MOTHER"]') as HTMLButtonElement
      motherOption?.click()

      await new Promise((resolve) => setTimeout(resolve, 100))

      const sexInput = modal?.querySelector('input[name="sex"]') as HTMLInputElement
      expect(sexInput?.value).toBe('F')
    })

    it('should make sex field readonly', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()

      await new Promise((resolve) => setTimeout(resolve, 100))

      const sexInput = modal?.querySelector('input[name="sex"]') as HTMLInputElement
      expect(sexInput?.hasAttribute('readonly')).toBe(true)
    })

    it('should display Back button in step 2', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()

      await new Promise((resolve) => setTimeout(resolve, 100))

      const backBtn = modal?.querySelector('.btn-back')
      expect(backBtn).toBeTruthy()
      expect(backBtn?.textContent).toContain('Back')
    })

    it('should display submit button with role label', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const motherOption = modal?.querySelector('[data-role="MOTHER"]') as HTMLButtonElement
      motherOption?.click()

      await new Promise((resolve) => setTimeout(resolve, 100))

      const submitBtn = modal?.querySelector('.btn-submit')
      expect(submitBtn?.textContent).toContain('Add Mother')
    })
  })

  describe('Navigation Between Steps', () => {
    it('should go back to step 1 when Back button is clicked', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')

      // Go to step 2
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      // Click back
      const backBtn = modal?.querySelector('.btn-back') as HTMLButtonElement
      backBtn?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      // Should be back at step 1
      const title = modal?.querySelector('.modal-title')
      expect(title?.textContent).toBe('Add Parent - Step 1 of 2')
    })

    it('should reset selection when going back to step 1', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')

      // Select Father
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      // Go back
      const backBtn = modal?.querySelector('.btn-back') as HTMLButtonElement
      backBtn?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      // Select Mother - should work without issues
      const motherOption = modal?.querySelector('[data-role="MOTHER"]') as HTMLButtonElement
      motherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const title = modal?.querySelector('.modal-title')
      expect(title?.textContent).toBe('Add Mother - Step 2 of 2')
    })
  })

  describe('Form Validation', () => {
    it('should show error when both names are empty', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      parentForm?.dispatchEvent(new Event('submit'))

      await new Promise((resolve) => setTimeout(resolve, 50))

      const validationError = modal?.querySelector('.validation-error') as HTMLElement
      expect(validationError?.style.display).toBe('block')
      expect(validationError?.textContent).toBe('Please provide at least a given name or surname')
      expect(onSubmitCallback).not.toHaveBeenCalled()
    })

    it('should show error when names contain only whitespace', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const givenNameInput = modal?.querySelector('input[name="givenName"]') as HTMLInputElement
      const surnameInput = modal?.querySelector('input[name="surname"]') as HTMLInputElement
      givenNameInput.value = '   '
      surnameInput.value = '   '

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      parentForm?.dispatchEvent(new Event('submit'))

      await new Promise((resolve) => setTimeout(resolve, 50))

      const validationError = modal?.querySelector('.validation-error') as HTMLElement
      expect(validationError?.style.display).toBe('block')
      expect(onSubmitCallback).not.toHaveBeenCalled()
    })

    it('should accept form with only given name', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const givenNameInput = modal?.querySelector('input[name="givenName"]') as HTMLInputElement
      givenNameInput.value = 'Robert'

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      parentForm?.dispatchEvent(new Event('submit'))

      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(onSubmitCallback).toHaveBeenCalled()
    })

    it('should accept form with only surname', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const motherOption = modal?.querySelector('[data-role="MOTHER"]') as HTMLButtonElement
      motherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const surnameInput = modal?.querySelector('input[name="surname"]') as HTMLInputElement
      surnameInput.value = 'Smith'

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      parentForm?.dispatchEvent(new Event('submit'))

      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(onSubmitCallback).toHaveBeenCalled()
    })
  })

  describe('Form Submission', () => {
    it('should call callback with correct data for Father', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const givenNameInput = modal?.querySelector('input[name="givenName"]') as HTMLInputElement
      const surnameInput = modal?.querySelector('input[name="surname"]') as HTMLInputElement
      givenNameInput.value = 'Robert'
      surnameInput.value = 'Doe'

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      parentForm?.dispatchEvent(new Event('submit'))

      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(onSubmitCallback).toHaveBeenCalledWith(
        {
          givenName: 'Robert',
          surname: 'Doe',
          sex: 'M',
        },
        'FATHER'
      )
    })

    it('should call callback with correct data for Mother', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const motherOption = modal?.querySelector('[data-role="MOTHER"]') as HTMLButtonElement
      motherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const givenNameInput = modal?.querySelector('input[name="givenName"]') as HTMLInputElement
      const surnameInput = modal?.querySelector('input[name="surname"]') as HTMLInputElement
      givenNameInput.value = 'Mary'
      surnameInput.value = 'Smith'

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      parentForm?.dispatchEvent(new Event('submit'))

      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(onSubmitCallback).toHaveBeenCalledWith(
        {
          givenName: 'Mary',
          surname: 'Smith',
          sex: 'F',
        },
        'MOTHER'
      )
    })

    it('should trim whitespace from names', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const givenNameInput = modal?.querySelector('input[name="givenName"]') as HTMLInputElement
      const surnameInput = modal?.querySelector('input[name="surname"]') as HTMLInputElement
      givenNameInput.value = '  Robert  '
      surnameInput.value = '  Doe  '

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      parentForm?.dispatchEvent(new Event('submit'))

      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(onSubmitCallback).toHaveBeenCalledWith(
        expect.objectContaining({
          givenName: 'Robert',
          surname: 'Doe',
        }),
        'FATHER'
      )
    })

    it('should convert empty strings to null', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const givenNameInput = modal?.querySelector('input[name="givenName"]') as HTMLInputElement
      givenNameInput.value = 'Robert'
      // Leave surname empty

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      parentForm?.dispatchEvent(new Event('submit'))

      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(onSubmitCallback).toHaveBeenCalledWith(
        {
          givenName: 'Robert',
          surname: null,
          sex: 'M',
        },
        'FATHER'
      )
    })

    it('should close form after successful submission', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const givenNameInput = modal?.querySelector('input[name="givenName"]') as HTMLInputElement
      givenNameInput.value = 'Robert'

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      parentForm?.dispatchEvent(new Event('submit'))

      await new Promise((resolve) => setTimeout(resolve, 100))

      // Modal should be removed from DOM after close
      const modalAfterSubmit = form.querySelector<HTMLElement>('generic-modal')
      expect(modalAfterSubmit).toBeNull()
    })

    it('should prevent default form submission', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      const givenNameInput = modal?.querySelector('input[name="givenName"]') as HTMLInputElement
      givenNameInput.value = 'Robert'

      const parentForm = modal?.querySelector('.parent-details-form') as HTMLFormElement
      const submitEvent = new Event('submit', { cancelable: true })
      const preventDefaultSpy = vi.spyOn(submitEvent, 'preventDefault')

      parentForm?.dispatchEvent(submitEvent)

      expect(preventDefaultSpy).toHaveBeenCalled()
    })
  })

  describe('Form Closure', () => {
    it('should close form when close method is called', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      const modal = form.querySelector<HTMLElement>('generic-modal')
      expect(modal?.style.display).toBe('flex')

      form.close()
      await new Promise((resolve) => setTimeout(resolve, 50))

      expect(modal?.style.display).toBe('none')
    })

    it('should reset to step 1 on reopen', async () => {
      form.open('John Doe', onSubmitCallback)
      await new Promise((resolve) => setTimeout(resolve, 100))

      let modal = form.querySelector<HTMLElement>('generic-modal')

      // Go to step 2
      const fatherOption = modal?.querySelector('[data-role="FATHER"]') as HTMLButtonElement
      fatherOption?.click()
      await new Promise((resolve) => setTimeout(resolve, 100))

      // Close
      form.close()
      await new Promise((resolve) => setTimeout(resolve, 50))

      // Reopen
      form.open('Jane Doe', vi.fn())
      await new Promise((resolve) => setTimeout(resolve, 100))

      // Get new modal reference after reopening
      modal = form.querySelector<HTMLElement>('generic-modal')
      const title = modal?.querySelector('.modal-title')
      expect(title?.textContent).toBe('Add Parent - Step 1 of 2')
    })
  })
})
