/* ── Category Page ── */
import { showToast } from '../components/toast.js'
import { api, BASE_URL, request } from '../data/api.js'

const subIcons = [
  './assets/images/icon-fashion-01.webp',
  './assets/images/icon-mens-02.webp',
  './assets/images/icon-skincare-03.webp',
  './assets/images/icon-phone-04.webp',
  './assets/images/icon-home-05.webp',
  './assets/images/icon-sport-06.webp',
  './assets/images/icon-food-07.webp',
  './assets/images/icon-beauty-08.webp',
]

let categories = []
let currentCat = 0

function renderLeftNav() {
  const left = document.getElementById('catLeft')
  left.innerHTML = categories.map((cat, i) =>
    `<div class="cat-nav-item ${i === currentCat ? 'active' : ''}" data-index="${i}">${cat.name}</div>`
  ).join('')

  left.querySelectorAll('.cat-nav-item').forEach(item => {
    item.addEventListener('click', () => {
      switchCategory(parseInt(item.dataset.index))
    })
  })
}

function renderRightContent(index) {
  const right = document.getElementById('catRight')
  const cat = categories[index]

  // subcategories 现在是对象数组，包含 name 和 products
  const subNames = cat.subcategories ? cat.subcategories.map(s => s.name) : []
  // 获取所有子分类的产品
  const allProducts = cat.subcategories ? cat.subcategories.flatMap(s => s.products || []) : []

  right.innerHTML = `
    <div class="cat-banner">
      <img src="${cat.banner}" alt="${cat.name}">
    </div>
    <div class="cat-sub-title">${cat.name}分类</div>
    <div class="cat-sub-grid">
      ${subNames.map((sub) => `
        <div class="cat-sub-item" onclick="location.href='search.html?keyword=${encodeURIComponent(sub)}'">
          <div class="cat-sub-icon-wrap">
            <img src="${subIcons[index] || subIcons[0]}" class="cat-sub-icon" alt="${sub}">
          </div>
          <span class="cat-sub-name">${sub}</span>
        </div>
      `).join('')}
    </div>
    ${allProducts.length > 0 ? `
      <div class="cat-sub-title">热门商品</div>
      <div class="cat-product-list" id="catProductList"></div>
    ` : '<div class="cat-empty">该分类暂无商品</div>'}
  `

  if (allProducts.length === 0) return

  const list = document.getElementById('catProductList')
  list.innerHTML = allProducts.map(p => `
    <div class="cat-product-row" data-id="${p.id}">
      <div class="cat-product-img"><img src="${p.image}" alt="${p.name}"></div>
      <div class="cat-product-info">
        <div class="cat-product-name">${p.name}</div>
        <div class="cat-product-bottom">
          <span class="cat-product-price">¥${p.price}</span>
          ${Number(p.original_price) > Number(p.price) ? `<span class="cat-product-original">¥${p.original_price}</span>` : ''}
          <span class="cat-product-sales">已售 ${p.sales_count}</span>
        </div>
        <div class="cat-product-rating">
          ${[1,2,3,4,5].map(i => `
            <svg width="10" height="10" viewBox="0 0 24 24" fill="${i <= Math.round(p.rating || 0) ? '#FFB800' : 'none'}" stroke="${i <= Math.round(p.rating || 0) ? '#FFB800' : '#CCC'}" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          `).join('')}
          <span>${Number(p.rating || 0).toFixed(1)}</span>
        </div>
        <div class="cat-product-cart" data-index="${allProducts.indexOf(p)}">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        </div>
      </div>
    </div>
  `).join('')

  list.querySelectorAll('.cat-product-row').forEach(row => {
    row.addEventListener('click', () => {
      const id = row.dataset.id
      if (id) {
        sessionStorage.setItem('productId', id)
        location.href = 'product-detail.html'
      }
    })
  })

  list.querySelectorAll('.cat-product-cart').forEach((btn, i) => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation()
      addToCart(allProducts[i])
    })
  })
}

function switchCategory(index) {
  currentCat = index
  document.querySelectorAll('.cat-nav-item').forEach((item, i) => {
    item.classList.toggle('active', i === index)
  })
  renderRightContent(index)
}

function addToCart(product) {
  if (!product) return
  try {
    let cart = JSON.parse(localStorage.getItem('cart') || '[]')
    const existing = cart.find(c => c.id === product.id)
    if (existing) {
      existing.qty += 1
    } else {
      cart.push({ id: product.id, name: product.name, price: product.price, img: product.image, qty: 1, selected: true })
    }
    localStorage.setItem('cart', JSON.stringify(cart))
    updateTabCartBadge()
    showToast('已加入购物车')
  } catch (e) {
    console.error('Failed to add to cart:', e)
  }
}

function updateTabCartBadge() {
  try {
    const cart = JSON.parse(localStorage.getItem('cart') || '[]')
    const badge = document.getElementById('tabCartBadge')
    if (!badge) return
    const total = cart.reduce((s, item) => s + item.qty, 0)
    badge.textContent = total > 99 ? '99+' : total
    badge.style.display = total > 0 ? 'flex' : 'none'
  } catch (e) {
    console.error('Failed to update cart badge:', e)
  }
}

// Load categories from API - get full category detail with subcategories with products
api.category.getList().then(cs => {
  // For each category, fetch full details including subcategories with products
  // Use request() to properly unwrap {code: 0, data: ...} response from Django
  return Promise.all(cs.map(c => request('/api/h5/categories/' + c.id + '/').then(data => ({
    ...c,
    subcategories: data.subcategories || []
  }))))
}).then(categoriesWithProducts => {
  categories = categoriesWithProducts
  // Remove skeleton loading
  document.getElementById('catLeft').classList.add('loaded')
  document.getElementById('catRight').classList.add('loaded')
  renderLeftNav()
  renderRightContent(0)
}).catch(err => {
  console.error('Failed to load categories:', err)
  // Hide skeleton on error too
  document.getElementById('catLeft').classList.add('loaded')
  document.getElementById('catRight').classList.add('loaded')
})

updateTabCartBadge()
