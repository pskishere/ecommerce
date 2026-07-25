/* ── Main Entry ── */
import { api } from './data/api.js'
import { initCarousel } from './components/carousel.js'
import { initSearch } from './components/search.js'
import { initProductSheet } from './components/productSheet.js'
import { initCartDrawer } from './components/cartDrawer.js'
import { showToast } from './components/toast.js'

let flashSaleEndTime = null
const _favMap = new Map() // productId → favoriteId (populated on add, used for remove)

// ── 1. Scroll Reveal ──
function initScrollReveal() {
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  if (prefersReducedMotion) {
    document.querySelectorAll('[data-reveal]').forEach(el => el.classList.add('revealed'))
    return
  }
  const revealAll = () => {
    document.querySelectorAll('[data-reveal]:not(.revealed)').forEach(el => {
      if (el.getBoundingClientRect().top < window.innerHeight - 60) el.classList.add('revealed')
    })
  }
  document.querySelectorAll('.category-grid, .hot-grid, .recommend-grid').forEach((grid, i) => {
    grid.querySelectorAll('[data-reveal]').forEach((item, j) => { item.style.transitionDelay = `${j * 60}ms` })
  })
  window.addEventListener('scroll', revealAll, { passive: true })
  revealAll()
}

// ── 2. Flash Sale Countdown ──
function initCountdown() {
  const el = document.getElementById('countdownNums')
  if (!el) return

  function computeRemaining() {
    if (flashSaleEndTime) return Math.max(0, Math.floor((flashSaleEndTime.getTime() - Date.now()) / 1000))
    return 0
  }

  let totalSeconds = computeRemaining()

  function update() {
    if (totalSeconds <= 0) { el.textContent = '已结束'; return }
    const h = Math.floor(totalSeconds / 3600)
    const m = Math.floor((totalSeconds % 3600) / 60)
    const s = totalSeconds % 60
    el.textContent = `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`
    totalSeconds--
  }
  update()
  setInterval(update, 1000)
}

// ── 3. Recommend Tabs ──
function initRecommendTabs() {
  const tabs = document.getElementById('recommendTabs')
  if (!tabs) return
  tabs.addEventListener('click', (e) => {
    const btn = e.target.closest('.tab-btn')
    if (!btn) return
    tabs.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'))
    btn.classList.add('active')
    const grid = document.getElementById('recommendGrid')
    if (grid) {
      grid.style.opacity = '0'
      grid.style.transform = 'translateY(10px)'
      setTimeout(() => {
        grid.style.transition = 'opacity 0.3s, transform 0.3s'
        grid.style.opacity = '1'
        grid.style.transform = 'translateY(0)'
      }, 150)
    }
  })
}

// ── 4. Favorites ──
function initFavorites() {
  document.addEventListener('click', (e) => {
    const favBtn = e.target.closest('.product-fav')
    if (!favBtn) return
    e.preventDefault()
    e.stopPropagation()
    const card = favBtn.closest('.product-card, .flash-card, .hot-item')
    const productId = card?.dataset.id
    if (!productId) return

    const svg = favBtn.querySelector('svg')
    const isFilled = svg.getAttribute('fill') !== 'none'
    if (isFilled) {
      svg.setAttribute('fill', 'none')
      showToast('已取消收藏')
      const favId = _favMap.get(productId)
      if (favId) {
        api.favorite.remove(favId).catch(() => {})
        _favMap.delete(productId)
      }
    } else {
      svg.setAttribute('fill', 'currentColor')
      showToast('已添加到收藏')
      api.favorite.add(productId)
        .then(res => { if (res && res.id) _favMap.set(productId, res.id) })
        .catch(() => {})
    }
    favBtn.style.transform = 'scale(1.3)'
    setTimeout(() => { favBtn.style.transform = '' }, 150)
  })
}

// ── 5. Browse History Tracking (now handled by global delegation above) ──
function initBrowseHistory() {
  // Moved to top-level document listener for immediate binding
}

// ── 6. Load More ──
function initLoadMore() {
  const btn = document.getElementById('loadMoreBtn')
  if (!btn) return
  btn.addEventListener('click', async () => {
    btn.textContent = '加载中...'
    btn.disabled = true
    const grid = document.getElementById('recommendGrid')
    if (!grid) return
    const recs = await api.product.getRecommend()
    recs.forEach((p, i) => {
      const card = document.createElement('div')
      card.className = 'product-card'
      card.dataset.id = p.id
      card.dataset.name = p.name
      card.dataset.price = p.price
      card.dataset.img = p.img.replace('/assets/images/', '')
      card.innerHTML = `
        <div class="product-img-wrap">
          <img src="${p.img}" alt="${p.name}" class="product-img">
          <button class="product-fav" aria-label="收藏">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.0 0 0 0 0-7.78z"/>
            </svg>
          </button>
        </div>
        <div class="product-info">
          <span class="product-name">${p.name}</span>
          <div class="product-bottom">
            <span class="product-price">¥${p.price}</span>
          </div>
        </div>`
      grid.appendChild(card)
      setTimeout(() => { card.classList.add('revealed') }, i * 100 + 100)
    })
    btn.textContent = '没有更多了'
    btn.style.opacity = '0.5'
    btn.style.pointerEvents = 'none'
    showToast('已加载全部商品')
  })
}

// ── 7. Navbar Hide on Scroll ──
function initNavScroll() {
  const nav = document.getElementById('topNav')
  if (!nav) return
  let lastScroll = 0, ticking = false
  window.addEventListener('scroll', () => {
    if (!ticking) {
      window.requestAnimationFrame(() => {
        const currentScroll = window.scrollY
        nav.style.transform = currentScroll > 80 && currentScroll > lastScroll ? 'translateY(-100%)' : 'translateY(0)'
        nav.style.transition = 'transform 0.3s var(--easing-smooth)'
        lastScroll = currentScroll
        ticking = false
      })
      ticking = true
    }
  }, { passive: true })
}

// ── 8. Tab Bar ──
function initTabBar() {
  const tabBar = document.getElementById('tabBar')
  if (!tabBar) return
  tabBar.addEventListener('click', (e) => {
    const item = e.target.closest('.tab-item')
    if (!item) return
    tabBar.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'))
    item.classList.add('active')
  })
}

// ── 9. User Badges (notifications + cart count) ──
async function loadUserBadges() {
  if (!localStorage.getItem('token')) return
  const [notifData, cartCount] = await Promise.all([
    api.notification.getUnreadCount().catch(() => ({ count: 0 })),
    api.cart.getCount().catch(() => 0),
  ])
  const notifBadge = document.querySelector('.nav-badge')
  if (notifBadge) {
    notifBadge.textContent = notifData.count
    notifBadge.style.display = notifData.count > 0 ? '' : 'none'
  }
  const cartBadge = document.getElementById('cartBadge')
  if (cartBadge) {
    cartBadge.textContent = cartCount > 99 ? '99+' : cartCount
    cartBadge.style.display = cartCount > 0 ? '' : 'none'
  }
}

// ── 10. Profile Section ──
async function loadProfileSection() {
  if (!localStorage.getItem('token')) return
  const [profile, orders, coupons] = await Promise.all([
    api.user.getInfo().catch(() => null),
    api.order.getList().catch(() => []),
    api.coupon.getList().catch(() => ({ available: [] })),
  ])
  if (profile) {
    const nameEl = document.querySelector('.profile-name')
    const idEl = document.querySelector('.profile-id')
    if (nameEl) nameEl.textContent = profile.username || profile.name || '用户'
    if (idEl && profile.id) idEl.textContent = `ID: ${profile.id}`
  }
  const counts = { pending: 0, paid: 0, shipped: 0 }
  orders.forEach(o => { if (counts[o.status] !== undefined) counts[o.status]++ })
  ;[['pending', '[href="order.html?tab=pending"]'],
    ['paid', '[href="order.html?tab=paid"]'],
    ['shipped', '[href="order.html?tab=shipped"]']].forEach(([status, sel]) => {
    const badge = document.querySelector(sel + ' .order-badge')
    if (badge) {
      badge.textContent = counts[status]
      badge.style.display = counts[status] > 0 ? '' : 'none'
    }
  })
  const couponCount = (coupons.available || []).length
  const firstAsset = document.querySelector('.asset-item:first-child .asset-num')
  if (firstAsset) firstAsset.textContent = couponCount
}

// ── 0. Global click delegation (binds immediately, before any async) ──
document.addEventListener('click', (e) => {
  const card = e.target.closest('.product-card, .flash-card, .hot-item, .cat-product-row, .new-arrival-card')
  if (!card) return
  const id = card.dataset.id
  if (!id) return
  sessionStorage.setItem('productId', id)
  window.location.href = 'product-detail.html'
})

// ── 0. Home Page Data (index.html) ──
async function renderHomePage() {
  const hideSkeleton = (id) => {
    const el = document.getElementById(id)
    if (el) el.style.display = 'none'
  }

  const [banners, cats, flashSales, hotRanks, recommends, newArrivals, promotions] = await Promise.all([
    api.home.getBanners().catch(() => []),
    api.home.getCategories().catch(() => []),
    api.home.getFlashSale().catch(() => []),
    api.home.getHotRank().catch(() => []),
    api.home.getRecommend().catch(() => []),
    api.home.getNewArrival().catch(() => []),
    api.home.getPromotions().catch(() => []),
  ])

  if (flashSales.length > 0 && flashSales[0].endTime) {
    flashSaleEndTime = new Date(flashSales[0].endTime)
  }

  // 轮播图
  const carouselTrack = document.getElementById('carouselTrack')
  const carouselDots = document.getElementById('carouselDots')
  if (carouselTrack) {
    hideSkeleton('skeletonBanner')
    carouselTrack.innerHTML = banners.map((b, i) => `
      <div class="carousel-slide${i === 0 ? ' active' : ''}">
        <img src="${b.img}" alt="${b.title}" class="carousel-img">
        <div class="carousel-overlay"></div>
        <div class="carousel-text">
          <span class="carousel-tag">${b.tag}</span>
          <h2 class="carousel-title">${b.title.replace('\n', '<br>')}</h2>
          <a href="${b.link}" class="carousel-cta">${b.cta}</a>
        </div>
      </div>`).join('')
    if (carouselDots) {
      carouselDots.innerHTML = banners.map((_, i) =>
        `<button class="dot${i === 0 ? ' active' : ''}" data-index="${i}" aria-label="第${i + 1}张"></button>`
      ).join('')
    }
  }

  // 分类图标
  const categoryGrid = document.getElementById('categoryGrid')
  if (categoryGrid) {
    hideSkeleton('skeletonCategory')
    categoryGrid.innerHTML = cats.map(c => `
      <a href="${c.link}" class="category-item" data-reveal>
        <div class="category-icon-wrap">
          <img src="${c.icon}" alt="${c.name}" class="category-icon">
        </div>
        <span class="category-name">${c.name}</span>
      </a>`).join('')
    window.dispatchEvent(new Event('scroll'))
  }

  // 活动会场
  const promotionTrack = document.getElementById('promotionTrack')
  if (promotionTrack) {
    hideSkeleton('skeletonPromotion')
    if (promotions.length > 0) {
      promotionTrack.innerHTML = promotions.map(p => {
        const href = p.link || 'coupon.html'
        const image = p.img ? `<img src="${p.img}" alt="${p.title}" class="promotion-card__img">` : ''
        return `
          <a href="${href}" class="promotion-card">
            ${image}
            <div class="promotion-card__overlay"></div>
            <div class="promotion-card__body">
              <span class="promotion-card__title">${p.title || '优惠活动'}</span>
              <span class="promotion-card__sub">${p.subtitle || '限时福利，立即领取'}</span>
              <span class="promotion-card__cta">去领取</span>
            </div>
          </a>`
      }).join('')
    } else {
      promotionTrack.innerHTML = '<div class="empty-tip">暂无活动</div>'
    }
  }

  // 限时抢购
  const flashTrack = document.getElementById('flashTrack')
  if (flashTrack) {
    hideSkeleton('skeletonFlash')
    const allProducts = flashSales.flatMap(fs => fs.products || [])
    if (allProducts.length > 0) {
      flashTrack.innerHTML = allProducts.slice(0, 10).map((p) => `
        <div class="flash-card" data-id="${p.id}" data-name="${p.name}" data-price="${p.price}" data-img="${p.img}">
          <div class="flash-img-wrap">
            <img src="${p.img}" alt="${p.name}" class="flash-img">
            <span class="flash-tag">${p.tag}</span>
          </div>
          <div class="flash-info">
            <span class="flash-price">¥${p.price}</span>
            <span class="flash-original">¥${p.original}</span>
            <div class="flash-sales">已售 ${p.sales}</div>
          </div>
        </div>`).join('')
    } else {
      flashTrack.innerHTML = '<div class="empty-tip">暂无秒杀商品</div>'
    }
  }

  // 新品首发
  const newArrivalTrack = document.getElementById('newArrivalTrack')
  if (newArrivalTrack) {
    hideSkeleton('skeletonNewArrival')
    const allNewProducts = newArrivals.flatMap(na => na.products || [])
    if (allNewProducts.length > 0) {
      newArrivalTrack.innerHTML = allNewProducts.slice(0, 8).map((p) => `
        <div class="new-arrival-card" data-id="${p.id}" data-name="${p.name}" data-price="${p.price}" data-img="${p.img}">
          <div class="new-arrival-card__img-wrap">
            <img src="${p.img}" alt="${p.name}" class="new-arrival-card__img">
            <span class="new-arrival-card__tag">NEW</span>
          </div>
          <div class="new-arrival-card__body">
            <span class="new-arrival-card__name">${p.name}</span>
            <div class="new-arrival-card__meta">
              <span class="new-arrival-card__price">¥${p.price}</span>
              <span class="new-arrival-card__sales">${p.sales || 0}+</span>
            </div>
          </div>
        </div>`).join('')
    } else {
      newArrivalTrack.innerHTML = '<div class="empty-tip">暂无新品</div>'
    }
  }

  // 热销榜单
  const hotBento = document.getElementById('hotBento')
  if (hotBento) {
    hideSkeleton('skeletonHot')
    const allHotProducts = hotRanks.flatMap(hr => hr.products || [])
    if (allHotProducts.length > 0) {
      hotBento.innerHTML = `
        <div class="hot-item hot-item--hero" data-id="${allHotProducts[0].id}" data-name="${allHotProducts[0].name}" data-price="${allHotProducts[0].price}" data-img="${allHotProducts[0].img}">
          <div class="hot-item__rank">1</div>
          <div class="hot-item__img"><img src="${allHotProducts[0].img}" alt="${allHotProducts[0].name}"></div>
          <div class="hot-item__body">
            <p class="hot-item__name">${allHotProducts[0].name}</p>
            <p class="hot-item__sales">已售 ${allHotProducts[0].sales}</p>
            <p class="hot-item__price">¥${allHotProducts[0].price}</p>
          </div>
        </div>
        ${allHotProducts.slice(1, 4).map((p, i) => `
          <div class="hot-item" data-id="${p.id}" data-name="${p.name}" data-price="${p.price}" data-img="${p.img}">
            <div class="hot-item__rank">${i + 2}</div>
            <div class="hot-item__img"><img src="${p.img}" alt="${p.name}"></div>
            <div class="hot-item__body">
              <p class="hot-item__name">${p.name}</p>
              <p class="hot-item__sales">已售 ${p.sales}</p>
              <p class="hot-item__price">¥${p.price}</p>
            </div>
          </div>`).join('')}`
    } else {
      hotBento.innerHTML = '<div class="empty-tip">暂无热销商品</div>'
    }
  }

  // 为你推荐
  const recommendGrid = document.getElementById('recommendGrid')
  if (recommendGrid) {
    hideSkeleton('skeletonRecommend')
    const allRecProducts = recommends.flatMap(rec => rec.products || [])
    if (allRecProducts.length > 0) {
      recommendGrid.innerHTML = allRecProducts.map((p) => `
        <div class="product-card" data-id="${p.id}" data-name="${p.name}" data-price="${p.price}" data-img="${p.img}">
          <div class="product-img-wrap">
            <img src="${p.img}" alt="${p.name}" class="product-img">
            <button class="product-fav" aria-label="收藏">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.0 0 0 0 0-7.78z"/>
              </svg>
            </button>
          </div>
          <div class="product-info">
            <span class="product-name">${p.name}</span>
            <div class="product-bottom">
              <span class="product-price">¥${p.price}</span>
            </div>
          </div>
        </div>`).join('')
    } else {
      recommendGrid.innerHTML = '<div class="empty-tip">暂无推荐商品</div>'
    }
  }
}

// ── Bootstrap ──
function init() {
  loadUserBadges()
  loadProfileSection()
  renderHomePage().then(() => {
    initCarousel()
    initScrollReveal()
    initCountdown()
    initRecommendTabs()
    initFavorites()
    initBrowseHistory()
    initLoadMore()
    initNavScroll()
    initTabBar()
    initProductSheet()
    initSearch()
    initCartDrawer()
  })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init)
} else {
  init()
}
