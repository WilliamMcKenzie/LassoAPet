// Recover transparent native Studio renders from aligned white/black captures.
// Usage: node export-cutouts.cjs <capture-directory> (requires sharp).
// No image generation or repainting: solve C = alpha * F + (1-alpha) * B.
const sharp = require('sharp');
const path = require('node:path');

async function cutout(directory, name) {
  const read = file => sharp(file).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const [white, black] = await Promise.all([
    read(path.join(directory, `${name}-white.jpg`)),
    read(path.join(directory, `${name}-black.jpg`)),
  ]);
  const { width, height } = white.info;
  if (width !== black.info.width || height !== black.info.height) throw Error('Capture sizes differ');
  const pixels = width * height;
  const rgba = Buffer.alloc(pixels * 4);
  const median = values => values.sort((a, b) => a - b)[1];
  const whiteBG = [...white.data.subarray(0, 3)];
  const blackBG = [...black.data.subarray(0, 3)];
  for (let i = 0; i < pixels; i++) {
    let alpha = 1 - median([0, 1, 2].map(c =>
      (white.data[i * 3 + c] - black.data[i * 3 + c]) / (whiteBG[c] - blackBG[c])));
    alpha = Math.max(0, Math.min(1, alpha));
    if (alpha < 0.035) continue; // JPEG compression noise on the plain background
    if (alpha > 0.985) alpha = 1;
    rgba[i * 4 + 3] = Math.round(alpha * 255);
    for (let c = 0; c < 3; c++) {
      const foreground = (white.data[i * 3 + c] + black.data[i * 3 + c]
        - (whiteBG[c] + blackBG[c]) * (1 - alpha)) / (2 * alpha);
      rgba[i * 4 + c] = Math.max(0, Math.min(255, Math.round(foreground)));
    }
  }
  // Discard isolated compression flecks; preserve every meaningful silhouette.
  const visited = new Uint8Array(pixels);
  for (let i = 0; i < pixels; i++) {
    if (visited[i] || !rgba[i * 4 + 3]) continue;
    const component = [i];
    visited[i] = 1;
    for (let at = 0; at < component.length; at++) {
      const p = component[at], x = p % width, y = Math.floor(p / width);
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const nx = x + dx, ny = y + dy, next = ny * width + nx;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height || visited[next] || !rgba[next * 4 + 3]) continue;
        visited[next] = 1;
        component.push(next);
      }
    }
    if (component.length < 12) for (const p of component) rgba.fill(0, p * 4, p * 4 + 4);
  }
  let left = width, top = height, right = 0, bottom = 0;
  for (let i = 0; i < pixels; i++) if (rgba[i * 4 + 3]) {
    left = Math.min(left, i % width); right = Math.max(right, i % width);
    top = Math.min(top, Math.floor(i / width)); bottom = Math.max(bottom, Math.floor(i / width));
  }
  if (left > right) throw Error(`Empty alpha matte for ${name}`);
  left = Math.max(0, left - 32); top = Math.max(0, top - 32);
  right = Math.min(width - 1, right + 32); bottom = Math.min(height - 1, bottom + 32);
  const output = path.join(directory, `${name}-transparent.png`);
  await sharp(rgba, { raw: { width, height, channels: 4 } })
    .extract({ left, top, width: right - left + 1, height: bottom - top + 1 }).png().toFile(output);
  console.log(`${name}: ${right - left + 1} x ${bottom - top + 1}, RGBA`);
}

async function main() {
  const directory = process.argv[2];
  if (!directory) throw Error('Provide the capture directory');
  for (const mount of ['horse', 'cactus']) for (const face of ['smug', 'grin', 'reference']) {
    await cutout(directory, `${mount}-${face}`);
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
