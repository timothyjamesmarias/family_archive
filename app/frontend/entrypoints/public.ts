import { Application } from '@hotwired/stimulus'
import DarkModeController from '../controllers/dark_mode_controller'
import '../shared/mobileMenu'
import { initializePhotoGalleries, initializeAnnotatedPhotos } from '../shared/photos'

// The public bundle carries no Turbo and only the controllers it needs.
const application = Application.start()
application.register('dark-mode', DarkModeController)

document.addEventListener('DOMContentLoaded', () => {
  initializePhotoGalleries()
  initializeAnnotatedPhotos()
})
