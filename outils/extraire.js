/* Extraction des constantes de donnees vibetab vers JSON, MIT. */
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const WEB = process.argv[2], OUT = process.argv[3];
const html = fs.readFileSync(path.join(WEB, 'index.html'), 'utf8');
const srcs = [...html.matchAll(/<script src="([^"]+)"><\/script>/g)].map(m => m[1])
  .filter(s => s.indexOf('js/data/') === 0);
let code = '';
const noms = new Set(); const EXTRAS = ['FR_TransportsParis_Str','FR_TransportsVilles_Str','FR_TransportsParis_Stations_Str','FR_TransportsVilles_Stations_Str','UE_TransportsVilles_Str','UE_TransportsVilles_Stations_Str']; EXTRAS.forEach(n=>noms.add(n));
for (const s of srcs) {
  const t = fs.readFileSync(path.join(WEB, s), 'utf8');
  code += t + '\n';
  for (const m of t.matchAll(/(?:^|\n)\s*(?:const|var)\s+([A-Za-z][A-Za-z0-9_]*_STR|[A-Za-z][A-Za-z0-9_]*_B64)\b/g)) noms.add(m[1]);
}
code += 'globalThis.__dump = {' + [...noms].map(n => n).join(',') + '};';
const sandbox = { window: {}, vbtScriptVu: function () {} };
vm.createContext(sandbox);
vm.runInContext(code, sandbox, { filename: 'toutes-donnees' });
const dump = sandbox.__dump || sandbox.globalThis.__dump;
const keep = {};
for (const n of Object.keys(dump)) {
  if (typeof dump[n] === 'string') { keep[n] = dump[n]; console.error(n + '\t' + dump[n].length); }
}
fs.writeFileSync(OUT, JSON.stringify(keep));
console.error('constantes retenues : ' + Object.keys(keep).length);
