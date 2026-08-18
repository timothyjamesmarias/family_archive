import { describe, it, expect, beforeEach, vi, afterEach, type Mock } from 'vitest'
import '../person-form-modal'
import { type PersonFormModal } from '../person-form-modal'
import type { IndividualRequest } from '../../types/mutations'

describe('PersonFormModal', () => {
  let modal: PersonFormModal
  let onSubmitCallback: Mock<(data: IndividualRequest) => void>

  beforeEach(async () => {
    modal = document.createElement('person-form-modal') as PersonFormModal
    document.body.appendChild(modal)
    await customElements.whenDefined('person-form-modal')
    await new Promise((resolve) => setTimeout(resolve, 0))
    onSubmitCallback = vi.fn()
  })

  afterEach(() => {
    modal.remove()
    document.body.innerHTML = ''
  })

  describe('Modal Lifecycle', () => {
    it('should be hidden by default', () => {
      expect(modal.style.display).toBe('')
    })

    it('should display when opened', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      expect(modal.style.display).toBe('flex')
    })

    it('should render modal structure when opened', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      expect(modal.querySelector('.modal-backdrop')).toBeTruthy()
      expect(modal.querySelector('.modal-container')).toBeTruthy()
      expect(modal.querySelector('.modal-header')).toBeTruthy()
      expect(modal.querySelector('.modal-form')).toBeTruthy()
    })

    it('should display the correct title', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Add New Person',
        },
        onSubmitCallback
      )

      const title = modal.querySelector('.modal-title')
      expect(title?.textContent).toBe('Add New Person')
    })

    it('should escape HTML in title', () => {
      modal.open(
        {
          mode: 'create',
          title: '<script>alert("xss")</script>',
        },
        onSubmitCallback
      )

      const title = modal.querySelector('.modal-title')
      expect(title?.innerHTML).not.toContain('<script>')
      expect(title?.textContent).toContain('<script>')
    })

    it('should hide when closed', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      modal.close()

      expect(modal.style.display).toBe('none')
      expect(modal.innerHTML).toBe('')
    })

    it('should clear form data on close', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      modal.close()

      // Re-open should not retain previous data
      modal.open(
        {
          mode: 'edit',
          title: 'Edit Person',
        },
        vi.fn()
      )

      const title = modal.querySelector('.modal-title')
      expect(title?.textContent).toBe('Edit Person')
    })
  })

  describe('Form Rendering', () => {
    it('should render all form fields', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      expect(modal.querySelector('#givenName')).toBeTruthy()
      expect(modal.querySelector('#surname')).toBeTruthy()
      expect(modal.querySelector('input[name="sex"]')).toBeTruthy()
      expect(modal.querySelector('#birthDate')).toBeTruthy()
      expect(modal.querySelector('#birthPlace')).toBeTruthy()
      expect(modal.querySelector('#deathDate')).toBeTruthy()
      expect(modal.querySelector('#deathPlace')).toBeTruthy()
    })

    it('should render three sex radio options', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const sexOptions = modal.querySelectorAll('input[name="sex"]')
      expect(sexOptions.length).toBe(3)

      const values = Array.from(sexOptions).map((input) => (input as HTMLInputElement).value)
      expect(values).toEqual(['M', 'F', ''])
    })

    it('should check "Unknown" sex by default', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const unknownOption = modal.querySelector('input[name="sex"][value=""]') as HTMLInputElement
      expect(unknownOption?.checked).toBe(true)
    })

    it('should display "Create" button in create mode', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const submitBtn = modal.querySelector('.btn-primary')
      expect(submitBtn?.textContent).toBe('Create')
    })

    it('should display "Save" button in edit mode', () => {
      modal.open(
        {
          mode: 'edit',
          title: 'Edit Person',
        },
        onSubmitCallback
      )

      const submitBtn = modal.querySelector('.btn-primary')
      expect(submitBtn?.textContent).toBe('Save')
    })
  })

  describe('Pre-populated Data', () => {
    it('should pre-populate all fields with existing data', () => {
      modal.open(
        {
          mode: 'edit',
          title: 'Edit Person',
          individual: {
            givenName: 'John',
            surname: 'Doe',
            sex: 'M',
            birthDate: '15 Jan 1980',
            birthPlace: 'New York, USA',
            deathDate: '20 Mar 2050',
            deathPlace: 'Los Angeles, USA',
          },
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      const surnameInput = modal.querySelector('#surname') as HTMLInputElement
      const maleRadio = modal.querySelector('input[name="sex"][value="M"]') as HTMLInputElement
      const birthDateInput = modal.querySelector('#birthDate') as HTMLInputElement
      const birthPlaceInput = modal.querySelector('#birthPlace') as HTMLInputElement
      const deathDateInput = modal.querySelector('#deathDate') as HTMLInputElement
      const deathPlaceInput = modal.querySelector('#deathPlace') as HTMLInputElement

      expect(givenNameInput.value).toBe('John')
      expect(surnameInput.value).toBe('Doe')
      expect(maleRadio.checked).toBe(true)
      expect(birthDateInput.value).toBe('15 Jan 1980')
      expect(birthPlaceInput.value).toBe('New York, USA')
      expect(deathDateInput.value).toBe('20 Mar 2050')
      expect(deathPlaceInput.value).toBe('Los Angeles, USA')
    })

    it('should check Female radio when sex is F', () => {
      modal.open(
        {
          mode: 'edit',
          title: 'Edit Person',
          individual: {
            givenName: 'Jane',
            surname: 'Smith',
            sex: 'F',
            birthDate: null,
            birthPlace: null,
            deathDate: null,
            deathPlace: null,
          },
        },
        onSubmitCallback
      )

      const femaleRadio = modal.querySelector('input[name="sex"][value="F"]') as HTMLInputElement
      expect(femaleRadio.checked).toBe(true)
    })

    it('should escape HTML in pre-populated data', () => {
      modal.open(
        {
          mode: 'edit',
          title: 'Edit Person',
          individual: {
            givenName: '<script>alert("xss")</script>',
            surname: 'Test',
            sex: null,
            birthDate: null,
            birthPlace: null,
            deathDate: null,
            deathPlace: null,
          },
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      expect(givenNameInput.value).not.toContain('<script>')
    })

    it('should handle null values gracefully', () => {
      modal.open(
        {
          mode: 'edit',
          title: 'Edit Person',
          individual: {
            givenName: null,
            surname: null,
            sex: null,
            birthDate: null,
            birthPlace: null,
            deathDate: null,
            deathPlace: null,
          },
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      const surnameInput = modal.querySelector('#surname') as HTMLInputElement

      expect(givenNameInput.value).toBe('')
      expect(surnameInput.value).toBe('')
    })
  })

  describe('Form Validation', () => {
    it('should show validation error when both names are empty', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      const validationMessage = modal.querySelector('.form-validation-message')
      expect(validationMessage?.textContent).toBe('Please provide at least a given name or surname')
      expect(onSubmitCallback).not.toHaveBeenCalled()
    })

    it('should show validation error when names contain only whitespace', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      const surnameInput = modal.querySelector('#surname') as HTMLInputElement

      givenNameInput.value = '   '
      surnameInput.value = '   '

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      const validationMessage = modal.querySelector('.form-validation-message')
      expect(validationMessage?.textContent).toBe('Please provide at least a given name or surname')
      expect(onSubmitCallback).not.toHaveBeenCalled()
    })

    it('should accept form with only given name', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      givenNameInput.value = 'John'

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      expect(onSubmitCallback).toHaveBeenCalled()
    })

    it('should accept form with only surname', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const surnameInput = modal.querySelector('#surname') as HTMLInputElement
      surnameInput.value = 'Doe'

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      expect(onSubmitCallback).toHaveBeenCalled()
    })

    it('should clear validation message after 3 seconds', async () => {
      vi.useFakeTimers()

      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      const validationMessage = modal.querySelector('.form-validation-message') as HTMLElement
      expect(validationMessage.textContent).toBeTruthy()

      vi.advanceTimersByTime(3000)

      expect(validationMessage.textContent).toBe('')

      vi.useRealTimers()
    })
  })

  describe('Form Submission', () => {
    it('should call onSubmit callback with form data', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      const surnameInput = modal.querySelector('#surname') as HTMLInputElement
      const maleRadio = modal.querySelector('input[name="sex"][value="M"]') as HTMLInputElement
      const birthDateInput = modal.querySelector('#birthDate') as HTMLInputElement
      const birthPlaceInput = modal.querySelector('#birthPlace') as HTMLInputElement

      givenNameInput.value = 'John'
      surnameInput.value = 'Doe'
      maleRadio.checked = true
      birthDateInput.value = '15 Jan 1980'
      birthPlaceInput.value = 'New York, USA'

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      expect(onSubmitCallback).toHaveBeenCalledWith({
        givenName: 'John',
        surname: 'Doe',
        sex: 'M',
        birthDate: '15 Jan 1980',
        birthPlace: 'New York, USA',
        deathDate: null,
        deathPlace: null,
      })
    })

    it('should trim whitespace from all fields', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      const surnameInput = modal.querySelector('#surname') as HTMLInputElement

      givenNameInput.value = '  John  '
      surnameInput.value = '  Doe  '

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      expect(onSubmitCallback).toHaveBeenCalledWith(
        expect.objectContaining({
          givenName: 'John',
          surname: 'Doe',
        })
      )
    })

    it('should convert empty strings to null', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      givenNameInput.value = 'John'

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      expect(onSubmitCallback).toHaveBeenCalledWith({
        givenName: 'John',
        surname: null,
        sex: null,
        birthDate: null,
        birthPlace: null,
        deathDate: null,
        deathPlace: null,
      })
    })

    it('should convert "Unknown" sex to null', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      const unknownRadio = modal.querySelector('input[name="sex"][value=""]') as HTMLInputElement

      givenNameInput.value = 'John'
      unknownRadio.checked = true

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      expect(onSubmitCallback).toHaveBeenCalledWith(
        expect.objectContaining({
          sex: null,
        })
      )
    })

    it('should close modal after successful submission', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      givenNameInput.value = 'John'

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      form.dispatchEvent(new Event('submit'))

      expect(modal.style.display).toBe('none')
    })

    it('should prevent default form submission', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      givenNameInput.value = 'John'

      const form = modal.querySelector('.modal-form') as HTMLFormElement
      const submitEvent = new Event('submit', { cancelable: true })

      const preventDefaultSpy = vi.spyOn(submitEvent, 'preventDefault')
      form.dispatchEvent(submitEvent)

      expect(preventDefaultSpy).toHaveBeenCalled()
    })
  })

  describe('User Interactions', () => {
    it('should close when close button is clicked', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const closeBtn = modal.querySelector('.modal-close') as HTMLButtonElement
      closeBtn.click()

      expect(modal.style.display).toBe('none')
    })

    it('should close when cancel button is clicked', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const cancelBtn = modal.querySelector('.btn-cancel') as HTMLButtonElement
      cancelBtn.click()

      expect(modal.style.display).toBe('none')
    })

    it('should close when backdrop is clicked', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const backdrop = modal.querySelector('.modal-backdrop') as HTMLElement
      backdrop.click()

      expect(modal.style.display).toBe('none')
    })

    it('should close when ESC key is pressed', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const escEvent = new KeyboardEvent('keydown', { key: 'Escape' })
      document.dispatchEvent(escEvent)

      expect(modal.style.display).toBe('none')
    })

    it('should not close on other key presses', () => {
      modal.open(
        {
          mode: 'create',
          title: 'Create Person',
        },
        onSubmitCallback
      )

      const enterEvent = new KeyboardEvent('keydown', { key: 'Enter' })
      document.dispatchEvent(enterEvent)

      expect(modal.style.display).toBe('flex')
    })
  })

  describe('HTML Escaping', () => {
    it('should escape HTML in all text fields', () => {
      modal.open(
        {
          mode: 'edit',
          title: 'Edit Person',
          individual: {
            givenName: '<script>alert("xss")</script>',
            surname: '<img src=x onerror=alert(1)>',
            sex: null,
            birthDate: '<b>malicious</b>',
            birthPlace: '<a href="javascript:alert(1)">click</a>',
            deathDate: '"><script>alert(2)</script>',
            deathPlace: '<iframe>test</iframe>',
          },
        },
        onSubmitCallback
      )

      const givenNameInput = modal.querySelector('#givenName') as HTMLInputElement
      const surnameInput = modal.querySelector('#surname') as HTMLInputElement
      const birthDateInput = modal.querySelector('#birthDate') as HTMLInputElement
      const birthPlaceInput = modal.querySelector('#birthPlace') as HTMLInputElement
      const deathDateInput = modal.querySelector('#deathDate') as HTMLInputElement
      const deathPlaceInput = modal.querySelector('#deathPlace') as HTMLInputElement

      // Values should be safe - HTML tags are escaped
      expect(givenNameInput.value).not.toContain('<script>')
      expect(surnameInput.value).not.toContain('<img')
      expect(birthDateInput.value).not.toContain('<b>')
      expect(birthPlaceInput.value).not.toContain('<a')
      expect(deathDateInput.value).not.toContain('<script>')
      expect(deathPlaceInput.value).not.toContain('<iframe>')
    })
  })
})
