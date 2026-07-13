import { doc, setDoc, onSnapshot } from 'firebase/firestore';
import { db } from '../common/firebase.js';

const DEFAULT_SETTINGS = { defaultViewMode: 'grid', headerLinks: [], popupTagMode: 'off', showDescription: true };

export function updateUserSettings(uid, settings) {
	return setDoc(doc(db, 'users', uid, 'settings', 'preferences'), settings, { merge: true });
}

export function subscribeUserSettings(uid, callback) {
	return onSnapshot(
		doc(db, 'users', uid, 'settings', 'preferences'),
		(snap) =>
			callback(snap.exists() ? { ...DEFAULT_SETTINGS, ...snap.data() } : DEFAULT_SETTINGS),
		(error) => {
			console.error('[userSettings]', error);
			callback(DEFAULT_SETTINGS);
		},
	);
}
