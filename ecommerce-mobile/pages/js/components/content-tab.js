/* ── Content Tab Component ── */

/**
 * Render a content tab bar.
 * @param {string} id - Unique container id
 * @param {Array<{value: string, label: string}>} tabs - Tab options
 * @param {string} defaultTab - Initially selected tab value
 * @param {Function} onChange - Called with (tabValue) when tab changes
 * @param {string} [accentColor='#FF6B4A']
 */
export function createContentTab({ id, tabs, defaultTab, onChange, accentColor = '#FF6B4A' }) {
  const container = document.getElementById(id)
  if (!container) return

  let current = defaultTab ?? tabs[0]?.value

  function render() {
    container.innerHTML = tabs.map(tab => `
      <div class="content-tab ${tab.value === current ? 'active' : ''}" data-tab="${tab.value}">
        ${tab.label}
      </div>
    `).join('')

    container.querySelectorAll('.content-tab').forEach(el => {
      el.addEventListener('click', () => {
        if (el.dataset.tab === current) return
        current = el.dataset.tab
        render()
        onChange?.(current)
      })
    })
  }

  render()
  return () => current
}
