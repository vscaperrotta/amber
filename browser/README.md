# Amber for Chrome

Manifest V3 Chrome extension — save links from any page, browse them on the new tab page, or from the side panel. React 19, Vite, Firebase Auth + Firestore, SCSS.

See the [root README](../README.md) for the full feature list, data model, and Firebase setup shared across all Amber clients.

## Requirements

- Node.js ≥ 22 (`.nvmrc` → `22.22.2`, run `nvm use`)
- npm only — never yarn (lockfile is `package-lock.json`)

## Setup

```bash
cp .env.example .env   # fill in your Firebase project config
npm install
npm run dev            # Vite HMR dev build
```

Load the extension: `chrome://extensions/` → enable **Developer mode** → **Load unpacked** → select `dist/`.

## Commands

```bash
npm run build            # production: clear → vite build → manifest.json → zip
npm run lint              # ESLint
npm run clear              # delete dist/
npm run storybook         # component dev server on :6006
npm run build-storybook   # build static storybook
```

No test runner is configured.

## Contexts

Four independently bundled entry points, built in a single Vite multi-entry pass:

| Context | Entry | Notes |
|---|---|---|
| `background` | `src/background/index.js` | Service worker |
| `content` | `src/content/index.jsx` | Injected into all pages — save overlay |
| `popup` | `src/popup/index.html` | Toolbar popup — quick save/delete |
| `newtab` | `src/newtab/index.html` | Main browse/search/organize UI |
| `sidepanel` | `src/sidepanel/index.html` | Persistent side panel |
| `options` | `src/options/index.html` | Account (sign in, register, password recovery), settings, import/export |

## Data layer

Firebase Auth (email/password + Google) + Firestore for cloud sync, falling back to IndexedDB when logged out. `src/utils/useLinks.js` abstracts over both backends.

## Docs

- [CLAUDE.md](./CLAUDE.md) — conventions, component structure, reference architecture
- [MAP.md](./MAP.md) — full source tree and data flow diagrams
