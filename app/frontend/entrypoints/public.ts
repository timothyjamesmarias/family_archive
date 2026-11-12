import '@hotwired/turbo-rails'
import { Application } from '@hotwired/stimulus'
import DarkModeController from '../controllers/dark_mode_controller'
import AutosubmitController from '../controllers/autosubmit_controller'
import PhotoAnnotationsController from '../controllers/photo_annotations_controller'
import MediaPlayerController from '../controllers/media_player_controller'
import MobileMenuController from '../controllers/mobile_menu_controller'
import TreeZoomController from '../controllers/tree_zoom_controller'

// Turbo Drive like the admin, but only the controllers public pages need.
const application = Application.start()
application.register('dark-mode', DarkModeController)
application.register('autosubmit', AutosubmitController)
application.register('photo-annotations', PhotoAnnotationsController)
application.register('media-player', MediaPlayerController)
application.register('mobile-menu', MobileMenuController)
application.register('tree-zoom', TreeZoomController)
