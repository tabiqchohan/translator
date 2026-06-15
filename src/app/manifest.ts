import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Translater - Text, Voice & Document Translation',
    short_name: 'Translater',
    description: 'Free AI-powered translator app. Translate text, voice, camera, and documents.',
    start_url: '/',
    scope: '/',
    display: 'standalone',
    background_color: '#ffffff',
    theme_color: '#2563eb',
    orientation: 'portrait',
    categories: ['productivity', 'utilities', 'communication'],
    lang: 'en',
    dir: 'ltr',
    icons: [
      { src: '/icon-192.png', sizes: '192x192', type: 'image/png' },
      { src: '/icon-512.png', sizes: '512x512', type: 'image/png' },
      { src: '/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'maskable' },
      { src: '/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
    ],
    shortcuts: [
      {
        name: 'Text Translation',
        short_name: 'Text',
        description: 'Translate text instantly',
        url: '/?tab=text',
      },
      {
        name: 'Voice Translation',
        short_name: 'Voice',
        description: 'Translate by speaking',
        url: '/?tab=voice',
      },
    ],
  };
}
