import Browser from 'webextension-polyfill';
import { CONTENT_SCRIPT_PING } from '../common/actions.js';

const SCRIPTABLE_PROTOCOLS = new Set(['http:', 'https:']);
const CONTENT_SCRIPT_PATH = 'assets/content.js';

export function canInjectContentScript(tab) {
	if (!tab?.id || !tab.url) return false;
	try {
		return SCRIPTABLE_PROTOCOLS.has(new URL(tab.url).protocol);
	} catch {
		return false;
	}
}

async function isContentScriptReady(tabId) {
	try {
		const response = await Browser.tabs.sendMessage(tabId, { action: CONTENT_SCRIPT_PING });
		return response?.ok === true;
	} catch {
		return false;
	}
}

async function injectContentScript(tabId) {
	const sourceUrl = Browser.runtime.getURL(CONTENT_SCRIPT_PATH);
	const scripting = Browser.scripting ?? globalThis.chrome?.scripting;
	if (!scripting?.executeScript) return false;

	await scripting.executeScript({
		target: { tabId },
		func: async (src) => {
			if (globalThis.__AMBER_CONTENT_SCRIPT_READY__) return true;
			await import(src);
			return true;
		},
		args: [sourceUrl],
	});
	return true;
}

export async function ensureContentScript(tab) {
	if (!canInjectContentScript(tab)) return false;
	if (await isContentScriptReady(tab.id)) return true;
	try {
		await injectContentScript(tab.id);
		return isContentScriptReady(tab.id);
	} catch (err) {
		console.warn('[contentScriptAccess] injection failed:', err?.message);
		return false;
	}
}
