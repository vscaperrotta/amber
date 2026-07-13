import LinkThumbnail from './LinkThumbnail.jsx';

export default {
	title: 'Components/LinkThumbnail',
	component: LinkThumbnail,
};

const withPreview = {
	url: 'https://stripe.com',
	title: 'Stripe',
	metadata: {
		thumbnail: 'https://picsum.photos/seed/stripe/320/180',
		favicon: 'https://www.google.com/s2/favicons?domain=stripe.com&sz=32',
	},
};

const faviconOnly = {
	url: 'https://linear.app',
	title: 'Linear',
	metadata: {
		favicon: 'https://www.google.com/s2/favicons?domain=linear.app&sz=32',
	},
};

const bare = {
	url: 'https://example.org/some/deep/page',
	title: 'Example article',
	metadata: {},
};

export const WithPreview = { args: { link: withPreview, size: 'md' } };
export const FaviconFallback = { args: { link: faviconOnly, size: 'md' } };
export const MonogramFallback = { args: { link: bare, size: 'md' } };
export const Small = { args: { link: withPreview, size: 'sm' } };
export const Large = {
	args: { link: withPreview, size: 'lg' },
	decorators: [(Story) => <div style={{ width: 260 }}><Story /></div>],
};
