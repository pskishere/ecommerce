/* ============================================================
   潮流好物 — DOM Utilities
   ============================================================ */

/**
 * querySelector shorthand
 * @param {string} selector
 * @param {Element|Document} ctx
 * @returns {Element|null}
 */
export function $(selector, ctx = document) {
  return ctx.querySelector(selector)
}

/**
 * querySelectorAll shorthand
 * @param {string} selector
 * @param {Element|Document} ctx
 * @returns {Element[]}
 */
export function $$(selector, ctx = document) {
  return Array.from(ctx.querySelectorAll(selector))
}
