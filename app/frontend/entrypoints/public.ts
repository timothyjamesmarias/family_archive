import '../shared/darkMode'
import '../shared/mobileMenu'
import { initializePhotoGalleries, initializeAnnotatedPhotos } from '../shared/photos'

document.addEventListener('DOMContentLoaded', () => {
  initializePhotoGalleries()
  initializeAnnotatedPhotos()
})
