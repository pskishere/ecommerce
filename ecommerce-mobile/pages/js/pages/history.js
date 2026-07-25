import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

let historyItems = []

function escHtml(str) {
  return String(str ?? '').replace(/[&<>"']/g, ch => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  }[ch]))
}

async function loadHistory() {
  try {
    historyItems = await api.history.getList()
  } catch (e) {
    historyItems = []
    showToast('足迹加载失败')
  }
  document.getElementById('historySkeleton')?.classList.add('loaded')
  renderHistory()
}

function openProduct(productId) {
  sessionStorage.setItem('productId', productId)
  window.location.href = 'product-detail.html'
}

function renderHistory() {
  const grid = document.getElementById('historyGrid')
  if (!grid) return

  if (historyItems.length === 0) {
    grid.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/><polyline points="12 7 12 12 16 14"/></svg>
        </div>
        <div class="empty-text">暂无浏览记录</div>
        <button class="empty-btn" onclick="window.location.href='index.html'">去逛逛</button>
      </div>`
    return
  }

  grid.innerHTML = historyItems.map(item => `
    <div class="history-card" onclick="openProduct('${item.id}')">
      <div class="history-img-wrap">
        <img class="history-img" src="${item.img}" alt="${escHtml(item.name)}">
        <div class="history-remove" onclick="event.stopPropagation(); removeHistoryItem('${item.historyId}')">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </div>
      </div>
      <div class="history-info">
        <div class="history-name">${escHtml(item.name)}</div>
        <div class="history-bottom">
          <div class="history-price">¥${item.price}</div>
          <div class="history-time">${escHtml(item.viewedAt)}</div>
        </div>
      </div>
    </div>
  `).join('')
}

async function removeHistoryItem(id) {
  try {
    await api.history.remove(id)
    historyItems = historyItems.filter(item => item.historyId !== id)
    renderHistory()
    showToast('已删除')
  } catch (e) {
    showToast('删除失败')
  }
}

async function clearHistory() {
  if (historyItems.length === 0) return
  if (!confirm('确定清空全部浏览记录吗？')) return
  try {
    await api.history.clear()
    historyItems = []
    renderHistory()
    showToast('已清空')
  } catch (e) {
    showToast('清空失败')
  }
}

window.openProduct = openProduct
window.removeHistoryItem = removeHistoryItem
window.clearHistory = clearHistory

loadHistory()
