/* PWA service worker: no authenticated pages or API calls are cached. */
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

// This is a display handler only; notifications require a server-side Web Push sender
// and per-device subscriptions. No automatic reminders are enabled yet.
self.addEventListener('push', (event) => {
  let data = {};
  try { data = event.data?.json() ?? {}; } catch { data = { body: event.data?.text() ?? '' }; }
  const title = typeof data.title === 'string' ? data.title : 'أعطني قلبك';
  const body = typeof data.body === 'string' ? data.body : 'وقت الصلاة ❤️';
  event.waitUntil(self.registration.showNotification(title, {
    body, icon: '/icon-192.png', badge: '/icon-192.png',
    tag: typeof data.tag === 'string' ? data.tag : undefined,
    data: { url: typeof data.url === 'string' && data.url.startsWith('/') && !data.url.startsWith('//') ? data.url : '/' }
  }));
});
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = new URL(event.notification.data?.url || '/', self.location.origin).href;
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const client of windows) {
      if (new URL(client.url).origin === self.location.origin) {
        await client.navigate(url);
        return client.focus();
      }
    }
    return self.clients.openWindow(url);
  })());
});
