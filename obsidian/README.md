# Amber for Obsidian

Obsidian plugin — manage saved links inside your vault. TypeScript, esbuild, Firebase, SCSS.

See the [root README](../README.md) for the full feature list, data model, and Firebase setup shared across all Amber clients.

## Requirements

- Node.js ≥ 16
- An Obsidian vault

## Setup

```bash
cp .env.example .env   # fill in your Firebase config
npm install
npm run build           # tsc type-check → esbuild + sass → main.js + styles.css
```

**Install into Obsidian:** copy `main.js`, `manifest.json`, `styles.css` into `<vault>/.obsidian/plugins/amber/`, then enable **Amber** under Settings → Community plugins.

## Commands

```bash
npm run dev      # esbuild watch + sass watch, for live-reload development
npm run build    # production build
```

## Architecture

- **Entry point:** `src/main.ts` — registers the view, ribbon icon, settings tab.
- **Dual-storage pattern:** `LinksService` (`src/utils/linksService.ts`) is the single source of truth — switches between Firestore (logged in, real-time listener) and a local JSON file at `Amber/links.json` in the vault (logged out).
- **View:** `src/views/pluginView.ts` renders login/logout, add-link form, and links list.
- **Firebase config:** `src/firebase.ts` — hardcoded public project config.
- **Legacy book library:** `src/services/storage.ts` — older reading-collection feature, superseded by links but still surfaced in the settings tab.

## Docs

- [CLAUDE.md](./CLAUDE.md) — conventions and architecture notes
- [MAP.md](./MAP.md) — full source tree
