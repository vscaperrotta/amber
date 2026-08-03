const JSON_LD_TYPES = new Set([
	'Article', 'NewsArticle', 'BlogPosting', 'TechArticle',
	'Product', 'Recipe', 'VideoObject', 'WebPage', 'SoftwareApplication',
]);

/**
 * Parsa tutti i blocchi <script type="application/ld+json"> nel documento.
 * Ritorna il primo oggetto con un campo image appartenente a un tipo supportato.
 *
 * @param {Document} doc
 * @returns {{ image: string|null, description: string|null, author: string|null, datePublished: string|null, name: string|null }|null}
 */
function parseJsonLd(doc) {
	const scripts = doc.querySelectorAll('script[type="application/ld+json"]');
	for (const script of scripts) {
		try {
			let data = JSON.parse(script.textContent || '');

			// Gestisce @graph (array di nodi Schema.org)
			if (data && data['@graph'] && Array.isArray(data['@graph'])) {
				data = data['@graph'].find(n => n.image) || data['@graph'][0] || data;
			}
			if (Array.isArray(data)) {
				data = data.find(n => n.image) || data[0];
			}
			if (!data || typeof data !== 'object') continue;

			// Verifica tipo supportato (accetta anche senza tipo se ha image)
			const type = data['@type'];
			const typeOk = !type
				|| (typeof type === 'string' && JSON_LD_TYPES.has(type))
				|| (Array.isArray(type) && type.some(t => JSON_LD_TYPES.has(t)));
			if (!typeOk && !data.image) continue;

			// Normalizza image (stringa, oggetto {url/contentUrl}, o array)
			let image = data.image;
			if (Array.isArray(image)) image = image[0];
			if (image && typeof image === 'object') {
				image = image.url || image.contentUrl || null;
			}

			// Normalizza author (stringa o oggetto {name}, o array)
			let author = data.author;
			if (Array.isArray(author)) author = author[0];
			if (author && typeof author === 'object') author = author.name || null;

			return {
				image:         typeof image === 'string' ? image : null,
				description:   typeof data.description === 'string' ? data.description : null,
				author:        typeof author === 'string' ? author : null,
				datePublished: data.datePublished || data.dateCreated || null,
				name:          data.name || data.headline || null,
			};
		} catch {
			// JSON non valido — skip
		}
	}
	return null;
}

const NOISE_IMG_RE = /\/(icon|logo|avatar|sprite|pixel|tracking|badge|btn|button|arrow|star|rating|ad[_\-])/i;

/**
 * Trova il primo <img> significativo nell'area principale del documento.
 * Funziona meglio nel content script (DOM live, naturalWidth disponibile).
 * Nel DOMParser del background le dimensioni sono 0 — usa solo il filtro regex sul src.
 *
 * @param {Document} doc
 * @returns {string|null} URL src dell'immagine, o null
 */
function findLargestImg(doc) {
	try {
		const container = doc.querySelector('article, main, [role="main"]') || doc.body;
		if (!container) return null;

		const imgs = [...container.querySelectorAll('img[src]')].filter(img => {
			const src = img.getAttribute('src') || '';
			if (!src || src.startsWith('data:')) return false;
			if (NOISE_IMG_RE.test(src)) return false;
			return true;
		});

		// Ordina per area (naturalWidth*naturalHeight se disponibile, poi attributi)
		imgs.sort((a, b) => {
			const aW = a.naturalWidth || parseInt(a.getAttribute('width') || '0', 10);
			const aH = a.naturalHeight || parseInt(a.getAttribute('height') || '0', 10);
			const bW = b.naturalWidth || parseInt(b.getAttribute('width') || '0', 10);
			const bH = b.naturalHeight || parseInt(b.getAttribute('height') || '0', 10);
			return (bW * bH) - (aW * aH);
		});

		// Accetta solo se almeno una dimensione > 200
		const best = imgs.find(img => {
			const w = img.naturalWidth || parseInt(img.getAttribute('width') || '0', 10);
			const h = img.naturalHeight || parseInt(img.getAttribute('height') || '0', 10);
			return w > 200 || h > 200;
		});

		return best ? best.getAttribute('src') : null;
	} catch {
		return null;
	}
}

/**
 * Estrae Open Graph + JSON-LD + meta tag metadata da un Document.
 * Funziona nel content script (DOM live) e nel background service worker (DOMParser).
 *
 * Priorità thumbnail: JSON-LD image → og:image → twitter:image → largest DOM img
 *
 * @param {Document} doc
 * @param {string} baseUrl - URL base per risolvere URL relativi
 * @param {string} bodyText - Testo estratto dal body (opzionale, usato per readingTime)
 * @returns {{
 *   description: string, thumbnail: string, favicon: string, siteName: string,
 *   tags: string[], canonicalUrl: string, author: string,
 *   publishedDate: string, readingTime: number, screenshot: null
 * }}
 */
export function extractMetadata(doc = document, baseUrl = '', bodyText = '') {
	function getMeta(...selectors) {
		for (const sel of selectors) {
			try {
				const el = doc.querySelector(sel);
				if (!el) continue;
				const val = el.getAttribute('content') || el.getAttribute('href') || el.getAttribute('datetime') || '';
				if (val.trim()) return val.trim();
			} catch {
				// selettore non valido — skip
			}
		}
		return '';
	}

	function resolveUrl(raw) {
		if (!raw) return '';
		try {
			return new URL(raw, baseUrl).href;
		} catch {
			return '';
		}
	}

	// ── JSON-LD (fonte dati strutturati, spesso più ricca degli OG tag) ──────
	const jsonLd = parseJsonLd(doc);

	// ── Thumbnail ────────────────────────────────────────────────────────────
	// Priorità: JSON-LD image → og:image → twitter:image → largest DOM img
	const thumbnail = resolveUrl(jsonLd?.image)
		|| resolveUrl(getMeta(
			'meta[property="og:image"]',
			'meta[name="twitter:image"]',
			'meta[name="twitter:image:src"]',
		))
		|| resolveUrl(findLargestImg(doc));

	// ── Description ─────────────────────────────────────────────────────────
	const description = (
		getMeta(
			'meta[property="og:description"]',
			'meta[name="description"]',
			'meta[name="twitter:description"]',
		) || jsonLd?.description || ''
	).slice(0, 300);

	// ── Favicon ──────────────────────────────────────────────────────────────
	const faviconRaw = getMeta(
		'link[rel="icon"]',
		'link[rel="shortcut icon"]',
		'link[rel="apple-touch-icon"]',
	);
	const favicon = faviconRaw
		? resolveUrl(faviconRaw)
		: (baseUrl ? resolveUrl('/favicon.ico') : '');

	// ── Site name ────────────────────────────────────────────────────────────
	const siteName = getMeta('meta[property="og:site_name"]') || jsonLd?.name || '';

	// ── Canonical URL ────────────────────────────────────────────────────────
	const canonicalUrl = resolveUrl(getMeta(
		'link[rel="canonical"]',
		'meta[property="og:url"]',
	));

	// ── Author ───────────────────────────────────────────────────────────────
	const author = getMeta(
		'meta[name="author"]',
		'meta[property="article:author"]',
		'meta[name="twitter:creator"]',
	) || jsonLd?.author || '';

	// ── Published date ───────────────────────────────────────────────────────
	const publishedDate = getMeta(
		'meta[property="article:published_time"]',
		'time[datetime]',
		'meta[name="date"]',
		'meta[name="pubdate"]',
	) || jsonLd?.datePublished || '';

	// ── Reading time (derived from body text word count) ─────────────────────
	const wordCount = bodyText ? bodyText.split(/\s+/).filter(Boolean).length : 0;
	const readingTime = wordCount > 0 ? Math.ceil(wordCount / 200) : 0;

	// ── Tags ─────────────────────────────────────────────────────────────────
	// Nessuna generazione automatica: i tag si inseriscono a mano dal TagEditor.
	const tags = [];

	// screenshot: null — campo predisposto, viene popolato dal background service worker
	// come fallback finale quando nessuna fonte sopra ha prodotto una thumbnail
	return { description, thumbnail, favicon, siteName, tags, canonicalUrl, author, publishedDate, readingTime, screenshot: null };
}
