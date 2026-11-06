"""Serves the map editor on this Mac (QM, Oct 24) and saves straight into the game, so
there's no file to send over.

Run: python3 tools/mapeditor/serve.py [port]     (default 3000; http://localhost:3000)

  GET  /            the editor (MapEditor.html; run build.py after Config or mesh changes)
  GET  /world.map   the game's map as it is now (the editor opens this, not its baked-in copy)
  POST /save        a .map from the editor: merged with any change made to the file since
                    that tab opened it (its X-Map-Base), written to maps/world.map, baked into
                    src/shared/MapData.luau (tools/map_bake.py), synced into the open Studio
                    place and rebuilt there (tools/studio/rebuild.luau) when it's in Edit mode
"""

import hashlib
import json
import os
import select
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from map_grow import reframe  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
STUDIO = os.path.join(ROOT, "tools", "studio")
WORLD = os.path.join(ROOT, "maps", "world.map")
# every version served, on disk so a restart of this server still knows what an open tab
# opened (a tab saves against that version; without it the save would overwrite the file)
# (what a save changes, synced into Studio before the rebuild: Lasso's src/ is too big to send whole)
MAP_FILES = ("src/shared/MapData.luau", "src/shared/MapFile.luau", "src/shared/HiddenFaces.luau", "src/server/Map.luau")
SERVED_DIR = os.path.join(tempfile.gettempdir(), "mapeditor_served")
os.makedirs(SERVED_DIR, exist_ok=True)


class Served:
    def __setitem__(self, v, text):
        open(os.path.join(SERVED_DIR, v), "w").write(text)

    def get(self, v, default=None):
        path = os.path.join(SERVED_DIR, os.path.basename(v)) if v else ""
        return open(path).read() if v and os.path.exists(path) else default


SERVED = Served()
SENT = {}  # each map file as last synced into Studio
BUILT = [None]  # the map text Studio last built (Map.update builds only what changed since)
PARTS = ("colours", "areas", "tiles", "objects", "fixed", "rows")


def version(text):
    return hashlib.sha1(text.encode()).hexdigest()[:12]


def dump(m):
    """A .map as the editor writes it (dumpMap in editor.html): one row, tile or object a line."""
    j = lambda v: json.dumps(v, separators=(",", ":"), ensure_ascii=False)
    head = {k: v for k, v in m.items() if k not in PARTS}
    out = [j(head)[:-1] + ",", '"colours": {']
    out.append(",\n".join('  "%s": %s' % (k, j(m["colours"][k])) for k in sorted(m["colours"])))
    out.append("},")
    for k in ("areas", "tiles", "objects"):
        out += ['"%s": [' % k, ",\n".join("  " + j(v) for v in m[k]), "],"]
    out.append('"fixed": {')
    items = list(m["fixed"].items())
    for n, (k, v) in enumerate(items):
        comma = "," if n < len(items) - 1 else ""
        if isinstance(v, list):
            out += ['  "%s": [' % k, ",\n".join("    " + j(x) for x in v), "  ]" + comma]
        else:
            out.append('  "%s": %s%s' % (k, j(v), comma))
    out += ["},", '"rows": [', ",\n".join('"%s"' % r for r in m["rows"]), "]}"]
    return "\n".join(out) + "\n"


def merge(base, mine, theirs):
    """Three-way: what the tab changed from the version it opened wins; everything else
    (QM's other tabs, Claude's edits to the file) stays. Rows merge cell by cell."""
    b, m, t = json.loads(base), json.loads(mine), json.loads(theirs)
    if b.get("size") != t.get("size") or b.get("size") != m.get("size"):
        # (the map grew, in the tab or in the file: all three laid into a grid holding both)
        cell = m["cell"]
        x0 = min(m["origin"][0], t["origin"][0])
        z0 = min(m["origin"][1], t["origin"][1])
        x1 = max(d["origin"][0] + d["size"][0] * cell for d in (m, t))
        z1 = max(d["origin"][1] + d["size"][1] * cell for d in (m, t))
        frame = ([x0, z0], [(x1 - x0) // cell, (z1 - z0) // cell])
        grown = [reframe(d, *frame) for d in (b, m, t)]
        if None in grown or cell != t["cell"]:
            return mine  # (a different layout: the tab's map as it is)
        b, m, t = grown
        for d in (b, m):
            d["origin"], d["size"] = t["origin"], t["size"]
    out = dict(t)
    for k in m:
        if k == "rows":
            # (cell by cell only where both sides changed a row: QM, Nov 6, saves in a second)
            out["rows"] = [rt if rm == rb else rm if rt == rb else
                           "".join(cm if cm != cb else ct for cm, cb, ct in zip(rm, rb, rt))
                           for rm, rb, rt in zip(m["rows"], b["rows"], t["rows"])]
        elif k == "saved" or m[k] != b.get(k):
            out[k] = m[k]
    return dump(out)


def keep_tops(mine, theirs):
    m, t = json.loads(mine), json.loads(theirs)
    tops = {x["id"]: x["top"] for x in t["tiles"]}
    if all(x.get("top") == tops.get(x["id"], x.get("top")) for x in m["tiles"]):
        return mine
    for x in m["tiles"]:
        x["top"] = tops.get(x["id"], x["top"])
    return dump(m)


class StudioLink:
    """One StudioMCP kept open for every save (QM, Nov 6: starting it took ~2 s a save), as
    tools/studio/lu.py talks to it. Only with STUDIO (the place's studio id) set; lu.py otherwise."""
    MCP = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"

    def __init__(self, sid):
        self.sid, self.p, self.n, self.lock = sid, None, 10, threading.Lock()

    def _send(self, m):
        self.p.stdin.write(json.dumps(m) + "\n")
        self.p.stdin.flush()

    def _call(self, name, args, timeout=300):
        self.n += 1
        i = self.n
        self._send({"jsonrpc": "2.0", "id": i, "method": "tools/call", "params": {"name": name, "arguments": args}})
        end = time.time() + timeout
        while True:
            if not select.select([self.p.stdout], [], [], max(0, end - time.time()))[0]:
                raise TimeoutError("Studio didn't answer")
            line = self.p.stdout.readline()
            if not line:
                raise EOFError("StudioMCP closed")
            m = json.loads(line)
            if m.get("id") == i:
                break
        outs = [c.get("text", str(c)) for c in m.get("result", {}).get("content", [])]
        return "\n".join(outs) + (str(m["error"]) if "error" in m else "")

    def _start(self):
        self.p = subprocess.Popen([self.MCP, "--stdio"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL, text=True)
        self._send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
            "protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "mapeditor", "version": "1"}}})
        while json.loads(self.p.stdout.readline()).get("id") != 1:
            pass
        self._send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        end = time.time() + 8
        while time.time() < end:
            try:
                if any(x.get("id") == self.sid for x in json.loads(self._call("list_roblox_studios", {}, 5)).get("studios", [])):
                    return
            except (ValueError, TimeoutError):
                pass
            time.sleep(0.1)
        raise TimeoutError("Studio %s isn't listed by StudioMCP (is it open?)" % self.sid)

    def execute(self, code):
        """(ok, output) as run(lu.py) gives them."""
        with self.lock:
            for attempt in (0, 1):
                try:
                    if not self.p or self.p.poll() is not None:
                        self._start()
                    return True, self._call("execute_luau", {"code": code, "datamodel_type": "Edit", "studio_id": self.sid})
                except (OSError, EOFError, TimeoutError, ValueError) as e:
                    sys.stderr.write("studio link: %s\n" % e)
                    if self.p:
                        self.p.kill()
                    self.p = None
                    if attempt:
                        return False, str(e)


LINK = StudioLink(os.environ["STUDIO"]) if os.environ.get("STUDIO") else None


def run(*args):
    r = subprocess.run(["python3", *args], cwd=ROOT, capture_output=True, text=True, timeout=300)
    return r.returncode == 0, (r.stdout + r.stderr).strip()


def changed_areas(old, new):
    """The areas whose floors or walls a save changed, or None when it needs the whole map
    built again (QM, Nov 6: one object added shouldn't rebuild everything). [] is objects only."""
    try:
        o, n = json.loads(old), json.loads(new)
    except ValueError:
        return None
    for k in ("cell", "origin", "size", "areas", "colours", "fixed"):
        if o.get(k) != n.get(k):
            return None
    ot = {t["id"]: t for t in o["tiles"]}
    nt = {t["id"]: t for t in n["tiles"]}
    ids = {i for i in set(ot) | set(nt) if ot.get(i) != nt.get(i)}
    if [t["id"] for t in o["tiles"]] != [t["id"] for t in n["tiles"]]:
        ids |= set(nt)  # (reordered: every area's tile numbers may have moved)
    for ro, rn in zip(o["rows"], n["rows"]):
        if ro != rn:
            ids |= {a for a, b in zip(ro, rn) if a != b} | {b for a, b in zip(ro, rn) if a != b}
    return sorted({(nt.get(i) or ot.get(i))["area"] for i in ids if i in nt or i in ot})


def to_studio(areas=None, since=None):
    """Syncs src/ into Studio and rebuilds workspace.Map there (only `areas`' floors and the
    objects, if given); a message saying how it went."""
    load = os.path.join(tempfile.gettempdir(), "mapeditor_load.luau")
    t0 = time.time()
    # (only the files that changed since the last good save: usually just MapData)
    texts = {f: open(os.path.join(ROOT, f)).read() for f in MAP_FILES}
    files = [f for f in MAP_FILES if SENT.get(f) != texts[f]] or [MAP_FILES[0]]
    ok, out = run(os.path.join(STUDIO, "mkload.py"), load, *files)
    if ok:
        # (the sync and the rebuild in one call to Studio: QM, Nov 6, a save in about a second)
        sync = open(load).read()
        rebuild = open(os.path.join(STUDIO, "rebuild.luau")).read()
        head = "local AREAS = " + ("nil" if areas is None else "{" + ", ".join(json.dumps(a) for a in areas) + "}") + "\n"
        open(load, "w").write(head + "local loaded = (function()\n" + sync + "\nend)()\n"
                              + "return loaded .. \"\\n\" .. (function()\n" + rebuild + "\nend)()\n")
        ok, out = LINK.execute(open(load).read()) if LINK else run(os.path.join(STUDIO, "lu.py"), load, "Edit")
    if "Play mode" in out:  # (Studio's answer while a play test runs: no Edit datamodel to load into)
        return "Saved. Studio is in Play: stop it, then press Save to game again."
    SENT.clear()
    if ok and "loaded" in out and (out.splitlines() or [""])[-1].startswith("baked"):
        SENT.update(texts)
    took = " (%.1f s, %.1f in Studio)" % (time.time() - (since or t0), time.time() - t0)
    if not ok or "loaded" not in out:
        return "Saved, but Studio didn't take it (is it open?). Sync and press Map > Rebuild there."
    last = out.splitlines()[-1] if out else ""
    if ok and last.startswith("baked"):
        return "Saved and rebuilt in Studio" + took + ". Save the place there to keep it."
    if "playing" in last:
        return "Saved. Studio is in Play: stop it and press Map > Rebuild."
    return "Saved, but the rebuild in Studio failed: " + last[:200]


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
            self.send(200, open(os.path.join(HERE, "MapEditor.html"), "rb").read(), "text/html; charset=utf-8")
        elif path == "/world.map":
            text = open(WORLD).read()
            SERVED[version(text)] = text
            self.send(200, text, "application/json", {"X-Map-Version": version(text)})
        else:
            self.send(404, "not found")

    def do_POST(self):
        if self.path != "/save":
            return self.send(404, "not found")
        since = time.time()
        text = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode()
        try:
            json.loads(text)
        except ValueError:
            return self.send(400, "That isn't a .map.")
        current = open(WORLD).read()
        base = SERVED.get(self.headers.get("X-Map-Base", ""))
        merged = base is not None and base != current
        if merged:
            text = merge(base, text, current)
        elif base is None:
            # (a tab opened before saves were versioned: keep the file's tile heights, which
            # Claude may have changed since that tab opened)
            text = keep_tops(text, current)
        # (against what Studio last built, not the file: a save that didn't reach Studio
        # still gets built; the first save after starting this server builds everything)
        areas = changed_areas(BUILT[0], text) if BUILT[0] else None
        tmp = WORLD + ".tmp"
        open(tmp, "w").write(text)
        os.replace(tmp, WORLD)
        SERVED[version(text)] = text
        ok, out = run(os.path.join(ROOT, "tools", "map_bake.py"))
        if not ok:
            return self.send(500, "Saved maps/world.map, but baking it failed: " + out[-300:])
        # (merged: the tab reloads the file, so it carries the other changes from now on)
        said = to_studio(areas, since)
        BUILT[0] = text if said.startswith("Saved and rebuilt") else None
        self.send(200, said, headers={"X-Map-Version": version(text), "X-Map-Merged": "1" if merged else "0"})

    def log_message(self, fmt, *args):
        sys.stderr.write("%s\n" % (fmt % args))


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
    print("map editor on http://localhost:%d" % port)
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
