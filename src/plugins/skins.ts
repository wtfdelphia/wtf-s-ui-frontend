/**
 * 6 gradient "skins". Each bundles a background gradient with the matching
 * Vuetify base theme (light/dark) so component colours and contrast stay
 * correct. The gradient + glass CSS lives in styles/skins.css, keyed off the
 * <html data-skin="..."> attribute this module sets.
 */
export type SkinId = 'aurora' | 'mesh' | 'deepsea' | 'sunrise' | 'cyber' | 'mint'

export interface Skin {
  id: SkinId
  base: 'light' | 'dark'
  swatch: string // small gradient used as the menu preview chip
}

export const SKINS: Skin[] = [
  { id: 'aurora', base: 'dark', swatch: 'linear-gradient(135deg,#302b63,#a855f7)' },
  { id: 'mesh', base: 'light', swatch: 'linear-gradient(135deg,#c2e9fb,#fbc2eb)' },
  { id: 'deepsea', base: 'dark', swatch: 'linear-gradient(135deg,#0e3a5f,#38bdf8)' },
  { id: 'sunrise', base: 'light', swatch: 'linear-gradient(135deg,#ffaa96,#b4a0ff)' },
  { id: 'cyber', base: 'dark', swatch: 'linear-gradient(135deg,#ec4899,#22d3ee)' },
  { id: 'mint', base: 'light', swatch: 'linear-gradient(135deg,#a7f3d0,#bae6fd)' },
]

export const DEFAULT_SKIN: SkinId = 'aurora'

export function savedSkin(): Skin {
  const id = localStorage.getItem('skin') as SkinId | null
  return SKINS.find((s) => s.id === id) ?? SKINS[0]
}

/** Reflect the chosen skin onto <html> so styles/skins.css picks its gradient. */
export function applySkinAttr(id: SkinId): void {
  document.documentElement.setAttribute('data-skin', id)
}
