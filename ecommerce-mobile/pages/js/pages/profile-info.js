/* ── Profile Info Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

let currentGender = '女'

async function loadUserData() {
  try {
    const user = await api.user.getInfo()
    // Update user name
    const nickname = document.getElementById('nickname')
    if (nickname && user.name) nickname.textContent = user.name

    // Update email
    const email = document.getElementById('email')
    if (email && user.email) email.textContent = user.email

    // Update user ID
    const userIdEl = document.querySelector('.info-item:nth-child(1) .value')
    if (userIdEl && user.id) userIdEl.textContent = user.id
  } catch (e) {
    console.error('Failed to load user:', e)
  }

  document.getElementById('profileInfoSkeleton')?.classList.add('loaded')
}

function selectGender(el, gender) {
  document.querySelectorAll('.gender-option').forEach(opt => opt.classList.remove('active'))
  el.classList.add('active')
  currentGender = gender
  el.querySelector('input').checked = true
}

function editField(field, currentValue) {
  const newValue = prompt(`请输入${field}：`, currentValue)
  if (newValue && newValue.trim() !== '') {
    if (field === '昵称') {
      document.getElementById('nickname').textContent = newValue.trim()
    } else if (field === '邮箱') {
      document.getElementById('email').textContent = newValue.trim()
    }
    showToast(`${field}已更新`)
  }
}

function showDatePicker() {
  const current = document.getElementById('birthday').textContent
  const newDate = prompt('请输入生日（格式：YYYY-MM-DD）：', current)
  if (newDate && /^\d{4}-\d{2}-\d{2}$/.test(newDate)) {
    document.getElementById('birthday').textContent = newDate
    showToast('生日已更新')
  } else if (newDate) {
    showToast('日期格式不正确')
  }
}

function saveProfile() {
  showToast('保存成功')
  setTimeout(() => window.history.back(), 1000)
}

loadUserData()
