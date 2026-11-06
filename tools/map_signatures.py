"""Gives each biome past the Lava its own look, so none repeats another's gimmick (QM, Nov 6:
"make sure biomes aren't repetitive"), straight into maps/world.map, with each biome's own
Fight to Steal an Egg props:

  Dungeon  (keeps its split route) a slate path down the middle; a hallway: a narrower stretch
           lined both sides with wall torches and candelabras; bones by the walls
  Forest   (its split route taken out) palm islands: raised stone islands out in the lane with
           palms on them (tier-3 obstacles: the herd swerves round), boulders by the walls
  Castle   a carpet runway down the middle; a colonnade of three arches in a row, candelabras
           between them; candles by the walls
  Ocean    big mixed coral reefs out in the middle on stone patches; kelp forests along the walls

Run: python3 tools/map_signatures.py   (replaces whatever objects those four biomes have, so run
     it before placing things there by hand), then save in the editor or tools/map_bake.py.
"""
import json
import math
import os
import random
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
WORLD = os.path.join(ROOT, "maps", "world.map")
sys.path.insert(0, os.path.join(HERE, "mapeditor"))
from serve import dump  # noqa: E402

AREAS = ["Dungeon", "Forest", "Castle", "Ocean"]
UNSPLIT = "a1542427"  # a commit from before the Magic Woods had a split route (its rows put back)


def main():
    d = json.load(open(WORLD))
    cell = d["cell"]
    ox, oz = d["origin"]
    cols, nrows = d["size"]
    rows = [list(r) for r in d["rows"]]
    T = {t["id"]: t for t in d["tiles"]}
    B = {a["name"]: (a["bounds"][1], a["bounds"][3]) for a in d["areas"] if a.get("bounds")}

    def inside(o, name):
        near, far = B[name]
        return far <= o.get("z", 0) < near

    d["objects"] = [o for o in d["objects"] if not any(inside(o, n) for n in AREAS)]

    def row_of(z):
        return int((z - oz) // cell)

    def x_of(c):
        return ox + (c + 0.5) * cell

    def z_of(r):
        return oz + (r + 0.5) * cell

    def is_floor(ch):
        t = T.get(ch)
        return t is not None and not t.get("wall")

    def band(r):
        row, mid = rows[r], cols // 2
        if not is_floor(row[mid]):
            return None
        a = b = mid
        while a > 0 and is_floor(row[a - 1]):
            a -= 1
        while b < cols - 1 and is_floor(row[b + 1]):
            b += 1
        return ox + a * cell, ox + (b + 1) * cell

    def edge(z):
        b = band(row_of(z))
        return min(-b[0], b[1]) if b else None

    def tile(area, key=None, wall=False, top=None):
        for t in d["tiles"]:
            if t["area"] == area and bool(t.get("wall")) == wall and (key is None or t["key"] == key) and (top is None or t["top"] == top):
                return t["id"]
        raise KeyError((area, key, wall, top))

    def paint(test, ch, base, z0, z1):  # cells of tile `base` between z1..z0 where test(x, z)
        for r in range(max(0, row_of(z1)), min(nrows, row_of(z0) + 1)):
            z = z_of(r)
            for c in range(cols):
                if rows[r][c] == base and test(x_of(c), z):
                    rows[r][c] = ch

    def prop(item, x, z, scale, name, rng, **extra):
        o = {"type": "Prop", "item": item, "x": round(x), "z": round(z), "yaw": rng.randrange(360), "scale": round(scale, 2), "style": name}
        o.update(extra)
        d["objects"].append(o)

    report = []

    # ---- Dungeon: slate path, a torch-and-candelabra hallway, bones -----------------------------
    name = "Dungeon"
    near, far = B[name]
    rng = random.Random("sig Dungeon")
    stone, slate = tile(name, "DungeonStone"), tile(name, "DungeonSlate")
    paint(lambda x, z: abs(x) <= 16, slate, stone, near - 4, far + 4)
    # the hallway: the narrowest 480 studs outside the split, lined both sides every 48 studs
    best = None
    for z in range(int(near - 120), int(far + 600), -16):
        widths = [edge(z - k) for k in range(0, 480, 32)]
        if all(widths):
            w = max(widths)
            if best is None or w < best[1]:
                best = (z, w)
    if best:
        z0, _ = best
        for k, zz in enumerate(range(int(z0), int(z0 - 480), -48)):
            e = edge(zz)
            for s in (-1, 1):
                if k % 2 == 0:
                    prop("WallTorch", s * (e - 4), zz, 3, name, rng)
                else:
                    prop("Candelabra", s * (e - 16), zz, 4.5, name, rng)
    for _ in range(9):
        zz = rng.uniform(far + 100, near - 100)
        e = edge(zz)
        if e:
            prop(rng.choice(["Femur", "Femur", "Ribcage", "Candles"]), rng.choice((-1, 1)) * (e - rng.uniform(14, 40)), zz, rng.uniform(2, 4), name, rng)
    for s in (-1, 1):
        e = edge(far + 140)
        if e:
            prop("Monolith", s * (e - 24), far + 140, 6, name, rng)
    report.append("Dungeon: slate path, a hallway of wall torches and candelabras at z %d..%d, bones" % (best[0], best[0] - 480) if best else "Dungeon: slate path, bones")

    # ---- Forest: split out, palm islands in the lane ---------------------------------------------
    name = "Forest"
    near, far = B[name]
    rng = random.Random("sig Forest")
    old = json.loads(subprocess.check_output(["git", "show", UNSPLIT + ":maps/world.map"], cwd=ROOT))
    if old["origin"] == d["origin"] and old["size"] == d["size"]:
        for r in range(row_of(far), row_of(near) + 1):
            rows[r] = list(old["rows"][r])
    grass, stones = tile(name, "ForestGrass"), tile(name, "ForestStone")
    islands = 0
    for frac in (0.18, 0.4, 0.62, 0.84):
        zc = near - (near - far) * frac
        e = edge(zc) or 160
        cx = rng.choice((-1, 1)) * rng.uniform(0, e * 0.35)
        rx, rz = rng.uniform(30, 44), rng.uniform(44, 70)  # (lanes either side stay 100+ wide)
        paint(lambda x, z, cx=cx, cz=zc, rx=rx, rz=rz: ((x - cx) / rx) ** 2 + ((z - cz) / rz) ** 2 <= 1, stones, grass, zc + rz, zc - rz)
        prop("PalmTree", cx, zc, rng.uniform(5, 8), name, rng, obstacle=3)
        for _ in range(rng.randint(1, 2)):
            prop("PalmTreeSmall", cx + rng.uniform(-rx * 0.5, rx * 0.5), zc + rng.uniform(-rz * 0.6, rz * 0.6), rng.uniform(3, 5), name, rng, obstacle=3)
        islands += 1
    for _ in range(7):
        zz = rng.uniform(far + 100, near - 100)
        e = edge(zz)
        if e:
            prop(rng.choice(["Boulders", "Boulders", "Monolith"]), rng.choice((-1, 1)) * (e - rng.uniform(16, 36)), zz, rng.uniform(4, 8), name, rng)
    e = edge(far + 160) or 160
    prop("RuinPillar", e - 30, far + 160, 6, name, rng)
    prop("RuinPillarBroken", -e + 30, far + 200, 6, name, rng)
    report.append("Magic Woods: split taken out, %d palm islands (palms are tier-3 obstacles), boulders by the walls" % islands)

    # ---- Castle: carpet runway, a colonnade of three arches, candelabras -------------------------
    name = "Castle"
    near, far = B[name]
    rng = random.Random("sig Castle")
    floor, carpet = tile(name, "CastleFloor"), tile(name, "CastleCarpet")
    paint(lambda x, z: abs(x) <= 24, carpet, floor, near - 4, far + 4)
    zc = near - (near - far) * 0.45
    for k in (-1, 0, 1):
        za = zc + k * 140
        e = edge(za) or 150
        px = e + 124  # (as QM's Meadow gate: pillars 124 studs past the floor's edge, arch scale 7)
        f = px / 204
        for s in (-1, 1):
            d["objects"].append({"type": "Pillar", "style": name, "kind": "joint", "x": round(s * px), "z": round(za), "size": 14, "height": 36, "scale": 7})
        d["objects"].append({"type": "Arch", "style": name, "x": 0, "z": round(za), "scale": round(7 * f, 2), "y": round(-48 * f)})
        if k < 1:
            for s in (-1, 1):
                prop("Candelabra", s * (e - 24), za - 70, 5, name, rng)
    for _ in range(10):
        zz = rng.uniform(far + 100, near - 100)
        if abs(zz - zc) < 260:
            continue
        e = edge(zz)
        if e:
            prop(rng.choice(["Candles", "Candles", "Boulders", "Femur", "Ribcage"]), rng.choice((-1, 1)) * (e - rng.uniform(10, 30)), zz, rng.uniform(2, 4), name, rng)
    for s in (-1, 1):
        e = edge(far + 120)
        if e:
            prop("Monolith", s * (e - 24), far + 120, 6, name, rng)
    report.append("Red Dungeon: carpet runway, a colonnade of three arches at z %d with candelabras between" % zc)

    # ---- Ocean: coral reefs in the middle, kelp forests on the edges -----------------------------
    name = "Ocean"
    near, far = B[name]
    rng = random.Random("sig Ocean")
    sand, rock = tile(name, "OceanSand"), tile(name, "OceanStone")
    z, reefs = near - 260, 0
    while z > far + 260:
        e = edge(z) or 140
        cx = rng.uniform(-e * 0.3, e * 0.3)
        rx, rz = rng.uniform(40, 64), rng.uniform(70, 120)
        paint(lambda x, zz, cx=cx, cz=z, rx=rx, rz=rz: ((x - cx) / rx) ** 2 + ((zz - cz) / rz) ** 2 <= 1, rock, sand, z + rz, z - rz)
        for _ in range(rng.randint(2, 3)):
            prop("Coral", cx + rng.uniform(-rx * 0.5, rx * 0.5), z + rng.uniform(-rz * 0.5, rz * 0.5), rng.uniform(4, 8), name, rng)
        for _ in range(rng.randint(3, 4)):
            prop(rng.choice(["Starfish", "Sponges", "Sponges", "Kelp"]), cx + rng.uniform(-rx * 0.8, rx * 0.8), z + rng.uniform(-rz * 0.8, rz * 0.8), rng.uniform(2, 3.5), name, rng)
        reefs += 1
        z -= rng.uniform(420, 560)
    z, side = near - 100, 1
    while z > far + 100:
        e = edge(z) or 140
        for _ in range(rng.randint(5, 8)):
            prop("Kelp", side * (e - rng.uniform(6, 44)), z + rng.uniform(-50, 50), rng.uniform(3, 7), name, rng)
        side = -side
        z -= rng.uniform(140, 200)
    for s in (-1, 1):
        prop("Boulders", s * ((edge(far + 140) or 140) - 24), far + 140, 7, name, rng)
    report.append("Ocean: %d coral reefs on stone out in the middle, kelp forests along the walls" % reefs)

    d["rows"] = ["".join(r) for r in rows]
    open(WORLD, "w").write(dump(d))
    print("\n".join(report))


if __name__ == "__main__":
    main()
