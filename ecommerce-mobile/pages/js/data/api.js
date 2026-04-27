// API Configuration
const BASE_URL = 'https://handsome-youth-production-98c5.up.railway.app'

const getToken = () => localStorage.getItem('token') || ''
const setToken = (token) => localStorage.setItem('token', token)

const clearAuth = () => {
  localStorage.removeItem('token')
  location.href = 'login.html'
}

const request = (endpoint, options = {}) => {
  const url = BASE_URL + endpoint
  const token = getToken()
  const headers = { 'Content-Type': 'application/json' }
  if (token) headers['Authorization'] = 'Token ' + token

  return fetch(url, { headers: Object.assign(headers, options.headers), ...options })
    .then(res => {
      if (res.status === 401 || res.status === 403) {
        clearAuth()
        throw new Error('登录已过期，请重新登录')
      }
      const contentType = res.headers.get('content-type') || ''
      if (!contentType.includes('application/json')) {
        throw new Error('API returned non-JSON: ' + res.status)
      }
      return res.json()
    })
    .then(data => {
      if (data && data.code !== undefined) {
        if (data.code === 0) return data.data
        throw new Error(data.msg || 'API Error')
      }
      return data
    })
}

// Helper to convert static image path to full URL
const imgUrl = (path) => {
  if (!path) return ''
  if (path.startsWith('http')) return path
  // Convert ./static/images/xxx to http://localhost:8000/static/images/xxx
  if (path.startsWith('./static/')) {
    return BASE_URL + '/static/' + path.replace('./static/', '')
  }
  // Convert /media/xxx to http://localhost:8080/media/xxx
  if (path.startsWith('/media/')) {
    return BASE_URL + path
  }
  return path
}

const cartLS = {
  _load: () => { try { return JSON.parse(localStorage.getItem('cart')) || [] } catch { return [] } },
  _save: (v) => localStorage.setItem('cart', JSON.stringify(v)),
  _total: () => cartLS._load().reduce((s, i) => s + Number(i.price) * i.qty, 0),
}
const favLS = {
  _load: () => { try { return JSON.parse(localStorage.getItem('favorites')) || [] } catch { return [] } },
  _save: (v) => localStorage.setItem('favorites', JSON.stringify(v)),
}
const searchLS = {
  _load: () => { try { return JSON.parse(localStorage.getItem('searchHistory')) || [] } catch { return [] } },
  _save: (v) => localStorage.setItem('searchHistory', JSON.stringify(v)),
}

// ─── Mappers ───────────────────────────────────────────────

const mapProduct = (p) => ({
  id: p.id,
  name: p.name,
  price: p.price,
  original: p.original_price || p.originalPrice || p.price,
  img: imgUrl(p.image),
  desc: p.description || '',
  rating: p.rating || 0,
  reviewCount: p.review_count || p.reviewCount || 0,
  sales: p.sales_count || p.salesCount || 0,
  stock: p.is_in_stock ? 999 : 0,
  category: (p.subcategory && p.subcategory.name) || (p.category && p.category.name) || '',
  tag: p.tag || '',
})

const mapBanner = (b) => ({
  id: b.id,
  img: imgUrl(b.image),
  tag: b.tag || '',
  title: b.title || '',
  cta: b.action_title || b.actionTitle || '',
  gradientType: b.gradient_type || 0,
  link: b.link || 'category.html'
})

const mapFlashSale = (fs) => ({
  id: fs.id,
  title: fs.title || '',
  subtitle: fs.subtitle || '',
  startTime: fs.start_time,
  endTime: fs.end_time,
  products: (fs.products || []).map(mapProduct)
})

const mapHotRank = (hr) => ({
  id: hr.id,
  title: hr.title || '',
  products: (hr.products || []).map(mapProduct)
})

const mapRecommend = (rec) => ({
  id: rec.id,
  title: rec.title || '',
  products: (rec.products || []).map(mapProduct)
})

const mapNewArrival = (na) => ({
  id: na.id,
  title: na.title || '',
  products: (na.products || []).map(mapProduct)
})

const mapPromotion = (p) => ({
  id: p.id,
  title: p.title || '',
  subtitle: p.subtitle || '',
  img: imgUrl(p.image),
  link: p.link || ''
})

const mapCategory = (c) => ({
  id: c.id,
  name: c.name,
  icon: imgUrl(c.icon),
  banner: imgUrl(c.banner),
  link: 'category.html',
  subs: (c.subcategories || []).map(s => s.name),
  products: (c.products || []).map(mapProduct)
})

const mapSubcategory = (s) => ({
  id: s.id,
  name: s.name,
  icon: imgUrl(s.image),
  categoryId: s.category_id,
  products: (s.products || []).map(mapProduct)
})

const mapCartItem = (item) => ({
  cartId: item.id || '',
  id: (item.product && item.product.id) || item.productID || '',
  name: (item.product && item.product.name) || item.name || '',
  price: (item.product && item.product.price) || item.price || 0,
  original: (item.product && (item.product.original_price || item.product.originalPrice)) || item.price || 0,
  qty: item.quantity || 1,
  selected: item.is_selected !== undefined ? item.is_selected : (item.isSelected !== undefined ? item.isSelected : true),
  img: imgUrl(item.product && (item.product.image || item.product.imageName)),
  skuId: item.skuId || null,
  specValues: item.specValues || [],
})

const mapOrderProduct = (p) => ({
  name: p.name ?? '商品',
  spec: p.spec ?? '',
  price: Number(p.price) ?? 0,
  qty: p.quantity ?? 1,
  img: imgUrl(p.image ?? p.img ?? '')
})

const mapOrder = (o) => ({
  id: o.order_number ?? '',
  store: o.store ?? '潮流好物',
  status: o.status ?? 'pending',
  statusText: o.statusText ?? '',
  products: (o.products ?? o.items ?? []).map(mapOrderProduct),
  total: Number(o.total_amount ?? o.totalAmount ?? 0) || 0,
  payment: Number(o.payment ?? o.total_amount ?? 0) || 0,
  freight: Number(o.freight ?? 0) || 0,
  discount: Number(o.discount ?? 0) || 0,
  address: o.address ?? null,
  payTime: o.pay_time ? new Date(o.pay_time).toLocaleString('zh-CN') : '',
  createTime: o.created_at ? new Date(o.created_at).toLocaleString('zh-CN') : '',
})

const getStatusText = (status) => ({
  'pending': '待付款',
  'paid': '待发货',
  'shipped': '待收货',
  'completed': '已完成',
  'cancelled': '已取消'
}[status ?? ''] ?? status ?? '')

const mapAddress = (a) => ({
  id: a.id,
  name: a.name,
  phone: a.phone,
  province: a.province,
  city: a.city,
  district: a.district,
  detail: a.detail,
  isDefault: a.is_default || false
})

const mapCoupon = (c) => ({
  id: c.id,
  name: c.name,
  value: c.value,
  threshold: c.threshold,
  desc: c.description || c.desc || '',
  time: c.time
})

const mapNotification = (n) => ({
  id: n.id,
  type: n.type,
  name: n.name,
  time: n.time,
  content: n.content,
  action: n.action || ''
})

const mapFavorite = (f) => ({
  id: f.id,
  name: f.name,
  price: f.price,
  originalPrice: f.original_price || f.originalPrice,
  img: imgUrl(f.image),
  sales: f.sales || ''
})


const mapReview = (r) => ({
  id: r.id,
  userName: r.user_name || r.userName,
  userAvatar: imgUrl(r.user_avatar || r.userAvatar),
  rating: r.rating,
  content: r.content,
  spec: r.spec || '',
  images: (r.images || []).map(i => imgUrl(typeof i === 'string' ? i : i.img)),
  createdAt: r.created_at || r.createdAt
})

// ─── API ────────────────────────────────────────────────────

const api = {
  product: {
    getDetail: (id) => request('/api/h5/products/' + id + '/').then(p => p ? Object.assign(mapProduct(p), {
      images: (p.detail && p.detail.images) ? p.detail.images.map(i => imgUrl(i)) : [imgUrl(p.image)],
      detailImages: (p.detail && p.detail.detail_images) ? p.detail.detail_images.map(i => imgUrl(i)) : [],
      shop: (p.detail && p.detail.shop_name) || '潮流优品官方旗舰店',
      shopLogo: imgUrl(p.detail && p.detail.shop_logo) || imgUrl('./static/images/product-01-watch.webp'),
      specGroups: (p.spec_groups || p.specGroups || []).map(sg => ({
        id: sg.id, name: sg.name,
        values: (sg.values || []).map(sv => ({ id: sv.id, value: sv.value, imageName: imgUrl(sv.image || sv.image_name) }))
      })),
      skus: (p.skus || []).map(sku => ({
        id: sku.id, price: sku.price, originalPrice: sku.original_price || sku.originalPrice,
        stock: sku.stock, imageName: imgUrl(sku.image || sku.imageName), specValueIds: sku.spec_value_ids || sku.specValueIds || []
      })),
      stock: p.is_in_stock ? 999 : 0
    }) : null),

    getList: () => request('/api/h5/products/').then(ps => (ps || []).map(mapProduct)),
    getRelated: (id) => request('/api/h5/products/').then(ps => (ps || []).filter(p => p.id !== id).slice(0, 6).map(mapProduct)),
    getHome: () => request('/api/h5/products/').then(ps => (ps || []).slice(0, 10).map(mapProduct)),
    search: (keyword) => request('/api/h5/products/search/?q=' + encodeURIComponent(keyword)).then(ps => (ps || []).map(mapProduct)),
    getDesc: (name) => request('/api/h5/products/search/?q=' + encodeURIComponent(name)).then(ps => (ps && ps[0] && ps[0].description) || '优质商品，精选材质，简约设计，品质保障'),
    recommend: () => request('/api/h5/products/').then(ps => (ps || []).slice(0, 4).map(mapProduct)),
    getReviews: (productId) => request('/api/h5/products/' + productId + '/reviews/').then(res => (res.data || []).map(mapReview)),
    createReview: (productId, data) => request('/api/h5/products/' + productId + '/reviews/', {
      method: 'POST',
      body: JSON.stringify(data)
    }),
  },

  category: {
    getList: () => request('/api/h5/categories/').then(cs => (cs || []).map(mapCategory)),
    getProducts: (categoryId) => request('/api/h5/categories/' + categoryId + '/products/').then(ps => (ps || []).map(mapProduct)),
    getSubcategories: (categoryId) => request('/api/h5/categories/' + categoryId + '/subcategories/').then(scs => (scs || []).map(mapSubcategory)),
    getAllProducts: (categoryId) => request('/api/h5/categories/' + categoryId + '/all_products/').then(ps => (ps || []).map(mapProduct)),
  },

  subcategory: {
    getList: () => request('/api/h5/subcategories/').then(scs => (scs || []).map(mapSubcategory)),
    getProducts: (subcategoryId) => request('/api/h5/subcategories/' + subcategoryId + '/products/').then(ps => (ps || []).map(mapProduct)),
  },

  cart: {
    _load: () => [],
    _total: () => 0,

    getList: () => request('/api/h5/cart/').then(data => {
      const items = Array.isArray(data) ? data : (data && data.items) || []
      const total = (data && data.total) || 0
      return { items: items.map(mapCartItem), total }
    }),
    getTotal: () => request('/api/h5/cart/').then(data =>
      (Array.isArray(data) ? data : (data && data.items) || []).reduce((s, i) => s + ((i.product && (i.product.price || 0)) || 0) * (i.quantity || 0), 0)
    ),
    getCount: () => request('/api/h5/cart/').then(data =>
      (Array.isArray(data) ? data : (data && data.items) || []).reduce((s, i) => s + (i.quantity || 0), 0)
    ),

    addItem: ({ id, qty, skuId }) => request('/api/h5/cart/', {
      method: 'POST',
      body: JSON.stringify({ productId: id, quantity: qty || 1, skuId: skuId || '' })
    }),

    updateItem: (itemId, qty) => request('/api/h5/cart/' + itemId + '/', {
      method: 'PATCH',
      body: JSON.stringify({ quantity: qty })
    }),

    removeItem: (itemId) => request('/api/h5/cart/' + itemId + '/', { method: 'DELETE' }),

    toggleItem: (itemId) => request('/api/h5/cart/' + itemId + '/toggle/', { method: 'PATCH' }),

    selectAll: (selected) => request('/api/h5/cart/select-all/?selected=' + selected, { method: 'PUT' }),

    clear: () => request('/api/h5/cart/', { method: 'DELETE' }),
  },

  order: {
    getList: (status, page, limit) => {
      let url = '/api/h5/orders/'
      const params = new URLSearchParams()
      if (status) params.set('status', status)
      if (page) params.set('page', page)
      if (limit) params.set('limit', limit)
      const qs = params.toString()
      if (qs) url += '?' + qs
      return request(url).then(res => res)
    },
    getById: (id) => request('/api/h5/orders/' + id + '/').then(o => o ? mapOrder(o) : null),
    preview: ({ cartItemIds, addressId }) => request('/api/h5/orders/preview/', {
      method: 'POST',
      body: JSON.stringify({ cartItemIds, addressId })
    }),
    create: ({ cartItemIds, addressId, couponId, remark }) => request('/api/h5/orders/', {
      method: 'POST',
      body: JSON.stringify({ cartItemIds, addressId, couponId: couponId || undefined, remark: remark || '' })
    }),
    cancel: (id) => request('/api/h5/orders/' + id + '/cancel', { method: 'PUT' }),
    pay: (id) => request('/api/h5/orders/' + id + '/pay', { method: 'PUT' }),
    confirmReceipt: (id) => request('/api/h5/orders/' + id + '/confirm', { method: 'PUT' }),
  },

  address: {
    getList: () => request('/api/h5/addresses/').then(addrs => (addrs || []).map(mapAddress)),
    getById: (id) => request('/api/h5/addresses/' + id + '/').then(a => a ? mapAddress(a) : null),
    create: (data) => request('/api/h5/addresses/', {
      method: 'POST',
      body: JSON.stringify(data)
    }).then(() => ({ success: true })),
    update: (id, data) => request('/api/h5/addresses/' + id + '/', {
      method: 'PUT',
      body: JSON.stringify(data)
    }).then(() => ({ success: true })),
    delete: (id) => request('/api/h5/addresses/' + id + '/', { method: 'DELETE' }).then(() => ({ success: true })),
    setDefault: (id) => request('/api/h5/addresses/' + id + '/set_default/', { method: 'PUT' }).then(() => ({ success: true })),
    getRegion: () => request('/api/h5/addresses/region/').then(res => res || {}),
  },

  favorite: {
    getList: () => request('/api/h5/favorites/').then(favs => (favs || []).map(mapFavorite)),
    add: ({ id }) => request('/api/h5/favorites/', {
      method: 'POST',
      body: JSON.stringify({ productId: id })
    }).then(() => ({ success: true })),
    remove: (id) => request('/api/h5/favorites/' + id + '/', { method: 'DELETE' }).then(() => ({ success: true })),
  },

  
  coupon: {
    getList: () => request('/api/h5/coupons/').then(coupons => ({
      available: (coupons || []).map(mapCoupon),
      used: [],
      expired: []
    })),
  },

  notification: {
    getList: () => request('/api/h5/notifications/').then(notifs => (notifs || []).map(mapNotification)),
    getUnreadCount: () => request('/api/h5/notifications/count/').then(data => ({ count: (data && data.count) || 0 })),
    markRead: (id) => request('/api/h5/notifications/' + id + '/read/', { method: 'PUT' }).then(() => ({ success: true })),
    markAllRead: () => request('/api/h5/notifications/read_all/', { method: 'PUT' }).then(() => ({ success: true })),
  },

  checkout: {
    getAddresses: () => request('/api/h5/addresses/').then(addrs => (addrs || []).map(mapAddress)),
    getCoupons: () => request('/api/h5/coupons/').then(coupons => (coupons || []).map(c => ({
      id: c.id, name: c.name, discount: c.value, threshold: c.threshold,
      desc: c.description || c.desc || '', validUntil: c.time
    }))),
  },

  search: {
    getHistory: () => Promise.resolve(searchLS._load()),
    addHistory: (term) => {
      if (!term || !term.trim()) return Promise.resolve({ success: false })
      let h = searchLS._load().filter(t => t !== term)
      h.unshift(term)
      searchLS._save(h.slice(0, 20))
      return Promise.resolve({ success: true })
    },
    removeHistory: (term) => { searchLS._save(searchLS._load().filter(t => t !== term)); return Promise.resolve({ success: true }) },
    clearHistory: () => { searchLS._save([]); return Promise.resolve({ success: true }) },
    search: (keyword) => request('/api/h5/products/search/?q=' + encodeURIComponent(keyword)).then(ps => (ps || []).map(mapProduct)),
  },

  home: {
    // 新接口 - 独立模块
    getBanners: () => request('/api/h5/home/banners/').then(bs => (bs || []).map(mapBanner)),
    getCategories: () => request('/api/h5/categories/').then(cs => (cs || []).map(mapCategory)),
    getFlashSale: () => request('/api/h5/home/flash-sales/').then(data => (data || []).map(mapFlashSale)),
    getHotRank: () => request('/api/h5/home/hot-ranks/').then(data => (data || []).map(mapHotRank)),
    getRecommend: () => request('/api/h5/home/recommends/').then(data => (data || []).map(mapRecommend)),
    getNewArrival: () => request('/api/h5/home/new-arrivals/').then(data => (data || []).map(mapNewArrival)),
    getPromotions: () => request('/api/h5/home/promotions/').then(data => (data || []).map(mapPromotion)),
    // 获取所有首页数据
    getData: () => Promise.all([
      request('/api/h5/home/banners/'),
      request('/api/h5/categories/'),
      request('/api/h5/home/flash-sales/'),
      request('/api/h5/home/hot-ranks/'),
      request('/api/h5/home/recommends/'),
      request('/api/h5/home/new-arrivals/'),
      request('/api/h5/home/promotions/'),
    ]).then(([banners, categories, flashSales, hotRanks, recommends, newArrivals, promotions]) => ({
      banners: (banners || []).map(mapBanner),
      categories: (categories || []).map(mapCategory),
      flashSales: (flashSales || []).map(mapFlashSale),
      hotRanks: (hotRanks || []).map(mapHotRank),
      recommends: (recommends || []).map(mapRecommend),
      newArrivals: (newArrivals || []).map(mapNewArrival),
      promotions: (promotions || []).map(mapPromotion),
    })),
  },

  shop: {
    getInfo: () => Promise.resolve({
      name: '潮流优品官方旗舰店',
      logo: imgUrl('./static/images/product-01-watch.webp'),
      banner: imgUrl('./static/images/banner-1-summer-1710.webp'),
      desc: '专注品质生活，提供高性价比优质商品，正品保障',
      score: 4.9, productCount: 286, sales: '12.8万', fans: '56.2万',
    }),
    getProducts: () => request('/api/h5/products/').then(ps => (ps || []).map(p => ({
      id: p.id, name: p.name, price: p.price,
      original: p.original_price || p.originalPrice || p.price,
      img: imgUrl(p.image),
      sales: p.sales_count || p.salesCount || 0
    }))),
  },

  user: {
    loginH5: (username, password) => request('/api/h5/login/', {
      method: 'POST',
      body: JSON.stringify({ username, password })
    }).then(data => {
      if (data && data.token) setToken(data.token)
      return data
    }),
    loginIOS: (username, password) => request('/api/ios/login/', {
      method: 'POST',
      body: JSON.stringify({ username, password })
    }).then(data => {
      if (data && data.token) setToken(data.token)
      return data
    }),
    getInfo: () => request('/api/h5/user/profile/'),
  }
}

window.api = api
export { api, BASE_URL, request, clearAuth, imgUrl }
