import Browser from 'webextension-polyfill';
import { createRoot } from 'react-dom/client';
import { extractMetadata } from '../utils/extractMetadata.js';
import { extractBodyText } from '../utils/extractBodyText.js';
import { SAVE_LINK_LOADING, GET_METADATA, CONTENT_SCRIPT_PING } from '../common/actions.js';
import { SaveOverlay } from './SaveOverlay.jsx';

function handleMessage(msg) {
	console.log('[content] message received:', msg.action, msg.payload);

	if (msg.action === CONTENT_SCRIPT_PING) {
		return Promise.resolve({ ok: true });
	}

	// Risponde con i metadata estratti dal DOM live
	if (msg.action === GET_METADATA) {
		const bodyText = extractBodyText(document);
		const metadata = extractMetadata(document, location.href, bodyText);
		console.log('[content] GET_METADATA — extracted:', JSON.stringify(metadata, null, 2));
		return Promise.resolve(metadata);
	}

	// Inietta l'overlay nella pagina al segnale di salvataggio
	if (msg.action === SAVE_LINK_LOADING) {
		console.log('[content] SAVE_LINK_LOADING — injecting overlay');
		injectSaveOverlay();
		return false;
	}

	console.warn('[content] unhandled message action:', msg.action);
	return false;
}

if (!globalThis.__AMBER_CONTENT_SCRIPT_READY__) {
	globalThis.__AMBER_CONTENT_SCRIPT_READY__ = true;
	console.log('[content] script loaded — url:', location.href);
	Browser.runtime.onMessage.addListener(handleMessage);
} else {
	console.log('[content] script already active — url:', location.href);
}

function injectSaveOverlay() {
	if (document.getElementById('amber-overlay-root')) {
		console.log('[content] overlay already present — skip');
		return;
	}
	console.log('[content] creating overlay root');
	const container = document.createElement('div');
	container.id = 'amber-overlay-root';
	document.body.appendChild(container);
	createRoot(container).render(<SaveOverlay />);
}
