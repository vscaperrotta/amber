import { useState } from 'react';
import PropTypes from 'prop-types';
import Input from '@components/Input';
import Button from '@components/Button';
import GoogleIcon from '@components/GoogleIcon';
import { t } from '@utils/i18n';

function AccountForm(props) {
	const [mode, setMode] = useState('login'); // 'login' | 'register' | 'reset'
	const [username, setUsername] = useState('');
	const [resetSent, setResetSent] = useState(false);

	function switchMode(newMode) {
		setMode(newMode);
		setResetSent(false);
		props.onClearError();
	}

	async function handleSubmit(e) {
		e.preventDefault();
		if (mode === 'login') {
			props.onSignIn(e);
		} else if (mode === 'register') {
			props.onSignUp({ email: props.email, password: props.password, username });
		} else {
			const sent = await props.onForgotPassword(props.email);
			if (sent) setResetSent(true);
		}
	}

	return (
		<div className="options__account-form">
			{mode !== 'reset' && (
				<>
					<button
						className="options__google-btn"
						type="button"
						onClick={props.onGoogleSignIn}
						disabled={props.loading}
					>
						<GoogleIcon size={18} />
						{t('options.googleCta')}
					</button>

					<div className="user-modal__divider">
						<span>{t('options.divider')}</span>
					</div>
				</>
			)}

			<form onSubmit={handleSubmit} className="modal__form">
				{mode === 'register' && (
					<Input
						id="options-username"
						type="text"
						placeholder={t('options.username')}
						value={username}
						onChange={(e) => setUsername(e.target.value)}
						disabled={props.loading}
					/>
				)}
				<Input
					id="options-email"
					type="email"
					placeholder={t('options.email')}
					value={props.email}
					onChange={(e) => props.setEmail(e.target.value)}
					disabled={props.loading}
					required
				/>
				{mode !== 'reset' && (
					<Input
						id="options-password"
						type="password"
						placeholder={t('options.password')}
						value={props.password}
						onChange={(e) => props.setPassword(e.target.value)}
						disabled={props.loading}
						required
					/>
				)}
				{mode === 'reset' && resetSent && (
					<p className="options__account-loading">{t('options.resetLinkSent')}</p>
				)}
				{props.error && <p className="user-modal__error">{props.error}</p>}
				<Button
					text={
						props.loading
							? t('common.loading')
							: mode === 'login'
								? t('options.signIn')
								: mode === 'register'
									? t('options.register')
									: t('options.sendResetLink')
					}
					type="submit"
					variant="primary"
					size="medium"
					disabled={props.loading}
				/>
			</form>

			<div className="options__account-links">
				{mode === 'login' && (
					<>
						<button type="button" className="options__link-btn" onClick={() => switchMode('register')}>
							{t('options.registerTab')}
						</button>
						<button type="button" className="options__link-btn" onClick={() => switchMode('reset')}>
							{t('options.forgotPassword')}
						</button>
					</>
				)}
				{mode !== 'login' && (
					<button type="button" className="options__link-btn" onClick={() => switchMode('login')}>
						{t('options.backToSignIn')}
					</button>
				)}
			</div>
		</div>
	);
}

AccountForm.propTypes = {
	email: PropTypes.string,
	setEmail: PropTypes.func,
	password: PropTypes.string,
	setPassword: PropTypes.func,
	error: PropTypes.string,
	loading: PropTypes.bool,
	onSignIn: PropTypes.func,
	onSignUp: PropTypes.func,
	onGoogleSignIn: PropTypes.func,
	onForgotPassword: PropTypes.func,
	onClearError: PropTypes.func,
};

AccountForm.defaultProps = {
	email: '',
	setEmail: undefined,
	password: '',
	setPassword: undefined,
	error: '',
	loading: false,
	onSignIn: undefined,
	onSignUp: undefined,
	onGoogleSignIn: undefined,
	onForgotPassword: undefined,
	onClearError: () => {},
};

export default AccountForm;
