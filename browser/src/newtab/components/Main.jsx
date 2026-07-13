import PropTypes from "prop-types";
import { useState, useMemo } from 'react';
import { useLinks } from '@utils/useLinks';
import { useCollections } from '@utils/useCollections';
import { useUserSettings } from '@utils/useUserSettings.js';
import Sidebar from '@components/Sidebar';
import EditModal from './EditModal.jsx';
import HomeView from '@newtab/views/HomeView.jsx';
import FavoritesView from '@newtab/views/FavoritesView.jsx';
import TagsView from '@newtab/views/TagsView.jsx';

export default function Main(props) {
	const { links, loading, deleteLink, updateLink, saveCustomLink } = useLinks();
	const { collections, addCollection, renameCollection, deleteCollection } = useCollections();
	const { settings } = useUserSettings();
	const newtabEnabled = settings.newtabEnabled !== false;
	const [activeView, setActiveView] = useState('home');
	const [activeCollectionId, setActiveCollectionId] = useState(null);

	const linkCounts = useMemo(() => ({
		home: links.length,
		favorites: links.filter(l => l.metadata?.isFavorite).length,
		tags: new Set(links.flatMap(l => l.metadata?.tags || [])).size,
	}), [links]);

	const collectionCounts = useMemo(() => {
		const counts = {};
		links.forEach(l => {
			const cid = l.metadata?.collectionId;
			if (cid) counts[cid] = (counts[cid] || 0) + 1;
		});
		return counts;
	}, [links]);

	const allTags = useMemo(() =>
		[...new Set(links.flatMap(l => l.metadata?.tags || []))].sort(),
	[links]);
	const [editingLink, setEditingLink] = useState(null);
	const [isModalOpen, setIsModalOpen] = useState(false);
	const [isSaving, setIsSaving] = useState(false);
	const [saveError, setSaveError] = useState(null);
	const [isSidebarOpen, setIsSidebarOpen] = useState(true);

	function openEdit(link) {
		setEditingLink(link);
		setIsModalOpen(true);
	}

	function openAddModal() {
		setEditingLink(null);
		setIsModalOpen(true);
	}

	function closeModal() {
		setIsModalOpen(false);
		setEditingLink(null);
		setIsSaving(false);
		setSaveError(null);
	}

	async function handleUpdate(id, updates) {
		setIsSaving(true);
		setSaveError(null);
		try {
			await updateLink(id, updates);
			closeModal();
		} catch (err) {
			console.error('[Main] updateLink error', err);
			setIsSaving(false);
			setSaveError(true);
		}
	}

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

	function handleNavigate(view) {
		setActiveView(view);
		setActiveCollectionId(null);
	}

	function handleCollectionSelect(id) {
		setActiveCollectionId(id);
		setActiveView('home');
	}

	return (
		<main className={`newtab__main${isSidebarOpen ? ' sidebar-open' : ''}`}>
			<Sidebar
				onAdd={openAddModal}
				isOpen={isSidebarOpen}
				onToggle={() => setIsSidebarOpen(prev => !prev)}
				activeView={activeView}
				onNavigate={handleNavigate}
				linkCounts={linkCounts}
				collections={collections}
				activeCollectionId={activeCollectionId}
				onCollectionSelect={handleCollectionSelect}
				onCollectionAdd={addCollection}
				onCollectionRename={renameCollection}
				onCollectionDelete={deleteCollection}
				collectionCounts={collectionCounts}
			/>

			{newtabEnabled && (
			<section className="newtab__main-content">
				{activeView === 'home' && (
					<HomeView
						links={links}
						loading={loading}
						auth={props.auth}
						onEdit={openEdit}
						onDelete={deleteLink}
						updateLink={updateLink}
						activeCollectionId={activeCollectionId}
						collections={collections}
					/>
				)}
				{activeView === 'favorites' && (
					<FavoritesView
						links={links}
						loading={loading}
						auth={props.auth}
						onEdit={openEdit}
						onDelete={deleteLink}
						updateLink={updateLink}
						activeCollectionId={activeCollectionId}
						collections={collections}
					/>
				)}
				{activeView === 'tags' && (
					<TagsView
						links={links}
						updateLink={updateLink}
						onEdit={openEdit}
						onDelete={deleteLink}
					/>
				)}
				</section>
			)}

			{isModalOpen && (
				<EditModal
					isOpen={isModalOpen}
					link={editingLink}
					isSaving={isSaving}
					saveError={saveError}
					allTags={allTags}
					collections={collections}
					onClose={closeModal}
					onSubmit={(updates) => (editingLink ? handleUpdate(editingLink.id, updates) : handleAdd(updates))}
				/>
			)}
		</main>
	);
}

Main.propTypes = {
	auth: PropTypes.object
};

Main.defaultProps = {
	auth: null
};
