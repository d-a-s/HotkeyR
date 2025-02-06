const wdurl = p => new URL(p, 'https://d.indyblue.com:23443');
const remotePath = '/zprogs/AutoHotkey/HotkeyR';
const winPath = String.raw`C:\zprogs\AHK\alt-tab`;

const os = require('os');
const { createHmac } = require('crypto');
/* eslint-disable no-unused-vars */
const { promises: { readFile, writeFile, mkdir, stat } } = require('fs');
const { join, dirname, posix: { join: pjoin } } = require('path');
const { URL } = require('url');
const request = fetch; // require('./asyncRequest');
const { parse } = require('./xml');

const uclean = x => x.replace(/^\/|\/$/g, '');
const ujoin = (...x) => pjoin(...x.map(a => uclean(a)));
const opt = a => Object.fromEntries(Object.entries(a).filter(x => x[1] !== undefined));

async function ensure(dir) {
  try {
    await stat(dir);
  } catch {
    await mkdir(dir, { recursive: true });
    console.log(`Directory created: ${dir}`);
  }
}

// d: 0=f is data, w=readfile, g=get
const md5 = async (f, d, stablems) => {
  if (d && stablems) {
    let dh0 = [];
    while (true) {
      const dh = await md5(f, d);
      if (dh[1] === dh0[1]) return dh;
      await sleep(stablems);
      dh0 = dh;
    }
  }

  let data = f;
  if (d === 'w') data = await readFile(f);
  else if (d === 'g') {
    const resp = await get(f);
    const ab = await resp.arrayBuffer();
    data = Buffer.from(ab);
  }
  const hasher = createHmac('md5', '');
  const hash = hasher.update(data).digest('hex');
  if (d) return [data, hash];
  return hash;
};

const pf = async (p, recurse = false) => {
  const resp = await request(wdurl(p), { method: 'PROPFIND', headers: { depth: 1 } });
  const txt = await resp.text();
  const obj = parse(txt);
  if (!Array.isArray(obj?.multistatus?.response)) return;
  const prs = obj.multistatus.response.map(async ({ href, propstat }) => {
    const io = href.indexOf(p);
    if (io < 0) return;
    const name = uclean(href.substring(io + p.length));
    let path = name;
    if (recurse) {
      if (typeof recurse !== 'string') recurse = p;
      const iob = href.indexOf(recurse);
      path = uclean(href.substring(iob + recurse.length));
    }
    if (!name) return { name };
    const dir = propstat.prop.resourcetype?.collection && true;
    if (recurse && dir) {
      if (name === '.git') return;
      const pf2 = await pf(ujoin(p, name), recurse);
      return pf2;
    }
    const {
      getlastmodified: mod,
      getcontentlength: len,
    } = propstat.prop;
    return opt({ path, dir, name, mod, len });
  });
  const expand = await Promise.all(prs);
  const rv = expand.flat().filter(y => y?.name);
  return rv;
};

const get = p => request(wdurl(p));

/* eslint-disable-next-line no-unused-vars */
const put = (p, data) => request(wdurl(p), { method: 'put', data });

const sleep = async ms => new Promise(resolve => setTimeout(() => resolve('done'), ms));

const iip = x => join(winPath, ...x.split(/[/\\]/));

async function main() {
  let cache = {};
  while (true) {
    const files = await pf(remotePath, 1);

    for (const f of files) {
      const cx = cache[f.path];
      const dif = f.mod !== cx?.mod || f.len !== cx?.len;
      if (!dif) continue;
      const [data, hash] = await md5(ujoin(remotePath, f.path), 'g');

      // console.log(new Date(), { x, cx, dif, hash, len: data?.length });

      if (os.platform() !== 'win32') continue;

      const winfile = iip(f.path);
      let action = 'writing';
      try {
        const [, winhash] = await md5(winfile, 'w');
        if (hash === winhash) continue;
      } catch { action = 'creating'; }

      if (data.length) {
        console.log(new Date(), action, winfile, data.length);
        await ensure(dirname(winfile));
        await writeFile(winfile, data);
      }
    };

    cache = files.reduce((a, x) => { a[x.path] = x; return a; }, {});

    await sleep(1000);
  }
}
main();
