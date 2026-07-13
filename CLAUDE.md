# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

Monorepo for **Amber** — a cross-platform link-saving app (save/organize URLs, similar to Pocket). Three independently developed clients:

| Directory | Description | Stack |
|---|---|---|
| `browser/` | Chrome extension ("Amber") | React 19, Vite, Firebase, SCSS |
| `flutter/` | Mobile app | Flutter/Dart, Firebase, SQLite |
| `obsidian/` | Obsidian plugin | TypeScript, esbuild, Firebase, SCSS |

Each sub-project has its own `CLAUDE.md` with full details:
- [`browser/CLAUDE.md`](browser/CLAUDE.md)
- [`flutter/CLAUDE.md`](flutter/CLAUDE.md)
- [`obsidian/CLAUDE.md`](obsidian/CLAUDE.md)

## Shared Concepts

All clients share the same product model:
- **Auth:** Firebase Auth (Google sign-in or email/password)
- **Cloud storage:** Firestore at `/users/{uid}/links/{linkId}`
- **Local fallback:** IndexedDB (browser) / SQLite (flutter) / JSON file (obsidian) when logged out
- **Migration:** On login, local links migrate to Firestore and local storage is cleared
- **Link model:** `id` (UUID v4), `url`, `title`, `savedAt`, optional `metadata` (tags, description, collectionId, isFavorite, isRead, …)

## Working in a Sub-project

Always `cd` into the relevant sub-project before running commands. Each manages its own dependencies and build independently.

**Package manager: npm only — never yarn**, across all sub-projects. Don't introduce or commit a `yarn.lock`.

## Design System

Void v2 — see [`DESIGN.md`](DESIGN.md) for full token reference. Key tokens:

| Token | Dark | Light |
|---|---|---|
| bg-primary | `#0F0F12` | `#F5F5F7` |
| bg-surface | `#16161E` | `#FFFFFF` |
| bg-elevated | `#222232` | `#EBEBEF` |
| accent | `#F5A623` | `#E8950F` |
| text-primary | `#FFFFFF` | `#0F0F12` |
| text-secondary | `#C0C0D0` | — |
| border | `#303048` | `#D0D0E0` |

Font: **Outfit** in the browser; Flutter uses **Mulish** (body) + **Baloo2** (display headings) bundled locally; Obsidian inherits from the host theme.
