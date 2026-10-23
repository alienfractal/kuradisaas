// node tool/render_combat_guide.mjs <path-to-pele-1.6.0-module>
// With pele installed locally, the module path may be omitted.
// Generates an offline guide; does not start a server or browser.
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const { render } = await import(process.argv[2]
  ? pathToFileURL(resolve(process.argv[2])).href : 'pele');
const base = new URL('../', import.meta.url);
let page = await readFile(new URL('tool/combat-guide-template.html', base), 'utf8');
const escape = value => value.replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
const names = [...page.matchAll(/<!-- DIAGRAM:([\w-]+) -->/g)].map(match => match[1]);
for (const name of names) {
  const source = await readFile(new URL(`docs/combat/${name}.mmd`, base), 'utf8');
  let mobileSource = source;
  if (name === 'combat-states' || name === 'hit-reactions') {
    mobileSource = await readFile(new URL(`docs/combat/${name}-mobile.mmd`, base), 'utf8');
  }
  const diagrams = [];
  for (const [layout, maxWidth] of [['wide', 800], ['narrow', 280]]) {
    const result = render(layout === 'narrow' ? mobileSource : source, {
      fontFamily: 'AlienRetroConsole, monospace', fontSize: layout === 'narrow' ? 10 : 12,
      padding: 12, maxWidth, responsive: true, autoDirection: false,
      idPrefix: `${name}-${layout}`,
      measurer: { width: (text, size) => [...text].length * size },
    });
    if (!result.svg.includes('<svg') || /NaN/.test(result.svg)) {
      throw new Error(`Invalid rendered diagram: ${name}/${layout}`);
    }
    diagrams.push(`<div class="diagram ${layout}-diagram" role="img" aria-label="${escape(name.replaceAll('-', ' '))}. Full Mermaid source follows.">${result.svg}</div>`);
    console.log(`${name}/${layout}: ${result.width} x ${result.height}`);
  }
  page = page.replace(`<!-- DIAGRAM:${name} -->`, diagrams.join('\n') +
    `<details><summary>Mermaid source</summary><pre>${escape(source)}</pre></details>` +
    (mobileSource === source ? '' : `<details><summary>Mobile Mermaid source</summary><pre>${escape(mobileSource)}</pre></details>`));
}
if (page.includes('<!-- DIAGRAM:')) throw new Error('Unrendered diagram placeholder');
await writeFile(new URL('web/combat-diagram.html', base), page);
console.log(`Updated web/combat-diagram.html (${names.length} Mermaid sources; desktop and mobile SVGs).`);
