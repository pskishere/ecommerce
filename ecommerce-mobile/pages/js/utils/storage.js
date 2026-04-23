/* ── LocalStorage Unified Wrapper ── */

function createStorage(name) {
  return {
    get: () => {
      try { return JSON.parse(localStorage.getItem(name)) || null } catch { return null }
    },
    set: (v) => localStorage.setItem(name, JSON.stringify(v)),
    clear: () => localStorage.removeItem(name),
  }
}

export const storage = {
  cart: createStorage('cart'),
  favorites: createStorage('favorites'),
  searchHistory: createStorage('searchHistory'),
}
