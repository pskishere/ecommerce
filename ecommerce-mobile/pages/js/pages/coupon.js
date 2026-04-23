/* ── Coupon Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'
import { createContentTab } from '../components/content-tab.js'

let allCoupons = {}

async function loadCoupons() {
  allCoupons = await api.coupon.getList()
  document.getElementById('couponSkeleton')?.classList.add('loaded')
  renderCoupons('available')
}

createContentTab({
  id: 'couponTabs',
  tabs: [
    { value: 'available', label: '可用优惠券' },
    { value: 'used', label: '已使用' },
    { value: 'expired', label: '已失效' },
  ],
  defaultTab: 'available',
  onChange: (tab) => renderCoupons(tab),
})

function renderCoupons(currentTab) {
  const list = document.getElementById('couponList')
  if (!list) return
  const coupons = allCoupons[currentTab] || []

  if (coupons.length === 0) {
    list.innerHTML = `
      <div class="coupon-empty">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><line x1="12" y1="22" x2="12" y2="7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>
        <div class="coupon-empty-text">暂无优惠券</div>
      </div>`
    return
  }

  list.innerHTML = coupons.map(coupon => `
    <div class="coupon-card" style="position:relative;display:flex;border-radius:12px;height:112px;box-shadow:0 1px 4px rgba(0,0,0,0.06);">
      <div class="coupon-left">
        <div class="coupon-value"><span>¥</span>${coupon.value}</div>
        <div class="coupon-threshold">${coupon.threshold}</div>
      </div>
      <div class="coupon-right">
        <div>
          <div class="coupon-name">${coupon.name}</div>
          <div class="coupon-desc">${coupon.desc}</div>
          <div class="coupon-time">${coupon.time}</div>
        </div>
        ${currentTab === 'available' ? `<button class="coupon-use-btn" onclick="useCoupon(${coupon.id})">立即使用</button>` : ''}
        ${currentTab === 'used' ? '<div class="coupon-status-tag used">已使用</div>' : ''}
        ${currentTab === 'expired' ? '<div class="coupon-status-tag expired">已失效</div>' : ''}
      </div>
    </div>`).join('')
}

function useCoupon(id) {
  showToast('跳转优惠专区...')
}

loadCoupons()
