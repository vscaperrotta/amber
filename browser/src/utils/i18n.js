const translations = {
	en: {
		// ── Common ────────────────────────────────────────────
		'common.save': 'Save',
		'common.cancel': 'Cancel',
		'common.delete': 'Delete',
		'common.confirm': 'Confirm',
		'common.add': 'Add',
		'common.loading': 'Loading...',
		'common.settings': 'Settings',
		'common.search': 'Search',

		// ── Popup ─────────────────────────────────────────────
		'popup.saveCurrentPage': 'Save this page',
		'popup.saving': 'Saving...',
		'popup.addManually': 'Add URL',
		'popup.urlPlaceholder': 'https://',
		'popup.titleOptional': 'Title (optional)',
		'popup.errorSave': 'Couldn\'t save. Try again.',
		'popup.duplicateLink': 'This link is already saved.',
		'popup.errorUrl': 'Please enter a URL.',
		'popup.errorUrlInvalid': 'Invalid URL. Must start with https://',
		'popup.searchPlaceholder': 'Search saved links...',
		'popup.openFullView': 'Open full library →',
		'popup.addToHeaderLinks': 'Add to link bar',
		'popup.removeFromHeaderLinks': 'Remove from link bar',

		// ── HomeView ──────────────────────────────────────────
		'homeView.linksCount': ({ count }) => `${count} link${count === 1 ? '' : 's'} saved`,
		'homeView.listView': 'List view',
		'homeView.gridView': 'Grid view',
		'homeView.viewModeLabel': 'View mode',
		'homeView.groupToday': 'Today',
		'homeView.groupThisWeek': 'This week',
		'homeView.groupEarlier': 'Earlier',
		'homeView.unreadOnly': 'Unread',
		'homeView.clearFilters': 'Clear',
		'tagFilter.label': 'Tags',
		'tagFilter.title': 'Filter by tag',
		'tagFilter.panelLabel': 'Tag filter',
		'homeView.groupByDate': 'By date',
		'homeView.bulkAssignCollection': 'Assign to folder',
		'homeView.bulkAssignBtn': 'Assign',
		'homeView.bulkNoCollection': 'No folder',
		'homeView.pagination.prev': 'Previous page',
		'homeView.pagination.next': 'Next page',
		'homeView.pagination.page': ({ current, total }) => `${current} of ${total}`,

		// ── TagsView ──────────────────────────────────────────
		'tagsView.empty': 'No tags yet. Save links — tags are extracted automatically.',
		'tagsView.all': 'All',
		'tagsView.untagged': 'Untagged',
		'tagsView.noLinksForTag': 'No links with this tag.',
		'tagsView.matchAny': 'Match any',
		'tagsView.matchAll': 'Match all',
		'tagsView.selectLinks': 'Select',
		'tagsView.cancelSelect': 'Done',
		'tagsView.selectedCount': ({ count }) => `${count} selected`,
		'tagsView.bulkAddTag': 'Add tag',
		'tagsView.bulkRemoveTag': 'Remove tag',
		'tagsView.bulkTagInput': 'Tag name…',
		'tagsView.renameTag': 'Rename',
		'tagsView.deleteTag': 'Delete tag',
		'tagsView.mergeTag': 'Merge into…',
		'tagsView.searchPlaceholder': 'Search links or tags…',
		'tagsView.statsTags': 'tags',
		'tagsView.statsTagged': 'tagged',
		'tagsView.statsUntagged': 'untagged',
		'tagsView.backToIndex': 'Back to all tags',
		'tagsView.related': 'Also in:',
		'tagsView.links': 'links',
		'tagsView.confirmDelete': 'Delete this tag from all links?',

		// ── EditModal ─────────────────────────────────────────
		'editModal.titleAdd': 'Add link',
		'editModal.titleEdit': 'Edit link',
		'editModal.fieldTitle': 'Title',
		'editModal.fieldUrl': 'URL',
		'editModal.fieldDescription': 'Description',
		'editModal.fieldNote': 'Personal note',
		'editModal.fieldNotePlaceholder': 'Your thoughts, context, why you saved this…',
		'editModal.fieldCollection': 'Collection',
		'editModal.collectionNone': 'No collection',
		'editModal.saveError': 'Could not save. Please try again.',
		'editModal.duplicateError': 'This link is already saved.',

		// ── TagEditor ─────────────────────────────────────────
		'tagEditor.placeholder': 'new tag...',
		'tagEditor.addAriaLabel': 'Add tag',

		// ── UserModal ─────────────────────────────────────────
		'userModal.titleLogin': 'Sign in',
		'userModal.titleRegister': 'Create account',
		'userModal.loginTab': 'Sign in',
		'userModal.registerTab': 'Register',
		'userModal.googleCta': 'Continue with Google',
		'userModal.divider': 'or',
		'userModal.usernamePlaceholder': 'Username',
		'userModal.emailPlaceholder': 'Email',
		'userModal.passwordPlaceholder': 'Password',
		'userModal.switchToRegister': 'Register',
		'userModal.switchToLogin': 'Already have an account? Sign in',

		// ── UserDropdown ──────────────────────────────────────
		'userDropdown.settings': 'Settings',
		'userDropdown.logout': 'Sign out',

		// ── Sidebar ───────────────────────────────────────────
		'sidebar.ariaLabel': 'Main navigation',
		'sidebar.expand': 'Expand navigation',
		'sidebar.collapse': 'Collapse navigation',
		'sidebar.addManually': 'Add URL',
		'sidebar.navHome': 'Home',
		'sidebar.navFavorites': 'Favorites',
		'sidebar.navTags': 'Tags',
		'sidebar.collectionsLabel': 'Collections',
		'sidebar.collectionsEmpty': 'No collections yet',
		'sidebar.collectionAdd': 'New collection',
		'sidebar.collectionNamePlaceholder': 'Collection name',
		'sidebar.collectionRename': 'Rename collection',
		'sidebar.collectionDelete': 'Delete collection',
		'sidebar.collectionDeleteConfirm': ({ name }) => `Delete "${name}"? Links inside will not be deleted.`,

		// ── Header ────────────────────────────────────────────
		'header.accountLabel': 'User account',
		'header.signIn': 'Sign in',

		// ── ConfirmModal ──────────────────────────────────────
		'confirmModal.title': 'Confirm',
		'confirmModal.confirm': 'Confirm',

		// ── Pill ──────────────────────────────────────────────
		'pill.removeAriaLabel': ({ label }) => `Remove tag ${label}`,
		'options.headerLinkRemove': ({ label }) => `Remove ${label}`,

		// ── LinkItem ──────────────────────────────────────────
		'linkItem.favorite': 'Add to favorites',
		'linkItem.unfavorite': 'Remove from favorites',
		'linkItem.edit': 'Edit',
		'linkItem.delete': 'Delete',
		'linkItem.markRead': 'Mark as read',
		'linkItem.markUnread': 'Mark as unread',
		// ── BaseModal ─────────────────────────────────────────
		'baseModal.close': 'Close',

		// ── Options page ──────────────────────────────────────
		'options.title': 'Settings',
		'options.accountSection': 'Account',
		'options.logoutTitle': 'Sign out?',
		'options.logoutMessage': 'Your links stay saved. Sign in again to sync.',
		'options.googleCta': 'Continue with Google',
		'options.divider': 'or',
		'options.signOut': 'Sign out',
		'options.email': 'Email',
		'options.password': 'Password',
		'options.signIn': 'Sign in',
		'options.footer.caption': 'Link saver for Chrome.',
		'options.privacySection': 'Privacy Policy',
		'options.privacyOpen': 'Read Privacy Policy',
		'options.preferencesSection': 'Preferences',
		'options.defaultView': 'Default view',
		'options.defaultViewDesc': 'Layout shown when you open a new tab.',
		'options.showDescription': 'Show description',
		'options.showDescriptionDesc': 'Display the AI-generated (or page) description under each saved link.',
		'options.newtabEnabled': 'Full new tab screen',
		'options.newtabEnabledDesc': 'When on, opening a new tab shows the full Amber app. When off, only the sidebar (links, folders, tags, favorites) is shown.',
		'options.headerLinksSection': 'Header Links',
		'options.headerLinksDesc': 'Quick-access links shown in the header.',
		'options.headerLinkLabel': 'Label',
		'options.headerLinkUrl': 'URL',
		'options.headerLinkAdd': 'Add',
		'options.headerLinkEmpty': 'No links added yet.',
		'options.headerLinkInvalidUrl': 'Enter a valid URL (https://...)',
		'options.collectionSection': 'Your Collection',
		'options.statLinks': 'links saved',
		'options.statFavorites': 'favorites',
		'options.exportLinks': 'Export links',
		'options.exportDesc': 'Download all saved links as JSON.',
		'options.exportBtn': 'Export JSON',
		'options.importSection': 'Import bookmarks',
		'options.importDesc': 'Import from a browser bookmarks export (HTML file).',
		'options.importBtn': 'Choose file',
		'options.importProgress': 'Importing… {done}/{total}',
		'options.importDone': 'Done — {count} imported, {skipped} duplicates skipped',
		'options.importError': "Couldn't read that file. Make sure it's a bookmarks HTML export.",

		// ── Empty states ─────────────────────────────────────
		'emptyState.noLinks.title': 'Save your first link',
		'emptyState.noLinks.description': 'Click Save this page or add a URL manually.',
		'emptyState.noResults.title': 'No links match',
		'emptyState.noResults.description': 'Try a different search term.',
		'emptyState.noFavorites.title': 'No favorites yet',
		'emptyState.noFavorites.description': 'Star a link to find it here.',
		'emptyState.noTags.title': 'No tags yet',
		'emptyState.noTags.description': 'Add tags to organize your links.',
		'emptyState.noCollectionLinks.title': 'No links in this collection',
		'emptyState.noCollectionLinks.description': 'Edit a link and assign it to this collection.',

		// ── Auth errors ───────────────────────────────────────
		'auth.invalidEmail': 'Invalid email.',
		'auth.invalidCredential': 'Incorrect email or password.',
		'auth.userNotFound': 'No account found with this email.',
		'auth.wrongPassword': 'Incorrect password.',
		'auth.emailAlreadyInUse': 'Email already in use.',
		'auth.weakPassword': 'Password must be at least 6 characters.',
		'auth.tooManyRequests': 'Too many attempts. Try again shortly.',
		'auth.popupBlocked': 'Sign-in popup was blocked. Allow popups for this site in your browser settings.',
		'auth.genericError': 'An error occurred. Please try again.',

		// ── Side panel ────────────────────────────────────────
		'sidepanel.save': 'Save this page',
		'sidepanel.saving': 'Saving…',
		'sidepanel.saved': 'Saved!',
		'sidepanel.duplicate': 'Already saved',
		'sidepanel.error': "Couldn't save",
		'sidepanel.searchPlaceholder': 'Search…',
		'sidepanel.openFullView': 'Open Amber →',
		'sidepanel.openSidePanel': 'Open side panel',

		// ── SaveOverlay (content script) ──────────────────────
		'overlay.saving': 'Saving...',
		'overlay.saved': 'Link saved',
		'overlay.error': 'Save failed',
		'overlay.duplicate': 'Already saved',
		'overlay.close': 'Close',
	},

	it: {
		// ── Common ────────────────────────────────────────────
		'common.save': 'Salva',
		'common.cancel': 'Annulla',
		'common.delete': 'Elimina',
		'common.confirm': 'Conferma',
		'common.add': 'Aggiungi',
		'common.loading': 'Caricamento...',
		'common.settings': 'Impostazioni',
		'common.search': 'Cerca',

		// ── Popup ─────────────────────────────────────────────
		'popup.saveCurrentPage': 'Salva questa pagina',
		'popup.saving': 'Salvataggio...',
		'popup.addManually': 'Aggiungi URL',
		'popup.urlPlaceholder': 'https://',
		'popup.titleOptional': 'Titolo (opzionale)',
		'popup.errorSave': 'Salvataggio non riuscito. Riprova.',
		'popup.duplicateLink': 'Questo link è già stato salvato.',
		'popup.errorUrl': 'Inserisci un URL.',
		'popup.errorUrlInvalid': 'URL non valido. Inizia con https://',
		'popup.searchPlaceholder': 'Cerca nei link salvati...',
		'popup.openFullView': 'Apri libreria completa →',
		'popup.addToHeaderLinks': 'Aggiungi alla barra link',
		'popup.removeFromHeaderLinks': 'Rimuovi dalla barra link',

		// ── HomeView ──────────────────────────────────────────
		'homeView.linksCount': ({ count }) => `${count} link salvat${count === 1 ? 'o' : 'i'}`,
		'homeView.listView': 'Vista lista',
		'homeView.gridView': 'Vista griglia',
		'homeView.viewModeLabel': 'Modalità vista',
		'homeView.groupToday': 'Oggi',
		'homeView.groupThisWeek': 'Questa settimana',
		'homeView.groupEarlier': 'Precedenti',
		'homeView.unreadOnly': 'Non letti',
		'homeView.clearFilters': 'Rimuovi',
		'tagFilter.label': 'Tag',
		'tagFilter.title': 'Filtra per tag',
		'tagFilter.panelLabel': 'Filtro tag',
		'homeView.groupByDate': 'Per data',
		'homeView.bulkAssignCollection': 'Assegna a cartella',
		'homeView.bulkAssignBtn': 'Assegna',
		'homeView.bulkNoCollection': 'Nessuna cartella',
		'homeView.pagination.prev': 'Pagina precedente',
		'homeView.pagination.next': 'Pagina successiva',
		'homeView.pagination.page': ({ current, total }) => `${current} di ${total}`,

		// ── TagsView ──────────────────────────────────────────
		'tagsView.empty': 'Nessun tag ancora. Salva dei link — i tag vengono estratti automaticamente.',
		'tagsView.all': 'Tutti',
		'tagsView.untagged': 'Senza tag',
		'tagsView.noLinksForTag': 'Nessun link con questo tag.',
		'tagsView.matchAny': 'Uno qualsiasi',
		'tagsView.matchAll': 'Tutti i tag',
		'tagsView.selectLinks': 'Seleziona',
		'tagsView.cancelSelect': 'Fine',
		'tagsView.selectedCount': ({ count }) => `${count} selezionat${count === 1 ? 'o' : 'i'}`,
		'tagsView.bulkAddTag': 'Aggiungi tag',
		'tagsView.bulkRemoveTag': 'Rimuovi tag',
		'tagsView.bulkTagInput': 'Nome tag…',
		'tagsView.renameTag': 'Rinomina',
		'tagsView.deleteTag': 'Elimina tag',
		'tagsView.mergeTag': 'Unisci in…',
		'tagsView.searchPlaceholder': 'Cerca link o tag…',
		'tagsView.statsTags': 'tag',
		'tagsView.statsTagged': 'con tag',
		'tagsView.statsUntagged': 'senza tag',
		'tagsView.backToIndex': 'Torna a tutti i tag',
		'tagsView.related': 'Anche in:',
		'tagsView.links': 'link',
		'tagsView.confirmDelete': 'Eliminare questo tag da tutti i link?',

		// ── EditModal ─────────────────────────────────────────
		'editModal.titleAdd': 'Aggiungi link',
		'editModal.titleEdit': 'Modifica link',
		'editModal.fieldTitle': 'Titolo',
		'editModal.fieldUrl': 'URL',
		'editModal.fieldDescription': 'Descrizione',
		'editModal.fieldNote': 'Nota personale',
		'editModal.fieldNotePlaceholder': 'Pensieri, contesto, perché hai salvato questo link…',
		'editModal.fieldCollection': 'Cartella',
		'editModal.collectionNone': 'Nessuna cartella',
		'editModal.saveError': 'Salvataggio non riuscito. Riprova.',
		'editModal.duplicateError': 'Questo link è già stato salvato.',

		// ── TagEditor ─────────────────────────────────────────
		'tagEditor.placeholder': 'nuovo tag...',
		'tagEditor.addAriaLabel': 'Aggiungi tag',

		// ── UserModal ─────────────────────────────────────────
		'userModal.titleLogin': 'Accedi',
		'userModal.titleRegister': 'Crea account',
		'userModal.loginTab': 'Accedi',
		'userModal.registerTab': 'Registrati',
		'userModal.googleCta': 'Continua con Google',
		'userModal.divider': 'oppure',
		'userModal.usernamePlaceholder': 'Nome utente',
		'userModal.emailPlaceholder': 'Email',
		'userModal.passwordPlaceholder': 'Password',
		'userModal.switchToRegister': 'Registrati',
		'userModal.switchToLogin': 'Hai già un account? Accedi',

		// ── UserDropdown ──────────────────────────────────────
		'userDropdown.settings': 'Impostazioni',
		'userDropdown.logout': 'Esci',

		// ── Sidebar ───────────────────────────────────────────
		'sidebar.ariaLabel': 'Navigazione principale',
		'sidebar.expand': 'Espandi navigazione',
		'sidebar.collapse': 'Comprimi navigazione',
		'sidebar.addManually': 'Aggiungi URL',
		'sidebar.navHome': 'Home',
		'sidebar.navFavorites': 'Preferiti',
		'sidebar.navTags': 'Tag',
		'sidebar.collectionsLabel': 'Cartelle',
		'sidebar.collectionsEmpty': 'Nessuna cartella',
		'sidebar.collectionAdd': 'Nuova cartella',
		'sidebar.collectionNamePlaceholder': 'Nome cartella',
		'sidebar.collectionRename': 'Rinomina cartella',
		'sidebar.collectionDelete': 'Elimina cartella',
		'sidebar.collectionDeleteConfirm': ({ name }) => `Eliminare "${name}"? I link al suo interno non saranno eliminati.`,

		// ── Header ────────────────────────────────────────────
		'header.accountLabel': 'Account utente',
		'header.signIn': 'Accedi',

		// ── ConfirmModal ──────────────────────────────────────
		'confirmModal.title': 'Conferma',
		'confirmModal.confirm': 'Conferma',

		// ── Pill ──────────────────────────────────────────────
		'pill.removeAriaLabel': ({ label }) => `Rimuovi tag ${label}`,
		'options.headerLinkRemove': ({ label }) => `Rimuovi ${label}`,

		// ── LinkItem ──────────────────────────────────────────
		'linkItem.favorite': 'Aggiungi ai preferiti',
		'linkItem.unfavorite': 'Rimuovi dai preferiti',
		'linkItem.edit': 'Modifica',
		'linkItem.delete': 'Elimina',
		'linkItem.markRead': 'Segna come letto',
		'linkItem.markUnread': 'Segna come non letto',
		// ── BaseModal ─────────────────────────────────────────
		'baseModal.close': 'Chiudi',

		// ── Options page ──────────────────────────────────────
		'options.title': 'Impostazioni',
		'options.accountSection': 'Account',
		'options.logoutTitle': 'Esci?',
		'options.logoutMessage': 'I tuoi link rimangono salvati. Accedi di nuovo per sincronizzarli.',
		'options.googleCta': 'Continua con Google',
		'options.divider': 'oppure',
		'options.signOut': 'Esci',
		'options.email': 'Email',
		'options.password': 'Password',
		'options.signIn': 'Accedi',
		'options.footer.caption': 'Salva link per Chrome.',
		'options.privacySection': 'Privacy Policy',
		'options.privacyOpen': 'Leggi la Privacy Policy',
		'options.preferencesSection': 'Preferenze',
		'options.defaultView': 'Vista predefinita',
		'options.defaultViewDesc': 'Layout all\'apertura di una nuova scheda.',
		'options.showDescription': 'Mostra descrizione',
		'options.showDescriptionDesc': 'Mostra la descrizione (generata da AI o della pagina) sotto ogni link salvato.',
		'options.newtabEnabled': 'Schermata nuova scheda completa',
		'options.newtabEnabledDesc': 'Se attivo, l\'apertura di una nuova scheda mostra l\'app Amber completa. Se disattivo, viene mostrata solo la sidebar (link, cartelle, tag e preferiti).',
		'options.headerLinksSection': 'Link nell\'header',
		'options.headerLinksDesc': 'Link rapidi mostrati nell\'header.',
		'options.headerLinkLabel': 'Etichetta',
		'options.headerLinkUrl': 'URL',
		'options.headerLinkAdd': 'Aggiungi',
		'options.headerLinkEmpty': 'Nessun link aggiunto.',
		'options.headerLinkInvalidUrl': 'Inserisci un URL valido (https://...)',
		'options.collectionSection': 'La tua collezione',
		'options.statLinks': 'link salvati',
		'options.statFavorites': 'preferiti',
		'options.exportLinks': 'Esporta link',
		'options.exportDesc': 'Scarica tutti i link salvati come JSON.',
		'options.exportBtn': 'Esporta JSON',
		'options.importSection': 'Importa bookmark',
		'options.importDesc': 'Importa da un\'esportazione bookmark del browser (file HTML).',
		'options.importBtn': 'Scegli file',
		'options.importProgress': 'Importazione… {done}/{total}',
		'options.importDone': 'Completato — {count} importati, {skipped} duplicati ignorati',
		'options.importError': 'File non leggibile. Assicurati sia un export HTML dei bookmark.',

		// ── Empty states ─────────────────────────────────────
		'emptyState.noLinks.title': 'Salva il tuo primo link',
		'emptyState.noLinks.description': 'Clicca Salva questa pagina o aggiungi un URL.',
		'emptyState.noResults.title': 'Nessun link trovato',
		'emptyState.noResults.description': 'Prova un altro termine di ricerca.',
		'emptyState.noFavorites.title': 'Ancora nessun preferito',
		'emptyState.noFavorites.description': 'Aggiungi una stella a un link per trovarlo qui.',
		'emptyState.noTags.title': 'Ancora nessun tag',
		'emptyState.noTags.description': 'Aggiungi tag per organizzare i tuoi link.',
		'emptyState.noCollectionLinks.title': 'Nessun link in questa cartella',
		'emptyState.noCollectionLinks.description': 'Modifica un link e assegnalo a questa cartella.',

		// ── Auth errors ───────────────────────────────────────
		'auth.invalidEmail': 'Email non valida.',
		'auth.invalidCredential': 'Email o password non corretti.',
		'auth.userNotFound': 'Nessun account trovato con questa email.',
		'auth.wrongPassword': 'Password errata.',
		'auth.emailAlreadyInUse': 'Email già in uso.',
		'auth.weakPassword': 'La password deve avere almeno 6 caratteri.',
		'auth.tooManyRequests': 'Troppi tentativi. Riprova tra poco.',
		'auth.popupBlocked': 'Il popup di accesso è stato bloccato. Consenti i popup nelle impostazioni del browser.',
		'auth.genericError': 'Si è verificato un errore. Riprova.',

		// ── Side panel ────────────────────────────────────────
		'sidepanel.save': 'Salva questa pagina',
		'sidepanel.saving': 'Salvataggio…',
		'sidepanel.saved': 'Salvato!',
		'sidepanel.duplicate': 'Già salvato',
		'sidepanel.error': 'Salvataggio fallito',
		'sidepanel.searchPlaceholder': 'Cerca…',
		'sidepanel.openFullView': 'Apri Amber →',
		'sidepanel.openSidePanel': 'Apri pannello laterale',

		// ── SaveOverlay (content script) ──────────────────────
		'overlay.saving': 'Salvataggio in corso...',
		'overlay.saved': 'Link salvato',
		'overlay.error': 'Salvataggio fallito',
		'overlay.duplicate': 'Già salvato',
		'overlay.close': 'Chiudi',
	},
};

function getLocale() {
	const lang = (navigator.language || 'en').toLowerCase();
	return lang.startsWith('it') ? 'it' : 'en';
}

/**
 * Returns the translated string for the given key.
 * For function-valued keys (dynamic strings), pass vars as second argument.
 * @param {string} key
 * @param {object} [vars]
 * @returns {string}
 */
export function t(key, vars) {
	const locale = getLocale();
	const val = translations[locale]?.[key] ?? translations['en']?.[key] ?? key;
	if (vars === undefined) return val;
	return typeof val === 'function' ? val(vars) : val;
}
