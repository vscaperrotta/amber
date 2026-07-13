import { useState } from 'react';
import PropTypes from 'prop-types';
import './LinkThumbnail.scss';
import { extractDomain } from '@utils/domain';

// Deterministic hue from a string so every domain gets a stable fallback color.
function hueFromString(str) {
	let hash = 0;
	for (let i = 0; i < str.length; i += 1) {
		hash = (hash * 31 + str.charCodeAt(i)) % 360;
	}
	return hash;
}

export default function LinkThumbnail(props) {
	const [imgFailed, setImgFailed] = useState(false);

	const meta = props.link.metadata || {};
	const preview = meta.thumbnail || meta.screenshot;
	const domain = extractDomain(props.link.url);
	const monogram = (props.link.title || domain || '?').trim().charAt(0).toUpperCase();
	const hue = hueFromString(domain || props.link.url || monogram);

	const className = `link-thumb link-thumb--${props.size}${props.className ? ` ${props.className}` : ''}`;

	if (preview && !imgFailed) {
		return (
			<div className={className}>
				<img
					className="link-thumb__img"
					src={preview}
					alt=""
					loading="lazy"
					onError={() => setImgFailed(true)}
				/>
				{meta.favicon ? (
					<img
						className="link-thumb__favicon"
						src={meta.favicon}
						alt=""
						width={14}
						height={14}
						onError={(e) => { e.target.style.display = 'none'; }}
					/>
				) : null}
			</div>
		);
	}

	// Fallback: colored monogram block seeded by domain, with favicon if available.
	return (
		<div
			className={`${className} link-thumb--fallback`}
			style={{
				'--thumb-hue': hue,
			}}
			aria-hidden="true"
		>
			{meta.favicon && !imgFailed ? (
				<img
					className="link-thumb__fallback-favicon"
					src={meta.favicon}
					alt=""
					width={props.size === 'sm' ? 16 : 22}
					height={props.size === 'sm' ? 16 : 22}
					onError={() => setImgFailed(true)}
				/>
			) : (
				<span className="link-thumb__monogram">{monogram}</span>
			)}
		</div>
	);
}

LinkThumbnail.propTypes = {
	link: PropTypes.object.isRequired,
	size: PropTypes.oneOf(['sm', 'md', 'lg']),
	className: PropTypes.string,
};

LinkThumbnail.defaultProps = {
	size: 'md',
	className: '',
};
