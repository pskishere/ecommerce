/* ── Order Page ── */
import { showToast } from '../components/toast.js'
import { api } from '../data/api.js'
import { createContentTab } from '../components/content-tab.js'

let allOrders = []

function escHtml(str) {
  return String(str ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
}

function reviewUrl(order) {
  const product = order.products?.[0]
  const params = new URLSearchParams({ orderId: order.id })
  if (product?.productId) params.set('productId', product.productId)
  return `review.html?${params.toString()}`
}

function storeReviewContext(order) {
  const product = order?.products?.[0]
  sessionStorage.setItem('reviewOrderId', order.id)
  if (product?.productId) sessionStorage.setItem('reviewProductId', product.productId)
}

function orderDetailUrl(id) {
  return `order-detail.html?id=${id}`
}

async function loadOrders() {
  allOrders = await api.order.getList()
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
    { value: 'refund', label: '售后' },
  ],
  defaultTab: getTabFromURL(),
  onChange: (tab) => renderOrders(tab),
})

function renderOrders(currentTab) {
  const orderList = document.getElementById('orderList')
  let orders = currentTab === 'all'
    ? allOrders
    : currentTab === 'refund'
      ? allOrders.filter(o => o.afterSaleStatus && o.afterSaleStatus !== 'none')
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
    <div class="order-card" onclick="window.orderActions.detail('${order.id}')">
      <div class="order-card-header">
        <div class="order-store">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          ${escHtml(order.store)}
        </div>
        <div class="order-status ${order.status}">${escHtml(order.statusText)}</div>
      </div>
      <div class="order-card-body">
        <div class="order-products">
          ${order.products.map(p => `
            <div class="order-product">
              <div class="order-product-img"><img src="${escHtml(p.image)}" alt="${escHtml(p.name)}" onerror="this.src='./assets/images/icon-beauty-08.webp'"></div>
              <div class="order-product-info">
                <div class="order-product-name">${escHtml(p.name)}</div>
                <div class="order-product-spec">${escHtml(p.spec)}</div>
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
            <button class="order-btn order-btn-outline" onclick="window.orderActions.detail('${order.id}')">查看物流</button>
            <button class="order-btn order-btn-primary" onclick="window.orderActions.confirmReceipt('${order.id}')">确认收货</button>
          ` : order.status === 'completed' ? `
            <button class="order-btn order-btn-outline" onclick="window.orderActions.buyAgain('${order.id}')">再次购买</button>
            <button class="order-btn order-btn-primary" onclick="window.orderActions.review('${order.id}')">去评价</button>
          ` : ''}
        </div>
      </div>
    </div>
  `).join('')
}

window.orderActions = {
  detail: (id) => {
    sessionStorage.setItem('orderId', id)
    window.location.href = orderDetailUrl(id)
  },
  cancel: async (id) => {
    try { await api.order.cancel(id); showToast('已取消订单'); loadOrders() }
    catch { showToast('取消失败，请重试') }
  },
  pay: (id) => {
    const order = allOrders.find(o => o.id === id)
    const amount = order?.payment ?? order?.total_amount ?? '0.00'
    sessionStorage.setItem('paymentOrderId', id)
    sessionStorage.setItem('paymentAmount', amount)
    window.location.href = `payment.html?orderId=${id}&amount=${amount}`
  },
  review: (id) => {
    const order = allOrders.find(o => o.id === id)
    if (!order) return
    storeReviewContext(order)
    window.location.href = reviewUrl(order)
  },
  confirmReceipt: async (id) => {
    try { await api.order.confirmReceipt(id); showToast('已确认收货'); loadOrders() }
    catch { showToast('操作失败，请重试') }
  },
  buyAgain: async (id) => {
    try {
      await api.order.buyAgain(id)
      showToast('已加入购物车')
      setTimeout(() => { window.location.href = 'cart.html' }, 800)
    } catch {
      showToast('再次购买失败')
    }
  },
}

loadOrders()
