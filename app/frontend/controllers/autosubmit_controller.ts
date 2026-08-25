import { Controller } from '@hotwired/stimulus'

// Submits the surrounding form when a control changes, so the sort select
// works without an Apply button. The form remains a plain GET form —
// everything still works with JavaScript disabled via Enter on the input.
export default class AutosubmitController extends Controller<HTMLFormElement> {
  submit() {
    this.element.requestSubmit()
  }
}
