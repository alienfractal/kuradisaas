// node tool/render_app_architecture.mjs <path-to-pele-1.6.0-module>
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const root = new URL('../', import.meta.url);
const { render } = await import(process.argv[2]
  ? pathToFileURL(resolve(process.argv[2])).href : 'pele');
const markdown = await readFile(new URL('docs/app-architecture-uml.md', root), 'utf8');
const diagrams = [...markdown.matchAll(/## ([^\n]+)\r?\n([\s\S]*?)```mermaid\r?\n([\s\S]*?)```/g)];
if (diagrams.length !== 7) throw new Error('Expected overview and six state diagrams.');
const esc = s => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;').replaceAll('"', '&quot;');
const template = await readFile(new URL('tool/combat-guide-template.html', root), 'utf8');
const font = template.match(/@font-face\s*\{[^}]+\}/)?.[0];
if (!font) throw new Error('Missing retro font.');
const theme = ':root{--pele-bg:#031015;--pele-fg:#dfffee;--pele-line:#55ffff;--pele-muted:#99e3bd;--pele-surface:#061117;--pele-surface-alt:#06232a;--pele-border:#388d87;--pele-accent:#ff55ff;--pele-radius:0;--pele-font:Consolas,monospace}';
const tabs = diagrams.map(([,title],i) => `<button role="tab" id="tab-${i}" aria-controls="panel-${i}" aria-selected="${i === 0}" tabindex="${i ? -1 : 0}" data-tab="${i}">${esc(title.trim())}</button>`).join('');
const panels = diagrams.map(([,title,description,source],i) => {
  const result = render(source.trim(), {fontFamily:'Consolas, monospace', fontSize:16,
    padding:28, responsive:true, autoDirection:false, idPrefix:`app-${i}`, links:false, images:false});
  if (!result.svg.includes('<svg') || /NaN/.test(result.svg)) throw new Error(`Invalid diagram: ${title}`);
  console.log(`${title.trim()}: ${result.width} x ${result.height}`);
  const svg = result.svg.replace(/(<svg\b[^>]*>)/, `$1<style>${theme}</style>`);
  return `<section role="tabpanel" id="panel-${i}" aria-labelledby="tab-${i}" ${i ? 'hidden' : ''}>
    <h2>${esc(title.trim())}</h2><p>${esc(description.trim())}</p>
    <div class="toolbar"><button data-zoom="out" aria-label="Zoom out">−</button><output>100%</output><button data-zoom="in" aria-label="Zoom in">+</button><button data-zoom="fit">Fit</button><button data-zoom="actual">100%</button><a download="app-state-${i}.svg" href="data:image/svg+xml;base64,${Buffer.from(svg).toString('base64')}">Download SVG</a></div>
    <div class="viewport" tabindex="0" aria-label="${esc(title.trim())} UML diagram; scroll to explore"><div class="drawing" data-width="${result.width}" style="width:${result.width}px">${svg}</div></div>
    <details><summary>Mermaid source</summary><pre>${esc(source.trim())}</pre></details></section>`;
}).join('');
const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" href="data:,"><title>Kuradi Sääsed / Application UML</title><style>
${font}
${theme}
*{box-sizing:border-box}[hidden]{display:none!important}body{margin:0;padding:24px;background:#0000aa;color:#dfffee;font:15px/1.6 Consolas,monospace}main{max-width:1500px;margin:auto;border:3px solid black;box-shadow:7px 7px black;background:#55ffff;padding:18px}header{color:black;padding:8px 10px 24px}h1{font:clamp(18px,3vw,32px)/1.7 AlienRetroConsole,monospace;margin:16px 0}header p{margin:0}a{color:#55ffff}header a{color:#000}nav{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:18px}button{cursor:pointer;font:inherit;background:#061117;color:#55ffff;border:1px solid #388d87;padding:8px 13px}nav button{background:white;color:black;border:2px solid black;box-shadow:3px 3px black}nav button[aria-selected=true]{background:#ff55ff}section{background:#031015;border:2px solid black;padding:22px}h2{color:#55ffff;margin:0;font:17px/1.8 AlienRetroConsole,monospace}section>p{max-width:1050px;white-space:pre-line;color:#b8dacc}.toolbar{display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin:16px 0}.toolbar a{margin-left:auto}.viewport{overflow:auto;max-height:78vh;min-height:240px;border:1px solid #388d87;background:#031015}.drawing{margin:auto}.drawing svg{display:block;width:100%;height:auto}output{min-width:48px;text-align:center}details{margin-top:16px}summary{cursor:pointer;color:#55ffff}pre{overflow:auto;font-size:12px;padding:14px;border:1px solid #388d87}.legend{background:#061117;padding:14px;color:#b8dacc;margin-top:18px}.legend strong{color:#ff55ff}footer{color:black;padding:18px 6px 0;font-size:13px}footer a{color:black}:focus-visible{outline:3px solid #ffff55;outline-offset:3px}@media(max-width:650px){body{padding:10px}main{padding:10px}section{padding:14px}nav button{font-size:12px;padding:8px}.toolbar a{margin-left:0}h2{font-size:13px}}@media print{body,main{padding:0}nav,.toolbar,footer{display:none}section[hidden]{display:block!important}section{break-before:page}.viewport{max-height:none;overflow:visible}.drawing{max-width:100%}}
</style></head><body><main><header><a href="./">← Game</a> · <a href="fighter-arena.html">Detailed fighter UML</a><h1>APPLICATION UML</h1><p>How each state's views connect to models, services and shared resources.</p></header><nav role="tablist" aria-label="Application states">${tabs}</nav>${panels}<div class="legend"><strong>UML notation:</strong> diamond = owns lifecycle · hollow triangle = inherits · solid arrow = held reference · dashed arrow = uses or receives values through the game.<br>Score and End receive snapshots; Pause retains the arena through the game. They do not each own a copy of the gameplay models.</div><footer>Canonical source: docs/app-architecture-uml.md · Offline SVGs rendered with Pele 1.6.0 · <a href="data:text/markdown;base64,${Buffer.from(markdown).toString('base64')}" download="app-architecture-uml.md">Download documentation</a></footer></main><script>
const tabs=[...document.querySelectorAll('[data-tab]')];
function zoom(panel,action){const drawing=panel.querySelector('.drawing'),viewport=panel.querySelector('.viewport'),native=Number(drawing.dataset.width);let scale=parseFloat(drawing.style.width)/native;if(action==='fit')scale=(viewport.clientWidth-4)/native;else if(action==='actual')scale=1;else scale*=action==='in'?1.25:.8;scale=Math.min(3,Math.max(.15,scale));drawing.style.width=(native*scale)+'px';panel.querySelector('output').textContent=Math.round(scale*100)+'%';}
function select(tab){tabs.forEach(t=>{const active=t===tab;t.setAttribute('aria-selected',active);t.tabIndex=active?0:-1;document.getElementById(t.getAttribute('aria-controls')).hidden=!active;});const panel=document.getElementById(tab.getAttribute('aria-controls'));if(!panel.dataset.opened){zoom(panel,'fit');panel.dataset.opened='true';}location.hash='state-'+tab.dataset.tab;}
tabs.forEach((tab,i)=>{tab.addEventListener('click',()=>select(tab));tab.addEventListener('keydown',e=>{if(['ArrowRight','ArrowLeft','Home','End'].includes(e.key)){e.preventDefault();const index=e.key==='Home'?0:e.key==='End'?tabs.length-1:(i+(e.key==='ArrowRight'?1:-1)+tabs.length)%tabs.length;select(tabs[index]);tabs[index].focus();}});});document.querySelectorAll('[data-zoom]').forEach(button=>button.addEventListener('click',()=>zoom(button.closest('section'),button.dataset.zoom)));const initial=Number(location.hash.replace('#state-',''));select(tabs[initial]||tabs[0]);
</script></body></html>`;
await writeFile(new URL('web/app-architecture.html', root), html);
console.log('Updated web/app-architecture.html');
