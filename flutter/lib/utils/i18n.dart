import 'dart:ui';

const Map<String, Map<String, String>> _translations = {
  'en': {
    // Common
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.delete': 'Delete',
    'common.saving': 'Saving...',

    // Navigation
    'nav.home': 'Home',
    'nav.favorites': 'Favorites',
    'nav.tags': 'Tags',
    'nav.addLink': 'Add link',
    'nav.signOut': 'Sign out',

    // Home
    'home.title': 'Amber',
    'home.emptyTitle': 'No saved links',
    'home.emptySubtitle': 'Tap + to add one\nor share a link from another app',

    // Favorites
    'favorites.title': 'Favorites',
    'favorites.emptyTitle': 'No favorites',
    'favorites.emptySubtitle': 'Tap the star on a link to add it to favorites',

    // Tags
    'tags.title': 'Tags',
    'tags.all': 'All',
    'tags.emptyTitle': 'No tags',
    'tags.emptySubtitle': 'Add tags to links to organize them',

    // Tag Filtered
    'tagFiltered.empty': 'No links with this tag',

    // Delete Dialog
    'dialog.deleteTitle': 'Delete link',
    'dialog.deleteMessage': 'Do you want to delete this link?',

    // Add Link
    'addLink.title': 'Add Link',
    'addLink.urlLabel': 'URL',
    'addLink.urlHint': 'https://example.com',
    'addLink.urlRequired': 'Please enter a URL',
    'addLink.urlInvalid': 'Invalid URL',
    'addLink.duplicateError': 'This link is already saved.',
    'addLink.titleLabel': 'Title (optional)',
    'addLink.titleHint': 'Link description',
    'addLink.tagsLabel': 'Tags (comma-separated)',
    'addLink.tagsHint': 'SPORT, TECH, NEWS',

    // Edit Link
    'editLink.title': 'Edit Link',
    'editLink.titleLabel': 'Title',
    'editLink.tagsLabel': 'Tags (comma-separated)',
    'editLink.noteLabel': 'Personal note',
    'editLink.noteHint': 'Your thoughts, context, why you saved this…',
    'editLink.save': 'Save changes',

    // Auth
    'auth.signIn': 'Sign in',
    'auth.signUp': 'Register',
    'auth.email': 'Email',
    'auth.password': 'Password',
    'auth.emailRequired': 'Enter your email',
    'auth.emailInvalid': 'Invalid email',
    'auth.passwordRequired': 'Enter your password',
    'auth.passwordTooShort': 'Minimum 6 characters',
    'auth.noAccount': "Don't have an account? Register",
    'auth.hasAccount': 'Already have an account? Sign in',
    'auth.forgotPassword': 'Forgot password?',
    'auth.resetPassword': 'Reset Password',
    'auth.resetPasswordMessage': 'Enter your email to receive a password reset link',
    'auth.sendResetLink': 'Send reset link',
    'auth.resetSent': 'Check your email for a password reset link',
    'auth.backToSignIn': 'Back to sign in',

    // Auth Errors
    'auth.errorEmailInUse': 'Email already in use.',
    'auth.errorInvalidEmail': 'Invalid email.',
    'auth.errorWeakPassword': 'Password too weak (min. 6 characters).',
    'auth.errorUserNotFound': 'User not found.',
    'auth.errorWrongPassword': 'Wrong password.',
    'auth.errorInvalidCredential': 'Invalid credentials.',
    'auth.errorGeneric': 'Error: {code}',
    'auth.errorUnexpected': 'Unexpected error. Try again.',

    // Link Card
    'linkCard.cannotOpen': 'Cannot open this link',
    'linkCard.editTooltip': 'Edit',
    'linkCard.addFavorite': 'Add to favorites',
    'linkCard.removeFavorite': 'Remove from favorites',
    'linkCard.timeNow': 'now',
    'linkCard.timeDays': '{n}d',

    // Options / Settings screen
    'options.title': 'Settings',
    'options.sectionAccount': 'Account',
    'options.sectionCollection': 'Collection',
    'options.sectionStats': 'Statistics',
    'options.sectionData': 'Data',
    'options.signedInAs': 'Signed in as',
    'options.signOut': 'Sign out',
    'options.signIn': 'Sign in / Register',
    'options.totalLinks': 'Total links',
    'options.favorites': 'Favorites',
    'options.tags': 'Tags',
    'options.folders': 'Folders',
    'options.exportJson': 'Export as JSON',
    'options.exportSuccess': '{n} links exported',
    'options.exportError': 'Export failed',
    'options.clearLibrary': 'Clear library (demo)',
    'options.clearLibraryTitle': 'Clear library?',
    'options.clearLibraryMessage':
        'Deletes every saved link. This cannot be undone.',
    'options.footer': 'Amber · Void v2 · design concept',
    'options.save': 'Save',
    'options.saved': 'Saved',

    // Tag management
    'tags.renameTag': 'Rename tag',
    'tags.deleteTag': 'Delete tag',
    'tags.mergeInto': 'Merge into…',
    'tags.renameHint': 'New tag name',
    'tags.confirm': 'Confirm',
    'tags.mergeHint': 'Target tag',
    'tags.selectLinks': 'Select links',
    'tags.selectedCount': '{n} selected',
    'tags.addTagToSelected': 'Add tag',
    'tags.removeTagFromSelected': 'Remove tag',
    'tags.tagHint': 'TAG NAME',
    'tags.bulkDone': 'Done',

    // Home filters & grouping
    'home.filterAll': 'All',
    'home.filterUnread': 'Unread',
    'home.groupToday': 'Today',
    'home.groupYesterday': 'Yesterday',
    'home.groupThisWeek': 'This week',
    'home.groupThisMonth': 'This month',
    'home.groupEarlier': 'Earlier',

    // Read state
    'link.markRead': 'Mark as read',
    'link.markUnread': 'Mark as unread',

    // Collections
    'collections.fieldLabel': 'Collection',
    'collections.none': 'No collection',
    'collections.clearFilter': 'Clear collection filter',
    'collections.emptyTitle': 'No links in this collection',
    'collections.emptySubtitle':
        'Edit a link and assign it to this collection.',
    'collections.add': 'New collection',
    'collections.addTitle': 'Add collection',
    'collections.nameHint': 'Collection name',
    'collections.rename': 'Rename',
    'collections.deleteConfirm': 'Delete collection?',
    'collections.deleteMessage':
        'Links in this collection will not be deleted.',
    'collections.manage': 'Manage collections',

    // Filter sheet
    'filters.title': 'Filters',
    'filters.folder': 'FOLDER',
    'filters.allFolders': 'All',
    'filters.status': 'STATUS',
    'filters.tags': 'TAGS',
    'filters.crossFolder': 'across all folders',
    'filters.reset': 'Reset',
    'filters.apply': 'Apply',

    // Search
    'home.searchHint': 'Search links…',
    'favorites.searchHint': 'Search favorites…',
    'search.title': 'Search',
    'search.emptyTitle': 'No results',

    // Tags cloud
    'tags.subtitle':
        'Every link, from every folder. Tap a tag to explore it — size = how often you use it.',
  },
  'it': {
    // Common
    'common.save': 'Salva',
    'common.cancel': 'Annulla',
    'common.delete': 'Elimina',
    'common.saving': 'Salvataggio...',

    // Navigation
    'nav.home': 'Home',
    'nav.favorites': 'Preferiti',
    'nav.tags': 'Tag',
    'nav.addLink': 'Aggiungi link',
    'nav.signOut': 'Esci',

    // Home
    'home.title': 'Amber',
    'home.emptyTitle': 'Nessun link salvato',
    'home.emptySubtitle':
        "Tocca + per aggiungerne uno\noppure condividi un link da un'altra app",

    // Favorites
    'favorites.title': 'Preferiti',
    'favorites.emptyTitle': 'Nessun preferito',
    'favorites.emptySubtitle':
        'Tocca la stella su un link per aggiungerlo ai preferiti',

    // Tags
    'tags.title': 'Tag',
    'tags.all': 'Tutti',
    'tags.emptyTitle': 'Nessun tag',
    'tags.emptySubtitle': 'Aggiungi tag ai link per organizzarli',

    // Tag Filtered
    'tagFiltered.empty': 'Nessun link con questo tag',

    // Delete Dialog
    'dialog.deleteTitle': 'Elimina link',
    'dialog.deleteMessage': 'Vuoi eliminare questo link?',

    // Add Link
    'addLink.title': 'Aggiungi Link',
    'addLink.urlLabel': 'URL',
    'addLink.urlHint': 'https://esempio.com',
    'addLink.urlRequired': 'Inserisci un URL',
    'addLink.urlInvalid': 'URL non valido',
    'addLink.duplicateError': 'Questo link è già stato salvato.',
    'addLink.titleLabel': 'Titolo (opzionale)',
    'addLink.titleHint': 'Descrizione del link',
    'addLink.tagsLabel': 'Tag (separati da virgola)',
    'addLink.tagsHint': 'SPORT, TECH, NEWS',

    // Edit Link
    'editLink.title': 'Modifica Link',
    'editLink.titleLabel': 'Titolo',
    'editLink.tagsLabel': 'Tag (separati da virgola)',
    'editLink.noteLabel': 'Nota personale',
    'editLink.noteHint': 'Pensieri, contesto, perché hai salvato questo link…',
    'editLink.save': 'Salva modifiche',

    // Auth
    'auth.signIn': 'Accedi',
    'auth.signUp': 'Registrati',
    'auth.email': 'Email',
    'auth.password': 'Password',
    'auth.emailRequired': 'Inserisci la tua email',
    'auth.emailInvalid': 'Email non valida',
    'auth.passwordRequired': 'Inserisci la password',
    'auth.passwordTooShort': 'Minimo 6 caratteri',
    'auth.noAccount': 'Non hai un account? Registrati',
    'auth.hasAccount': 'Hai già un account? Accedi',
    'auth.forgotPassword': 'Password dimenticata?',
    'auth.resetPassword': 'Reimposta Password',
    'auth.resetPasswordMessage': 'Inserisci la tua email per ricevere un link per reimpostare la password',
    'auth.sendResetLink': 'Invia link',
    'auth.resetSent': 'Controlla la tua email per il link di reimpostazione della password',
    'auth.backToSignIn': 'Torna all\'accesso',

    // Auth Errors
    'auth.errorEmailInUse': 'Email già in uso.',
    'auth.errorInvalidEmail': 'Email non valida.',
    'auth.errorWeakPassword': 'Password troppo debole (min. 6 caratteri).',
    'auth.errorUserNotFound': 'Utente non trovato.',
    'auth.errorWrongPassword': 'Password errata.',
    'auth.errorInvalidCredential': 'Credenziali non valide.',
    'auth.errorGeneric': 'Errore: {code}',
    'auth.errorUnexpected': 'Errore imprevisto. Riprova.',

    // Link Card
    'linkCard.cannotOpen': 'Impossibile aprire il link',
    'linkCard.editTooltip': 'Modifica',
    'linkCard.addFavorite': 'Aggiungi ai preferiti',
    'linkCard.removeFavorite': 'Rimuovi dai preferiti',
    'linkCard.timeNow': 'ora',
    'linkCard.timeDays': '{n}g',

    // Options / Settings screen
    'options.title': 'Impostazioni',
    'options.sectionAccount': 'Account',
    'options.sectionCollection': 'Collezione',
    'options.sectionStats': 'Statistiche',
    'options.sectionData': 'Dati',
    'options.signedInAs': 'Accesso come',
    'options.signOut': 'Esci',
    'options.signIn': 'Accedi / Registrati',
    'options.totalLinks': 'Link totali',
    'options.favorites': 'Preferiti',
    'options.tags': 'Tag',
    'options.folders': 'Cartelle',
    'options.exportJson': 'Esporta come JSON',
    'options.exportSuccess': '{n} link esportati',
    'options.exportError': 'Esportazione fallita',
    'options.clearLibrary': 'Svuota libreria (demo)',
    'options.clearLibraryTitle': 'Svuotare la libreria?',
    'options.clearLibraryMessage':
        'Elimina tutti i link salvati. Azione irreversibile.',
    'options.footer': 'Amber · Void v2 · concept di design',
    'options.save': 'Salva',
    'options.saved': 'Salvato',

    // Tag management
    'tags.renameTag': 'Rinomina tag',
    'tags.deleteTag': 'Elimina tag',
    'tags.mergeInto': 'Unisci in…',
    'tags.renameHint': 'Nuovo nome tag',
    'tags.confirm': 'Conferma',
    'tags.mergeHint': 'Tag destinazione',
    'tags.selectLinks': 'Seleziona link',
    'tags.selectedCount': '{n} selezionati',
    'tags.addTagToSelected': 'Aggiungi tag',
    'tags.removeTagFromSelected': 'Rimuovi tag',
    'tags.tagHint': 'NOME TAG',
    'tags.bulkDone': 'Fatto',

    // Home filters & grouping
    'home.filterAll': 'Tutti',
    'home.filterUnread': 'Non letti',
    'home.groupToday': 'Oggi',
    'home.groupYesterday': 'Ieri',
    'home.groupThisWeek': 'Questa settimana',
    'home.groupThisMonth': 'Questo mese',
    'home.groupEarlier': 'Prima',

    // Read state
    'link.markRead': 'Segna come letto',
    'link.markUnread': 'Segna come non letto',

    // Collections
    'collections.fieldLabel': 'Cartella',
    'collections.none': 'Nessuna cartella',
    'collections.clearFilter': 'Rimuovi filtro cartella',
    'collections.emptyTitle': 'Nessun link in questa cartella',
    'collections.emptySubtitle':
        'Modifica un link e assegnalo a questa cartella.',
    'collections.add': 'Nuova cartella',
    'collections.addTitle': 'Aggiungi cartella',
    'collections.nameHint': 'Nome cartella',
    'collections.rename': 'Rinomina',
    'collections.deleteConfirm': 'Eliminare la cartella?',
    'collections.deleteMessage':
        'I link in questa cartella non verranno eliminati.',
    'collections.manage': 'Gestisci cartelle',

    // Filter sheet
    'filters.title': 'Filtri',
    'filters.folder': 'CARTELLA',
    'filters.allFolders': 'Tutte',
    'filters.status': 'STATO',
    'filters.tags': 'TAG',
    'filters.crossFolder': 'trasversali alle cartelle',
    'filters.reset': 'Reimposta',
    'filters.apply': 'Applica',

    // Search
    'home.searchHint': 'Cerca nei link…',
    'favorites.searchHint': 'Cerca nei preferiti…',
    'search.title': 'Cerca',
    'search.emptyTitle': 'Nessun risultato',

    // Tags cloud
    'tags.subtitle':
        'Tutti i link, di ogni cartella. Tocca un tag per esplorarlo — dimensione = quanto lo usi.',
  },
};

String _getLocale() {
  final lang = PlatformDispatcher.instance.locale.languageCode;
  return lang == 'it' ? 'it' : 'en';
}

String t(String key, [Map<String, String>? vars]) {
  final locale = _getLocale();
  var val = _translations[locale]?[key] ?? _translations['en']?[key] ?? key;
  if (vars != null) {
    vars.forEach((k, v) => val = val.replaceAll('{$k}', v));
  }
  return val;
}
