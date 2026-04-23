/* ── Settings Page ── */
import { showToast } from '../components/toast.js'
window.showToast = showToast

document.querySelectorAll('.settings-item').forEach(item => {
  item.addEventListener('click', () => {
    const action = item.dataset.action
    if (action === 'clearCache') {
      showToast('缓存已清除')
    } else if (action === 'about') {
      showToast('潮流好物 v1.0.0')
    }
  })
})

document.querySelector('.settings-logout').addEventListener('click', () => {
  localStorage.removeItem('token')
  showToast('已退出登录')
  setTimeout(() => location.href = 'login.html', 500)
})
