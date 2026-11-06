"""Serves the map editor on this Mac (QM, Nov 6, as Fight to Steal an Egg's) and saves
straight into the game, so there's no file to send over.

Run: python3 tools/mapeditor/serve.py [port]     (default 3001; http://localhost:3001)

  GET  /            the editor (editor.html with the palette and the map baked in)
  GET  /world.map   the game's map as it is now (maps/world1.map)
  POST /save        a .map from the editor: merged with any change made to the file since
                    that tab opened it (its X-Map-Base), written to maps/world1.map, and built
                    into World 1's open Studio place (studio/build.luau) when it's in Edit mode.
                    Publish the place in Studio to keep it.
On start it refreshes the palette (Config's colours) from Studio if it can.
"""

import hashlib
import json
import os
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mapfile import MAP, dump, rle  # noqa: E402
from studio import run_luau  # noqa: E402
import build  # noqa: E402
import export  # noqa: E402

SERVED_DIR = os.path.join(tempfile.gettempdir(), "lasso_mapeditor_served")
os.makedirs(SERVED_DIR, exist_ok=True)
LOCK = threading.Lock()


def version(text):
    return hashlib.sha1(text.encode()).hexdigest()[:12]


def served_put(text):
    open(os.path.join(SERVED_DIR, version(text)), "w").write(text)


def served_get(v):
    path = os.path.join(SERVED_DIR, os.path.basename(v)) if v else ""
    return open(path).read() if v and os.path.exists(path) else None


def merge(base, mine, theirs):
    """Three-way: what the tab changed from the version it opened wins; everything else
    (other tabs, Claude's edits to the file) stays. Rows merge cell by cell."""
    b, m, t = json.loads(base), json.loads(mine), json.loads(theirs)
    if b.get("size") != t.get("size") or b.get("size") != m.get("size"):
        return mine
    out = dict(t)
    for k in m:
        if k == "rows":
            out["rows"] = ["".join(cm if cm != cb else ct for cm, cb, ct in zip(rm, rb, rt))
                           for rm, rb, rt in zip(m["rows"], b["rows"], t["rows"])]
        elif k == "saved" or m[k] != b.get(k):
            out[k] = m[k]
    return dump(out)


def to_studio(text):
    """Builds the map in World 1's open Studio place. (message, new map text or None)"""
    m = json.loads(text)
    data = {k: m[k] for k in ("cell", "origin", "size", "tiles", "objects", "borders", "colours")}
    index = {t["id"]: i + 1 for i, t in enumerate(m["tiles"])}
    data["rle"] = [rle(r, index) for r in m["rows"]]
    blob = json.dumps(data, separators=(",", ":"))
    level = 1
    while "]" + "=" * level + "]" in blob:
        level += 1
    eq = "=" * level
    code = "local DATA = [%s[%s]%s]\n" % (eq, blob, eq) + open(os.path.join(HERE, "studio", "build.luau")).read()
    try:
        out = run_luau(code, "Edit")
    except Exception as e:  # (Studio closed, or in Play)
        return "Saved, but Studio didn't take it (%s). Save again once it's open in Edit mode." % e, None
    if "Play mode" in out:
        return "Saved. Studio is in Play: stop it and save again to build it there.", None
    try:
        r = json.loads(out)
    except ValueError:
        return "Saved, but the build in Studio failed: " + out[:300], None
    if not r.get("ok"):
        return "Saved. Studio is in Play: stop it and save again to build it there.", None
    new = None
    if r.get("newIds"):
        # the objects placed in the editor have their ids now: into the file, so the next
        # save moves them instead of adding them again
        for n, oid in r["newIds"].items():
            m["objects"][int(n) - 1]["id"] = oid
        new = dump(m)
    return "Saved and built in Studio: " + r["message"] + ". Publish the place there to keep it.", new


class Handler(BaseHTTPRequestHandler):
    def send(self, code, body, kind="text/plain; charset=utf-8", headers=None):
        data = body if isinstance(body, bytes) else body.encode()
        self.send_response(code)
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path in ("/", "/MapEditor.html"):
            self.send(200, open(build.main(), "rb").read(), "text/html; charset=utf-8")
        elif path == "/world.map":
            text = open(MAP).read()
            served_put(text)
            self.send(200, text, "application/json", {"X-Map-Version": version(text)})
        else:
            self.send(404, "not found")

    def do_POST(self):
        if self.path != "/save":
            return self.send(404, "not found")
        text = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode()
        try:
            json.loads(text)
        except ValueError:
            return self.send(400, "That isn't a .map.")
        with LOCK:
            current = open(MAP).read()
            base = served_get(self.headers.get("X-Map-Base", ""))
            merged = base is not None and base != current
            if merged:
                text = merge(base, text, current)
            tmp = MAP + ".tmp"
            open(tmp, "w").write(text)
            os.replace(tmp, MAP)
            msg, new = to_studio(text)
            if new:
                open(tmp, "w").write(new)
                os.replace(tmp, MAP)
                text, merged = new, True
            served_put(text)
        # (merged: the tab reloads the file, so it carries the other changes and new ids from now on)
        self.send(200, msg, headers={"X-Map-Version": version(text), "X-Map-Merged": "1" if merged else "0"})

    def log_message(self, fmt, *args):
        sys.stderr.write("%s\n" % (fmt % args))


def refresh_palette():
    try:
        export.export("palette")
    except BaseException as e:  # (Studio not open: the palette from last time)
        sys.stderr.write("palette not refreshed from Studio: %s\n" % e)


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 3001
    threading.Thread(target=refresh_palette, daemon=True).start()
    print("map editor on http://localhost:%d" % port)
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
