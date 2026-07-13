import PropTypes from 'prop-types';
import './CollectionBadge.scss';

// Small colored indicator that identifies which collection a link belongs to.
// `dot` renders just the color chip; otherwise a chip + name pill tinted by color.
export default function CollectionBadge(props) {
	const color = props.color || 'var(--text-tertiary)';

	if (props.variant === 'dot') {
		return (
			<span
				className="collection-badge collection-badge--dot"
				style={{ '--badge-color': color }}
				title={props.name}
				aria-label={props.name}
			/>
		);
	}

	return (
		<span
			className="collection-badge collection-badge--pill"
			style={{ '--badge-color': color }}
		>
			<span className="collection-badge__dot" aria-hidden="true" />
			<span className="collection-badge__name">{props.name}</span>
		</span>
	);
}

CollectionBadge.propTypes = {
	name: PropTypes.string.isRequired,
	color: PropTypes.string,
	variant: PropTypes.oneOf(['dot', 'pill']),
};

CollectionBadge.defaultProps = {
	color: '',
	variant: 'pill',
};
