# P0 Competitor-Parity Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Verification note:** `browser/AGENTS.md.md` states no test runner is configured in this repo. Every "Verify" step below is `npm run lint` + `npm run build` (must stay clean) plus a manual trace/check — this replaces the skill's default "write failing test, watch it fail, make it pass" loop, per the project's actual testing convention (already used for every prior feature this session).

**Goal:** Ship the 4 P0 features from `docs/superpowers/specs/2026-06-16-competitor-parity-features-design.md`: duplicate detection, wider full-text search, bulk bookmark import, keyboard shortcuts.

**Architecture:** All four are additive changes to `browser/src/`. Duplicate detection touches every save entry point (popup, manual-add modal, background service worker) plus a new shared `normalizeUrl` util. Search widening is a 2-line filter change in two view files. Bulk import is a new section in the Options page using the existing AI-batch-progress UI pattern. Keyboard shortcuts reactivate the already-built-but-unreachable `saveTab()` background function via a new `manifest.commands` entry.

**Tech Stack:** React 19, Firebase (Firestore + Auth client SDK), IndexedDB (local fallback), `webextension-polyfill`, Vite.

All paths below are relative to `browser/`.

---

### Task 1: Duplicate detection

**Files:**
- Create: `src/utils/normalizeUrl.js`
- Modify: `src/utils/firebaseDb.js`
- Modify: `src/utils/useLinks.js`
- Modify: `src/background/index.js`
- Modify: `src/common/actions.js`
- Modify: `src/content/SaveOverlay.jsx`
- Modify: `src/popup/App.jsx`
- Modify: `src/newtab/components/Main.jsx`
- Modify: `src/newtab/components/EditModal.jsx`
- Modify: `src/utils/i18n.js`

- [ ] **Step 1: Create the URL-normalization util**

`src/utils/normalizeUrl.js`:
```js
const TRACKING_PARAMS = [
	'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
	'fbclid', 'gclid', 'igshid', 'si', 'ref',
];

/**
 * Normalizes a URL for duplicate comparison: strips www., trailing slash,
 * and known tracking query params, lowercases the result. Not for display —
 * comparison only.
 */
export function normalizeUrl(rawUrl) {
	try {
		const u = new URL(rawUrl);
		const host = u.hostname.replace(/^www\./, '');
		const path = u.pathname.replace(/\/+$/, '') || '/';
		const params = new URLSearchParams(u.search);
		TRACKING_PARAMS.forEach((p) => params.delete(p));
		const sorted = new URLSearchParams([...params.entries()].sort());
		const query = sorted.toString();
		return `${host}${path}${query ? `?${query}` : ''}`.toLowerCase();
	} catch {
		return (rawUrl || '').trim().toLowerCase();
	}
}
```

- [ ] **Step 2: Add a one-off Firestore fetch for the background service worker**

The service worker doesn't keep the real-time `onSnapshot` link list in memory like the popup/newtab do — it needs a one-shot read to check duplicates. Add to `src/utils/firebaseDb.js`, after the existing `import` block (add `getDocs` to the firestore import) and after `subscribeLinks`:

```js
import {
  collection,
  addDoc,
  deleteDoc,
  doc,
  updateDoc,
  onSnapshot,
  query,
  orderBy,
  getDocs,
} from 'firebase/firestore';
```

```js
/**
 * One-off fetch of all the user's links (no real-time subscription).
 * Used by the background service worker, which doesn't hold a live link list.
 * @param {string} uid
 * @returns {Promise<Array>}
 */
export async function getAllLinksOnce(uid) {
  const snapshot = await getDocs(collection(db, `users/${uid}/links`));
  return snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
}
```

- [ ] **Step 3: Add the duplicate action constant**

Append to `src/common/actions.js`:
```js
/** Background → content script: salvataggio saltato, link già esistente */
export const SAVE_LINK_DUPLICATE = 'SAVE_LINK_DUPLICATE'
```

- [ ] **Step 4: Check for duplicates in `useLinks.js` (popup + newtab manual-add path)**

In `src/utils/useLinks.js`, add the import:
```js
import { normalizeUrl } from './normalizeUrl.js';
```

Modify `saveCurrentTab` — insert the duplicate check right after `const entry = {...}` is built (before `const uid = userRef.current?.uid ?? null;`), and change the dependency array to include `links`:

```js
    const entry = {
      url: tab.url,
      title: tab.title || metadata?.siteName || tab.url,
      ...(metadata ? { metadata } : {}),
    };

    const normalized = normalizeUrl(entry.url);
    const existingLink = links.find((l) => normalizeUrl(l.url) === normalized);
    if (existingLink) {
      console.log('[saveCurrentTab] duplicate detected:', existingLink.id);
      return { duplicate: true, existingLink };
    }

    const uid = userRef.current?.uid ?? null;
    let savedId;
```

And at the end of the function, change both branches' tail to return a consistent shape:
```js
      _tryGenerateAiDescription({ url: entry.url, title: entry.title, id: savedId, uid, loadLocal: null });
    } else {
      console.log('[saveCurrentTab] saving to IndexedDB');
      const newId = await dbAddLink(entry);
      savedId = newId;
      console.log('[saveCurrentTab] IndexedDB save OK — id:', savedId);
      await loadLocalLinks();
      if (!metadata?.thumbnail) {
        Browser.runtime.sendMessage({
          action: FETCH_METADATA,
          payload: { url: entry.url, id: savedId, uid: null, tabId: tab.id },
        }).catch(() => { });
      }
      _tryGenerateAiDescription({ url: entry.url, title: entry.title, id: savedId, uid: null, loadLocal: loadLocalLinks });
    }
    return { duplicate: false, savedId };
  }, [loadLocalLinks, links]);
```

Modify `saveCustomLink` similarly — insert the check after `const entry = { url, title: title || url };`:
```js
  const saveCustomLink = useCallback(async ({ url, title } = {}) => {
    if (!url) return;
    const entry = { url, title: title || url };

    const normalized = normalizeUrl(entry.url);
    const existingLink = links.find((l) => normalizeUrl(l.url) === normalized);
    if (existingLink) {
      console.log('[saveCustomLink] duplicate detected:', existingLink.id);
      return { duplicate: true, existingLink };
    }

    if (userRef.current) {
```

And give it a successful-path return value too — change the two inner `try` blocks' last line before each `catch`:
```js
      try {
        const docRef = await fbAddLink(userRef.current.uid, entry);
        Browser.runtime.sendMessage({
          action: FETCH_METADATA,
          payload: { url, id: docRef.id, uid: userRef.current.uid, tabId: null },
        }).catch(() => { });
        _tryGenerateAiDescription({ url, title: title || url, id: docRef.id, uid: userRef.current.uid, loadLocal: null });
        return { duplicate: false, savedId: docRef.id };
      } catch (err) {
        console.error('[useLinks] fbAddLink error (custom)', err);
        throw err;
      }
    } else {
      try {
        const newId = await dbAddLink(entry);
        await loadLocalLinks();
        Browser.runtime.sendMessage({
          action: FETCH_METADATA,
          payload: { url, id: newId, uid: null, tabId: null },
        }).catch(() => { });
        _tryGenerateAiDescription({ url, title: title || url, id: newId, uid: null, loadLocal: loadLocalLinks });
        return { duplicate: false, savedId: newId };
      } catch (err) {
        console.error('[useLinks] dbAddLink error (custom)', err);
        throw err;
      }
    }
  }, [loadLocalLinks, links]);
```

- [ ] **Step 5: Check for duplicates in the background service worker (keyboard-shortcut save path)**

In `src/background/index.js`, update the imports:
```js
import { addLink as dbAddLink, updateLink as dbUpdateLink, patchLinkMetadata as dbPatchMeta, getAllLinks as dbGetAllLinks } from '../utils/db.js';
import { addLink as fbAddLink, updateLink as fbUpdateLink, patchLinkMetadata as fbPatchMeta, getAllLinksOnce as fbGetAllLinksOnce } from '../utils/firebaseDb.js';
import { normalizeUrl } from '../utils/normalizeUrl.js';
```
```js
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
```

Modify the "5. Determina uid e salva su DB" block inside `saveTab()`:
```js
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
```

- [ ] **Step 6: Show "already saved" in the content-script overlay**

In `src/content/SaveOverlay.jsx`, update the import and status union:
```js
import {
	SAVE_LINK_LOADING,
	SAVE_LINK_SUCCESS,
	SAVE_LINK_FAILURE,
	SAVE_LINK_DUPLICATE,
	UPDATE_ITEM_PREVIEW,
} from '../common/actions.js';
```
```js
	const [status, setStatus] = useState('loading'); // 'loading' | 'saved' | 'error' | 'duplicate'
```
Add a case to the message switch:
```js
				case SAVE_LINK_FAILURE:
					setStatus('error');
					setErrorMsg(msg.payload?.message || t('overlay.error'));
					break;
				case SAVE_LINK_DUPLICATE:
					setStatus('duplicate');
					break;
```
Update the status icon and label rows:
```js
				<span style={{ fontSize: '16px', lineHeight: 1 }}>
					{status === 'loading' && <LoadingSpinner color={tokens.accent} />}
					{status === 'saved' && <CheckIcon color={tokens.accent} />}
					{status === 'error' && <ErrorIcon color={tokens.error} />}
					{status === 'duplicate' && <CheckIcon color={tokens.textSecondary} />}
				</span>

				<span style={{ fontSize: '14px', fontWeight: 600, color: tokens.text, flex: 1 }}>
					{status === 'loading' && t('overlay.saving')}
					{status === 'saved' && t('overlay.saved')}
					{status === 'error' && t('overlay.error')}
					{status === 'duplicate' && t('overlay.duplicate')}
				</span>
```
Add `'duplicate'` to the auto-dismiss effect's trigger condition:
```js
	useEffect(() => {
		if (status !== 'saved' && status !== 'duplicate') return;
		const timer = setTimeout(dismiss, AUTO_DISMISS_MS);
		return () => clearTimeout(timer);
	}, [status, dismiss]);
```

- [ ] **Step 7: Surface duplicates in the popup**

In `src/popup/App.jsx`, modify `handleSaveCurrentTab` and `handleSaveCustom`:
```js
	async function handleSaveCurrentTab() {
		setSaving(true);
		setSaveError('');
		try {
			const result = await saveCurrentTab();
			if (result?.duplicate) {
				setSaveError(t('popup.duplicateLink'));
			}
		} catch (err) {
			console.error('[popup] handleSaveCurrentTab — error:', err?.message ?? err);
			setSaveError(t('popup.errorSave'));
		} finally {
			setSaving(false);
		}
	}
```
```js
	async function handleSaveCustom() {
		if (!customUrl) {
			setUrlError(t('popup.errorUrl'));
			return;
		}
		if (!validateUrl(customUrl)) {
			setUrlError(t('popup.errorUrlInvalid'));
			return;
		}
		setUrlError('');
		try {
			const result = await saveCustomLink({ url: customUrl, title: customTitle });
			if (result?.duplicate) {
				setUrlError(t('popup.duplicateLink'));
				return;
			}
			setCustomUrl('');
			setCustomTitle('');
			setAddManually(false);
		} catch (err) {
			console.error('[popup] handleSaveCustom — error:', err?.message ?? err);
			setUrlError(t('popup.errorSave'));
		}
	}
```

- [ ] **Step 8: Surface duplicates in the newtab "add manually" modal**

In `src/newtab/components/Main.jsx`, modify `handleAdd`:
```js
	async function handleAdd(updates) {
		setIsSaving(true);
		setSaveError(null);
		try {
			const result = await saveCustomLink(updates);
			if (result?.duplicate) {
				setSaveError('duplicate');
				setIsSaving(false);
				return;
			}
			closeModal();
		} catch (err) {
			console.error('[Main] saveCustomLink error', err);
			setIsSaving(false);
			setSaveError(true);
		}
	}
```

In `src/newtab/components/EditModal.jsx`, widen the `saveError` prop and branch the message. Current code:
```jsx
			{saveError && (
				<p className="user-modal__error" role="alert">{t('editModal.saveError')}</p>
```
New:
```jsx
			{saveError && (
				<p className="user-modal__error" role="alert">
					{saveError === 'duplicate' ? t('editModal.duplicateError') : t('editModal.saveError')}
				</p>
```
Update its `propTypes`/`defaultProps`:
```js
	saveError: PropTypes.oneOfType([PropTypes.bool, PropTypes.string]),
```
(`defaultProps` stays `saveError: false`.)

- [ ] **Step 9: Add i18n keys (EN + IT)**

In `src/utils/i18n.js`, EN block — add near the existing `'overlay.error'` key:
```js
		'overlay.duplicate': 'Already saved',
```
Near `'popup.errorSave'`:
```js
		'popup.duplicateLink': 'This link is already saved.',
```
Near `'editModal.saveError'`:
```js
		'editModal.duplicateError': 'This link is already saved.',
```
IT block, mirroring the same insertion points:
```js
		'overlay.duplicate': 'Già salvato',
```
```js
		'popup.duplicateLink': 'Questo link è già stato salvato.',
```
```js
		'editModal.duplicateError': 'Questo link è già stato salvato.',
```

- [ ] **Step 10: Verify**

Run from `browser/`:
```bash
npm run lint
npm run build
```
Expected: no new errors/warnings beyond the pre-existing baseline (process/chrome/prop-types warnings already present before this task), build succeeds, zip created.

Manual trace check (no live browser needed for this one — pure logic): re-read `normalizeUrl('https://www.Example.com/Page/?utm_source=x')` and `normalizeUrl('https://example.com/page')` mentally/in a scratch Node REPL — both must produce `example.com/page`. Run:
```bash
node -e "
const { normalizeUrl } = await import('./src/utils/normalizeUrl.js');
console.log(normalizeUrl('https://www.Example.com/Page/?utm_source=x'));
console.log(normalizeUrl('https://example.com/page'));
"
```
Expected: both lines print `example.com/page`.

- [ ] **Step 11: Commit (HELD — do not run until user gives explicit final approval)**
```bash
git add src/utils/normalizeUrl.js src/utils/firebaseDb.js src/utils/useLinks.js src/background/index.js src/common/actions.js src/content/SaveOverlay.jsx src/popup/App.jsx src/newtab/components/Main.jsx src/newtab/components/EditModal.jsx src/utils/i18n.js
git commit -m "feat(browser): detect duplicate links across all save paths"
```

---

### Task 2: Wider full-text search

**Files:**
- Modify: `src/newtab/views/HomeView.jsx`
- Modify: `src/newtab/views/FavoritesView.jsx`

- [ ] **Step 1: Widen the match clause in `HomeView.jsx`**

Add the import:
```js
import { extractDomain } from '@utils/domain';
```
Current filter block:
```js
    const q = searchQuery.trim().toLowerCase();
    if (q) {
      result = result.filter(l =>
        (l.title || '').toLowerCase().includes(q) ||
        l.url.toLowerCase().includes(q) ||
        (l.metadata?.description || '').toLowerCase().includes(q)
      );
    }
```
New:
```js
    const q = searchQuery.trim().toLowerCase();
    if (q) {
      result = result.filter(l =>
        (l.title || '').toLowerCase().includes(q) ||
        l.url.toLowerCase().includes(q) ||
        (l.metadata?.description || '').toLowerCase().includes(q) ||
        extractDomain(l.url).toLowerCase().includes(q) ||
        (l.metadata?.tags || []).join(' ').toLowerCase().includes(q)
      );
    }
```

- [ ] **Step 2: Same change in `FavoritesView.jsx`**

Add the same `import { extractDomain } from '@utils/domain';` and apply the identical filter-block edit (it's byte-for-byte the same block in this file).

- [ ] **Step 3: Verify**

```bash
npm run lint
npm run build
```
Expected: clean (no new errors).

Manual check: open the real installed extension's newtab page (per this session's established method — screenshot via the granted Microsoft Edge read-tier access, since AI-in-Chrome can't reach another extension's pages). Type a tag name or a bare domain fragment (e.g. `youtube`) into the search box that does **not** appear in any saved title/URL/description, confirm matching cards now show up.

- [ ] **Step 4: Commit (HELD)**
```bash
git add src/newtab/views/HomeView.jsx src/newtab/views/FavoritesView.jsx
git commit -m "feat(browser): widen newtab search to tags and domain"
```

---

### Task 3: Bulk import (bookmarks HTML)

**Files:**
- Modify: `src/options/App.jsx`
- Modify: `src/utils/i18n.js`

- [ ] **Step 1: Write the parser as a pure function inside `options/App.jsx`**

Add near the top of the file, after the existing imports, before the component:
```js
/**
 * Parses a Netscape-format bookmarks export (the universal format Chrome,
 * Firefox, Raindrop, and Pocket all produce). Returns a flat list of
 * { url, title, tag } — `tag` is the nearest enclosing folder name, or '' for
 * bookmarks at the root.
 */
function parseBookmarksHtml(html) {
	const doc = new DOMParser().parseFromString(html, 'text/html');
	const results = [];

	function walk(node, currentFolder) {
		for (const child of node.children) {
			if (child.tagName === 'DT') {
				const folderHeading = child.querySelector(':scope > H3');
				const link = child.querySelector(':scope > A');
				if (folderHeading) {
					const nextDl = child.querySelector(':scope > DL');
					if (nextDl) walk(nextDl, folderHeading.textContent.trim());
				} else if (link) {
					const url = link.getAttribute('href') || '';
					if (url.startsWith('http://') || url.startsWith('https://')) {
						results.push({ url, title: link.textContent.trim() || url, tag: currentFolder });
					}
				}
			} else if (child.tagName === 'DL') {
				walk(child, currentFolder);
			}
		}
	}

	const rootDl = doc.querySelector('DL');
	if (rootDl) walk(rootDl, '');
	return results;
}
```

- [ ] **Step 2: Add import state**

In the component body, alongside the existing `bulkGenerating`/`bulkProgress`/`bulkResult` state:
```js
	const [importing, setImporting] = useState(false);
	const [importProgress, setImportProgress] = useState(null);
	const [importResult, setImportResult] = useState(null);
```

- [ ] **Step 3: Add the import handler**

`useLinks()` is already destructured at the top of the component (`const { links, updateLink } = useLinks();`) — widen it to also pull `saveCustomLink`:
```js
	const { links, updateLink, saveCustomLink } = useLinks();
```

Add the handler function near `handleExport`:
```js
	async function handleImportFile(e) {
		const file = e.target.files?.[0];
		e.target.value = '';
		if (!file) return;

		setImportResult(null);
		let entries;
		try {
			const html = await file.text();
			entries = parseBookmarksHtml(html);
		} catch (err) {
			console.error('[options] bookmarks parse error', err);
			setImportResult({ error: true });
			return;
		}

		if (entries.length === 0) {
			setImportResult({ error: true });
			return;
		}

		setImporting(true);
		setImportProgress({ done: 0, total: entries.length });
		let imported = 0;
		let skipped = 0;

		for (const entry of entries) {
			try {
				const result = await saveCustomLink({ url: entry.url, title: entry.title });
				if (result?.duplicate) {
					skipped += 1;
				} else {
					imported += 1;
					if (entry.tag) {
						await updateLink(result.savedId, { metadata: { tags: [entry.tag.toUpperCase()] } });
					}
				}
			} catch (err) {
				console.warn('[options] import entry failed', entry.url, err?.message);
			}
			setImportProgress((p) => ({ done: p.done + 1, total: p.total }));
		}

		setImporting(false);
		setImportResult({ error: false, imported, skipped });
	}
```

This depends on Task 1's `saveCustomLink` returning `{ duplicate, savedId }` — **do Task 1 before this task.**

- [ ] **Step 4: Add the UI section**

In the Preferences section (right after the `showDescription` toggle row added earlier this session, still inside the same `<section className="options__section">` for Preferences — or as its own new section; use its own section for clarity since it's a distinct action, not a passive preference). Insert a new section after the existing Preferences `</section>` and before the Header Links section:
```jsx
			{/* Import */}
			<section className="options__section">
				<h2 className="options__section-title">{t('options.importSection')}</h2>
				<hr className="options__section-divider" />
				<div className="options__export-row">
					<div className="options__export-label">
						<span className="options__export-title">{t('options.importSection')}</span>
						<span className="options__export-desc">{t('options.importDesc')}</span>
					</div>
					<label className="options__view-btn" style={{ cursor: 'pointer' }}>
						<Upload size={14} />
						{t('options.importBtn')}
						<input
							type="file"
							accept=".html,.htm"
							onChange={handleImportFile}
							disabled={importing}
							style={{ display: 'none' }}
						/>
					</label>
				</div>
				{importing && importProgress && (
					<p className="options__ai-bulk-status">
						{t('options.importProgress', { done: importProgress.done, total: importProgress.total })}
					</p>
				)}
				{!importing && importResult && (
					<p className={`options__ai-bulk-status${importResult.error ? ' options__ai-bulk-status--error' : ' options__ai-bulk-status--done'}`}>
						{importResult.error
							? t('options.importError')
							: t('options.importDone', { count: importResult.imported, skipped: importResult.skipped })}
					</p>
				)}
			</section>
```

Add `Upload` to the lucide-react import:
```js
import { LayoutGrid, List, Download, Upload, Sparkles } from 'lucide-react';
```

- [ ] **Step 5: Add i18n keys (EN + IT)**

EN block, near `'options.exportBtn'`:
```js
		'options.importSection': 'Import bookmarks',
		'options.importDesc': 'Import from a browser bookmarks export (HTML file).',
		'options.importBtn': 'Choose file',
		'options.importProgress': 'Importing… {done}/{total}',
		'options.importDone': 'Done — {count} imported, {skipped} duplicates skipped',
		'options.importError': "Couldn't read that file. Make sure it's a bookmarks HTML export.",
```
IT block, same insertion point:
```js
		'options.importSection': 'Importa bookmark',
		'options.importDesc': 'Importa da un\'esportazione bookmark del browser (file HTML).',
		'options.importBtn': 'Scegli file',
		'options.importProgress': 'Importazione… {done}/{total}',
		'options.importDone': 'Completato — {count} importati, {skipped} duplicati ignorati',
		'options.importError': 'File non leggibile. Assicurati sia un export HTML dei bookmark.',
```

- [ ] **Step 6: Verify**

```bash
npm run lint
npm run build
```
Expected: clean.

Manual check: in Chrome, `chrome://bookmarks` → "⋮" menu → "Export bookmarks" to get a real Netscape HTML file. Load the built extension's Options page (real installed extension, screenshot-verified per this session's established method), use the new "Choose file" control, confirm the progress text appears and the link count in the Collection section increases by the right amount (minus any duplicates already saved).

- [ ] **Step 7: Commit (HELD)**
```bash
git add src/options/App.jsx src/utils/i18n.js
git commit -m "feat(browser): import bookmarks from HTML export"
```

---

### Task 4: Keyboard shortcuts

**Files:**
- Modify: `src/manifest.js`
- Modify: `src/background/index.js`
- Modify: `src/newtab/views/HomeView.jsx`

- [ ] **Step 1: Declare the global shortcut in the manifest**

In `src/manifest.js`, add a `commands` key to the manifest object (after `content_security_policy` is fine, order doesn't matter for `manifest.json`):
```js
    content_security_policy: {
      extension_pages: [
        "script-src 'self'",
        "object-src 'self'",
        "connect-src https: wss: http://localhost:*",
      ].join('; ')
    },
    commands: {
      "save-current-tab": {
        suggested_key: {
          default: "Ctrl+Shift+S",
          mac: "Command+Shift+S"
        },
        description: "Save the current tab to Amber"
      }
    }
```
(Note the added trailing comma after the `content_security_policy` block's closing `}`.)

- [ ] **Step 2: Handle the command in the background script**

In `src/background/index.js`, near the existing `Browser.action.onClicked` listener:
```js
Browser.action.onClicked.addListener(async (tab) => {
	if (!tab.id || !tab.url) return;
	await saveTab(tab);
});

Browser.commands.onCommand.addListener(async (command) => {
	if (command !== 'save-current-tab') return;
	const [tab] = await Browser.tabs.query({ active: true, lastFocusedWindow: true });
	if (!tab?.id || !tab.url) return;
	await saveTab(tab);
});
```

- [ ] **Step 3: Add the `/` search-focus shortcut on the newtab page**

In `src/newtab/views/HomeView.jsx`, give the search `Input` a stable id:
```jsx
          <div className="newtab__toolbar-search">
            <Input
              id="newtab-search-input"
              type="text"
              placeholder={t('common.search') + '...'}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
```
Add an effect (anywhere among the other `useEffect`s in the component, e.g. right after the `settingsApplied` effect):
```js
  useEffect(() => {
    function handleKeyDown(e) {
      if (e.key !== '/') return;
      const tag = document.activeElement?.tagName;
      if (tag === 'INPUT' || tag === 'TEXTAREA') return;
      e.preventDefault();
      document.getElementById('newtab-search-input')?.focus();
    }
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);
```

- [ ] **Step 4: Verify**

```bash
npm run lint
npm run build
```
Expected: clean.

Manual check (real installed extension, reload it at `chrome://extensions/` after rebuild so the new manifest commands register):
1. Visit `chrome://extensions/shortcuts` — confirm "Amber" now lists "Save the current tab to Amber" with the `Ctrl+Shift+S` / `Cmd+Shift+S` default.
2. On any normal webpage, press the shortcut — confirm the save overlay appears (loading → saved, or → "Already saved" if that page was already saved, proving Task 1's wiring works end to end).
3. On the newtab page, click somewhere that isn't an input, press `/` — confirm the search box gets focus. Then click into the title field of "Add manually" (if open) and press `/` — confirm it types a literal `/` instead of stealing focus (the `tagName` guard).

- [ ] **Step 5: Commit (HELD)**
```bash
git add src/manifest.js src/background/index.js src/newtab/views/HomeView.jsx
git commit -m "feat(browser): add save-current-tab and search-focus shortcuts"
```

---

## Plan self-review

**Spec coverage:** Task 1 → spec item 1 (duplicate detection). Task 2 → spec item 2 (search widening). Task 3 → spec item 3 (bulk import). Task 4 → spec item 4 (keyboard shortcuts). All four P0 spec items have a task.

**Dependency order:** Task 1 must land before Task 3 (import relies on `saveCustomLink`'s new `{ duplicate, savedId }` return shape) and before Task 4's manual-verification step 2 (which exercises the duplicate path). Tasks are listed in dependency-safe order already.

**Type consistency check:** `saveCurrentTab()` and `saveCustomLink()` both now resolve to `{ duplicate: boolean, savedId? , existingLink? }` everywhere they're read (`popup/App.jsx`, `newtab/components/Main.jsx`, `options/App.jsx`'s new import handler) — consistent shape used in every consumer in this plan.
