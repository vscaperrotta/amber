# MAP — flutter (Mobile App)

Stack: Flutter/Dart, Firebase Auth + Firestore, SQLite, Provider  
Build: `flutter build apk` (requires Java 17+)

## Source tree

```
lib/
├── main.dart                          # App entry — MultiProvider setup, share intent listener
├── firebase_options.dart              # FlutterFire generated config — replace with your own Firebase project
│
├── models/
│   ├── link_item.dart                 # LinkItem — id, url, title, tags, createdAt, isFavorite, isRead, thumbnail?, note?, collectionId?
│   ├── collection_item.dart           # CollectionItem — id, name, parentId?, color?, createdAt (folder)
│   └── link_filter.dart               # LinkFilter — combined filter state (collectionId?, unreadOnly, tags)
│
├── providers/                         # ChangeNotifier state (Provider pattern)
│   ├── auth_provider.dart             # Firebase Auth state — user, isLoggedIn, sign-in/out
│   ├── link_provider.dart             # Links list — delegates to LinkRepository, exposes CRUD
│   ├── collection_provider.dart       # Collections list — delegates to CollectionRepository
│   └── ui_state_provider.dart         # UI toggles (grid/list, active tab, filter state)
│
├── services/
│   ├── link_repository.dart           # Routes link calls: logged in → Firebase, offline → SQLite
│   ├── collection_repository.dart     # Routes collection calls: logged in → Firebase, offline → SQLite
│   ├── firebase_storage_service.dart  # Firestore CRUD + migration + collections + user settings
│   ├── local_storage_service.dart     # SQLite (amber.db, schema v8) — links + collections tables
│   ├── auth_service.dart              # Firebase Auth wrappers (Google, email, sign-out)
│   └── metadata_service.dart          # Fetch OG meta from URL for title/thumbnail
│
├── screens/
│   ├── home_screen.dart               # Link list/grid — search, sort, filter
│   ├── add_link_screen.dart           # Save new link (pre-fills title/thumbnail via MetadataService)
│   ├── search_screen.dart             # Full-text search across links
│   ├── favorites_screen.dart          # Filtered favorites view
│   ├── tags_screen.dart               # Tag list + counts
│   ├── options_screen.dart            # Settings — default view
│   ├── auth_screen.dart               # Sign in / register
│   └── forgot_password_screen.dart    # Password reset flow
│
├── widgets/
│   ├── main_scaffold.dart             # Bottom nav, FAB, tab switching
│   ├── link_card.dart                 # Link card
│   ├── link_avatar.dart               # Thumbnail/favicon for a link
│   ├── edit_link_sheet.dart           # Bottom sheet to edit link fields
│   ├── filter_sheet.dart              # Bottom sheet for LinkFilter (folder/unread/tags)
│   ├── group_header.dart              # Date-bucket section header
│   ├── pill_filter_chip.dart          # Pill-style filter chip
│   ├── action_sheet.dart              # Contextual action bottom sheet
│   ├── header_icon_button.dart        # AppBar icon button helper
│   ├── empty_state_view.dart          # Empty-list placeholder
│   └── loading_spinner.dart           # Loading indicator
│
├── theme/
│   ├── void_colors.dart               # Void v2 color constants (accent, bg-*, text-*, border)
│   ├── app_colors.dart                # Semantic aliases (light/dark) exposed as ThemeExtension
│   ├── app_fonts.dart                 # AppFonts.body() (Mulish) / AppFonts.display() (Baloo2)
│   └── cool_icons.dart                # CoolIcons icon font mapping
│
└── utils/
    ├── i18n.dart                      # t() — IT translations (app primary language)
    ├── normalize_url.dart             # URL normalization helper
    ├── time_bucket.dart               # Date bucketing for list sections
    ├── dialogs.dart                   # Generic dialog helpers
    └── collection_dialogs.dart        # Collection create/rename/delete dialogs
```

## Key data flows

```
Save link
  AddLinkScreen → MetadataService.fetchMetadata(url) → pre-fill title/thumbnail
    → linkProvider.addLink(link)
      → linkRepository.addLink()
        → logged in:  FirebaseStorageService.addLink() (Firestore /users/{uid}/links)
        → offline:    LocalStorageService.addLink() (SQLite links table)

Login migration
  AuthProvider.signIn() → linkRepository.migrateLocalToCloud()
    → reads all SQLite links → writes to Firestore → clears SQLite

Collections
  CollectionProvider → collectionRepository.{get,add,update,delete}()
    → logged in:  FirebaseStorageService (Firestore /users/{uid}/collections)
    → offline:    LocalStorageService (SQLite collections table)

Browse links
  LinkProvider.links (in-memory list, refreshed via reload)
  → HomeScreen (list or grid, filtered by LinkFilter)
  → FavoritesScreen / TagsScreen / SearchScreen
```

## Storage schema (SQLite — amber.db, version 8)

```sql
CREATE TABLE links (
  id TEXT PRIMARY KEY,
  url TEXT NOT NULL,
  title TEXT NOT NULL,
  tags TEXT NOT NULL DEFAULT '',        -- comma-separated, uppercase
  savedAt INTEGER NOT NULL,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  is_read INTEGER NOT NULL DEFAULT 1,
  ai_description TEXT DEFAULT '',
  thumbnail TEXT DEFAULT '',
  note TEXT DEFAULT '',
  collection_id TEXT DEFAULT ''         -- FK → collections.id
);

CREATE TABLE collections (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  parent_id TEXT,                       -- self-reference for nested folders
  color TEXT,
  created_at INTEGER NOT NULL
);
```

Migrations: `onUpgrade` handles versions 2–8 incrementally (adds columns, creates the `collections` table at v7, adds `color` at v8).

## Settings persistence

User preferences: `SharedPreferences` locally, synced to Firestore at `/users/{uid}/settings/preferences` when logged in.