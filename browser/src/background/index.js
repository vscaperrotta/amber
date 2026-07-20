import Browser from 'webextension-polyfill';
import { onAuthStateChanged } from '@firebase/auth';
import { auth } from '../common/firebase.js';
import { deriveItemPreview } from '../utils/deriveItemPreview.js';
import { addLink as dbAddLink, updateLink as dbUpdateLink, patchLinkMetadata as dbPatchMeta, getAllLinks as dbGetAllLinks } from '../utils/db.js';
import { addLink as fbAddLink, updateLink as fbUpdateLink, patchLinkMetadata as fbPatchMeta, getAllLinksOnce as fbGetAllLinksOnce } from '../utils/firebaseDb.js';
import { uploadThumbnail } from '../utils/firebaseStorage.js';
import { normalizeUrl } from '../utils/normalizeUrl.js';
import { ensureContentScript } from '../utils/contentScriptAccess.js';
import {
	SAVE_LINK_LOADING,
	SAVE_LINK_SUCCESS,
	SAVE_LINK_FAILURE,
	SAVE_LINK_DUPLICATE,
	UPDATE_ITEM_PREVIEW,
	FETCH_METADATA,
	METADATA_ENRICHED,
	GET_METADATA,
	TRIGGER_SAVE,
} from '../common/actions.js';

/* Initial Setup
–––––––––––––––––––––––––––––––––––––––––––––––––– */
// Icon is set declaratively via manifest's action.default_icon — no runtime override needed.

// ── Auth helper ──────────────────────────────────────────────────────────────

/**
 * Restituisce l'uid Firebase corrente.
 * Attende fino a 2s per la re-inizializzazione del service worker (MV3).
 */
function getCurrentUid() {
	if (auth.currentUser !== null) return Promise.resolve(auth.currentUser.uid);
	return new Promise((resolve) => {
		const timer = setTimeout(() => { unsubscribe(); resolve(null); }, 2000);
		const unsubscribe = onAuthStateChanged(auth, (user) => {
			clearTimeout(timer);
			unsubscribe();
			resolve(user?.uid ?? null);
		});
	});
}

// ── Save flow ────────────────────────────────────────────────────────────────

/**
 * Orchestratore principale del salvataggio.
 * Pattern adattato da userActions.js + postSave.js del REFERENCE.
 *
 * @param {{ id: number, url: string, title: string }} tab - oggetto tab del browser
 * @param {string|null} [uidOverride] - uid già noto (passato dal popup via TRIGGER_SAVE)
 */
async function saveTab(tab, uidOverride) {
	const { id: tabId, url, title } = tab;
	console.log('[saveTab] start — tabId:', tabId, 'url:', url, 'uidOverride:', uidOverride);

	const contentScriptReady = await ensureContentScript(tab);

	// 1. Notifica il content script: mostra overlay "Salvataggio..."
	if (contentScriptReady) {
		try {
			await Browser.tabs.sendMessage(tabId, { action: SAVE_LINK_LOADING });
			console.log('[saveTab] SAVE_LINK_LOADING sent');
		} catch (err) {
			console.warn('[saveTab] SAVE_LINK_LOADING failed (tab not injectable):', err?.message);
		}
	}

	// 2. Ottieni metadata dal content script (DOM live — fonte migliore)
	let metadata;
	if (contentScriptReady) {
		try {
			metadata = await Browser.tabs.sendMessage(tabId, { action: GET_METADATA });
			console.log('[saveTab] GET_METADATA result:', metadata);
		} catch (err) {
			console.warn('[saveTab] GET_METADATA failed (content script unavailable):', err?.message);
		}
	}

	// 3. Risolve canonical URL se same-origin
	const resolvedUrl = resolveCanonical(url, metadata?.canonicalUrl);

	// 4. Deriva titolo con fallback chain
	const resolvedTitle = title || metadata?.siteName || hostnameFor(resolvedUrl);

	const entry = {
		url: resolvedUrl,
		title: resolvedTitle,
		...(metadata ? { metadata } : {}),
	};

	// 5. Determina uid e salva su DB
	let savedId;
	let uid;
	try {
		uid = uidOverride !== undefined ? uidOverride : await getCurrentUid();
		console.log('[saveTab] resolved uid:', uid);

		const normalized = normalizeUrl(resolvedUrl);
		const existingLinks = uid ? await fbGetAllLinksOnce(uid) : await dbGetAllLinks();
		const duplicate = existingLinks.find((l) => normalizeUrl(l.url) === normalized);
		if (duplicate) {
			console.log('[saveTab] duplicate found — skipping save:', duplicate.id);
			Browser.tabs.sendMessage(tabId, { action: SAVE_LINK_DUPLICATE }).catch(() => { });
			return;
		}

		if (uid) {
			console.log('[saveTab] saving to Firebase...');
			const docRef = await fbAddLink(uid, entry);
			savedId = docRef.id;
			console.log('[saveTab] Firebase save OK — docId:', savedId);
		} else {
			console.log('[saveTab] saving to IndexedDB...');
			savedId = await dbAddLink(entry);
			console.log('[saveTab] IndexedDB save OK — id:', savedId);
		}
	} catch (err) {
		console.error('[saveTab] DB save error:', err);
		Browser.tabs.sendMessage(tabId, {
			action: SAVE_LINK_FAILURE,
			payload: { message: err?.message || 'Salvataggio fallito' },
		}).catch(() => { });
		return;
	}

	// 6. Post-save: deriva preview e notifica il content script
	console.log('[saveTab] save complete — calling saveSuccess');
	await saveSuccess(tabId, savedId, uid, { ...entry, id: savedId });
}

/**
 * Post-save: deriva preview e triggera arricchimento asincrono se necessario.
 * Pattern postSave.js del REFERENCE.
 */
async function saveSuccess(tabId, savedId, uid, entry) {
	const preview = deriveItemPreview(entry);

	// Invia SUCCESS + preview al content script
	Browser.tabs.sendMessage(tabId, {
		action: SAVE_LINK_SUCCESS,
		payload: { preview },
	}).catch(() => { });

	if (!entry.metadata?.thumbnail) {
		// Nessuna thumbnail trovata — cattura screenshot prima che l'utente navighi via
		let screenshot = await captureScreenshot(tabId);
		if (screenshot) {
			if (uid) {
				try {
					screenshot = await uploadThumbnail(uid, savedId, screenshot);
				} catch (err) {
					console.warn('[saveSuccess] Storage upload failed, keeping base64:', err?.message);
				}
			}
			const updatedMeta = { ...(entry.metadata || {}), screenshot };
			if (uid) {
				await fbUpdateLink(uid, savedId, { metadata: updatedMeta });
			} else {
				await dbUpdateLink(savedId, { metadata: updatedMeta });
			}
		}
		// Enrichment asincrono: se trova thumbnail, screenshot viene rimosso;
		// altrimenti viene preservato tramite fallbackScreenshot
		triggerEnrichment({ url: entry.url, id: savedId, uid, tabId, fallbackScreenshot: screenshot });
	}
}

/**
 * Cattura il viewport della tab come JPEG compresso (max 400px larghezza).
 * Usa OffscreenCanvas per ridimensionare senza bloccare il thread principale.
 * Ritorna una data URL base64, o null in caso di errore.
 *
 * @param {number} tabId
 * @returns {Promise<string|null>}
 */
async function captureScreenshot(tabId) {
	if (!tabId) return null;
	try {
		const dataUrl = await Browser.tabs.captureVisibleTab({ format: 'jpeg', quality: 70 });
		if (!dataUrl) return null;

		// Decodifica in blob e ridimensiona a max 400px larghezza
		const blob = await fetch(dataUrl).then(r => r.blob());
		const img = await createImageBitmap(blob);

		const ratio = Math.min(1, 400 / img.width);
		const w = Math.round(img.width * ratio);
		const h = Math.round(img.height * ratio);

		const canvas = new OffscreenCanvas(w, h);
		const ctx = canvas.getContext('2d');
		ctx.drawImage(img, 0, 0, w, h);

		const outBlob = await canvas.convertToBlob({ type: 'image/jpeg', quality: 0.5 });
		const arrayBuffer = await outBlob.arrayBuffer();
		const bytes = new Uint8Array(arrayBuffer);

		// Converti in base64 in chunk per evitare stack overflow su buffer grandi
		const CHUNK = 8192;
		let binary = '';
		for (let i = 0; i < bytes.length; i += CHUNK) {
			binary += String.fromCharCode(...bytes.subarray(i, i + CHUNK));
		}
		return `data:image/jpeg;base64,${btoa(binary)}`;
	} catch (err) {
		console.warn('[captureScreenshot] failed:', err?.message);
		return null;
	}
}

/**
 * Estrae metadata da HTML grezzo usando regex.
 * Non richiede DOMParser — funziona nel background service worker MV3.
 * Gestisce entrambi gli ordini di attributi nei meta tag (property/content e content/property).
 */
function extractMetadataFromHtml(html, baseUrl) {
	function resolveUrl(raw) {
		if (!raw) return '';
		try { return new URL(raw.trim(), baseUrl).href; } catch { return ''; }
	}

	function metaContent(patterns) {
		for (const re of patterns) {
			const m = html.match(re);
			if (m?.[1]?.trim()) return m[1].trim();
		}
		return '';
	}

	// og:image / twitter:image — entrambi gli ordini di attributi
	const thumbnail = resolveUrl(metaContent([
		/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)/i,
		/<meta[^>]+content=["']([^"'<]+)["'][^>]+property=["']og:image["']/i,
		/<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)/i,
		/<meta[^>]+content=["']([^"'<]+)["'][^>]+name=["']twitter:image["']/i,
		/<meta[^>]+name=["']twitter:image:src["'][^>]+content=["']([^"']+)/i,
		/<meta[^>]+content=["']([^"'<]+)["'][^>]+name=["']twitter:image:src["']/i,
	]));

	// JSON-LD image (fallback se og:image manca)
	let jsonLdThumbnail = '';
	if (!thumbnail) {
		const scripts = [...html.matchAll(/<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)];
		for (const m of scripts) {
			try {
				let data = JSON.parse(m[1]);
				if (data?.['@graph']) data = data['@graph'].find(n => n.image) || data['@graph'][0] || data;
				if (Array.isArray(data)) data = data.find(n => n.image) || data[0];
				let img = data?.image;
				if (Array.isArray(img)) img = img[0];
				if (img && typeof img === 'object') img = img.url || img.contentUrl;
				if (typeof img === 'string') { jsonLdThumbnail = resolveUrl(img); break; }
			} catch { /* noop */ }
		}
	}

	// favicon
	const favicon = resolveUrl(metaContent([
		/<link[^>]+rel=["']icon["'][^>]+href=["']([^"']+)/i,
		/<link[^>]+href=["']([^"'<]+)["'][^>]+rel=["']icon["']/i,
		/<link[^>]+rel=["']shortcut icon["'][^>]+href=["']([^"']+)/i,
		/<link[^>]+href=["']([^"'<]+)["'][^>]+rel=["']shortcut icon["']/i,
		/<link[^>]+rel=["']apple-touch-icon["'][^>]+href=["']([^"']+)/i,
		/<link[^>]+href=["']([^"'<]+)["'][^>]+rel=["']apple-touch-icon["']/i,
	])) || resolveUrl('/favicon.ico');

	// description
	const description = metaContent([
		/<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)/i,
		/<meta[^>]+content=["']([^"'<]+)["'][^>]+property=["']og:description["']/i,
		/<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)/i,
		/<meta[^>]+content=["']([^"'<]+)["'][^>]+name=["']description["']/i,
	]).slice(0, 300);

	// siteName
	const siteName = metaContent([
		/<meta[^>]+property=["']og:site_name["'][^>]+content=["']([^"']+)/i,
		/<meta[^>]+content=["']([^"'<]+)["'][^>]+property=["']og:site_name["']/i,
	]);

	// canonicalUrl
	const canonicalUrl = resolveUrl(metaContent([
		/<link[^>]+rel=["']canonical["'][^>]+href=["']([^"']+)/i,
		/<link[^>]+href=["']([^"'<]+)["'][^>]+rel=["']canonical["']/i,
		/<meta[^>]+property=["']og:url["'][^>]+content=["']([^"']+)/i,
		/<meta[^>]+content=["']([^"'<]+)["'][^>]+property=["']og:url["']/i,
	]));

	return {
		thumbnail: thumbnail || jsonLdThumbnail,
		favicon,
		description,
		siteName,
		canonicalUrl,
		author: '',
		publishedDate: '',
		readingTime: 0,
		screenshot: null,
	};
}

/**
 * Fetch remoto per arricchire metadata (fallback quando il content script
 * non ha trovato thumbnail o la tab non era iniettabile).
 *
 * Se l'enrichment trova una thumbnail, rimuove lo screenshot (non più necessario).
 * Se non trova thumbnail, preserva lo screenshot passato come fallbackScreenshot.
 */
function triggerEnrichment({ url, id, uid, tabId, fallbackScreenshot = null }) {
	(async () => {
		const controller = new AbortController();
		const timer = setTimeout(() => controller.abort(), 10000);
		try {
			const res = await fetch(url, {
				signal: controller.signal,
				headers: {
					'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
				},
			});
			clearTimeout(timer);
			if (!res.ok) return;

			const html = await res.text();
			const metadata = extractMetadataFromHtml(html, url);

			// Se enrichment non trova thumbnail, preserva lo screenshot come fallback
			const finalMetadata = {
				screenshot: metadata.thumbnail ? null : fallbackScreenshot,
				...metadata,
			};

			// Patch (non overwrite) — preserva campi non derivati dalla pagina
			// (es. tags, isRead, isFavorite) scritti nel frattempo da altri flussi.
			if (uid) {
				await fbPatchMeta(uid, id, finalMetadata);
			} else {
				await dbPatchMeta(id, finalMetadata);
			}

			// Notifica il content script con la preview aggiornata
			if (tabId) {
				const entry = { url, metadata: finalMetadata };
				const preview = deriveItemPreview(entry);
				Browser.tabs.sendMessage(tabId, {
					action: UPDATE_ITEM_PREVIEW,
					payload: { preview },
				}).catch(() => { });
			}

			// Notifica il popup per aggiornare la lista link
			Browser.runtime.sendMessage({
				action: METADATA_ENRICHED,
				payload: { id },
			}).catch(() => { });

		} catch (err) {
			clearTimeout(timer);
			console.warn('[background] enrichment failed for', url, err?.message);
		}
	})();
}

// ── Toolbar icon click ───────────────────────────────────────────────────────

Browser.action.onClicked.addListener(async (tab) => {
	if (!tab.id || !tab.url) return;
	await saveTab(tab);
});

// ── Keyboard shortcut ────────────────────────────────────────────────────────

Browser.commands.onCommand.addListener(async (command) => {
	if (command !== 'save-current-tab') return;
	const [tab] = await Browser.tabs.query({ active: true, lastFocusedWindow: true });
	if (!tab?.id || !tab.url) return;
	await saveTab(tab);
});

// ── Message router ───────────────────────────────────────────────────────────

Browser.runtime.onMessage.addListener((msg) => {
	console.log('[background] message received:', msg.action, msg.payload);

	// Salvataggio delegato dal popup (porta uid noto)
	if (msg.action === TRIGGER_SAVE) {
		const { tabId, url, title, uid } = msg.payload || {};
		console.log('[background] TRIGGER_SAVE — tabId:', tabId, 'url:', url, 'uid:', uid);
		if (!tabId || !url) {
			console.warn('[background] TRIGGER_SAVE rejected — missing tabId or url');
			return false;
		}
		saveTab({ id: tabId, url, title }, uid ?? null);
		return false;
	}

	// Arricchimento fallback richiesto dal popup (flusso saveCustomLink)
	if (msg.action === FETCH_METADATA) {
		const { url, id, uid, tabId } = msg.payload || {};
		if (!url || !id) return false;
		triggerEnrichment({ url, id, uid: uid ?? null, tabId: tabId ?? null });
		return false;
	}

	return false;
});

// ── Utilities ────────────────────────────────────────────────────────────────

function resolveCanonical(pageUrl, canonicalUrl) {
	if (!canonicalUrl) return pageUrl;
	try {
		const page = new URL(pageUrl);
		const canonical = new URL(canonicalUrl);
		if (canonical.origin === page.origin) return canonical.href;
	} catch { /* noop */ }
	return pageUrl;
}

function hostnameFor(url) {
	try { return new URL(url).hostname.replace(/^www\./, ''); } catch { return url; }
}
