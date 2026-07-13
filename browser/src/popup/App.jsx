import { useState, useEffect, useMemo } from 'react';
import { Settings, Trash2, Plus, Search, Bookmark, Pin, PanelRight, Folder } from 'lucide-react';
import { APP_NAME } from '../common/constants.js';
import { useLinks } from '@utils/useLinks';
import { useCollections } from '@utils/useCollections';
import { useAuth } from '@contexts/AuthContext.jsx';
import { useUserSettings } from '@utils/useUserSettings';
import { getCurrentTab } from '@utils/tabs';
import { extractDomain } from '@utils/domain';
import { goToSettings } from '@utils/globalMethods.js';
import Button from '@components/Button';
import IconButton from '@components/IconButton';
import Input from '@components/Input';
import { SkeletonLinkRow } from '@components/Skeleton';
import EmptyState from '@components/EmptyState';
import LinkThumbnail from '@components/LinkThumbnail';
import CollectionBadge from '@components/CollectionBadge';
import TagEditor from '@newtab/components/TagEditor.jsx';
import { MAX_POPUP_LINKS } from '../common/constants.js';
import { t } from '@utils/i18n';
import '@styles/main.scss';
import '@styles/layout/popup.scss';

export default function App() {
	const { links, loading, saveCurrentTab, saveCustomLink, deleteLink, updateLink } = useLinks();
	const { collections } = useCollections();
	const { user } = useAuth();
	const { settings, updateSettings } = useUserSettings();

	const [addManually, setAddManually] = useState(false);
	const [customUrl, setCustomUrl] = useState('');
	const [customTitle, setCustomTitle] = useState('');
	const [selectedCollectionId, setSelectedCollectionId] = useState('');
	const [urlError, setUrlError] = useState('');
	const [saving, setSaving] = useState(false);
	const [saveError, setSaveError] = useState('');
	const [searchQuery, setSearchQuery] = useState('');

	const headerLinks = useMemo(() => settings.headerLinks || [], [settings.headerLinks]);

	const [currentTab, setCurrentTab] = useState({ url: '', title: '' });

	useEffect(() => {
		getCurrentTab().then(setCurrentTab);
	}, []);

	const isCurrentTabInHeader = headerLinks.some((l) => l.url === currentTab.url);

	function handleToggleCurrentTabHeaderLink() {
		if (!user || !currentTab.url) return;
		if (isCurrentTabInHeader) {
			updateSettings({ headerLinks: headerLinks.filter((l) => l.url !== currentTab.url) });
		} else {
			const newEntry = {
				id: Date.now().toString(),
				label: currentTab.title || currentTab.url,
				url: currentTab.url,
			};
			updateSettings({ headerLinks: [...headerLinks, newEntry] });
		}
	}

	const filteredLinks = useMemo(() => {
		const q = searchQuery.trim().toLowerCase();
		if (!q) return links.slice(0, MAX_POPUP_LINKS);
		return links
			.filter(
				(l) =>
					l.title?.toLowerCase().includes(q) ||
					l.url?.toLowerCase().includes(q) ||
					l.metadata?.description?.toLowerCase().includes(q)
			)
			.slice(0, MAX_POPUP_LINKS);
	}, [links, searchQuery]);

	const allTags = useMemo(() => {
		const set = new Set();
		links.forEach((l) => l.metadata?.tags?.forEach((tag) => set.add(tag)));
		return Array.from(set);
	}, [links]);

	const collectionsById = useMemo(() => {
		const map = {};
		collections.forEach((col) => { map[col.id] = col; });
		return map;
	}, [collections]);

	async function handleSaveCurrentTab() {
		setSaving(true);
		setSaveError('');
		try {
			const result = await saveCurrentTab(selectedCollectionId || null);
			if (result?.duplicate) {
				setSaveError(t('popup.duplicateLink'));
			} else {
				setSelectedCollectionId('');
			}
		} catch (err) {
			console.error('[popup] handleSaveCurrentTab — error:', err?.message ?? err);
			setSaveError(t('popup.errorSave'));
		} finally {
			setSaving(false);
		}
	}

	function validateUrl(value) {
		try {
			new URL(value);
			return true;
		} catch {
			return false;
		}
	}

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
			const result = await saveCustomLink({ url: customUrl, title: customTitle, collectionId: selectedCollectionId || null });
			if (result?.duplicate) {
				setUrlError(t('popup.duplicateLink'));
				return;
			}
			setCustomUrl('');
			setCustomTitle('');
			setSelectedCollectionId('');
			setAddManually(false);
		} catch (err) {
			console.error('[popup] handleSaveCustom — error:', err?.message ?? err);
			setUrlError(t('popup.errorSave'));
		}
	}

	function handleCancelManual() {
		setCustomUrl('');
		setCustomTitle('');
		setUrlError('');
		setAddManually(false);
	}

	function handleTagSave(link, newTags) {
		updateLink(link.id, { metadata: { ...link.metadata, tags: newTags } });
	}

	function handleOpenSidePanel() {
		if (!chrome?.sidePanel?.open) return;
		chrome.tabs.query({ active: true, currentWindow: true }, ([tab]) => {
			if (!tab?.windowId) return;
			chrome.sidePanel.open({ windowId: tab.windowId });
			window.close();
		});
	}

	return (
		<div className="popup__container">
			<header className="popup__header">
				<div className="popup__header-brand">
					<img src="/icons/icon16.png" alt="" className="popup__header-mark" width={16} height={16} />
					<h2 className="popup__title">{APP_NAME}</h2>
				</div>
				<div className="popup__header-actions">
					<IconButton
						icon={<Pin size={17} fill={isCurrentTabInHeader ? 'currentColor' : 'none'} />}
						onClick={handleToggleCurrentTabHeaderLink}
						disabled={!user || !currentTab.url}
						title={isCurrentTabInHeader ? t('popup.removeFromHeaderLinks') : t('popup.addToHeaderLinks')}
						className={isCurrentTabInHeader ? 'is-active' : ''}
					/>
					<IconButton
						icon={<PanelRight size={17} />}
						onClick={handleOpenSidePanel}
						title={t('sidepanel.openSidePanel')}
					/>
					<IconButton
						icon={<Settings size={18} />}
						onClick={goToSettings}
						title={t('common.settings')}
					/>
				</div>
			</header>

			<div className="popup__top">
				<div className="popup__top-actions">
					<Button
						onClick={handleSaveCurrentTab}
						icon={<Plus size={16} />}
						text={saving ? t('popup.saving') : t('popup.saveCurrentPage')}
						size="medium"
						variant="primary"
						disabled={saving}
					/>
					<Button
						onClick={() => setAddManually((p) => !p)}
						text={t('popup.addManually')}
						size="small"
						variant="ghost"
					/>
				</div>

				{collections.length > 0 && (
					<div
						className="popup__collection-row"
						style={collectionsById[selectedCollectionId] ? { '--row-color': collectionsById[selectedCollectionId].color } : undefined}
					>
						{collectionsById[selectedCollectionId]
							? <span className="popup__collection-dot" aria-hidden="true" />
							: <Folder size={12} className="popup__collection-icon" />}
						<select
							className="popup__collection-select"
							value={selectedCollectionId}
							onChange={e => setSelectedCollectionId(e.target.value)}
						>
							<option value="">{t('homeView.bulkNoCollection')}</option>
							{collections.map(col => (
								<option key={col.id} value={col.id}>{col.name}</option>
							))}
						</select>
					</div>
				)}

				{saveError && <p className="popup__error">{saveError}</p>}

				<div className={`popup__manual-form-wrapper${addManually ? ' popup__manual-form-wrapper--open' : ''}`}>
					<div className="popup__manual-form">
						<Input
							type="url"
							placeholder={t('popup.urlPlaceholder')}
							ariaLabel={t('popup.urlPlaceholder')}
							value={customUrl}
							onChange={(e) => {
								setCustomUrl(e.target.value);
								if (urlError) setUrlError('');
							}}
						/>
						<Input
							type="text"
							placeholder={t('popup.titleOptional')}
							ariaLabel={t('popup.titleOptional')}
							value={customTitle}
							onChange={(e) => setCustomTitle(e.target.value)}
						/>
						{urlError && <p className="popup__error">{urlError}</p>}
						<div className="popup__manual-actions">
							<Button text={t('common.save')} variant="primary" size="small" onClick={handleSaveCustom} />
							<Button text={t('common.cancel')} variant="secondary" size="small" onClick={handleCancelManual} />
						</div>
					</div>
				</div>
			</div>

			<div className="popup__scroll">
				{loading ? (
					<div className="popup__skeleton" role="status">
						<SkeletonLinkRow count={5} />
					</div>
				) : (
					<>
						<div className="popup__search">
							<div className="popup__search-input-wrapper">
								<Search size={14} className="popup__search-icon" />
								<input
									className="popup__search-input"
									type="search"
									aria-label={t('popup.searchPlaceholder')}
									placeholder={t('popup.searchPlaceholder')}
									value={searchQuery}
									onChange={(e) => setSearchQuery(e.target.value)}
								/>
							</div>
						</div>

						{filteredLinks.length === 0 ? (
							<EmptyState
								icon={searchQuery ? <Search size={28} /> : <Bookmark size={28} />}
								title={t(searchQuery ? 'emptyState.noResults.title' : 'emptyState.noLinks.title')}
								description={t(searchQuery ? 'emptyState.noResults.description' : 'emptyState.noLinks.description')}
							/>
						) : (
							<ul className="popup__links">
								{filteredLinks.map((link) => {
									const col = link.metadata?.collectionId ? collectionsById[link.metadata.collectionId] : null;
									return (
										<li
											key={link.id}
											className="popup__link-item popup__link-item--with-tags"
										>
											<div className="popup__link-main">
												<LinkThumbnail link={link} size="sm" />
												<div className="popup__link-body">
													<a
														href={link.url}
														className="popup__link-title"
														target="_blank"
														rel="noopener noreferrer"
														title={link.url}
													>
														{link.title || link.url}
													</a>
													<div className="popup__link-meta">
														<span className="popup__link-domain">{extractDomain(link.url)}</span>
														{col && <CollectionBadge name={col.name} color={col.color} />}
													</div>
												</div>
												<IconButton
													icon={<Trash2 size={14} />}
													onClick={() => deleteLink(link.id)}
													variant="danger"
													title={t('common.delete')}
												/>
											</div>

											<div className="popup__link-tags">
												<TagEditor
													tags={link.metadata?.tags ?? []}
													allTags={allTags}
													onSave={(newTags) => handleTagSave(link, newTags)}
												/>
											</div>
											{collections.length > 0 && (
												<div
													className="popup__link-collection"
													style={col ? { '--row-color': col.color } : undefined}
												>
													<Folder size={10} className="popup__link-collection-icon" />
													<select
														className="popup__link-collection-select"
														value={link.metadata?.collectionId || ''}
														onChange={e => updateLink(link.id, { metadata: { ...(link.metadata || {}), collectionId: e.target.value || null } })}
													>
														<option value="">{t('homeView.bulkNoCollection')}</option>
														{collections.map(col => (
															<option key={col.id} value={col.id}>{col.name}</option>
														))}
													</select>
												</div>
											)}
										</li>
									);
								})}
							</ul>
						)}
					</>
				)}
			</div>
		</div>
	);
}
