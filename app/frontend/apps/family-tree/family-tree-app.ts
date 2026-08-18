import { type TreeCanvas } from './components/tree-canvas'
import { ZoomController } from './components/zoom-controller'
import { Renderer } from './components/renderer'
import { FamilyTreeService } from './family-tree-service'
import { familyTreeStore, type TreeState } from './family-tree-store'
import { calculateLayout } from './components/layout'
import { type PersonNode, type ExpandTreeNode, type RenderableNode } from './types/node'
import { store } from '../../shared/store'
import { type PersonFormModal } from './components/person-form-modal'
import { type ActionMenuPopup, type PersonAction } from './components/action-menu-popup'
import { type FamilyPickerModal } from './components/family-picker-modal'
import { type AddParentForm } from './components/add-parent-form'
import { type PersonSearchPicker } from './components/person-search-picker'
import { showToast } from '../../shared/components/toast'
import { type Modal } from '../../shared/components/modal'
import { type IndividualRequest } from './types/mutations'
import { type FamilyUnit, type FamilyTreeResponse } from './types/family-tree'
import { type RelationshipMetadata } from './types/mutations'
import { type Individual } from './types/individual'
import {
  TREE_LAYOUT,
  EXPAND_NODE_OFFSET,
  DEFAULT_GENERATIONS,
  ExpansionDirection,
  type ParentRole,
  PARENT_ROLE_LABELS,
} from './constants'

const LAYOUT_CONFIG = {
  rankdir: TREE_LAYOUT.RANK_DIRECTION,
  nodesep: TREE_LAYOUT.NODE_SEPARATION,
  ranksep: TREE_LAYOUT.RANK_SEPARATION,
  marginx: TREE_LAYOUT.MARGIN_X,
  marginy: TREE_LAYOUT.MARGIN_Y,
} as const

export class FamilyTreeApp {
  private rootElement: HTMLElement
  private service: FamilyTreeService
  private renderer: Renderer | null = null

  private personFormModal: PersonFormModal | null = null
  private actionMenuPopup: ActionMenuPopup | null = null
  private familyPickerModal: FamilyPickerModal | null = null
  private addParentForm: AddParentForm | null = null
  private personSearchPicker: PersonSearchPicker | null = null

  constructor(rootElement: HTMLElement) {
    this.rootElement = rootElement
    this.service = new FamilyTreeService()

    this.initialize()
  }

  private async initialize(): Promise<void> {
    store.initialize(this.rootElement)
    this.renderCanvas()
    familyTreeStore.subscribe((state) => this.handleStateChange(state))
  }

  private renderCanvas(): void {
    this.rootElement.innerHTML = `
      <tree-canvas></tree-canvas>
      <edit-mode-toggle></edit-mode-toggle>
      <person-form-modal></person-form-modal>
      <action-menu-popup></action-menu-popup>
      <family-picker-modal></family-picker-modal>
      <add-parent-form></add-parent-form>
      <person-search-picker></person-search-picker>
    `

    const canvas = this.rootElement.querySelector('tree-canvas') as TreeCanvas
    if (!canvas) {
      console.error('Failed to create tree canvas')
      return
    }

    this.personFormModal = this.rootElement.querySelector('person-form-modal') as PersonFormModal
    this.actionMenuPopup = this.rootElement.querySelector('action-menu-popup') as ActionMenuPopup
    this.familyPickerModal = this.rootElement.querySelector(
      'family-picker-modal'
    ) as FamilyPickerModal
    this.addParentForm = this.rootElement.querySelector('add-parent-form') as AddParentForm
    this.personSearchPicker = this.rootElement.querySelector(
      'person-search-picker'
    ) as PersonSearchPicker

    requestAnimationFrame(() => void this.initializeRendering(canvas))
  }

  private async initializeRendering(canvas: TreeCanvas): Promise<void> {
    const transformGroup = canvas.getTransformGroup()
    const svgSelection = canvas.getSvgSelection()

    if (!transformGroup || !svgSelection) {
      console.error('Failed to get canvas elements')
      return
    }

    new ZoomController(svgSelection, transformGroup)
    this.renderer = new Renderer(transformGroup)

    transformGroup.addEventListener('expand-tree', ((event: CustomEvent) => {
      void this.handleExpandTree(event)
    }) as EventListener)

    transformGroup.addEventListener('action-menu-open', this.handleActionMenuOpen as EventListener)

    try {
      const treeResponse = await this.service.loadInitialTree()

      if (treeResponse.individuals.length === 0) {
        console.warn('No individuals found in tree')
        this.displayPlaceholder()
        return
      }

      familyTreeStore.setTreeData(treeResponse)
    } catch (error) {
      console.error('Failed to load family tree:', error)
      this.displayError(error instanceof Error ? error : new Error('Unknown error'))
    }
  }

  private handleStateChange(state: TreeState): void {
    this.renderTree(state)
  }

  private renderTree(state: TreeState): void {
    if (!this.renderer) return

    const personNodes = calculateLayout(state.individuals, state.families, LAYOUT_CONFIG)
    const expandNodes = this.createExpandNodes(personNodes, state.families)
    const allNodes: RenderableNode[] = [...personNodes, ...expandNodes]

    this.renderer.render(allNodes, state.families)
  }

  private createExpandNodes(personNodes: PersonNode[], families: FamilyUnit[]): ExpandTreeNode[] {
    const expandNodes: ExpandTreeNode[] = []

    // Track individuals who have visible parents/children in the tree
    const individualsWithVisibleParents = new Set<number>()
    const individualsWithVisibleChildren = new Set<number>()

    families.forEach((family) => {
      // Only count as having visible parents if the family has at least one parent shown
      if (family.parentIds.length > 0) {
        family.childIds.forEach((childId) => individualsWithVisibleParents.add(childId))
      }

      // Only count as having visible children if the family has at least one child shown
      if (family.childIds.length > 0) {
        family.parentIds.forEach((parentId) => individualsWithVisibleChildren.add(parentId))
      }
    })

    personNodes.forEach((node) => {
      const { individual, x, y } = node
      const { relationships } = individual
      if (!relationships) return

      // Show ancestor expand if: has unloaded ancestors AND no visible parents in tree
      if (relationships.hasUnloadedAncestors && !individualsWithVisibleParents.has(individual.id)) {
        expandNodes.push({
          id: `expand-ancestors-${individual.id}`,
          direction: ExpansionDirection.UP,
          individualId: individual.id,
          generations: DEFAULT_GENERATIONS,
          x,
          y: y - EXPAND_NODE_OFFSET,
        })
      }

      // Show descendant expand if: has unloaded descendants AND no visible children in tree
      if (
        relationships.hasUnloadedDescendants &&
        !individualsWithVisibleChildren.has(individual.id)
      ) {
        expandNodes.push({
          id: `expand-descendants-${individual.id}`,
          direction: ExpansionDirection.DOWN,
          individualId: individual.id,
          generations: DEFAULT_GENERATIONS,
          x,
          y: y + EXPAND_NODE_OFFSET,
        })
      }
    })

    return expandNodes
  }

  private async handleExpandTree(event: CustomEvent): Promise<void> {
    const { individualId, direction } = event.detail

    try {
      const expansionParams =
        direction === ExpansionDirection.UP
          ? { personId: individualId, generationsUp: DEFAULT_GENERATIONS, includeSiblings: true }
          : { personId: individualId, generationsDown: DEFAULT_GENERATIONS }

      const newData = await this.service.expandTree(expansionParams)

      // When expanding ancestors with siblings, filter out descendants of siblings
      const filteredData =
        direction === ExpansionDirection.UP
          ? this.filterAncestorExpansion(newData, individualId)
          : newData

      familyTreeStore.mergeTreeData(filteredData)
    } catch (error) {
      console.error('Error expanding tree:', error)
      this.showErrorMessage(error instanceof Error ? error.message : 'Failed to expand tree')
    }
  }

  private filterAncestorExpansion(
    data: FamilyTreeResponse,
    rootPersonId: number
  ): FamilyTreeResponse {
    // When expanding ancestors with siblings, we want:
    // 1. The root person and their ancestors (parents)
    // 2. Siblings of the root person
    // 3. Spouses of those siblings (if the sibling+spouse family has children)
    // But NOT: Descendants of the siblings OR childless spouse families

    const state = familyTreeStore.getState()
    const rootPerson = [...state.individuals, ...data.individuals].find(
      (i) => i.id === rootPersonId
    )

    const childFamilyIds = rootPerson?.relationships?.childFamilyIds
    if (!childFamilyIds || childFamilyIds.length === 0) {
      // No parent family, just return all data
      return data
    }

    const allowedIndividualIds = new Set<number>()
    const allowedFamilyIds = new Set<number>()

    // Get the root person's parent family
    const parentFamilyId = childFamilyIds[0]
    const parentFamily = data.families.find((f) => f.familyId === parentFamilyId)

    if (!parentFamily) {
      return data
    }

    allowedFamilyIds.add(parentFamilyId)

    // Add all parents (ancestors)
    parentFamily.parentIds.forEach((parentId) => {
      allowedIndividualIds.add(parentId)

      // Also include the parent's spouse families (so we get both parents even if in different families)
      const parent = data.individuals.find((i) => i.id === parentId)
      if (parent?.relationships?.spouseFamilyIds) {
        parent.relationships.spouseFamilyIds.forEach((fid) => allowedFamilyIds.add(fid))
      }
    })

    // Add all children of the parent family (root person + siblings)
    parentFamily.childIds.forEach((childId) => {
      allowedIndividualIds.add(childId)

      // For each sibling, only include spouse families that have children (not childless marriages)
      const sibling = data.individuals.find((i) => i.id === childId)
      if (sibling?.relationships?.spouseFamilyIds) {
        sibling.relationships.spouseFamilyIds.forEach((spouseFamilyId) => {
          const spouseFamily = data.families.find((f) => f.familyId === spouseFamilyId)

          // Only include this family if it has children
          // (We don't want to show childless marriages when expanding ancestors)
          if (spouseFamily && spouseFamily.childIds.length > 0) {
            allowedFamilyIds.add(spouseFamilyId)

            // Add the spouses from this family
            spouseFamily.parentIds.forEach((spouseId) => {
              if (spouseId !== childId) {
                // Don't re-add the sibling
                allowedIndividualIds.add(spouseId)
              }
            })
          }
        })
      }
    })

    // Filter individuals and families to only allowed ones
    const filteredIndividuals = data.individuals.filter((i) => allowedIndividualIds.has(i.id))
    const filteredFamilies = data.families.filter((f) => allowedFamilyIds.has(f.familyId))

    return {
      individuals: filteredIndividuals,
      families: filteredFamilies,
    }
  }

  private handleActionMenuOpen = (event: CustomEvent): void => {
    const { individualId, x, y } = event.detail
    const state = familyTreeStore.getState()
    const individual = state.individuals.find((i) => i.id === individualId)

    if (!individual || !this.actionMenuPopup) return

    this.actionMenuPopup.open(
      {
        individualId,
        position: { x, y },
        metadata: individual.relationships,
      },
      (action) => void this.handleAction(action, individualId, individual.relationships)
    )
  }

  private async handleAction(
    action: PersonAction,
    individualId: number,
    metadata?: RelationshipMetadata
  ): Promise<void> {
    const actionHandlers: Record<PersonAction, () => void | Promise<void>> = {
      'edit': () => this.handleEditPerson(individualId),
      'delete': () => this.handleDeletePerson(individualId),
      'add-child': () => this.handleAddChild(individualId, metadata!),
      'add-spouse': () => this.handleAddSpouse(individualId),
      'add-parent': () => this.handleAddParent(individualId),
      'add-sibling': () => this.handleAddSibling(individualId),
      'link-existing-parent': () => this.handleLinkExistingParent(individualId, metadata!),
    }

    const handler = actionHandlers[action]
    if (handler) {
      await handler()
    }
  }

  private handleEditPerson(individualId: number): void {
    const state = familyTreeStore.getState()
    const individual = state.individuals.find((i) => i.id === individualId)

    if (!individual || !this.personFormModal) return

    this.personFormModal.open(
      {
        mode: 'edit',
        title: 'Edit Person',
        individual,
      },
      async (data) => {
        try {
          const updated = await this.service.updateIndividual(individualId, data)
          familyTreeStore.updateIndividual(updated)
          this.showSuccessMessage(`Updated ${updated.givenName} ${updated.surname}`)
        } catch (error) {
          this.showErrorMessage(error instanceof Error ? error.message : 'Failed to update person')
        }
      }
    )
  }

  private async handleDeletePerson(individualId: number): Promise<void> {
    const state = familyTreeStore.getState()
    const individual = state.individuals.find((i) => i.id === individualId)

    if (!individual) {
      return
    }

    // Client-side validation: check if person has descendants
    const hasDescendants = this.checkHasDescendants(individual, state.families)

    if (hasDescendants) {
      this.showErrorMessage('Cannot delete person - they have descendants')
      return
    }

    const confirmed = await this.showConfirmDialog({
      title: 'Delete Person',
      message: `Are you sure you want to delete ${individual.givenName} ${individual.surname}?`,
      confirmText: 'Delete',
      cancelText: 'Cancel',
    })

    if (!confirmed) return

    try {
      await this.service.deleteIndividual(individualId)
      familyTreeStore.removeIndividual(individualId)
      this.showSuccessMessage(`Deleted ${individual.givenName} ${individual.surname}`)
    } catch (error) {
      console.error('Delete failed:', error)
      this.showErrorMessage(error instanceof Error ? error.message : 'Failed to delete person')
    }
  }

  private checkHasDescendants(individual: Individual, families: FamilyUnit[]): boolean {
    if (!individual.relationships?.spouseFamilyIds) return false

    // Check if any of the person's spouse families have children
    return individual.relationships.spouseFamilyIds.some((familyId) => {
      const family = families.find((f) => f.familyId === familyId)
      return family && family.childIds.length > 0
    })
  }

  private async handleAddChild(parentId: number, metadata: RelationshipMetadata): Promise<void> {
    if (!this.personFormModal || !this.familyPickerModal) return

    let selectedFamilyId: number | null = null

    if (metadata.spouseFamilyIds && metadata.spouseFamilyIds.length > 1) {
      const state = familyTreeStore.getState()
      const families = metadata.spouseFamilyIds
        .map((familyId) => state.families.find((f) => f.familyId === familyId))
        .filter((f): f is FamilyUnit => f !== undefined)

      selectedFamilyId = await this.showFamilyPicker(families, state.individuals)
      if (selectedFamilyId === null) return
    } else if (metadata.spouseFamilyIds && metadata.spouseFamilyIds.length === 1) {
      selectedFamilyId = metadata.spouseFamilyIds[0]
    }

    this.personFormModal.open(
      {
        mode: 'create',
        title: 'Add Child',
      },
      async (childData) => {
        try {
          const newData = await this.service.addChild({
            parentId,
            parentFamilyId: selectedFamilyId,
            childData,
          })
          familyTreeStore.mergeTreeData(newData)
          this.showSuccessMessage('Child added successfully')
        } catch (error) {
          this.showErrorMessage(error instanceof Error ? error.message : 'Failed to add child')
        }
      }
    )
  }

  private handleAddSpouse(personId: number): void {
    if (!this.personFormModal) return

    this.personFormModal.open(
      {
        mode: 'create',
        title: 'Add Spouse',
      },
      async (spouseData) => {
        try {
          const newData = await this.service.addSpouse({ personId, spouseData })
          familyTreeStore.mergeTreeData(newData)
          this.showSuccessMessage('Spouse added successfully')
        } catch (error) {
          this.showErrorMessage(error instanceof Error ? error.message : 'Failed to add spouse')
        }
      }
    )
  }

  private handleAddParent(childId: number): void {
    const state = familyTreeStore.getState()
    const child = state.individuals.find((i) => i.id === childId)

    if (!child || !this.addParentForm) return

    this.addParentForm.open(
      `${child.givenName} ${child.surname}`,
      async (parentData: IndividualRequest, role: ParentRole) => {
        try {
          const newData = await this.service.addParent({ childId, parentData, role })
          familyTreeStore.mergeTreeData(newData)
          this.showSuccessMessage(`${PARENT_ROLE_LABELS[role]} added successfully`)
        } catch (error) {
          this.showErrorMessage(error instanceof Error ? error.message : 'Failed to add parent')
        }
      }
    )
  }

  private async handleLinkExistingParent(
    childId: number,
    metadata: RelationshipMetadata
  ): Promise<void> {
    const state = familyTreeStore.getState()
    const child = state.individuals.find((i) => i.id === childId)

    if (!child || !this.personSearchPicker) return

    const availableRoles = this.service.determineAvailableParentRoles(
      metadata,
      state.individuals,
      state.families
    )

    if (availableRoles.length === 0) {
      this.showErrorMessage('Both parent roles are already filled')
      return
    }

    const role =
      availableRoles.length === 1 ? availableRoles[0] : await this.showRolePicker(availableRoles)

    if (!role) return

    this.personSearchPicker.open({
      title: `Select ${PARENT_ROLE_LABELS[role]} for ${child.givenName}`,
      allIndividuals: state.individuals,
      excludeIds: [childId],
      onSelect: async (existingParentId) => {
        try {
          const newData = await this.service.linkExistingParent({
            childId,
            existingParentId,
            role,
          })
          familyTreeStore.mergeTreeData(newData)
          this.showSuccessMessage(`${PARENT_ROLE_LABELS[role]} linked successfully`)
        } catch (error) {
          this.showErrorMessage(error instanceof Error ? error.message : 'Failed to link parent')
        }
      },
    })
  }

  private handleAddSibling(personId: number): void {
    if (!this.personFormModal) return

    this.personFormModal.open(
      {
        mode: 'create',
        title: 'Add Sibling',
      },
      async (siblingData) => {
        try {
          const newData = await this.service.addSibling({ personId, siblingData })
          familyTreeStore.mergeTreeData(newData)
          this.showSuccessMessage('Sibling added successfully')
        } catch (error) {
          this.showErrorMessage(error instanceof Error ? error.message : 'Failed to add sibling')
        }
      }
    )
  }

  private async showFamilyPicker(
    families: FamilyUnit[],
    individuals: Individual[]
  ): Promise<number | null> {
    const picker = this.familyPickerModal
    if (!picker) return null

    const options = families.map((family) => {
      const parents = family.parentIds
        .map((id) => individuals.find((individual) => individual.id === id))
        .filter((individual) => individual !== undefined)

      return {
        familyId: family.familyId,
        spouseName: parents
          .map((parent) => `${parent.givenName ?? ''} ${parent.surname ?? ''}`.trim())
          .join(' & '),
      }
    })

    return new Promise((resolve) => {
      picker.open(options, (familyId) => resolve(familyId))
    })
  }

  private async showRolePicker(roles: ParentRole[]): Promise<ParentRole | null> {
    return new Promise((resolve) => {
      const modal = document.createElement('generic-modal') as Modal
      document.body.appendChild(modal)

      const content = `
        <div style="display: flex; flex-direction: column; gap: 16px;">
          <p>Select the role for this parent:</p>
          <div style="display: flex; gap: 12px;">
            ${roles
              .map(
                (role) => `
              <button class="btn-primary" data-role="${role}">
                ${PARENT_ROLE_LABELS[role]}
              </button>
            `
              )
              .join('')}
          </div>
        </div>
      `

      modal.open({
        title: 'Select Parent Role',
        content,
        showCloseButton: true,
        onClose: () => {
          modal.remove()
          resolve(null)
        },
      })

      // Wait for DOM to update before attaching event listeners
      requestAnimationFrame(() => {
        modal.querySelectorAll('[data-role]').forEach((button) => {
          button.addEventListener('click', () => {
            const role = button.getAttribute('data-role') as ParentRole
            modal.close()
            modal.remove()
            resolve(role)
          })
        })
      })
    })
  }

  private showSuccessMessage(message: string): void {
    showToast({ message, type: 'success' })
  }

  private showErrorMessage(message: string): void {
    showToast({ message, type: 'error' })
  }

  private async showConfirmDialog(config: {
    title: string
    message: string
    confirmText: string
    cancelText: string
  }): Promise<boolean> {
    return new Promise((resolve) => {
      const modal = document.createElement('generic-modal') as Modal
      document.body.appendChild(modal)
      let resolved = false // Track if we've already resolved

      const content = `
        <div style="display: flex; flex-direction: column; gap: 24px;">
          <p style="font-size: 16px; color: #374151;">${config.message}</p>
          <div style="display: flex; gap: 12px; justify-content: flex-end;">
            <button class="btn-secondary" data-action="cancel">${config.cancelText}</button>
            <button class="btn-danger" data-action="confirm">${config.confirmText}</button>
          </div>
        </div>
      `

      modal.open({
        title: config.title,
        content,
        showCloseButton: false,
        onClose: () => {
          // Only resolve if not already resolved by button click
          if (!resolved) {
            resolved = true
            modal.remove()
            resolve(false)
          }
        },
      })

      // Wait for DOM to update before attaching event listeners
      requestAnimationFrame(() => {
        const confirmBtn = modal.querySelector('[data-action="confirm"]')
        const cancelBtn = modal.querySelector('[data-action="cancel"]')

        confirmBtn?.addEventListener('click', () => {
          if (!resolved) {
            resolved = true
            modal.close()
            modal.remove()
            resolve(true)
          }
        })

        cancelBtn?.addEventListener('click', () => {
          if (!resolved) {
            resolved = true
            modal.close()
            modal.remove()
            resolve(false)
          }
        })
      })
    })
  }

  private displayPlaceholder(): void {
    if (!this.rootElement) return

    const canvas = this.rootElement.querySelector('tree-canvas')
    if (canvas) {
      canvas.innerHTML = '<div class="text-center p-8">No family tree data available</div>'
    }
  }

  private displayError(error: Error): void {
    if (!this.rootElement) return

    const canvas = this.rootElement.querySelector('tree-canvas')
    if (canvas) {
      canvas.innerHTML = `<div class="text-center p-8 text-red-600">Error loading tree: ${error.message}</div>`
    }
  }
}
