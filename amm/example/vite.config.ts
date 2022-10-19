import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: process.env['VITE_DEV_HOST'],
  },
  build: {
    target: 'ES2020',
  },
})
