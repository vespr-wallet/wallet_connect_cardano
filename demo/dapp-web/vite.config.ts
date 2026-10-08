import { defineConfig } from 'vite';
import wasm from 'vite-plugin-wasm';

export default defineConfig({
  // CSL's browser build imports its .wasm as an ES module (top-level await).
  plugins: [wasm()],
  build: { target: 'esnext' },
  server: {
    port: 5173,
    host: true,
  },
});
