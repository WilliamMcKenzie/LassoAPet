"""The map editor's .map (QM, Nov 6), as maps/world1.map has it. JSON, a tile, object or row
a line so diffs read well:

  format, version, world, cell (4 studs), origin [x, z] (the north-west corner: the course
  runs to -z, north), size [cols, rows], saved
  borders  { Desert: z, ..., End: z }: where each biome starts, End the finish line
           (World.Borders, Shared/Borders)
  colours  { "<World colour attribute>": [r, g, b] }: the colours changed from Config's
           (GroundA, DesertWallB, CliffA... as WorldColors reads them), set on World
  tiles    { id, key, top, wall?, cap?, material?, nocollide? }: key is the part's name, which
           picks its colour in each biome (Ground, Dirt, Grass, Wall, Cliff...); a wall rises
           from below the floor to top, its last studs the cap's
  objects  { id, group (Obstacles, Decor, Nests), item, x, z, y (above the floor), yaw, scale }
  rows     north to south, one character a cell: a tile's id, "." for nothing
"""

import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
MAP = os.path.join(ROOT, "maps", "world1.map")
PALETTE = os.path.join(ROOT, "maps", "world1.palette.json")
PARTS = ("borders", "colours", "tiles", "objects", "rows")
# a tile's letter in the rows (the editor's TILE_IDS): no digits, quotes or backslashes
IDS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&()*+-/:;<=>?@^_`{|}~ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"


def dump(m):
    """As the editor writes it (dumpMap in editor.html)."""
    j = lambda v: json.dumps(v, separators=(",", ":"), ensure_ascii=False)
    head = {k: v for k, v in m.items() if k not in PARTS}
    out = [j(head)[:-1] + ","]
    for k in ("borders", "colours"):
        out.append('"%s": {' % k)
        out.append(",\n".join('  "%s": %s' % (n, j(m.get(k, {})[n])) for n in sorted(m.get(k, {}))))
        out.append("},")
    for k in ("tiles", "objects"):
        out += ['"%s": [' % k, ",\n".join("  " + j(v) for v in m[k]), "],"]
    out += ['"rows": [', ",\n".join('"%s"' % r for r in m["rows"]), "]}"]
    return "\n".join(out) + "\n"


def rle(row, index):
    """A row as Studio takes it: "tile:run,..." (tile numbers from 1, 0 for nothing)."""
    out, last, run = [], None, 0
    for ch in (index.get(c, 0) for c in row):
        if ch == last:
            run += 1
        else:
            if last is not None:
                out.append("%d:%d" % (last, run))
            last, run = ch, 1
    if last is not None:
        out.append("%d:%d" % (last, run))
    return ",".join(out)


def unrle(text, ids):
    out = []
    for tok in text.split(","):
        k, n = tok.split(":")
        out.append(("." if k == "0" else ids[int(k) - 1]) * int(n))
    return "".join(out)
