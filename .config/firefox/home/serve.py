#!/usr/bin/env python3
"""Static server for the Firefox start page, with caching disabled.

WHY THIS EXISTS INSTEAD OF `python3 -m http.server`
---------------------------------------------------
The stock handler sends no Cache-Control header at all. Browsers then fall back
to *heuristic* freshness: they may reuse a response without revalidating, based
on how long ago it was last modified. colors.css and surfaces.css are symlinks
into ~/.cache/wal/ that are rewritten on every wallpaper change, so the page
would keep rendering a previous palette — and, worse, a previous stylesheet.

That is exactly what happened on 2026-08-02: the page rendered a washed-out
light background because Firefox was still using a cached style.css from an
older revision that painted the raw wallpaper behind the content, while the
served copy on disk had long since switched to a dark surface.

index.html used to work around this with a JS cache-buster that rewrote each
<link href> with a ?v=timestamp. That is a patch on the client for a defect in
the server's headers, it cannot help the very first paint, and it silently does
nothing if the script errors. Sending no-store is the actual fix, so the
cache-buster is gone from the page.

`Cache-Control: no-store` is deliberately stronger than `no-cache`: no-cache
permits storing a copy and revalidating, no-store forbids keeping it at all.
This is localhost serving six small files — there is nothing to optimise.
"""
import functools
import http.server
import os
import socketserver

PORT = 8080
BIND = "127.0.0.1"
DIRECTORY = "/home/chris/.config/firefox/home"
WALLPAPER_LINK = os.path.expanduser("~/.current_wallpaper")

# Sniffed from the file's magic bytes rather than trusted from its extension,
# because the symlink target may be .png, .jpg or .jpeg and the extension is
# not always honest about the contents.
MAGIC = [
    (b"\x89PNG\r\n\x1a\n", "image/png"),
    (b"\xff\xd8\xff", "image/jpeg"),
    (b"GIF87a", "image/gif"),
    (b"GIF89a", "image/gif"),
    (b"BM", "image/bmp"),
]


def sniff(head: bytes) -> str:
    if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        return "image/webp"
    for sig, mime in MAGIC:
        if head.startswith(sig):
            return mime
    return "application/octet-stream"


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # THE WALLPAPER ROUTE.
        #
        # colors.css carries `--wallpaper: url("/home/chris/pics/wallpapers/…")`,
        # an absolute FILESYSTEM path. Served over http://localhost:8080 a leading
        # slash resolves against the SERVER ROOT, not the filesystem, so the
        # browser requested /home/chris/pics/... and got a 404 every time — the
        # backdrop could never load. That is why this page never showed the right
        # image, and why it kept whatever stale bitmap the cache still held.
        #
        # Resolving ~/.current_wallpaper per request rather than at startup means
        # the backdrop follows Super+W immediately, with no restart and nothing
        # for wal-hypr.sh to remember to update.
        if self.path.split("?")[0] == "/wallpaper":
            return self.send_wallpaper()
        return super().do_GET()

    def do_HEAD(self):
        # Overridden alongside do_GET. Without this, HEAD /wallpaper fell through
        # to the static file lookup, found no file literally named "wallpaper",
        # and returned 404 — while GET on the same URL returned 200. Browsers use
        # GET for a CSS background so the page still worked, but a URL that
        # answers differently to HEAD and GET is a trap for anything that probes
        # before fetching, and it made the route look broken when checked by hand.
        if self.path.split("?")[0] == "/wallpaper":
            return self.send_wallpaper(body=False)
        return super().do_HEAD()

    def send_wallpaper(self, body=True):
        try:
            target = os.path.realpath(WALLPAPER_LINK)
            with open(target, "rb") as fh:
                data = fh.read()
        except OSError:
            # No wallpaper set yet, or a dangling symlink. 404 so the CSS simply
            # falls back to the flat --app-bg instead of the page erroring.
            self.send_error(404, "no current wallpaper")
            return
        self.send_response(200)
        self.send_header("Content-Type", sniff(data[:16]))
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        if body:
            self.wfile.write(data)

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
