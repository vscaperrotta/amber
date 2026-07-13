import CollectionBadge from './CollectionBadge.jsx';

export default {
	title: 'Components/CollectionBadge',
	component: CollectionBadge,
};

export const Pill = { args: { name: 'Reading list', color: '#5096F0', variant: 'pill' } };
export const Dot = { args: { name: 'Reading list', color: '#50D282', variant: 'dot' } };
export const Amber = { args: { name: 'Work', color: '#F5A623', variant: 'pill' } };

export const Palette = {
	render: () => (
		<div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
			{['#F5A623', '#5096F0', '#50D282', '#EE5555', '#A78BFA', '#4ECDC4', '#FF8C42', '#F06292'].map((c, i) => (
				<CollectionBadge key={c} name={`Folder ${i + 1}`} color={c} />
			))}
		</div>
	),
};
