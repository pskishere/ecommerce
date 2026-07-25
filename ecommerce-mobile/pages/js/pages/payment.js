import { api } from '../data/api.js'
import { showToast } from '../components/toast.js'

const params = new URLSearchParams(location.search)
const orderId = params.get('orderId') || sessionStorage.getItem('paymentOrderId') || ''
const amount  = params.get('amount')  || sessionStorage.getItem('paymentAmount')  || '0.00'

let selectedMethod = 'wxpay'

function init() {
  document.getElementById('payAmount').textContent = parseFloat(amount).toFixed(2)
  document.getElementById('payOrderId').textContent = orderId || '-'
  if (!orderId) showToast('订单信息缺失')
}

function selectMethod(el, method) {
  selectedMethod = method
  document.querySelectorAll('.pay-method').forEach(m => {
    m.classList.remove('selected')
    m.querySelector('.pay-method-radio').classList.remove('active')
  })
  el.classList.add('selected')
  el.querySelector('.pay-method-radio').classList.add('active')
}

async function submitPayment() {
  if (!orderId) { showToast('订单信息缺失'); return }

  document.getElementById('processingOverlay').style.display = 'flex'

  try {
    const session = await api.order.pay(orderId, selectedMethod)
    if (session?.next_action?.type === 'sandbox_confirm') {
      await api.payment.confirm(session.id)
    } else if (session?.payment_url) {
      window.location.href = session.payment_url
      return
    }
    document.getElementById('processingOverlay').style.display = 'none'
    document.getElementById('successAmount').textContent = parseFloat(amount).toFixed(2)
    document.getElementById('successOverlay').style.display = 'flex'
  } catch (e) {
    document.getElementById('processingOverlay').style.display = 'none'
    document.getElementById('failedOverlay').style.display = 'flex'
    console.error('Payment failed', e)
  }
}

function viewOrder() {
  if (orderId) sessionStorage.setItem('orderId', orderId)
  window.location.href = 'order-detail.html?id=' + orderId
}

function continueShopping() {
  window.location.href = 'index.html'
}

function retryPayment() {
  document.getElementById('failedOverlay').style.display = 'none'
}

init()

window.selectMethod = selectMethod
window.submitPayment = submitPayment
window.viewOrder = viewOrder
window.continueShopping = continueShopping
window.retryPayment = retryPayment
