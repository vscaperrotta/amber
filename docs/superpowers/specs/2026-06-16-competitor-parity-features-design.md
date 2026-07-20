# Competitor-parity features — browser extension

## Context

Competitor analysis (Raindrop.io, Pocket alternatives — Instapaper, Matter, Wallabag, Readwise Reader) surfaced 12 features Amber lacks. User confirmed building all of them in this iteration, across three priority tiers. Scope explicitly includes P2 items (reader mode, TTS, RSS reader) despite tension with PRODUCT.md's "calm over novelty / not a second brain" principle — accepted deviation, noted here for the record.

One scope reduction from the original ask: "newsletter inbox" (real email-forwarding ingestion) is dropped. It requires a dedicated inbound email address + webhook receiver — a different, much larger project. What ships instead is an **RSS feed reader** (subscribe to public feeds, pull items as save-able links), which covers the "external content inbox" need without the email infra.

All work is scoped to `browser/` (Chrome extension). No changes to `flutter/` or `obsidian/`.

## Build order & dependency notes

Items 1–6 need no new infrastructure — they extend existing Firestore documents, the existing content script, and existing background-script save flow. Items 7–8 need **new infra** (Firebase Hosting + a Cloud Function) — first server-side code in this repo, which has been 100% client-Firebase until now. Items 9–11 are pure client features layered on top of 5's extracted content.

1. Duplicate detection
2. Full-text search widening
3. Bulk import (Netscape bookmarks HTML)
4. Keyboard shortcuts
5. Permanent copy (readable-text snapshot)
6. Highlights (selection saved as a note, no live re-injection)
7. Public shareable collection
8. RSS export of a public collection
9. Reader mode
10. Text-to-speech
11. RSS feed reader (subscribe to external feeds)
12. (this spec + the implementation plan that follows it)

---

## 1. Duplicate detection

**What:** On save (popup "Save current page" and content-script quick-save), normalize the URL (strip `www.`, trailing slash, and known tracking query params via the existing `extractDomain`-adjacent logic) and check it against the user's existing links. If a match exists, surface it instead of creating a duplicate.

**Data:** No new fields. Compare against `link.url` (normalized) in the already-loaded `links` array (`useLinks` hook already holds the full list client-side).

**UI:** `saveCurrentTab()` / `saveCustomLink()` in `useLinks.js` return a `{ duplicate: true, existingLink }` result instead of writing. Popup (`App.jsx`) and content-script `SaveOverlay.jsx` show "Already saved" with a link to the existing entry instead of "Saved."

**Edge case:** User can still force-save a duplicate via a small "Save anyway" action — duplicates aren't blocked, just flagged (matches Raindrop's non-destructive approach).

## 2. Full-text search widening

**What:** `HomeView`'s `searchQuery` filter currently matches `title`, `url`, `metadata.description`. Add `metadata.tags` (joined) and the extracted domain to the match set.

**Data/UI:** No schema change. Pure filter-function edit in `HomeView.jsx`/`FavoritesView.jsx`.

## 3. Bulk import

**What:** Options page gets an "Import bookmarks" action: file picker accepts a Netscape bookmark HTML export (the universal format Chrome/Firefox/Raindrop/Pocket all export). Parse `<A HREF="...">Title</A>` entries, map folder nesting to tags (top folder name → tag), batch-write via existing `saveCustomLink`.

**Data:** Reuses the existing link schema. No new fields.

**UI:** New section in Options, progress indicator (`Importing… {done}/{total}`, same pattern as the existing AI-description batch generator). Duplicate detection (#1) applies automatically during import — duplicates are skipped, not re-saved.

## 4. Keyboard shortcuts

**What:**
- Global browser shortcut (manifest `commands` key) — default `Ctrl+Shift+S` / `Cmd+Shift+S` — saves the current tab without opening the popup, using the same background-script save path the popup button uses. Configurable by the user at `chrome://extensions/shortcuts` (standard Chrome UX, no custom UI needed).
- In-page shortcut on the newtab surface only: `/` focuses the search input (checked against existing focus so it doesn't fire while typing elsewhere).

**Data:** None. **Manifest:** add a `commands` block to `src/manifest.js`, handle it in `background/index.js` alongside the existing `onInstalled`/action handlers.

## 5. Permanent copy (page snapshot)

**What:** At save time, alongside the existing thumbnail/metadata enrichment (`triggerEnrichment` in `background/index.js`), fetch the page HTML (already being fetched for og:image extraction) and run a lightweight readability extraction (strip nav/ads/scripts, keep article text) — reuse Readability-style heuristics, not a full Mozilla-readability dependency unless the bundle-size cost is acceptable (flag this trade-off in the implementation plan). Store the resulting plain text in Firebase Storage at `users/{uid}/snapshots/{linkId}.txt`, store the Storage URL in `metadata.snapshotUrl`.

**Why client-extracted, not a Cloud Function:** the background service worker already fetches and parses the HTML for thumbnails; doing the readability extraction there is free — no new infra for this one item.

**UI:** Link card gets a subtle "saved copy" indicator when `metadata.snapshotUrl` exists (used by reader mode, #9).

## 6. Highlights

**What:** Content script (already injected on every page for the save overlay) listens for text selection. A small floating "Save highlight" button appears near the selection (similar pattern to the existing `SaveOverlay`). On click, sends `{ url, selectedText }` to the background script, which either attaches the highlight to an existing saved link for that URL or creates one.

**Data:** New `metadata.highlights: Array<{ text: string, savedAt: number }>` field on the link document. Plain text, no DOM anchoring, no live re-injection on revisit — confirmed simpler approach.

**UI:** Highlights render as a list under the description in `LinkItem.jsx`, gated behind the existing "description visible" expand state — read-only list, no editing beyond delete-per-highlight.

## 7. Public shareable collection

**What:** A tag (or "all links") can be marked shareable. A public, unauthenticated page at a new Firebase Hosting site (e.g. `amber-share.web.app/u/{shareId}`) reads the user's links filtered to that tag directly from Firestore via a relaxed security rule scoped to documents with `isPublic: true` and matching `shareId`.

**New infra:** Firebase Hosting (static React build, can reuse newtab's component library and design tokens) + a new top-level Firestore collection `publicShares/{shareId}` (denormalized: `{ uid, tag, createdAt }`) so the public rule never needs to read the user's private settings doc.

**Security:** Firestore rule for `publicShares/{shareId}`: public read, write only by the owning `uid`. Links collection rule gains a narrow public-read clause scoped to `request.resource.data.metadata.tags` matching a published share's tag — **this is the one part of this spec that touches existing security rules and needs careful review before deploy**, flagged for the implementation plan.

**UI:** Options page gets a "Share" toggle per tag (in the existing tag-management section), showing the generated public URL once enabled.

## 8. RSS export

**What:** A Cloud Function (`functions/rssFeed.js`, first Cloud Function in this repo) at `https://.../rss/{shareId}` reads the same `publicShares` + filtered links Firestore data server-side and renders an RSS 2.0 XML document. RSS readers can't execute JS, so this can't be the static Hosting page from #7 — it needs to run server-side.

**New infra:** Firebase Cloud Functions (Node runtime), billing implication (Functions require the Blaze plan even at near-zero usage) — **flagged for explicit confirmation before deploy**, since it's a cost/plan change, not just code.

**UI:** The public share page (#7) shows an "RSS" link alongside the public URL.

## 9. Reader mode

**What:** Clicking a link with a stored snapshot (#5) opens a distraction-free reader view inside the newtab page (modal or dedicated route) rendering the saved plain-text snapshot in Amber's typography system, instead of (or in addition to) opening the original URL.

**Data:** Reuses `metadata.snapshotUrl` from #5. No new fields.

**UI:** New `ReaderView` component, opened from a "Read" action on `LinkItem` (only shown when a snapshot exists).

## 10. Text-to-speech

**What:** Reader mode (#9) gets a "Listen" control using the browser's built-in `SpeechSynthesis` Web API on the snapshot text. Zero new dependencies, zero infra — pure client feature.

**UI:** Play/pause/stop controls in the `ReaderView` header.

## 11. RSS feed reader

**What:** Options page gets a "Feeds" section where the user adds external RSS feed URLs. A background-script periodic check (`chrome.alarms`, already permitted via existing `tabs`/`storage` permissions — needs the `alarms` permission added to the manifest) fetches each feed, and new items appear in a dedicated "Feed" view in the newtab sidebar as save-able candidates (not auto-saved — explicit save per item, consistent with Amber's "save links you chose" model rather than turning into an auto-ingesting reader).

**Data:** New Firestore subcollection `users/{uid}/feeds/{feedId}` (`{ url, title, lastFetched }`). Feed items themselves are not persisted server-side — fetched live into memory each time the view opens, to avoid duplicating RSS-reader-scale storage in Firestore.

**UI:** New sidebar nav entry "Feeds" (mirrors Home/Favorites/Tags), new `FeedsView.jsx`.

---

## Out of scope (explicitly)

- Real email-newsletter ingestion (dedicated inbound address + webhook) — separate future project, not attempted here.
- Live highlight re-injection onto the original page on revisit — rejected in favor of the simpler text-only approach (see #6).
- Nested collections / folders — Amber's flat-tag model is treated as sufficient; not revisited in this batch.

## Testing approach

Per-feature: code review + `npm run build` + `npm run lint` clean, consistent with how every other feature this session was verified. Live in-browser verification where feasible via the real installed extension (screenshot-only, per the architectural limits already hit this session — AGENTS.md-in-Chrome can't access other extensions' pages, computer-use grants browsers read-only). No automated test runner exists in this repo (per `browser/AGENTS.md.md`); none is being introduced for this batch.
