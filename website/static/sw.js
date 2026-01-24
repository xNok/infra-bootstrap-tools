const cacheName = 'ibt-{{ now.Format "2006-01-02" }}';
const staticAssets = [
    '/infra-bootstrap-tools/',
    '/infra-bootstrap-tools/index.html',
    '/infra-bootstrap-tools/manifest.json',
    '/infra-bootstrap-tools/docs/**/*',
    '/infra-bootstrap-tools/favicon/android-chrome-192x192.png',
    '/infra-bootstrap-tools/favicon/android-chrome-512x512.png',
    '/infra-bootstrap-tools/favicon/apple-touch-icon.png',
    '/infra-bootstrap-tools/favicon/favicon.ico',
    '/infra-bootstrap-tools/favicon/favicon-16x16.png',
    '/infra-bootstrap-tools/favicon/favicon-32x32.png',
    '/infra-bootstrap-tools/css/home.min.*.css',
    '/infra-bootstrap-tools/css/docs.min.*.css',
    '/infra-bootstrap-tools/js/home.min.*.js',
    '/infra-bootstrap-tools/js/docs.min.*.js',
];

self.addEventListener('install', async e => {
    const cache = await caches.open(cacheName);
    await cache.addAll(staticAssets);
    return self.skipWaiting();
});

self.addEventListener('activate', e => {
    self.clients.claim();
});

self.addEventListener('fetch', async e => {
    const req = e.request;
    const url = new URL(req.url);

    if (url.origin === location.origin) {
        e.respondWith(cacheFirst(req));
    } else {
        e.respondWith(networkFirst(req));
    }
});

async function cacheFirst(req) {
    const cache = await caches.open(cacheName);
    const cached = await cache.match(req);
    return cached || fetch(req);
}

async function networkFirst(req) {
    const cache = await caches.open(cacheName);
    try {
        const fresh = await fetch(req);
        cache.put(req, fresh.clone());
        return fresh;
    } catch (e) {
        const cached = await cache.match(req);
        return cached;
    }
}