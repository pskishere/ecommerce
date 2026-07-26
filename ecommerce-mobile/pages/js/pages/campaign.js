import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

const root = document.getElementById('campaignRoot')
const navTitle = document.getElementById('navTitle')
const backBtn = document.getElementById('backBtn')
const params = new URLSearchParams(window.location.search)
const bannerId = params.get('banner_id') || params.get('id') || ''

const escapeHTML = (value) => String(value ?? '')
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;')

const priceText = (price) => {
  const n = Number(price)
  if (!Number.isFinite(n)) return `¥${price || 0}`
  return `¥${n.toFixed(2)}`
}

function goBack() {
  if (window.history.length > 1) {
    window.history.back()
  } else {
    window.location.href = 'index.html'
  }
}

function productCard(product) {
  return `
    <a href="product-detail.html" class="campaign-product" data-id="${escapeHTML(product.id)}">
      <div class="campaign-product-img">
        <img src="${escapeHTML(product.img)}" alt="${escapeHTML(product.name)}" loading="lazy">
      </div>
      <div class="campaign-product-body">
        <div class="campaign-product-name">${escapeHTML(product.name)}</div>
        <div class="campaign-product-meta">
          <span class="campaign-product-price">${priceText(product.price)}</span>
          <span class="campaign-product-sales">已售 ${escapeHTML(product.sales || 0)}</span>
        </div>
      </div>
    </a>
  `
}

function renderEmpty(title, text, retry = false) {
  root.innerHTML = `
    <section class="${retry ? 'campaign-error' : 'campaign-empty'}">
      <div class="campaign-empty-icon">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>
      </div>
      <div class="campaign-empty-title">${escapeHTML(title)}</div>
      <div class="campaign-empty-text">${escapeHTML(text)}</div>
      ${retry ? '<button class="campaign-retry" id="retryBtn">重试</button>' : ''}
    </section>
  `
  document.getElementById('retryBtn')?.addEventListener('click', loadCampaign)
}

function renderCampaign(campaign) {
  const products = campaign.products || []
  navTitle.textContent = campaign.tag || campaign.title || '专题会场'

  root.innerHTML = `
    <section class="campaign-hero">
      <img src="${escapeHTML(campaign.img)}" alt="${escapeHTML(campaign.title)}" class="campaign-hero-img">
      <div class="campaign-hero-gradient"></div>
      <div class="campaign-hero-body">
        <span class="campaign-badge">${escapeHTML(campaign.badge || campaign.tag || 'TREND')}</span>
        <h1 class="campaign-title">${escapeHTML(campaign.title || '专题会场')}</h1>
        <div class="campaign-subtitle">${escapeHTML(campaign.subtitle || campaign.tag || '')}</div>
      </div>
    </section>

    <section class="campaign-intro">
      <p class="campaign-desc">${escapeHTML(campaign.description || '精选商品已为你整理好，可直接浏览并加入购物车。')}</p>
      <div class="campaign-tags">
        <span class="campaign-tag">官方精选</span>
        <span class="campaign-tag">7天无理由</span>
        <span class="campaign-tag">满99包邮</span>
      </div>
    </section>

    <section class="campaign-section">
      <div class="campaign-section-head">
        <h2 class="campaign-section-title">会场商品</h2>
        <span class="campaign-count">${products.length} 件精选</span>
      </div>
      ${products.length > 0
        ? `<div class="campaign-products">${products.map(productCard).join('')}</div>`
        : '<div class="campaign-empty-text">当前专题商品正在补货</div>'}
    </section>
  `

  root.querySelectorAll('.campaign-product').forEach(card => {
    card.addEventListener('click', () => {
      const id = card.dataset.id
      if (id) sessionStorage.setItem('productId', id)
    })
  })
}

async function loadCampaign() {
  if (!bannerId) {
    renderEmpty('专题不存在', '没有拿到有效的 banner 参数，请从首页重新进入。')
    return
  }

  try {
    const campaign = await api.home.getBannerLanding(bannerId)
    renderCampaign(campaign)
  } catch (error) {
    renderEmpty('专题加载失败', error.message || '请稍后重试', true)
    showToast(error.message || '专题加载失败')
  }
}

backBtn?.addEventListener('click', goBack)
loadCampaign()
