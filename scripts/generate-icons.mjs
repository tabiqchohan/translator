import sharp from 'sharp';

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="64" fill="#2563eb"/>
  <circle cx="380" cy="140" r="60" fill="#60a5fa" opacity="0.8"/>
  <text x="256" y="340" font-family="Arial,sans-serif" font-size="220" font-weight="bold" fill="white" text-anchor="middle">T</text>
</svg>`;

await Promise.all([
  sharp(Buffer.from(svg)).resize(192, 192).png().toFile('public/icon-192.png'),
  sharp(Buffer.from(svg)).resize(512, 512).png().toFile('public/icon-512.png'),
]);

console.log('Icons generated!');
