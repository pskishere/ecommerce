/* ── Favorites Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

let favorites = []

async function loadFavorites() {
  favorites = await api.favorite.getList()
  document.getElementById('favSkeleton')?.classList.add('loaded')
  renderFavorites()
}

function renderFavorites() {
  const grid = document.getElementById('favGrid')
  if (!grid) return

  if (favorites.length === 0) {
    grid.innerHTML = `
      <div class="empty-state" style="grid-column: span 2;">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.0 0 0 0 0-7.78z"/></svg>
        </div>
        <div class="empty-text">暂无收藏商品</div>
        <button class="empty-btn" onclick="window.location.href='index.html'">去逛逛</button>
      </div>`
    return
  }

  grid.innerHTML = favorites.map(item => `
    <div class="fav-card" onclick="sessionStorage.setItem('productId','${item.id}');window.location.href='product-detail.html'">
      ${item.tag ? `<span class="fav-tag">${item.tag}</span>` : ''}
      <div class="fav-img-wrap">
        <img class="fav-img" src="${item.img}" alt="${item.name}">
        <div class="fav-remove" onclick="event.stopPropagation(); removeFavoriteItem(${item.id})">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </div>
      </div>
      <div class="fav-info">
        <div class="fav-name">${item.name}</div>
        <div class="fav-bottom">
          <div class="fav-price">¥${item.price}</div>
          ${item.original > item.price ? `<div class="fav-original">¥${item.original}</div>` : ''}
        </div>
        <div class="fav-meta">
          <div class="fav-sales">已售 ${item.sales || 0}</div>
          ${item.rating ? `
          <div class="fav-rating">
            ${[1,2,3,4,5].map(i => `
              <svg width="9" height="9" viewBox="0 0 24 24" fill="${i <= Math.round(item.rating) ? '#FFB800' : 'none'}" stroke="${i <= Math.round(item.rating) ? '#FFB800' : '#CCC'}" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
            `).join('')}
            <span>${item.rating.toFixed(1)}</span>
          </div>` : ''}
        </div>
      </div>
    </div>`).join('')
}

async function removeFavoriteItem(id) {
  await api.favorite.remove(id)
  favorites = favorites.filter(f => f.id !== id)
  renderFavorites()
  showToast('已取消收藏')
}

window.removeFavoriteItem = removeFavoriteItem
loadFavorites()
