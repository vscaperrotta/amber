import { useState, useEffect, useRef, useCallback } from 'react';
import { useAuth } from '@contexts/AuthContext.jsx';
import Browser from 'webextension-polyfill';
import {
  addLink as dbAddLink,
  getAllLinks,
  deleteLink as dbDeleteLink,
  updateLink as dbUpdateLink,
  patchLinkMetadata as dbPatchLinkMetadata,
} from './db.js';
import {
  addLink as fbAddLink,
  deleteLink as fbDeleteLink,
  updateLink as fbUpdateLink,
  subscribeLinks,
  patchLinkMetadata as fbPatchLinkMetadata,
} from './firebaseDb.js';
import { getCurrentTab, isInternalUrl } from './tabs.js';
import { normalizeUrl } from './normalizeUrl.js';
import { ensureContentScript } from './contentScriptAccess.js';
import { FETCH_METADATA, METADATA_ENRICHED, GET_METADATA } from '../common/actions.js';

export function useLinks() {
  const [links, setLinks] = useState([]);
  const [loading, setLoading] = useState(true);
  const userRef = useRef(null);

  const { user, authReady } = useAuth();

  // Carica da IndexedDB (usato quando non autenticati)
  const loadLocalLinks = useCallback(async () => {
    const all = await getAllLinks();
    setLinks(all);
    setLoading(false);
  }, []);

  useEffect(() => {
    let unsubscribeDb = null;

    console.log('[useLinks] effect — authReady:', authReady, 'uid:', user?.uid ?? 'null');

    if (!authReady) {
      console.log('[useLinks] auth not ready yet — waiting');
      return () => { };
    }

    userRef.current = user;
    setLoading(true);

    if (user) {
      console.log('[useLinks] subscribing to Firebase links — uid:', user.uid);
      unsubscribeDb = subscribeLinks(user.uid, (fbLinks) => {
        console.log('[useLinks] Firebase links updated — count:', fbLinks.length);
        setLinks(fbLinks);
        setLoading(false);
      });
    } else {
      console.log('[useLinks] no user — loading from IndexedDB');
      loadLocalLinks();
    }

    // Listener METADATA_ENRICHED: aggiorna la lista IndexedDB quando il background
    // completa l'arricchimento asincrono. Per Firebase, onSnapshot gestisce già il refresh.
    const handleEnriched = (msg) => {
      if (msg.action === METADATA_ENRICHED && !userRef.current) {
        loadLocalLinks();
      }
    };
    Browser.runtime.onMessage.addListener(handleEnriched);

    return () => {
      if (unsubscribeDb) unsubscribeDb();
      Browser.runtime.onMessage.removeListener(handleEnriched);
    };
  }, [authReady, user, loadLocalLinks]);

  /**
   * Salva la tab corrente direttamente dal popup (senza delegare al background).
   * Recupera i metadata dal content script della tab attiva, poi scrive su Firebase o IndexedDB.
   * L'arricchimento asincrono (thumbnail remota) è delegato al background in fire-and-forget.
   */
  const saveCurrentTab = useCallback(async (collectionId = null) => {
    console.log('[saveCurrentTab] called — uid:', userRef.current?.uid ?? 'null');
    const tab = await getCurrentTab();
    console.log('[saveCurrentTab] tab:', tab);

    if (!tab.url) {
      console.warn('[saveCurrentTab] no url — abort');
      throw new Error('Nessuna pagina attiva da salvare.');
    }
    if (isInternalUrl(tab.url)) {
      console.warn('[saveCurrentTab] internal URL blocked:', tab.url);
      throw new Error('Questa pagina non può essere salvata.');
    }
    if (!tab.id) {
      console.warn('[saveCurrentTab] tab.id is null');
      throw new Error('Impossibile identificare la tab corrente.');
    }

    // Recupera metadata dal content script della tab (best-effort)
    let metadata;
    if (await ensureContentScript(tab)) {
      try {
        metadata = await Browser.tabs.sendMessage(tab.id, { action: GET_METADATA });
        console.log('[saveCurrentTab] metadata from content script:', metadata);
      } catch (err) {
        console.warn('[saveCurrentTab] content script unavailable:', err?.message);
      }
    }

    const entry = {
      url: tab.url,
      title: tab.title || metadata?.siteName || tab.url,
      ...((metadata || collectionId) ? { metadata: { ...(metadata || {}), ...(collectionId ? { collectionId } : {}) } } : {}),
    };

    const normalized = normalizeUrl(entry.url);
    const existingLink = links.find((l) => normalizeUrl(l.url) === normalized);
    if (existingLink) {
      console.log('[saveCurrentTab] duplicate detected:', existingLink.id);
      return { duplicate: true, existingLink };
    }

    const uid = userRef.current?.uid ?? null;
    let savedId;

    if (uid) {
      console.log('[saveCurrentTab] saving to Firebase — uid:', uid);
      const docRef = await fbAddLink(uid, entry);
      savedId = docRef.id;
      console.log('[saveCurrentTab] Firebase save OK — id:', savedId);
      if (!metadata?.thumbnail) {
        Browser.runtime.sendMessage({
          action: FETCH_METADATA,
          payload: { url: entry.url, id: savedId, uid, tabId: tab.id },
        }).catch(() => { });
      }
    } else {
      console.log('[saveCurrentTab] saving to IndexedDB');
      const newId = await dbAddLink(entry);
      savedId = newId;
      console.log('[saveCurrentTab] IndexedDB save OK — id:', savedId);
      await loadLocalLinks();
      if (!metadata?.thumbnail) {
        Browser.runtime.sendMessage({
          action: FETCH_METADATA,
          payload: { url: entry.url, id: savedId, uid: null, tabId: tab.id },
        }).catch(() => { });
      }
    }
    return { duplicate: false, savedId };
  }, [loadLocalLinks, links]);

  /**
   * Salva un link inserito manualmente (URL + titolo opzionale).
   * Non ha accesso al DOM live → il background farà sempre fetch remoto per i metadata.
   */
  const saveCustomLink = useCallback(async ({ url, title, collectionId } = {}) => {
    if (!url) return;
    const entry = { url, title: title || url, ...(collectionId ? { metadata: { collectionId } } : {}) };

    const normalized = normalizeUrl(entry.url);
    const existingLink = links.find((l) => normalizeUrl(l.url) === normalized);
    if (existingLink) {
      console.log('[saveCustomLink] duplicate detected:', existingLink.id);
      return { duplicate: true, existingLink };
    }

    if (userRef.current) {
      try {
        const docRef = await fbAddLink(userRef.current.uid, entry);
        Browser.runtime.sendMessage({
          action: FETCH_METADATA,
          payload: { url, id: docRef.id, uid: userRef.current.uid, tabId: null },
        }).catch(() => { });
        return { duplicate: false, savedId: docRef.id };
      } catch (err) {
        console.error('[useLinks] fbAddLink error (custom)', err);
        throw err;
      }
    } else {
      try {
        const newId = await dbAddLink(entry);
        await loadLocalLinks();
        Browser.runtime.sendMessage({
          action: FETCH_METADATA,
          payload: { url, id: newId, uid: null, tabId: null },
        }).catch(() => { });
        return { duplicate: false, savedId: newId };
      } catch (err) {
        console.error('[useLinks] dbAddLink error (custom)', err);
        throw err;
      }
    }
  }, [loadLocalLinks, links]);

  const deleteLink = useCallback(async (id) => {
    if (userRef.current) {
      await fbDeleteLink(userRef.current.uid, id);
    } else {
      await dbDeleteLink(id);
      await loadLocalLinks();
    }
  }, [loadLocalLinks]);

  const updateLink = useCallback(async (id, updates) => {
    if (userRef.current) {
      await fbUpdateLink(userRef.current.uid, id, updates);
    } else {
      await dbUpdateLink(id, updates);
      await loadLocalLinks();
    }
  }, [loadLocalLinks]);

  return { links, loading, saveCurrentTab, saveCustomLink, deleteLink, updateLink };
}
