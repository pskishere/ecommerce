/* ── Cart Drawer Component ── */
import { api } from '../data/api.js'
import { showToast } from './toast.js'

const isAuthenticated = () => Boolean(localStorage.getItem('token'))

async function getCartState() {
  if (!isAuthenticated()) return { items: [], total: 0 }
  try {
    const result = await api.cart.getList()
    return {
      items: result.items || [],
      total: Number(result.total || 0)
    }
  } catch {
    return { items: [], total: 0 }
  }
}

export function initCartDrawer() {
  updateCartBadge()

  document.getElementById('cartBackdrop')?.addEventListener('click', closeCartDrawer)
  document.getElementById('cartClose')?.addEventListener('click', closeCartDrawer)
  document.getElementById('cartEmptyBtn')?.addEventListener('click', closeCartDrawer)

  document.getElementById('cartCheckout')?.addEventListener('click', async () => {
    const { items } = await getCartState()
    if (items.length === 0) return
    window.location.href = 'cart.html'
  })
}

export async function openCartDrawer() {
  const drawer = document.getElementById('cartDrawer')
  if (!drawer) return

  drawer.classList.add('open')
  document.body.style.overflow = 'hidden'

  const { items: cart, total } = await getCartState()

  const emptyEl = document.getElementById('cartEmpty')
  const footerEl = document.getElementById('cartFooter')
  const itemsEl = document.getElementById('cartItems')
  const totalEl = document.getElementById('cartTotalPrice')

  if (emptyEl) emptyEl.style.display = cart.length === 0 ? '' : 'none'
  if (footerEl) footerEl.style.display = cart.length === 0 ? 'none' : ''
  if (totalEl) totalEl.textContent = `¥${total.toFixed(2)}`

  if (itemsEl) {
    itemsEl.innerHTML = cart.map((item, i) => `
      <div class="cart-item" data-index="${i}" data-cart-id="${item.cartId}">
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
    setTimeout(async () => {
      const cartId = el.dataset.cartId
      if (cartId) await api.cart.removeItem(cartId).catch(() => showToast('删除失败'))
      await openCartDrawer()
      updateCartBadge()
    }, 250)
  }
}

window.__cartChangeQty = async function(index, delta) {
  const { items: cart } = await getCartState()
  const item = cart[index]
  if (!item) return
  const newQty = item.qty + delta
  if (newQty <= 0) return window.__cartRemove(index)
  await api.cart.updateItem(item.cartId, newQty).catch(() => showToast('更新失败'))
  await openCartDrawer()
  updateCartBadge()
}

async function updateCartBadge() {
  const badge = document.getElementById('cartBadge')
  if (!badge) return
  if (!isAuthenticated()) {
    badge.style.display = 'none'
    return
  }
  const count = await api.cart.getCount().catch(() => 0)
  if (badge) {
    badge.textContent = count > 99 ? '99+' : count
    badge.style.display = count > 0 ? '' : 'none'
  }
}
