"""Paints tall background blocks out in the fog beside the course, as QM painted by hand
round the Base and Meadow (Nov 6): blocks of each biome's wall, 120 to 320 studs tall,
scattered a few hundred studs apart past the ledges on both sides, so it looks like
there's more world just beyond sight.

Run: python3 tools/map_backdrop.py [area ...]   (default: every biome but Base and Meadow)
     then python3 tools/map_bake.py. Only paints empty cells, so painted things stay;
     running it again on an area adds more blocks, so erase that area's first.
"""
import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
WORLD = os.path.join(HERE, "..", "maps", "world.map")
sys.path.insert(0, os.path.join(HERE, "mapeditor"))
from serve import dump  # noqa: E402

TILE_IDS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$%&()*+-/:;<=>?@^_`{|}~',["
HEIGHTS = [(320, 0.45), (220, 0.35), (120, 0.2)]  # (top, weight): mostly tall, as QM's
GAP = (250, 520)  # studs along z between one block and the next on a side
WIDE = (60, 230)  # across (x)
LONG = (80, 360)  # along (z)
OUT = (40, 260)  # how far past the ledges' outer edge a block starts


def main(only):
    d = json.load(open(WORLD))
    cell = d["cell"]
    ox, oz = d["origin"]
    cols, nrows = d["size"]
    rows = [list(r) for r in d["rows"]]
    tiles = d["tiles"]
    used = {t["id"] for t in tiles}
    free = [c for c in TILE_IDS if c not in used]

    def wall_tile(area, top):
        for t in tiles:
            if t["area"] == area and t.get("wall") and t["top"] == top:
                return t["id"]
        base = next(t for t in tiles if t["area"] == area and t.get("wall"))
        if not free:
            sys.exit("no tile ids left for a %s wall at %d" % (area, top))
        t = {"id": free.pop(0), "area": area, "key": base["key"], "cap": base.get("cap", base["key"]), "top": top, "wall": True}
        tiles.append(t)
        return t["id"]

    def band(r):  # the course and its ledges on row r: (first col, last col), or None
        row, mid = rows[r], cols // 2
        if row[mid] == ".":
            return None
        a = b = mid
        while a > 0 and row[a - 1] != ".":
            a -= 1
        while b < cols - 1 and row[b + 1] != ".":
            b += 1
        return a, b

    def paint(x0, x1, z0, z1, ch):  # studs, x0 < x1, z0 < z1; empty cells only
        n = 0
        for r in range(max(0, int((z0 - oz) // cell)), min(nrows, int((z1 - oz) // cell))):
            for c in range(max(0, int((x0 - ox) // cell)), min(cols, int((x1 - ox) // cell))):
                if rows[r][c] == ".":
                    rows[r][c] = ch
                    n += 1
        return n

    snap = lambda v: int(round(v / cell)) * cell  # noqa: E731
    report = []
    for area in d["areas"]:
        name = area["name"]
        if name in ("Base", "Meadow") or (only and name not in only) or not area.get("bounds"):
            continue
        rng = random.Random(name)  # (the same blocks every run)
        near, far = area["bounds"][1], area["bounds"][3]
        blocks = cells = 0
        for side in (-1, 1):
            z = near - rng.uniform(40, GAP[0])
            while z > far + LONG[0]:
                length = rng.uniform(*LONG)
                z0, z1 = max(far + 20, z - length), z
                # the ledges' outer edge on this side, over the block's rows
                edge = 0
                for r in range(int((z0 - oz) // cell), int((z1 - oz) // cell)):
                    b = band(r) if 0 <= r < nrows else None
                    if b:
                        edge = max(edge, (ox + (b[1] + 1) * cell) if side > 0 else -(ox + b[0] * cell))
                top = rng.choices([h for h, _ in HEIGHTS], [w for _, w in HEIGHTS])[0]
                out = rng.uniform(*OUT) * (0.5 if top == 120 else 1)  # (the lower ones nearer)
                inner = edge + out
                outer = min(inner + rng.uniform(*WIDE), -ox - cell)
                if outer - inner >= 40:
                    x0, x1 = (inner, outer) if side > 0 else (-outer, -inner)
                    n = paint(snap(x0), snap(x1), snap(z0), snap(z1), wall_tile(name, top))
                    # sometimes a lower block stepped in front of a tall one
                    if top == 320 and rng.random() < 0.35:
                        w = rng.uniform(24, 60)
                        zz0, zz1 = z0 + rng.uniform(0, length * 0.3), z1 - rng.uniform(0, length * 0.3)
                        fx0, fx1 = (inner - w, inner) if side > 0 else (-inner, -inner + w)
                        n += paint(snap(fx0), snap(fx1), snap(zz0), snap(zz1), wall_tile(name, 220))
                    blocks += 1
                    cells += n
                z -= length + rng.uniform(*GAP)
        report.append("%s: %d blocks, %d cells" % (name, blocks, cells))

    d["rows"] = ["".join(r) for r in rows]
    open(WORLD, "w").write(dump(d))
    print("\n".join(report))
    print("tile ids left:", len(free))


if __name__ == "__main__":
    main(set(sys.argv[1:]))
