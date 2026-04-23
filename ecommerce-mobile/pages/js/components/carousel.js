/* ============================================================
   潮流好物 — Carousel Component
   ============================================================ */

export function initCarousel() {
  const track = document.getElementById('carouselTrack')
  const dots = document.querySelectorAll('.dot')
  const slides = document.querySelectorAll('.carousel-slide')
  if (!track || slides.length === 0) return

  let current = 0
  let autoplayTimer = null
  const len = slides.length

  function goTo(index) {
    current = ((index % len) + len) % len
    track.style.transform = `translateX(-${current * 100}%)`
    dots.forEach((d, i) => d.classList.toggle('active', i === current))
    slides.forEach((s, i) => s.classList.toggle('active', i === current))
  }

  function next() { goTo(current + 1) }
  function startAutoplay() { stopAutoplay(); autoplayTimer = setInterval(next, 4000) }
  function stopAutoplay() { clearInterval(autoplayTimer) }

  dots.forEach(dot => {
    dot.addEventListener('click', () => { goTo(Number(dot.dataset.index)); startAutoplay() })
  })

  let touchStartX = 0, touchDeltaX = 0, isDragging = false
  track.addEventListener('touchstart', (e) => {
    touchStartX = e.touches[0].clientX
    isDragging = true
    stopAutoplay()
  }, { passive: true })
  track.addEventListener('touchmove', (e) => {
    if (!isDragging) return
    touchDeltaX = e.touches[0].clientX - touchStartX
  }, { passive: true })
  track.addEventListener('touchend', () => {
    if (!isDragging) return
    isDragging = false
    if (Math.abs(touchDeltaX) > 50) goTo(current + (touchDeltaX < 0 ? 1 : -1))
    startAutoplay()
  }, { passive: true })

  goTo(0)
  startAutoplay()
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) stopAutoplay()
    else startAutoplay()
  })
}
