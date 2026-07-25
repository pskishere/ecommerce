/* ── Settings Page ── */
import { showToast } from '../components/toast.js'
window.showToast = showToast

document.querySelectorAll('.settings-item').forEach(item => {
  item.addEventListener('click', () => {
    const action = item.dataset.action
    if (action === 'clearCache') {
      const token = localStorage.getItem('token')
      localStorage.clear()
      sessionStorage.clear()
      if (token) localStorage.setItem('token', token)
      showToast('缓存已清除')
    } else if (action === 'profile') {
      location.href = 'profile-info.html'
    } else if (action === 'notifications') {
      location.href = 'notifications.html'
    } else if (action === 'about') {
      showToast('潮流好物 v1.0.0')
    } else if (action === 'security') {
      showToast('账号安全正常')
    } else if (action === 'general') {
      showToast('通用设置已同步')
    } else if (action === 'help') {
      showToast('客服已收到反馈入口')
    } else if (action === 'thirdParty') {
      showToast('暂无绑定的第三方账号')
    }
  })
})

document.querySelector('.settings-logout').addEventListener('click', () => {
  localStorage.removeItem('token')
  showToast('已退出登录')
  setTimeout(() => location.href = 'login.html', 500)
})
