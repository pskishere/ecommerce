/* ============================================================
   潮流好物 — Toast Component
   ============================================================ */

export function showToast(message) {
  const toast = document.getElementById('toast')
  const text = document.getElementById('toastText')
  if (!toast || !text) return
  text.textContent = message
  toast.classList.add('show')
  setTimeout(() => { toast.classList.remove('show') }, 2000)
}
