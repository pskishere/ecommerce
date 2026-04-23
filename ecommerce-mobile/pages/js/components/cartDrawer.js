/* ── Cart Drawer Component ── */
import { api } from '../data/api.js'
import { showToast } from './toast.js'

function getCart() { return api.cart._load() }
function getTotal() { return api.cart._total() }

export function initCartDrawer() {
  updateCartBadge()

  document.getElementById('cartBackdrop')?.addEventListener('click', closeCartDrawer)
  document.getElementById('cartClose')?.addEventListener('click', closeCartDrawer)
  document.getElementById('cartEmptyBtn')?.addEventListener('click', closeCartDrawer)

  document.getElementById('cartCheckout')?.addEventListener('click', () => {
    const cart = getCart()
    if (cart.length === 0) return
    showToast(`结算 ${cart.length} 件商品，共 ¥${getTotal()}`)
  })
}

export function openCartDrawer() {
  const drawer = document.getElementById('cartDrawer')
  if (!drawer) return

  drawer.classList.add('open')
  document.body.style.overflow = 'hidden'

  const cart = getCart()
  const total = getTotal()

  const emptyEl = document.getElementById('cartEmpty')
  const footerEl = document.getElementById('cartFooter')
  const itemsEl = document.getElementById('cartItems')
  const totalEl = document.getElementById('cartTotalPrice')

  if (emptyEl) emptyEl.style.display = cart.length === 0 ? '' : 'none'
  if (footerEl) footerEl.style.display = cart.length === 0 ? 'none' : ''
  if (totalEl) totalEl.textContent = `¥${total}`

  if (itemsEl) {
    itemsEl.innerHTML = cart.map((item, i) => `
      <div class="cart-item" data-index="${i}">
        <div class="cart-item-img"><img src="${item.img}" alt="${item.name}"></div>
        <div class="cart-item-info">
          <span class="cart-item-name">${item.name}</span>
          <div class="cart-item-bottom">
            <span class="cart-item-price">¥${item.price * item.qty}</span>
            <div class="cart-item-qty">
              <button class="cart-qty-btn" onclick="window.__cartChangeQty(${i}, -1)">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><line x1="5" y1="12" x2="19" y2="12"/></svg>
              </button>
              <span class="cart-qty-num">${item.qty}</span>
              <button class="cart-qty-btn" onclick="window.__cartChangeQty(${i}, 1)">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
              </button>
            </div>
          </div>
        </div>
        <button class="cart-item-remove" onclick="window.__cartRemove(${i})" aria-label="删除">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
        </button>
      </div>`).join('')
  }
}

export function closeCartDrawer() {
  document.getElementById('cartDrawer')?.classList.remove('open')
  document.body.style.overflow = ''
}

window.__cartRemove = function(index) {
  const el = document.querySelector(`.cart-item[data-index="${index}"]`)
  if (el) {
    el.classList.add('removing')
    setTimeout(() => {
      api.cart.removeByIndex(index)
      openCartDrawer()
    }, 250)
  }
}

window.__cartChangeQty = function(index, delta) {
  const cart = getCart()
  const newQty = cart[index].qty + delta
  if (newQty <= 0) {
    window.__cartRemove(index)
  } else {
    api.cart.changeQty(cart[index].id, delta)
    openCartDrawer()
  }
}

function updateCartBadge() {
  const badge = document.getElementById('cartBadge')
  const count = getCart().reduce((sum, item) => sum + item.qty, 0)
  if (badge) {
    badge.textContent = count > 99 ? '99+' : count
    badge.style.display = count > 0 ? '' : 'none'
  }
}
