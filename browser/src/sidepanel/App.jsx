import { useState, useMemo } from 'react';
import { Search, Plus, Trash2, Bookmark, X, FolderPlus, Star, Pencil, Check } from 'lucide-react';
import { APP_NAME } from '../common/constants.js';
import { useLinks } from '@utils/useLinks';
import { useCollections } from '@utils/useCollections';
import { extractDomain } from '@utils/domain';
import { timeAgo } from '@utils/timeAgo';
import { t } from '@utils/i18n';
import { SkeletonLinkRow } from '@components/Skeleton';
import EmptyState from '@components/EmptyState';
import LinkThumbnail from '@components/LinkThumbnail';
import CollectionBadge from '@components/CollectionBadge';
import TagEditor from '@newtab/components/TagEditor.jsx';
import '@styles/layout/sidepanel.scss';

const ALL = '__all__';
const NONE = '__none__';

export default function App() {
	const { links, loading, saveCurrentTab, deleteLink, updateLink } = useLinks();
	const { collections, addCollection } = useCollections();

	const [searchQuery, setSearchQuery] = useState('');
	const [activeCollection, setActiveCollection] = useState(ALL);
	const [activeTags, setActiveTags] = useState(new Set());
	const [saving, setSaving] = useState(false);
	const [saveMsg, setSaveMsg] = useState('');
	const [saveMsgType, setSaveMsgType] = useState('ok');
	const [creatingFolder, setCreatingFolder] = useState(false);
	const [newFolderName, setNewFolderName] = useState('');
	const [editingId, setEditingId] = useState(null);

	const collectionsById = useMemo(() => {
		const map = {};
		collections.forEach((col) => { map[col.id] = col; });
		return map;
	}, [collections]);

	const allTags = useMemo(() => {
		const set = new Set();
		links.forEach((l) => (l.metadata?.tags || []).forEach((tag) => set.add(tag)));
		return Array.from(set).sort();
	}, [links]);

	const collectionCounts = useMemo(() => {
		const counts = { [ALL]: links.length, [NONE]: 0 };
		links.forEach((l) => {
			const id = l.metadata?.collectionId;
			if (id && collectionsById[id]) counts[id] = (counts[id] || 0) + 1;
			else counts[NONE] += 1;
		});
		return counts;
	}, [links, collectionsById]);

	const filtered = useMemo(() => {
		const q = searchQuery.trim().toLowerCase();
		return links.filter((l) => {
			const cid = l.metadata?.collectionId;
			if (activeCollection === NONE && (cid && collectionsById[cid])) return false;
			if (activeCollection !== ALL && activeCollection !== NONE && cid !== activeCollection) return false;

			if (activeTags.size > 0) {
				const linkTags = l.metadata?.tags || [];
				for (const tag of activeTags) if (!linkTags.includes(tag)) return false;
			}

			if (q) {
				const inTitle = l.title?.toLowerCase().includes(q);
				const inUrl = l.url?.toLowerCase().includes(q);
				const inTags = (l.metadata?.tags || []).some((tag) => tag.toLowerCase().includes(q));
				if (!inTitle && !inUrl && !inTags) return false;
			}
			return true;
		});
	}, [links, searchQuery, activeCollection, activeTags, collectionsById]);

	const hasFilters = activeCollection !== ALL || activeTags.size > 0 || searchQuery.trim();

	async function handleSave() {
		setSaving(true);
		setSaveMsg('');
		try {
			const result = await saveCurrentTab(activeCollection !== ALL && activeCollection !== NONE ? activeCollection : null);
			if (result?.duplicate) {
				setSaveMsg(t('sidepanel.duplicate'));
				setSaveMsgType('warn');
			} else {
				setSaveMsg(t('sidepanel.saved'));
				setSaveMsgType('ok');
			}
		} catch {
			setSaveMsg(t('sidepanel.error'));
			setSaveMsgType('err');
		} finally {
			setSaving(false);
			setTimeout(() => setSaveMsg(''), 2500);
		}
	}

	async function handleCreateFolder() {
		const name = newFolderName.trim();
		if (!name) { setCreatingFolder(false); return; }
		await addCollection({ name });
		setNewFolderName('');
		setCreatingFolder(false);
	}

	function toggleTag(tag) {
		setActiveTags((prev) => {
			const next = new Set(prev);
			if (next.has(tag)) next.delete(tag);
			else next.add(tag);
			return next;
		});
	}

	function clearFilters() {
		setActiveCollection(ALL);
		setActiveTags(new Set());
		setSearchQuery('');
	}

	function toggleFavorite(link) {
		updateLink(link.id, { metadata: { ...(link.metadata || {}), isFavorite: !link.metadata?.isFavorite } });
	}

	function assignCollection(link, collectionId) {
		updateLink(link.id, { metadata: { ...(link.metadata || {}), collectionId: collectionId || null } });
	}

	function saveTags(link, tags) {
		updateLink(link.id, { metadata: { ...(link.metadata || {}), tags } });
	}

	return (
		<div className="sp__container">
			<header className="sp__header">
				<div className="sp__header-brand">
					<img src="/icons/icon16.png" alt="" width={16} height={16} />
					<span className="sp__title">{APP_NAME}</span>
				</div>
				<span className="sp__count">{links.length}</span>
			</header>

			<div className="sp__top">
				<button
					type="button"
					className="sp__save-btn"
					onClick={handleSave}
					disabled={saving}
				>
					<Plus size={14} />
					{saving ? t('sidepanel.saving') : t('sidepanel.save')}
				</button>
				{saveMsg && (
					<p className={`sp__save-msg sp__save-msg--${saveMsgType}`} role="status">
						{saveMsg}
					</p>
				)}
				<div className="sp__search-wrapper">
					<Search size={13} className="sp__search-icon" aria-hidden="true" />
					<input
						className="sp__search-input"
						type="search"
						placeholder={t('sidepanel.searchPlaceholder')}
						aria-label={t('sidepanel.searchPlaceholder')}
						value={searchQuery}
						onChange={(e) => setSearchQuery(e.target.value)}
					/>
					{searchQuery && (
						<button
							type="button"
							className="sp__search-clear"
							onClick={() => setSearchQuery('')}
							aria-label={t('sidepanel.clearFilters')}
						>
							<X size={12} />
						</button>
					)}
				</div>
			</div>

			{/* ── Collection filter + create ───────────────────── */}
			<div className="sp__filters">
				<div className="sp__chip-row" role="tablist" aria-label={t('sidepanel.allCollections')}>
					<button
						type="button"
						role="tab"
						aria-selected={activeCollection === ALL}
						className={`sp__chip${activeCollection === ALL ? ' sp__chip--active' : ''}`}
						onClick={() => setActiveCollection(ALL)}
					>
						{t('sidepanel.allCollections')}
						<span className="sp__chip-count">{collectionCounts[ALL] || 0}</span>
					</button>

					{collections.map((col) => (
						<button
							key={col.id}
							type="button"
							role="tab"
							aria-selected={activeCollection === col.id}
							className={`sp__chip sp__chip--collection${activeCollection === col.id ? ' sp__chip--active' : ''}`}
							style={{ '--chip-color': col.color }}
							onClick={() => setActiveCollection(col.id)}
						>
							<span className="sp__chip-dot" aria-hidden="true" />
							{col.name}
							<span className="sp__chip-count">{collectionCounts[col.id] || 0}</span>
						</button>
					))}

					{collectionCounts[NONE] > 0 && (
						<button
							type="button"
							role="tab"
							aria-selected={activeCollection === NONE}
							className={`sp__chip${activeCollection === NONE ? ' sp__chip--active' : ''}`}
							onClick={() => setActiveCollection(NONE)}
						>
							{t('sidepanel.uncategorized')}
							<span className="sp__chip-count">{collectionCounts[NONE]}</span>
						</button>
					)}

					{creatingFolder ? (
						<span className="sp__folder-create">
							<input
								className="sp__folder-input"
								type="text"
								autoFocus
								placeholder={t('sidepanel.folderPlaceholder')}
								value={newFolderName}
								onChange={(e) => setNewFolderName(e.target.value)}
								onKeyDown={(e) => {
									if (e.key === 'Enter') handleCreateFolder();
									if (e.key === 'Escape') { setCreatingFolder(false); setNewFolderName(''); }
								}}
							/>
							<button type="button" className="sp__folder-confirm" onClick={handleCreateFolder} aria-label={t('common.confirm')}>
								<Check size={13} />
							</button>
						</span>
					) : (
						<button
							type="button"
							className="sp__chip sp__chip--add"
							onClick={() => setCreatingFolder(true)}
							title={t('sidepanel.newFolder')}
						>
							<FolderPlus size={13} />
						</button>
					)}
				</div>

				{allTags.length > 0 && (
					<div className="sp__chip-row sp__chip-row--tags">
						{allTags.map((tag) => (
							<button
								key={tag}
								type="button"
								className={`sp__tag-chip${activeTags.has(tag) ? ' sp__tag-chip--active' : ''}`}
								onClick={() => toggleTag(tag)}
							>
								{tag}
							</button>
						))}
					</div>
				)}

				{hasFilters && (
					<button type="button" className="sp__clear-filters" onClick={clearFilters}>
						<X size={11} />
						{t('sidepanel.clearFilters')}
					</button>
				)}
			</div>

			<div className="sp__list-container" role="main">
				{loading ? (
					<div className="sp__skeleton" role="status" aria-busy="true">
						<SkeletonLinkRow count={8} />
					</div>
				) : filtered.length === 0 ? (
					<EmptyState
						icon={hasFilters ? <Search size={24} /> : <Bookmark size={24} />}
						title={t(hasFilters ? 'emptyState.noResults.title' : 'emptyState.noLinks.title')}
						description={hasFilters ? '' : t('emptyState.noLinks.description')}
					/>
				) : (
					<ul className="sp__links" role="list">
						{filtered.map((link) => {
							const col = link.metadata?.collectionId ? collectionsById[link.metadata.collectionId] : null;
							const tags = link.metadata?.tags || [];
							const isFav = !!link.metadata?.isFavorite;
							const isEditing = editingId === link.id;
							return (
								<li key={link.id} className={`sp__link-item${isEditing ? ' sp__link-item--editing' : ''}`}>
									<div className="sp__link-row">
										<a
											href={link.url}
											className="sp__link-main"
											target="_blank"
											rel="noopener noreferrer"
											title={link.url}
										>
											<LinkThumbnail link={link} size="sm" />
											<span className="sp__link-text">
												<span className="sp__link-title">{link.title || link.url}</span>
												<span className="sp__link-meta">
													<span className="sp__link-domain">{extractDomain(link.url)}</span>
													{link.savedAt && (
														<>
															<span className="sp__link-dot" aria-hidden="true">·</span>
															<span className="sp__link-time">{timeAgo(link.savedAt)}</span>
														</>
													)}
												</span>
												{(col || tags.length > 0) && (
													<span className="sp__link-badges">
														{col && <CollectionBadge name={col.name} color={col.color} />}
														{tags.map((tag) => (
															<span key={tag} className="sp__link-tag">{tag}</span>
														))}
													</span>
												)}
											</span>
										</a>
										<div className="sp__link-actions">
											<button
												type="button"
												className={`sp__link-action${isFav ? ' sp__link-action--fav' : ''}`}
												onClick={() => toggleFavorite(link)}
												aria-label={t(isFav ? 'linkItem.unfavorite' : 'linkItem.favorite')}
												title={t(isFav ? 'linkItem.unfavorite' : 'linkItem.favorite')}
											>
												<Star size={14} fill={isFav ? 'currentColor' : 'none'} />
											</button>
											<button
												type="button"
												className={`sp__link-action${isEditing ? ' sp__link-action--active' : ''}`}
												onClick={() => setEditingId(isEditing ? null : link.id)}
												aria-label={t('linkItem.edit')}
												title={t('linkItem.edit')}
											>
												<Pencil size={13} />
											</button>
											<button
												type="button"
												className="sp__link-action sp__link-action--danger"
												onClick={() => deleteLink(link.id)}
												aria-label={t('common.delete')}
												title={t('common.delete')}
											>
												<Trash2 size={13} />
											</button>
										</div>
									</div>

									{isEditing && (
										<div className="sp__link-edit">
											<label className="sp__edit-field">
												<span className="sp__edit-label">{t('sidepanel.assignFolder')}</span>
												<div className="sp__select-wrap" style={col ? { '--chip-color': col.color } : undefined}>
													{col && <span className="sp__select-dot" aria-hidden="true" />}
													<select
														className="sp__folder-select"
														value={link.metadata?.collectionId || ''}
														onChange={(e) => assignCollection(link, e.target.value)}
													>
														<option value="">{t('homeView.bulkNoCollection')}</option>
														{collections.map((c) => (
															<option key={c.id} value={c.id}>{c.name}</option>
														))}
													</select>
												</div>
											</label>
											<div className="sp__edit-field">
												<span className="sp__edit-label">{t('sidepanel.editTags')}</span>
												<TagEditor
													tags={tags}
													allTags={allTags}
													onSave={(newTags) => saveTags(link, newTags)}
												/>
											</div>
											<button type="button" className="sp__edit-done" onClick={() => setEditingId(null)}>
												{t('sidepanel.done')}
											</button>
										</div>
									)}
								</li>
							);
						})}
					</ul>
				)}
			</div>
		</div>
	);
}
