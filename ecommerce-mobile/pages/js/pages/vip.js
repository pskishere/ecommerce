/* ── VIP Page ── */
import { showToast } from '../components/toast.js'

document.querySelector('.vip-upgrade-btn')?.addEventListener('click', () => {
  showToast('升级成功，成为VIP会员')
})
