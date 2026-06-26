import sharp from 'sharp';

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 500">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#2563eb"/>
      <stop offset="100%" stop-color="#4f46e5"/>
    </linearGradient>
  </defs>
  <rect width="1024" height="500" fill="url(#bg)"/>
  <circle cx="800" cy="120" r="140" fill="#60a5fa" opacity="0.15"/>
  <circle cx="200" cy="400" r="100" fill="#818cf8" opacity="0.12"/>
  <text x="300" y="230" font-family="Arial,sans-serif" font-size="100" font-weight="bold" fill="white" text-anchor="middle">Translater</text>
  <text x="300" y="290" font-family="Arial,sans-serif" font-size="32" fill="#bfdbfe" text-anchor="middle">AI-Powered Translation</text>
  <text x="700" y="360" font-family="Arial,sans-serif" font-size="24" fill="#c7d2fe" text-anchor="middle">Text · Voice · Camera · Documents</text>
  <rect x="635" y="380" width="130" height="4" rx="2" fill="#818cf8"/>
</svg>`;

await sharp(Buffer.from(svg)).resize(1024, 500).png().toFile('public/feature-graphic.png');

console.log('Feature graphic generated!');
