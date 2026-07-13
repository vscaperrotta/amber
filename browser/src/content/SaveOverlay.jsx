import { useState, useEffect, useCallback } from 'react';
import Browser from 'webextension-polyfill';
import {
	SAVE_LINK_LOADING,
	SAVE_LINK_SUCCESS,
	SAVE_LINK_FAILURE,
	SAVE_LINK_DUPLICATE,
	UPDATE_ITEM_PREVIEW,
} from '../common/actions.js';
import { t } from '@utils/i18n';

// Auto-dismiss delay in ms after a successful save
const AUTO_DISMISS_MS = 4000;

// ── Styles ───────────────────────────────────────────────────────────────────
// Inline styles for CSS isolation from host page (all: unset pattern from REFERENCE).

function getTokens() {
	return {
		bg: '#16161E',
		border: '#303048',
		text: '#FFFFFF',
		textSecondary: '#A0A0B4',
		accent: '#F5A623',
		error: '#EE5555',
		shadow: '0 8px 32px rgba(0,0,0,0.7)',
	};
}

// ── Component ────────────────────────────────────────────────────────────────

export function SaveOverlay() {
	const [status, setStatus] = useState('loading'); // 'loading' | 'saved' | 'error' | 'duplicate'
	const [preview, setPreview] = useState(null);    // { title, thumbnail, publisher }
	const [errorMsg, setErrorMsg] = useState('');
	const [visible, setVisible] = useState(true);
	const tokens = getTokens();

	const dismiss = useCallback(() => setVisible(false), []);

	// Message listener (background → overlay)
	useEffect(() => {
		const handleMessage = (msg) => {
			switch (msg.action) {
				case SAVE_LINK_LOADING:
					setStatus('loading');
					setVisible(true);
					break;
				case SAVE_LINK_SUCCESS:
					setStatus('saved');
					if (msg.payload?.preview) setPreview(msg.payload.preview);
					break;
				case SAVE_LINK_FAILURE:
					setStatus('error');
					setErrorMsg(msg.payload?.message || t('overlay.error'));
					break;
				case SAVE_LINK_DUPLICATE:
					setStatus('duplicate');
					break;
				case UPDATE_ITEM_PREVIEW:
					if (msg.payload?.preview) setPreview(msg.payload.preview);
					break;
			}
		};

		Browser.runtime.onMessage.addListener(handleMessage);
		return () => Browser.runtime.onMessage.removeListener(handleMessage);
	}, []);

	// Auto-dismiss on success
	useEffect(() => {
		if (status !== 'saved' && status !== 'duplicate') return;
		const timer = setTimeout(dismiss, AUTO_DISMISS_MS);
		return () => clearTimeout(timer);
	}, [status, dismiss]);

	// Click outside to dismiss
	useEffect(() => {
		const handler = (e) => {
			const root = document.getElementById('amber-overlay-root');
			if (root && !root.contains(e.target)) dismiss();
		};
		document.addEventListener('click', handler, true);
		return () => document.removeEventListener('click', handler, true);
	}, [dismiss]);

	if (!visible) return null;

	return (
		<div style={{
			all: 'initial',
			// ponytail: injected toast — Mulish if the page has it, else system-ui; not worth web_accessible_resources to force-load the ttf in-page
			fontFamily: "'Mulish', system-ui, sans-serif",
			position: 'fixed',
			bottom: '24px',
			right: '24px',
			zIndex: 2147483647,
			width: '300px',
			background: tokens.bg,
			border: `1px solid ${tokens.border}`,
			borderRadius: '12px',
			boxShadow: tokens.shadow,
			overflow: 'hidden',
		}}>
			{/* Header */}
			<div style={{
				display: 'flex',
				alignItems: 'center',
				gap: '8px',
				padding: '12px 16px',
				borderBottom: status === 'saved' && preview ? `1px solid ${tokens.border}` : 'none',
			}}>
				{/* Status icon */}
				<span style={{ fontSize: '16px', lineHeight: 1 }}>
					{status === 'loading' && <LoadingSpinner color={tokens.accent} />}
					{status === 'saved' && <CheckIcon color={tokens.accent} />}
					{status === 'error' && <ErrorIcon color={tokens.error} />}
					{status === 'duplicate' && <CheckIcon color={tokens.textSecondary} />}
				</span>

				<span style={{ fontSize: '14px', fontWeight: 600, color: tokens.text, flex: 1 }}>
					{status === 'loading' && t('overlay.saving')}
					{status === 'saved' && t('overlay.saved')}
					{status === 'error' && t('overlay.error')}
					{status === 'duplicate' && t('overlay.duplicate')}
				</span>

				{/* Close button */}
				<button
					onClick={dismiss}
					style={{
						all: 'unset',
						cursor: 'pointer',
						color: tokens.textSecondary,
						fontSize: '18px',
						lineHeight: 1,
						padding: '2px 4px',
					}}
					aria-label={t('overlay.close')}
				>
					×
				</button>
			</div>

			{/* Preview (shown on success) */}
			{status === 'saved' && preview && (
				<div style={{ display: 'flex', gap: '10px', padding: '12px 16px', alignItems: 'flex-start' }}>
					{/* Thumbnail */}
					{preview.thumbnail && (
						<img
							src={preview.thumbnail}
							alt=""
							style={{
								width: '56px',
								height: '40px',
								objectFit: 'cover',
								borderRadius: '4px',
								flexShrink: 0,
								background: tokens.border,
							}}
							onError={e => { e.target.style.display = 'none'; }}
						/>
					)}
					<div style={{ flex: 1, minWidth: 0 }}>
						{preview.title && (
							<p style={{
								all: 'unset',
								display: '-webkit-box',
								fontSize: '13px',
								fontWeight: 600,
								color: tokens.text,
								lineHeight: 1.4,
								overflow: 'hidden',
								WebkitLineClamp: 2,
								WebkitBoxOrient: 'vertical',
							}}>
								{preview.title}
							</p>
						)}
						{preview.publisher && (
							<p style={{
								all: 'unset',
								display: 'block',
								fontSize: '11px',
								color: tokens.textSecondary,
								marginTop: '2px',
							}}>
								{preview.publisher}
							</p>
						)}
					</div>
				</div>
			)}

			{/* Error message */}
			{status === 'error' && errorMsg && (
				<p style={{
					all: 'unset',
					display: 'block',
					fontSize: '12px',
					color: tokens.error,
					padding: '0 16px 12px',
				}}>
					{errorMsg}
				</p>
			)}
		</div>
	);
}

// ── Icon components ───────────────────────────────────────────────────────────

function LoadingSpinner({ color }) {
	return (
		<svg width="16" height="16" viewBox="0 0 16 16" style={{ animation: 'amber-spin 0.8s linear infinite' }}>
			<style>{`@keyframes amber-spin { to { transform: rotate(360deg); } }`}</style>
			<circle cx="8" cy="8" r="6" fill="none" stroke={color} strokeWidth="2" strokeDasharray="28 10" />
		</svg>
	);
}

function CheckIcon({ color }) {
	return (
		<svg width="16" height="16" viewBox="0 0 16 16" fill="none">
			<circle cx="8" cy="8" r="7" fill={color} />
			<path d="M5 8l2 2 4-4" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
		</svg>
	);
}

function ErrorIcon({ color }) {
	return (
		<svg width="16" height="16" viewBox="0 0 16 16" fill="none">
			<circle cx="8" cy="8" r="7" fill={color} />
			<path d="M8 5v3M8 11v.5" stroke="white" strokeWidth="1.5" strokeLinecap="round" />
		</svg>
	);
}
