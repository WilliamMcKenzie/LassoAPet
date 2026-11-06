"""Reads World 1's course out of the open Studio place into the map editor's files
(QM, Nov 6), with tools/mapeditor/studio/export.luau:

    python3 tools/mapeditor/export.py            maps/world1.map and maps/world1.palette.json
    python3 tools/mapeditor/export.py palette    just the palette (Config's colours, borders)

Run it when the place was changed by hand in Studio (the .map is otherwise the source:
the editor's Save builds it into the place). Studio must be in Edit mode.
"""

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
from studio import run_luau  # noqa: E402
from mapfile import dump, unrle, IDS, MAP, PALETTE  # noqa: E402


def export(mode="all"):
    code = 'local MODE = "%s"\n' % mode + open(os.path.join(HERE, "studio", "export.luau")).read()
    out = run_luau(code, "Edit", chunked=True)
    try:
        data = json.loads(out)
    except ValueError:
        raise SystemExit("Studio said: " + out[:500])
    old = json.load(open(PALETTE)) if os.path.exists(PALETTE) else {}
    palette = {"palette": data["palette"], "items": data.get("items", old.get("items", []))}
    open(PALETTE, "w").write(json.dumps(palette, separators=(",", ":")) + "\n")
    print("wrote", os.path.relpath(PALETTE, ROOT))
    if mode == "palette":
        return
    m = data["map"]
    assert len(m["tiles"]) <= len(IDS), "more tiles than the format has letters for"
    for i, t in enumerate(m["tiles"]):
        t["id"] = IDS[i]
    m["rows"] = [unrle(r, IDS) for r in m.pop("rle")]
    m = {"format": "LassoAPet.map", "version": 1, "world": 1, **m, "colours": {}}
    if os.path.exists(MAP):
        m["colours"] = json.load(open(MAP)).get("colours", {})
    open(MAP, "w").write(dump(m))
    print("wrote", os.path.relpath(MAP, ROOT), "(%dx%d cells, %d tiles, %d objects)" % (*m["size"], len(m["tiles"]), len(m["objects"])))


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else "all")
