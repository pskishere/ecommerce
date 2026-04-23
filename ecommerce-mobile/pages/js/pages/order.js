/* ── Order Page ── */
import { showToast } from '../components/toast.js'
import { api } from '../data/api.js'
import { createContentTab } from '../components/content-tab.js'

let allOrders = []

async function loadOrders() {
  allOrders = await api.order.getList()
  console.log('[Order] allOrders:', JSON.stringify(allOrders.map(o => ({id: o.id, status: o.status, products: o.products.map(p => ({name: p.name, img: p.img}))}))))
  document.getElementById('orderSkeleton')?.classList.add('loaded')
  renderOrders(getTabFromURL())
}

function getTabFromURL() {
  const params = new URLSearchParams(location.search)
  return params.get('tab') || 'all'
}

createContentTab({
  id: 'orderTabs',
  tabs: [
    { value: 'all', label: '全部' },
    { value: 'pending', label: '待付款' },
    { value: 'paid', label: '待发货' },
    { value: 'shipped', label: '待收货' },
    { value: 'completed', label: '已完成' },
  ],
  defaultTab: getTabFromURL(),
  onChange: (tab) => renderOrders(tab),
})

function renderOrders(currentTab) {
  const orderList = document.getElementById('orderList')
  let orders = currentTab === 'all'
    ? allOrders
    : allOrders.filter(o => o.status === currentTab)

  if (orders.length === 0) {
    orderList.innerHTML = `
      <div class="order-empty">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
        <div class="order-empty-text">暂无相关订单</div>
        <button class="order-empty-btn" onclick="location.href='index.html'">去逛逛</button>
      </div>`
    return
  }

  orderList.innerHTML = orders.map(order => `
    <div class="order-card" onclick="location.href='order-detail.html?id=${order.id}'">
      <div class="order-card-header">
        <div class="order-store">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          ${order.store}
        </div>
        <div class="order-status ${order.status}">${order.statusText}</div>
      </div>
      <div class="order-card-body">
        <div class="order-products">
          ${order.products.map(p => `
            <div class="order-product">
              <div class="order-product-img"><img src="${p.image}" alt="${p.name}" onerror="this.src='./assets/images/icon-beauty-08.webp'"></div>
              <div class="order-product-info">
                <div class="order-product-name">${p.name}</div>
                <div class="order-product-spec">${p.spec}</div>
                <div class="order-product-bottom">
                  <div class="order-product-price">¥${p.price}</div>
                  <div class="order-product-qty">x${p.quantity}</div>
                </div>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
      <div class="order-card-footer">
        <div class="order-total">共${order.products.length}件商品，合计<strong>¥${order.total_amount}</strong></div>
        <div class="order-actions" onclick="event.stopPropagation();event.preventDefault();">
          ${order.status === 'pending' ? `
            <button class="order-btn order-btn-outline" onclick="window.orderActions.cancel('${order.id}')">取消</button>
            <button class="order-btn order-btn-primary" onclick="window.orderActions.pay('${order.id}')">去付款</button>
          ` : order.status === 'shipped' ? `
            <button class="order-btn order-btn-outline" onclick="showToast('查看物流')">查看物流</button>
            <button class="order-btn order-btn-primary" onclick="window.orderActions.confirmReceipt('${order.id}')">确认收货</button>
          ` : order.status === 'completed' ? `
            <button class="order-btn order-btn-outline" onclick="location.href='order-detail.html?id=${order.id}'">查看详情</button>
            <button class="order-btn order-btn-primary" onclick="location.href='review.html'">去评价</button>
          ` : ''}
        </div>
      </div>
    </div>
  `).join('')
}

window.orderActions = {
  cancel: async (id) => { await api.order.cancel(id); showToast('已取消订单'); loadOrders() },
  pay: (id) => { showToast('跳转支付...'); setTimeout(() => api.order.pay(id).then(() => { showToast('支付成功'); loadOrders() }), 500) },
  confirmReceipt: async (id) => { await api.order.confirmReceipt(id); showToast('已确认收货'); loadOrders() },
}

loadOrders()
