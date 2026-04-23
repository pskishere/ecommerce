/* ============================================================
   潮流好物 — Toast Component
   ============================================================ */

export function showToast(message) {
  const toast = document.getElementById('toast')
  if (!toast) return
  const text = document.getElementById('toastText')
  if (text) {
    text.textContent = message
  } else {
    toast.textContent = message
  }
  toast.classList.add('show')
  setTimeout(() => { toast.classList.remove('show') }, 2000)
}
