import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  base: '',
  plugins: [react()],
  server: {
    host: process.env['DEV_HOST'],
  },
  build: {
    target: 'ES2020',
    rollupOptions: {
      output: {
        manualChunks: {
          mui: ['@mui/material'],
          sui: ['@mysten/sui.js'],
        },
      },
    },
  },
})
