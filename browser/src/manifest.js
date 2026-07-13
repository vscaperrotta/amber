import fs from 'fs-extra';
import path from 'path';

export async function getManifest() {
  const pkg = await fs.readJSON(path.resolve('package.json'));

  const manifest = {
    manifest_version: 3,
    name: pkg.displayName || pkg.name,
    version: pkg.version,
    description: pkg.description,
    action: {
      default_popup: "src/popup/index.html",
      default_icon: {
        16: "icons/icon16.png",
        32: "icons/icon32.png",
        48: "icons/icon48.png",
        128: "icons/icon128.png"
      }
    },
    icons: {
      16: "icons/icon16.png",
      32: "icons/icon32.png",
      48: "icons/icon48.png",
      128: "icons/icon128.png"
    },
    permissions: [
      'storage',
      'tabs',
      'activeTab',
      'cookies',
      'sidePanel',
    ],
    side_panel: {
      default_path: 'src/sidepanel/index.html',
    },
    host_permissions: [
      "<all_urls>"
    ],
    background: {
      "service_worker": "assets/background.js",
      "type": "module"
    },
    content_scripts: [
      {
        matches: [
          "<all_urls>"
        ],
        match_origin_as_fallback: true,
        run_at: 'document_idle',
        js: ['assets/content.js'],
        type: 'module',
      }
    ],
    // newtab override removed — new tab reverts to browser default
    // chrome_url_overrides: {
    //   newtab: 'src/newtab/index.html'
    // },
    options_ui: {
      page: "src/options/index.html",
      open_in_tab: true
    },
    content_security_policy: {
      extension_pages: [
        "script-src 'self'",
        "object-src 'self'",
        "connect-src https: wss: http://localhost:*",
      ].join('; ')
    },
    commands: {
      "save-current-tab": {
        suggested_key: {
          default: "Ctrl+Shift+S",
          mac: "Command+Shift+S"
        },
        description: "Save the current tab to Amber"
      }
    }
  }

  return manifest
}
