/* ── Cart Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

let cart = []
let recommendProducts = []
let isEditMode = false
let cartLoaded = false

async function loadCartFromServer() {
  try {
    cart = await api.cart.getList()
    cartLoaded = true
  } catch (e) {
    console.error('Failed to load cart from server:', e)
    cart = []
    cartLoaded = true
  }
}

async function loadRecommend() {
  try {
    const recs = await api.home.getRecommend()
    console.log('[Cart] getRecommend returned:', recs)
    const allProducts = []
    recs.forEach(rec => {
      if (rec.products && rec.products.length > 0) {
        allProducts.push(...rec.products)
      }
    })
    console.log('[Cart] allProducts:', allProducts)
    recommendProducts = allProducts.slice(0, 6)
    console.log('[Cart] recommendProducts:', recommendProducts)
    renderRecommend()
  } catch (e) {
    console.error('Failed to load recommend:', e)
  }
}

function renderRecommend() {
  console.log('[Cart] renderRecommend called, recommendProducts:', recommendProducts)
  if (recommendProducts.length === 0) {
    console.log('[Cart] recommendProducts is empty, skipping render')
    return
  }

  const recSection = document.getElementById('recommendSection')
  console.log('[Cart] recSection element:', recSection)
  if (!recSection) return

  recSection.innerHTML = `
    <div class="recommend-header">
      <span class="recommend-title">为你推荐</span>
    </div>
    <div class="recommend-grid">
      ${recommendProducts.map(p => `
        <div class="recommend-card" data-id="${p.id}">
          <div class="recommend-img-wrap">
            <img src="${p.img}" alt="${p.name}" class="recommend-img">
          </div>
          <div class="recommend-info">
            <div class="recommend-name">${p.name}</div>
            <div class="recommend-bottom">
              <span class="recommend-price">¥${p.price}</span>
            </div>
          </div>
        </div>
      `).join('')}
    </div>
  `
  console.log('[Cart] recSection innerHTML updated')
}

function renderCart() {
  const content = document.getElementById('cartContent')

  if (cart.length === 0) {
    content.innerHTML = `
      <div class="cart-empty">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
        <div class="empty-title">购物车是空的</div>
        <div class="empty-sub">快去挑选心仪的商品吧</div>
        <button class="empty-btn" onclick="window.location.href='index.html'">去逛逛</button>
      </div>`
    document.getElementById('cartBar').style.display = 'none'
    document.getElementById('editBar').style.display = 'none'
    return
  }

  document.getElementById('cartBar').style.display = isEditMode ? 'none' : 'flex'
  document.getElementById('editBar').style.display = isEditMode ? 'flex' : 'none'

  content.innerHTML = `
    <div class="cart-store">
      <div class="cart-store-header">
        <div class="store-check" id="storeCheck"></div>
        <div class="store-logo">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
        </div>
        <span class="store-name">潮流优品官方旗舰店</span>
        <span class="store-tag">领券</span>
      </div>
      <div class="cart-items">
        ${cart.map((item, index) => `
          <div class="cart-product-wrap" data-index="${index}">
            <div class="product-delete-action" data-action="swipe-delete">删除</div>
            <div class="cart-product">
              <div class="product-check ${item.selected ? 'checked' : ''}" data-action="check"></div>
              <div class="cart-item-img">
                <img src="${item.img}" alt="${item.name}">
              </div>
              <div class="product-info">
                <div>
                  <div class="product-name">${item.name}</div>
                  ${item.color || item.size ? `<div class="product-spec">${[item.color, item.size].filter(Boolean).join(' / ')}</div>` : ''}
                </div>
                <div class="product-bottom">
                  <span class="product-price">¥${item.price}</span>
                  <div style="display:flex;align-items:center">
                    <div class="product-qty">
                      <div class="qty-btn" data-action="dec">−</div>
                      <div class="qty-num">${item.qty}</div>
                      <div class="qty-btn" data-action="inc">+</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        `).join('')}
      </div>
    </div>`

  bindCartEvents()
  updateTotals()
}

function bindCartEvents() {
  // ── Swipe to reveal delete ──
  document.querySelectorAll('.cart-product-wrap').forEach(el => {
    let startX = 0
    let currentX = 0
    let dragging = false
    const productEl = el.querySelector('.cart-product')

    el.addEventListener('touchstart', (e) => {
      startX = e.touches[0].clientX
      dragging = true
      productEl.classList.remove('swiped')
    }, { passive: true })

    el.addEventListener('touchmove', (e) => {
      if (!dragging) return
      currentX = e.touches[0].clientX
      const diff = startX - currentX
      if (diff > 0) {
        const offset = Math.min(diff, 80)
        productEl.style.transform = `translateX(-${offset}px)`
      }
    }, { passive: true })

    el.addEventListener('touchend', () => {
      if (!dragging) return
      dragging = false
      const diff = startX - currentX
      if (diff > 40) {
        productEl.classList.add('swiped')
        productEl.style.transform = 'translateX(-80px)'
      } else {
        productEl.classList.remove('swiped')
        productEl.style.transform = ''
      }
    })

    // Tap on delete button
    el.querySelector('[data-action="swipe-delete"]')?.addEventListener('click', async () => {
      const idx = parseInt(el.closest('.cart-product-wrap').dataset.index)
      const item = cart[idx]
      if (!item) return
      // Delete from server
      if (item.cartId && !item.cartId.startsWith('local_')) {
        await api.cart.removeItem(item.cartId)
      } else if (item.id && !item.id.startsWith('local_')) {
        await api.cart.removeItem(item.id)
      }
      await loadCartFromServer()
      renderCart()
      showToast('已删除')
      updateTabBadge()
    })
  })

  // Close swiped item when tapping elsewhere
  document.addEventListener('touchstart', (e) => {
    if (!e.target.closest('.cart-product-wrap')) {
      document.querySelectorAll('.cart-product.swiped').forEach(el => {
        el.classList.remove('swiped')
        el.style.transform = ''
      })
    }
  }, { passive: true })

  document.getElementById('storeCheck')?.addEventListener('click', async () => {
    const allSelected = cart.every(i => i.selected)
    cart.forEach(i => i.selected = !allSelected)
    // Sync to server
    for (const item of cart) {
      if (item.id && !item.id.startsWith('local_')) {
        await api.cart.toggleItem(item.id)
      }
    }
    await loadCartFromServer()
    renderCart()
  })

  const allSelected = cart.every(i => i.selected)
  const storeCheck = document.getElementById('storeCheck')
  if (storeCheck) storeCheck.classList.toggle('checked', allSelected)

  document.querySelectorAll('.product-check').forEach(el => {
    el.addEventListener('click', async () => {
      const idx = parseInt(el.closest('.cart-product-wrap').dataset.index)
      if (!cart[idx]) return
      cart[idx].selected = !cart[idx].selected
      // Sync to server
      if (cart[idx].id && !cart[idx].id.startsWith('local_')) {
        await api.cart.toggleItem(cart[idx].id)
      }
      await loadCartFromServer()
      renderCart()
    })
  })

  document.querySelectorAll('.qty-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const idx = parseInt(btn.closest('.cart-product-wrap').dataset.index)
      if (!cart[idx]) return
      let newQty = cart[idx].qty
      if (btn.dataset.action === 'inc') {
        newQty = Math.min(cart[idx].qty + 1, 99)
      } else if (btn.dataset.action === 'dec' && cart[idx].qty > 1) {
        newQty = cart[idx].qty - 1
      }
      // Update quantity on server
      if (cart[idx].cartId && !cart[idx].cartId.startsWith('local_')) {
        await api.cart.updateItem(cart[idx].cartId, newQty)
      } else if (cart[idx].id && !cart[idx].id.startsWith('local_')) {
        await api.cart.updateItem(cart[idx].id, newQty)
      }
      await loadCartFromServer()
      renderCart()
    })
  })

  }

function setupSelectAll() {
  ['selectAll', 'selectAllEdit'].forEach(id => {
    document.getElementById(id)?.addEventListener('click', async () => {
      const allSelected = cart.every(i => i.selected)
      cart.forEach(i => i.selected = !allSelected)
      // Sync to server
      for (const item of cart) {
        if (item.id && !item.id.startsWith('local_')) {
          await api.cart.toggleItem(item.id)
        }
      }
      await loadCartFromServer()
      renderCart()
    })
  })
}

function updateTotals() {
  const selected = cart.filter(i => i.selected)
  const total = selected.reduce((s, i) => s + i.price * i.qty, 0)
  const count = selected.reduce((s, i) => s + i.qty, 0)

  document.getElementById('totalPrice').textContent = `¥${total}`
  document.getElementById('checkoutCount').textContent = count

  const allSelected = cart.length > 0 && cart.every(i => i.selected)
  ;['selectAllCheck', 'selectAllCheckEdit'].forEach(id => {
    document.getElementById(id)?.classList.toggle('checked', allSelected)
  })

  const storeCheck = document.getElementById('storeCheck')
  if (storeCheck) storeCheck.classList.toggle('checked', allSelected)

  const checkoutBtn = document.getElementById('checkoutBtn')
  if (checkoutBtn) checkoutBtn.disabled = count === 0
}

function toggleEdit() {
  isEditMode = !isEditMode
  document.getElementById('editBtn').textContent = isEditMode ? '完成' : '编辑'
  renderCart()
}

async function deleteSelected() {
  const selected = cart.filter(i => i.selected)
  if (selected.length === 0) { showToast('请先选择商品'); return }

  // Delete selected items from server
  for (const item of selected) {
    if (item.cartId && !item.cartId.startsWith('local_')) {
      await api.cart.removeItem(item.cartId)
    } else if (item.id && !item.id.startsWith('local_')) {
      await api.cart.removeItem(item.id)
    }
  }

  await loadCartFromServer()
  renderCart()
  updateTabBadge()
  showToast(`已删除 ${selected.length} 件商品`)
}

function checkout() {
  const selected = cart.filter(i => i.selected)
  if (selected.length === 0) { showToast('请先选择商品'); return }
  window.location.href = 'checkout.html'
}

function updateTabBadge() {
  const total = cart.reduce((s, i) => s + i.qty, 0)
  const badge = document.getElementById('tabCartBadge')
  if (!badge) return
  badge.textContent = total > 99 ? '99+' : total
  badge.style.display = total > 0 ? 'flex' : 'none'
}

document.getElementById('editBtn').addEventListener('click', toggleEdit)
document.getElementById('deleteBtn').addEventListener('click', deleteSelected)
document.getElementById('checkoutBtn').addEventListener('click', checkout)
setupSelectAll()

// Recommend cards click delegation
document.addEventListener('click', (e) => {
  const card = e.target.closest('.recommend-card')
  if (!card) return
  const id = card.dataset.id
  if (!id) return
  sessionStorage.setItem('productId', id)
  window.location.href = 'product-detail.html'
})

// Initialize cart from server
async function init() {
  await loadCartFromServer()
  document.getElementById('cartSkeleton')?.classList.add('loaded')
  renderCart()
  updateTabBadge()
  loadRecommend()
}
init()
