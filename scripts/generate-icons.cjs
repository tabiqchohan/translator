const sharp = require('sharp');
const fs = require('fs');

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="64" fill="#2563eb"/>
  <text x="256" y="340" font-family="Arial,sans-serif" font-size="220" font-weight="bold" fill="white" text-anchor="middle">T</text>
</svg>`;

sharp(Buffer.from(svg)).resize(192, 192).png().toFile('public/icon-192.png')
  .then(() => console.log('icon-192.png generated'))
  .catch(e => console.log('192 error:', e.message));

sharp(Buffer.from(svg)).resize(512, 512).png().toFile('public/icon-512.png')
  .then(() => console.log('icon-512.png generated'))
  .catch(e => console.log('512 error:', e.message));
