/* ── VIP Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

async function init() {
  const [userInfo, vip] = await Promise.all([
    api.user.getInfo().catch(() => null),
    api.user.getVIP().catch(() => null),
  ])

  if (userInfo) {
    const el = document.getElementById('vipUserName')
    if (el) el.textContent = userInfo.username || userInfo.name || '-'
  }

  if (vip) {
    const levelEl = document.getElementById('vipLevelName')
    const expireEl = document.getElementById('vipExpire')
    const pointsEl = document.getElementById('vipPoints')
    const growthEl = document.getElementById('vipGrowth')
    const upgradeBar = document.getElementById('vipUpgradeBar')
    const upgradeBtn = document.getElementById('vipUpgradeBtn')

    if (levelEl) levelEl.textContent = vip.level_name || '普通会员'
    if (expireEl) expireEl.textContent = vip.expire_date ? `有效期至 ${vip.expire_date}` : '暂未开通'
    if (pointsEl) pointsEl.textContent = vip.points ?? 0
    if (growthEl) growthEl.textContent = vip.growth_value ?? 0

    if (upgradeBar) {
      if (vip.next_level) {
        upgradeBar.style.display = 'block'
        if (upgradeBtn) {
          const label = vip.level === 'none' ? '立即开通会员' : `升级为${vip.next_level_name}`
          upgradeBtn.textContent = label
        }
      }
    }
  }
}

document.getElementById('vipUpgradeBtn')?.addEventListener('click', async () => {
  const btn = document.getElementById('vipUpgradeBtn')
  if (btn) btn.disabled = true
  try {
    const vip = await api.user.upgradeVIP()
    const levelEl = document.getElementById('vipLevelName')
    const expireEl = document.getElementById('vipExpire')
    const growthEl = document.getElementById('vipGrowth')
    if (levelEl) levelEl.textContent = vip.level_name || ''
    if (expireEl) expireEl.textContent = vip.expire_date ? `有效期至 ${vip.expire_date}` : ''
    if (growthEl) growthEl.textContent = vip.growth_value ?? 0
    showToast(`${vip.level_name}升级成功！`)
    if (!vip.next_level) {
      document.getElementById('vipUpgradeBar')?.remove()
    } else {
      if (btn) btn.textContent = `升级为${vip.next_level_name}`
    }
  } catch {
    showToast('升级失败，请重试')
  } finally {
    if (btn) btn.disabled = false
  }
})

init()
