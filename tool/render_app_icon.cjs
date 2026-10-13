// Install the renderer in the ignored tooling directory before running:
// npm install --prefix .dart_tool/icon_renderer --no-save --package-lock=false @resvg/resvg-js@2.6.2
const fs = require('node:fs');
const path = require('node:path');
const { Resvg } = require('../.dart_tool/icon_renderer/node_modules/@resvg/resvg-js');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'assets/icons/algolens.svg'), 'utf8');
// Add 15% of the SVG's dimensions on every side without changing the source logo.
const svg = source.replace(/viewBox="([^"]+)"/, (_, viewBox) => {
  const [x, y, width, height] = viewBox.trim().split(/[\s,]+/).map(Number);
  const paddingX = width * 0.15;
  const paddingY = height * 0.15;
  return `viewBox="${x - paddingX} ${y - paddingY} ${width + 2 * paddingX} ${height + 2 * paddingY}"`;
});

for (const [filename, background] of [
  ['algolens_launcher.png', '#0F172A'],
  ['algolens_foreground.png', undefined],
]) {
  const renderer = new Resvg(svg, {
    fitTo: { mode: 'width', value: 1024 },
    ...(background ? { background } : {}),
  });
  const output = path.join(root, 'assets/icons', filename);
  fs.writeFileSync(output, renderer.render().asPng());
  console.log(`Rendered ${filename}`);
}
