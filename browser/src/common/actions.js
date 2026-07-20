// ── Save flow (background → content script) ─────────────────────────────────
/** Background → content script: avvia il flusso di salvataggio, inietta overlay */
export const SAVE_LINK_LOADING = 'SAVE_LINK_LOADING'
/** Background → content script: salvataggio completato con successo */
export const SAVE_LINK_SUCCESS = 'SAVE_LINK_SUCCESS'
/** Background → content script: salvataggio fallito */
export const SAVE_LINK_FAILURE = 'SAVE_LINK_FAILURE'
/** Background → content script: salvataggio saltato, link già esistente */
export const SAVE_LINK_DUPLICATE = 'SAVE_LINK_DUPLICATE'

// ── Post-save metadata push ──────────────────────────────────────────────────
/** Background → content script: preview derivata pronta (title, thumbnail, publisher) */
export const UPDATE_ITEM_PREVIEW = 'UPDATE_ITEM_PREVIEW'

// ── Remove flow (background → content script) ───────────────────────────────
export const REMOVE_LINK_REQUEST = 'REMOVE_LINK_REQUEST'
export const REMOVE_LINK_SUCCESS = 'REMOVE_LINK_SUCCESS'
export const REMOVE_LINK_FAILURE = 'REMOVE_LINK_FAILURE'

// ── Popup → background ───────────────────────────────────────────────────────
/** Popup → background: trigger principale del salvataggio tab corrente */
export const TRIGGER_SAVE = 'TRIGGER_SAVE'

// ── Background → popup ───────────────────────────────────────────────────────
/** Background → popup: arricchimento asincrono completato, aggiorna lista link */
export const METADATA_ENRICHED = 'METADATA_ENRICHED'

// ── Metadata extraction ──────────────────────────────────────────────────────
/** Popup/background → content script: estrai metadata dal DOM live della tab */
export const GET_METADATA = 'GET_METADATA'
/** Popup/background → content script: verifica se il content script è già attivo */
export const CONTENT_SCRIPT_PING = 'CONTENT_SCRIPT_PING'
/** Background interno: fetch remoto fallback per arricchire metadata */
export const FETCH_METADATA = 'FETCH_METADATA'
