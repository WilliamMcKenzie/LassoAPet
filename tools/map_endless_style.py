"""Regrows the biomes past the Lava (Dungeon, Forest, Jurassic, Ocean) in the endless course's
style (QM, Nov 7: "do that tool to create a one time map"), straight into maps/world.map, so
they can be edited in the map editor afterwards like anything else:

  - the corridor's width wanders row by row (noise), with narrow gorges, blended in from the
    Lava's end and between biomes; Config.CourseProfile is rewritten to follow it
  - the floor is noise: each biome's own patterns (Dungeon: slab plazas, cracks and magma
    pits; Forest: moss, ponds and stone ruins; Jurassic: moss, mud, swamp pools and rock
    ridges; Ocean: bands of sand, trenches and stone outcrops), a winding path down the
    middle, and a ragged seam where one biome meets the next
  - the walls: a low ledge, then a tall cliff, each side, their widths and heights wandering
  - props on a jittered 40-stud grid, gathered in groves: obstacles out in the corridor,
    bigger ones on the ledges; a set piece at the middle of each biome

The noise is Shared/Endless's (same hash, value noise and fbm). It replaces those four
biomes' floors, walls and objects (props, pillars, arches); backdrop blocks out past the
walls stay. Run once: python3 tools/map_endless_style.py   then python3 tools/map_bake.py.
"""
import json
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
WORLD = os.path.join(ROOT, "maps", "world.map")
CONFIG = os.path.join(ROOT, "src", "shared", "Config.luau")
sys.path.insert(0, os.path.join(HERE, "mapeditor"))
from serve import dump  # noqa: E402

CELL = 4
TWO32 = 4294967296
SEED = 20261107

# ---- Shared/Endless's noise ------------------------------------------------------------


def mul(a, b):
    return (((a >> 16) * b % 65536) * 65536 + (a & 65535) * b) % TWO32


def mix(h):
    h ^= h >> 15
    h = mul(h, 0x2C1B3C6D)
    h ^= h >> 12
    h = mul(h, 0x297A2D39)
    return h ^ (h >> 15)


def hsh(a, b, c):
    h = mix((int(a) % TWO32) ^ SEED)
    h = mix(h ^ (int(b) % TWO32))
    return mix(h ^ (int(c) % TWO32)) / TWO32


def fade(t):
    return t * t * (3 - 2 * t)


def value2(x, z, salt):
    xi, zi = math.floor(x), math.floor(z)
    fx, fz = fade(x - xi), fade(z - zi)
    a, b = hsh(xi, zi, salt), hsh(xi + 1, zi, salt)
    c, d = hsh(xi, zi + 1, salt), hsh(xi + 1, zi + 1, salt)
    top = a + (b - a) * fx
    return top + (c + (d - c) * fx - top) * fz


def value1(t, salt):
    ti = math.floor(t)
    a, b = hsh(ti, 0, salt), hsh(ti + 1, 0, salt)
    return a + (b - a) * fade(t - ti)


def fbm(x, z, salt, octaves):
    s, amp, n = 0, 1, 0
    for k in range(1, octaves + 1):
        s += value2(x, z, salt + k * 101) * amp
        n += amp
        amp *= 0.5
        x *= 2.03
        z *= 2.03
    return s / n


def fbm1(t, salt, octaves):
    s, amp, n = 0, 1, 0
    for k in range(1, octaves + 1):
        s += value1(t, salt + k * 101) * amp
        n += amp
        amp *= 0.5
        t *= 2.03
    return s / n


def smooth(a, b, v):
    t = min(max((v - a) / (b - a), 0), 1)
    return t * t * (3 - 2 * t)


LOW, HIGH, HIGHER = 0.37, 0.63, 0.68
BLEND = 96  # studs: the ragged seam between two biomes
BLOCK = 8  # studs: the floor's patterns are this coarse (the map builds a part per run of a tile)

# ---- the biomes -------------------------------------------------------------------------
# width: the corridor's mean half width; ledge / cliff: the heights they pick from (wall
# tiles the map has); wall: the area's wall key and cap; props: (item, weight, tier, scale lo,
# hi) inside the corridor (obstacles) and on the ledges (scenery)
STYLE = {
    "Dungeon": dict(
        width=168, ledge=[30, 40, 60], cliff=[120, 220, 320], causeway=10,
        wall=("DungeonWall", "DungeonCap"),
        inside=[("Femur", 4, 1, 1.6, 2.4), ("Ribcage", 2, 2, 1.8, 2.6), ("StoneRubble", 4, 1, 1.8, 2.8),
                ("StoneBlockLow", 3, 2, 2, 3), ("Candles", 2, 1, 2, 2.6)],
        ledge_props=[("Candelabra", 3, None, 4, 5), ("Torch", 2, None, 1, 1.4), ("Monolith", 1, None, 4.5, 6.5),
                     ("Ribcage", 1, None, 4, 7)],
    ),
    "Forest": dict(
        width=176, ledge=[30, 40, 60], cliff=[90, 120, 220], causeway=10,
        wall=("ForestWall", "ForestCap"),
        inside=[("PalmTreeSmall", 4, 3, 3.2, 4.8), ("Boulders", 3, 2, 1.6, 2.8), ("RuinPillarBroken", 1, 2, 3, 4),
                ("StoneRubble", 2, 1, 1.8, 2.6)],
        ledge_props=[("PalmTree", 4, None, 6, 8), ("RuinPillar", 1, None, 6, 9), ("Boulders", 2, None, 4, 7),
                     ("Monolith", 1, None, 4.5, 6.5)],
    ),
    "Castle": dict(  # the Jurassic: skulls, bones and rock pillars (QM / the Jurassic thread, Nov 7)
        width=176, ledge=[30, 40, 60], cliff=[80, 120, 220], causeway=8,
        wall=("CastleWall", "CastleCap"),
        inside=[("Skull", 3, 2, 1.8, 2.6), ("Femur", 4, 1, 1.6, 2.4), ("Ribcage", 2, 2, 1.8, 2.6),
                ("Boulders", 3, 2, 1.6, 2.8)],
        ledge_props=[("Skull", 3, None, 5, 8), ("Ribcage", 2, None, 5, 8), ("Boulders", 2, None, 4, 7),
                     ("PILLARS", 3, None, 1, 1)],
    ),
    "Ocean": dict(
        width=180, ledge=[40, 60, 90], cliff=[120, 220, 320], causeway=12,
        wall=("OceanWall", "OceanCap"),
        inside=[("Coral", 4, 2, 2.4, 3.4), ("Starfish", 3, 1, 2, 3), ("Sponges", 3, 1, 2, 2.9),
                ("Boulders", 2, 2, 1.6, 2.8), ("Kelp", 3, 1, 2.6, 3.6)],
        ledge_props=[("Kelp", 4, None, 3.5, 5.5), ("Coral", 3, None, 4, 7), ("Monolith", 1, None, 4.5, 6.5),
                     ("Boulders", 2, None, 4, 7)],
    ),
}
AREAS = ["Dungeon", "Forest", "Castle", "Ocean"]

# the new floor keys (Config.WorldColors gets them too) and their checkers
NEW_COLOURS = {
    "DungeonTile": (122, 142, 160), "DungeonTileChecker": (116, 136, 154),
    "ForestMoss": (22, 168, 158), "ForestMossChecker": (20, 160, 151),
    "ForestWater": (70, 150, 230), "ForestWaterChecker": (80, 160, 236),
    "CastleMoss": (66, 140, 42), "CastleMossChecker": (61, 131, 39),
    "CastleMud": (110, 82, 52), "CastleMudChecker": (102, 76, 48),
    "CastleSwamp": (64, 140, 120), "CastleSwampChecker": (70, 150, 128),
    "CastleRock": (128, 114, 92), "CastleRockChecker": (120, 107, 86),
    "CastleTrail": (150, 118, 76), "CastleTrailChecker": (142, 111, 71),
    "OceanSandDark": (130, 200, 226), "OceanSandDarkChecker": (124, 193, 219),
    "OceanShell": (196, 240, 250), "OceanShellChecker": (188, 234, 246),
    "OceanTrench": (110, 170, 210), "OceanTrenchChecker": (104, 163, 203),
}
LIQUID = {"ForestWater", "CastleSwamp", "LavaMagma"}


def area_salt(name):
    return (AREAS.index(name) + 1) * 1013


def causeway(name, top, bottom, z, w):
    """The path's x at z, and its half width (Shared/Endless's causeway, one per biome)."""
    s = AREAS.index(name) + 1
    length = top - bottom
    along = (top - z) / length
    env = max(0.0, min(1.0, along * 6, (1 - along) * 6))
    d = top - z
    wave, wave2 = 380 + hsh(s, 5, 7) * 340, 150 + hsh(s, 6, 7) * 110
    ph, ph2 = hsh(s, 3, 7) * 2 * math.pi, hsh(s, 4, 7) * 2 * math.pi
    sway = 0.25 + hsh(s, 8, 7) * 0.3
    x = math.sin(d / wave * 2 * math.pi + ph) * 0.8 + math.sin(d / wave2 * 2 * math.pi + ph2) * 0.2
    return x * sway * w * env, STYLE[name]["causeway"]


def stone_at(i, j, salt):
    return hsh(i, j, 41 + salt) < 0.008


def plaza(x, z, w, salt, size=72):
    """Inside one of the squares a 72-stud grid scatters (Marble Meadow's plazas): its inlay
    noise, or None."""
    mi, mj = math.floor(x / size), math.floor(z / size)
    if abs(x) >= w - 12 or hsh(mi, mj, salt + 31) >= 0.3:
        return None
    n = size // CELL
    px, pz = math.floor((x - mi * size) / CELL), math.floor((z - mj * size) / CELL)
    a, b = 1 + math.floor(hsh(mi, mj, salt + 32) * 4), 1 + math.floor(hsh(mi, mj, salt + 33) * 4)
    c, d = 1 + math.floor(hsh(mi, mj, salt + 34) * 4), 1 + math.floor(hsh(mi, mj, salt + 35) * 4)
    if a <= px <= n - 1 - b and c <= pz <= n - 1 - d:
        return value2(x / 20, z / 20, salt + 36)
    return None


def floor_tile(name, x, z, w, top, bottom, i, j):
    """(key, top) of the floor cell at x, z in biome `name` (Shared/Endless's floorTile rules,
    in each biome's own tiles)."""
    salt = area_salt(name)
    xc, cw = causeway(name, top, bottom, z, w)
    road = abs(x - xc) < cw
    wx = x + 80 * (value2(x / 90, z / 90, salt + 1) - 0.5)
    wz = z + 80 * (value2(x / 90 + 17.3, z / 90 + 4.1, salt + 2) - 0.5)
    h = fbm(wx / 110, wz / 110, salt + 3, 3)
    if name == "Dungeon":  # slab plazas, cracks, magma pits, a slate path
        if road:
            return ("DungeonSlate", 0.5)
        p = plaza(x, z, w, salt)
        if p is not None:
            return ("DungeonTile", 0.5) if p > 0.3 else ("CastleFloor", -0.5)
        if h < LOW - 0.07:
            return ("LavaMagma", -0.5)
        if h < LOW + 0.02:
            return ("CastleFloor", -0.5)
        r = 1 - abs(2 * fbm(wx / 150, wz / 150, salt + 4, 2) - 1)
        if r > 0.94:
            return ("DungeonSlate", 0)
        return ("DungeonStone", 0)
    if name == "Forest":  # moss, ponds, stone ruins, a stone path
        if road:
            return ("ForestStone", 0.5)
        p = plaza(x, z, w, salt, 80)
        if p is not None:
            return ("ForestStone", 0.5) if p > 0.36 else ("ForestMoss", 0)
        if h < LOW - 0.04:
            return ("ForestWater", -1)
        if h < LOW - 0.02:
            return ("ForestStone", -0.5)
        if h > HIGH:
            return ("ForestGrass", 0.5)
        if value2(x / 72, z / 72, salt + 6) > 0.66:
            return ("ForestMoss", 0)
        return ("ForestGrass", 0)
    if name == "Castle":  # the Jurassic: moss, mud, swamp pools, rock ridges, a dirt trail
        if road:
            return ("CastleTrail", 0.5)
        r = 1 - abs(2 * fbm(wx / 150, wz / 150, salt + 4, 2) - 1)
        if r > 0.965:
            return ("CastleRock", 1)
        if r > 0.93:
            return ("CastleRock", 0.5)
        if h < LOW - 0.01:
            return ("CastleSwamp", -1)
        if h < LOW + 0.03:
            return ("CastleMud", -0.5)
        if value2(x / 72, z / 72, salt + 6) > 0.64:
            return ("CastleMoss", 0)
        return ("CastleGrass", 0)
    # the Ocean (Crystal Cavern's bands): shell sand down the middle, sand, dark sand by the
    # walls, trenches, stone outcrops; stepping stones where the path crosses a trench
    if h < LOW:
        return ("OceanStone", 0) if road else ("OceanTrench", -0.5)
    if h > HIGHER:
        return ("OceanStone", 1)
    if h > HIGH:
        return ("OceanStone", 0.5)
    band = (abs(x - xc) + 36 * (value2(x / 60, z / 60, salt + 5) - 0.5)) / w
    if band < 0.16:
        return ("OceanShell", 0)
    if band < 0.45:
        return ("OceanSand", 0)
    return ("OceanSandDark", 0)


def level(lst, v):
    return lst[min(max(1 + math.floor(v * len(lst)), 1), len(lst)) - 1]


def walls_of(name, z, side):
    """(ledge width, ledge top, cliff width, cliff top) on one side at z (Shared/Endless)."""
    st = STYLE[name]
    salt = (300 if side > 0 else 400) + area_salt(name)
    lw = 24 + CELL * math.floor(value1(z / 300, salt + 1) * 5)
    lt = level(st["ledge"], value1(z / 180, salt + 2))
    cw = 64 + CELL * math.floor(fbm1(z / 220, salt + 3, 2) * 24)
    ct = level(st["cliff"], fbm1(z / 260, salt + 4, 2) * 1.35 - 0.12)
    return lw, lt, cw, max(ct, lt + 20)


# ---- run ----------------------------------------------------------------------------------


def main():
    d = json.load(open(WORLD, encoding="utf-8"))
    ox, oz = d["origin"]
    cols, nrows = d["size"]
    assert d["cell"] == CELL and ox == -cols // 2 * CELL, "the grid must be centred on x = 0"
    centre = cols // 2  # column of the cell from x = 0 to 4
    areas = {a["name"]: a for a in d["areas"] if "bounds" in a}
    span = {n: (areas[n]["bounds"][1], areas[n]["bounds"][3]) for n in AREAS}  # (top z, bottom z)
    z_top, z_bottom = span[AREAS[0]][0], span[AREAS[-1]][1]

    # tiles: reuse the map's, add what's missing
    used = {t["id"] for t in d["tiles"]}
    pool = [c for c in "ÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ" if c not in used]
    by = {}
    for t in d["tiles"]:
        k = (t["area"], t["key"], t["top"], bool(t.get("wall")))
        by.setdefault(k, t["id"])

    def tile(area, key, top, wall=False, cap=None):
        k = (area, key, top, wall)
        if k not in by:
            t = {"id": pool.pop(0), "area": area, "key": key, "top": top}
            if wall:
                t["cap"], t["wall"] = cap, True
            if key in LIQUID:
                t["liquid"] = True
            d["tiles"].append(t)
            by[k] = t["id"]
        return by[k]

    # (the Jurassic thread's old carpet and stone ids, as grass: any cell still using them builds)
    for i in ("~", "]"):
        if i not in used:
            d["tiles"].append({"id": i, "area": "Castle", "key": "CastleGrass", "top": 0})
            used.add(i)

    # the old corridor's half width at the Lava's end, to blend from
    def old_half(r):
        row = d["rows"][r]
        n = 0
        while centre + n < cols and row[centre + n] != "." and not d_wall(row[centre + n]):
            n += 1
        return n * CELL

    walls = {t["id"] for t in d["tiles"] if t.get("wall")}

    def d_wall(ch):
        return ch in walls

    def row_of(z):
        return int((z - oz) // CELL)

    lava_half = old_half(row_of(z_top))  # the Lava's last row (just +z of the Dungeon's top)

    def area_at(z):
        for n in AREAS:
            if span[n][1] <= z < span[n][0] or (n == AREAS[0] and z == span[n][0]):
                return n
        return None

    def target(z):  # the mean half width, blended over 320 studs where biomes meet
        n = area_at(z)
        w = STYLE[n]["width"]
        k = AREAS.index(n)
        if k > 0:
            prev = STYLE[AREAS[k - 1]]["width"]
            w = prev + (w - prev) * smooth(0, 320, span[n][0] - z)
        return w

    halves = {}

    def half(r):  # Shared/Endless's rowHalf, about each biome's width
        if r in halves:
            return halves[r]
        z = math.floor((oz + r * CELL) / BLOCK) * BLOCK + BLOCK / 2
        w = target(z) + 120 * (fbm1(z / 640, 11, 3) - 0.5)
        g = value1(z / 1500, 13)
        if g > 0.7:
            w -= (g - 0.7) / 0.3 * 64
        w = min(max(w, 128), 222)
        w += (lava_half - w) * (1 - smooth(0, 240, z_top - z))  # from the Lava's width
        w = math.floor(w / BLOCK + 0.5) * BLOCK
        halves[r] = w
        return w

    def edge_offset(k, x):
        return (value1(x / 24, 990 + k) - 0.5) * BLEND

    def cell_area(x, z):  # the ragged seam: a cell near a line between two biomes
        n = area_at(z)
        k = AREAS.index(n)
        top, bottom = span[n]
        if z - bottom < BLEND / 2 and k + 1 < len(AREAS):
            if z < bottom + edge_offset(k, x):
                return AREAS[k + 1]
        elif top - z < BLEND / 2 and k > 0:
            if z >= top + edge_offset(k - 1, x):
                return AREAS[k - 1]
        return n

    r0, r1 = row_of(z_bottom), row_of(z_top)  # rows z_bottom .. z_top - 4
    profile = []
    for r in range(r0, r1):
        z0 = oz + r * CELL
        zc = z0 + 2
        w = half(r)
        n = area_at(zc)
        old = list(d["rows"][r])
        # clear the old corridor and its walls (the run of painted cells out from the middle)
        for side in (1, -1):
            c = centre if side > 0 else centre - 1
            while 0 <= c < cols and old[c] != ".":
                old[c] = "."
                c += side
        nc = w // CELL
        for c in range(centre - nc, centre + nc):
            # (the patterns in 8-stud blocks, 2 x 2 cells: a quarter of the parts)
            bx = math.floor((ox + c * CELL) / BLOCK) * BLOCK + BLOCK / 2
            bz = math.floor(z0 / BLOCK) * BLOCK + BLOCK / 2
            a = cell_area(bx, bz)
            top, bottom = span[a]
            key, t = floor_tile(a, bx, bz, w, top, bottom, int(bx // BLOCK), int(bz // BLOCK))
            old[c] = tile(a, key, t)
        for side in (1, -1):
            lw, lt, cw, ct = walls_of(n, zc, side)
            key, cap = STYLE[n]["wall"]
            for k in range(lw // CELL + cw // CELL):
                c = centre + nc + k if side > 0 else centre - nc - 1 - k
                if 0 <= c < cols:
                    old[c] = tile(n, key, lt if k < lw // CELL else ct, True, cap)
        d["rows"][r] = "".join(old)
        profile.append((z0 + CELL, w))  # (the row's +z edge, its half width)

    # objects: keep everything that isn't these biomes' props, pillars or arches
    def ours(o):
        return o["type"] in ("Prop", "Pillar", "Arch") and z_bottom <= o["z"] < z_top

    d["objects"] = [o for o in d["objects"] if not ours(o)]

    def cell_at(x, z):
        r, c = row_of(z), int((x - ox) // CELL)
        return d["rows"][r][c]

    tiles = {t["id"]: t for t in d["tiles"]}

    def pick(lst, v):
        total = sum(p[1] for p in lst)
        v *= total
        for p in lst:
            v -= p[1]
            if v < 0:
                return p
        return lst[-1]

    GRID = 40
    added = 0
    for gj in range(math.floor(z_bottom / GRID), math.floor(z_top / GRID) + 1):
        for gi in range(-12, 12):
            x = gi * GRID + 4 + hsh(gi, gj, 62) * (GRID - 8)
            z = gj * GRID + 4 + hsh(gi, gj, 63) * (GRID - 8)
            if not (z_bottom + 24 < z < z_top - 24):
                continue
            n = area_at(z)
            st = STYLE[n]
            w = half(row_of(z))
            ax, side = abs(x), (1 if x >= 0 else -1)
            grove = value2(x / 220, z / 220, area_salt(n) + 64)
            roll = hsh(gi, gj, 61)
            t = tiles.get(cell_at(x, z))
            top, bottom = span[n]
            if ax < w - 10:
                near = 1 - smooth(20, 60, w - ax)
                xc, cw = causeway(n, top, bottom, z, w)
                if roll > 0.08 + 0.25 * grove + 0.35 * near or abs(x - xc) < cw + 6 or not t or t.get("liquid"):
                    continue
                p, obstacle = pick(st["inside"], hsh(gi, gj, 65)), True
            else:
                lw, lt, cw, ct = walls_of(n, z, side)
                if ax < w + 6 or ax > w + lw - 6 or roll > 0.25 + 0.4 * grove:
                    continue
                p, obstacle = pick(st["ledge_props"], hsh(gi, gj, 65)), False
            yaw = int(hsh(gi, gj, 66) * 360)
            if p[0] == "PILLARS":  # a cluster of rock pillars (the Jurassic's)
                for k in range(1 + int(hsh(gi, gj, 68) * 3)):
                    d["objects"].append({"type": "Pillar", "style": n, "kind": "joint", "y": lt,
                                         "x": round(x + (hsh(gi, gj, 70 + k) - 0.5) * 14),
                                         "z": round(z + (hsh(gi, gj, 80 + k) - 0.5) * 14),
                                         "size": [14, 10, 8][k], "height": [64, 36, 28][k] + int(hsh(gi, gj, 90 + k) * 32),
                                         "yaw": int(hsh(gi, gj, 95 + k) * 90)})
                    added += 1
                continue
            o = {"type": "Prop", "item": p[0], "x": round(x), "z": round(z), "yaw": yaw,
                 "scale": round(p[3] + (p[4] - p[3]) * hsh(gi, gj, 67), 2), "style": n}
            if obstacle:
                o["obstacle"] = p[2]
            d["objects"].append(o)
            added += 1

    # a set piece at the middle of each biome: a gate of two pillars and an arch over the
    # corridor (the Jurassic: two towering rock-pillar clusters and a giant skull)
    for n in AREAS:
        top, bottom = span[n]
        zm = math.floor((top + bottom) / 2 / CELL) * CELL + CELL / 2
        w = half(row_of(zm))
        lw = min(walls_of(n, zm, 1)[0], walls_of(n, zm, -1)[0])
        px = w + lw // 2  # (on the ledges)
        if n == "Castle":
            for s in (1, -1):
                lt = walls_of(n, zm, s)[1]
                for k, (dx, dz, size, height) in enumerate([(0, 0, 18, 110), (8, 14, 12, 70), (-6, -12, 10, 50)]):
                    d["objects"].append({"type": "Pillar", "style": n, "kind": "joint", "x": s * (px + dx), "z": zm + dz,
                                         "size": size, "height": height, "yaw": 20 * k, "y": lt})
            d["objects"].append({"type": "Prop", "item": "Skull", "x": round(px + 34), "z": zm - 60, "yaw": 250,
                                 "scale": 10, "style": n})
        else:
            px = w - 10  # (the gate stands on the corridor's edges, as the Meadow's and Ice's)
            scale = round(px / 29.1, 2)
            for s in (1, -1):
                d["objects"].append({"type": "Pillar", "style": n, "kind": "joint", "x": s * px, "z": zm,
                                     "size": 14, "height": 36, "scale": scale})
            d["objects"].append({"type": "Arch", "style": n, "x": 0, "z": zm, "scale": scale,
                                 "y": round(-64 * scale / 7.69)})
        added += 1

    # colours: the new keys, unless the map already has its own
    for k, v in NEW_COLOURS.items():
        d["colours"].setdefault(k, list(v))

    with open(WORLD, "w", encoding="utf-8") as f:
        f.write(dump(d))

    # Config.CourseProfile: the Lava's stops as they were, then these rows' (merged where
    # straight within 2 studs)
    pts = [(z, w) for z, w in reversed(profile)]  # from the Dungeon's top down
    steps = []
    for z, w in pts:  # each row: its top edge and its bottom edge at its width
        steps += [(z, w), (z - CELL, w)]
    keep = [steps[0]]
    for k in range(1, len(steps) - 1):
        a, b, c = keep[-1], steps[k], steps[k + 1]
        if a[0] != c[0]:
            want = a[1] + (c[1] - a[1]) * (a[0] - b[0]) / (a[0] - c[0])
            if abs(want - b[1]) <= 2:
                continue
        keep.append(b)
    keep.append(steps[-1])
    src = open(CONFIG, encoding="utf-8").read()
    m = re.search(r"(\tCourseProfile = \{ )(.*?)( \},\n)", src)
    stops = re.findall(r"\{ (-?\d+(?:\.\d+)?), (\d+(?:\.\d+)?) \}", m.group(2))
    old = [(float(a), float(b)) for a, b in stops if float(a) > z_top]
    new = old + [(z, w) for z, w in keep]
    fmt = lambda v: str(int(v)) if v == int(v) else str(v)  # noqa: E731
    text = ", ".join("{ %s, %s }" % (fmt(z), fmt(w)) for z, w in new)
    src = src[: m.start(2)] + text + src[m.end(2):]
    # the new floor keys' colours in Config.WorldColors (after CastleCarpetChecker)
    if "DungeonTile = " not in src:
        lines = "".join("\t\t%s = Color3.fromRGB(%d, %d, %d),\n" % (k, *v) for k, v in NEW_COLOURS.items())
        anchor = re.search(r"\t\tCastleCarpetChecker = Color3\.fromRGB\([^)]*\),\n", src)
        src = src[: anchor.end()] + "\t\t-- (tools/map_endless_style.py: the endless-style floors past the Lava, QM Nov 7)\n" + lines + src[anchor.end():]
    open(CONFIG, "w", encoding="utf-8").write(src)
    print("rows %d..%d regrown, %d objects added, %d profile stops (was %d past the Lava)"
          % (r0, r1, added, len(keep), len(stops) - len(old)))


if __name__ == "__main__":
    main()
