/* ── Review Submit Page ── */
import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

const params = new URLSearchParams(location.search)
const orderId = params.get('orderId') || sessionStorage.getItem('reviewOrderId') || ''
let productId = params.get('productId') || sessionStorage.getItem('reviewProductId') || ''
let productSpec = ''
let returnUrl = orderId ? `order-detail.html?id=${encodeURIComponent(orderId)}` : 'order.html'

let currentRating = 5
let isAnon = false
let reviewImages = []

// Init star rating
const stars = document.querySelectorAll('#reviewStars svg')
function setRating(n) {
  currentRating = n
  stars.forEach((s, i) => {
    s.setAttribute('fill', i < n ? 'currentColor' : 'none')
  })
}
stars.forEach((s, i) => {
  s.style.cursor = 'pointer'
  s.addEventListener('click', () => setRating(i + 1))
})

async function initReviewProduct() {
  try {
    if (orderId) {
      const order = await api.order.getById(orderId)
      const product = order?.products?.find(p => !productId || p.productId === productId) || order?.products?.[0]
      if (product) {
        productId = product.productId || productId
        productSpec = product.spec || ''
        renderProduct(product)
      }
      return
    }

    if (productId) {
      const product = await api.product.getDetail(productId)
      if (product) renderProduct(product)
    }
  } catch (e) {
    console.error('load review product failed', e)
  }
}

function renderProduct(product) {
  const img = document.getElementById('reviewProductImg')
  const name = document.getElementById('reviewProductName')
  const spec = document.getElementById('reviewProductSpec')
  const image = product.image || product.img || ''
  if (img && image) img.src = image
  if (name) name.textContent = product.name || '商品'
  if (spec) spec.textContent = product.spec || ''
}

// Char counter
const textarea = document.getElementById('reviewText')
const counter = document.getElementById('textCount')
textarea?.addEventListener('input', () => {
  if (counter) counter.textContent = textarea.value.length
})

function toggleAnon() {
  isAnon = !isAnon
  document.getElementById('anonSwitch')?.classList.toggle('active', isAnon)
}

function chooseReviewImages() {
  document.getElementById('reviewImageInput')?.click()
}

function fileToDataURL(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result)
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

async function handleImageChange(event) {
  const files = Array.from(event.target.files || [])
  if (!files.length) return
  const remaining = Math.max(0, 6 - reviewImages.length)
  const selected = files.slice(0, remaining)
  if (files.length > remaining) showToast('最多上传6张图片')

  try {
    const images = await Promise.all(selected.map(fileToDataURL))
    reviewImages = reviewImages.concat(images)
    renderImages()
  } catch (e) {
    showToast('图片读取失败')
  } finally {
    event.target.value = ''
  }
}

function renderImages() {
  const list = document.getElementById('imageList')
  if (!list) return
  const addButton = `
    <div class="review-add-image" onclick="chooseReviewImages()">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
      <span>添加图片</span>
    </div>`
  list.innerHTML = reviewImages.map((src, index) => `
    <div class="review-image-item">
      <img src="${src}" alt="评价图片${index + 1}">
      <div class="remove-btn" onclick="removeReviewImage(${index})">×</div>
    </div>
  `).join('') + (reviewImages.length < 6 ? addButton : '')
}

function removeReviewImage(index) {
  reviewImages.splice(index, 1)
  renderImages()
}

async function submitReview() {
  const content = textarea?.value.trim()
  if (!content) { showToast('请填写评价内容'); return }
  if (!productId) { showToast('商品信息缺失'); return }

  try {
    await api.product.createReview(productId, {
      rating: currentRating,
      content,
      spec: productSpec,
      is_anonymous: isAnon,
      images: reviewImages,
    })
    showToast('评价提交成功')
    if (orderId) sessionStorage.setItem('orderId', orderId)
    setTimeout(() => { window.location.href = returnUrl }, 1000)
  } catch (e) {
    showToast('提交失败，请重试')
  }
}

window.submitReview = submitReview
window.toggleAnon = toggleAnon
window.chooseReviewImages = chooseReviewImages
window.removeReviewImage = removeReviewImage

document.getElementById('reviewImageInput')?.addEventListener('change', handleImageChange)

initReviewProduct()
