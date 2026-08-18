import { type Modal } from '../../../shared/components/modal'
import { escapeHtml } from '../../../shared/escape_html'
import { type Individual } from '../types/individual'

/**
 * PersonSearchPicker - A modal for searching and selecting existing people.
 * Used for operations like "link existing parent" where you need to pick
 * a person who already exists in the database.
 */
export class PersonSearchPicker extends HTMLElement {
  private modal: Modal | null = null
  private onSelectCallback: ((personId: number) => void | Promise<void>) | null = null
  private excludeIds: number[] = []
  private allIndividuals: Individual[] = []
  private searchQuery: string = ''
  private selectedPersonId: number | null = null
  private isClosing: boolean = false

  constructor() {
    super()
  }

  /**
   * Open the picker with a list of individuals to choose from.
   *
   * @param config - Configuration for the picker
   */
  open(config: PersonSearchPickerConfig) {
    if (this.isClosing) return

    this.onSelectCallback = config.onSelect
    this.excludeIds = config.excludeIds || []
    this.allIndividuals = config.allIndividuals || []
    this.searchQuery = ''
    this.selectedPersonId = null

    // Create a fresh modal
    this.modal = document.createElement('generic-modal') as Modal
    this.appendChild(this.modal)

    this.renderModal(config.title)
  }

  /**
   * Close the picker.
   */
  close() {
    if (this.isClosing) return
    this.isClosing = true

    this.onSelectCallback = null

    if (this.modal) {
      this.modal.close()
      this.modal.remove()
      this.modal = null
    }

    this.innerHTML = ''
    this.isClosing = false
  }

  private renderModal(title: string) {
    if (!this.modal) return

    const content = this.buildContent()

    this.modal.open({
      title,
      content,
      maxWidth: '600px',
      autoFocus: true,
      onClose: () => this.close(),
    })

    // Attach event listeners after modal is rendered
    setTimeout(() => this.attachEventListeners(), 50)
  }

  private buildContent(): string {
    const filteredPeople = this.filterPeople()

    return `
      <div class="person-search-picker">
        <div class="search-box">
          <input
            type="text"
            id="person-search-input"
            class="search-input"
            placeholder="Search by name..."
            value="${escapeHtml(this.searchQuery)}"
            autocomplete="off"
          />
        </div>

        <div class="results-container">
          ${filteredPeople.length === 0 ? this.renderNoResults() : this.renderResults(filteredPeople)}
        </div>

        <div class="picker-actions">
          <button type="button" class="btn-cancel">Cancel</button>
          <button
            type="button"
            class="btn-select"
            ${this.selectedPersonId === null ? 'disabled' : ''}
          >
            Select Person
          </button>
        </div>
      </div>
    `
  }

  private filterPeople(): Individual[] {
    let filtered = this.allIndividuals.filter((person) => !this.excludeIds.includes(person.id))

    if (this.searchQuery.trim() !== '') {
      const query = this.searchQuery.toLowerCase()
      filtered = filtered.filter((person) => {
        const fullName = `${person.givenName || ''} ${person.surname || ''}`.toLowerCase()
        const id = person.id.toString()
        return fullName.includes(query) || id.includes(query)
      })
    }

    // Sort by name
    filtered.sort((a, b) => {
      const nameA = `${a.surname || ''} ${a.givenName || ''}`.trim().toLowerCase()
      const nameB = `${b.surname || ''} ${b.givenName || ''}`.trim().toLowerCase()
      return nameA.localeCompare(nameB)
    })

    return filtered
  }

  private renderNoResults(): string {
    return `
      <div class="no-results">
        <p>No people found matching "${escapeHtml(this.searchQuery)}"</p>
      </div>
    `
  }

  private renderResults(people: Individual[]): string {
    return `
      <div class="results-list">
        ${people.map((person) => this.renderPersonItem(person)).join('')}
      </div>
    `
  }

  private renderPersonItem(person: Individual): string {
    const fullName = `${person.givenName || ''} ${person.surname || ''}`.trim() || 'Unknown'
    const sexLabel = person.sex === 'M' ? 'Male' : person.sex === 'F' ? 'Female' : 'Unknown'
    const isSelected = this.selectedPersonId === Number(person.id)

    return `
      <div
        class="person-item ${isSelected ? 'selected' : ''}"
        data-person-id="${person.id}"
        role="button"
        tabindex="0"
      >
        <div class="person-info">
          <div class="person-name">${escapeHtml(fullName)}</div>
          <div class="person-details">ID: ${person.id} • ${sexLabel}</div>
        </div>
        ${isSelected ? '<div class="selected-indicator">✓</div>' : ''}
      </div>
    `
  }

  private attachEventListeners() {
    if (!this.modal) return

    // Search input with debounce
    const searchInput = this.modal.querySelector('#person-search-input') as HTMLInputElement
    if (searchInput) {
      let debounceTimer: number
      searchInput.addEventListener('input', (e) => {
        clearTimeout(debounceTimer)
        debounceTimer = window.setTimeout(() => {
          this.searchQuery = (e.target as HTMLInputElement).value
          this.refreshContent()
        }, 300)
      })
    }

    // Person item clicks
    const personItems = this.modal.querySelectorAll('.person-item')
    personItems.forEach((item) => {
      const personId = parseInt(item.getAttribute('data-person-id') || '0', 10)

      const selectPerson = () => {
        this.selectedPersonId = personId
        this.refreshContent()
      }

      item.addEventListener('click', selectPerson)
      item.addEventListener('keydown', (e) => {
        if ((e as KeyboardEvent).key === 'Enter' || (e as KeyboardEvent).key === ' ') {
          e.preventDefault()
          selectPerson()
        }
      })
    })

    // Cancel button
    const cancelBtn = this.modal.querySelector('.btn-cancel') as HTMLButtonElement
    if (cancelBtn) {
      cancelBtn.addEventListener('click', () => this.close())
    }

    // Select button
    const selectBtn = this.modal.querySelector('.btn-select') as HTMLButtonElement
    if (selectBtn) {
      selectBtn.addEventListener('click', () => {
        if (this.selectedPersonId !== null && this.onSelectCallback) {
          const callback = this.onSelectCallback
          this.onSelectCallback = null
          this.close()
          callback(this.selectedPersonId)
        }
      })
    }
  }

  /**
   * Refresh the modal content (used when search query or selection changes)
   */
  private refreshContent() {
    if (!this.modal) return

    const modalContent = this.modal.querySelector('.modal-content')
    if (modalContent) {
      modalContent.innerHTML = this.buildContent()
      this.attachEventListeners()
    }
  }

  connectedCallback() {
    this.injectStyles()
  }

  private injectStyles() {
    const styleId = 'person-search-picker-styles'
    if (document.getElementById(styleId)) return

    const style = document.createElement('style')
    style.id = styleId
    style.textContent = `
      .person-search-picker {
        display: flex;
        flex-direction: column;
        gap: 16px;
      }

      .search-box {
        position: sticky;
        top: 0;
        background: white;
        z-index: 10;
      }

      .search-input {
        width: 100%;
        padding: 10px 12px;
        font-size: 14px;
        border: 1px solid #d1d5db;
        border-radius: 6px;
        outline: none;
        transition: border-color 0.2s;
      }

      .search-input:focus {
        border-color: #3b82f6;
        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
      }

      .results-container {
        max-height: 400px;
        overflow-y: auto;
        border: 1px solid #e5e7eb;
        border-radius: 6px;
        background: #f9fafb;
      }

      .results-list {
        display: flex;
        flex-direction: column;
      }

      .person-item {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 12px 16px;
        background: white;
        border-bottom: 1px solid #e5e7eb;
        cursor: pointer;
        transition: all 0.2s;
        outline: none;
      }

      .person-item:last-child {
        border-bottom: none;
      }

      .person-item:hover {
        background: #f3f4f6;
      }

      .person-item:focus {
        background: #f3f4f6;
        box-shadow: inset 0 0 0 2px #3b82f6;
      }

      .person-item.selected {
        background: #eff6ff;
        border-left: 3px solid #3b82f6;
      }

      .person-info {
        flex: 1;
      }

      .person-name {
        font-size: 15px;
        font-weight: 500;
        color: #111827;
        margin-bottom: 4px;
      }

      .person-details {
        font-size: 13px;
        color: #6b7280;
      }

      .selected-indicator {
        font-size: 18px;
        color: #3b82f6;
        font-weight: bold;
      }

      .no-results {
        padding: 40px 20px;
        text-align: center;
        color: #6b7280;
      }

      .picker-actions {
        display: flex;
        gap: 12px;
        justify-content: flex-end;
        padding-top: 8px;
        border-top: 1px solid #e5e7eb;
      }

      .btn-cancel,
      .btn-select {
        padding: 8px 16px;
        font-size: 14px;
        font-weight: 500;
        border-radius: 6px;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
      }

      .btn-cancel {
        background: #f3f4f6;
        color: #374151;
      }

      .btn-cancel:hover {
        background: #e5e7eb;
      }

      .btn-select {
        background: #3b82f6;
        color: white;
      }

      .btn-select:hover:not(:disabled) {
        background: #2563eb;
      }

      .btn-select:disabled {
        background: #d1d5db;
        cursor: not-allowed;
      }
    `
    document.head.appendChild(style)
  }
}

export interface PersonSearchPickerConfig {
  /** Title of the picker modal */
  title: string

  /** IDs to exclude from search results (e.g., the child shouldn't be their own parent) */
  excludeIds?: number[]

  /** All individuals available for selection */
  allIndividuals: Individual[]

  /** Callback when a person is selected */
  onSelect: (personId: number) => void | Promise<void>
}

// Register the custom element
customElements.define('person-search-picker', PersonSearchPicker)
