import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["history", "input", "sendButton", "sendLabel", "counter", "status", "promptButton"]

  connect() {
    this.isSubmitting = false
    this.pendingMessage = ""
    this.autoResize()
    this.updateCounter()
    this.toggleSend()
    this.scrollToBottom()
  }

  handleKeydown(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return

    event.preventDefault()
    this.element.querySelector("form")?.requestSubmit()
  }

  submitStart(event) {
    const message = this.inputTarget.value.trim()

    if (message.length === 0) {
      event.preventDefault()
      this.setStatus("Type a message to get started.")
      this.toggleSend()
      return
    }

    this.isSubmitting = true
    this.pendingMessage = message

    this.renderPendingExchange(message)
    this.inputTarget.value = ""
    this.autoResize()
    this.updateCounter()

    this.setStatus("Fathership is thinking...")
    this.sendLabelTarget.textContent = "Sending..."
    this.disablePromptButtons(true)
    this.toggleSend()
  }

  submitEnd(event) {
    const success = event.detail.success

    if (!success) {
      this.clearPendingExchange()
      this.inputTarget.value = this.pendingMessage
      this.autoResize()
      this.updateCounter()
      this.setStatus("Message could not be sent. Please try again.")
      this.isSubmitting = false
      this.disablePromptButtons(false)
      this.sendLabelTarget.textContent = "Send"
      this.toggleSend()
      this.inputTarget.focus()
      return
    }

    this.isSubmitting = false
    this.disablePromptButtons(false)
    this.sendLabelTarget.textContent = "Send"
    this.toggleSend()
    this.setStatus("Press Enter to send. Use Shift+Enter for a new line.")
  }

  toggleSend() {
    const hasContent = this.inputTarget.value.trim().length > 0
    this.sendButtonTarget.disabled = this.isSubmitting || !hasContent
  }

  autoResize() {
    this.inputTarget.style.height = "auto"
    this.inputTarget.style.height = `${Math.min(this.inputTarget.scrollHeight, 160)}px`
  }

  updateCounter() {
    this.counterTarget.textContent = this.inputTarget.value.length
  }

  insertPrompt(event) {
    if (this.isSubmitting) return

    const prompt = event.params.prompt || ""
    this.inputTarget.value = prompt
    this.autoResize()
    this.updateCounter()
    this.toggleSend()
    this.setStatus("Press Enter to send. Use Shift+Enter for a new line.")
    this.inputTarget.focus()
  }

  renderPendingExchange(message) {
    const safeMessage = this.escapeHtml(message).replace(/\n/g, "<br>")
    const placeholderLines = [
      "Thinking through this with you...",
      "Putting together a practical next step..."
    ]

    const wrapper = document.createElement("div")
    wrapper.className = "space-y-2 js-pending-exchange"
    wrapper.innerHTML = `
      <div class="flex justify-end gap-2">
        <div class="max-w-[80%] rounded-2xl rounded-br-sm bg-blue-600 px-4 py-2 text-sm text-white shadow-sm">
          <p class="m-0 whitespace-pre-wrap">${safeMessage}</p>
        </div>
      </div>
      <div class="flex justify-start gap-2">
        <div class="max-w-[80%] rounded-2xl rounded-bl-sm border border-slate-200 bg-white px-4 py-3 text-sm text-slate-800 shadow-sm">
          <div class="space-y-2">
            <p class="m-0 text-slate-500">${placeholderLines[0]}</p>
            <p class="m-0 text-slate-400">${placeholderLines[1]}</p>
            <div class="flex gap-1 pt-1">
              <span class="h-2 w-2 animate-pulse rounded-full bg-slate-400"></span>
              <span class="h-2 w-2 animate-pulse rounded-full bg-slate-400" style="animation-delay: 0.1s"></span>
              <span class="h-2 w-2 animate-pulse rounded-full bg-slate-400" style="animation-delay: 0.2s"></span>
            </div>
          </div>
        </div>
      </div>
    `

    this.historyTarget.append(wrapper)
    this.scrollToBottom()
  }

  clearPendingExchange() {
    this.historyTarget.querySelectorAll(".js-pending-exchange").forEach((node) => node.remove())
  }

  disablePromptButtons(disabled) {
    this.promptButtonTargets.forEach((button) => {
      button.disabled = disabled
    })
  }

  setStatus(text) {
    this.statusTarget.textContent = text
  }

  scrollToBottom() {
    this.historyTarget.scrollTop = this.historyTarget.scrollHeight
  }

  escapeHtml(text) {
    return text
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;")
  }
}
