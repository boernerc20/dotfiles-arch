// Firefox start page — source in ~/.config/firefox/home/ (tracked in dotfiles-arch).
//
// WHY user.js AND NOT THE SETTINGS UI
// -----------------------------------
// Firefox replays this file into prefs.js on EVERY startup. That makes it the
// source of truth, but it also means a homepage set through Settings > Home is
// silently reverted on the next launch. If the homepage needs to change, change
// it HERE — editing it in the UI will not stick.
//
// WHY THE TAILSCALE ADDRESS AND NOT localhost:8080
// ------------------------------------------------
// The page is served twice: locally by serve.py on 127.0.0.1:8080, and by an
// nginx container on truenas that wal-hypr.sh mirrors to on every wallpaper
// change (see ~/.local/bin/sync-startpage). Pointing at the mirror means
// desktop, phone and laptop load the identical URL and the identical palette.
// The MagicDNS name is used rather than the literal 100.87.245.19 so that a
// reassigned tailnet IP cannot silently break the homepage on every device.
//
// Tradeoff accepted: if truenas or the tailnet is down this fails to load, and
// http://localhost:8080 is the fallback to type manually.
user_pref("browser.startup.homepage", "http://truenas-scale.tail847e28.ts.net:8081");
user_pref("browser.startup.page", 1);

// THE SECOND REVERSION VECTOR: FIREFOX SYNC
// -----------------------------------------
// This profile is signed into Sync (boernerc20@gmail.com), and upstream defaults
// BOTH services.sync.engine.prefs AND
// services.sync.prefs.sync.browser.startup.homepage to true. The prefs engine
// applies incoming values with a bare setCharPref at runtime — it does not
// consult user.js — so another device could silently overwrite the homepage
// mid-session even after user.js had set it correctly at startup.
//
// Per prefs.sys.mjs, a pref is only synced when its "services.sync.prefs.sync.*"
// gate reads true, so setting the gate false opts the homepage out of Sync
// entirely. It lives here rather than in the UI so it is re-asserted on every
// startup and Sync can never flip it back.
user_pref("services.sync.prefs.sync.browser.startup.homepage", false);
user_pref("services.sync.prefs.sync.browser.startup.page", false);

// NEW TABS
// --------
// Firefox has NO supported pref for a custom new-tab URL. browser.newtab.url
// was removed in Firefox 41 because hijacking it was a malware vector, and
// newtabpage.enabled=false only yields about:blank. An extension is the only
// supported route — "New Tab Override", pointed at the URL above.
//
// Left enabled (true) deliberately: about:blank on every new tab is worse than
// Firefox's own page while no extension is installed. Flip to false only if you
// prefer blank. The extension overrides this either way once installed.
user_pref("browser.newtabpage.enabled", true);
