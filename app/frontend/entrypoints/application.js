import "./application.css"

import "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"
import "@37signals/lexxy"
import "@37signals/lexxy/stylesheets/lexxy.css"
import { application } from "../controllers"

ActiveStorage.start()

export { application }