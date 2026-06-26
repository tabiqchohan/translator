import sharp from 'sharp';

const SCREENS = [
  {
    name: 'translate',
    title: 'Translation',
    bg: '#2563eb',
    accent: '#3b82f6',
    lines: [
      'Hello, how are you?',
      'السلام علیکم',
      '',
      'Selected: English → Urdu',
      'Characters: 0',
    ],
  },
  {
    name: 'voice',
    title: 'Voice Translation',
    bg: '#7c3aed',
    accent: '#8b5cf6',
    lines: [
      'Tap to speak',
      '',
      '🎤 Listening...',
    ],
  },
  {
    name: 'history',
    title: 'Translation History',
    bg: '#059669',
    accent: '#10b981',
    lines: [
      'Good morning → صبح بخیر',
      'Thank you → شکریہ',
      'How much? → کتنا؟',
    ],
  },
  {
    name: 'settings',
    title: 'Settings',
    bg: '#d97706',
    accent: '#f59e0b',
    lines: [
      'Dark Mode',
      'Default Language',
      'TTS Speed',
      'Clear History',
    ],
  },
];

function phoneSvg({ title, bg, accent, lines }) {
  const content = lines.map((l, i) => {
    if (l === '') return '';
    const isHeading = i === 0;
    return `<text x="54" y="${180 + i * 56}" font-family="Arial,sans-serif" font-size="${isHeading ? 28 : 20}" font-weight="${isHeading ? 'bold' : 'normal'}" fill="${isHeading ? '#1e293b' : '#64748b'}">${l}</text>`;
  }).join('\n');

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1080 1920">
  <rect width="1080" height="1920" fill="#f8fafc"/>
  <!-- Status bar -->
  <rect width="1080" height="80" fill="white"/>
  <text x="50" y="50" font-family="Arial,sans-serif" font-size="28" font-weight="bold" fill="#1e293b">9:41</text>
  <circle cx="980" cy="40" r="20" fill="#e2e8f0"/>
  <rect x="1000" y="30" width="40" height="20" rx="10" fill="#e2e8f0"/>
  <!-- Header bar -->
  <rect y="80" width="1080" height="120" fill="${bg}"/>
  <text x="540" y="152" font-family="Arial,sans-serif" font-size="40" font-weight="bold" fill="white" text-anchor="middle">${title}</text>
  <!-- Content area -->
  <rect x="30" y="240" width="1020" height="800" rx="20" fill="white" stroke="#e2e8f0" stroke-width="2"/>
  <text x="80" y="310" font-family="Arial,sans-serif" font-size="32" font-weight="bold" fill="${accent}">Translater</text>
  <rect x="80" y="340" width="460" height="2" rx="1" fill="${accent}" opacity="0.3"/>
  ${content}
  <!-- Bottom nav -->
  <rect y="1620" width="1080" height="90" fill="white" stroke="#e2e8f0" stroke-width="1"/>
  <text x="180" y="1670" font-family="Arial,sans-serif" font-size="22" fill="${bg}" text-anchor="middle" font-weight="bold">Translate</text>
  <text x="380" y="1670" font-family="Arial,sans-serif" font-size="22" fill="#94a3b8" text-anchor="middle">History</text>
  <text x="580" y="1670" font-family="Arial,sans-serif" font-size="22" fill="#94a3b8" text-anchor="middle">Favorites</text>
  <text x="780" y="1670" font-family="Arial,sans-serif" font-size="22" fill="#94a3b8" text-anchor="middle">Settings</text>
</svg>`;
}

function tabletSvg({ title, bg, accent, lines }) {
  const content = lines.map((l, i) => {
    if (l === '') return '';
    const isHeading = i === 0;
    return `<text x="60" y="${200 + i * 50}" font-family="Arial,sans-serif" font-size="${isHeading ? 26 : 18}" font-weight="${isHeading ? 'bold' : 'normal'}" fill="${isHeading ? '#1e293b' : '#64748b'}">${l}</text>`;
  }).join('\n');

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2048 1366">
  <rect width="2048" height="1366" fill="#f8fafc"/>
  <!-- Status bar -->
  <rect width="2048" height="60" fill="white"/>
  <text x="50" y="40" font-family="Arial,sans-serif" font-size="22" font-weight="bold" fill="#1e293b">9:41</text>
  <!-- Header bar -->
  <rect y="60" width="2048" height="90" fill="${bg}"/>
  <text x="1024" y="112" font-family="Arial,sans-serif" font-size="34" font-weight="bold" fill="white" text-anchor="middle">${title}</text>
  <!-- Content area -->
  <rect x="40" y="180" width="1968" height="800" rx="16" fill="white" stroke="#e2e8f0" stroke-width="2"/>
  <text x="80" y="260" font-family="Arial,sans-serif" font-size="28" font-weight="bold" fill="${accent}">Translater</text>
  <rect x="80" y="280" width="300" height="2" rx="1" fill="${accent}" opacity="0.3"/>
  ${content}
  <!-- Bottom nav -->
  <rect y="1250" width="2048" height="70" fill="white" stroke="#e2e8f0" stroke-width="1"/>
  <text x="350" y="1290" font-family="Arial,sans-serif" font-size="20" fill="${bg}" text-anchor="middle" font-weight="bold">Translate</text>
  <text x="750" y="1290" font-family="Arial,sans-serif" font-size="20" fill="#94a3b8" text-anchor="middle">History</text>
  <text x="1150" y="1290" font-family="Arial,sans-serif" font-size="20" fill="#94a3b8" text-anchor="middle">Favorites</text>
  <text x="1550" y="1290" font-family="Arial,sans-serif" font-size="20" fill="#94a3b8" text-anchor="middle">Settings</text>
</svg>`;
}

async function main() {
  // Phone screenshots (1080×1920)
  for (const screen of SCREENS) {
    await sharp(Buffer.from(phoneSvg(screen)))
      .png()
      .toFile(`public/screenshot-phone-${screen.name}.png`);
    console.log(`Created phone screenshot: ${screen.name}`);
  }

  // Tablet screenshots (2048×1366) - first 3 screens
  const tabletScreens = SCREENS.slice(0, 3);
  for (const screen of tabletScreens) {
    await sharp(Buffer.from(tabletSvg(screen)))
      .png()
      .toFile(`public/screenshot-tablet-${screen.name}.png`);
    console.log(`Created tablet screenshot: ${screen.name}`);
  }

  console.log('\nAll screenshots generated in public/ folder!');
}

main();
