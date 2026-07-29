import { ItemView, WorkspaceLeaf, Notice } from 'obsidian';
import { signOut } from '@firebase/auth';
import { VIEW_TYPE, NAME, PLUGIN_ICON } from '../constants';
import MainPlugin from '../main';
import { auth } from '../firebase';
import { t } from '../utils/i18n';
import { LinksService } from '../utils/linksService';
import { AuthModal } from '../components/authModal';
import { AddLinkModal } from '../components/addLinkModal';
import { EditLinkModal } from '../components/editLinkModal';
import renderHeader from '../components/header';
import renderLinksTabBar, { TabId } from '../components/linksTabBar';
import renderLinksList from '../components/linksList';
import renderLinksGrid from '../components/linksGrid';
import renderLinksFavorites from '../components/linksFavorites';
import { LinksTagView } from '../components/linksTagView';

export default class PluginView extends ItemView {
  plugin: MainPlugin;
  linksService: LinksService | null = null;
  private activeTab: TabId = 'grid';
  private tabContentEl: HTMLElement | null = null;
  private headerDestroy: (() => void) | null = null;
  private linksTagView: LinksTagView | null = null;

  constructor(leaf: WorkspaceLeaf, plugin: MainPlugin) {
    super(leaf);
    this.plugin = plugin;
  }

  getViewType() {
    return VIEW_TYPE;
  }

  getDisplayText() {
    return NAME;
  }

  getIcon(): string {
    return PLUGIN_ICON;
  }

  async onOpen() {
    this.linksService = new LinksService(this.plugin.app, this.plugin, () => this.renderTabContent());
    this.render();
  }

  async onClose() {
    this.linksService?.destroy();
    this.linksService = null;
    this.headerDestroy?.();
    this.headerDestroy = null;
    this.linksTagView?.destroy();
    this.linksTagView = null;
  }

  private render() {
    const container = this.containerEl.children[1] as HTMLElement;
    container.empty();

    // Header
    const { destroy } = renderHeader(
      container,
      () => new AuthModal(this.app).open(),
      () => signOut(auth).catch(console.error),
      () => {
        new AddLinkModal(this.app, async (url, title, metadata) => {
          try {
            await this.linksService?.addLink(url, title, metadata) ?? null;
            new Notice(t('view.linkAdded'));
          } catch (err) {
            new Notice(t('view.errorAddLink'));
            console.error(err);
          }
        }).open();
      }
    );
    this.headerDestroy = destroy;

    // Tab bar
    renderLinksTabBar(container, this.activeTab, (tab) => {
      if (tab !== 'tags') {
        this.linksTagView?.destroy();
        this.linksTagView = null;
      }
      this.activeTab = tab;
      this.renderTabContent();
    });

    // Tab content container
    this.tabContentEl = container.createDiv({ cls: 'obs-amber-tab-content' });
    this.renderTabContent();
  }

  private renderTabContent() {
    if (!this.tabContentEl) return;

    const links = this.linksService?.links ?? [];
    const loading = this.linksService?.loading ?? true;
    const allTags = [...new Set(links.flatMap((l) => l.metadata?.tags ?? []))].sort();

    const onDelete = (id: string) => this.linksService?.deleteLink(id) ?? Promise.resolve();

    const onEdit = (id: string) => {
      const link = links.find((l) => l.id === id);
      if (!link) return;
      new EditLinkModal(this.app, link, async (linkId, updates) => {
        await this.linksService?.updateLink(linkId, updates);
      }).open();
    };

    const onAddTag = async (id: string, tag: string) => {
      const link = links.find((l) => l.id === id);
      if (!link) return;
      const existing = link.metadata?.tags ?? [];
      if (existing.includes(tag) || existing.length >= 10) return;
      // COMMENTED: Auto-save disabled temporarily
      // await this.linksService?.updateLink(id, {
      //   metadata: { ...link.metadata, tags: [...existing, tag] },
      // });
    };

    const onDeleteTag = async (id: string, tag: string) => {
      const link = links.find((l) => l.id === id);
      if (!link) return;
      const updated = (link.metadata?.tags ?? []).filter((t) => t !== tag);
      // COMMENTED: Auto-save disabled temporarily
      // await this.linksService?.updateLink(id, {
      //   metadata: { ...link.metadata, tags: updated },
      // });
    };

    const onToggleFavorite = async (id: string) => {
      await this.linksService?.toggleFavorite(id);
    };

    const onToggleRead = async (id: string) => {
      await this.linksService?.toggleRead(id);
    };

    const onGlobalRenameTag = async (oldTag: string, newTag: string) => {
      // COMMENTED: Auto-save disabled temporarily
      // await this.linksService?.renameTag(oldTag, newTag);
    };

    const onGlobalDeleteTag = async (tag: string) => {
      // COMMENTED: Auto-save disabled temporarily
      // await this.linksService?.deleteTag(tag);
    };

    const onGlobalMergeTag = async (fromTag: string, toTag: string) => {
      // COMMENTED: Auto-save disabled temporarily
      // await this.linksService?.mergeTag(fromTag, toTag);
    };

    switch (this.activeTab) {
      case 'grid':
        renderLinksGrid(this.tabContentEl, links, loading, allTags, onDelete, onAddTag, onDeleteTag, onEdit, onToggleFavorite, onToggleRead);
        break;
      case 'list':
        renderLinksList(this.tabContentEl, links, loading, allTags, onDelete, onAddTag, onDeleteTag, onEdit, onToggleFavorite, onToggleRead);
        break;
      case 'tags':
        if (!this.linksTagView) {
          this.linksTagView = new LinksTagView(this.tabContentEl);
        }
        this.linksTagView.render(links, allTags, onDelete, onAddTag, onDeleteTag, onEdit, onGlobalRenameTag, onGlobalDeleteTag, onGlobalMergeTag);
        break;
      case 'favorites':
        renderLinksFavorites(this.tabContentEl, links, loading, allTags, onDelete, onAddTag, onDeleteTag, onEdit, onToggleFavorite, onToggleRead);
        break;
    }
  }
}
