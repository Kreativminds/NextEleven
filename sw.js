// NextEleven — Parents Page app shell cache.
//
// Only caches the static shell listed below, so "Add to Home Screen"
// still opens to something useful with a weak/no connection. It NEVER
// caches Supabase responses or anything cross-origin — match data must
// always be live; a stale cached score would be worse than no offline
// support at all. Any request that isn't a same-origin GET for one of
// these exact files is left completely untouched and goes straight to
// the network, same as if this file didn't exist.
const CACHE_NAME = 'nexteleven-shell-v1';
const SHELL_FILES = [
  'team.html',
  'public-stats-core.js',
  'team-manifest.json',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'icons/icon-maskable-192.png',
  'icons/icon-maskable-512.png',
  'icons/apple-touch-icon.png',
  'icons/favicon-32.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(SHELL_FILES))
      .catch(() => {}) // a failed pre-cache shouldn't block install — fetch() below still falls back per-file
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return; // never touch POSTs — that's the Supabase RPC calls

  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return; // never touch Supabase or any other cross-origin call

  const isShellFile = SHELL_FILES.some((f) => url.pathname.endsWith(f));
  if (!isShellFile) return;

  // Network-first: a parent with a normal connection always gets the
  // current page/scripts (so a deployed fix shows up immediately, same
  // as today), and the cache is only what keeps the app shell from going
  // fully blank when there's no connection at all.
  event.respondWith(
    fetch(req)
      .then((res) => {
        const copy = res.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(req, copy)).catch(() => {});
        return res;
      })
      .catch(() => caches.match(req))
  );
});
