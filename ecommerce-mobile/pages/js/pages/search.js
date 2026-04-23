/* ── Search Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

let history = JSON.parse(localStorage.getItem('searchHistory') || '[]')
let allProducts = []
const searchInput = document.getElementById('searchInput')

// Auto-fill from URL parameter (after doSearch is defined)
const params = new URLSearchParams(location.search)
const kwParam = params.get('keyword')
if (kwParam && searchInput) {
  searchInput.value = kwParam
  history = [kwParam, ...history.filter(h => h !== kwParam)].slice(0, 20)
  localStorage.setItem('searchHistory', JSON.stringify(history))
  doSearch(kwParam)
}

function renderHistory() {
  const historyList = document.getElementById('historyList')
  const historySection = document.getElementById('historySection')
  if (!historyList || !historySection) return
  if (history.length === 0) {
    historySection.style.display = 'none'
    return
  }
  historySection.style.display = ''
  historyList.innerHTML = history.slice(0, 10).map(term => `
    <div class="history-item" onclick="doSearch('${term.replace(/'/g, "\\'")}')">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
      <span>${term}</span>
      <div class="history-del" onclick="event.stopPropagation();delHistory('${term.replace(/'/g, "\\'")}')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </div>
    </div>`).join('')
}

function delHistory(term) {
  history = history.filter(h => h !== term)
  localStorage.setItem('searchHistory', JSON.stringify(history))
  renderHistory()
}

function clearAllHistory() {
  history = []
  localStorage.setItem('searchHistory', JSON.stringify(history))
  renderHistory()
}

function resetSearch() {
  const hotSection = document.getElementById('hotSection')
  const historySection = document.getElementById('historySection')
  const searchResults = document.getElementById('searchResults')
  if (hotSection) hotSection.style.display = ''
  if (historySection) historySection.style.display = history.length > 0 ? '' : 'none'
  if (searchResults) searchResults.style.display = 'none'
  if (searchInput) searchInput.value = ''
  renderHistory()
}

function doSearch(term) {
  if (!term.trim()) return
  history = [term, ...history.filter(h => h !== term)].slice(0, 20)
  localStorage.setItem('searchHistory', JSON.stringify(history))

  const hotSection = document.getElementById('hotSection')
  const historySection = document.getElementById('historySection')
  const searchResults = document.getElementById('searchResults')
  if (hotSection) hotSection.style.display = 'none'
  if (historySection) historySection.style.display = 'none'
  if (searchResults) {
    searchResults.style.display = ''
    searchResults.innerHTML = '<div style="padding:20px 0;color:var(--gray-2);font-size:14px;text-align:center">搜索中...</div>'
  }

  // Search from all products
  const kw = term.trim().toLowerCase()
  const results = allProducts.filter(p => p.name.toLowerCase().includes(kw))

  if (results.length === 0) {
    if (searchResults) {
      searchResults.innerHTML = `<div class="no-results">未找到"${term}"相关商品</div>`
    }
    return
  }

  if (searchResults) {
    searchResults.innerHTML = `
      <div class="result-count">找到 ${results.length} 个商品</div>
      ${results.map(p => `
        <div class="result-card" onclick="sessionStorage.setItem('productId','${p.id}');window.location.href='product-detail.html'">
          <div class="result-img"><img src="${p.img}" alt="${p.name}"></div>
          <div class="result-info">
            <div class="result-name">${p.name}</div>
            <div class="result-bottom">
              <span class="result-price">¥${p.price}</span>
              ${p.original > p.price ? `<span class="result-original">¥${p.original}</span>` : ''}
              <span class="result-sales">已售 ${p.sales}</span>
            </div>
            ${p.rating ? `
            <div class="result-rating">
              ${[1,2,3,4,5].map(i => `
                <svg width="10" height="10" viewBox="0 0 24 24" fill="${i <= Math.round(p.rating) ? '#FFB800' : 'none'}" stroke="${i <= Math.round(p.rating) ? '#FFB800' : '#CCC'}" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
              `).join('')}
              <span>${p.rating.toFixed(1)}</span>
            </div>` : ''}
          </div>
        </div>
      `).join('')}`
  }
}

searchInput?.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && searchInput.value.trim()) {
    doSearch(searchInput.value.trim())
  }
})

// Clear button → reset to initial view
document.getElementById('searchClear')?.addEventListener('click', () => {
  if (searchInput) searchInput.value = ''
  resetSearch()
})

// If input becomes empty, show initial view
searchInput?.addEventListener('input', () => {
  if (!searchInput.value.trim()) {
    resetSearch()
  }
})

document.getElementById('searchBtn')?.addEventListener('click', () => {
  if (searchInput?.value.trim()) doSearch(searchInput.value.trim())
})

document.getElementById('clearHistory')?.addEventListener('click', clearAllHistory)

// Hot tag click → fill input + search
document.querySelectorAll('.hot-tag').forEach(tag => {
  tag.addEventListener('click', () => {
    const text = tag.textContent
    if (searchInput) searchInput.value = text
    doSearch(text)
  })
})

window.doSearch = doSearch
window.resetSearch = resetSearch
window.delHistory = delHistory
window.clearAllHistory = clearAllHistory

// Load all products for search
api.category.getList().then(categories => {
  allProducts = categories.flatMap(c => c.products || [])
})

renderHistory()