/* ── Order Detail Page ── */
import { showToast } from '../components/toast.js'
import { api } from '../data/api.js'

async function loadOrderDetail() {
  const id = sessionStorage.getItem('orderId')
  sessionStorage.removeItem('orderId')
  if (!id) {
    showToast('订单不存在')
    return
  }
  const detail = await api.order.getById(id)
  document.getElementById('detailSkeleton')?.classList.add('loaded')
  renderOrderDetail(detail)
}

function renderOrderDetail(order) {
  const detailBody = document.getElementById('detailBody')
  const detailBar = document.getElementById('detailBar')
  if (!detailBody || !order) return

  detailBody.innerHTML = `
    <div class="detail-section">
      <div class="status-section">
        <div class="status-icon ${order.status}">
          ${order.status === 'pending' ? '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>' : ''}
          ${order.status === 'completed' ? '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>' : ''}
          ${order.status === 'shipped' ? '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>' : ''}
          ${order.status === 'paid' ? '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>' : ''}
          ${order.status === 'cancelled' ? '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>' : ''}
        </div>
        <div class="status-info">
          <div class="status-text">${order.statusText}</div>
          <div class="status-desc">${order.statusDesc || ''}</div>
        </div>
      </div>
    </div>

    <div class="detail-section">
      <div class="detail-section-body">
        <div class="address-section">
          <div class="address-icon">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
          </div>
          <div class="address-info">
            <div class="address-name">${order.address?.name || ''} ${order.address?.phone || ''}</div>
            <div class="address-detail">${order.address?.province || ''} ${order.address?.city || ''} ${order.address?.district || ''} ${order.address?.detail || ''}</div>
          </div>
        </div>
      </div>
    </div>

    <div class="detail-section">
      <div class="detail-section-body">
        <div class="store-section">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          <span class="store-name">${order.store}</span>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
        </div>
      </div>
    </div>

    <div class="detail-section">
      <div class="detail-section-body">
        <div class="product-list">
          ${order.products.map(p => `
            <div class="product-item">
              <div class="product-img"><img src="${p.img}" alt="${p.name}"></div>
              <div class="product-info">
                <div class="product-name">${p.name}</div>
                <div class="product-spec">${p.spec}</div>
                <div class="product-bottom">
                  <div class="product-price">¥${p.price}</div>
                  <div class="product-qty">x${p.qty}</div>
                </div>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    </div>

    <div class="detail-section">
      <div class="detail-section-body">
        <div class="info-row"><span class="info-label">商品总价</span><span class="info-value">¥${order.total}</span></div>
        <div class="info-row"><span class="info-label">运费</span><span class="info-value">${order.freight === 0 ? '免运费' : '¥' + order.freight}</span></div>
        ${order.discount ? `<div class="info-row"><span class="info-label">优惠</span><span class="info-value">-¥${order.discount}</span></div>` : ''}
        <div class="info-row"><span class="info-label">订单编号</span><span class="info-value">${order.id} <span style="color:#FF6B4A;margin-left:8px" onclick="copyOrderId()">复制</span></span></div>
        ${order.createTime ? `<div class="info-row"><span class="info-label">下单时间</span><span class="info-value">${order.createTime}</span></div>` : ''}
        ${order.payTime ? `<div class="info-row"><span class="info-label">支付时间</span><span class="info-value">${order.payTime}</span></div>` : ''}
        <div class="info-row" style="border-bottom:none"><span class="info-label">实付金额</span><span class="info-value" style="color:#FF6B4A;font-weight:700;font-size:16px">¥${order.payment}</span></div>
      </div>
    </div>

    ${order.logistics?.length > 0 ? `
    <div class="detail-section">
      <div class="detail-section-header"><span class="detail-section-title">物流信息</span></div>
      <div class="logistics-section">
        ${order.logistics.map(log => `
          <div class="logistics-item">
            <div class="logistics-dot ${log.active ? 'active' : ''}"></div>
            <div class="logistics-content">
              <div class="logistics-text">${log.text}</div>
              <div class="logistics-time">${log.time}</div>
            </div>
          </div>
        `).join('')}
      </div>
    </div>` : ''}
  `

  let buttons = ''
  if (order.status === 'pending') {
    buttons = `
      <button class="detail-btn detail-btn-danger" onclick="cancelOrder()">取消订单</button>
      <button class="detail-btn detail-btn-primary" onclick="payOrder()">去支付</button>`
  } else if (order.status === 'shipped') {
    buttons = `
      <button class="detail-btn detail-btn-outline" onclick="showToast('查看物流')">查看物流</button>
      <button class="detail-btn detail-btn-primary" onclick="confirmReceive()">确认收货</button>`
  } else if (order.status === 'completed') {
    buttons = `
      <button class="detail-btn detail-btn-outline" onclick="showToast('再次购买')">再次购买</button>
      <button class="detail-btn detail-btn-primary" onclick="location.href='review.html'">去评价</button>`
  }
  detailBar.innerHTML = buttons
}

async function cancelOrder() {
  const params = new URLSearchParams(location.search)
  const id = params.get('id')
  await api.order.cancel(id)
  showToast('订单已取消')
  setTimeout(() => history.back(), 1500)
}

async function payOrder() {
  const params = new URLSearchParams(location.search)
  const id = params.get('id')
  showToast('跳转支付...')
  await api.order.pay(id)
  showToast('支付成功')
  setTimeout(() => history.back(), 1500)
}

async function confirmReceive() {
  const params = new URLSearchParams(location.search)
  const id = params.get('id')
  await api.order.confirmReceipt(id)
  showToast('已确认收货')
  setTimeout(() => history.back(), 1500)
}

function copyOrderId() {
  const params = new URLSearchParams(location.search)
  const id = params.get('id') || 'ORDER20260327001'
  navigator.clipboard.writeText(id).then(() => showToast('订单编号已复制'))
}

window.cancelOrder = cancelOrder
window.payOrder = payOrder
window.confirmReceive = confirmReceive
window.copyOrderId = copyOrderId

loadOrderDetail()
