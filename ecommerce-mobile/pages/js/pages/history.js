/* ── History Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

function formatTime(timestamp) {
  const now = Date.now()
  const diff = now - timestamp
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)

  if (minutes < 1) return '刚刚'
  if (minutes < 60) return `${minutes}分钟前`
  if (hours < 24) return `${hours}小时前`
  if (days < 7) return `${days}天前`
  return new Date(timestamp).toLocaleDateString('zh-CN')
}

async function loadHistory() {
  const historyItems = await api.history.getList()
  document.getElementById('historySkeleton')?.classList.add('loaded')
  renderHistory(historyItems)
}

function renderHistory(historyItems) {
  const list = document.getElementById('historyList')
  const clearBtn = document.getElementById('clearBtn')
  if (!list) return

  if (historyItems.length === 0) {
    list.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        </div>
        <div class="empty-text">暂无浏览记录</div>
        <button class="empty-btn" onclick="window.location.href='index.html'">去逛逛</button>
      </div>`
    if (clearBtn) clearBtn.style.display = 'none'
    return
  }

  if (clearBtn) clearBtn.style.display = ''
  list.innerHTML = historyItems.map(item => `
    <div class="history-item" onclick="window.location.href='product-detail.html?id=${item.id}'">
      <div class="history-img-wrap">
        <img class="history-img" src="${item.img}" alt="${item.name}">
      </div>
      <div class="history-info">
        <div class="history-name">${item.name}</div>
        <div class="history-price">¥${item.price}</div>
        <div class="history-time">浏览于 ${formatTime(item.time)}</div>
      </div>
      <div class="history-remove" onclick="event.stopPropagation(); removeItem(${item.id})">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </div>
    </div>`).join('')
}

async function removeItem(id) {
  await api.history.remove(id)
  showToast('已删除')
  loadHistory()
}

async function clearAll() {
  await api.history.clear()
  showToast('已清空')
  loadHistory()
}

window.removeItem = removeItem
window.clearAllHistory = clearAll

document.getElementById('clearBtn')?.addEventListener('click', clearAll)

loadHistory()
