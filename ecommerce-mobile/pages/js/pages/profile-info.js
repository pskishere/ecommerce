/* ── Profile Info Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

let currentGender = 'secret'
let profileState = {
  phone: '',
  avatar: '',
}

const fieldIdMap = {
  昵称: 'nickname',
  邮箱: 'email',
  手机号: 'phone',
}

function maskPhone(phone) {
  const raw = String(phone || '').trim()
  if (raw.length >= 7) return `${raw.slice(0, 3)}****${raw.slice(-4)}`
  return raw
}

function setText(id, value, fallback = '') {
  const el = document.getElementById(id)
  if (el) el.textContent = value || fallback
}

function fileToDataURL(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result)
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

function applyGender(gender) {
  currentGender = gender || 'secret'
  document.querySelectorAll('.gender-option').forEach(opt => {
    const input = opt.querySelector('input')
    const isActive = input?.value === currentGender
    opt.classList.toggle('active', isActive)
    if (input) input.checked = isActive
  })
}

async function loadUserData() {
  try {
    const user = await api.user.getInfo()
    profileState.phone = user.phone || ''

    setText('nickname', user.username || user.name, '未填写')
    setText('email', user.email, '未填写')
    setText('birthday', user.birthday, '未填写')
    setText('phone', user.phone_masked || maskPhone(user.phone), '未填写')
    setText('userId', user.id)
    setText('registeredAt', user.registered_at, '未知')
    setText('memberLevel', user.vip_level_name, '普通会员')

    const avatar = document.getElementById('profileAvatar')
    if (avatar && user.avatar_name) avatar.src = user.avatar_name
    applyGender(user.gender || 'secret')
  } catch (e) {
    console.error('Failed to load user:', e)
    showToast('资料加载失败')
  }

  document.getElementById('profileInfoSkeleton')?.classList.add('loaded')
}

function chooseAvatar() {
  document.getElementById('avatarInput')?.click()
}

async function handleAvatarChange(event) {
  const file = event.target.files?.[0]
  event.target.value = ''
  if (!file) return
  if (!file.type.startsWith('image/')) {
    showToast('请选择图片文件')
    return
  }
  if (file.size > 5 * 1024 * 1024) {
    showToast('图片不能超过5MB')
    return
  }

  try {
    const dataUrl = await fileToDataURL(file)
    profileState.avatar = dataUrl
    const avatar = document.getElementById('profileAvatar')
    if (avatar) avatar.src = dataUrl
    showToast('头像已选择')
  } catch (e) {
    showToast('头像读取失败')
  }
}

function selectGender(el, gender) {
  currentGender = gender
  document.querySelectorAll('.gender-option').forEach(opt => opt.classList.remove('active'))
  el.classList.add('active')
  el.querySelector('input').checked = true
}

function editField(field) {
  const id = fieldIdMap[field]
  if (!id) return
  const currentValue = field === '手机号'
    ? profileState.phone
    : document.getElementById(id)?.textContent?.trim()
  const newValue = prompt(`请输入${field}：`, currentValue || '')
  if (newValue === null) return

  const value = newValue.trim()
  if (field === '昵称' && !value) {
    showToast('昵称不能为空')
    return
  }
  if (field === '手机号') {
    if (value && !/^[0-9+\-\s]{5,20}$/.test(value)) {
      showToast('手机号格式不正确')
      return
    }
    profileState.phone = value
    setText('phone', maskPhone(value), '未填写')
  } else {
    setText(id, value, '未填写')
  }
  showToast(`${field}已更新`)
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

async function saveProfile() {
  const nickname = document.getElementById('nickname')?.textContent?.trim()
  const email = document.getElementById('email')?.textContent?.trim()
  const birthday = document.getElementById('birthday')?.textContent?.trim()
  try {
    const updated = await api.user.updateProfile({
      username: nickname || '',
      email: email || '',
      phone: profileState.phone || '',
      gender: currentGender,
      birthday: birthday === '未填写' ? '' : birthday,
      ...(profileState.avatar ? { avatar: profileState.avatar } : {}),
    })
    if (updated?.phone !== undefined) profileState.phone = updated.phone || ''
    if (updated?.avatar_name) {
      profileState.avatar = ''
      const avatar = document.getElementById('profileAvatar')
      if (avatar) avatar.src = updated.avatar_name
    }
    showToast('保存成功')
    setTimeout(() => window.history.back(), 1000)
  } catch (e) {
    showToast('保存失败，请重试')
  }
}

window.selectGender = selectGender
window.editField = editField
window.showDatePicker = showDatePicker
window.saveProfile = saveProfile
window.chooseAvatar = chooseAvatar

document.getElementById('avatarInput')?.addEventListener('change', handleAvatarChange)

loadUserData()
