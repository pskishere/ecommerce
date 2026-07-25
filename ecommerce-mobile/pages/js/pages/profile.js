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

  const [userResult, ordersResult, couponsResult] = await Promise.allSettled([
    api.user.getInfo(),
    api.order.getList(),
    api.coupon.getList(),
  ])

  if (userResult.status === 'fulfilled') {
    userData = userResult.value
  } else {
    const msg = userResult.reason?.message ?? ''
    if (msg.includes('invalid') || msg.includes('Unauthorized')) {
      localStorage.removeItem('token')
      updateLoginState()
    }
  }

  if (ordersResult.status === 'fulfilled') {
    orderCounts = { pending: 0, paid: 0, shipped: 0, completed: 0 }
    ordersResult.value.forEach(o => {
      if (o.status in orderCounts) orderCounts[o.status]++
    })
  }

  if (couponsResult.status === 'fulfilled') {
    couponCount = (couponsResult.value.available || []).length
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

async function updateTabCartBadge() {
  try {
    const count = await api.cart.getCount()
    const badge = document.getElementById('tabCartBadge')
    if (!badge) return
    if (count > 0) {
      badge.textContent = count > 99 ? '99+' : count
      badge.style.display = 'flex'
    } else {
      badge.style.display = 'none'
    }
  } catch (e) {
    const badge = document.getElementById('tabCartBadge')
    if (badge) badge.style.display = 'none'
  }
}

loadProfile()
updateTabCartBadge()
