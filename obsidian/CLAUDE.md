# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm install          # install dependencies
npm run dev          # development: esbuild watch + sass watch (concurrently)
npm run build        # production build: tsc type-check, then esbuild + sass
```

The build outputs `main.js` (bundled plugin) and `styles.css` in the project root, which Obsidian loads directly.

## Architecture

This is an Obsidian plugin (TypeScript + esbuild) that lets users save and manage links. It uses Firebase for cloud sync when logged in, and a local JSON file in the vault when offline/unauthenticated.

**Entry point:** `src/main.ts` — registers the view, ribbon icon, and settings tab. Plugin settings are persisted via Obsidian's `loadData`/`saveData`.

**Dual-storage pattern (core concept):**
- `LinksService` (`src/utils/linksService.ts`) is the single source of truth for the UI. It listens to Firebase Auth state and automatically switches between:
  - **Logged in:** Firestore real-time listener (`src/utils/firebaseDb.ts`) — `users/{uid}/links` collection, ordered by `savedAt` desc.
  - **Logged out:** local JSON file (`src/services/localLinksStorage.ts`) at `Amber/links.json` in the vault.
- The view calls `LinksService.addLink` / `deleteLink` without knowing which backend is active.

**View:** `src/views/pluginView.ts` extends `ItemView`. It renders a login/logout form, an "Add Link" form, and the links list. Auth state changes (via `onAuthStateChanged`) toggle visibility of login/logout sections. The links list is re-rendered by calling `renderLinksList()` via the `onChange` callback passed to `LinksService`.

**Firebase config:** `src/firebase.ts` — initializes the app, `auth`, and `db` (Firestore). The config values are hardcoded (public Firebase project).

**Settings tab:** `src/settings/settingsTab.ts` — manages library folder, linked local JSON file (for the book library feature, not links), create/export library, and support links.

**Legacy book library:** `src/services/storage.ts` and types in `src/types/` (`BookType`, `DataType`, etc.) represent an older reading-collection feature (books/manga). The `Data` type wraps a `Book[]` array with metadata. This is largely superseded by the links feature but the settings tab still surfaces it.

**Styles:** `src/styles/main.scss` imports all partials. Component styles are in `src/styles/components/`, view styles in `src/styles/views/`. CSS class prefix: `obs-amber-`.

**i18n:** `src/utils/i18n.ts` exports a `t(key)` function with `en` and `it` dictionaries (auto-detected from Obsidian's locale). All UI strings go through `t()` — never hardcode strings.

**UI components:** `src/components/` contains small helpers (`renderInput`, `renderHeader`, etc.) that return/append DOM elements using Obsidian's `createEl` API.
