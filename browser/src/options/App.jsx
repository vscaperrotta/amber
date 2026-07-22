import { useState, useMemo } from 'react';
import {
	signOut,
	signInWithEmailAndPassword,
	createUserWithEmailAndPassword,
	sendPasswordResetEmail,
	signInWithPopup,
	GoogleAuthProvider,
	updateProfile,
} from '@firebase/auth';
import { Download, ExternalLink } from 'lucide-react';
import { APP_NAME, APP_VERSION, PRIVACY_URL } from '../common/constants.js';
import '@styles/main.scss';
import '@styles/layout/options.scss';
import { useAuth } from '@contexts/AuthContext.jsx';
import { useLinks } from '@utils/useLinks.js';
import { auth } from '../common/firebase.js';
import ConfirmModal from '@components/ConfirmModal';
import { mapFirebaseError } from '@utils/authErrors.js';
import AccountInfo from './components/AccountInfo.jsx';
import AccountForm from './components/AccountForm.jsx';
import { t } from '@utils/i18n';

export default function App() {
	const { user, authReady } = useAuth();
	const { links } = useLinks();
	const [email, setEmail] = useState('');
	const [password, setPassword] = useState('');
	const [error, setError] = useState('');
	const [loading, setLoading] = useState(false);
	const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

	const stats = useMemo(() => ({
		total: links.length,
		favorites: links.filter(l => l.metadata?.isFavorite).length,
	}), [links]);

	async function handleSignIn(e) {
		e.preventDefault();
		setError('');
		setLoading(true);
		try {
			await signInWithEmailAndPassword(auth, email, password);
			setEmail('');
			setPassword('');
		} catch (err) {
			const msg = mapFirebaseError(err.code);
			if (msg) setError(msg);
		} finally {
			setLoading(false);
		}
	}

	async function handleSignUp({ email: signUpEmail, password: signUpPassword, username }) {
		setError('');
		setLoading(true);
		try {
			const credential = await createUserWithEmailAndPassword(auth, signUpEmail, signUpPassword);
			if (username?.trim()) {
				await updateProfile(credential.user, { displayName: username.trim() });
			}
			setEmail('');
			setPassword('');
		} catch (err) {
			const msg = mapFirebaseError(err.code);
			if (msg) setError(msg);
		} finally {
			setLoading(false);
		}
	}

	async function handleForgotPassword(resetEmail) {
		setError('');
		setLoading(true);
		try {
			await sendPasswordResetEmail(auth, resetEmail);
			return true;
		} catch (err) {
			const msg = mapFirebaseError(err.code);
			if (msg) setError(msg);
			return false;
		} finally {
			setLoading(false);
		}
	}

	async function handleGoogleSignIn() {
		setError('');
		setLoading(true);
		try {
			await signInWithPopup(auth, new GoogleAuthProvider());
		} catch (err) {
			const msg = mapFirebaseError(err.code);
			if (msg) setError(msg);
		} finally {
			setLoading(false);
		}
	}

	async function handleSignOut() {
		try {
			await signOut(auth);
		} catch (err) {
			console.error(err);
		} finally {
			setShowLogoutConfirm(false);
		}
	}

	function normalizeSavedAt(savedAt) {
		if (!savedAt) return null;
		if (typeof savedAt === 'string') return savedAt;
		if (typeof savedAt === 'number') return new Date(savedAt).toISOString();
		if (typeof savedAt.toMillis === 'function') return new Date(savedAt.toMillis()).toISOString();
		if (typeof savedAt.seconds === 'number') return new Date(savedAt.seconds * 1000).toISOString();
		return null;
	}

	function handleExport() {
		const now = new Date().toISOString();
		const exportedLinks = links.map(l => ({
			id: l.id,
			url: l.url,
			title: l.title,
			savedAt: normalizeSavedAt(l.savedAt),
			isRead: l.metadata?.isRead ?? true,
			isFavorite: l.metadata?.isFavorite ?? false,
			tags: l.metadata?.tags ?? [],
			description: l.metadata?.description ?? '',
			thumbnail: l.metadata?.thumbnail ?? '',
		}));
		const payload = {
			version: 1,
			app: 'Amber',
			exportedAt: now,
			count: exportedLinks.length,
			links: exportedLinks,
		};
		const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `amber-links-${now.slice(0, 10)}.json`;
		a.click();
		URL.revokeObjectURL(url);
	}

	return (
		<div className="options__container">
			<header className="options__page-header">
				<img src="/icons/icon32.png" alt="" className="options__page-mark" width={24} height={24} />
				<h1 className="options__title">{t('options.title')}</h1>
			</header>

			{/* Account */}
			<section className="options__section">
				<h2 className="options__section-title">{t('options.accountSection')}</h2>
				<hr className="options__section-divider" />
				{!authReady ? (
					<p className="options__account-loading">{t('common.loading')}</p>
				) : user ? (
					<AccountInfo user={user} onSignOutRequest={() => setShowLogoutConfirm(true)} />
				) : (
					<AccountForm
						email={email}
						setEmail={setEmail}
						password={password}
						setPassword={setPassword}
						error={error}
						loading={loading}
						onSignIn={handleSignIn}
						onSignUp={handleSignUp}
						onForgotPassword={handleForgotPassword}
						onGoogleSignIn={handleGoogleSignIn}
						onClearError={() => setError('')}
					/>
				)}
			</section>

			{/* Collection stats */}
			<section className="options__section">
				<div className="options__section-header">
					<h2 className="options__section-title">{t('options.collectionSection')}</h2>
				</div>
				<hr className="options__section-divider" />
				<div className="options__stats-row">
					<div className="options__stat">
						<span className="options__stat-value">{stats.total}</span>
						<span className="options__stat-label">{t('options.statLinks')}</span>
					</div>
					<div className="options__stat">
						<span className="options__stat-value">{stats.favorites}</span>
						<span className="options__stat-label">{t('options.statFavorites')}</span>
					</div>
				</div>
				<div className="options__export-row">
					<div className="options__export-label">
						<span className="options__export-title">{t('options.exportLinks')}</span>
						<span className="options__export-desc">{t('options.exportDesc')}</span>
					</div>
					<button
						type="button"
						className="options__view-btn"
						onClick={handleExport}
						disabled={links.length === 0}
					>
						<Download size={14} />
						{t('options.exportBtn')}
					</button>
				</div>
			</section>

			<ConfirmModal
				isOpen={showLogoutConfirm}
				title={t('options.logoutTitle')}
				message={t('options.logoutMessage')}
				onConfirm={handleSignOut}
				onCancel={() => setShowLogoutConfirm(false)}
			/>

			{/* Privacy Policy */}
			<section className="options__section">
				<h2 className="options__section-title">{t('options.privacySection')}</h2>
				<hr className="options__section-divider" />
				<p className="options__export-desc">{t('options.privacyDesc')}</p>
				<a
					className="options__view-btn"
					href={PRIVACY_URL}
					target="_blank"
					rel="noopener noreferrer"
				>
					{t('options.privacyOpen')}
					<ExternalLink size={14} />
				</a>
			</section>

			<footer className="options__footer">
				<p>{APP_NAME} v{APP_VERSION} — {t('options.footer.caption')}</p>
			</footer>
		</div>
	);
}
