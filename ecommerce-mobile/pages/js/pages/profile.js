/* ── Profile Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

let userData = {}
let orderCounts = { pending: 0, paid: 0, shipped: 0, completed: 0 }
let couponCount = 0

// Check if user is logged in
function isLoggedIn() {
  return !!localStorage.getItem('token')
}

function updateLoginState() {
  const loginCard = document.getElementById('loginCard')
  const userCard = document.getElementById('userCard')

  if (isLoggedIn()) {
    loginCard.style.display = 'none'
    userCard.style.display = 'flex'
  } else {
    loginCard.style.display = 'flex'
    userCard.style.display = 'none'
  }
}

async function loadProfile() {
  // Update login state UI
  updateLoginState()

  // If not logged in, skip loading user data
  if (!isLoggedIn()) {
    renderProfile()
    updateTabCartBadge()
    return
  }

  // Load user data
  try {
    userData = await api.user.getInfo()
  } catch (e) {
    console.error('Failed to load user:', e)
    // If token is invalid, clear it
    if (e.message.includes('invalid') || e.message.includes('Unauthorized')) {
      localStorage.removeItem('token')
      updateLoginState()
    }
  }

  // Load order counts
  try {
    const orders = await api.order.getList()
    orderCounts = { pending: 0, paid: 0, shipped: 0, completed: 0 }
    orders.forEach(o => {
      if (o.status in orderCounts) orderCounts[o.status]++
    })
  } catch (e) {
    console.error('Failed to load orders:', e)
  }

  // Load coupon count
  try {
    const coupons = await api.coupon.getList()
    couponCount = (coupons.available || []).length
  } catch (e) {
    console.error('Failed to load coupons:', e)
  }

  renderProfile()
}

function renderProfile() {
  // Update user info
  const userName = document.getElementById('userName')
  if (userName) userName.textContent = userData.name || '用户'

  const userId = document.getElementById('userId')
  if (userId) userId.textContent = 'ID: ' + (userData.id || '-')

  // Update avatar
  const userAvatar = document.getElementById('userAvatar')
  if (userAvatar) {
    if (userData.avatarName) {
      // Use avatarName directly if it's a URL, otherwise construct path
      const avatarSrc = userData.avatarName.startsWith('http')
        ? userData.avatarName
        : `./assets/images/${userData.avatarName}.webp`
      userAvatar.innerHTML = `<img src="${avatarSrc}" alt="头像">`
    } else {
      userAvatar.innerHTML = `<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>`
    }
  }

  // Update stats
  const followCount = document.getElementById('followCount')
  if (followCount) followCount.textContent = userData.followCount || '0'

  const fansCount = document.getElementById('fansCount')
  if (fansCount) fansCount.textContent = userData.fansCount || '0'

  const pointsCount = document.getElementById('pointsCount')
  if (pointsCount) pointsCount.textContent = userData.points || '0'

  // Update order badges
  const pendingBadge = document.getElementById('pendingBadge')
  if (pendingBadge) {
    pendingBadge.textContent = orderCounts.pending || ''
    pendingBadge.style.display = orderCounts.pending > 0 ? 'inline-flex' : 'none'
  }

  const shippedBadge = document.getElementById('shippedBadge')
  if (shippedBadge) {
    shippedBadge.textContent = orderCounts.shipped || ''
    shippedBadge.style.display = orderCounts.shipped > 0 ? 'inline-flex' : 'none'
  }

  // Update coupon count
  const couponNum = document.getElementById('couponNum')
  if (couponNum) couponNum.textContent = couponCount
}

function updateTabCartBadge() {
  const cart = JSON.parse(localStorage.getItem('cart') || '[]')
  const badge = document.getElementById('tabCartBadge')
  if (!badge) return
  const total = cart.reduce((s, item) => s + item.qty, 0)
  if (total > 0) {
    badge.textContent = total > 99 ? '99+' : total
    badge.style.display = 'flex'
  } else {
    badge.style.display = 'none'
  }
}

loadProfile()
updateTabCartBadge()
