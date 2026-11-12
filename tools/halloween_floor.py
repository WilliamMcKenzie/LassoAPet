"""The Halloween world's base floor (QM, Oct 15: "something similar to meadow base but the
tile colors are like orange grass and dark stone pathes").

Run: python3 tools/halloween_floor.py [out_dir]
     renders it and writes tools/halloween_floor.luau, which lays it in Studio over the one
     Grass part tools/halloween_base.luau left (run that first).

World 2's / World 1's base pattern on the bigger base tools/halloween_base.luau makes
(x -310..310, z 0..492, ten pens round the yard's middle C): a dark stone yard in the
middle, a lane from it to the start line, a path to each pen's gap. Three tiles as a
gradient: the bright orange grass never touches the stone, even at a corner; there's
always darker orange between. The stone is sunk a stud; the bright grass is a stud up but
inside the pens (a tile round them) and on the start line's row.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects  # noqa: E402

HERE = os.path.dirname(__file__)
W, DEPTH, CELL = 312, 496, 8  # (the walls' inner faces: x +-310, z 492; the floor runs under them)
NX, NZ = 2 * W // CELL, DEPTH // CELL
BRIGHT, DARK, STONE, RAISED = 0, 1, 2, 3
C = (0, 182)  # tools/halloween_base.luau: the yard's middle
R = 210  # each pen's gap from C
ANGLES = [-30 + i * 240 / 9 for i in range(10)]  # degrees from +x toward +z
PEN_HALF = 44  # World 1's pens at their biggest, 22 tiles (tools/pens.py)
PENS = [(C[0] + math.cos(math.radians(a)) * (R + PEN_HALF), C[1] + math.sin(math.radians(a)) * (R + PEN_HALF)) for a in ANGLES]
COLOURS = {  # part, checker
    BRIGHT: [(121, 65, 137), (113, 61, 130)],  # purple ("Ground"; QM, Oct 15, set in Play: was orange)
    DARK: [(100, 55, 105), (92, 51, 97)],  # darker purple ("Grass")
    STONE: [(159, 136, 179), (153, 130, 174)],  # light lilac paths ("Dirt")
}
COLOURS[RAISED] = COLOURS[BRIGHT]


def centre(i, j):
    return -W + i * CELL + CELL / 2, j * CELL + CELL / 2


def gate(c):
    dx, dz = C[0] - c[0], C[1] - c[1]
    d = math.hypot(dx, dz)
    return c[0] + dx / d * PEN_HALF, c[1] + dz / d * PEN_HALF


def seg_dist(p, a, b):
    ax, az = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((p[0] - a[0]) * ax + (p[1] - a[1]) * az) / (ax * ax + az * az)))
    return math.hypot(p[0] - a[0] - t * ax, p[1] - a[1] - t * az)


def in_pen(x, z, grow=0):
    for c in PENS:
        a = math.atan2(C[0] - c[0], C[1] - c[1])
        u = (x - c[0]) * math.cos(a) - (z - c[1]) * math.sin(a)
        v = (x - c[0]) * math.sin(a) + (z - c[1]) * math.cos(a)
        if abs(u) < PEN_HALF + grow and abs(v) < PEN_HALF + grow:
            return True
    return False


def layout(seed=31):
    wob = noise(NX, NZ, 3, seed) - 0.5  # the stone's ragged edge
    ring = noise(NX, NZ, 2.5, seed + 1)  # how thick the darker orange is
    spots = noise(NX, NZ, 3.5, seed + 2) * 0.7 + noise(NX, NZ, 1.5, seed + 3) * 0.3  # darker patches
    kind = np.full((NX, NZ), BRIGHT)
    for i in range(NX):
        for j in range(NZ):
            x, z = centre(i, j)
            yard = 1 - math.hypot(x / 96, (z - C[1]) / 78)
            lane = (26 - abs(x) + max(0, 14 - z) * 0.7) / 26 if z < C[1] else -1  # flares onto the line
            paths = max(1 - seg_dist((x, z), C, gate(c)) / 11 for c in PENS)
            f = max(yard * 1.6, lane, paths) + wob[i, j] * 0.9
            if f > 0 and not in_pen(x, z) and abs(x) < W - 14 and z < DEPTH - 20:
                kind[i, j] = STONE
    stone = kind == STONE
    near = [stone]
    for r in range(1, 4):
        g = near[r - 1].copy()
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                g |= np.roll(np.roll(near[r - 1], di, 0), dj, 1)
        near.append(g)
    reach = np.where(ring > 0.62, 3, np.where(ring > 0.42, 2, 1))
    for r in (1, 2, 3):
        kind[(near[r] & ~stone) & (reach >= r)] = DARK
    kind[(spots > 0.72) & (kind == BRIGHT)] = DARK
    return kind


def check(kind):
    """Bright orange never touches the stone, even at a corner."""
    p = np.pad(kind, 1, constant_values=DARK)
    bad = 0
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            n = p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]
            bad += int(((kind == BRIGHT) & (n == STONE)).sum())
    return bad


def raise_grass(kind):
    out = kind.copy()
    for i in range(NX):
        for j in range(1, NZ):
            if kind[i, j] == BRIGHT and not in_pen(*centre(i, j), grow=CELL):
                out[i, j] = RAISED
    return out


def render(kind, out, s=2):
    im = Image.new("RGB", (NX * CELL * s, NZ * CELL * s))
    d = ImageDraw.Draw(im)
    shade = {RAISED: 1.0, BRIGHT: 0.9, DARK: 1.0, STONE: 1.0}
    for i in range(NX):
        for j in range(NZ):
            k = int(kind[i, j])
            for a in range(2):
                for b in range(2):
                    col = tuple(int(v * shade[k]) for v in COLOURS[k][(i * 2 + a + j * 2 + b) % 2])
                    x0, y0 = (i * CELL + a * 4) * s, ((NZ - 1 - j) * CELL + (1 - b) * 4) * s
                    d.rectangle([x0, y0, x0 + 4 * s - 1, y0 + 4 * s - 1], fill=col)

    def P(x, z):
        return ((x + W) * s, (NZ * CELL - z) * s)

    for c in PENS:
        a = math.atan2(C[0] - c[0], C[1] - c[1])
        pts = [P(c[0] + u * math.cos(a) + v * math.sin(a), c[1] - u * math.sin(a) + v * math.cos(a))
               for u, v in ((-44, -44), (44, -44), (44, 44), (-44, 44))]
        d.polygon(pts, outline=(40, 24, 16), width=s)
    d.rectangle([*P(-56, 6), *P(56, 0)], outline=(255, 255, 255), width=s)
    im.save(out)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/halloween_base"
    os.makedirs(out, exist_ok=True)
    kind = layout()
    bad = check(kind)
    assert bad == 0, f"{bad} bright tiles touch stone"
    raised = raise_grass(kind)
    render(raised, os.path.join(out, "halloween_base.png"))
    rows = ["\t{ %d, %d, %d, %d, %d }," % (k, -W + i0 * CELL, j0 * CELL, (i1 - i0) * CELL, (j1 - j0) * CELL)
            for k, i0, j0, i1, j1 in rects(raised)]
    body = open(os.path.join(HERE, "halloween_floor.luau.in")).read()
    open(os.path.join(HERE, "halloween_floor.luau"), "w").write(body.replace("--FLOOR--", "\n".join(rows)))
    print({n: int((kind == k).sum()) for n, k in (("bright", BRIGHT), ("dark", DARK), ("stone", STONE))}, "parts:", len(rows))


if __name__ == "__main__":
    main()
