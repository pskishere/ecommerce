/* ── Address Edit Page ── */
import { showToast } from '../components/toast.js'
import { api } from '../data/api.js'

const editing = { id: null, name: '', phone: '', province: '', city: '', district: '', detail: '', isDefault: false }
let regionData = {}
let isDefault = false

async function init() {
  regionData = await api.address.getRegion()
  const params = new URLSearchParams(location.search)
  const id = params.get('id')

  if (id) {
    editing.id = String(id)
    const list = await api.address.getList()
    const addr = list.find(a => String(a.id) === editing.id)
    if (addr) {
      editing.name = addr.name
      editing.phone = addr.phone
      editing.province = addr.province || ''
      editing.city = addr.city || ''
      editing.district = addr.district || ''
      editing.detail = addr.detail
      editing.isDefault = addr.isDefault
      isDefault = addr.isDefault
    }
  }

  renderForm()
  bindEvents()
}

function renderForm() {
  document.getElementById('pageTitle').textContent = editing.id ? '编辑地址' : '新增地址'
  if (editing.name) document.getElementById('nameInput').value = editing.name
  if (editing.phone) document.getElementById('phoneInput').value = editing.phone
  if (editing.detail) document.getElementById('detailInput').value = editing.detail

  const provinceSelect = document.getElementById('provinceSelect')
  const provinces = Object.keys(regionData)
  provinceSelect.innerHTML = '<option value="">请选择省</option>' + provinces.map(p => `<option value="${p}">${p}</option>`).join('')

  if (editing.province && provinces.includes(editing.province)) {
    provinceSelect.value = editing.province
    const cities = Object.keys(regionData[editing.province] || {})
    const citySelect = document.getElementById('citySelect')
    citySelect.innerHTML = '<option value="">请选择市</option>' + cities.map(c => `<option value="${c}">${c}</option>`).join('')
    citySelect.disabled = false

    if (editing.city && cities.includes(editing.city)) {
      citySelect.value = editing.city
      const districts = regionData[editing.province][editing.city] || []
      const districtSelect = document.getElementById('districtSelect')
      districtSelect.innerHTML = '<option value="">请选择区</option>' + districts.map(d => `<option value="${d}">${d}</option>`).join('')
      districtSelect.disabled = false

      if (editing.district && districts.includes(editing.district)) {
        districtSelect.value = editing.district
      }
    }
  }

  updateDefaultSwitch()
}

function bindEvents() {
  document.getElementById('provinceSelect').addEventListener('change', (e) => {
    updateCities(e.target.value)
    updateDistricts('')
  })
  document.getElementById('citySelect').addEventListener('change', (e) => updateDistricts(e.target.value))
  document.getElementById('defaultSwitch').addEventListener('click', () => {
    isDefault = !isDefault
    updateDefaultSwitch()
  })
}

function updateCities(province, preselect = '') {
  const citySelect = document.getElementById('citySelect')
  if (!province) {
    citySelect.innerHTML = '<option value="">请选择市</option>'
    citySelect.disabled = true
    return
  }
  const cities = Object.keys(regionData[province] || {})
  citySelect.innerHTML = '<option value="">请选择市</option>' + cities.map(c => `<option value="${c}">${c}</option>`).join('')
  citySelect.disabled = false
  if (preselect) citySelect.value = preselect
}

function updateDistricts(city, preselect = '') {
  const districtSelect = document.getElementById('districtSelect')
  if (!city) {
    districtSelect.innerHTML = '<option value="">请选择区</option>'
    districtSelect.disabled = true
    return
  }
  const province = document.getElementById('provinceSelect').value
  const districts = regionData[province]?.[city] || []
  districtSelect.innerHTML = '<option value="">请选择区</option>' + districts.map(d => `<option value="${d}">${d}</option>`).join('')
  districtSelect.disabled = false
  if (preselect) districtSelect.value = preselect
}

function updateDefaultSwitch() {
  document.getElementById('defaultSwitch').classList.toggle('active', isDefault)
}

function validate() {
  const name = document.getElementById('nameInput').value.trim()
  const phone = document.getElementById('phoneInput').value.trim()
  const detail = document.getElementById('detailInput').value.trim()
  const province = document.getElementById('provinceSelect').value
  const city = document.getElementById('citySelect').value
  const district = document.getElementById('districtSelect').value
  if (!name) { showToast('请输入收货人姓名'); return false }
  if (!phone || !/^1\d{10}$/.test(phone)) { showToast('请输入正确的手机号'); return false }
  if (!province || !city || !district) { showToast('请选择完整的省市区'); return false }
  if (!detail || detail.length < 5) { showToast('详细地址不能少于5个字符'); return false }
  return true
}

async function saveAddress() {
  if (!validate()) return
  const name = document.getElementById('nameInput').value.trim()
  const phone = document.getElementById('phoneInput').value.trim()
  const province = document.getElementById('provinceSelect').value
  const city = document.getElementById('citySelect').value
  const district = document.getElementById('districtSelect').value
  const detail = document.getElementById('detailInput').value.trim()

  const data = { name, phone, province, city, district, detail, isDefault }

  if (editing.id) {
    await api.address.update(editing.id, data)
  } else {
    await api.address.create(data)
  }
  showToast(editing.id ? '地址已保存' : '地址已添加')
  setTimeout(() => history.back(), 800)
}

window.saveAddress = saveAddress
init()
