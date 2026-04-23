/* ── Checkout Page ── */
import { api, BASE_URL } from '../data/api.js'
import { showToast } from '../components/toast.js'

// 检查是否已登录，未登录则跳转登录页
const token = localStorage.getItem('token')
if (!token) {
  window.location.href = 'login.html?redirect=checkout.html'
}

let orderPreview = null
let selectedCoupon = null
let selectedAddress = null
let remark = ''
let paymentMethod = 'wxpay'
let availableCoupons = []

async function loadOrderItems() {
  // 1. 同步购物车
  try {
    await api.cart.getList()
  } catch (e) { console.error('cart sync failed', e) }

  // 2. 并行加载地址和优惠券
  let addresses = [], coupons = []
  try {
    ;[addresses, coupons] = await Promise.all([
      api.checkout.getAddresses(),
      api.checkout.getCoupons(),
    ])
  } catch (e) {
    console.error('load addresses/coupons failed', e)
  }

  // 3. 回填默认地址和可用优惠券
  selectedAddress = addresses.find(a => a.isDefault) || addresses[0] || null
  availableCoupons = (coupons || []).map(c => ({ ...c }))
  updateCouponUsable()
  await renderCheckout()
}

function updateCouponUsable() {
  if (!orderPreview) return
  const subtotal = orderPreview.subtotal || 0
  availableCoupons = availableCoupons.map(c => ({
    ...c,
    usable: subtotal >= (parseFloat(c.threshold) || 0)
  }))
}

async function renderCheckout() {
  const body = document.getElementById('checkoutBody')
  if (!body) return

  // 加载本地购物车
  const cart = JSON.parse(localStorage.getItem('cart') || '[]')
  const selectedItems = cart.filter(item => item.selected)

  if (selectedItems.length === 0) {
    body.innerHTML = `<div class="checkout-empty"><svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg><div class="checkout-empty-text">请先选择商品</div><button class="checkout-empty-btn" onclick="window.location.href='cart.html'">去购物车</button></div>`
    document.getElementById('checkoutBar')?.remove()
    return
  }

  // 预订单
  if (!orderPreview) {
    const cartItemIds = selectedItems.map(item => item.cartId || item.id).filter(Boolean)
    try {
      orderPreview = await api.order.preview({
        cartItemIds,
        addressId: selectedAddress?.id || ''
      })
      // API 返回空则用本地数据
      if (!orderPreview?.items?.length) throw new Error('preview empty')
    } catch (e) {
      console.error('preview failed, using local', e)
      orderPreview = {
        items: selectedItems.map(item => ({
          cartId: item.cartId || item.id,
          productId: item.id,
          name: item.name,
          price: item.price,
          originalPrice: item.original || item.price,
          quantity: item.qty,
          image: item.img
        })),
        subtotal: selectedItems.reduce((s, i) => s + i.price * i.qty, 0),
        freight: 0,
        total: selectedItems.reduce((s, i) => s + i.price * i.qty, 0),
        store: '官方旗舰店'
      }
    }
    updateCouponUsable()
  }

  const { items, subtotal, freight, total, store } = orderPreview
  const discount = selectedCoupon ? parseFloat(selectedCoupon.discount) || 0 : 0
  const finalTotal = Math.max(0, total - discount)

  renderBody(items, subtotal, freight, finalTotal, store)
  renderBottomBar(finalTotal)
}

function renderBody(items, subtotal, freight, finalTotal, store) {
  const body = document.getElementById('checkoutBody')
  const discount = selectedCoupon ? parseFloat(selectedCoupon.discount) || 0 : 0

  body.innerHTML = `
    <div class="address-section" onclick="openAddressSheet()">
      ${selectedAddress ? `
      <div class="address-icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg></div>
      <div class="address-info">
        <div class="address-user">
          <span class="address-name">${selectedAddress.name}</span>
          <span class="address-phone">${selectedAddress.phone}</span>
          ${selectedAddress.isDefault ? '<span class="address-default-tag">默认</span>' : ''}
        </div>
        <div class="address-detail">${selectedAddress.province} ${selectedAddress.city} ${selectedAddress.district} ${selectedAddress.detail}</div>
      </div>
      <div class="address-arrow"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg></div>
      ` : `
      <div class="address-icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg></div>
      <div class="address-info"><div class="address-user"><span class="address-name" style="color:#FF6B4A">请添加收货地址</span></div></div>
      <div class="address-arrow"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg></div>
      `}
    </div>

    <div class="order-section">
      <div class="order-store-header">
        <div class="store-logo-small"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg></div>
        <span class="store-name-small">${store}</span>
      </div>
      ${items.map(item => `
        <div class="order-item">
          <div class="order-item-img"><img src="${item.image}" alt="${item.name}"></div>
          <div class="order-item-info">
            <div class="order-item-name">${item.name}</div>
            <div class="order-item-spec">${item.spec || ''}</div>
            <div class="order-item-bottom">
              <span class="order-item-price">¥${item.price}</span>
              <span class="order-item-qty">x${item.quantity}</span>
            </div>
          </div>
        </div>
      `).join('')}
    </div>

    <div class="coupon-row" onclick="openCouponSheet()">
      <div class="coupon-left">
        <div class="coupon-icon"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg></div>
        <span class="coupon-label">优惠券</span>
      </div>
      <div class="coupon-right">
        <span class="coupon-value">${selectedCoupon ? `-¥${selectedCoupon.discount}` : availableCoupons.filter(c => c.usable).length > 0 ? `${availableCoupons.filter(c => c.usable).length}张可用` : '暂无可用'}</span>
        <span class="coupon-arrow"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg></span>
      </div>
    </div>

    <div class="payment-section">
      <div class="payment-title">支付方式</div>
      <div class="payment-options">
        <div class="payment-option ${paymentMethod === 'wxpay' ? 'selected' : ''}" data-method="wxpay" onclick="selectPayment('wxpay')">
          <div class="payment-radio"></div>
          <div class="payment-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4"/><circle cx="12" cy="12" r="10"/></svg></div>
          <span class="payment-name">微信支付</span>
          <span class="payment-tag">推荐</span>
        </div>
        <div class="payment-option ${paymentMethod === 'alipay' ? 'selected' : ''}" data-method="alipay" onclick="selectPayment('alipay')">
          <div class="payment-radio"></div>
          <div class="payment-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M7 15h10M7 11h6"/></svg></div>
          <span class="payment-name">支付宝</span>
        </div>
      </div>
    </div>

    <div class="remark-row">
      <span class="remark-label">备注</span>
      <input type="text" class="remark-input" id="remarkInput" placeholder="选填，可备注特殊需求" maxlength="100" value="${remark}" oninput="updateRemark(this.value)">
    </div>

    <div class="price-section">
      <div class="price-row"><span class="label">商品金额</span><span class="value">¥${(subtotal || 0).toFixed(2)}</span></div>
      <div class="price-row discount"><span class="label">优惠券</span><span class="value">-¥${discount.toFixed(2)}</span></div>
      <div class="price-row"><span class="label">运费</span><span class="value">${freight === 0 ? '免运费' : '¥' + (freight || 0).toFixed(2)}</span></div>
      <div class="price-row total"><span class="label">合计</span><span class="value" id="finalTotal">¥${finalTotal.toFixed(2)}</span></div>
    </div>`
}

function renderBottomBar(total) {
  document.getElementById('checkoutBar')?.remove()
  const bar = document.createElement('div')
  bar.className = 'checkout-bar'
  bar.id = 'checkoutBar'
  bar.innerHTML = `<div class="checkout-total"><div class="checkout-total-price">¥${total.toFixed(2)}</div></div><button class="checkout-submit-btn" onclick="submitOrder()">提交订单</button>`
  document.body.appendChild(bar)
}

function selectPayment(method) {
  paymentMethod = method
  document.querySelectorAll('.payment-option').forEach(el => {
    el.classList.toggle('selected', el.dataset.method === method)
  })
}

function updateRemark(value) { remark = value }

function openSheet(sheetId) {
  document.getElementById('sheetOverlay').classList.add('show')
  document.getElementById(sheetId).classList.add('show')
}

function closeSheet() {
  document.getElementById('sheetOverlay').classList.remove('show')
  document.getElementById('addressSheet').classList.remove('show')
  document.getElementById('couponSheet').classList.remove('show')
}

function openAddressSheet() {
  api.checkout.getAddresses().then(addresses => {
    const list = document.getElementById('addrList')
    if (!addresses?.length) {
      list.innerHTML = '<div style="padding:20px;text-align:center;color:#999">暂无收货地址</div>'
    } else {
      list.innerHTML = addresses.map(addr => `
        <div class="addr-item ${addr.id === selectedAddress?.id ? 'selected' : ''}" onclick="selectAddress(${JSON.stringify(addr).replace(/"/g, '&quot;')})">
          <div class="addr-item-top">
            <div class="addr-check"></div>
            <div class="addr-item-info">
              <div class="addr-item-user">
                <span class="addr-item-name">${addr.name}</span>
                <span class="addr-item-phone">${addr.phone}</span>
                ${addr.isDefault ? '<span class="addr-item-default">默认</span>' : ''}
              </div>
              <div class="addr-item-detail">${addr.province} ${addr.city} ${addr.district} ${addr.detail}</div>
            </div>
          </div>
        </div>
      `).join('')
    }
    openSheet('addressSheet')
  }).catch(err => {
    console.error('openAddressSheet error', err)
    document.getElementById('addrList').innerHTML = '<div style="padding:20px;text-align:center;color:#999">加载失败</div>'
    openSheet('addressSheet')
  })
}

function selectAddress(addr) {
  selectedAddress = addr
  closeSheet()
  orderPreview = null
  renderCheckout()
  showToast('已选择收货地址')
}

function openCouponSheet() {
  const list = document.getElementById('couponList')
  if (!availableCoupons.length) {
    list.innerHTML = '<div style="padding:20px;text-align:center;color:#999">暂无可用优惠券</div>'
  } else {
    const usableCoupons = availableCoupons.filter(c => c.usable)
    list.innerHTML = `
      <div class="coupon-none-item ${!selectedCoupon ? 'selected' : ''}" onclick="selectCoupon(null)">
        <div class="coupon-none-radio"></div>
        <span class="coupon-none-text">不使用优惠券</span>
      </div>
      ${availableCoupons.map(c => `
        <div class="coupon-item ${c.id === selectedCoupon?.id ? 'selected' : ''} ${!c.usable ? 'disabled' : ''}" onclick="${c.usable ? 'selectCoupon(' + JSON.stringify(c).replace(/"/g, '&quot;') + ')' : ''}">
          <div class="coupon-item-left">
            <div class="coupon-item-discount"><span>¥</span>${c.discount}</div>
            <div class="coupon-item-threshold">满${c.threshold}元可用</div>
          </div>
          <div class="coupon-item-right">
            <div class="coupon-itemName">${c.name}</div>
            <div class="coupon-item-desc">${c.desc}</div>
            <div class="coupon-item-date">有效期至${c.validUntil}</div>
          </div>
        </div>
      `).join('')}
    `
  }
  openSheet('couponSheet')
}

function selectCoupon(coupon) {
  selectedCoupon = coupon
  closeSheet()
  renderCheckout()
  showToast(coupon ? `已选择：${coupon.name}` : '已取消优惠券')
}

async function submitOrder() {
  if (!orderPreview?.items?.length) { showToast('请先选择商品'); return }
  if (!selectedAddress) { showToast('请选择收货地址'); return }

  const cartItemIds = orderPreview.items.map(item => item.cartId).filter(Boolean)
  try {
    await api.order.create({
      cartItemIds,
      addressId: selectedAddress.id,
      couponId: selectedCoupon?.id || '',
      remark
    })
    showToast('订单提交成功！')
    // 清除已购买的商品
    const cart = JSON.parse(localStorage.getItem('cart') || '[]')
    const cartItemIdSet = new Set(cartItemIds)
    const remaining = cart.filter(item => !(item.cartId && cartItemIdSet.has(item.cartId)))
    localStorage.setItem('cart', JSON.stringify(remaining))
    setTimeout(() => { window.location.href = 'order.html' }, 1500)
  } catch (e) {
    showToast('订单提交失败')
    console.error('submitOrder error', e)
  }
}

loadOrderItems()

window.openAddressSheet = openAddressSheet
window.openCouponSheet = openCouponSheet
window.closeSheet = closeSheet
window.selectAddress = selectAddress
window.selectCoupon = selectCoupon
window.selectPayment = selectPayment
window.updateRemark = updateRemark
window.submitOrder = submitOrder
