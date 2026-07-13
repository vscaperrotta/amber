import { useState, useMemo } from 'react';
import {
	signOut,
	signInWithEmailAndPassword,
	signInWithPopup,
	GoogleAuthProvider,
} from '@firebase/auth';
import { LayoutGrid, List, Download, Upload } from 'lucide-react';
import Browser from 'webextension-polyfill';
import { APP_NAME, APP_VERSION } from '../common/constants.js';
import '@styles/main.scss';
import '@styles/layout/options.scss';
import { useAuth } from '@contexts/AuthContext.jsx';
import { useLinks } from '@utils/useLinks.js';
import { auth } from '../common/firebase.js';
import ConfirmModal from '@components/ConfirmModal';
import { mapFirebaseError } from '@utils/authErrors.js';
import { useUserSettings } from '@utils/useUserSettings.js';
import AccountInfo from './components/AccountInfo.jsx';
import AccountForm from './components/AccountForm.jsx';
import HeaderLinksSection from './components/HeaderLinksSection.jsx';
import { t } from '@utils/i18n';

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

export default function App() {
	const { user, authReady } = useAuth();
	const { links, updateLink, saveCustomLink } = useLinks();
	const { settings, updateSettings, loading: settingsLoading } = useUserSettings();
	const [email, setEmail] = useState('');
	const [password, setPassword] = useState('');
	const [error, setError] = useState('');
	const [loading, setLoading] = useState(false);
	const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
	const [importing, setImporting] = useState(false);
	const [importProgress, setImportProgress] = useState(null);
	const [importResult, setImportResult] = useState(null);

	const stats = useMemo(() => ({
		total: links.length,
		favorites: links.filter(l => l.metadata?.isFavorite).length,
	}), [links]);

	async function handleSignIn(e) {
		e.preventDefault();
		setError('');
		setLoading(true);
		try {
			await signInWithEmailAndPassword(auth, email, password);
			setEmail('');
			setPassword('');
		} catch (err) {
			const msg = mapFirebaseError(err.code);
			if (msg) setError(msg);
		} finally {
			setLoading(false);
		}
	}

	async function handleGoogleSignIn() {
		setError('');
		setLoading(true);
		try {
			await signInWithPopup(auth, new GoogleAuthProvider());
		} catch (err) {
			const msg = mapFirebaseError(err.code);
			if (msg) setError(msg);
		} finally {
			setLoading(false);
		}
	}

	async function handleSignOut() {
		try {
			await signOut(auth);
		} catch (err) {
			console.error(err);
		} finally {
			setShowLogoutConfirm(false);
		}
	}

	function normalizeSavedAt(savedAt) {
		if (!savedAt) return null;
		if (typeof savedAt === 'string') return savedAt;
		if (typeof savedAt === 'number') return new Date(savedAt).toISOString();
		if (typeof savedAt.toMillis === 'function') return new Date(savedAt.toMillis()).toISOString();
		if (typeof savedAt.seconds === 'number') return new Date(savedAt.seconds * 1000).toISOString();
		return null;
	}

	function handleExport() {
		const now = new Date().toISOString();
		const exportedLinks = links.map(l => ({
			id: l.id,
			url: l.url,
			title: l.title,
			savedAt: normalizeSavedAt(l.savedAt),
			isRead: l.metadata?.isRead ?? true,
			isFavorite: l.metadata?.isFavorite ?? false,
			tags: l.metadata?.tags ?? [],
			description: l.metadata?.description ?? '',
			thumbnail: l.metadata?.thumbnail ?? '',
		}));
		const payload = {
			version: 1,
			app: 'Amber',
			exportedAt: now,
			count: exportedLinks.length,
			links: exportedLinks,
		};
		const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `amber-links-${now.slice(0, 10)}.json`;
		a.click();
		URL.revokeObjectURL(url);
	}

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

	return (
		<div className="options__container">
			<header className="options__page-header">
				<img src="/icons/icon32.png" alt="" className="options__page-mark" width={24} height={24} />
				<h1 className="options__title">{t('options.title')}</h1>
			</header>

			{/* Account */}
			<section className="options__section">
				<h2 className="options__section-title">{t('options.accountSection')}</h2>
				<hr className="options__section-divider" />
				{!authReady ? (
					<p className="options__account-loading">{t('common.loading')}</p>
				) : user ? (
					<AccountInfo user={user} onSignOutRequest={() => setShowLogoutConfirm(true)} />
				) : (
					<AccountForm
						email={email}
						setEmail={setEmail}
						password={password}
						setPassword={setPassword}
						error={error}
						loading={loading}
						onSignIn={handleSignIn}
						onGoogleSignIn={handleGoogleSignIn}
					/>
				)}
			</section>

			{/* Collection stats */}
			<section className="options__section">
				<div className="options__section-header">
					<h2 className="options__section-title">{t('options.collectionSection')}</h2>
				</div>
				<hr className="options__section-divider" />
				<div className="options__stats-row">
					<div className="options__stat">
						<span className="options__stat-value">{stats.total}</span>
						<span className="options__stat-label">{t('options.statLinks')}</span>
					</div>
					<div className="options__stat">
						<span className="options__stat-value">{stats.favorites}</span>
						<span className="options__stat-label">{t('options.statFavorites')}</span>
					</div>
				</div>
				<div className="options__export-row">
					<div className="options__export-label">
						<span className="options__export-title">{t('options.exportLinks')}</span>
						<span className="options__export-desc">{t('options.exportDesc')}</span>
					</div>
					<button
						type="button"
						className="options__view-btn"
						onClick={handleExport}
						disabled={links.length === 0}
					>
						<Download size={14} />
						{t('options.exportBtn')}
					</button>
				</div>
			</section>

			{/* Preferences */}
			<section className="options__section">
				<h2 className="options__section-title">{t('options.preferencesSection')}</h2>
				<hr className="options__section-divider" />
				<div className="options__pref-row">
					<div className="options__pref-label">
						<span>{t('options.defaultView')}</span>
						<span className="options__pref-desc">{t('options.defaultViewDesc')}</span>
					</div>
					<div className="options__view-toggle">
						<button
							type="button"
							className={`options__view-btn${settings.defaultViewMode === 'grid' ? ' options__view-btn--active' : ''}`}
							onClick={() => updateSettings({ defaultViewMode: 'grid' })}
						>
							<LayoutGrid size={14} />
							{t('homeView.gridView')}
						</button>
						<button
							type="button"
							className={`options__view-btn${settings.defaultViewMode === 'list' ? ' options__view-btn--active' : ''}`}
							onClick={() => updateSettings({ defaultViewMode: 'list' })}
						>
							<List size={14} />
							{t('homeView.listView')}
						</button>
					</div>
				</div>
			</section>

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

			{/* Header Links */}
			<section className="options__section">
				<h2 className="options__section-title">{t('options.headerLinksSection')}</h2>
				<hr className="options__section-divider" />
				<HeaderLinksSection settings={settings} updateSettings={updateSettings} />
			</section>

			<ConfirmModal
				isOpen={showLogoutConfirm}
				title={t('options.logoutTitle')}
				message={t('options.logoutMessage')}
				onConfirm={handleSignOut}
				onCancel={() => setShowLogoutConfirm(false)}
			/>

			{/* Privacy Policy */}
			<section className="options__section">
				<h2 className="options__section-title">{t('options.privacySection')}</h2>
				<hr className="options__section-divider" />
				<button
					type="button"
					className="options__view-btn"
					onClick={() => Browser.tabs.create({ url: Browser.runtime.getURL('privacy.html') })}
				>
					{t('options.privacyOpen')}
				</button>
			</section>

			<footer className="options__footer">
				<p>{APP_NAME} v{APP_VERSION} — {t('options.footer.caption')}</p>
			</footer>
		</div>
	);
}
