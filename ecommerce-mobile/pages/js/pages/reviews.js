/* ── Reviews Page ── */
import { api } from '../data/api.js'
import { createContentTab } from '../components/content-tab.js'

let allReviews = []

async function loadReviews() {
  const params = new URLSearchParams(location.search)
  const productId = params.get('productId')
  allReviews = await api.product.getReviews(productId)
  document.getElementById('reviewsSkeleton')?.classList.add('loaded')
  renderReviews('all')
}

createContentTab({
  id: 'reviewsTabs',
  tabs: [
    { value: 'all', label: '全部' },
    { value: '5', label: '5星' },
    { value: '4', label: '4星' },
    { value: '3', label: '3星' },
    { value: '12', label: '1-2星' },
  ],
  defaultTab: 'all',
  onChange: (tab) => renderReviews(tab),
})

function renderReviews(currentTab) {
  const list = document.getElementById('reviewsList')
  if (!list) return

  let reviews = currentTab === 'all'
    ? allReviews
    : currentTab === '12'
      ? allReviews.filter(r => r.rating <= 2)
      : allReviews.filter(r => String(r.rating) === currentTab)

  if (reviews.length === 0) {
    list.innerHTML = '<div style="text-align:center;padding:40px;color:#999">暂无评价</div>'
    return
  }

  list.innerHTML = reviews.map(review => `
    <div class="review-card">
      <div class="review-card-header">
        ${review.userAvatar ? `<div class="review-avatar"><img src="${review.userAvatar}" alt=""></div>` : `<div class="review-avatar" style="display:flex;align-items:center;justify-content:center;font-size:14px;color:#999">${(review.userName || '匿名').charAt(0)}</div>`}
        <div class="review-user-info">
          <div class="review-user-name">${review.userName}</div>
          <div class="review-user-stars">
            ${[1,2,3,4,5].map(i => `<svg class="review-star ${i <= review.rating ? '' : 'empty'}" viewBox="0 0 24 24" fill="currentColor"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>`).join('')}
          </div>
        </div>
        <div class="review-date">${review.createdAt ? new Date(review.createdAt).toLocaleDateString('zh-CN') : ''}</div>
      </div>
      <div class="review-spec">${review.spec}</div>
      <div class="review-content">${review.content}</div>
      ${review.images?.length > 0 ? `<div class="review-images">${review.images.map(img => `<div class="review-image"><img src="${img}" alt=""></div>`).join('')}</div>` : ''}
      <div class="review-footer">
        <div></div>
        <div class="review-like ${review.isLiked ? 'active' : ''}" onclick="toggleLike(${review.id})">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="${review.isLiked ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/></svg>
          ${review.likeCount}
        </div>
      </div>
      ${review.hasReply ? `<div class="review-reply"><span>商家回复：</span>${review.reply}</div>` : ''}
    </div>`).join('')
}

async function toggleLike(id) {
  // Like API not available in backend, just toggle UI state
  const review = allReviews.find(r => r.id === id)
  if (review) {
    review.isLiked = !review.isLiked
    review.likeCount = (review.likeCount || 0) + (review.isLiked ? 1 : -1)
    renderReviews('all')
  }
}

window.toggleLike = toggleLike
loadReviews()
