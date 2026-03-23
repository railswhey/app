import { Controller } from "@hotwired/stimulus"

// Usage:
//   <div data-controller="modal">
//     <button data-action="modal#open" data-modal-target-param="my-modal">Open</button>
//     <dialog data-modal-target="dialog" id="my-modal">
//       <button data-action="modal#close">✕</button>
//       ...content...
//     </dialog>
//   </div>
//
// Or open any modal by id:
//   <button data-action="click->modal#openById" data-modal-id-param="move-modal-123">Move</button>

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event.preventDefault()
    const id = event.params.target
    const dialog = id ? document.getElementById(id) : this.dialogTarget
    if (dialog) this.#show(dialog)
  }

  openById(event) {
    event.preventDefault()
    const id = event.params.id
    const dialog = document.getElementById(id)
    if (dialog) this.#show(dialog)
  }

  close(event) {
    if (event) event.preventDefault()
    const dialog = event?.target?.closest("dialog")
    if (dialog) this.#hide(dialog)
  }

  backdropClose(event) {
    // Only close if clicking the dialog backdrop (not content)
    if (event.target === event.currentTarget) {
      this.#hide(event.target)
    }
  }

  // Private

  #show(dialog) {
    dialog.showModal()
    document.body.style.overflow = "hidden"
  }

  #hide(dialog) {
    dialog.close()
    document.body.style.overflow = ""
  }
}
