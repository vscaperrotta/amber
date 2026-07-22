# Privacy Policy — Amber

_Last updated: 22 July 2026_

Amber is a personal link-saving tool for Chrome. It does not collect analytics, show ads, or sell data. This page explains exactly what is handled and where it goes.

**Contact:** vittorio.scaperrotta@outlook.com

---

## Data you save

- The **URL and title** of links you explicitly save.
- **Page metadata** fetched at save time: description, thumbnail image, favicon, and canonical URL.
- A temporary **viewport screenshot** used as a fallback thumbnail if no `og:image` is found — replaced automatically once metadata is enriched.
- Optional **tags, notes, collections, and favourite/read flags** you add.
- Your **account email** and display name, when you choose to sign in.

Nothing is read or saved from a page until you explicitly trigger a save (toolbar button, side panel, or the `Ctrl/Cmd+Shift+S` shortcut).

---

## Where data is stored

- **Not signed in:** all links are stored locally in IndexedDB in your browser. Nothing leaves your device.
- **Signed in:** links are synced to **Firebase Firestore** (Google Cloud) under your account UID, readable only by that account. Preferences are synced via `chrome.storage.sync`.
- On sign-in, local links are migrated to Firestore and the local database is cleared.
- Deleting a link deletes it from Firestore. Deleting your account removes the associated data.

---

## Permissions and why they are needed

| Permission | Why |
|---|---|
| `storage` | Save links and preferences locally / sync them to your account. |
| `activeTab`, `tabs` | Read the URL and title of the tab you choose to save. |
| `scripting` | Read `og:` metadata from the page you are saving, at the moment you save it. |
| `sidePanel` | Show the Amber side panel. |

Amber requests no host permissions for background access and runs no code on pages you have not asked it to save.

---

## What Amber does NOT do

- Does not track your browsing history.
- Does not collect analytics or usage telemetry.
- Does not show ads.
- Does not sell or share your data with third parties.
- Does not use your data for advertising, credit scoring, or lending.
- Does not access any page you have not explicitly saved.

---

## Third-party services

| Service | Purpose | Privacy Policy |
|---|---|---|
| Firebase (Google) | Authentication and cloud storage when signed in | [firebase.google.com/support/privacy](https://firebase.google.com/support/privacy) |

---

## Changes

This policy lives at
<https://github.com/vscaperrotta/amber/blob/master/PRIVACY.md> and is the same
URL published in the Chrome Web Store listing. Material changes are noted by the
"Last updated" date above.
