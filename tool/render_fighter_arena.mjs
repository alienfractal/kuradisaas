// node tool/render_fighter_arena.mjs <path-to-pele-1.6.0-module>
// Reads canonical Mermaid documentation; emits a self-contained offline page.
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const { render } = await import(process.argv[2]
  ? pathToFileURL(resolve(process.argv[2])).href : 'pele');
const base = new URL('../', import.meta.url);
const markdown = await readFile(new URL('docs/fighter-arena-uml.md', base), 'utf8');
const sources = [...markdown.matchAll(/```mermaid\r?\n([\s\S]*?)```/g)].map(m => m[1].trim());
if (sources.length !== 3) throw new Error('Expected the three documented arena diagrams.');
const escape = value => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;').replaceAll('"', '&quot;');
const fontTemplate = await readFile(new URL('tool/combat-guide-template.html', base), 'utf8');
const font = fontTemplate.match(/@font-face\s*\{[^}]+\}/)?.[0];
if (!font) throw new Error('The existing combat guide font is missing.');
const theme = ':root{--pele-bg:#031015;--pele-fg:#dfffee;--pele-line:#55ffff;--pele-muted:#99e3bd;--pele-surface:#061117;--pele-surface-alt:#06232a;--pele-border:#388d87;--pele-accent:#ff55ff;--pele-radius:0;--pele-font:Consolas,monospace;--pele-font-mono:Consolas,monospace}';
const descriptions = [
  ['hierarchy', 'Class relationships', 'The fighter contract',
    'A view holds the same model that combat updates. The player and each enemy specialize that shared contract. Hollow triangles point toward the parent class.'],
  ['ownership', 'Ownership & dependencies', 'Who holds what?',
    'The game owns the simulation and shared sprite cache. The arena owns the visual components. Each animation handler reads frames from that one cache.'],
  ['flow', 'Construction & frame flow', 'From simulation to screen',
    'Models are created first. The factory pairs them with typed views. Fixed combat steps run before presentation updates; rendering reads the resulting state.'],
];

const diagrams = sources.map((source, index) => {
  const [id, label, title, description] = descriptions[index];
  const variants = index < 2
    ? [['compact', source.replace(/(class\s+[\w~]+)\s*\{[^}]*\}/g, '$1')], ['full', source]]
    : [['full', source]];
  const pictures = variants.map(([variant, text], j) => {
    const result = render(text, {
      fontFamily: 'Consolas, monospace', fontFamilyMono: 'Consolas, monospace',
      fontSize: 15, padding: 30, responsive: true, autoDirection: false,
      idPrefix: `arena-${id}-${variant}`, links: false, images: false,
    });
    if (!result.svg.includes('<svg') || /NaN/.test(result.svg)) {
      throw new Error(`Invalid SVG for ${id}/${variant}`);
    }
    const standalone = result.svg.replace(/(<svg\b[^>]*>)/, `$1<style>${theme}</style>`);
    const download = `data:image/svg+xml;base64,${Buffer.from(standalone).toString('base64')}`;
    console.log(`${id}/${variant}: ${result.width} x ${result.height}`);
    return `<div class="diagram-variant" data-variant="${variant}" data-width="${result.width}" ${j ? 'hidden' : ''}>
      <div class="svg-stage" role="img" aria-label="${escape(label)} diagram. Mermaid source is available below.">${result.svg}</div>
      <a class="svg-download" href="${download}" download="fighter-arena-${id}-${variant}.svg" hidden>Download SVG</a>
    </div>`;
  }).join('\n');
  return `<section class="diagram-panel" id="${id}" role="tabpanel" aria-labelledby="tab-${id}" ${index ? 'hidden' : ''}>
    <div class="panel-intro"><p class="eyebrow">0${index + 1} / ${escape(label)}</p><h2>${escape(title)}</h2><p>${escape(description)}</p></div>
    <div class="console-bar"><span class="console-file">${id}.mmd</span><div class="tools">
      ${index < 2 ? '<label class="members"><input type="checkbox" data-members> Members</label>' : ''}
      <button type="button" data-zoom="out" aria-label="Zoom out">−</button><output aria-live="polite">100%</output>
      <button type="button" data-zoom="in" aria-label="Zoom in">+</button><button type="button" data-zoom="fit">Fit</button>
      <button type="button" data-download>SVG ↓</button>
    </div></div>
    <div class="diagram-window" tabindex="0" aria-label="${escape(label)}. Scroll to explore the diagram.">${pictures}</div>
    <div class="diagram-caption"><span>MERMAID → PELE 1.6.0 → SVG</span><span>Scroll to explore · Use + for detail</span></div>
    <details><summary>Read the Mermaid source</summary><pre><code>${escape(source)}</code></pre>
      <a class="source-download" download="fighter-arena-${id}.mmd" href="data:text/plain;base64,${Buffer.from(source).toString('base64')}">Download .mmd source ↓</a>
    </details></section>`;
}).join('\n');

let page = await readFile(new URL('tool/fighter-arena-template.html', base), 'utf8');
page = page.replace('/* EMBEDDED_FONT */', font)
  .replace('/* DIAGRAM_THEME */', theme)
  .replace('<!-- DIAGRAM_PANELS -->', diagrams)
  .replace('<!-- MARKDOWN_DOWNLOAD -->', `data:text/markdown;base64,${Buffer.from(markdown).toString('base64')}`);
if (/<!-- (DIAGRAM_PANELS|MARKDOWN_DOWNLOAD) -->|\/\* (EMBEDDED_FONT|DIAGRAM_THEME) \*\//.test(page)) {
  throw new Error('Unfilled page template.');
}
await writeFile(new URL('web/fighter-arena.html', base), page);
console.log('Updated web/fighter-arena.html. No runtime renderer or remote assets.');
