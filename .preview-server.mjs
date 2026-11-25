import http from 'node:http';
import net from 'node:net';
import fs from 'node:fs';
import path from 'node:path';

const PORT = Number(process.env.DEFAULT_APP_PORT || 3000);
const APP_DIR = process.env.APP_DIR || '/app/applet';
const BACKEND_HOST = process.env.BACKEND_HOST || '127.0.0.1';
const BACKEND_PORT = Number(process.env.BACKEND_PORT || 8001);

const APK_CANDIDATES = [
  path.join(APP_DIR, 'app/build/outputs/apk/debug/app-debug.apk'),
  path.join(APP_DIR, '.build-outputs/app-debug.apk'),
];

const SITE_DIST = path.join(APP_DIR, 'mindora/site/dist');
const ADMIN_DIST = path.join(APP_DIR, 'mindora/admin/dist');
const LOGO_FALLBACK = path.join(APP_DIR, 'app/src/main/res/drawable/mindora_logo.png');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.txt': 'text/plain; charset=utf-8',
  '.xml': 'application/xml; charset=utf-8',
  '.woff2': 'font/woff2',
  '.webp': 'image/webp',
};

function getApkInfo() {
  for (const candidate of APK_CANDIDATES) {
    try {
      const stat = fs.statSync(candidate);
      if (stat.isFile() && stat.size > 0) {
        return {
          ready: true,
          path: candidate,
          sizeBytes: stat.size,
          mtime: stat.mtime.toISOString(),
        };
      }
    } catch {
      // try next
    }
  }
  return { ready: false, path: null, sizeBytes: 0, mtime: null };
}

function isBackendPath(urlPath) {
  return (
    urlPath.startsWith('/api') ||
    urlPath === '/docs' ||
    urlPath.startsWith('/docs/') ||
    urlPath === '/redoc' ||
    urlPath === '/openapi.json'
  );
}

function proxyHttpToBackend(req, res) {
  const options = {
    hostname: BACKEND_HOST,
    port: BACKEND_PORT,
    path: req.url || '/',
    method: req.method,
    headers: {
      ...req.headers,
      host: `${BACKEND_HOST}:${BACKEND_PORT}`,
    },
  };
  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
    proxyRes.pipe(res, { end: true });
  });
  proxyReq.on('error', (err) => {
    if (!res.headersSent) {
      res.writeHead(502, { 'Content-Type': 'application/json' });
    }
    res.end(JSON.stringify({ error: 'backend_unavailable', detail: err.message }));
  });
  req.pipe(proxyReq, { end: true });
}

function serveStaticSpa(distDir, relPath, res) {
  const cleanRel = decodeURIComponent(relPath.split('?')[0]).replace(/^\/+/, '');
  const resolved = path.normalize(path.join(distDir, cleanRel));
  if (resolved.startsWith(distDir) && cleanRel && fs.existsSync(resolved) && fs.statSync(resolved).isFile()) {
    const ext = path.extname(resolved).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
    fs.createReadStream(resolved).pipe(res);
    return true;
  }
  const indexPath = path.join(distDir, 'index.html');
  if (fs.existsSync(indexPath)) {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    fs.createReadStream(indexPath).pipe(res);
    return true;
  }
  return false;
}

const server = http.createServer((req, res) => {
  const urlPath = (req.url || '/').split('?')[0];

  if (urlPath === '/health') {
    const apk = getApkInfo();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(
      JSON.stringify({
        status: 'ok',
        gateway: 'mindora',
        apkReady: apk.ready,
        apkSizeBytes: apk.sizeBytes,
        siteReady: fs.existsSync(path.join(SITE_DIST, 'index.html')),
        adminReady: fs.existsSync(path.join(ADMIN_DIST, 'index.html')),
      })
    );
    return;
  }

  if (isBackendPath(urlPath)) {
    proxyHttpToBackend(req, res);
    return;
  }

  if (urlPath === '/app-debug.apk') {
    const apk = getApkInfo();
    if (!apk.ready || !apk.path) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('APK not found');
      return;
    }
    res.writeHead(200, {
      'Content-Type': 'application/vnd.android.package-archive',
      'Content-Length': apk.sizeBytes,
      'Content-Disposition': 'attachment; filename="mindora-debug.apk"',
    });
    fs.createReadStream(apk.path).pipe(res);
    return;
  }

  if (urlPath === '/admin') {
    res.writeHead(302, { Location: '/admin/' });
    res.end();
    return;
  }

  if (urlPath.startsWith('/admin/')) {
    const rel = urlPath.slice('/admin/'.length);
    if (serveStaticSpa(ADMIN_DIST, rel, res)) return;
  }

  if (urlPath === '/logo.png' && !fs.existsSync(path.join(SITE_DIST, 'logo.png')) && fs.existsSync(LOGO_FALLBACK)) {
    res.writeHead(200, { 'Content-Type': 'image/png' });
    fs.createReadStream(LOGO_FALLBACK).pipe(res);
    return;
  }

  if (serveStaticSpa(SITE_DIST, urlPath, res)) return;

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not found');
});

server.on('upgrade', (req, socket, head) => {
  const urlPath = (req.url || '/').split('?')[0];
  if (!isBackendPath(urlPath)) {
    socket.destroy();
    return;
  }
  const backendSocket = net.connect(BACKEND_PORT, BACKEND_HOST, () => {
    const headers = Object.entries(req.headers)
      .map(([k, v]) => `${k}: ${Array.isArray(v) ? v.join(', ') : v}`)
      .join('\r\n');
    backendSocket.write(`${req.method} ${req.url} HTTP/${req.httpVersion}\r\n${headers}\r\n\r\n`);
    if (head?.length) backendSocket.write(head);
    socket.pipe(backendSocket);
    backendSocket.pipe(socket);
  });
  backendSocket.on('error', () => socket.destroy());
  socket.on('error', () => backendSocket.destroy());
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`MINDORA unified gateway listening on http://0.0.0.0:${PORT}`);
});
