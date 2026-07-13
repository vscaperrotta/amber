import { useState, useEffect } from 'react';
import { useAuth } from '@contexts/AuthContext.jsx';
import { subscribeUserSettings, updateUserSettings } from './userSettings.js';

export function useUserSettings() {
	const { user, authReady } = useAuth();
	const [settings, setSettings] = useState({ defaultViewMode: 'grid', headerLinks: [], showDescription: true });
	const [loading, setLoading] = useState(true);

	useEffect(() => {
		if (!authReady) return;
		if (!user) {
			setSettings({ defaultViewMode: 'grid', headerLinks: [], showDescription: true });
			setLoading(false);
			return;
		}
		setLoading(true);
		const unsub = subscribeUserSettings(user.uid, (s) => {
			setSettings(s);
			setLoading(false);
		});
		return unsub;
	}, [user, authReady]);

	function updateSettings(partial) {
		if (!user) return;
		return updateUserSettings(user.uid, partial);
	}

	return { settings, loading, updateSettings };
}
