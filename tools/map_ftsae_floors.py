"""Floor patterns in the style QM painted in Fight to Steal an Egg (Nov 6: "look at the floor
tile patterns I did in FTSAE ... for the ocean specifically"), for Lasso's biomes past the Lava,
fitted to the long corridor, straight into maps/world.map:

  Dungeon  a slate frame along both walls and round the split's island, organic slate cracks
           over the middle, slate-rimmed square pits (FTSAE's magma pools, rimmed the same)
  Forest   Greek-key stone patterns round each palm island, square stone spirals by the walls
  Castle   a stone double border along both walls, two big carpet squares with crenellated
           edges on the runway, clusters of stone squares like ruins by the walls
  Ocean    FTSAE's Ocean: open sand, blocky stone outcrops raised 6 studs (alternating near
           one wall, the other, and out in the middle), boulders, coral, kelp and starfish
           crowding each one, lone kelp and coral scattered over the sand

Adds two tiles: Ocean stone at +6 ("["), and Castle stone ("]", DungeonStone's colours).
Run: python3 tools/map_ftsae_floors.py   then save in the editor or tools/map_bake.py.
Only touches these four biomes' floors (never walls) and replaces the Ocean's objects.
"""
import json
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
WORLD = os.path.join(HERE, "..", "maps", "world.map")
sys.path.insert(0, os.path.join(HERE, "mapeditor"))
from serve import dump  # noqa: E402


def main():
    d = json.load(open(WORLD))
    cell = d["cell"]
    ox, oz = d["origin"]
    cols, nrows = d["size"]
    rows = [list(r) for r in d["rows"]]
    B = {a["name"]: (a["bounds"][1], a["bounds"][3]) for a in d["areas"] if a.get("bounds")}

    def add_tile(t):
        if not any(x["id"] == t["id"] for x in d["tiles"]):
            assert not any(x["area"] == t["area"] and x["key"] == t["key"] and x["top"] == t["top"] for x in d["tiles"])
            d["tiles"].append(t)
        return t["id"]

    T = {}

    def refresh():
        T.clear()
        T.update({t["id"]: t for t in d["tiles"]})

    ocean_rock = add_tile({"id": "[", "area": "Ocean", "key": "OceanStone", "top": 6})
    castle_stone = add_tile({"id": "]", "area": "Castle", "key": "DungeonStone", "top": 0.5})
    refresh()

    def tile(area, key, top=None):
        for t in d["tiles"]:
            if t["area"] == area and t["key"] == key and not t.get("wall") and (top is None or t["top"] == top):
                return t["id"]
        raise KeyError((area, key, top))

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

    def wall_dist(r, c):  # studs to the nearest wall cell along the row, or 1e9
        best = 1e9
        for dc in range(1, 12):
            for cc in (c - dc, c + dc):
                if 0 <= cc < cols and T.get(rows[r][cc], {}).get("wall"):
                    return dc * cell - cell / 2
        return best

    def each(area, fn):  # fn(r, c, x, z) over that biome's rows
        near, far = B[area]
        for r in range(row_of(far), row_of(near)):
            z = z_of(r)
            for c in range(cols):
                fn(r, c, x_of(c), z)

    def rect(ch, base, x0, x1, z0, z1):  # cells of `base` inside the box get ch
        for r in range(row_of(min(z0, z1)), row_of(max(z0, z1) - 0.01) + 1):
            for c in range(int((min(x0, x1) - ox) // cell), int((max(x0, x1) - 0.01 - ox) // cell) + 1):
                if 0 <= r < nrows and 0 <= c < cols and rows[r][c] in base:
                    rows[r][c] = ch

    def edge(z):
        b = band(row_of(z))
        return min(-b[0], b[1]) if b else None

    report = []

    # ---- Dungeon -----------------------------------------------------------------------------
    stone, slate = tile("Dungeon", "DungeonStone"), tile("Dungeon", "DungeonSlate")

    def dungeon(r, c, x, z):
        ch = rows[r][c]
        if ch not in (stone, slate):
            return
        dist = wall_dist(r, c)
        n = math.sin(x / 23 + z / 61) + math.sin(z / 29 - x / 47) + math.sin((x + 2 * z) / 37)
        rows[r][c] = slate if dist <= 12 or (dist > 28 and n > 1.35) else stone

    each("Dungeon", dungeon)
    near, far = B["Dungeon"]
    rng = random.Random("ftsae Dungeon")
    pits = 0
    for frac in (0.12, 0.3, 0.72, 0.9):
        z = near - (near - far) * frac
        e = edge(z) or 140
        x = rng.choice((-1, 1)) * (e - 56)
        rect(slate, (stone, slate), x - 24, x + 24, z - 24, z + 24)  # the rim
        rect(stone, (slate,), x - 14, x + 14, z - 14, z + 14)  # the pit's floor
        pits += 1
    report.append("Dungeon: slate frame, slate cracks, %d slate-rimmed pits" % pits)

    # ---- Forest -------------------------------------------------------------------------------
    grass, fstone = tile("Forest", "ForestGrass"), tile("Forest", "ForestStone")
    near, far = B["Forest"]
    islands = [o for o in d["objects"] if o.get("item") == "PalmTree" and o.get("obstacle") and far <= o["z"] < near]

    def key_ring(cx, cz, h):  # a Greek-key ring: a square line, opened on two sides, hooked in at its corners
        w = 4
        for s in (-1, 1):
            rect(fstone, (grass,), cx - h, cx + h, cz + s * h - w / 2, cz + s * h + w / 2)  # top/bottom
            rect(fstone, (grass,), cx + s * h - w / 2, cx + s * h + w / 2, cz - h, cz + h)  # sides
        for sx in (-1, 1):  # gaps in the sides, hooks at the corners
            rect(grass, (fstone,), cx + sx * h - w, cx + sx * h + w, cz - 10, cz + 10)
            for sz in (-1, 1):
                rect(fstone, (grass,), cx + sx * (h - 14) - w / 2, cx + sx * (h - 14) + w / 2, cz + sz * (h - 14), cz + sz * h)
                rect(fstone, (grass,), cx + sx * (h - 14), cx + sx * h, cz + sz * (h - 14) - w / 2, cz + sz * (h - 14) + w / 2)

    for o in islands:
        key_ring(o["x"], o["z"], 84)
    rng = random.Random("ftsae Forest")
    spirals = 0
    for frac in (0.08, 0.29, 0.51, 0.73, 0.95):
        z = near - (near - far) * frac
        e = edge(z) or 160
        x = (1 if spirals % 2 else -1) * (e - 40)
        for k, h in enumerate((28, 18, 8)):
            rect(fstone, (grass,), x - h, x + h, z + h - 2, z + h + 2)
            rect(fstone, (grass,), x - h - 2, x - h + 2, z - h, z + h)
            rect(fstone, (grass,), x - h, x + h - 8, z - h - 2, z - h + 2)
        spirals += 1
    report.append("Magic Woods: Greek-key rings round %d palm islands, %d stone spirals by the walls" % (len(islands), spirals))

    # ---- Castle -------------------------------------------------------------------------------
    floor, carpet = tile("Castle", "CastleFloor"), tile("Castle", "CastleCarpet")

    def castle(r, c, x, z):
        if rows[r][c] != floor:
            return
        dist = wall_dist(r, c)
        if 6 <= dist <= 10 or 18 <= dist <= 22:
            rows[r][c] = castle_stone

    each("Castle", castle)
    near, far = B["Castle"]
    for frac in (0.25, 0.68):
        z = near - (near - far) * frac
        rect(carpet, (floor, castle_stone), -60, 60, z - 60, z + 60)
        for k in range(-60, 60, 16):  # crenellations: notches out of every edge
            rect(carpet, (floor, castle_stone), k, k + 8, z + 60, z + 68)
            rect(carpet, (floor, castle_stone), k, k + 8, z - 68, z - 60)
            rect(carpet, (floor, castle_stone), 60, 68, z + k, z + k + 8)
            rect(carpet, (floor, castle_stone), -68, -60, z + k, z + k + 8)
    rng = random.Random("ftsae Castle")
    ruins = 0
    for frac in (0.08, 0.4, 0.55, 0.85, 0.95):
        z = near - (near - far) * frac
        e = edge(z) or 150
        s = 1 if ruins % 2 else -1
        x = s * (e - 52)
        rect(castle_stone, (floor,), x - 16, x + 16, z - 16, z + 16)
        for _ in range(rng.randint(4, 7)):
            h = rng.choice((4, 4, 6, 8))
            xx, zz = x + rng.uniform(-40, 40), z + rng.uniform(-44, 44)
            rect(castle_stone, (floor,), xx - h, xx + h, zz - h, zz + h)
        ruins += 1
    report.append("Red Dungeon: stone double border, two crenellated carpet squares, %d stone ruin clusters" % ruins)

    # ---- Ocean (FTSAE's composition) ----------------------------------------------------------
    sand = tile("Ocean", "OceanSand")
    low_rock = tile("Ocean", "OceanStone", 0.5)
    near, far = B["Ocean"]
    each("Ocean", lambda r, c, x, z: rows[r].__setitem__(c, sand) if rows[r][c] in (low_rock, ocean_rock) else None)
    d["objects"] = [o for o in d["objects"] if not (far <= o.get("z", 0) < near)]
    rng = random.Random("ftsae Ocean")

    def prop(item, x, z, scale):
        d["objects"].append({"type": "Prop", "item": item, "x": round(x), "z": round(z), "yaw": rng.randrange(360), "scale": round(scale, 2), "style": "Ocean"})

    z, k, outcrops = near - 180, 0, 0
    while z > far + 180:
        e = edge(z) or 140
        where = (-0.62, 0.62, -0.18, 0.55, -0.6, 0.15)[k % 6]
        cx = where * e
        w, l = rng.uniform(22, 34), rng.uniform(26, 42)
        rect(ocean_rock, (sand,), cx - w, cx + w, z - l, z + l)
        for _ in range(rng.randint(1, 3)):  # blocky lumps off its sides
            sx, sz = rng.choice((-1, 1)), rng.uniform(-l, l)
            ww, ll = rng.uniform(8, 16), rng.uniform(10, 20)
            rect(ocean_rock, (sand,), cx + sx * w - (ww if sx < 0 else 0), cx + sx * w + (ww if sx > 0 else 0), z + sz - ll, z + sz + ll)
        # the crowd on and round it, FTSAE-style: boulders, coral, kelp, starfish, sponges
        for _ in range(rng.randint(2, 3)):
            prop("Boulders", cx + rng.uniform(-w, w), z + rng.uniform(-l, l), rng.uniform(3, 6))
        for _ in range(rng.randint(2, 3)):
            prop("Coral", cx + rng.uniform(-w - 14, w + 14), z + rng.uniform(-l - 14, l + 14), rng.uniform(3, 6))
        for _ in range(rng.randint(1, 3)):
            prop("Kelp", cx + rng.choice((-1, 1)) * (w + rng.uniform(4, 16)), z + rng.uniform(-l, l), rng.uniform(3, 6))
        for _ in range(rng.randint(1, 3)):
            prop(rng.choice(["Starfish", "Starfish", "Sponges"]), cx + rng.uniform(-w, w), z + rng.uniform(-l, l), rng.uniform(2, 3))
        if rng.random() < 0.35:
            prop("Monolith", cx + rng.uniform(-w, w), z + rng.uniform(-l, l), rng.uniform(4, 6))
        outcrops += 1
        k += 1
        z -= rng.uniform(260, 360)
    z = near - 80
    while z > far + 60:  # lone kelp and coral over the sand
        e = edge(z) or 140
        prop(rng.choice(["Kelp", "Kelp", "Coral"]), rng.uniform(-e + 16, e - 16), z, rng.uniform(3, 5))
        z -= rng.uniform(70, 120)
    z = near - 120
    while z > far + 100:  # boulders by the walls
        e = edge(z) or 140
        prop("Boulders", rng.choice((-1, 1)) * (e - rng.uniform(8, 24)), z, rng.uniform(4, 8))
        z -= rng.uniform(260, 420)
    report.append("Ocean: %d stone outcrops raised 6 studs, each crowded with boulders, coral, kelp and starfish; lone kelp and coral over the sand" % outcrops)

    d["rows"] = ["".join(r) for r in rows]
    open(WORLD, "w").write(dump(d))
    print("\n".join(report))


if __name__ == "__main__":
    main()
