/* ── Notifications Page ── */
import { api } from '../data/api.js'
import { createContentTab } from '../components/content-tab.js'

let notifList = []

async function loadNotifs() {
  notifList = await api.notification.getList()
  renderNotifs('all')
}

createContentTab({
  id: 'notifTabs',
  tabs: [
    { value: 'all', label: '全部' },
    { value: 'order', label: '订单' },
    { value: 'promo', label: '优惠' },
    { value: 'sys', label: '系统' },
  ],
  defaultTab: 'all',
  onChange: (tab) => renderNotifs(tab),
})

function renderNotifs(currentTab) {
  const list = document.getElementById('notifList')
  if (!list || notifList.length === 0) return

  const filtered = currentTab === 'all' ? notifList : notifList.filter(n => n.type === currentTab)
  const notifs = filtered

  if (notifs.length === 0) {
    list.innerHTML = `
      <div class="notif-empty">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        <div class="notif-empty-text">暂无消息</div>
      </div>`
    return
  }

  const iconMap = {
    order: '<path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="2"/>',
    promo: '<path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/>',
    sys: '<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>',
    logistics: '<rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/>'
  }

  list.innerHTML = notifs.map(notif => `
    <div class="notif-card">
      <div class="notif-card-header">
        <div class="notif-icon ${notif.type}">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${iconMap[notif.type] || iconMap.sys}</svg>
        </div>
        <div class="notif-info">
          <div class="notif-name">${notif.name}</div>
          <div class="notif-time">${notif.time}</div>
        </div>
      </div>
      <div class="notif-content">${notif.content}</div>
      ${notif.action ? `<div class="notif-action">${notif.action} <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg></div>` : ''}
    </div>`).join('')
}

loadNotifs()
