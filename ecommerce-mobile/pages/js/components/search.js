/* ============================================================
   潮流好物 — Search Component
   ============================================================ */

import { showToast } from './toast.js'

export function initSearch() {
  const overlay = document.getElementById('searchOverlay')
  const searchBtn = document.getElementById('searchBtn')
  const cancelBtn = document.getElementById('searchCancel')
  const input = document.getElementById('searchInput')
  const clearBtn = document.getElementById('searchClear')
  const hotSection = document.getElementById('searchHot')
  const historySection = document.getElementById('searchHistory')
  const historyList = document.getElementById('historyList')
  const resultsSection = document.getElementById('searchResults')

  if (!overlay || !searchBtn) return

  let history = JSON.parse(localStorage.getItem('searchHistory') || '[]')

  function openSearch() {
    overlay.classList.add('open')
    setTimeout(() => { input?.focus() }, 350)
    document.body.style.overflow = 'hidden'
    renderHistory()
  }

  function closeSearch() {
    overlay.classList.remove('open')
    document.body.style.overflow = ''
    if (input) input.value = ''
    if (clearBtn) clearBtn.style.display = 'none'
    if (hotSection) hotSection.style.display = ''
    if (historySection) historySection.style.display = history.length > 0 ? '' : 'none'
    if (resultsSection) resultsSection.style.display = 'none'
  }

  searchBtn.addEventListener('click', openSearch)
  cancelBtn?.addEventListener('click', closeSearch)
  document.getElementById('sheetBackdrop')?.addEventListener('click', closeSearch)

  input?.addEventListener('input', () => {
    if (!clearBtn || !hotSection || !historySection || !resultsSection) return
    clearBtn.style.display = input.value ? '' : 'none'
    if (input.value.length > 0) {
      hotSection.style.display = 'none'
      historySection.style.display = 'none'
      resultsSection.style.display = ''
      resultsSection.innerHTML = `
        <div class="product-card" style="cursor:pointer" onclick="document.getElementById('searchInput').value='${input.value}'; doSearch('${input.value}')">
          <div class="product-img-wrap" style="aspect-ratio:1">
            <div style="display:flex;align-items:center;justify-content:center;height:100%;background:var(--light);font-size:12px;color:var(--gray-2)">搜索 "${input.value}"</div>
          </div>
          <div class="product-info">
            <span class="product-name">查看全部结果</span>
            <div class="product-bottom">
              <span class="product-price" style="font-size:12px;color:var(--gray-1)">按回车搜索</span>
            </div>
          </div>
        </div>`
    } else {
      hotSection.style.display = ''
      resultsSection.style.display = 'none'
      resultsSection.innerHTML = ''
    }
  })

  clearBtn?.addEventListener('click', () => {
    if (!input || !clearBtn || !hotSection || !resultsSection) return
    input.value = ''
    clearBtn.style.display = 'none'
    hotSection.style.display = ''
    resultsSection.style.display = 'none'
    resultsSection.innerHTML = ''
    input.focus()
  })

  input?.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && input.value.trim()) {
      doSearch(input.value.trim())
    }
  })

  // Hot tags
  document.querySelectorAll('.hot-tag').forEach(tag => {
    tag.addEventListener('click', () => {
      if (input) {
        input.value = tag.textContent
        doSearch(tag.textContent)
      }
    })
  })

  function renderHistory() {
    if (!historySection || !historyList) return
    if (history.length === 0) {
      historySection.style.display = 'none'
      return
    }
    historySection.style.display = ''
    historyList.innerHTML = history.slice(0, 10).map(term => `
      <div class="history-item" onclick="document.getElementById('searchInput').value='${term}'; doSearch('${term}')">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        <span>${term}</span>
      </div>`).join('')
  }

  // Expose globally for inline onclick handlers
  window.doSearch = function(term) {
    if (!term) return
    history = [term, ...history.filter(h => h !== term)].slice(0, 20)
    localStorage.setItem('searchHistory', JSON.stringify(history))
    if (hotSection) hotSection.style.display = 'none'
    if (historySection) historySection.style.display = 'none'
    if (resultsSection) {
      resultsSection.style.display = ''
      resultsSection.innerHTML = `<p style="padding:20px 0;color:var(--gray-2);font-size:14px;text-align:center">搜索 "${term}" 的结果</p>`
    }
    showToast(`已搜索: ${term}`)
  }
}
