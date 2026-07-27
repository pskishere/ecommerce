const BASE_URL = 'http://localhost:8080'

const state = {
  view: 'dashboard',
  query: '',
  productStatus: '',
  orderStatus: '',
  couponStatus: '',
  contentKind: 'categories',
  products: [],
  orders: [],
  users: [],
  coupons: [],
  categories: [],
  subcategories: [],
  banners: [],
  media: [],
  drawerSubmit: null,
}

const viewMeta = {
  dashboard: ['后台 / 概览', '概览'],
  products: ['后台 / 商品', '商品管理'],
  orders: ['后台 / 订单', '订单履约'],
  users: ['后台 / 会员', '用户管理'],
  content: ['后台 / 内容', '内容管理'],
  coupons: ['后台 / 权益', '优惠券'],
  shop: ['后台 / 店铺', '店铺设置'],
}

const $ = (selector, ctx = document) => ctx.querySelector(selector)
const $$ = (selector, ctx = document) => Array.from(ctx.querySelectorAll(selector))

const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, ch => ({
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
}[ch]))

const token = () => localStorage.getItem('admin_token') || ''
const setToken = value => localStorage.setItem('admin_token', value)
const clearToken = () => localStorage.removeItem('admin_token')

async function request(endpoint, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) }
  if (token()) headers.Authorization = 'Token ' + token()
  const response = await fetch(BASE_URL + endpoint, { ...options, headers })

  if (response.status === 401 || response.status === 403) {
    clearToken()
    showLogin('请先使用管理员账号登录')
    throw new Error('请先使用管理员账号登录')
  }

  const contentType = response.headers.get('content-type') || ''
  if (!contentType.includes('application/json')) {
    throw new Error('接口返回格式错误')
  }

  const payload = await response.json()
  if (payload && payload.code !== undefined) {
    if (payload.code === 0) return payload.data
    throw new Error(payload.msg || '操作失败')
  }
  return payload
}

function jsonBody(data) {
  return { body: JSON.stringify(data) }
}

function money(value) {
  const n = Number(value || 0)
  return '¥' + (Number.isFinite(n) ? n.toFixed(2) : '0.00')
}

function statusText(status) {
  return {
    pending: '待付款',
    paid: '待发货',
    shipped: '待收货',
    completed: '已完成',
    cancelled: '已取消',
    none: '未申请',
    requested: '已申请',
    processing: '处理中',
    refunded: '已退款',
    rejected: '已拒绝',
    available: '可用',
    used: '已使用',
    expired: '已失效',
  }[status] || status || '-'
}

function statusPill(status, label = statusText(status)) {
  return `<span class="status-pill ${escapeHtml(status)}">${escapeHtml(label)}</span>`
}

function itemThumb(src, alt = '') {
  return src
    ? `<img class="item-thumb" src="${escapeHtml(src)}" alt="${escapeHtml(alt)}">`
    : '<div class="item-thumb is-empty">IMG</div>'
}

function showToast(message) {
  const toast = $('#adminToast')
  if (!toast) return
  toast.textContent = message
  toast.classList.add('show')
  clearTimeout(showToast.timer)
  showToast.timer = setTimeout(() => toast.classList.remove('show'), 2200)
}

function showLogin(message = '') {
  $('#loginPanel').hidden = false
  $('#adminApp').hidden = true
  document.body.classList.add('admin-locked')
  const error = $('#loginError')
  if (message) {
    error.textContent = message
    error.hidden = false
  }
}

function showApp() {
  $('#loginPanel').hidden = true
  $('#adminApp').hidden = false
  document.body.classList.remove('admin-locked')
}

async function login(event) {
  event.preventDefault()
  const error = $('#loginError')
  error.hidden = true
  try {
    const data = await request('/api/admin/login/', {
      method: 'POST',
      body: JSON.stringify({
        username: $('#adminUsername').value.trim(),
        password: $('#adminPassword').value,
      }),
    })
    setToken(data.token)
    showApp()
    await bootstrap()
  } catch (err) {
    error.textContent = err.message || '登录失败'
    error.hidden = false
  }
}

async function bootstrap() {
  bindChrome()
  await loadMeta()
  await switchView(state.view)
}

function bindChrome() {
  if (bindChrome.done) return
  bindChrome.done = true

  $('#adminLoginForm')?.addEventListener('submit', login)
  $('#logoutBtn')?.addEventListener('click', () => {
    clearToken()
    showLogin()
  })
  $('#refreshBtn')?.addEventListener('click', () => loadCurrentView())
  $('#globalSearch')?.addEventListener('input', debounce(event => {
    state.query = event.target.value.trim()
    loadCurrentView()
  }, 260))

  document.addEventListener('click', event => {
    const action = event.target.closest('[data-action]')
    if (action) {
      handleAction(action.dataset.action, action)
      return
    }

    const viewButton = event.target.closest('[data-view]')
    if (viewButton) {
      switchView(viewButton.dataset.view)
    }
  })

  bindSegment('#productStatus', value => {
    state.productStatus = value
    loadProducts()
  })
  bindSegment('#orderStatus', value => {
    state.orderStatus = value
    loadOrders()
  })
  bindSegment('#couponStatus', value => {
    state.couponStatus = value
    loadCoupons()
  })
  bindSegment('#contentKind', value => {
    state.contentKind = value
    renderContent()
  })

  $('#drawerForm')?.addEventListener('submit', async event => {
    event.preventDefault()
    if (!state.drawerSubmit) return
    await state.drawerSubmit(collectDrawerValues())
  })

  $('#shopForm')?.addEventListener('submit', saveShop)
}

function bindSegment(selector, onChange) {
  const node = $(selector)
  if (!node) return
  node.addEventListener('click', event => {
    const button = event.target.closest('button[data-value]')
    if (!button) return
    $$('button', node).forEach(item => item.classList.remove('active'))
    button.classList.add('active')
    onChange(button.dataset.value)
  })
}

function debounce(fn, delay) {
  let timer = 0
  return (...args) => {
    clearTimeout(timer)
    timer = setTimeout(() => fn(...args), delay)
  }
}

async function loadMeta() {
  const [categories, subcategories, media, productResult] = await Promise.all([
    request('/api/admin/categories/'),
    request('/api/admin/subcategories/'),
    request('/api/admin/media/'),
    request('/api/admin/products/'),
  ])
  state.categories = categories || []
  state.subcategories = subcategories || []
  state.media = media || []
  state.products = productResult.items || []
}

async function switchView(view) {
  state.view = view
  state.query = ''
  if ($('#globalSearch')) $('#globalSearch').value = ''
  $$('.admin-view').forEach(node => node.classList.remove('active'))
  $('#' + view + 'View')?.classList.add('active')
  $$('.admin-nav__item').forEach(item => item.classList.toggle('active', item.dataset.view === view))
  $('#viewKicker').textContent = viewMeta[view]?.[0] || 'Admin'
  $('#viewTitle').textContent = viewMeta[view]?.[1] || '后台'
  await loadCurrentView()
}

function loadCurrentView() {
  return {
    dashboard: loadDashboard,
    products: loadProducts,
    orders: loadOrders,
    users: loadUsers,
    content: loadContent,
    coupons: loadCoupons,
    shop: loadShop,
  }[state.view]?.()
}

async function loadDashboard() {
  try {
    const data = await request('/api/admin/overview/')
    renderMetrics(data.metrics)
    renderRecentOrders(data.recent_orders || [])
    renderTopProducts(data.top_products || [])
  } catch (err) {
    showToast(err.message)
  }
}

function renderMetrics(metrics = {}) {
  const items = [
    ['营业额', money(metrics.revenue), 'GMV'],
    ['订单数', metrics.orders || 0, `${metrics.paid_orders || 0} 待发货`],
    ['上架商品', metrics.active_products || 0, `${metrics.products || 0} 总商品`],
    ['会员用户', metrics.users || 0, `${metrics.coupons || 0} 张券`],
  ]
  $('#metricGrid').innerHTML = items.map(([label, value, tag]) => `
    <article class="metric-card">
      <span>${escapeHtml(label)}</span>
      <strong>${escapeHtml(value)}</strong>
      <em>${escapeHtml(tag)}</em>
    </article>
  `).join('')
}

function renderRecentOrders(orders) {
  $('#recentOrders').innerHTML = orders.length ? `
    <div class="summary-list">
      ${orders.map(order => `
        <div class="summary-row">
          <div>
            <strong>${escapeHtml(order.id)}</strong>
            <span>${escapeHtml(order.user?.username || '-')} · ${escapeHtml(order.created_display || '')}</span>
          </div>
          <div>
            ${statusPill(order.status)}
            <small>${money(order.payment || order.total_amount)}</small>
          </div>
        </div>
      `).join('')}
    </div>
  ` : '<div class="empty-state">暂无订单</div>'
}

function renderTopProducts(products) {
  $('#topProducts').innerHTML = products.length ? `
    <div class="summary-list">
      ${products.map(product => `
        <div class="summary-row">
          <div class="item-cell">
            ${itemThumb(product.image, product.name)}
            <div>
              <strong class="item-title">${escapeHtml(product.name)}</strong>
              <span class="item-sub">${escapeHtml(product.category_name || product.subcategory_name || '未分类')}</span>
            </div>
          </div>
          <small>${escapeHtml(product.sales_count)} 销量</small>
        </div>
      `).join('')}
    </div>
  ` : '<div class="empty-state">暂无商品</div>'
}

async function loadProducts() {
  try {
    const params = new URLSearchParams()
    if (state.query) params.set('q', state.query)
    if (state.productStatus) params.set('status', state.productStatus)
    const data = await request('/api/admin/products/' + (params.toString() ? '?' + params : ''))
    state.products = data.items || []
    renderProducts()
  } catch (err) {
    showToast(err.message)
  }
}

function renderProducts() {
  const body = $('#productsTable')
  body.innerHTML = state.products.length ? state.products.map(product => `
    <tr>
      <td>
        <div class="item-cell">
          ${itemThumb(product.image, product.name)}
          <div>
            <strong class="item-title">${escapeHtml(product.name)}</strong>
            <span class="item-sub">${escapeHtml(product.tag || '无标签')} · 库存 ${escapeHtml(product.stock_total)}</span>
          </div>
        </div>
      </td>
      <td>${escapeHtml(product.category_name || '-')}<span class="item-sub">${escapeHtml(product.subcategory_name || '')}</span></td>
      <td><strong>${money(product.price)}</strong><span class="item-sub">${product.original_price ? money(product.original_price) : ''}</span></td>
      <td>${escapeHtml(product.sales_count)}</td>
      <td>${statusPill(product.is_in_stock ? 'is-live' : 'is-off', product.is_in_stock ? '上架' : '下架')}</td>
      <td>
        <div class="row-actions">
          <button class="row-btn" data-action="edit-product" data-id="${escapeHtml(product.id)}" type="button">编辑</button>
          <button class="row-btn" data-action="toggle-product" data-id="${escapeHtml(product.id)}" type="button">${product.is_in_stock ? '下架' : '上架'}</button>
        </div>
      </td>
    </tr>
  `).join('') : '<tr><td colspan="6"><div class="empty-state">暂无商品</div></td></tr>'
}

async function loadOrders() {
  try {
    const params = new URLSearchParams()
    if (state.query) params.set('q', state.query)
    if (state.orderStatus) params.set('status', state.orderStatus)
    const data = await request('/api/admin/orders/' + (params.toString() ? '?' + params : ''))
    state.orders = data.items || []
    renderOrders()
  } catch (err) {
    showToast(err.message)
  }
}

function renderOrders() {
  $('#ordersTable').innerHTML = state.orders.length ? state.orders.map(order => {
    const firstProduct = order.products?.[0]
    return `
      <tr>
        <td>
          <strong>${escapeHtml(order.id)}</strong>
          <span class="item-sub">${escapeHtml(firstProduct?.name || '无商品')} · ${escapeHtml(order.item_count || 0)} 件</span>
        </td>
        <td>${escapeHtml(order.user?.username || '-')}<span class="item-sub">${escapeHtml(order.address?.phone || '')}</span></td>
        <td><strong>${money(order.payment || order.total_amount)}</strong><span class="item-sub">优惠 ${money(order.discount || 0)}</span></td>
        <td>${statusPill(order.status)}<span class="item-sub">${escapeHtml(order.created_display || '')}</span></td>
        <td>${escapeHtml(order.carrier || '-')}<span class="item-sub">${escapeHtml(order.tracking_number || order.after_sale_status_text || '')}</span></td>
        <td>
          <div class="row-actions">
            ${order.status === 'pending' ? `<button class="row-btn" data-action="mark-paid" data-id="${escapeHtml(order.id)}" type="button">标记支付</button>` : ''}
            ${order.status === 'paid' ? `<button class="row-btn" data-action="ship-order" data-id="${escapeHtml(order.id)}" type="button">发货</button>` : ''}
            <button class="row-btn" data-action="set-order-status" data-id="${escapeHtml(order.id)}" type="button">改状态</button>
            <button class="row-btn" data-action="after-sale" data-id="${escapeHtml(order.id)}" type="button">售后</button>
          </div>
        </td>
      </tr>
    `
  }).join('') : '<tr><td colspan="6"><div class="empty-state">暂无订单</div></td></tr>'
}

async function loadUsers() {
  try {
    const params = new URLSearchParams()
    if (state.query) params.set('q', state.query)
    const data = await request('/api/admin/users/' + (params.toString() ? '?' + params : ''))
    state.users = data.items || []
    renderUsers()
  } catch (err) {
    showToast(err.message)
  }
}

function renderUsers() {
  $('#usersTable').innerHTML = state.users.length ? state.users.map(user => `
    <tr>
      <td><strong>${escapeHtml(user.username)}</strong><span class="item-sub">${escapeHtml(user.user_type === 'admin' ? '管理员' : '普通用户')}</span></td>
      <td>${escapeHtml(user.phone || '-')}<span class="item-sub">${escapeHtml(user.email || '')}</span></td>
      <td>${escapeHtml(user.vip_level_name)}<span class="item-sub">${escapeHtml(user.points)} 积分</span></td>
      <td>${escapeHtml(user.order_count)} 单<span class="item-sub">${money(user.total_spent)}</span></td>
      <td>${statusPill(user.is_active ? 'is-live' : 'is-off', user.is_active ? '启用' : '停用')}</td>
      <td><button class="row-btn" data-action="edit-user" data-id="${escapeHtml(user.id)}" type="button">编辑</button></td>
    </tr>
  `).join('') : '<tr><td colspan="6"><div class="empty-state">暂无用户</div></td></tr>'
}

async function loadContent() {
  await loadMeta()
  renderContent()
}

function renderContent() {
  const head = $('#contentHead')
  const body = $('#contentTable')

  if (state.contentKind === 'categories') {
    head.innerHTML = '<tr><th>分类</th><th>排序</th><th>内容</th><th>状态</th><th>操作</th></tr>'
    body.innerHTML = state.categories.map(category => `
      <tr>
        <td><div class="item-cell">${itemThumb(category.icon, category.name)}<strong>${escapeHtml(category.name)}</strong></div></td>
        <td>${escapeHtml(category.sort_order)}</td>
        <td>${escapeHtml(category.subcategory_count)} 子类<span class="item-sub">${escapeHtml(category.product_count)} 商品</span></td>
        <td>${statusPill(category.is_enabled ? 'is-live' : 'is-off', category.is_enabled ? '启用' : '停用')}</td>
        <td><button class="row-btn" data-action="edit-category" data-id="${escapeHtml(category.id)}" type="button">编辑</button></td>
      </tr>
    `).join('') || '<tr><td colspan="5"><div class="empty-state">暂无分类</div></td></tr>'
    return
  }

  if (state.contentKind === 'subcategories') {
    head.innerHTML = '<tr><th>子分类</th><th>所属分类</th><th>排序</th><th>商品</th><th>状态</th><th>操作</th></tr>'
    body.innerHTML = state.subcategories.map(sub => `
      <tr>
        <td><div class="item-cell">${itemThumb(sub.image, sub.name)}<strong>${escapeHtml(sub.name)}</strong></div></td>
        <td>${escapeHtml(sub.category_name || '-')}</td>
        <td>${escapeHtml(sub.sort_order)}</td>
        <td>${escapeHtml(sub.product_count)}</td>
        <td>${statusPill(sub.is_enabled ? 'is-live' : 'is-off', sub.is_enabled ? '启用' : '停用')}</td>
        <td><button class="row-btn" data-action="edit-subcategory" data-id="${escapeHtml(sub.id)}" type="button">编辑</button></td>
      </tr>
    `).join('') || '<tr><td colspan="6"><div class="empty-state">暂无子分类</div></td></tr>'
    return
  }

  head.innerHTML = '<tr><th>Banner</th><th>跳转</th><th>商品</th><th>排序</th><th>状态</th><th>操作</th></tr>'
  body.innerHTML = state.banners.map(banner => `
    <tr>
      <td><div class="item-cell">${itemThumb(banner.image, banner.title)}<div><strong class="item-title">${escapeHtml(banner.title || banner.tag || 'Banner')}</strong><span class="item-sub">${escapeHtml(banner.tag || '')}</span></div></div></td>
      <td>${escapeHtml(banner.link || '-')}</td>
      <td>${escapeHtml(banner.product_count)}</td>
      <td>${escapeHtml(banner.sort_order)}</td>
      <td>${statusPill(banner.is_enabled ? 'is-live' : 'is-off', banner.is_enabled ? '启用' : '停用')}</td>
      <td><button class="row-btn" data-action="edit-banner" data-id="${escapeHtml(banner.id)}" type="button">编辑</button></td>
    </tr>
  `).join('') || '<tr><td colspan="6"><div class="empty-state">暂无 Banner</div></td></tr>'
}

async function loadCoupons() {
  try {
    const params = new URLSearchParams()
    if (state.query) params.set('q', state.query)
    if (state.couponStatus) params.set('status', state.couponStatus)
    const data = await request('/api/admin/coupons/' + (params.toString() ? '?' + params : ''))
    state.coupons = data.items || []
    renderCoupons()
  } catch (err) {
    showToast(err.message)
  }
}

function renderCoupons() {
  $('#couponsTable').innerHTML = state.coupons.length ? state.coupons.map(coupon => `
    <tr>
      <td><strong>${escapeHtml(coupon.name)}</strong><span class="item-sub">减 ${escapeHtml(coupon.value)}</span></td>
      <td>${escapeHtml(coupon.username)}<span class="item-sub">ID ${escapeHtml(coupon.user_id)}</span></td>
      <td>${escapeHtml(coupon.threshold)}</td>
      <td>${escapeHtml(coupon.time || '-')}</td>
      <td>${statusPill(coupon.status)}</td>
      <td><button class="row-btn" data-action="edit-coupon" data-id="${escapeHtml(coupon.id)}" type="button">编辑</button></td>
    </tr>
  `).join('') : '<tr><td colspan="6"><div class="empty-state">暂无优惠券</div></td></tr>'
}

async function loadShop() {
  try {
    const shop = await request('/api/admin/shop/')
    const form = $('#shopForm')
    Object.entries(shop || {}).forEach(([key, value]) => {
      const field = form.elements[key]
      if (field) field.value = value ?? ''
    })
  } catch (err) {
    showToast(err.message)
  }
}

async function saveShop(event) {
  event.preventDefault()
  const values = Object.fromEntries(new FormData(event.currentTarget).entries())
  try {
    await request('/api/admin/shop/save/', { method: 'PATCH', ...jsonBody(values) })
    showToast('店铺资料已保存')
  } catch (err) {
    showToast(err.message)
  }
}

function handleAction(action, target) {
  const id = target.dataset.id
  const map = {
    'close-drawer': closeDrawer,
    'new-product': () => openProductDrawer(),
    'edit-product': () => openProductDrawer(state.products.find(item => String(item.id) === String(id))),
    'toggle-product': () => toggleProduct(id),
    'mark-paid': () => updateOrder(id, '/mark-paid/', '订单已标记支付'),
    'ship-order': () => openShipDrawer(id),
    'set-order-status': () => openOrderStatusDrawer(id),
    'after-sale': () => openAfterSaleDrawer(id),
    'edit-user': () => openUserDrawer(state.users.find(item => String(item.id) === String(id))),
    'new-content': () => openContentDrawer(),
    'edit-category': () => openCategoryDrawer(state.categories.find(item => String(item.id) === String(id))),
    'edit-subcategory': () => openSubcategoryDrawer(state.subcategories.find(item => String(item.id) === String(id))),
    'edit-banner': () => openBannerDrawer(state.banners.find(item => String(item.id) === String(id))),
    'new-coupon': () => openCouponDrawer(),
    'edit-coupon': () => openCouponDrawer(state.coupons.find(item => String(item.id) === String(id))),
  }
  map[action]?.()
}

function mediaOptions() {
  return [
    { value: '', label: '不设置图片' },
    ...state.media.map(item => ({ value: item.id, label: item.name || item.id })),
  ]
}

function categoryOptions() {
  return state.categories.map(item => ({ value: item.id, label: item.name }))
}

function subcategoryOptions() {
  return [
    { value: '', label: '未分类' },
    ...state.subcategories.map(item => ({ value: item.id, label: `${item.category_name} / ${item.name}` })),
  ]
}

function productOptions() {
  return state.products.map(item => ({ value: item.id, label: item.name }))
}

function openDrawer({ title, fields, submitLabel = '保存', onSubmit }) {
  $('#drawerTitle').textContent = title
  $('#drawerSubmit').textContent = submitLabel
  $('#drawerFields').innerHTML = fields.map(fieldHtml).join('')
  state.drawerSubmit = onSubmit
  $('#drawer').hidden = false
  document.body.classList.add('admin-locked')
}

function closeDrawer() {
  $('#drawer').hidden = true
  document.body.classList.remove('admin-locked')
  state.drawerSubmit = null
}

function fieldHtml(field) {
  const full = field.full ? ' drawer-field-full' : ''
  const value = field.value ?? ''
  if (field.type === 'checkbox') {
    return `
      <label class="admin-field checkbox${full}">
        <input data-field="${escapeHtml(field.name)}" type="checkbox" ${value ? 'checked' : ''}>
        <span>${escapeHtml(field.label)}</span>
      </label>
    `
  }
  if (field.type === 'textarea') {
    return `
      <label class="admin-field${full}">
        <span>${escapeHtml(field.label)}</span>
        <textarea data-field="${escapeHtml(field.name)}" rows="${field.rows || 4}">${escapeHtml(value)}</textarea>
      </label>
    `
  }
  if (field.type === 'select' || field.type === 'multiselect') {
    const selectedValues = Array.isArray(value) ? value.map(String) : [String(value)]
    return `
      <label class="admin-field${full}">
        <span>${escapeHtml(field.label)}</span>
        <select data-field="${escapeHtml(field.name)}" ${field.type === 'multiselect' ? 'multiple size="6"' : ''}>
          ${(field.options || []).map(option => `
            <option value="${escapeHtml(option.value)}" ${selectedValues.includes(String(option.value)) ? 'selected' : ''}>${escapeHtml(option.label)}</option>
          `).join('')}
        </select>
      </label>
    `
  }
  return `
    <label class="admin-field${full}">
      <span>${escapeHtml(field.label)}</span>
      <input data-field="${escapeHtml(field.name)}" type="${field.type || 'text'}" value="${escapeHtml(value)}" ${field.step ? `step="${escapeHtml(field.step)}"` : ''}>
    </label>
  `
}

function collectDrawerValues() {
  const values = {}
  $$('[data-field]', $('#drawerFields')).forEach(field => {
    const name = field.dataset.field
    if (field.type === 'checkbox') {
      values[name] = field.checked
    } else if (field.multiple) {
      values[name] = Array.from(field.selectedOptions).map(option => option.value)
    } else {
      values[name] = field.value
    }
  })
  return values
}

function openProductDrawer(product = null) {
  openDrawer({
    title: product ? '编辑商品' : '新增商品',
    fields: [
      { name: 'name', label: '商品名称', value: product?.name || '' },
      { name: 'tag', label: '标签', value: product?.tag || '' },
      { name: 'price', label: '售价', type: 'number', step: '0.01', value: product?.price || '' },
      { name: 'original_price', label: '划线价', type: 'number', step: '0.01', value: product?.original_price || '' },
      { name: 'sales_count', label: '销量', type: 'number', value: product?.sales_count || 0 },
      { name: 'rating', label: '评分', type: 'number', step: '0.1', value: product?.rating || '5.0' },
      { name: 'subcategory_id', label: '所属子分类', type: 'select', options: subcategoryOptions(), value: product?.subcategory_id || '' },
      { name: 'image_id', label: '商品图片', type: 'select', options: mediaOptions(), value: product?.image_id || '' },
      { name: 'is_in_stock', label: '商品上架', type: 'checkbox', value: product ? product.is_in_stock : true, full: true },
      { name: 'description', label: '商品描述', type: 'textarea', value: product?.description || '', full: true },
    ],
    submitLabel: product ? '保存商品' : '创建商品',
    onSubmit: async values => {
      const endpoint = product ? `/api/admin/products/${product.id}/` : '/api/admin/products/'
      const method = product ? 'PATCH' : 'POST'
      await request(endpoint, { method, ...jsonBody(values) })
      closeDrawer()
      await loadProducts()
      showToast(product ? '商品已保存' : '商品已创建')
    },
  })
}

async function toggleProduct(id) {
  try {
    await request(`/api/admin/products/${id}/toggle/`, { method: 'POST', ...jsonBody({}) })
    await loadProducts()
    showToast('商品状态已更新')
  } catch (err) {
    showToast(err.message)
  }
}

async function updateOrder(id, action, message, body = {}) {
  try {
    await request(`/api/admin/orders/${id}${action}`, { method: 'POST', ...jsonBody(body) })
    await loadOrders()
    showToast(message)
  } catch (err) {
    showToast(err.message)
  }
}

function openShipDrawer(id) {
  openDrawer({
    title: '订单发货',
    fields: [
      { name: 'carrier', label: '物流公司', value: '顺丰速运' },
      { name: 'tracking_number', label: '运单号', value: '' },
    ],
    submitLabel: '确认发货',
    onSubmit: async values => {
      await updateOrder(id, '/ship/', '订单已发货', values)
      closeDrawer()
    },
  })
}

function openOrderStatusDrawer(id) {
  openDrawer({
    title: '修改订单状态',
    fields: [
      {
        name: 'status',
        label: '订单状态',
        type: 'select',
        options: [
          { value: 'pending', label: '待付款' },
          { value: 'paid', label: '待发货' },
          { value: 'shipped', label: '待收货' },
          { value: 'completed', label: '已完成' },
          { value: 'cancelled', label: '已取消' },
        ],
      },
    ],
    submitLabel: '保存状态',
    onSubmit: async values => {
      await updateOrder(id, '/set-status/', '订单状态已更新', values)
      closeDrawer()
    },
  })
}

function openAfterSaleDrawer(id) {
  const order = state.orders.find(item => String(item.id) === String(id))
  openDrawer({
    title: '售后处理',
    fields: [
      {
        name: 'after_sale_status',
        label: '售后状态',
        type: 'select',
        value: order?.after_sale_status || 'none',
        options: [
          { value: 'none', label: '未申请' },
          { value: 'requested', label: '已申请' },
          { value: 'processing', label: '处理中' },
          { value: 'refunded', label: '已退款' },
          { value: 'rejected', label: '已拒绝' },
        ],
      },
      { name: 'after_sale_reason', label: '处理备注', type: 'textarea', value: order?.after_sale_reason || '', full: true },
    ],
    submitLabel: '保存售后',
    onSubmit: async values => {
      await updateOrder(id, '/after-sale/', '售后状态已更新', values)
      closeDrawer()
    },
  })
}

function openUserDrawer(user) {
  if (!user) return
  openDrawer({
    title: '编辑用户',
    fields: [
      { name: 'email', label: '邮箱', value: user.email || '' },
      { name: 'phone', label: '手机号', value: user.phone || '' },
      {
        name: 'vip_level',
        label: '会员等级',
        type: 'select',
        value: user.vip_level || 'none',
        options: [
          { value: 'none', label: '普通会员' },
          { value: 'bronze', label: '铜牌会员' },
          { value: 'silver', label: '银牌会员' },
          { value: 'gold', label: '黄金会员' },
          { value: 'diamond', label: '钻石会员' },
        ],
      },
      { name: 'points', label: '积分', type: 'number', value: user.points || 0 },
      { name: 'is_active', label: '账号启用', type: 'checkbox', value: user.is_active, full: true },
    ],
    submitLabel: '保存用户',
    onSubmit: async values => {
      await request(`/api/admin/users/${user.id}/`, { method: 'PATCH', ...jsonBody(values) })
      closeDrawer()
      await loadUsers()
      showToast('用户已保存')
    },
  })
}

function openContentDrawer() {
  if (state.contentKind === 'categories') return openCategoryDrawer()
  if (state.contentKind === 'subcategories') return openSubcategoryDrawer()
  return openBannerDrawer()
}

function openCategoryDrawer(category = null) {
  openDrawer({
    title: category ? '编辑一级分类' : '新增一级分类',
    fields: [
      { name: 'name', label: '分类名称', value: category?.name || '' },
      { name: 'sort_order', label: '排序', type: 'number', value: category?.sort_order || 0 },
      { name: 'icon_id', label: '分类图标', type: 'select', options: mediaOptions(), value: category?.icon_id || '' },
      { name: 'banner_id', label: '分类 Banner', type: 'select', options: mediaOptions(), value: category?.banner_id || '' },
      { name: 'is_enabled', label: '启用分类', type: 'checkbox', value: category ? category.is_enabled : true, full: true },
    ],
    submitLabel: '保存分类',
    onSubmit: async values => {
      const endpoint = category ? `/api/admin/categories/${category.id}/` : '/api/admin/categories/'
      await request(endpoint, { method: category ? 'PATCH' : 'POST', ...jsonBody(values) })
      closeDrawer()
      await loadContent()
      showToast('分类已保存')
    },
  })
}

function openSubcategoryDrawer(subcategory = null) {
  openDrawer({
    title: subcategory ? '编辑二级分类' : '新增二级分类',
    fields: [
      { name: 'name', label: '子分类名称', value: subcategory?.name || '' },
      { name: 'category_id', label: '所属一级分类', type: 'select', options: categoryOptions(), value: subcategory?.category_id || state.categories[0]?.id || '' },
      { name: 'sort_order', label: '排序', type: 'number', value: subcategory?.sort_order || 0 },
      { name: 'icon_id', label: '子分类图标', type: 'select', options: mediaOptions(), value: subcategory?.icon_id || '' },
      { name: 'is_enabled', label: '启用子分类', type: 'checkbox', value: subcategory ? subcategory.is_enabled : true, full: true },
    ],
    submitLabel: '保存子分类',
    onSubmit: async values => {
      const endpoint = subcategory ? `/api/admin/subcategories/${subcategory.id}/` : '/api/admin/subcategories/'
      await request(endpoint, { method: subcategory ? 'PATCH' : 'POST', ...jsonBody(values) })
      closeDrawer()
      await loadContent()
      showToast('子分类已保存')
    },
  })
}

function openBannerDrawer(banner = null) {
  openDrawer({
    title: banner ? '编辑 Banner' : '新增 Banner',
    fields: [
      { name: 'tag', label: '角标', value: banner?.tag || '' },
      { name: 'title', label: '主标题', value: banner?.title || '' },
      { name: 'action_title', label: '按钮文案', value: banner?.action_title || '' },
      { name: 'link', label: '跳转链接', value: banner?.link || 'category.html' },
      { name: 'landing_badge', label: '会场标识', value: banner?.landing_badge || '' },
      { name: 'landing_subtitle', label: '会场副标题', value: banner?.landing_subtitle || '' },
      { name: 'gradient_type', label: '色彩序号', type: 'number', value: banner?.gradient_type || 0 },
      { name: 'sort_order', label: '排序', type: 'number', value: banner?.sort_order || 0 },
      { name: 'image_id', label: 'Banner 图片', type: 'select', options: mediaOptions(), value: banner?.image_id || '' },
      { name: 'product_ids', label: '关联商品', type: 'multiselect', options: productOptions(), value: banner?.product_ids || [], full: true },
      { name: 'landing_description', label: '会场描述', type: 'textarea', value: banner?.landing_description || '', full: true },
      { name: 'is_enabled', label: '启用 Banner', type: 'checkbox', value: banner ? banner.is_enabled : true, full: true },
    ],
    submitLabel: '保存 Banner',
    onSubmit: async values => {
      const endpoint = banner ? `/api/admin/banners/${banner.id}/` : '/api/admin/banners/'
      await request(endpoint, { method: banner ? 'PATCH' : 'POST', ...jsonBody(values) })
      closeDrawer()
      await loadContent()
      showToast('Banner 已保存')
    },
  })
}

function openCouponDrawer(coupon = null) {
  openDrawer({
    title: coupon ? '编辑优惠券' : '发放优惠券',
    fields: [
      ...(coupon ? [] : [{ name: 'username', label: '用户名', value: '' }]),
      { name: 'name', label: '优惠券名称', value: coupon?.name || '专属优惠券' },
      { name: 'value', label: '优惠金额', type: 'number', value: coupon?.value || 20 },
      { name: 'threshold', label: '使用门槛', value: coupon?.threshold || '满100可用' },
      { name: 'time', label: '有效期', value: coupon?.time || '2026-12-31' },
      { name: 'status', label: '状态', type: 'select', value: coupon?.status || 'available', options: [
        { value: 'available', label: '可用' },
        { value: 'used', label: '已使用' },
        { value: 'expired', label: '已失效' },
      ] },
      { name: 'description', label: '说明', type: 'textarea', value: coupon?.description || '', full: true },
    ],
    submitLabel: coupon ? '保存优惠券' : '确认发券',
    onSubmit: async values => {
      const endpoint = coupon ? `/api/admin/coupons/${coupon.id}/` : '/api/admin/coupons/'
      await request(endpoint, { method: coupon ? 'PATCH' : 'POST', ...jsonBody(values) })
      closeDrawer()
      await loadCoupons()
      showToast(coupon ? '优惠券已保存' : '优惠券已发放')
    },
  })
}

if (token()) {
  showApp()
  bootstrap().catch(err => showToast(err.message))
} else {
  showLogin()
  bindChrome()
}
