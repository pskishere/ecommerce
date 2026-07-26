const TOKEN_KEY = 'ecommerce_admin_token'

export function getToken() {
  return localStorage.getItem(TOKEN_KEY) || ''
}

export function setToken(token) {
  localStorage.setItem(TOKEN_KEY, token)
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY)
}

export async function request(endpoint, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  }
  const token = getToken()
  if (token) headers.Authorization = `Token ${token}`

  const response = await fetch(endpoint, {
    ...options,
    headers,
  })

  const contentType = response.headers.get('content-type') || ''
  const payload = contentType.includes('application/json') ? await response.json() : null

  if (response.status === 401 || response.status === 403) {
    clearToken()
    throw new Error(payload?.msg || '管理员登录已过期')
  }

  if (!response.ok) {
    throw new Error(payload?.msg || `请求失败 ${response.status}`)
  }

  if (payload && payload.code !== undefined) {
    if (payload.code === 0) return payload.data
    throw new Error(payload.msg || '操作失败')
  }

  return payload
}

const json = (body) => ({
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
})

export const adminApi = {
  login: (username, password) => request('/api/admin/login/', {
    method: 'POST',
    ...json({ username, password }),
  }),
  overview: () => request('/api/admin/overview/'),
  media: () => request('/api/admin/media/'),

  products: (params = {}) => request(`/api/admin/products/?${new URLSearchParams(params)}`),
  createProduct: (payload) => request('/api/admin/products/', { method: 'POST', ...json(payload) }),
  updateProduct: (id, payload) => request(`/api/admin/products/${id}/`, { method: 'PATCH', ...json(payload) }),
  toggleProduct: (id) => request(`/api/admin/products/${id}/toggle/`, { method: 'POST', ...json({}) }),

  categories: () => request('/api/admin/categories/'),
  createCategory: (payload) => request('/api/admin/categories/', { method: 'POST', ...json(payload) }),
  updateCategory: (id, payload) => request(`/api/admin/categories/${id}/`, { method: 'PATCH', ...json(payload) }),

  subcategories: () => request('/api/admin/subcategories/'),
  createSubcategory: (payload) => request('/api/admin/subcategories/', { method: 'POST', ...json(payload) }),
  updateSubcategory: (id, payload) => request(`/api/admin/subcategories/${id}/`, { method: 'PATCH', ...json(payload) }),

  banners: () => request('/api/admin/banners/'),
  createBanner: (payload) => request('/api/admin/banners/', { method: 'POST', ...json(payload) }),
  updateBanner: (id, payload) => request(`/api/admin/banners/${id}/`, { method: 'PATCH', ...json(payload) }),

  orders: (params = {}) => request(`/api/admin/orders/?${new URLSearchParams(params)}`),
  markPaid: (id) => request(`/api/admin/orders/${id}/mark-paid/`, { method: 'POST', ...json({}) }),
  shipOrder: (id, payload) => request(`/api/admin/orders/${id}/ship/`, { method: 'POST', ...json(payload) }),
  setOrderStatus: (id, payload) => request(`/api/admin/orders/${id}/set-status/`, { method: 'POST', ...json(payload) }),
  updateAfterSale: (id, payload) => request(`/api/admin/orders/${id}/after-sale/`, { method: 'POST', ...json(payload) }),

  users: (params = {}) => request(`/api/admin/users/?${new URLSearchParams(params)}`),
  updateUser: (id, payload) => request(`/api/admin/users/${id}/`, { method: 'PATCH', ...json(payload) }),

  coupons: (params = {}) => request(`/api/admin/coupons/?${new URLSearchParams(params)}`),
  createCoupon: (payload) => request('/api/admin/coupons/', { method: 'POST', ...json(payload) }),
  updateCoupon: (id, payload) => request(`/api/admin/coupons/${id}/`, { method: 'PATCH', ...json(payload) }),

  shop: () => request('/api/admin/shop/'),
  saveShop: (payload) => request('/api/admin/shop/save/', { method: 'PATCH', ...json(payload) }),
}
