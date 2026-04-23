/* ── Shop Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'
import { createContentTab } from '../components/content-tab.js'

let shopInfo = {}
let currentTab = 'products'
let isFollowing = false

async function loadShop() {
  const info = await api.shop.getInfo()
  shopInfo = info
  renderShopHeader()
  renderProducts('products')
}

function renderShopHeader() {
  const nameEl = document.getElementById('shopName')
  const descEl = document.getElementById('shopDesc')
  const scoreEl = document.getElementById('shopScore')
  if (nameEl) nameEl.textContent = shopInfo.name
  if (descEl) descEl.textContent = shopInfo.desc
  if (scoreEl) scoreEl.textContent = shopInfo.score
}

function renderProducts(tab) {
  currentTab = tab
  const content = document.getElementById('shopContent')
  if (!content) return

  api.shop.getProducts(tab).then(products => {
    if (products.length === 0) {
      content.innerHTML = `
        <div class="shop-empty">
          <div class="shop-empty-icon">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
          </div>
          <div>暂无商品</div>
        </div>`
      return
    }

    content.innerHTML = `
      <div class="shop-product-grid">
        ${products.map(p => `
          <a href="product-detail.html" class="shop-product-card" onclick="sessionStorage.setItem('productId','${p.id}')">
            ${p.tag ? `<span class="shop-product-tag">${p.tag}</span>` : ''}
            <div class="shop-product-img"><img src="${p.img}" alt="${p.name}"></div>
            <div class="shop-product-info">
              <div class="shop-product-name">${p.name}</div>
              <div class="shop-product-bottom">
                <span class="shop-product-price">¥${p.price}</span>
                ${p.original > p.price ? `<span class="shop-product-original">¥${p.original}</span>` : ''}
                <span class="shop-product-sales">已售${p.sales}</span>
              </div>
              ${p.rating ? `
              <div class="shop-product-rating">
                ${[1,2,3,4,5].map(i => `
                  <svg width="10" height="10" viewBox="0 0 24 24" fill="${i <= Math.round(p.rating) ? '#FFB800' : 'none'}" stroke="${i <= Math.round(p.rating) ? '#FFB800' : '#CCC'}" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                `).join('')}
                <span>${p.rating.toFixed(1)}</span>
              </div>` : ''}
            </div>
          </a>
        `).join('')}
      </div>`
  })
}

createContentTab({
  id: 'shopTabs',
  tabs: [
    { value: 'products', label: '全部商品' },
    { value: 'new', label: '新品上架' },
    { value: 'hot', label: '热卖宝贝' },
  ],
  defaultTab: 'products',
  onChange: (tab) => renderProducts(tab),
})

function toggleFollow() {
  isFollowing = !isFollowing
  const btn = document.getElementById('followBtn')
  if (isFollowing) {
    btn.innerHTML = `
      <svg width="14" height="14" viewBox="0 0 24 24" fill="#FF6B4A" stroke="#FF6B4A" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
      已关注`
    showToast('关注成功')
  } else {
    btn.innerHTML = `
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.0 0 0 0 0-7.78z"/></svg>
      关注`
    showToast('已取消关注')
  }
}

document.getElementById('followBtn')?.addEventListener('click', toggleFollow)

loadShop()
