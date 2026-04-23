/* ── Product Detail Page ── */
import { showToast } from '../components/toast.js'
import { api, BASE_URL } from '../data/api.js'

let productData = {}
let relatedProducts = []
let productReviews = []
let cart = JSON.parse(localStorage.getItem('cart') || '[]')
let qty = 1
let isFav = false
// selectedSpecValues: Map<groupId, selectedSpecValueId>
let selectedSpecValues = new Map()
// availabilityCache: Map<groupId, Set<availableSpecValueId>>
let availabilityCache = new Map()
let swiperCurrent = 0

async function init() {
  const id = sessionStorage.getItem('productId')
  sessionStorage.removeItem('productId')

  if (!id) {
    return
  }

  let detail = null, related = [], reviews = []
  try {
    ;[detail, related, reviews] = await Promise.all([
      api.product.getDetail(id),
      api.product.getRelated(id),
      api.product.getReviews(id),
    ])
  } catch(e) {
    console.error('Failed to load product:', e)
  }

  if (!detail) {
    return
  }

  productData = detail
  relatedProducts = related || []
  productReviews = reviews || []

  loadProduct()
  renderSwiper()
  renderSpecSheet()
  renderReviews()
  renderRelated()
  updateCartBadge()
  bindEvents()
  initSwiperNav()
  // Fetch availability with empty selection first to get all available options
  fetchAvailability()
}

function loadProduct() {
  document.getElementById('priceCurrent').textContent = `¥${productData.price}`
  document.getElementById('priceOriginal').textContent = productData.original ? `¥${productData.original}` : ''
  document.getElementById('productTitle').textContent = productData.name || ''
  document.getElementById('productDesc').textContent = productData.desc || ''
  updateSelectedSpecText()
}

function renderSwiper() {
  const track = document.getElementById('swiperTrack')
  const dots = document.getElementById('swiperDots')
  const counter = document.getElementById('swiperCounter')
  const images = productData.images || (productData.img ? [productData.img] : [])

  track.innerHTML = images.map(img =>
    `<div class="swiper-slide"><img src="${img}" alt="" draggable="false"></div>`
  ).join('')

  dots.innerHTML = images.map((_, i) =>
    `<span class="swiper-dot ${i === 0 ? 'active' : ''}" data-index="${i}"></span>`
  ).join('')

  counter.textContent = `1/${images.length}`
}

// Dynamically render the spec sheet based on product's specGroups
function renderSpecSheet() {
  const container = document.getElementById('specSheetBodyGroups')
  if (!container || !productData.specGroups) return

  container.innerHTML = productData.specGroups.map(group => `
    <div class="spec-group" data-group-id="${group.id}">
      <div class="spec-group-title">${group.name}</div>
      <div class="spec-options">
        ${group.values.map(sv => `
          <div class="spec-option"
               data-value-id="${sv.id}"
               data-value="${sv.value}"
               ${sv.imageName ? `data-image="${sv.imageName.replace('./static/images/', './assets/images/')}"` : ''}>
            ${sv.value}
          </div>
        `).join('')}
      </div>
    </div>
  `).join('')

  bindSpecOptionEvents()
  updateSpecOptionStates()
}

function bindSpecOptionEvents() {
  document.querySelectorAll('#specSheetBodyGroups .spec-option').forEach(opt => {
    opt.addEventListener('click', () => {
      const groupEl = opt.closest('.spec-group')
      const groupId = groupEl.dataset.groupId
      const valueId = opt.dataset.valueId
      const value = opt.dataset.value

      // Toggle selection - if already selected, deselect
      if (selectedSpecValues.get(groupId) === valueId) {
        selectedSpecValues.delete(groupId)
      } else {
        selectedSpecValues.set(groupId, valueId)
      }
      updateSpecOptionStates()
      updateSelectedSpecText()
      updateSheetPriceAndStock()
      fetchAvailability()

      // Update main image if this spec has an image
      if (opt.dataset.image) {
        document.getElementById('sheetImg').src = opt.dataset.image
      }
    })
  })
}

// Update visual state of all spec options based on availability
function updateSpecOptionStates() {
  if (!productData.specGroups) return

  productData.specGroups.forEach(group => {
    const groupEl = document.querySelector(`.spec-group[data-group-id="${group.id}"]`)
    if (!groupEl) return
    const available = availabilityCache.get(group.id) || new Set(group.values.map(v => v.id))

    groupEl.querySelectorAll('.spec-option').forEach(opt => {
      const valueId = opt.dataset.valueId
      const isSelected = selectedSpecValues.get(group.id) === valueId
      const isAvailable = available.has(valueId)

      opt.classList.toggle('selected', isSelected)
      opt.classList.toggle('disabled', !isAvailable && !isSelected)
    })
  })
}

function updateSelectedSpecText() {
  if (!productData.specGroups) return

  const parts = []
  productData.specGroups.forEach(group => {
    const selectedId = selectedSpecValues.get(group.id)
    const sv = group.values.find(v => v.id === selectedId)
    if (sv) parts.push(sv.value)
  })

  const text = parts.join(' / ')
  document.getElementById('selectedSpecText').innerHTML = `${text} <span class="arrow">></span>`
  document.getElementById('sheetSelected').textContent = `已选：${text}`
}

function updateSheetPriceAndStock() {
  const selectedSKU = findSelectedSKU()
  if (selectedSKU) {
    document.getElementById('sheetPrice').textContent = `¥${selectedSKU.price}`
    const stockText = selectedSKU.stock > 0 ? `库存 ${selectedSKU.stock} 件` : '暂无库存'
    document.querySelector('.spec-sheet-stock').textContent = stockText
  } else {
    document.getElementById('sheetPrice').textContent = `¥${productData.price}`
    document.querySelector('.spec-sheet-stock').textContent = '请选择规格'
  }
}

// Find the SKU that matches current selections
function findSelectedSKU() {
  if (!productData.skus || productData.skus.length === 0) return null
  const selectedIds = Array.from(selectedSpecValues.values())

  return productData.skus.find(sku => {
    if (sku.specValueIds.length !== selectedIds.length) return false
    return selectedIds.every(id => sku.specValueIds.includes(id))
  })
}

function getBaseUrl() {
  return BASE_URL
}

// Fetch availability from the spec-available API
async function fetchAvailability() {
  if (!productData.specGroups) return
  const selectedIds = Array.from(selectedSpecValues.values()).filter(Boolean)
  const selectedStr = selectedIds.join(',')

  try {
    const res = await fetch(`${getBaseUrl()}/api/h5/products/${productData.id}/spec-available/?selected=${selectedStr}`)
    const json = await res.json()
    if (json.code !== 0) return

    availabilityCache.clear()
    ;(json.data || []).forEach(item => {
      availabilityCache.set(item.groupId, new Set(item.availableValues))
    })

    updateSpecOptionStates()
  } catch (e) {
    // On error, show all as available
    productData.specGroups.forEach(g => {
      availabilityCache.set(g.id, new Set(g.values.map(v => v.id)))
    })
    updateSpecOptionStates()
  }
}

function renderReviews() {
  const reviewsContainer = document.getElementById('reviewsList')
  if (!reviewsContainer) return

  if (productReviews.length === 0) {
    reviewsContainer.innerHTML = `<div class="reviews-empty">暂无评价</div>`
    return
  }

  const showReviews = productReviews.slice(0, 2)
  reviewsContainer.innerHTML = showReviews.map(r => `
    <div class="review-item">
      <div class="review-user">
        <div class="review-avatar" style="background: hsl(${(r.userName.charCodeAt(0) || 0) * 10}, 60%, 80%)">${r.userName.charAt(0)}</div>
        <span class="review-user-name">${r.userName}</span>
        <div class="review-stars">
          ${[1,2,3,4,5].map(i => `
            <svg width="12" height="12" viewBox="0 0 24 24" fill="${i <= r.rating ? '#FFB800' : 'none'}" stroke="${i <= r.rating ? '#FFB800' : '#CCC'}" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          `).join('')}
        </div>
      </div>
      <p class="review-text">${r.content}</p>
      ${r.spec ? `<p class="review-spec">购买规格：${r.spec}</p>` : ''}
      ${r.images && r.images.length > 0 ? `<div class="review-images">${r.images.map(img => `<img src="${img}" alt="">`).join('')}</div>` : ''}
    </div>
  `).join('')

  const reviewCountEl = document.getElementById('reviewCount')
  if (reviewCountEl && productData.rating) {
    reviewCountEl.textContent = productData.rating.toFixed(1)
  }
}

function initSwiperNav() {
  const track = document.getElementById('swiperTrack')
  const dots = document.querySelectorAll('.swiper-dot')
  const counter = document.getElementById('swiperCounter')
  const images = productData.images || []
  const len = images.length
  if (len === 0) return

  let startX = 0, currentX = 0, isDragging = false

  function goTo(index) {
    swiperCurrent = ((index % len) + len) % len
    track.style.transform = `translateX(-${swiperCurrent * 100}%)`
    dots.forEach((d, i) => d.classList.toggle('active', i === swiperCurrent))
    counter.textContent = `${swiperCurrent + 1}/${len}`
  }

  track.addEventListener('touchstart', (e) => { startX = e.touches[0].clientX; isDragging = true }, { passive: true })
  track.addEventListener('touchmove', (e) => { if (!isDragging) return; currentX = e.touches[0].clientX }, { passive: true })
  track.addEventListener('touchend', () => {
    if (!isDragging) return
    isDragging = false
    const delta = currentX - startX
    if (Math.abs(delta) > 50) goTo(swiperCurrent + (delta < 0 ? 1 : -1))
  }, { passive: true })
  dots.forEach(dot => dot.addEventListener('click', () => goTo(Number(dot.dataset.index))))
}

function renderRelated() {
  const track = document.getElementById('relatedTrack')
  if (!track) return
  track.innerHTML = relatedProducts.map(p => `
    <a href="product-detail.html" class="related-card" onclick="sessionStorage.setItem('productId','${p.id}')">
      ${p.tag ? `<span class="related-tag">${p.tag}</span>` : ''}
      <div class="related-img"><img src="${p.img}" alt="${p.name}"></div>
      <div class="related-info">
        <div class="related-name">${p.name}</div>
        <div class="related-bottom">
          <div class="related-price">¥${p.price}</div>
          ${p.original > p.price ? `<div class="related-original">¥${p.original}</div>` : ''}
        </div>
        <div class="related-sales">已售 ${p.sales}</div>
      </div>
    </a>
  `).join('')
}

function updateCartBadge() {
  const total = cart.reduce((s, item) => s + item.qty, 0)
  const badge = document.getElementById('cartBadge')
  if (badge) {
    badge.textContent = total > 99 ? '99+' : total
    badge.style.display = total > 0 ? 'flex' : 'none'
  }
}

async function addToCart() {
  const selectedSKU = findSelectedSKU()
  const skuId = selectedSKU ? selectedSKU.id : null

  const existing = cart.findIndex(c => c.id === productData.id && c.skuId === skuId)
  if (existing >= 0) {
    cart[existing].qty += qty
  } else {
    cart.push({
      id: productData.id, name: productData.name,
      price: selectedSKU ? selectedSKU.price : productData.price,
      original: selectedSKU ? (selectedSKU.originalPrice || selectedSKU.price) : productData.original,
      img: productData.images?.[0], qty: qty, selected: true,
      skuId: skuId,
      specValues: Array.from(selectedSpecValues.entries()).map(([groupId, valueId]) => {
        const group = productData.specGroups.find(g => g.id === groupId)
        const sv = group ? group.values.find(v => v.id === valueId) : null
        return { group: group ? group.name : '', value: sv ? sv.value : '' }
      }),
    })
  }
  localStorage.setItem('cart', JSON.stringify(cart))

  try {
    await api.cart.addItem({ id: productData.id, qty: qty })
  } catch (e) {
    console.error('Failed to sync cart to server:', e)
  }

  updateCartBadge()
  showToast(`已加入购物车 ×${qty}`)
}

function buyNow() {
  addToCart()
  setTimeout(() => { window.location.href = 'cart.html' }, 500)
}

async function toggleFav() {
  isFav = !isFav
  if (isFav) {
    await api.favorite.add(productData.id)
    showToast('已收藏')
  } else {
    showToast('已取消收藏')
  }
  const btn = document.getElementById('favBtn')
  const svg = btn.querySelector('svg')
  if (isFav) {
    svg.setAttribute('fill', '#FF6B4A')
    svg.setAttribute('stroke', '#FF6B4A')
    btn.classList.add('active')
  } else {
    svg.setAttribute('fill', 'none')
    svg.setAttribute('stroke', 'currentColor')
    btn.classList.remove('active')
  }
}

function openSpecSheet(mode) {
  const sheet = document.getElementById('specSheet')
  sheet.classList.add('open')
  document.body.style.overflow = 'hidden'
  sheet.dataset.mode = mode
  updateSheetPriceAndStock()
}

function closeSpecSheet() {
  const sheet = document.getElementById('specSheet')
  sheet.classList.remove('open')
  document.body.style.overflow = ''
}

function initStickyNav() {
  const nav = document.getElementById('detailNav')
  window.addEventListener('scroll', () => {
    nav.classList.toggle('show', window.scrollY > 280)
  }, { passive: true })
}

function bindEvents() {
  initStickyNav()

  document.getElementById('backBtn')?.addEventListener('click', () => history.back())
  document.getElementById('navBack')?.addEventListener('click', () => history.back())
  document.getElementById('shareBtn')?.addEventListener('click', () => showToast('分享功能'))
  document.getElementById('navShare')?.addEventListener('click', () => showToast('分享功能'))
  document.getElementById('navMore')?.addEventListener('click', () => showToast('更多选项'))
  document.getElementById('specSelect')?.addEventListener('click', () => openSpecSheet('add'))
  document.getElementById('serviceSelect')?.addEventListener('click', () => showToast('服务：极速退款 · 7天无理由 · 运费险'))
  document.getElementById('shopBtn')?.addEventListener('click', () => showToast('进入店铺'))
  document.getElementById('favBtn')?.addEventListener('click', toggleFav)
  document.getElementById('cartBtn')?.addEventListener('click', () => window.location.href = 'cart.html')
  document.getElementById('addCartBtn')?.addEventListener('click', () => openSpecSheet('add'))
  document.getElementById('buyBtn')?.addEventListener('click', () => openSpecSheet('buy'))
  document.getElementById('specBackdrop')?.addEventListener('click', closeSpecSheet)

  document.getElementById('qtyMinus')?.addEventListener('click', () => {
    if (qty > 1) { qty--; document.getElementById('qtyNum').textContent = qty }
  })
  document.getElementById('qtyPlus')?.addEventListener('click', () => {
    if (qty < 99) { qty++; document.getElementById('qtyNum').textContent = qty }
  })

  document.getElementById('sheetCartBtn')?.addEventListener('click', () => {
    const selectedSKU = findSelectedSKU()
    if (!selectedSKU) { showToast('请选择完整规格'); return }
    addToCart()
    closeSpecSheet()
  })
  document.getElementById('sheetBuyBtn')?.addEventListener('click', () => {
    const selectedSKU = findSelectedSKU()
    if (!selectedSKU) { showToast('请选择完整规格'); return }
    addToCart()
    closeSpecSheet()
    setTimeout(() => { window.location.href = 'cart.html' }, 400)
  })
}

init().catch(e => { console.error('Failed to load product:', e) })
