#!/usr/bin/env python3
"""Static server for the Firefox start page, with caching disabled.

WHY THIS EXISTS INSTEAD OF `python3 -m http.server`
---------------------------------------------------
The stock handler sends no Cache-Control header at all. Browsers then fall back
to *heuristic* freshness and may reuse a response without revalidating, based on
how long ago it was last modified. colors.css and surfaces.css are symlinks into
~/.cache/wal/ that are rewritten on every wallpaper change, so the page would
keep rendering a previous palette — and, worse, a previous stylesheet.

That is exactly what happened on 2026-08-02: the page rendered old markup
against a new stylesheet, because Firefox was still holding a cached index.html
from before a redesign while the served copy on disk had moved on.

index.html used to work around this with a JS cache-buster that rewrote each
<link href> with a ?v=timestamp. That is a patch on the client for a defect in
the server's headers, it cannot help the very first paint, and it silently does
nothing if the script errors. Sending no-store is the actual fix, so the
cache-buster is gone from the page.

`Cache-Control: no-store` is deliberately stronger than `no-cache`: no-cache
permits storing a copy and revalidating, no-store forbids keeping it at all.
This is localhost serving six small files — there is nothing to optimise.

NOTE: there is no longer a dynamic /wallpaper route here. It resolved
~/.current_wallpaper per request, which worked locally but had no equivalent in
the nginx mirror on truenas, so the mirrored page could never show a backdrop.
wal-hypr.sh now writes a normalised wallpaper.jpg into this directory instead,
which both servers serve as an ordinary static file.
"""
import functools
import http.server
import socketserver

PORT = 8080
BIND = "127.0.0.1"
DIRECTORY = "/home/chris/.config/firefox/home"


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, fmt, *args):
        # The stock handler logs every request to stderr, which systemd captures
        # into the journal. A start page reloads on every new tab, so this
        # produced a steady drip of noise with no diagnostic value.
        pass


class Server(socketserver.TCPServer):
    allow_reuse_address = True  # survive a restart without TIME_WAIT delays


if __name__ == "__main__":
    handler = functools.partial(NoCacheHandler, directory=DIRECTORY)
    with Server((BIND, PORT), handler) as httpd:
        httpd.serve_forever()
