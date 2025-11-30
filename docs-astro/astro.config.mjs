// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  site: 'https://kairin.github.io',
  base: '/win-qemu-docs/',
  outDir: 'dist',
  vite: {
    plugins: [tailwindcss()]
  }
});
