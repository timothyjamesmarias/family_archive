import { Application } from '@hotwired/stimulus'
import DarkModeController from '../controllers/dark_mode_controller'
import AutosubmitController from '../controllers/autosubmit_controller'
import PhotoAnnotationsController from '../controllers/photo_annotations_controller'
import '../shared/mobileMenu'

// The public bundle carries no Turbo and only the controllers it needs.
const application = Application.start()
application.register('dark-mode', DarkModeController)
application.register('autosubmit', AutosubmitController)
application.register('photo-annotations', PhotoAnnotationsController)
