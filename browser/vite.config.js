import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import paths from './config/paths';

const APP_DIR = paths.appSrc;

export default defineConfig({
  plugins: [
    react(),
  ],
  resolve: {
    alias: {
      '@': `${APP_DIR}`,
      '@background': `${APP_DIR}/background`,
      '@components': `${APP_DIR}/components`,
      '@contexts': `${APP_DIR}/contexts`,
      '@options': `${APP_DIR}/options`,
      '@popup': `${APP_DIR}/popup`,
      '@newtab': `${APP_DIR}/newtab`,
      '@styles': `${APP_DIR}/styles`,
      '@utils': `${APP_DIR}/utils`,
    },
  },
  build: {
    rollupOptions: {
      input: {
        background: path.resolve(APP_DIR, 'background', 'index.js'),
        content: path.resolve(APP_DIR, 'content', 'index.jsx'),
        // newtab removed from build — source kept only for shared components (TagEditor, UserModal)
        // newtab: path.resolve(APP_DIR, 'newtab', 'index.html'),
        options: path.resolve(APP_DIR, 'options', 'index.html'),
        popup: path.resolve(APP_DIR, 'popup', 'index.html'),
        sidepanel: path.resolve(APP_DIR, 'sidepanel', 'index.html'),
      },
      output: {
        entryFileNames: 'assets/[name].js',
        chunkFileNames: 'assets/[name].js',
        assetFileNames: 'assets/[name].[ext]'
      }
    }
  }
})
