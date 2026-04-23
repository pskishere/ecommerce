/* ── Address Page ── */
import { showToast } from '../components/toast.js'
import { api } from '../data/api.js'

let addrList = []

async function loadAddresses() {
  addrList = await api.address.getList()
  renderAddresses()
}

function renderAddresses() {
  const list = document.getElementById('addressList')
  if (!list) return

  if (addrList.length === 0) {
    list.innerHTML = `
      <div class="address-empty">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
        <div class="address-empty-text">暂无收货地址</div>
      </div>`
    return
  }

  list.innerHTML = addrList.map(addr => `
    <div class="address-card ${addr.isDefault ? 'default' : ''}">
      <div class="address-card-header">
        <span class="address-name">${addr.name}</span>
        <span class="address-phone">${addr.phone}</span>
      </div>
      <div class="address-detail">${addr.province} ${addr.city} ${addr.district} ${addr.detail}</div>
      <div class="address-card-footer">
        <button class="address-default-btn ${addr.isDefault ? 'active' : ''}" onclick="event.stopPropagation();setDefault(${addr.id})">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          ${addr.isDefault ? '默认地址' : '设为默认'}
        </button>
        <div class="address-actions">
          <button class="address-edit-btn" onclick="location.href='address-edit.html?id=${addr.id}'">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>编辑
          </button>
          <button class="address-del-btn" onclick="event.stopPropagation();deleteAddress(${addr.id})">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>删除
          </button>
        </div>
      </div>
    </div>`).join('')
}

async function setDefault(id) {
  await api.address.setDefault(id)
  addrList = addrList.map(a => ({ ...a, isDefault: a.id === id }))
  renderAddresses()
  showToast('已设为默认地址')
}

async function deleteAddress(id) {
  if (addrList.length <= 1) { showToast('至少保留一个地址'); return }
  await api.address.delete(id)
  addrList = addrList.filter(a => a.id !== id)
  renderAddresses()
  showToast('已删除地址')
}

loadAddresses()
