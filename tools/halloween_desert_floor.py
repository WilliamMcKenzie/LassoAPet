"""The Halloween world's Desert floor (QM, Oct 15: "make new desert terrain to match this
ground pattern", his teal night graveyard picture).

Run: python3 tools/halloween_desert_floor.py [desert|tundra] [out_dir]
     renders it (the biome cut into four strips side by side, start line at the top of the
     first) and writes tools/halloween_<biome>_floor.luau (template halloween_floor_biome.luau.in).

The Tundra the same way in QM's autumn colours (Oct 15, his harvest picture): tan
flagstones down the middle, sage green along the walls, brown patches inside the green.

His picture: pale flagstones down the middle, ragged patches of a darker flagstone mostly
along the walls (a few out in the middle), and the darkest slate in small patches inside
those, always ringed by the middle tone (pale never touches slate, even at a corner). All
flush. No patch under 2x2 tiles. Laid in game space (the Halloween Place is World 1's,
already funnelled): 8-stud cells, each 64-stud band as wide as the course at its middle,
the outer columns running on under the walls.
"""

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects  # noqa: E402

HERE = os.path.dirname(__file__)
BIOMES = {
    "desert": dict(name="Desert", z0=-2168, length=1816, seed=41, colours={  # Config World 4 Desert
        "Ground": [(126, 180, 210), (116, 170, 202)],  # pale flagstone
        "Stone": [(104, 154, 186), (96, 146, 178)],  # darker flagstone
        "Grass": [(86, 122, 150), (78, 114, 142)],  # slate
    }),
    "tundra": dict(name="Tundra", z0=-2168 - 1816, length=1920, seed=53, colours={  # (Config World 4 Tundra: Studio adds)
        "Ground": [(214, 184, 134), (204, 174, 124)],  # tan
        "Grass": [(136, 156, 104), (126, 146, 96)],  # sage green
        "Dirt": [(160, 112, 74), (148, 102, 66)],  # brown
    }),
}
KEY = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in BIOMES else "desert"
B = BIOMES[KEY]
Z0, Z1 = B["z0"], B["z0"] - B["length"]
CELL, BAND = 8, 64
PALE, MID, SLATE = 0, 1, 2
NAMES = dict(zip((PALE, MID, SLATE), B["colours"]))  # light, middle, darkest
COLOURS = {k: B["colours"][n] for k, n in NAMES.items()}


def half_width(z):  # tools/funnel.luau (Config.CourseHalfWidth, CourseWidening, CourseMaxHalfWidth)
    return min(56 + 0.005 * max(-z, 0), 137)


EDGE = int(math.ceil(half_width(Z1) / CELL)) * CELL  # the widest the grid needs (80)
NX, NZ = 2 * EDGE // CELL, (Z0 - Z1) // CELL


def centre(i, j):
    return -EDGE + i * CELL + CELL / 2, Z0 - j * CELL - CELL / 2


def shift(m, di, dj):
    p = np.pad(m, 1)
    return p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]


def grow(m, r=1):
    for _ in range(r):
        m = np.any([shift(m, a, b) for a in (-1, 0, 1) for b in (-1, 0, 1)], axis=0)
    return m


def shrink(m, r=1):
    return ~grow(~m, r)


def specks(m):
    """Cells of m in no 2x2 block of m."""
    ok = np.zeros_like(m)
    for di in (0, -1):
        for dj in (0, -1):
            ok |= np.all([shift(m, di + a, dj + b) for a in (0, 1) for b in (0, 1)], axis=0)
    return m & ~ok


def no_specks(m):
    for _ in range(4):
        m = m & ~specks(m)  # (lone bits go)
        m = m | specks(~m)  # (lone holes fill)
    return m


def layout(seed=B["seed"]):
    rag = noise(NX, NZ, 6, seed)  # how far each wall band reaches in
    mids = noise(NX, NZ, 3, seed + 1) * 0.7 + noise(NX, NZ, 8, seed + 2) * 0.3  # patches out in the middle
    dark = noise(NX, NZ, 7, seed + 3)
    inside = np.zeros((NX, NZ), bool)
    wall = np.zeros((NX, NZ))
    for i in range(NX):
        for j in range(NZ):
            x, z = centre(i, j)
            h = half_width(z)
            inside[i, j] = abs(x) < h + CELL  # (the cells under the wall too)
            wall[i, j] = h - abs(x)  # studs in from the wall
    reach = 8 + rag * 34  # 8..42 studs in
    mid = (wall < reach) | (mids > 0.74) | ~inside  # (under the walls counts as wall side)
    mid = no_specks(mid)
    slate = no_specks(shrink(mid, 2) & (dark > 0.55) & (wall < 30) & inside)
    slate &= shrink(mid, 1)  # (always ringed by the middle tone)
    kind = np.full((NX, NZ), PALE)
    kind[mid] = MID
    kind[slate] = SLATE
    for _ in range(6):  # (a middle-tone cell in no 2x2 of its own: whichever side it can join)
        sp = specks(kind == MID)
        if not sp.any():
            break
        near_pale, near_slate = grow(kind == PALE), grow(kind == SLATE)
        kind[sp & ~near_pale] = SLATE
        kind[sp & near_pale & ~near_slate] = PALE
    return kind


def check(kind):
    bad = 0
    for a in (-1, 0, 1):
        for b in (-1, 0, 1):
            n = np.pad(kind, 1, constant_values=MID)[1 + a:1 + a + NX, 1 + b:1 + b + NZ]
            bad += int(((kind == PALE) & (n == SLATE)).sum())
    return bad


def parts(kind):
    """{ name, low x, low z, size x, size z } per part: each 64-stud band to its own width."""
    out = []
    for j0 in range(0, NZ, BAND // CELL):
        j1 = min(NZ, j0 + BAND // CELL)
        zmid = Z0 - (j0 + j1) / 2 * CELL
        e = int(math.ceil(half_width(zmid) / CELL)) * CELL + CELL  # (a cell on under the wall)
        e = min(e, EDGE)
        i0, i1 = (EDGE - e) // CELL, (EDGE + e) // CELL
        sub = kind[i0:i1, j0:j1].copy()
        for k, a0, b0, a1, b1 in rects(sub):
            x = -e + a0 * CELL
            ztop = Z0 - (j0 + b0) * CELL
            out.append((NAMES[k], x, ztop - (b1 - b0) * CELL, (a1 - a0) * CELL, (b1 - b0) * CELL))
    return out


def render(kind, out, s=3, strips=4):
    per = int(math.ceil(NZ / strips))
    gap = 6
    im = Image.new("RGB", ((NX * CELL * s + gap * s) * strips, per * CELL * s), (20, 26, 40))
    px = im.load()
    for i in range(NX):
        for j in range(NZ):
            k = int(kind[i, j])
            x, z = centre(i, j)
            if abs(x) > half_width(z):  # (under the wall: the wall's colour)
                k = None
            st, jj = divmod(j, per)
            ox = st * (NX * CELL * s + gap * s)
            for a in range(2):
                for b in range(2):
                    col = (60, 50, 66) if k is None else COLOURS[k][(i * 2 + a + j * 2 + b) % 2]
                    for u in range(4 * s):
                        for v in range(4 * s):
                            px[ox + (i * CELL + a * 4) * s + u, (jj * CELL + b * 4) * s + v] = col
    im.save(out)


def main():
    args = [a for a in sys.argv[1:] if a not in BIOMES]
    out = args[0] if args else "/mnt/project-files/biomes/halloween_" + KEY
    os.makedirs(out, exist_ok=True)
    kind = layout()
    assert check(kind) == 0, "pale touches slate"
    for k in (PALE, MID, SLATE):
        assert not specks(kind == k).any(), f"specks of {k}"
    render(kind, os.path.join(out, "halloween_%s.png" % KEY))
    rows = ['\t{ "%s", %d, %d, %d, %d },' % p for p in parts(kind)]
    look = "\n".join("\t%s = { rgb%s, rgb%s }," % (n, tuple(c[0]), tuple(c[1])) for n, c in B["colours"].items())
    body = open(os.path.join(HERE, "halloween_floor_biome.luau.in")).read()
    body = body.replace("--NAME--", B["name"]).replace("--Z0--", str(Z0)).replace("--LENGTH--", str(B["length"]))
    body = body.replace("--LOOK--", look).replace("--FLOOR--", "\n".join(rows))
    open(os.path.join(HERE, "halloween_%s_floor.luau" % KEY), "w").write(body)
    print({n: int((kind == k).sum()) for n, k in (("pale", PALE), ("mid", MID), ("slate", SLATE))}, "parts:", len(rows))


if __name__ == "__main__":
    main()
