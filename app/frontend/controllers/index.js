import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = import.meta.env.DEV

// Exposed for debugging in the console and so system tests can wait for
// Stimulus to be ready before clicking anything it controls.
window.Stimulus = application

// Auto-register every *_controller.(js|ts) in this directory.
// `copy_button_controller.js` registers as `copy-button`.
const controllers = import.meta.glob("./*_controller.{js,ts}", { eager: true })

for (const [ path, module ] of Object.entries(controllers)) {
  const identifier = path
    .replace(/^\.\//, "")
    .replace(/_controller\.(js|ts)$/, "")
    .replace(/_/g, "-")

  application.register(identifier, module.default)
}

export { application }