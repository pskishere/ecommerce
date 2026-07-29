import { useEffect, useMemo, useRef, useState } from 'react'
import * as echarts from 'echarts'
import {
  App as AntdApp,
  Avatar,
  Button,
  Descriptions,
  Drawer,
  Dropdown,
  Empty,
  Form,
  Input,
  InputNumber,
  Layout,
  Menu,
  Modal,
  Select,
  Segmented,
  Space,
  Spin,
  Switch,
  Table,
  Tag,
  Tooltip,
} from 'antd'
import {
  AppstoreOutlined,
  AudioOutlined,
  BarChartOutlined,
  CheckCircleOutlined,
  ClockCircleOutlined,
  CopyOutlined,
  DeleteOutlined,
  DownOutlined,
  EyeOutlined,
  FileOutlined,
  GiftOutlined,
  HomeOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  MoreOutlined,
  PictureOutlined,
  PlusOutlined,
  ReloadOutlined,
  SearchOutlined,
  ShopOutlined,
  ShoppingOutlined,
  TagsOutlined,
  TeamOutlined,
  TruckOutlined,
  UploadOutlined,
  VideoCameraOutlined,
} from '@ant-design/icons'
import { PageContainer, ProCard, ProTable, StatisticCard } from '@ant-design/pro-components'
import { adminApi, clearToken, getToken, setToken } from './api/admin'

const ACTIVE_VIEW_KEY = 'ecommerce_admin_active_view'
const SIDEBAR_COLLAPSED_KEY = 'ecommerce_admin_sidebar_collapsed'

const viewMeta = {
  dashboard: { kicker: '后台 / 概览', title: '经营概览', desc: '订单、商品、内容和库存的今日处理台' },
  products: { kicker: '后台 / 商品', title: '商品管理', desc: '维护商品资料、图片、规格、价格和库存' },
  orders: { kicker: '后台 / 订单', title: '订单履约', desc: '处理付款、发货、状态流转和售后' },
  users: { kicker: '后台 / 会员', title: '用户会员', desc: '维护账号状态、会员等级、积分和联系方式' },
  content: { kicker: '后台 / 内容', title: '首页内容', desc: '管理分类、Banner、首页栏目和促销位' },
  media: { kicker: '后台 / 资源', title: '资源管理', desc: '统一管理图片、视频、音频和文档' },
  coupons: { kicker: '后台 / 权益', title: '优惠券', desc: '发放、编辑和筛选用户优惠券' },
  shop: { kicker: '后台 / 店铺', title: '店铺设置', desc: '维护商城前台展示的店铺信息' },
}

const navItems = [
  { key: 'dashboard', label: '经营概览', icon: <BarChartOutlined /> },
  { key: 'products', label: '商品管理', icon: <ShoppingOutlined /> },
  { key: 'orders', label: '订单履约', icon: <TruckOutlined /> },
  { key: 'users', label: '用户会员', icon: <TeamOutlined /> },
  { key: 'content', label: '首页内容', icon: <AppstoreOutlined /> },
  { key: 'media', label: '资源管理', icon: <PictureOutlined /> },
  { key: 'coupons', label: '优惠券', icon: <GiftOutlined /> },
  { key: 'shop', label: '店铺设置', icon: <ShopOutlined /> },
]

const productStatusOptions = [
  { label: '全部', value: '' },
  { label: '上架', value: 'active' },
  { label: '下架', value: 'inactive' },
]

const productStockOptions = [
  { label: '低库存', value: 'low' },
]

const orderStatusOptions = [
  { label: '全部', value: '' },
  { label: '待付款', value: 'pending' },
  { label: '待发货', value: 'paid' },
  { label: '待收货', value: 'shipped' },
  { label: '已完成', value: 'completed' },
  { label: '售后', value: 'after_sale' },
]

const orderRawStatuses = [
  { label: '待付款', value: 'pending' },
  { label: '待发货', value: 'paid' },
  { label: '待收货', value: 'shipped' },
  { label: '已完成', value: 'completed' },
  { label: '已取消', value: 'cancelled' },
]

const afterSaleStatuses = [
  { label: '未申请', value: 'none' },
  { label: '已申请', value: 'requested' },
  { label: '处理中', value: 'processing' },
  { label: '已退款', value: 'refunded' },
  { label: '已拒绝', value: 'rejected' },
]

const contentKindOptions = [
  { label: '一级分类', value: 'categories' },
  { label: '二级分类', value: 'subcategories' },
  { label: '首页 Banner', value: 'banners' },
  { label: '限时秒杀', value: 'flashSales' },
  { label: '热销榜', value: 'hotRanks' },
  { label: '新品上市', value: 'newArrivals' },
  { label: '为你推荐', value: 'recommends' },
  { label: '促销位', value: 'promotions' },
]

const mediaKindOptions = [
  { label: '全部', value: '' },
  { label: '图片', value: 'image' },
  { label: '视频', value: 'video' },
  { label: '音频', value: 'audio' },
  { label: '文档', value: 'document' },
  { label: '未引用', value: 'unused' },
]

const couponStatusOptions = [
  { label: '全部', value: '' },
  { label: '可用', value: 'available' },
  { label: '已使用', value: 'used' },
  { label: '已失效', value: 'expired' },
]

const couponRawStatuses = [
  { label: '可用', value: 'available' },
  { label: '已使用', value: 'used' },
  { label: '已失效', value: 'expired' },
]

const vipLevels = [
  { label: '普通会员', value: 'none' },
  { label: '铜牌会员', value: 'bronze' },
  { label: '银牌会员', value: 'silver' },
  { label: '黄金会员', value: 'gold' },
  { label: '钻石会员', value: 'diamond' },
]

const homeProductSectionKinds = ['flashSales', 'hotRanks', 'recommends', 'newArrivals']

function money(value) {
  const number = Number(value || 0)
  return `¥${Number.isFinite(number) ? number.toFixed(2) : '0.00'}`
}

function formatNumber(value) {
  const number = Number(value || 0)
  return Number.isFinite(number) ? number.toLocaleString('zh-CN') : '0'
}

function sumBy(rows, getter) {
  return (rows || []).reduce((total, item) => total + Number(getter(item) || 0), 0)
}

function optionLabel(options, value) {
  return options.find((item) => item.value === value)?.label || ''
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

function statusColor(status) {
  return {
    pending: 'gold',
    paid: 'blue',
    shipped: 'cyan',
    completed: 'default',
    cancelled: 'red',
    requested: 'orange',
    processing: 'blue',
    refunded: 'default',
    rejected: 'red',
  }[status] || 'default'
}

function couponColor(status) {
  return {
    available: 'blue',
    used: 'default',
    expired: 'red',
  }[status] || 'default'
}

function isLowStockProduct(item) {
  return Number(item.low_stock_count || 0) > 0 || Number(item.stock_total || 0) <= 200
}

function fileSize(value) {
  const size = Number(value || 0)
  if (!Number.isFinite(size) || size <= 0) return '-'
  if (size >= 1024 * 1024) return `${(size / 1024 / 1024).toFixed(1)} MB`
  return `${Math.ceil(size / 1024)} KB`
}

function mediaKindLabel(kind) {
  return {
    image: '图片',
    video: '视频',
    audio: '音频',
    document: '文档',
    other: '文件',
  }[kind] || '文件'
}

function mediaIcon(kind) {
  return {
    image: <PictureOutlined />,
    video: <VideoCameraOutlined />,
    audio: <AudioOutlined />,
    document: <FileOutlined />,
    other: <FileOutlined />,
  }[kind] || <FileOutlined />
}

function addressText(order) {
  return [order.address_province, order.address_city, order.address_district, order.address_detail]
    .filter(Boolean)
    .join('')
}

function createEmptyMediaSummary(items = []) {
  return {
    total: items.length,
    images: items.filter((item) => item.kind === 'image').length,
    videos: items.filter((item) => item.kind === 'video').length,
    audios: items.filter((item) => item.kind === 'audio').length,
    documents: items.filter((item) => item.kind === 'document').length,
    unused: items.filter((item) => !item.usage_count).length,
    storage: sumBy(items, (item) => item.size),
  }
}

function normalizeMediaResponse(data) {
  if (Array.isArray(data)) {
    return { items: data, summary: createEmptyMediaSummary(data) }
  }
  const items = data?.items || []
  return {
    items,
    summary: {
      ...createEmptyMediaSummary(items),
      ...(data?.summary || {}),
    },
  }
}

function makeTempId(prefix) {
  return `${prefix}_${Date.now()}_${Math.random().toString(16).slice(2)}`
}

function cloneSpecGroups(groups = []) {
  return groups.map((group, groupIndex) => ({
    id: group.id || '',
    local_id: group.id || makeTempId('group'),
    name: group.name || '',
    sort_order: Number(group.sort_order ?? groupIndex),
    draft: '',
    values: (group.values || []).map((value, valueIndex) => ({
      id: value.id || '',
      client_id: value.client_id || value.id || makeTempId('value'),
      local_id: value.id || value.client_id || makeTempId('value'),
      value: value.value || '',
      image_id: value.image_id || '',
      sort_order: Number(value.sort_order ?? valueIndex),
    })),
  }))
}

function cloneSkus(skus = [], product = {}) {
  return skus.map((sku) => ({
    id: sku.id || '',
    spec_value_ids: [...(sku.spec_value_ids || [])],
    spec_text: sku.spec_text || '',
    price: Number(sku.price || product.price || 0),
    original_price: Number(sku.original_price || product.original_price || 0),
    stock: Number(sku.stock || 0),
    image_id: sku.image_id || '',
  }))
}

function buildCombinations(groups) {
  return groups
    .reduce((rows, group) => {
      const values = group.values.filter((item) => item.value?.trim())
      return rows.flatMap((row) => values.map((value) => ({
        ids: [...row.ids, value.id || value.client_id],
        labels: [...row.labels, value.value],
      })))
    }, [{ ids: [], labels: [] }])
    .map((row) => ({ ...row, text: row.labels.join(' / ') }))
}

function skuKey(ids) {
  return (ids || []).join('|')
}

function rebuildSkuRows(form) {
  const groups = (form.spec_groups || []).filter((group) => group.name?.trim() && group.values?.length)
  if (!groups.length || groups.some((group) => !group.values.length)) {
    return { ...form, skus: [] }
  }

  const existing = new Map((form.skus || []).map((sku) => [skuKey(sku.spec_value_ids), sku]))
  const combinations = buildCombinations(groups)
  return {
    ...form,
    skus: combinations.map((combo) => {
      const old = existing.get(skuKey(combo.ids))
      return {
        id: old?.id || '',
        spec_value_ids: combo.ids,
        spec_text: combo.text,
        price: Number(old?.price ?? form.price ?? 0),
        original_price: Number(old?.original_price ?? form.original_price ?? 0),
        stock: Number(old?.stock ?? 99),
        image_id: old?.image_id || '',
      }
    }),
  }
}

function buildProductPayload(form) {
  return {
    id: form.id,
    name: form.name,
    description: form.description,
    tag: form.tag,
    price: form.price,
    original_price: form.original_price || '',
    sales_count: form.sales_count,
    rating: form.rating,
    subcategory_id: form.subcategory_id,
    image_id: form.image_id,
    is_in_stock: form.is_in_stock,
    spec_groups: (form.spec_groups || []).map((group, groupIndex) => ({
      id: group.id || '',
      name: group.name,
      sort_order: groupIndex,
      values: (group.values || []).map((value, valueIndex) => ({
        id: value.id || '',
        client_id: value.client_id || value.id || '',
        value: value.value,
        image_id: value.image_id || '',
        sort_order: valueIndex,
      })),
    })),
    skus: (form.skus || []).map((sku) => ({
      id: sku.id || '',
      spec_value_ids: sku.spec_value_ids || [],
      price: sku.price,
      original_price: sku.original_price || '',
      stock: sku.stock,
      image_id: sku.image_id || '',
    })),
  }
}

function Thumb({ src, wide = false, small = false, className = '' }) {
  const [failed, setFailed] = useState(false)
  if (!src || failed) {
    return (
      <div className={`thumb ${wide ? 'wide' : ''} ${small ? 'small' : ''} fallback ${className}`}>
        <PictureOutlined />
      </div>
    )
  }
  return (
    <div className={`thumb ${wide ? 'wide' : ''} ${small ? 'small' : ''} ${className}`}>
      <img src={src} alt="" onError={() => setFailed(true)} />
    </div>
  )
}

function StatusTag({ status }) {
  return <Tag color={statusColor(status)}>{statusText(status)}</Tag>
}

function CouponTag({ status }) {
  return <Tag color={couponColor(status)}>{statusText(status)}</Tag>
}

function StatStrip({ items }) {
  return (
    <div className="stat-strip">
      {items.map((item) => (
        <button
          key={item.label}
          className="stat-button"
          type="button"
          disabled={!item.action}
          onClick={item.action}
        >
          <span>{item.label}</span>
          <strong>{item.value}</strong>
          <em>{item.hint}</em>
        </button>
      ))}
    </div>
  )
}

function SectionHero({ title, desc, stats }) {
  return (
    <ProCard className="section-hero" bordered>
      <div className="section-hero-copy">
        <h3>{title}</h3>
        <span>{desc}</span>
      </div>
      <StatStrip items={stats} />
    </ProCard>
  )
}

function EmptyAction({ description, children }) {
  return (
    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description={description}>
      <Space wrap>{children}</Space>
    </Empty>
  )
}

function ProductCell({ row }) {
  return (
    <div className="entity-cell">
      <Thumb src={row.image} />
      <div>
        <strong>{row.name}</strong>
        <span>{row.tag || '无标签'} · {row.sku_count || 0} SKU · 库存 {row.stock_total ?? 0}</span>
      </div>
    </div>
  )
}

function ProductAvatars({ products = [], count = 0 }) {
  return (
    <div className="product-avatar-row">
      <Avatar.Group max={{ count: 4 }}>
        {(products || []).slice(0, 4).map((item) => (
          <Avatar key={item.id} shape="square" src={item.image} />
        ))}
      </Avatar.Group>
      <span>{count} 个商品</span>
    </div>
  )
}

export default function App() {
  const { message, modal } = AntdApp.useApp()
  const initialMobile = typeof window !== 'undefined' && window.innerWidth <= 920
  const [isAuthed, setIsAuthed] = useState(Boolean(getToken()))
  const [activeView, setActiveView] = useState(localStorage.getItem(ACTIVE_VIEW_KEY) || 'dashboard')
  const [collapsed, setCollapsed] = useState(initialMobile || localStorage.getItem(SIDEBAR_COLLAPSED_KEY) === 'true')
  const [mobileNavOpen, setMobileNavOpen] = useState(false)
  const [isMobile, setIsMobile] = useState(initialMobile)
  const [loading, setLoading] = useState(false)
  const [lastSyncedAt, setLastSyncedAt] = useState(null)
  const [keyword, setKeyword] = useState('')

  const [loginForm, setLoginForm] = useState({ username: 'admin', password: 'iole' })
  const [dashboard, setDashboard] = useState({
    metrics: {},
    orderStatus: {},
    salesTrend: [],
    contentHealth: {},
    recentOrders: [],
    topProducts: [],
    lowStockProducts: [],
  })
  const [products, setProducts] = useState([])
  const [orders, setOrders] = useState([])
  const [users, setUsers] = useState([])
  const [coupons, setCoupons] = useState([])
  const [categories, setCategories] = useState([])
  const [subcategories, setSubcategories] = useState([])
  const [banners, setBanners] = useState([])
  const [homeFlashSales, setHomeFlashSales] = useState([])
  const [homeHotRanks, setHomeHotRanks] = useState([])
  const [homeRecommends, setHomeRecommends] = useState([])
  const [homeNewArrivals, setHomeNewArrivals] = useState([])
  const [promotions, setPromotions] = useState([])
  const [media, setMedia] = useState([])
  const [mediaSummary, setMediaSummary] = useState(createEmptyMediaSummary())
  const [shopForm, setShopForm] = useState({})

  const [productStatus, setProductStatus] = useState('')
  const [productCategory, setProductCategory] = useState('')
  const [productStock, setProductStock] = useState('')
  const [orderStatus, setOrderStatus] = useState('')
  const [couponStatus, setCouponStatus] = useState('')
  const [contentKind, setContentKind] = useState('categories')
  const [mediaKind, setMediaKind] = useState('')
  const [selectedProducts, setSelectedProducts] = useState([])

  const [productDrawer, setProductDrawer] = useState(false)
  const [productForm, setProductForm] = useState({})
  const [contentDrawer, setContentDrawer] = useState(false)
  const [contentForm, setContentForm] = useState({})
  const [orderDrawer, setOrderDrawer] = useState(false)
  const [orderAction, setOrderAction] = useState('')
  const [editingOrderId, setEditingOrderId] = useState('')
  const [orderForm, setOrderForm] = useState({})
  const [orderDetailDrawer, setOrderDetailDrawer] = useState(false)
  const [orderDetail, setOrderDetail] = useState(null)
  const [userDrawer, setUserDrawer] = useState(false)
  const [userForm, setUserForm] = useState({})
  const [couponDrawer, setCouponDrawer] = useState(false)
  const [couponForm, setCouponForm] = useState({})
  const [mediaPreview, setMediaPreview] = useState(null)
  const [mediaRename, setMediaRename] = useState(null)
  const [mediaRenameValue, setMediaRenameValue] = useState('')

  const mediaInputRef = useRef(null)
  const orderChartRef = useRef(null)
  const salesChartRef = useRef(null)
  const orderChart = useRef(null)
  const salesChart = useRef(null)

  const currentMeta = viewMeta[activeView] || viewMeta.dashboard
  const searchable = ['products', 'orders', 'users', 'media', 'coupons'].includes(activeView)
  const formattedLastSynced = lastSyncedAt
    ? lastSyncedAt.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
    : ''
  const isHomeProductSection = homeProductSectionKinds.includes(contentKind)
  const currentContentLabel = optionLabel(contentKindOptions, contentKind) || '内容'
  const contentPrimaryLabel = `新增${currentContentLabel}`
  const currentHomeSections = {
    flashSales: homeFlashSales,
    hotRanks: homeHotRanks,
    recommends: homeRecommends,
    newArrivals: homeNewArrivals,
  }[contentKind] || []
  const currentContentRows = {
    categories,
    subcategories,
    banners,
    flashSales: homeFlashSales,
    hotRanks: homeHotRanks,
    recommends: homeRecommends,
    newArrivals: homeNewArrivals,
    promotions,
  }[contentKind] || []
  const mediaImageOptions = media.filter((item) => item.kind === 'image' || (item.mime_type || '').startsWith('image/'))

  const productFilterLabel = useMemo(() => {
    const parts = []
    const status = optionLabel(productStatusOptions, productStatus)
    if (status && status !== '全部') parts.push(status)
    const category = categories.find((item) => item.id === productCategory)?.name
    if (category) parts.push(category)
    const stock = optionLabel(productStockOptions, productStock)
    if (stock) parts.push(stock)
    return parts.length ? parts.join(' / ') : '全部商品'
  }, [categories, productCategory, productStatus, productStock])

  const orderFilterLabel = optionLabel(orderStatusOptions, orderStatus) || '全部订单'
  const couponFilterLabel = optionLabel(couponStatusOptions, couponStatus) || '全部优惠券'
  const hasProductFilters = Boolean(keyword.trim() || productStatus || productCategory || productStock)
  const hasOrderFilters = Boolean(keyword.trim() || orderStatus)
  const hasUserFilters = Boolean(keyword.trim())
  const hasMediaFilters = Boolean(keyword.trim() || mediaKind)
  const hasCouponFilters = Boolean(keyword.trim() || couponStatus)

  const metrics = [
    { title: '营业额', value: money(dashboard.metrics.revenue), description: 'GMV' },
    { title: '订单数', value: formatNumber(dashboard.metrics.orders || 0), description: `${dashboard.metrics.paid_orders || 0} 待发货` },
    { title: '上架商品', value: formatNumber(dashboard.metrics.active_products || 0), description: `${dashboard.metrics.products || 0} 总商品` },
    { title: '会员用户', value: formatNumber(dashboard.metrics.users || 0), description: `${dashboard.metrics.coupons || 0} 张券` },
  ]

  const productSummaryCards = [
    { label: '当前结果', value: formatNumber(products.length), hint: productFilterLabel },
    { label: '上架商品', value: formatNumber(products.filter((item) => item.is_in_stock).length), hint: '可售状态', action: () => openProductFilter({ status: 'active' }) },
    { label: '低库存', value: formatNumber(products.filter(isLowStockProduct).length), hint: '需要补货', action: openInventoryRisk },
    { label: '库存合计', value: formatNumber(sumBy(products, (item) => item.stock_total)), hint: '当前结果' },
  ]

  const orderSummaryCards = [
    { label: '当前订单', value: formatNumber(orders.length), hint: orderFilterLabel },
    { label: '待付款', value: formatNumber(dashboard.metrics.pending_orders || 0), hint: '需要催付', action: () => openOrderQueue('pending') },
    { label: '待发货', value: formatNumber(dashboard.metrics.paid_orders || 0), hint: '尽快履约', action: () => openOrderQueue('paid') },
    { label: '售后', value: formatNumber(dashboard.metrics.after_sale_orders || 0), hint: '需要处理', action: () => openOrderQueue('after_sale') },
  ]

  const userSummaryCards = [
    { label: '当前用户', value: formatNumber(users.length), hint: '列表结果' },
    { label: '启用账号', value: formatNumber(users.filter((item) => item.is_active).length), hint: '可登录' },
    { label: '会员用户', value: formatNumber(users.filter((item) => item.vip_level && item.vip_level !== 'none').length), hint: '非普通等级' },
    { label: '消费合计', value: money(sumBy(users, (item) => item.total_spent)), hint: '累计贡献' },
  ]

  const contentSummaryCards = [
    { label: '当前模块', value: currentContentLabel, hint: '正在维护' },
    { label: '当前内容', value: formatNumber(currentContentRows.length), hint: '列表结果' },
    { label: '已启用', value: formatNumber(currentContentRows.filter((item) => item.is_enabled !== false).length), hint: '前台可见' },
    { label: '关联商品', value: formatNumber(sumBy(currentContentRows, (item) => item.product_count)), hint: '内容绑定' },
  ]

  const mediaSummaryCards = [
    { label: '资源总数', value: formatNumber(mediaSummary.total), hint: fileSize(mediaSummary.storage) },
    { label: '图片', value: formatNumber(mediaSummary.images), hint: '可用于商品和内容', action: () => openMediaKind('image') },
    { label: '视频 / 音频', value: `${formatNumber(mediaSummary.videos)} / ${formatNumber(mediaSummary.audios)}`, hint: '展示与介绍素材' },
    { label: '未引用', value: formatNumber(mediaSummary.unused), hint: '可清理资源', action: () => openMediaKind('unused') },
  ]

  const couponSummaryCards = [
    { label: '当前优惠券', value: formatNumber(coupons.length), hint: couponFilterLabel },
    { label: '可用', value: formatNumber(coupons.filter((item) => item.status === 'available').length), hint: '可核销', action: () => openCouponQueue('available') },
    { label: '已使用', value: formatNumber(coupons.filter((item) => item.status === 'used').length), hint: '已核销', action: () => openCouponQueue('used') },
    { label: '面额合计', value: `¥${formatNumber(sumBy(coupons, (item) => item.value))}`, hint: '当前结果' },
  ]

  const shopSummaryCards = [
    { label: '店铺评分', value: shopForm.score || '-', hint: '前台展示' },
    { label: '商品数', value: formatNumber(shopForm.product_count || 0), hint: '展示口径' },
    { label: '销售额', value: shopForm.sales || '-', hint: '展示文本' },
    { label: '粉丝数', value: shopForm.fans_count || '-', hint: '展示文本' },
  ]

  useEffect(() => {
    const syncViewport = () => {
      const next = window.innerWidth <= 920
      setIsMobile(next)
      if (next) setCollapsed(true)
    }
    syncViewport()
    window.addEventListener('resize', syncViewport)
    return () => window.removeEventListener('resize', syncViewport)
  }, [])

  useEffect(() => {
    localStorage.setItem(SIDEBAR_COLLAPSED_KEY, collapsed ? 'true' : 'false')
    window.setTimeout(() => {
      orderChart.current?.resize()
      salesChart.current?.resize()
    }, 180)
  }, [collapsed])

  useEffect(() => {
    if (isAuthed) bootstrap()
    return () => {
      orderChart.current?.dispose()
      salesChart.current?.dispose()
      orderChart.current = null
      salesChart.current = null
    }
  }, [isAuthed])

  useEffect(() => {
    if (activeView !== 'dashboard') return
    const timer = window.setTimeout(renderDashboardCharts, 80)
    return () => window.clearTimeout(timer)
  }, [activeView, dashboard])

  async function run(task, silent = false) {
    setLoading(true)
    try {
      return await task()
    } catch (error) {
      if (!silent) message.error(error.message || '操作失败')
      if (error.message?.includes('登录')) setIsAuthed(false)
      return undefined
    } finally {
      setLoading(false)
    }
  }

  async function login() {
    if (!loginForm.username || !loginForm.password) {
      message.warning('请输入管理员账号和密码')
      return
    }
    await run(async () => {
      const data = await adminApi.login(loginForm.username, loginForm.password)
      setToken(data.token)
      setIsAuthed(true)
      message.success('已进入后台')
    })
  }

  function logout() {
    closeFloatingPanels()
    clearToken()
    setIsAuthed(false)
    setActiveView('dashboard')
    setKeyword('')
  }

  async function bootstrap() {
    await run(async () => {
      await loadMeta()
      await loadView(activeView, { q: keyword })
    }, true)
  }

  async function loadMeta() {
    const [categoryData, subcategoryData, mediaData, productData] = await Promise.all([
      adminApi.categories(),
      adminApi.subcategories(),
      adminApi.media(),
      adminApi.products(),
    ])
    const normalized = normalizeMediaResponse(mediaData)
    setCategories(categoryData || [])
    setSubcategories(subcategoryData || [])
    setMedia(normalized.items)
    setMediaSummary(normalized.summary)
    setProducts(productData?.items || [])
  }

  async function switchView(view) {
    closeFloatingPanels()
    setActiveView(view)
    localStorage.setItem(ACTIVE_VIEW_KEY, view)
    setKeyword('')
    setMobileNavOpen(false)
    await loadView(view, { q: '' })
  }

  function closeFloatingPanels() {
    setProductDrawer(false)
    setContentDrawer(false)
    setOrderDrawer(false)
    setOrderDetailDrawer(false)
    setUserDrawer(false)
    setCouponDrawer(false)
    setMediaPreview(null)
    setMediaRename(null)
  }

  async function loadCurrentView() {
    await loadView(activeView, { q: keyword })
  }

  async function loadView(view, overrides = {}) {
    const result = await run(async () => {
      if (view === 'dashboard') return loadDashboard()
      if (view === 'products') return loadProducts(overrides)
      if (view === 'orders') return loadOrders(overrides)
      if (view === 'users') return loadUsers(overrides)
      if (view === 'content') return loadContent(contentKind)
      if (view === 'media') return loadMedia(overrides)
      if (view === 'coupons') return loadCoupons(overrides)
      if (view === 'shop') return loadShop()
      return loadDashboard()
    })
    setLastSyncedAt(new Date())
    return result
  }

  async function loadDashboard() {
    const data = await adminApi.overview()
    setDashboard({
      metrics: data.metrics || {},
      orderStatus: data.order_status || {},
      salesTrend: data.sales_trend || [],
      contentHealth: data.content_health || {},
      recentOrders: data.recent_orders || [],
      topProducts: data.top_products || [],
      lowStockProducts: data.low_stock_products || [],
    })
  }

  async function loadProducts(overrides = {}) {
    const data = await adminApi.products({
      q: overrides.q ?? keyword,
      status: overrides.status ?? productStatus,
      category: overrides.category ?? productCategory,
      stock: overrides.stock ?? productStock,
    })
    setProducts(data.items || [])
    setSelectedProducts([])
  }

  async function loadOrders(overrides = {}) {
    const data = await adminApi.orders({ q: overrides.q ?? keyword, status: overrides.status ?? orderStatus })
    setOrders(data.items || [])
  }

  async function loadUsers(overrides = {}) {
    const data = await adminApi.users({ q: overrides.q ?? keyword })
    setUsers(data.items || [])
  }

  async function loadContent(kind = contentKind) {
    if (kind === 'categories') setCategories(await adminApi.categories())
    else if (kind === 'subcategories') setSubcategories(await adminApi.subcategories())
    else if (kind === 'banners') setBanners(await adminApi.banners())
    else if (kind === 'flashSales') setHomeFlashSales(await adminApi.homeFlashSales())
    else if (kind === 'hotRanks') setHomeHotRanks(await adminApi.homeHotRanks())
    else if (kind === 'recommends') setHomeRecommends(await adminApi.homeRecommends())
    else if (kind === 'newArrivals') setHomeNewArrivals(await adminApi.homeNewArrivals())
    else if (kind === 'promotions') setPromotions(await adminApi.homePromotions())
  }

  async function loadMedia(overrides = {}) {
    const data = await adminApi.media({ q: overrides.q ?? keyword, kind: overrides.kind ?? mediaKind })
    const normalized = normalizeMediaResponse(data)
    setMedia(normalized.items)
    setMediaSummary(normalized.summary)
    return normalized
  }

  async function loadCoupons(overrides = {}) {
    const data = await adminApi.coupons({ q: overrides.q ?? keyword, status: overrides.status ?? couponStatus })
    setCoupons(data.items || [])
  }

  async function loadShop() {
    const data = await adminApi.shop()
    setShopForm({
      ...data,
      score: Number(data?.score || 0),
      product_count: Number(data?.product_count || 0),
    })
  }

  function renderDashboardCharts() {
    if (!orderChartRef.current || !salesChartRef.current) return
    orderChart.current ||= echarts.init(orderChartRef.current)
    salesChart.current ||= echarts.init(salesChartRef.current)
    const orderData = orderRawStatuses.map((item) => ({
      name: item.label,
      value: dashboard.orderStatus[item.value] || 0,
    }))
    const rows = dashboard.salesTrend || []
    orderChart.current.setOption({
      color: ['#3f6588', '#7891a7', '#ad8b63', '#b8c4cf', '#d9dee5'],
      tooltip: { trigger: 'item' },
      legend: { bottom: 0, icon: 'circle' },
      series: [{
        type: 'pie',
        radius: ['48%', '72%'],
        center: ['50%', '43%'],
        minAngle: 6,
        label: { formatter: '{b} {c}' },
        data: orderData,
      }],
    })
    salesChart.current.setOption({
      color: ['#3f6588', '#a9785f'],
      tooltip: { trigger: 'axis' },
      grid: { left: 42, right: 18, top: 28, bottom: 34 },
      legend: { top: 0, right: 4 },
      xAxis: {
        type: 'category',
        boundaryGap: false,
        data: rows.map((item) => item.label),
        axisLine: { lineStyle: { color: '#dbe2ea' } },
        axisTick: { show: false },
      },
      yAxis: [
        { type: 'value', name: 'GMV', splitLine: { lineStyle: { color: '#edf1f5' } } },
        { type: 'value', name: '订单', splitLine: { show: false } },
      ],
      series: [
        {
          name: 'GMV',
          type: 'line',
          smooth: true,
          areaStyle: { color: 'rgba(63, 101, 136, 0.1)' },
          data: rows.map((item) => Number(item.revenue || 0)),
        },
        {
          name: '订单',
          type: 'bar',
          yAxisIndex: 1,
          barWidth: 16,
          data: rows.map((item) => Number(item.orders || 0)),
        },
      ],
    })
    orderChart.current.resize()
    salesChart.current.resize()
  }

  async function handleSearch(value) {
    setKeyword(value)
    await loadView(activeView, { q: value })
  }

  async function resetProductFilters() {
    setKeyword('')
    setProductStatus('')
    setProductCategory('')
    setProductStock('')
    setSelectedProducts([])
    await loadView('products', { q: '', status: '', category: '', stock: '' })
  }

  async function resetOrderFilters() {
    setKeyword('')
    setOrderStatus('')
    await loadView('orders', { q: '', status: '' })
  }

  async function resetUserFilters() {
    setKeyword('')
    await loadView('users', { q: '' })
  }

  async function resetMediaFilters() {
    setKeyword('')
    setMediaKind('')
    await loadView('media', { q: '', kind: '' })
  }

  async function resetCouponFilters() {
    setKeyword('')
    setCouponStatus('')
    await loadView('coupons', { q: '', status: '' })
  }

  async function openOrderQueue(status) {
    setOrderStatus(status)
    await switchView('orders')
    await loadView('orders', { q: '', status })
  }

  async function openProductFilter({ status = '', stock = '', category = '' } = {}) {
    setProductStatus(status)
    setProductStock(stock)
    setProductCategory(category)
    await switchView('products')
    await loadView('products', { q: '', status, stock, category })
  }

  async function openInventoryRisk() {
    await openProductFilter({ status: 'active', stock: 'low' })
  }

  async function openCouponQueue(status) {
    setCouponStatus(status)
    await switchView('coupons')
    await loadView('coupons', { q: '', status })
  }

  async function openContentHealth(kind = 'banners') {
    setContentKind(kind)
    await switchView('content')
    await loadContent(kind)
  }

  async function openMediaKind(kind) {
    setMediaKind(kind)
    await switchView('media')
    await loadView('media', { q: '', kind })
  }

  async function handleQuickCreate({ key }) {
    if (key === 'product') {
      await switchView('products')
      openProduct()
    } else if (key === 'banner') {
      setContentKind('banners')
      await switchView('content')
      await loadContent('banners')
      openContent('banners')
    } else if (key === 'coupon') {
      await switchView('coupons')
      openCoupon()
    } else if (key === 'media') {
      await switchView('media')
      window.setTimeout(() => mediaInputRef.current?.click(), 80)
    }
  }

  function openProduct(row = null) {
    setProductForm({
      id: row?.id || '',
      name: row?.name || '',
      description: row?.description || '',
      tag: row?.tag || '',
      price: Number(row?.price || 0),
      original_price: Number(row?.original_price || 0),
      sales_count: Number(row?.sales_count || 0),
      rating: Number(row?.rating || 5),
      subcategory_id: row?.subcategory_id || '',
      image_id: row?.image_id || '',
      is_in_stock: row ? Boolean(row.is_in_stock) : true,
      spec_groups: cloneSpecGroups(row?.spec_groups || []),
      skus: cloneSkus(row?.skus || [], row || {}),
    })
    setProductDrawer(true)
  }

  async function saveProduct() {
    await run(async () => {
      if (!productForm.name?.trim()) throw new Error('商品名称不能为空')
      const payload = buildProductPayload(productForm)
      if (productForm.id) await adminApi.updateProduct(productForm.id, payload)
      else await adminApi.createProduct(payload)
      setProductDrawer(false)
      await loadProducts()
      await loadDashboard()
      message.success('商品已保存')
    })
  }

  function addSpecGroup() {
    setProductForm((form) => ({
      ...form,
      spec_groups: [
        ...(form.spec_groups || []),
        { id: '', local_id: makeTempId('group'), name: '', sort_order: (form.spec_groups || []).length, draft: '', values: [] },
      ],
    }))
  }

  function removeSpecGroup(index) {
    setProductForm((form) => rebuildSkuRows({
      ...form,
      spec_groups: (form.spec_groups || []).filter((_, idx) => idx !== index),
    }))
  }

  function updateSpecGroup(index, patch, shouldRebuild = false) {
    setProductForm((form) => {
      const next = {
        ...form,
        spec_groups: (form.spec_groups || []).map((group, idx) => (idx === index ? { ...group, ...patch } : group)),
      }
      return shouldRebuild ? rebuildSkuRows(next) : next
    })
  }

  function addSpecValue(groupIndex) {
    setProductForm((form) => {
      const groups = [...(form.spec_groups || [])]
      const group = groups[groupIndex]
      const text = (group?.draft || '').trim()
      if (!text || group.values.some((item) => item.value === text)) {
        groups[groupIndex] = { ...group, draft: '' }
        return { ...form, spec_groups: groups }
      }
      const clientId = makeTempId('value')
      groups[groupIndex] = {
        ...group,
        draft: '',
        values: [
          ...group.values,
          { id: clientId, client_id: clientId, local_id: clientId, value: text, image_id: '', sort_order: group.values.length },
        ],
      }
      return rebuildSkuRows({ ...form, spec_groups: groups })
    })
  }

  function removeSpecValue(groupIndex, valueIndex) {
    setProductForm((form) => {
      const groups = (form.spec_groups || []).map((group, idx) => {
        if (idx !== groupIndex) return group
        return { ...group, values: group.values.filter((_, valueIdx) => valueIdx !== valueIndex) }
      })
      return rebuildSkuRows({ ...form, spec_groups: groups })
    })
  }

  function updateSku(index, patch) {
    setProductForm((form) => ({
      ...form,
      skus: (form.skus || []).map((sku, idx) => (idx === index ? { ...sku, ...patch } : sku)),
    }))
  }

  async function toggleProduct(row) {
    await run(async () => {
      await adminApi.toggleProduct(row.id)
      await loadProducts()
      await loadDashboard()
      message.success(row.is_in_stock ? '商品已下架' : '商品已上架')
    })
  }

  function bulkSetProductStatus(isInStock) {
    if (!selectedProducts.length) return
    const actionText = isInStock ? '上架' : '下架'
    modal.confirm({
      title: `确认${actionText}选中的 ${selectedProducts.length} 个商品？`,
      okText: actionText,
      cancelText: '取消',
      onOk: async () => {
        await run(async () => {
          await adminApi.bulkProductStatus(selectedProducts.map((item) => item.id), isInStock)
          await loadProducts()
          await loadDashboard()
          message.success(`已批量${actionText}`)
        })
      },
    })
  }

  function openContent(kind = contentKind, row = null) {
    const defaults = {
      categories: {
        id: row?.id || '',
        name: row?.name || '',
        sort_order: Number(row?.sort_order || 0),
        icon_id: row?.icon_id || '',
        banner_id: row?.banner_id || '',
        is_enabled: row ? Boolean(row.is_enabled) : true,
      },
      subcategories: {
        id: row?.id || '',
        name: row?.name || '',
        category_id: row?.category_id || categories[0]?.id || '',
        sort_order: Number(row?.sort_order || 0),
        icon_id: row?.icon_id || '',
        is_enabled: row ? Boolean(row.is_enabled) : true,
      },
      banners: {
        id: row?.id || '',
        tag: row?.tag || '',
        title: row?.title || '',
        action_title: row?.action_title || '',
        link: row?.link || 'category.html',
        landing_badge: row?.landing_badge || '',
        landing_subtitle: row?.landing_subtitle || '',
        landing_description: row?.landing_description || '',
        gradient_type: Number(row?.gradient_type || 0),
        sort_order: Number(row?.sort_order || 0),
        image_id: row?.image_id || '',
        product_ids: row?.product_ids || [],
        is_enabled: row ? Boolean(row.is_enabled) : true,
      },
      promotions: {
        id: row?.id || '',
        title: row?.title || '优惠活动',
        subtitle: row?.subtitle || '',
        link: row?.link || 'category.html',
        image_id: row?.image_id || '',
        sort_order: Number(row?.sort_order || 0),
        is_enabled: row ? Boolean(row.is_enabled) : true,
      },
    }
    const homeDefaults = {
      flashSales: '限时秒杀',
      hotRanks: '热销榜单',
      recommends: '为你推荐',
      newArrivals: '新品上市',
    }
    if (homeProductSectionKinds.includes(kind)) {
      setContentForm({
        id: row?.id || '',
        title: row?.title || homeDefaults[kind] || '',
        subtitle: row?.subtitle || '',
        start_time: row?.start_time || '',
        end_time: row?.end_time || '',
        sort_order: Number(row?.sort_order || 0),
        product_ids: row?.product_ids || [],
        is_enabled: row ? Boolean(row.is_enabled) : true,
      })
    } else {
      setContentForm(defaults[kind] || {})
    }
    setContentDrawer(true)
  }

  async function saveContent() {
    await run(async () => {
      if (contentKind === 'categories') {
        if (!contentForm.name?.trim()) throw new Error('分类名称不能为空')
        contentForm.id ? await adminApi.updateCategory(contentForm.id, contentForm) : await adminApi.createCategory(contentForm)
      } else if (contentKind === 'subcategories') {
        if (!contentForm.name?.trim() || !contentForm.category_id) throw new Error('子分类名称和所属分类不能为空')
        contentForm.id ? await adminApi.updateSubcategory(contentForm.id, contentForm) : await adminApi.createSubcategory(contentForm)
      } else if (contentKind === 'banners') {
        contentForm.id ? await adminApi.updateBanner(contentForm.id, contentForm) : await adminApi.createBanner(contentForm)
      } else if (homeProductSectionKinds.includes(contentKind)) {
        if (!contentForm.title?.trim()) throw new Error('栏目标题不能为空')
        const apiMap = {
          flashSales: [adminApi.createHomeFlashSale, adminApi.updateHomeFlashSale],
          hotRanks: [adminApi.createHomeHotRank, adminApi.updateHomeHotRank],
          recommends: [adminApi.createHomeRecommend, adminApi.updateHomeRecommend],
          newArrivals: [adminApi.createHomeNewArrival, adminApi.updateHomeNewArrival],
        }
        const [createFn, updateFn] = apiMap[contentKind]
        contentForm.id ? await updateFn(contentForm.id, contentForm) : await createFn(contentForm)
      } else if (contentKind === 'promotions') {
        if (!contentForm.title?.trim()) throw new Error('促销位标题不能为空')
        contentForm.id ? await adminApi.updateHomePromotion(contentForm.id, contentForm) : await adminApi.createHomePromotion(contentForm)
      }
      setContentDrawer(false)
      await loadContent(contentKind)
      await loadDashboard()
      message.success('内容已保存')
    })
  }

  async function uploadMediaFromInput(event) {
    const files = Array.from(event.target.files || [])
    event.target.value = ''
    if (!files.length) return
    await run(async () => {
      for (const file of files) {
        if (file.size > 20 * 1024 * 1024) throw new Error(`${file.name} 超过 20MB`)
        const dataUrl = await fileToDataUrl(file)
        await adminApi.uploadMedia({ file: dataUrl, name: file.name })
      }
      await loadMedia({ q: activeView === 'media' ? keyword : '', kind: activeView === 'media' ? mediaKind : '' })
      message.success(files.length > 1 ? `已上传 ${files.length} 个资源` : '资源已上传')
    })
  }

  function fileToDataUrl(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => resolve(reader.result)
      reader.onerror = () => reject(new Error('素材读取失败'))
      reader.readAsDataURL(file)
    })
  }

  async function copyMediaUrl(row) {
    if (!row.url) return
    try {
      await navigator.clipboard?.writeText(row.url)
      message.success('资源链接已复制')
    } catch {
      message.warning('浏览器不允许直接复制，请在预览里打开资源')
    }
  }

  async function saveMediaRename() {
    if (!mediaRename || !mediaRenameValue.trim()) {
      message.warning('名称不能为空')
      return
    }
    await run(async () => {
      await adminApi.updateMedia(mediaRename.id, { name: mediaRenameValue.trim() })
      await loadMedia()
      setMediaRename(null)
      setMediaRenameValue('')
      message.success('资源已重命名')
    })
  }

  function deleteMedia(row) {
    const force = Number(row.usage_count || 0) > 0
    modal.confirm({
      title: '删除资源',
      content: force
        ? `该资源仍被引用 ${row.usage_count} 次，删除后相关位置可能失去图片或文件。确认删除？`
        : `确认删除资源「${row.name}」？`,
      okText: '删除',
      okButtonProps: { danger: true },
      cancelText: '取消',
      onOk: async () => {
        await run(async () => {
          await adminApi.deleteMedia(row.id, force)
          await loadMedia()
          if (mediaPreview?.id === row.id) setMediaPreview(null)
          message.success('资源已删除')
        })
      },
    })
  }

  async function markPaid(row) {
    await run(async () => {
      await adminApi.markPaid(row.id)
      await loadOrders()
      await refreshOrderDetail(row.id)
      await loadDashboard()
      message.success('订单已标记支付')
    })
  }

  function openShip(row) {
    setEditingOrderId(row.id)
    setOrderAction('ship')
    setOrderForm({ carrier: row.carrier || '顺丰速运', tracking_number: row.tracking_number || '' })
    setOrderDrawer(true)
  }

  function openOrderStatus(row) {
    setEditingOrderId(row.id)
    setOrderAction('status')
    setOrderForm({ status: row.status })
    setOrderDrawer(true)
  }

  function openAfterSale(row) {
    setEditingOrderId(row.id)
    setOrderAction('afterSale')
    setOrderForm({
      after_sale_status: row.after_sale_status || 'none',
      after_sale_reason: row.after_sale_reason || '',
    })
    setOrderDrawer(true)
  }

  async function saveOrderAction() {
    await run(async () => {
      if (orderAction === 'ship') await adminApi.shipOrder(editingOrderId, orderForm)
      else if (orderAction === 'status') await adminApi.setOrderStatus(editingOrderId, orderForm)
      else await adminApi.updateAfterSale(editingOrderId, orderForm)
      setOrderDrawer(false)
      await loadOrders()
      await refreshOrderDetail(editingOrderId)
      await loadDashboard()
      message.success('订单已更新')
    })
  }

  async function openOrderDetail(row) {
    await run(async () => {
      setOrderDetail(await adminApi.order(row.id))
      setOrderDetailDrawer(true)
    })
  }

  async function refreshOrderDetail(id) {
    if (orderDetailDrawer && orderDetail?.id === id) {
      setOrderDetail(await adminApi.order(id))
    }
  }

  function openUser(row) {
    setUserForm({
      id: row.id,
      email: row.email || '',
      phone: row.phone || '',
      vip_level: row.vip_level || 'none',
      points: Number(row.points || 0),
      is_active: Boolean(row.is_active),
    })
    setUserDrawer(true)
  }

  async function saveUser() {
    await run(async () => {
      await adminApi.updateUser(userForm.id, userForm)
      setUserDrawer(false)
      await loadUsers()
      message.success('用户已保存')
    })
  }

  function openCoupon(row = null) {
    setCouponForm({
      id: row?.id || '',
      username: row?.username || '',
      name: row?.name || '专属优惠券',
      value: Number(row?.value || 20),
      threshold: row?.threshold || '满100可用',
      time: row?.time || '2026-12-31',
      status: row?.status || 'available',
      description: row?.description || '',
    })
    setCouponDrawer(true)
  }

  async function saveCoupon() {
    await run(async () => {
      if (!couponForm.id && !couponForm.username?.trim()) throw new Error('请输入发券用户名')
      couponForm.id ? await adminApi.updateCoupon(couponForm.id, couponForm) : await adminApi.createCoupon(couponForm)
      setCouponDrawer(false)
      await loadCoupons()
      await loadDashboard()
      message.success(couponForm.id ? '优惠券已保存' : '优惠券已发放')
    })
  }

  async function saveShop() {
    await run(async () => {
      await adminApi.saveShop(shopForm)
      message.success('店铺资料已保存')
    })
  }

  const headerExtra = [
    searchable && (
      <Input.Search
        key="search"
        className="header-search"
        allowClear
        prefix={<SearchOutlined />}
        value={keyword}
        placeholder="搜索当前模块"
        onChange={(event) => setKeyword(event.target.value)}
        onSearch={handleSearch}
      />
    ),
    formattedLastSynced && <Tag key="sync" className="sync-tag">已同步 {formattedLastSynced}</Tag>,
    <Dropdown
      key="quick"
      trigger={['click']}
      menu={{
        items: [
          { key: 'product', label: '新增商品', icon: <ShoppingOutlined /> },
          { key: 'banner', label: '新增 Banner', icon: <HomeOutlined /> },
          { key: 'coupon', label: '发放优惠券', icon: <GiftOutlined /> },
          { key: 'media', label: '上传资源', icon: <UploadOutlined /> },
        ],
        onClick: handleQuickCreate,
      }}
    >
      <Button type="primary">快速新建 <DownOutlined /></Button>
    </Dropdown>,
    <Tooltip key="refresh" title="刷新当前模块">
      <Button icon={<ReloadOutlined />} onClick={loadCurrentView} />
    </Tooltip>,
    <Button key="logout" onClick={logout}>退出</Button>,
  ].filter(Boolean)

  const navMenu = (
    <Menu
      mode="inline"
      selectedKeys={[activeView]}
      items={navItems}
      onClick={({ key }) => switchView(key)}
    />
  )

  if (!isAuthed) {
    return (
      <section className="login-page">
        <ProCard className="login-card" bordered>
          <div className="login-head">
            <span>管理后台</span>
            <h1>潮流好物后台</h1>
            <p>商品、订单、内容和会员在这里处理。</p>
          </div>
          <Form layout="vertical" onFinish={login}>
            <Form.Item label="管理员账号">
              <Input
                size="large"
                autoComplete="username"
                value={loginForm.username}
                onChange={(event) => setLoginForm((form) => ({ ...form, username: event.target.value }))}
              />
            </Form.Item>
            <Form.Item label="密码">
              <Input.Password
                size="large"
                autoComplete="current-password"
                value={loginForm.password}
                onChange={(event) => setLoginForm((form) => ({ ...form, password: event.target.value }))}
              />
            </Form.Item>
            <Button type="primary" htmlType="submit" size="large" block loading={loading}>
              进入后台
            </Button>
          </Form>
        </ProCard>
      </section>
    )
  }

  return (
    <Layout className="admin-shell">
      {!isMobile && (
        <Layout.Sider
          className="admin-sider"
          width={248}
          collapsedWidth={72}
          collapsible
          trigger={null}
          collapsed={collapsed}
        >
          <div className="sider-title">
            {!collapsed && (
              <>
                <strong>潮流好物</strong>
                <span>管理台</span>
              </>
            )}
          </div>
          {navMenu}
          <a className="front-link" href="http://localhost:3000/index.html" target="_blank" rel="noreferrer">
            <ShopOutlined />
            {!collapsed && <span>打开商城前台</span>}
          </a>
        </Layout.Sider>
      )}
      <Drawer
        className="mobile-nav-drawer"
        placement="left"
        width={280}
        title="潮流好物管理台"
        open={mobileNavOpen}
        onClose={() => setMobileNavOpen(false)}
      >
        {navMenu}
      </Drawer>
      <Layout className="admin-content-layout">
        <header className="top-header">
          <Button
            icon={isMobile || collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => (isMobile ? setMobileNavOpen(true) : setCollapsed((value) => !value))}
          />
          <div className="top-header-title">
            <span>{currentMeta.kicker}</span>
            <h2>{currentMeta.title}</h2>
          </div>
          <div className="top-header-actions">{headerExtra}</div>
        </header>
        <Layout.Content>
          <Spin spinning={loading} wrapperClassName="content-spin">
            <PageContainer
              className="page-container"
              title={currentMeta.title}
              subTitle={currentMeta.desc}
              breadcrumb={{ items: [{ title: '后台' }, { title: currentMeta.title }] }}
            >
              {renderActiveView()}
            </PageContainer>
          </Spin>
        </Layout.Content>
      </Layout>

      <input
        ref={mediaInputRef}
        className="hidden-file-input"
        type="file"
        multiple
        accept="image/*,video/*,audio/*,application/pdf,text/plain,.csv,.json"
        onChange={uploadMediaFromInput}
      />

      {renderProductDrawer()}
      {renderContentDrawer()}
      {renderOrderActionDrawer()}
      {renderOrderDetailDrawer()}
      {renderUserDrawer()}
      {renderCouponDrawer()}
      {renderMediaModals()}
    </Layout>
  )

  function renderActiveView() {
    if (activeView === 'dashboard') return renderDashboard()
    if (activeView === 'products') return renderProducts()
    if (activeView === 'orders') return renderOrders()
    if (activeView === 'users') return renderUsers()
    if (activeView === 'content') return renderContent()
    if (activeView === 'media') return renderMedia()
    if (activeView === 'coupons') return renderCoupons()
    if (activeView === 'shop') return renderShop()
    return renderDashboard()
  }

  function renderDashboard() {
    const quickActions = [
      { label: '待发货', value: formatNumber(dashboard.metrics.paid_orders || 0), hint: '进入履约队列', action: () => openOrderQueue('paid') },
      { label: '售后', value: formatNumber(dashboard.metrics.after_sale_orders || 0), hint: '处理退款/拒绝', action: () => openOrderQueue('after_sale') },
      { label: '低库存', value: formatNumber(dashboard.metrics.low_stock_products || 0), hint: '补库存', action: openInventoryRisk },
      { label: '内容项', value: formatNumber((dashboard.contentHealth.enabled_banners || 0) + (dashboard.contentHealth.enabled_home_sections || 0)), hint: '维护首页展示', action: () => openContentHealth('banners') },
    ]
    const todoCards = [
      { label: '待付款订单', value: formatNumber(dashboard.metrics.pending_orders || 0), hint: '催付或取消', action: () => openOrderQueue('pending') },
      { label: '待发货订单', value: formatNumber(dashboard.metrics.paid_orders || 0), hint: '尽快履约', action: () => openOrderQueue('paid') },
      { label: '售后处理', value: formatNumber(dashboard.metrics.after_sale_orders || 0), hint: '退款/拒绝', action: () => openOrderQueue('after_sale') },
      { label: '低库存商品', value: formatNumber(dashboard.metrics.low_stock_products || 0), hint: '补库存', action: openInventoryRisk },
    ]
    return (
      <div className="view-stack">
        <ProCard className="dashboard-brief" bordered>
          <div>
            <span className="eyebrow">经营中台</span>
            <h3>今日重点</h3>
            <p>先处理待发货、售后和低库存，再维护首页内容。</p>
          </div>
          <StatStrip items={quickActions} />
        </ProCard>

        <div className="metric-grid">
          {metrics.map((metric) => (
            <StatisticCard
              key={metric.title}
              className="metric-card"
              statistic={{ title: metric.title, value: metric.value, description: metric.description }}
            />
          ))}
        </div>

        <div className="two-col-grid">
          <ProCard title="7 天销售趋势" bordered extra={<Tag>订单 / GMV</Tag>}>
            <div ref={salesChartRef} className="chart-box compact" />
          </ProCard>
          <ProCard title="运营待办" bordered extra={<Button type="link" onClick={loadDashboard}>刷新</Button>}>
            <StatStrip items={todoCards} />
          </ProCard>
        </div>

        <div className="two-col-grid">
          <ProCard title="订单状态" bordered extra={<Tag>实时</Tag>}>
            <div ref={orderChartRef} className="chart-box" />
          </ProCard>
          <ProCard title="热卖商品" bordered extra={<Button type="link" onClick={() => switchView('products')}>管理商品</Button>}>
            <div className="rank-list">
              {dashboard.topProducts.length ? dashboard.topProducts.map((item) => (
                <div key={item.id} className="rank-item">
                  <Thumb src={item.image} />
                  <div>
                    <strong>{item.name}</strong>
                    <span>{item.category_name || item.subcategory_name || '未分类'} · {item.sales_count} 销量</span>
                  </div>
                </div>
              )) : <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无热卖商品" />}
            </div>
          </ProCard>
        </div>

        <ProCard title="最近订单" bordered extra={<Button type="link" onClick={() => switchView('orders')}>查看全部</Button>}>
          <Table
            rowKey="id"
            dataSource={dashboard.recentOrders}
            pagination={false}
            size="middle"
            columns={[
              { title: '订单号', dataIndex: 'id', width: 190 },
              { title: '用户', render: (_, row) => row.user?.username || '-' },
              { title: '金额', width: 120, render: (_, row) => money(row.payment || row.total_amount) },
              { title: '状态', width: 110, render: (_, row) => <StatusTag status={row.status} /> },
              { title: '创建时间', dataIndex: 'created_display', width: 170 },
            ]}
          />
        </ProCard>

        <div className="two-col-grid">
          <ProCard title="库存预警" bordered extra={<Button type="link" onClick={openInventoryRisk}>查看低库存</Button>}>
            <div className="rank-list">
              {dashboard.lowStockProducts.length ? dashboard.lowStockProducts.map((item) => (
                <div key={item.id} className="rank-item">
                  <Thumb src={item.image} />
                  <div>
                    <strong>{item.name}</strong>
                    <span>{item.category_name || item.subcategory_name || '未分类'} · 库存 {item.stock_total}</span>
                  </div>
                  <Button type="link" onClick={() => openProduct(item)}>补货</Button>
                </div>
              )) : <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无低库存商品" />}
            </div>
          </ProCard>
          <ProCard title="内容健康度" bordered extra={<Button type="link" onClick={() => openContentHealth('banners')}>管理首页</Button>}>
            <StatStrip items={[
              { label: '启用 Banner', value: dashboard.contentHealth.enabled_banners || 0, hint: '前台可见', action: () => openContentHealth('banners') },
              { label: '启用分类', value: dashboard.contentHealth.enabled_categories || 0, hint: '分类入口', action: () => openContentHealth('categories') },
              { label: '首页栏目', value: dashboard.contentHealth.enabled_home_sections || 0, hint: '运营位', action: () => openContentHealth('flashSales') },
              { label: '素材文件', value: dashboard.contentHealth.media_files || 0, hint: '资源库', action: () => switchView('media') },
            ]} />
          </ProCard>
        </div>
      </div>
    )
  }

  function renderProducts() {
    const columns = [
      { title: '商品', dataIndex: 'name', width: 320, fixed: 'left', render: (_, row) => <ProductCell row={row} /> },
      { title: '分类', width: 190, render: (_, row) => `${row.category_name || '-'} / ${row.subcategory_name || '-'}` },
      { title: '价格', width: 120, render: (_, row) => money(row.price) },
      { title: '销量', dataIndex: 'sales_count', width: 100, sorter: (a, b) => Number(a.sales_count || 0) - Number(b.sales_count || 0) },
      {
        title: '库存',
        width: 120,
        sorter: (a, b) => Number(a.stock_total || 0) - Number(b.stock_total || 0),
        render: (_, row) => (
          <div className={isLowStockProduct(row) ? 'danger-text' : ''}>
            <strong>{row.stock_total ?? 0}</strong>
            {Number(row.low_stock_count || 0) > 0 && <span>{row.low_stock_count} 个低库存</span>}
          </div>
        ),
      },
      { title: '状态', width: 100, render: (_, row) => <Tag color={row.is_in_stock ? 'blue' : 'red'}>{row.is_in_stock ? '上架' : '下架'}</Tag> },
      {
        title: '操作',
        width: 88,
        fixed: 'right',
        render: (_, row) => (
          <Dropdown
            trigger={['click']}
            menu={{
              items: [
                { key: 'edit', label: '编辑商品' },
                { key: 'toggle', label: row.is_in_stock ? '下架商品' : '上架商品', danger: row.is_in_stock },
              ],
              onClick: ({ key }) => (key === 'edit' ? openProduct(row) : toggleProduct(row)),
            }}
          >
            <Button icon={<MoreOutlined />} />
          </Dropdown>
        ),
      },
    ]
    return (
      <div className="view-stack">
        <SectionHero title="商品库" desc="上下架、库存和规格维护" stats={productSummaryCards} />
        <div className="toolbar product-toolbar">
          <Space wrap>
            <Segmented
              value={productStatus}
              options={productStatusOptions}
              onChange={(value) => {
                setProductStatus(value)
                loadProducts({ status: value })
              }}
            />
            <Select
              allowClear
              className="toolbar-select"
              placeholder="按分类筛选"
              value={productCategory || undefined}
              options={categories.map((item) => ({ label: item.name, value: item.id }))}
              onChange={(value = '') => {
                setProductCategory(value)
                loadProducts({ category: value })
              }}
            />
            <Select
              allowClear
              className="toolbar-select small"
              placeholder="库存筛选"
              value={productStock || undefined}
              options={productStockOptions}
              onChange={(value = '') => {
                setProductStock(value)
                loadProducts({ stock: value })
              }}
            />
          </Space>
          <Space wrap>
            <Dropdown
              disabled={!selectedProducts.length}
              menu={{
                items: [
                  { key: 'active', label: '批量上架' },
                  { key: 'inactive', label: '批量下架' },
                ],
                onClick: ({ key }) => bulkSetProductStatus(key === 'active'),
              }}
            >
              <Button disabled={!selectedProducts.length}>
                批量操作{selectedProducts.length ? ` · ${selectedProducts.length}` : ''} <DownOutlined />
              </Button>
            </Dropdown>
            {hasProductFilters && <Button icon={<ReloadOutlined />} onClick={resetProductFilters}>重置筛选</Button>}
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openProduct()}>新增商品</Button>
          </Space>
        </div>
        {selectedProducts.length > 0 && (
          <div className="selection-bar">
            <span>已选 <strong>{selectedProducts.length}</strong> 个商品</span>
            <Button type="link" onClick={() => setSelectedProducts([])}>清除选择</Button>
          </div>
        )}
        <ProTable
          rowKey="id"
          cardBordered
          search={false}
          options={false}
          pagination={false}
          dataSource={products}
          columns={columns}
          scroll={{ x: 1100, y: 'calc(100vh - 430px)' }}
          rowSelection={{ selectedRowKeys: selectedProducts.map((item) => item.id), onChange: (_, rows) => setSelectedProducts(rows) }}
          locale={{
            emptyText: (
              <EmptyAction description={hasProductFilters ? '没有匹配的商品' : '暂无商品，先新增一个商品'}>
                {hasProductFilters && <Button onClick={resetProductFilters}>清空筛选</Button>}
                <Button type="primary" icon={<PlusOutlined />} onClick={() => openProduct()}>新增商品</Button>
              </EmptyAction>
            ),
          }}
          headerTitle={<span>商品列表</span>}
          toolBarRender={() => [<Tag key="filter">{productFilterLabel}</Tag>]}
        />
      </div>
    )
  }

  function renderOrders() {
    const columns = [
      { title: '订单号', dataIndex: 'id', width: 190, fixed: 'left' },
      { title: '用户', width: 130, render: (_, row) => row.user?.username || '-' },
      {
        title: '商品',
        width: 250,
        render: (_, row) => (
          <div className="stack-text">
            <strong>{row.products?.[0]?.name || '无商品'}</strong>
            <span>共 {row.item_count || 0} 件</span>
          </div>
        ),
      },
      { title: '金额', width: 120, render: (_, row) => money(row.payment || row.total_amount) },
      { title: '状态', width: 110, render: (_, row) => <StatusTag status={row.status} /> },
      {
        title: '履约',
        width: 180,
        render: (_, row) => (
          <div className="stack-text">
            <strong>{row.carrier || '-'}</strong>
            <span>{row.tracking_number || row.after_sale_status_text || ''}</span>
          </div>
        ),
      },
      {
        title: '操作',
        width: 88,
        fixed: 'right',
        render: (_, row) => (
          <Dropdown
            trigger={['click']}
            menu={{
              items: [
                { key: 'detail', label: '查看详情' },
                row.status === 'pending' && { key: 'markPaid', label: '标记支付' },
                row.status === 'paid' && { key: 'ship', label: '发货' },
                { type: 'divider' },
                { key: 'status', label: '修改状态' },
                { key: 'afterSale', label: '处理售后' },
              ].filter(Boolean),
              onClick: ({ key }) => {
                if (key === 'detail') openOrderDetail(row)
                else if (key === 'markPaid') markPaid(row)
                else if (key === 'ship') openShip(row)
                else if (key === 'status') openOrderStatus(row)
                else openAfterSale(row)
              },
            }}
          >
            <Button icon={<MoreOutlined />} />
          </Dropdown>
        ),
      },
    ]
    return (
      <div className="view-stack">
        <SectionHero title="履约队列" desc="付款、发货和售后按状态处理" stats={orderSummaryCards} />
        <div className="toolbar">
          <Segmented
            value={orderStatus}
            options={orderStatusOptions}
            onChange={(value) => {
              setOrderStatus(value)
              loadOrders({ status: value })
            }}
          />
          {hasOrderFilters && <Button icon={<ReloadOutlined />} onClick={resetOrderFilters}>重置筛选</Button>}
        </div>
        <ProTable
          rowKey="id"
          cardBordered
          search={false}
          options={false}
          pagination={false}
          dataSource={orders}
          columns={columns}
          scroll={{ x: 1080, y: 'calc(100vh - 420px)' }}
          locale={{ emptyText: <EmptyAction description={hasOrderFilters ? '没有匹配的订单' : '暂无订单'}>{hasOrderFilters && <Button onClick={resetOrderFilters}>清空筛选</Button>}</EmptyAction> }}
          headerTitle="订单列表"
          toolBarRender={() => [<Tag key="filter">{orderFilterLabel}</Tag>]}
        />
      </div>
    )
  }

  function renderUsers() {
    return (
      <div className="view-stack">
        <SectionHero title="会员列表" desc="账号状态、会员等级、积分和消费" stats={userSummaryCards} />
        <ProTable
          rowKey="id"
          cardBordered
          search={false}
          options={false}
          pagination={false}
          dataSource={users}
          scroll={{ x: 1040, y: 'calc(100vh - 360px)' }}
          locale={{ emptyText: <EmptyAction description={hasUserFilters ? '没有匹配的用户' : '暂无用户'}>{hasUserFilters && <Button onClick={resetUserFilters}>清空搜索</Button>}</EmptyAction> }}
          headerTitle="用户列表"
          toolBarRender={() => [hasUserFilters && <Button key="reset" type="link" onClick={resetUserFilters}>清空搜索</Button>, <Tag key="count">{users.length} 位用户</Tag>].filter(Boolean)}
          columns={[
            { title: '用户', dataIndex: 'username', width: 150, fixed: 'left' },
            { title: '手机号', dataIndex: 'phone', width: 150 },
            { title: '邮箱', dataIndex: 'email', width: 220 },
            { title: '会员', dataIndex: 'vip_level_name', width: 130 },
            { title: '订单', width: 160, render: (_, row) => `${row.order_count} 单 / ${money(row.total_spent)}` },
            { title: '状态', width: 100, render: (_, row) => <Tag color={row.is_active ? 'blue' : 'red'}>{row.is_active ? '启用' : '停用'}</Tag> },
            { title: '操作', width: 88, fixed: 'right', render: (_, row) => <Button icon={<MoreOutlined />} onClick={() => openUser(row)} /> },
          ]}
        />
      </div>
    )
  }

  function renderContent() {
    return (
      <div className="view-stack">
        <SectionHero title="前台内容" desc="分类、Banner 和栏目统一维护" stats={contentSummaryCards} />
        <div className="toolbar">
          <Segmented
            className="content-tabs"
            value={contentKind}
            options={contentKindOptions}
            onChange={(value) => {
              setContentKind(value)
              loadContent(value)
            }}
          />
          <Button type="primary" icon={<PlusOutlined />} onClick={() => openContent(contentKind)}>{contentPrimaryLabel}</Button>
        </div>
        {renderContentTable()}
      </div>
    )
  }

  function renderContentTable() {
    const shared = {
      rowKey: 'id',
      cardBordered: true,
      search: false,
      options: false,
      pagination: false,
      headerTitle: currentContentLabel,
      toolBarRender: () => [<Tag key="count">{currentContentRows.length} 条内容</Tag>],
      scroll: { x: 1000, y: 'calc(100vh - 420px)' },
    }
    if (contentKind === 'categories') {
      return (
        <ProTable
          {...shared}
          dataSource={categories}
          locale={{ emptyText: <EmptyAction description="暂无一级分类"><Button type="primary" icon={<PlusOutlined />} onClick={() => openContent('categories')}>新增一级分类</Button></EmptyAction> }}
          columns={[
            { title: '分类', width: 260, fixed: 'left', render: (_, row) => <div className="entity-cell"><Thumb src={row.icon} small /><strong>{row.name}</strong></div> },
            { title: '排序', dataIndex: 'sort_order', width: 100 },
            { title: '内容', width: 160, render: (_, row) => `${row.subcategory_count} 子类 / ${row.product_count} 商品` },
            { title: '状态', width: 100, render: (_, row) => <Tag color={row.is_enabled ? 'blue' : 'red'}>{row.is_enabled ? '启用' : '停用'}</Tag> },
            { title: '操作', width: 88, fixed: 'right', render: (_, row) => <Button icon={<MoreOutlined />} onClick={() => openContent('categories', row)} /> },
          ]}
        />
      )
    }
    if (contentKind === 'subcategories') {
      return (
        <ProTable
          {...shared}
          dataSource={subcategories}
          locale={{ emptyText: <EmptyAction description="暂无二级分类"><Button type="primary" icon={<PlusOutlined />} onClick={() => openContent('subcategories')}>新增二级分类</Button></EmptyAction> }}
          columns={[
            { title: '子分类', dataIndex: 'name', width: 200, fixed: 'left' },
            { title: '所属分类', dataIndex: 'category_name', width: 160 },
            { title: '排序', dataIndex: 'sort_order', width: 100 },
            { title: '商品', dataIndex: 'product_count', width: 100 },
            { title: '状态', width: 100, render: (_, row) => <Tag color={row.is_enabled ? 'blue' : 'red'}>{row.is_enabled ? '启用' : '停用'}</Tag> },
            { title: '操作', width: 88, fixed: 'right', render: (_, row) => <Button icon={<MoreOutlined />} onClick={() => openContent('subcategories', row)} /> },
          ]}
        />
      )
    }
    if (contentKind === 'banners') {
      return (
        <ProTable
          {...shared}
          dataSource={banners}
          locale={{ emptyText: <EmptyAction description="暂无首页 Banner"><Button type="primary" icon={<PlusOutlined />} onClick={() => openContent('banners')}>新增 Banner</Button></EmptyAction> }}
          columns={[
            { title: 'Banner', width: 300, fixed: 'left', render: (_, row) => <div className="entity-cell"><Thumb src={row.image} wide /><div><strong>{row.title || row.tag || 'Banner'}</strong><span>{row.tag || '-'}</span></div></div> },
            { title: '跳转', dataIndex: 'link', width: 180 },
            { title: '关联商品', dataIndex: 'product_count', width: 110 },
            { title: '排序', dataIndex: 'sort_order', width: 100 },
            { title: '状态', width: 100, render: (_, row) => <Tag color={row.is_enabled ? 'blue' : 'red'}>{row.is_enabled ? '启用' : '停用'}</Tag> },
            { title: '操作', width: 88, fixed: 'right', render: (_, row) => <Button icon={<MoreOutlined />} onClick={() => openContent('banners', row)} /> },
          ]}
        />
      )
    }
    if (isHomeProductSection) {
      return (
        <ProTable
          {...shared}
          dataSource={currentHomeSections}
          locale={{ emptyText: <EmptyAction description={`暂无${currentContentLabel}`}><Button type="primary" icon={<PlusOutlined />} onClick={() => openContent(contentKind)}>{contentPrimaryLabel}</Button></EmptyAction> }}
          columns={[
            { title: '栏目', dataIndex: 'title', width: 180, fixed: 'left' },
            contentKind === 'flashSales' && { title: '副标题', dataIndex: 'subtitle', width: 160 },
            { title: '商品', width: 260, render: (_, row) => <ProductAvatars products={row.products_preview} count={row.product_count} /> },
            contentKind === 'flashSales' && { title: '时间', width: 220, render: (_, row) => <div className="stack-text"><span>{row.start_time || '-'}</span><span>{row.end_time || ''}</span></div> },
            { title: '排序', dataIndex: 'sort_order', width: 100 },
            { title: '状态', width: 100, render: (_, row) => <Tag color={row.is_enabled ? 'blue' : 'red'}>{row.is_enabled ? '启用' : '停用'}</Tag> },
            { title: '操作', width: 88, fixed: 'right', render: (_, row) => <Button icon={<MoreOutlined />} onClick={() => openContent(contentKind, row)} /> },
          ].filter(Boolean)}
        />
      )
    }
    if (contentKind === 'promotions') {
      return (
        <ProTable
          {...shared}
          dataSource={promotions}
          locale={{ emptyText: <EmptyAction description="暂无促销位"><Button type="primary" icon={<PlusOutlined />} onClick={() => openContent('promotions')}>新增促销位</Button></EmptyAction> }}
          columns={[
            { title: '促销位', width: 300, fixed: 'left', render: (_, row) => <div className="entity-cell"><Thumb src={row.image} wide /><div><strong>{row.title}</strong><span>{row.subtitle || '-'}</span></div></div> },
            { title: '跳转', dataIndex: 'link', width: 180 },
            { title: '排序', dataIndex: 'sort_order', width: 100 },
            { title: '状态', width: 100, render: (_, row) => <Tag color={row.is_enabled ? 'blue' : 'red'}>{row.is_enabled ? '启用' : '停用'}</Tag> },
            { title: '操作', width: 88, fixed: 'right', render: (_, row) => <Button icon={<MoreOutlined />} onClick={() => openContent('promotions', row)} /> },
          ]}
        />
      )
    }
    return <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无内容" />
  }

  function renderMedia() {
    const mediaFilterLabel = `${optionLabel(mediaKindOptions, mediaKind) || '全部'}${keyword ? ` / ${keyword}` : ''} · ${formatNumber(media.length)} 个资源`
    return (
      <div className="view-stack">
        <SectionHero title="多媒体资源管理" desc="统一管理图片、视频、音频和文档，前台内容与商品图片从这里复用。" stats={mediaSummaryCards} />
        <div className="toolbar">
          <Segmented
            value={mediaKind}
            options={mediaKindOptions}
            onChange={(value) => {
              setMediaKind(value)
              loadMedia({ kind: value })
            }}
          />
          <Space wrap>
            {hasMediaFilters && <Button icon={<ReloadOutlined />} onClick={resetMediaFilters}>重置筛选</Button>}
            <Button icon={<ReloadOutlined />} onClick={loadCurrentView}>刷新</Button>
            <Button type="primary" icon={<UploadOutlined />} onClick={() => mediaInputRef.current?.click()}>上传资源</Button>
          </Space>
        </div>
        <ProCard title="资源库" bordered extra={<Tag>{mediaFilterLabel}</Tag>}>
          {media.length ? (
            <div className="media-grid">
              {media.map((item) => (
                <article key={item.id} className="media-card">
                  <button className="media-preview-button" type="button" onClick={() => setMediaPreview(item)}>
                    {item.kind === 'image'
                      ? <Thumb src={item.url} wide className="media-thumb" />
                      : <div className="media-thumb-fallback">{mediaIcon(item.kind)}<span>{mediaKindLabel(item.kind)}</span></div>}
                  </button>
                  <div className="media-card-body">
                    <div className="media-card-title">
                      <strong>{item.name}</strong>
                      <Tag>{item.extension || mediaKindLabel(item.kind)}</Tag>
                    </div>
                    <p>{item.mime_type || '-'}</p>
                    <div className="media-meta-row">
                      <span>{fileSize(item.size)}</span>
                      <span>{item.uploaded_at || '-'}</span>
                    </div>
                    <div className="media-usage">
                      <Tag color={item.usage_count ? 'blue' : 'default'}>{item.usage_count ? `引用 ${item.usage_count}` : '未引用'}</Tag>
                      <span>{item.used_in?.length ? item.used_in.map((usage) => `${usage.label} ${usage.count}`).join(' / ') : ''}</span>
                    </div>
                  </div>
                  <div className="media-actions">
                    <Button icon={<EyeOutlined />} onClick={() => setMediaPreview(item)}>预览</Button>
                    <Button icon={<CopyOutlined />} onClick={() => copyMediaUrl(item)}>复制</Button>
                    <Button onClick={() => { setMediaRename(item); setMediaRenameValue(item.name) }}>重命名</Button>
                    <Button danger icon={<DeleteOutlined />} onClick={() => deleteMedia(item)}>删除</Button>
                  </div>
                </article>
              ))}
            </div>
          ) : (
            <EmptyAction description={hasMediaFilters ? '没有匹配的资源' : '暂无资源，上传图片、视频、音频或文档'}>
              {hasMediaFilters && <Button onClick={resetMediaFilters}>清空筛选</Button>}
              <Button type="primary" icon={<UploadOutlined />} onClick={() => mediaInputRef.current?.click()}>上传资源</Button>
            </EmptyAction>
          )}
        </ProCard>
      </div>
    )
  }

  function renderCoupons() {
    return (
      <div className="view-stack">
        <SectionHero title="优惠券" desc="发放、核销和有效期" stats={couponSummaryCards} />
        <div className="toolbar">
          <Segmented
            value={couponStatus}
            options={couponStatusOptions}
            onChange={(value) => {
              setCouponStatus(value)
              loadCoupons({ status: value })
            }}
          />
          <Space wrap>
            {hasCouponFilters && <Button icon={<ReloadOutlined />} onClick={resetCouponFilters}>重置筛选</Button>}
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openCoupon()}>发放优惠券</Button>
          </Space>
        </div>
        <ProTable
          rowKey="id"
          cardBordered
          search={false}
          options={false}
          pagination={false}
          dataSource={coupons}
          scroll={{ x: 980, y: 'calc(100vh - 420px)' }}
          locale={{ emptyText: <EmptyAction description={hasCouponFilters ? '没有匹配的优惠券' : '暂无优惠券'}>{hasCouponFilters && <Button onClick={resetCouponFilters}>清空筛选</Button>}<Button type="primary" icon={<PlusOutlined />} onClick={() => openCoupon()}>发放优惠券</Button></EmptyAction> }}
          headerTitle="优惠券列表"
          toolBarRender={() => [<Tag key="filter">{couponFilterLabel}</Tag>]}
          columns={[
            { title: '优惠券', dataIndex: 'name', width: 180, fixed: 'left' },
            { title: '用户', dataIndex: 'username', width: 130 },
            { title: '优惠', width: 110, render: (_, row) => `减 ${row.value}` },
            { title: '门槛', dataIndex: 'threshold', width: 160 },
            { title: '有效期', dataIndex: 'time', width: 140 },
            { title: '状态', width: 100, render: (_, row) => <CouponTag status={row.status} /> },
            { title: '操作', width: 88, fixed: 'right', render: (_, row) => <Button icon={<MoreOutlined />} onClick={() => openCoupon(row)} /> },
          ]}
        />
      </div>
    )
  }

  function renderShop() {
    return (
      <div className="view-stack">
        <SectionHero title="店铺资料" desc="前台展示信息" stats={shopSummaryCards} />
        <ProCard title="店铺资料" bordered extra={<Button type="primary" onClick={saveShop}>保存店铺</Button>}>
          <Form layout="vertical" className="shop-form">
            <Form.Item label="店铺名称"><Input value={shopForm.name} onChange={(event) => setShopForm((form) => ({ ...form, name: event.target.value }))} /></Form.Item>
            <Form.Item label="评分"><InputNumber min={0} max={5} step={0.1} value={shopForm.score} onChange={(value) => setShopForm((form) => ({ ...form, score: value }))} /></Form.Item>
            <Form.Item label="商品数"><InputNumber min={0} value={shopForm.product_count} onChange={(value) => setShopForm((form) => ({ ...form, product_count: value }))} /></Form.Item>
            <Form.Item label="销售额展示"><Input value={shopForm.sales} onChange={(event) => setShopForm((form) => ({ ...form, sales: event.target.value }))} /></Form.Item>
            <Form.Item label="粉丝数展示"><Input value={shopForm.fans_count} onChange={(event) => setShopForm((form) => ({ ...form, fans_count: event.target.value }))} /></Form.Item>
            <Form.Item label="店铺简介" className="full"><Input.TextArea rows={4} value={shopForm.description} onChange={(event) => setShopForm((form) => ({ ...form, description: event.target.value }))} /></Form.Item>
          </Form>
        </ProCard>
      </div>
    )
  }

  function renderProductDrawer() {
    return (
      <Drawer
        title={productForm.id ? '编辑商品' : '新增商品'}
        width={760}
        open={productDrawer}
        onClose={() => setProductDrawer(false)}
        extra={<Space><Button onClick={() => setProductDrawer(false)}>取消</Button><Button type="primary" onClick={saveProduct}>保存商品</Button></Space>}
      >
        <Form layout="vertical" className="drawer-form">
          <Form.Item label="商品名称"><Input value={productForm.name} onChange={(event) => setProductForm((form) => ({ ...form, name: event.target.value }))} /></Form.Item>
          <Form.Item label="标签"><Input value={productForm.tag} onChange={(event) => setProductForm((form) => ({ ...form, tag: event.target.value }))} /></Form.Item>
          <Form.Item label="售价"><InputNumber min={0} precision={2} value={productForm.price} onChange={(value) => setProductForm((form) => ({ ...form, price: value }))} /></Form.Item>
          <Form.Item label="划线价"><InputNumber min={0} precision={2} value={productForm.original_price} onChange={(value) => setProductForm((form) => ({ ...form, original_price: value }))} /></Form.Item>
          <Form.Item label="销量"><InputNumber min={0} value={productForm.sales_count} onChange={(value) => setProductForm((form) => ({ ...form, sales_count: value }))} /></Form.Item>
          <Form.Item label="评分"><InputNumber min={0} max={5} step={0.1} value={productForm.rating} onChange={(value) => setProductForm((form) => ({ ...form, rating: value }))} /></Form.Item>
          <Form.Item label="所属子分类">
            <Select
              allowClear
              showSearch
              value={productForm.subcategory_id || undefined}
              optionFilterProp="label"
              options={subcategories.map((item) => ({ label: `${item.category_name} / ${item.name}`, value: item.id }))}
              onChange={(value = '') => setProductForm((form) => ({ ...form, subcategory_id: value }))}
            />
          </Form.Item>
          <Form.Item label="商品图片">
            <Select
              allowClear
              showSearch
              value={productForm.image_id || undefined}
              optionFilterProp="label"
              options={mediaImageOptions.map((item) => ({ label: item.name, value: item.id }))}
              onChange={(value = '') => setProductForm((form) => ({ ...form, image_id: value }))}
            />
          </Form.Item>
          <Form.Item label="上架状态"><Switch checked={productForm.is_in_stock} checkedChildren="上架" unCheckedChildren="下架" onChange={(value) => setProductForm((form) => ({ ...form, is_in_stock: value }))} /></Form.Item>
          <Form.Item label="商品描述" className="full"><Input.TextArea rows={4} value={productForm.description} onChange={(event) => setProductForm((form) => ({ ...form, description: event.target.value }))} /></Form.Item>
        </Form>

        <div className="form-section">
          <div className="section-title">
            <div>
              <strong>规格与库存</strong>
              <span>用于商品详情页、购物车和订单价格库存联动</span>
            </div>
            <Button size="small" onClick={addSpecGroup}>新增规格组</Button>
          </div>
          {productForm.spec_groups?.length ? (
            <div className="spec-stack">
              {productForm.spec_groups.map((group, groupIndex) => (
                <div key={group.local_id || group.id} className="spec-editor">
                  <div className="spec-row">
                    <Input
                      value={group.name}
                      placeholder="规格名，例如 尺码 / 颜色"
                      onChange={(event) => updateSpecGroup(groupIndex, { name: event.target.value }, true)}
                    />
                    <Button danger type="text" onClick={() => removeSpecGroup(groupIndex)}>删除</Button>
                  </div>
                  <div className="spec-value-row">
                    {group.values.map((value, valueIndex) => (
                      <Tag key={value.local_id || value.id} closable onClose={() => removeSpecValue(groupIndex, valueIndex)}>{value.value}</Tag>
                    ))}
                    <Input
                      className="spec-value-input"
                      size="small"
                      value={group.draft}
                      placeholder="输入规格值"
                      onChange={(event) => updateSpecGroup(groupIndex, { draft: event.target.value })}
                      onPressEnter={() => addSpecValue(groupIndex)}
                    />
                    <Button size="small" onClick={() => addSpecValue(groupIndex)}>添加</Button>
                  </div>
                </div>
              ))}
            </div>
          ) : <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无规格，单规格商品可不配置" />}
          {productForm.skus?.length > 0 && (
            <Table
              className="sku-table"
              rowKey={(row) => row.id || row.spec_value_ids?.join('|')}
              size="small"
              bordered
              pagination={false}
              dataSource={productForm.skus}
              scroll={{ x: 650 }}
              columns={[
                { title: 'SKU', dataIndex: 'spec_text', width: 180, fixed: 'left' },
                { title: '售价', width: 130, render: (_, row, index) => <InputNumber min={0} precision={2} value={row.price} onChange={(value) => updateSku(index, { price: value })} /> },
                { title: '划线价', width: 130, render: (_, row, index) => <InputNumber min={0} precision={2} value={row.original_price} onChange={(value) => updateSku(index, { original_price: value })} /> },
                { title: '库存', width: 120, render: (_, row, index) => <InputNumber min={0} value={row.stock} onChange={(value) => updateSku(index, { stock: value })} /> },
                { title: '图片', width: 180, render: (_, row, index) => <Select allowClear showSearch optionFilterProp="label" placeholder="默认商品图" value={row.image_id || undefined} options={mediaImageOptions.map((item) => ({ label: item.name, value: item.id }))} onChange={(value = '') => updateSku(index, { image_id: value })} /> },
              ]}
            />
          )}
        </div>
      </Drawer>
    )
  }

  function renderContentDrawer() {
    const title = {
      categories: contentForm.id ? '编辑一级分类' : '新增一级分类',
      subcategories: contentForm.id ? '编辑二级分类' : '新增二级分类',
      banners: contentForm.id ? '编辑 Banner' : '新增 Banner',
      flashSales: contentForm.id ? '编辑限时秒杀' : '新增限时秒杀',
      hotRanks: contentForm.id ? '编辑热销榜' : '新增热销榜',
      recommends: contentForm.id ? '编辑推荐栏目' : '新增推荐栏目',
      newArrivals: contentForm.id ? '编辑新品栏目' : '新增新品栏目',
      promotions: contentForm.id ? '编辑促销位' : '新增促销位',
    }[contentKind]
    return (
      <Drawer
        title={title}
        width={600}
        open={contentDrawer}
        onClose={() => setContentDrawer(false)}
        extra={<Space><Button onClick={() => setContentDrawer(false)}>取消</Button><Button type="primary" onClick={saveContent}>保存内容</Button></Space>}
      >
        <Form layout="vertical" className="drawer-form one-col">
          {contentKind === 'categories' && (
            <>
              <Form.Item label="分类名称"><Input value={contentForm.name} onChange={(event) => setContentForm((form) => ({ ...form, name: event.target.value }))} /></Form.Item>
              <Form.Item label="排序"><InputNumber min={0} value={contentForm.sort_order} onChange={(value) => setContentForm((form) => ({ ...form, sort_order: value }))} /></Form.Item>
              <Form.Item label="图标"><Select allowClear showSearch optionFilterProp="label" value={contentForm.icon_id || undefined} options={mediaImageOptions.map((item) => ({ label: item.name, value: item.id }))} onChange={(value = '') => setContentForm((form) => ({ ...form, icon_id: value }))} /></Form.Item>
              <Form.Item label="Banner"><Select allowClear showSearch optionFilterProp="label" value={contentForm.banner_id || undefined} options={mediaImageOptions.map((item) => ({ label: item.name, value: item.id }))} onChange={(value = '') => setContentForm((form) => ({ ...form, banner_id: value }))} /></Form.Item>
            </>
          )}
          {contentKind === 'subcategories' && (
            <>
              <Form.Item label="子分类名称"><Input value={contentForm.name} onChange={(event) => setContentForm((form) => ({ ...form, name: event.target.value }))} /></Form.Item>
              <Form.Item label="所属分类"><Select value={contentForm.category_id || undefined} options={categories.map((item) => ({ label: item.name, value: item.id }))} onChange={(value = '') => setContentForm((form) => ({ ...form, category_id: value }))} /></Form.Item>
              <Form.Item label="排序"><InputNumber min={0} value={contentForm.sort_order} onChange={(value) => setContentForm((form) => ({ ...form, sort_order: value }))} /></Form.Item>
              <Form.Item label="图标"><Select allowClear showSearch optionFilterProp="label" value={contentForm.icon_id || undefined} options={mediaImageOptions.map((item) => ({ label: item.name, value: item.id }))} onChange={(value = '') => setContentForm((form) => ({ ...form, icon_id: value }))} /></Form.Item>
            </>
          )}
          {contentKind === 'banners' && (
            <>
              <Form.Item label="角标"><Input value={contentForm.tag} onChange={(event) => setContentForm((form) => ({ ...form, tag: event.target.value }))} /></Form.Item>
              <Form.Item label="主标题"><Input value={contentForm.title} onChange={(event) => setContentForm((form) => ({ ...form, title: event.target.value }))} /></Form.Item>
              <Form.Item label="按钮文案"><Input value={contentForm.action_title} onChange={(event) => setContentForm((form) => ({ ...form, action_title: event.target.value }))} /></Form.Item>
              <Form.Item label="跳转链接"><Input value={contentForm.link} onChange={(event) => setContentForm((form) => ({ ...form, link: event.target.value }))} /></Form.Item>
              <Form.Item label="会场标识"><Input value={contentForm.landing_badge} onChange={(event) => setContentForm((form) => ({ ...form, landing_badge: event.target.value }))} /></Form.Item>
              <Form.Item label="会场副标题"><Input value={contentForm.landing_subtitle} onChange={(event) => setContentForm((form) => ({ ...form, landing_subtitle: event.target.value }))} /></Form.Item>
              <Form.Item label="色彩序号"><InputNumber min={0} value={contentForm.gradient_type} onChange={(value) => setContentForm((form) => ({ ...form, gradient_type: value }))} /></Form.Item>
              <Form.Item label="排序"><InputNumber min={0} value={contentForm.sort_order} onChange={(value) => setContentForm((form) => ({ ...form, sort_order: value }))} /></Form.Item>
              <Form.Item label="图片"><Select allowClear showSearch optionFilterProp="label" value={contentForm.image_id || undefined} options={mediaImageOptions.map((item) => ({ label: item.name, value: item.id }))} onChange={(value = '') => setContentForm((form) => ({ ...form, image_id: value }))} /></Form.Item>
              <Form.Item label="关联商品"><Select mode="multiple" showSearch optionFilterProp="label" value={contentForm.product_ids || []} options={products.map((item) => ({ label: item.name, value: item.id }))} onChange={(value) => setContentForm((form) => ({ ...form, product_ids: value }))} /></Form.Item>
              <Form.Item label="会场描述" className="full"><Input.TextArea rows={4} value={contentForm.landing_description} onChange={(event) => setContentForm((form) => ({ ...form, landing_description: event.target.value }))} /></Form.Item>
            </>
          )}
          {isHomeProductSection && (
            <>
              <Form.Item label="栏目标题"><Input value={contentForm.title} onChange={(event) => setContentForm((form) => ({ ...form, title: event.target.value }))} /></Form.Item>
              {contentKind === 'flashSales' && <Form.Item label="副标题"><Input value={contentForm.subtitle} onChange={(event) => setContentForm((form) => ({ ...form, subtitle: event.target.value }))} /></Form.Item>}
              {contentKind === 'flashSales' && <Form.Item label="开始时间"><Input type="datetime-local" value={contentForm.start_time} onChange={(event) => setContentForm((form) => ({ ...form, start_time: event.target.value }))} /></Form.Item>}
              {contentKind === 'flashSales' && <Form.Item label="结束时间"><Input type="datetime-local" value={contentForm.end_time} onChange={(event) => setContentForm((form) => ({ ...form, end_time: event.target.value }))} /></Form.Item>}
              <Form.Item label="排序"><InputNumber min={0} value={contentForm.sort_order} onChange={(value) => setContentForm((form) => ({ ...form, sort_order: value }))} /></Form.Item>
              <Form.Item label="关联商品"><Select mode="multiple" showSearch optionFilterProp="label" value={contentForm.product_ids || []} options={products.map((item) => ({ label: item.name, value: item.id }))} onChange={(value) => setContentForm((form) => ({ ...form, product_ids: value }))} /></Form.Item>
            </>
          )}
          {contentKind === 'promotions' && (
            <>
              <Form.Item label="标题"><Input value={contentForm.title} onChange={(event) => setContentForm((form) => ({ ...form, title: event.target.value }))} /></Form.Item>
              <Form.Item label="副标题"><Input value={contentForm.subtitle} onChange={(event) => setContentForm((form) => ({ ...form, subtitle: event.target.value }))} /></Form.Item>
              <Form.Item label="跳转链接"><Input value={contentForm.link} onChange={(event) => setContentForm((form) => ({ ...form, link: event.target.value }))} /></Form.Item>
              <Form.Item label="图片"><Select allowClear showSearch optionFilterProp="label" value={contentForm.image_id || undefined} options={mediaImageOptions.map((item) => ({ label: item.name, value: item.id }))} onChange={(value = '') => setContentForm((form) => ({ ...form, image_id: value }))} /></Form.Item>
              <Form.Item label="排序"><InputNumber min={0} value={contentForm.sort_order} onChange={(value) => setContentForm((form) => ({ ...form, sort_order: value }))} /></Form.Item>
            </>
          )}
          <Form.Item label="启用"><Switch checked={contentForm.is_enabled} checkedChildren="启用" unCheckedChildren="停用" onChange={(value) => setContentForm((form) => ({ ...form, is_enabled: value }))} /></Form.Item>
        </Form>
      </Drawer>
    )
  }

  function renderOrderActionDrawer() {
    const title = { ship: '订单发货', status: '修改订单状态', afterSale: '售后处理' }[orderAction] || '订单处理'
    return (
      <Drawer
        title={title}
        width={460}
        open={orderDrawer}
        onClose={() => setOrderDrawer(false)}
        extra={<Space><Button onClick={() => setOrderDrawer(false)}>取消</Button><Button type="primary" onClick={saveOrderAction}>保存</Button></Space>}
      >
        <Form layout="vertical">
          {orderAction === 'ship' && (
            <>
              <Form.Item label="物流公司"><Input value={orderForm.carrier} onChange={(event) => setOrderForm((form) => ({ ...form, carrier: event.target.value }))} /></Form.Item>
              <Form.Item label="运单号"><Input value={orderForm.tracking_number} onChange={(event) => setOrderForm((form) => ({ ...form, tracking_number: event.target.value }))} /></Form.Item>
            </>
          )}
          {orderAction === 'status' && (
            <Form.Item label="订单状态"><Select value={orderForm.status} options={orderRawStatuses} onChange={(value) => setOrderForm((form) => ({ ...form, status: value }))} /></Form.Item>
          )}
          {orderAction === 'afterSale' && (
            <>
              <Form.Item label="售后状态"><Select value={orderForm.after_sale_status} options={afterSaleStatuses} onChange={(value) => setOrderForm((form) => ({ ...form, after_sale_status: value }))} /></Form.Item>
              <Form.Item label="处理备注"><Input.TextArea rows={4} value={orderForm.after_sale_reason} onChange={(event) => setOrderForm((form) => ({ ...form, after_sale_reason: event.target.value }))} /></Form.Item>
            </>
          )}
        </Form>
      </Drawer>
    )
  }

  function renderOrderDetailDrawer() {
    return (
      <Drawer title="订单详情" width={640} open={orderDetailDrawer} onClose={() => setOrderDetailDrawer(false)}>
        {orderDetail && (
          <div className="order-detail">
            <div className="detail-summary">
              <div>
                <span>订单号</span>
                <strong>{orderDetail.id}</strong>
              </div>
              <StatusTag status={orderDetail.status} />
            </div>
            <Descriptions column={2} bordered size="small">
              <Descriptions.Item label="用户">{orderDetail.user?.username || '-'}</Descriptions.Item>
              <Descriptions.Item label="实付金额">{money(orderDetail.payment || orderDetail.total_amount)}</Descriptions.Item>
              <Descriptions.Item label="创建时间">{orderDetail.created_display || '-'}</Descriptions.Item>
              <Descriptions.Item label="支付时间">{orderDetail.pay_display || '-'}</Descriptions.Item>
              <Descriptions.Item label="物流公司">{orderDetail.carrier || '-'}</Descriptions.Item>
              <Descriptions.Item label="运单号">{orderDetail.tracking_number || '-'}</Descriptions.Item>
            </Descriptions>
            <section className="detail-section">
              <h3>收货地址</h3>
              <p>{orderDetail.address_name || '-'} {orderDetail.address_phone || ''}</p>
              <p>{addressText(orderDetail) || '-'}</p>
            </section>
            <section className="detail-section">
              <h3>商品明细</h3>
              {(orderDetail.products || []).map((item) => (
                <div key={item.id} className="order-product">
                  <Thumb src={item.image} />
                  <div>
                    <strong>{item.name}</strong>
                    <span>{item.spec || '默认规格'} · x{item.quantity}</span>
                  </div>
                  <b>{money(item.price)}</b>
                </div>
              ))}
            </section>
            {orderDetail.after_sale_status && orderDetail.after_sale_status !== 'none' && (
              <section className="detail-section warning-section">
                <h3>售后记录</h3>
                <p>{statusText(orderDetail.after_sale_status)}</p>
                <p>{orderDetail.after_sale_reason || '暂无备注'}</p>
              </section>
            )}
            <Space wrap className="drawer-footer-actions">
              {orderDetail.status === 'pending' && <Button type="primary" onClick={() => markPaid(orderDetail)}>标记支付</Button>}
              {orderDetail.status === 'paid' && <Button type="primary" onClick={() => openShip(orderDetail)}>发货</Button>}
              <Button onClick={() => openAfterSale(orderDetail)}>处理售后</Button>
            </Space>
          </div>
        )}
      </Drawer>
    )
  }

  function renderUserDrawer() {
    return (
      <Drawer
        title="编辑用户"
        width={460}
        open={userDrawer}
        onClose={() => setUserDrawer(false)}
        extra={<Space><Button onClick={() => setUserDrawer(false)}>取消</Button><Button type="primary" onClick={saveUser}>保存用户</Button></Space>}
      >
        <Form layout="vertical">
          <Form.Item label="邮箱"><Input value={userForm.email} onChange={(event) => setUserForm((form) => ({ ...form, email: event.target.value }))} /></Form.Item>
          <Form.Item label="手机号"><Input value={userForm.phone} onChange={(event) => setUserForm((form) => ({ ...form, phone: event.target.value }))} /></Form.Item>
          <Form.Item label="会员等级"><Select value={userForm.vip_level} options={vipLevels} onChange={(value) => setUserForm((form) => ({ ...form, vip_level: value }))} /></Form.Item>
          <Form.Item label="积分"><InputNumber min={0} value={userForm.points} onChange={(value) => setUserForm((form) => ({ ...form, points: value }))} /></Form.Item>
          <Form.Item label="账号启用"><Switch checked={userForm.is_active} onChange={(value) => setUserForm((form) => ({ ...form, is_active: value }))} /></Form.Item>
        </Form>
      </Drawer>
    )
  }

  function renderCouponDrawer() {
    return (
      <Drawer
        title={couponForm.id ? '编辑优惠券' : '发放优惠券'}
        width={460}
        open={couponDrawer}
        onClose={() => setCouponDrawer(false)}
        extra={<Space><Button onClick={() => setCouponDrawer(false)}>取消</Button><Button type="primary" onClick={saveCoupon}>保存优惠券</Button></Space>}
      >
        <Form layout="vertical">
          {!couponForm.id && <Form.Item label="用户名"><Input value={couponForm.username} onChange={(event) => setCouponForm((form) => ({ ...form, username: event.target.value }))} /></Form.Item>}
          <Form.Item label="优惠券名称"><Input value={couponForm.name} onChange={(event) => setCouponForm((form) => ({ ...form, name: event.target.value }))} /></Form.Item>
          <Form.Item label="优惠金额"><InputNumber min={0} value={couponForm.value} onChange={(value) => setCouponForm((form) => ({ ...form, value }))} /></Form.Item>
          <Form.Item label="使用门槛"><Input value={couponForm.threshold} onChange={(event) => setCouponForm((form) => ({ ...form, threshold: event.target.value }))} /></Form.Item>
          <Form.Item label="有效期"><Input value={couponForm.time} onChange={(event) => setCouponForm((form) => ({ ...form, time: event.target.value }))} /></Form.Item>
          <Form.Item label="状态"><Select value={couponForm.status} options={couponRawStatuses} onChange={(value) => setCouponForm((form) => ({ ...form, status: value }))} /></Form.Item>
          <Form.Item label="说明"><Input.TextArea rows={4} value={couponForm.description} onChange={(event) => setCouponForm((form) => ({ ...form, description: event.target.value }))} /></Form.Item>
        </Form>
      </Drawer>
    )
  }

  function renderMediaModals() {
    return (
      <>
        <Modal
          title="资源预览"
          width={760}
          open={Boolean(mediaPreview)}
          onCancel={() => setMediaPreview(null)}
          footer={mediaPreview ? [
            <Button key="copy" icon={<CopyOutlined />} onClick={() => copyMediaUrl(mediaPreview)}>复制链接</Button>,
            <Button key="close" type="primary" onClick={() => setMediaPreview(null)}>关闭</Button>,
          ] : null}
        >
          {mediaPreview && (
            <div className="media-preview">
              {mediaPreview.kind === 'image' && <img src={mediaPreview.url} alt="" />}
              {mediaPreview.kind === 'video' && <video src={mediaPreview.url} controls />}
              {mediaPreview.kind === 'audio' && <audio src={mediaPreview.url} controls />}
              {mediaPreview.mime_type === 'application/pdf' && <iframe src={mediaPreview.url} title="PDF 预览" />}
              {!['image', 'video', 'audio'].includes(mediaPreview.kind) && mediaPreview.mime_type !== 'application/pdf' && (
                <div className="media-file-preview">
                  {mediaIcon(mediaPreview.kind)}
                  <strong>{mediaPreview.name}</strong>
                  <Button href={mediaPreview.url} target="_blank">打开资源</Button>
                </div>
              )}
              <Descriptions column={2} bordered size="small" className="media-descriptions">
                <Descriptions.Item label="名称">{mediaPreview.name}</Descriptions.Item>
                <Descriptions.Item label="类型">{mediaPreview.mime_type || mediaKindLabel(mediaPreview.kind)}</Descriptions.Item>
                <Descriptions.Item label="大小">{fileSize(mediaPreview.size)}</Descriptions.Item>
                <Descriptions.Item label="上传时间">{mediaPreview.uploaded_at || '-'}</Descriptions.Item>
                <Descriptions.Item label="引用" span={2}>{mediaPreview.used_in?.length ? mediaPreview.used_in.map((usage) => `${usage.label} ${usage.count}`).join(' / ') : '未引用'}</Descriptions.Item>
              </Descriptions>
            </div>
          )}
        </Modal>
        <Modal
          title="重命名资源"
          open={Boolean(mediaRename)}
          okText="保存"
          cancelText="取消"
          onOk={saveMediaRename}
          onCancel={() => setMediaRename(null)}
        >
          <Input value={mediaRenameValue} onChange={(event) => setMediaRenameValue(event.target.value)} />
        </Modal>
      </>
    )
  }
}
