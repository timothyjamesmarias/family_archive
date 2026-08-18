import './components/tree-canvas'
import './components/edit-mode-toggle'
import './components/person-form-modal'
import './components/action-menu-popup'
import './components/family-picker-modal'
import './components/add-parent-form'
import './components/person-search-picker'
import '../../shared/components/toast'
import '../../shared/components/modal'

import { FamilyTreeApp } from './family-tree-app'

function initializeFamilyTree() {
  const rootElement = document.getElementById('family-tree-root')

  if (rootElement) {
    new FamilyTreeApp(rootElement)
  } else {
    console.error('Family tree root element not found')
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeFamilyTree)
} else {
  initializeFamilyTree()
}
