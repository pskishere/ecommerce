/* ── Product Sheet Component ── */
import { api } from '../data/api.js'
import { showToast } from './toast.js'
import { openCartDrawer } from './cartDrawer.js'

export function initProductSheet() {
  const sheet = document.getElementById('productSheet')
  const backdrop = document.getElementById('sheetBackdrop')
  const qtyNum = document.getElementById('qtyNum')
  const qtyMinus = document.getElementById('qtyMinus')
  const qtyPlus = document.getElementById('qtyPlus')
  const sheetFavBtn = document.getElementById('sheetFavBtn')
  const sheetCartBtn = document.getElementById('sheetCartBtn')
  const sheetBuyBtn = document.getElementById('sheetBuyBtn')

  let currentProduct = null
  let qty = 1

  // Clickable cards → go to detail page
  // Only handle cards with data-product (hardcoded HTML cards)
  // Dynamic cards (data-id) are handled by main.js global delegation
  document.addEventListener('click', (e) => {
    const card = e.target.closest('.product-card, .flash-card, .hot-item')
    if (!card || e.target.closest('.product-fav, button')) return
    if (!card.dataset.product) return  // Skip dynamic cards, let main.js handle them
    const productId = card.dataset.id || 1
    window.location.href = `product-detail.html?id=${productId}`
  })

  function closeSheet() {
    sheet?.classList.remove('open')
    document.body.style.overflow = ''
  }

  backdrop?.addEventListener('click', closeSheet)

  qtyMinus?.addEventListener('click', () => {
    if (qty > 1) { qty--; if (qtyNum) qtyNum.textContent = qty }
  })

  qtyPlus?.addEventListener('click', () => {
    if (qty < 99) { qty++; if (qtyNum) qtyNum.textContent = qty }
  })

  sheetFavBtn?.addEventListener('click', () => {
    if (!currentProduct) return
    const isFaved = sheetFavBtn.classList.toggle('faved')
    const svg = sheetFavBtn.querySelector('svg')
    if (isFaved) {
      svg.setAttribute('fill', 'currentColor')
      api.favorite.add(currentProduct)
      showToast('已添加到收藏')
    } else {
      svg.setAttribute('fill', 'none')
      api.favorite.remove(currentProduct.id)
      showToast('已取消收藏')
    }
  })

  sheetCartBtn?.addEventListener('click', () => {
    if (!currentProduct) return
    api.cart.addItem({ ...currentProduct, qty })
    closeSheet()
    showToast(`已加入购物车 ×${qty}`)
  })

  sheetBuyBtn?.addEventListener('click', () => {
    if (!currentProduct) return
    api.cart.addItem({ ...currentProduct, qty })
    closeSheet()
    setTimeout(() => { openCartDrawer() }, 300)
  })
}

export async function getDesc(name) {
  return await api.product.getDesc(name)
}
