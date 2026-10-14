"""World 3's home base (QM, Oct 14; draft): a pirate / tropical island, a bit bigger than
World 1's and 2's so the pens can grow bigger.

Run: python3 tools/world3_base.py [out_dir]
     renders the layout (top-down) to out_dir and writes tools/world3_base.luau.

- Sand everywhere, a darker wet sand on the paths (a lane to the start line, one to each
  pen's gate) and round all the water.
- Lagoons of the animated water tile (Config.Water: parts named Water, a stud down), always
  ringed by wet sand, never touching dry sand or grass.
- Patches of bright green grass a stud up, away from the water.
- 1.2x the old base: x -216..216, z 0..328; pens up to 104 square, at 1.2x their places.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects  # noqa: E402

HERE = os.path.dirname(__file__)
SCALE = 1.2
W, DEPTH, CELL = 216, 328, 8
NX, NZ = 2 * W // CELL, DEPTH // CELL
SAND, WET, GRASS, WATER = 0, 1, 2, 3
TOPS = {SAND: 0, WET: 0, GRASS: 1, WATER: -1}
COLOURS = {  # part, checker
    SAND: [(240, 218, 160), (230, 206, 146)],
    WET: [(206, 172, 110), (194, 160, 98)],
    GRASS: [(96, 204, 60), (84, 188, 50)],
    WATER: [(64, 190, 214), (52, 174, 200)],  # (the animated tile goes over it)
}
PENS = [(x * SCALE, z * SCALE) for x, z in [(0, 218), (-110.3, 188.6), (110.3, 188.6), (-120.1, 74.8), (120.1, 74.8)]]
PEN_HALF = 52
YARD = (0, 112)
PORTAL = (-76, 30)


def centre(i, j):
    return -W + i * CELL + CELL / 2, j * CELL + CELL / 2


def seg_dist(p, a, b):
    ax, az = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((p[0] - a[0]) * ax + (p[1] - a[1]) * az) / (ax * ax + az * az)))
    return math.hypot(p[0] - a[0] - t * ax, p[1] - a[1] - t * az)


def pen_frame(c):
    a = math.atan2(YARD[0] - c[0], YARD[1] - c[1])
    return a


def in_pen(x, z, grow=0):
    for c in PENS:
        a = pen_frame(c)
        u = (x - c[0]) * math.cos(a) - (z - c[1]) * math.sin(a)
        v = (x - c[0]) * math.sin(a) + (z - c[1]) * math.cos(a)
        if abs(u) < PEN_HALF + grow and abs(v) < PEN_HALF + grow:
            return True
    return False


def gate(c):
    dx, dz = YARD[0] - c[0], YARD[1] - c[1]
    d = math.hypot(dx, dz)
    return c[0] + dx / d * PEN_HALF, c[1] + dz / d * PEN_HALF


def grow(mask, n=1):
    for _ in range(n):
        p = np.pad(mask, 1)
        m = mask.copy()
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                m |= p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]
        mask = m
    return mask


def drop_small(mask, keep):
    mask, seen = mask.copy(), np.zeros_like(mask)
    for i in range(NX):
        for j in range(NZ):
            if mask[i, j] and not seen[i, j]:
                comp, todo = [], [(i, j)]
                seen[i, j] = True
                while todo:
                    a, b = todo.pop()
                    comp.append((a, b))
                    for c, d in ((a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)):
                        if 0 <= c < NX and 0 <= d < NZ and mask[c, d] and not seen[c, d]:
                            seen[c, d] = True
                            todo.append((c, d))
                if len(comp) < keep:
                    for a, b in comp:
                        mask[a, b] = False
    return mask


def smooth(mask, keep_n=4, add_n=6):
    p = np.pad(mask, 1).astype(int)
    n = sum(p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ] for di in (-1, 0, 1) for dj in (-1, 0, 1))
    return (mask & (n >= keep_n)) | (n >= add_n)


def layout(seed=7):
    wob = noise(NX, NZ, 3, seed) - 0.5
    lag = noise(NX, NZ, 5, seed + 1) * 0.75 + noise(NX, NZ, 2, seed + 2) * 0.25
    grs = noise(NX, NZ, 4, seed + 3) * 0.75 + noise(NX, NZ, 1.8, seed + 4) * 0.25
    ring = noise(NX, NZ, 2.5, seed + 5)
    kind = np.full((NX, NZ), SAND)
    path = np.zeros((NX, NZ), bool)
    free = np.zeros((NX, NZ), bool)  # where water may go
    for i in range(NX):
        for j in range(NZ):
            x, z = centre(i, j)
            lane = (20 - abs(x) + max(0, 12 - z) * 0.6) / 20 if z < YARD[1] else -1
            yard = 1 - math.hypot(x / 52, (z - YARD[1]) / 40)
            paths = max(1 - seg_dist((x, z), YARD, gate(c)) / 10 for c in PENS)
            f = max(lane, yard * 1.4, paths) + wob[i, j] * 0.8
            if f > 0 and not in_pen(x, z) and z < DEPTH - 16:
                path[i, j] = True
            far_wall = abs(x) < W - 16 and z < DEPTH - 24 and z > 12
            if far_wall and not in_pen(x, z, 12) and f < -0.25 and math.hypot(x - PORTAL[0], z - PORTAL[1]) > 28:
                free[i, j] = True
    water = (lag > 0.42) & free
    for _ in range(3):
        water = smooth(water, 5, 5) & free  # (rounded off)
    water = drop_small(water, 14)
    wet = (grow(water, 1) | (grow(water, 2) & (ring > 0.55)) | path) & ~water
    kind[wet] = WET
    kind[water] = WATER
    inside = np.array([[in_pen(*centre(i, j), CELL) for j in range(NZ)] for i in range(NX)])
    grass = smooth((grs > 0.42) & (kind == SAND)) & (kind == SAND) & ~grow(water, 3) & ~inside
    grass = drop_small(grass, 6)
    kind[grass] = GRASS
    return kind


def check(kind):
    """Water only ever touches wet sand (or water)."""
    p = np.pad(kind, 1, constant_values=WET)
    bad = 0
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            n = p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]
            bad += int(((kind == WATER) & ~np.isin(n, [WET, WATER])).sum())
    return bad


def render(kind, out, s=3):
    im = Image.new("RGB", (NX * CELL * s, NZ * CELL * s))
    d = ImageDraw.Draw(im)
    for i in range(NX):
        for j in range(NZ):
            for a in range(2):
                for b in range(2):
                    col = COLOURS[int(kind[i, j])][(i * 2 + a + j * 2 + b) % 2]
                    x0, y0 = (i * CELL + a * 4) * s, ((NZ - 1 - j) * CELL + (1 - b) * 4) * s
                    d.rectangle([x0, y0, x0 + 4 * s - 1, y0 + 4 * s - 1], fill=col)

    def P(x, z):
        return ((x + W) * s, (NZ * CELL - z) * s)

    for c in PENS:
        a = pen_frame(c)
        h = PEN_HALF
        pts = [P(c[0] + u * math.cos(a) + v * math.sin(a), c[1] - u * math.sin(a) + v * math.cos(a))
               for u, v in ((-h, -h), (h, -h), (h, h), (-h, h))]
        d.polygon(pts, outline=(90, 60, 30), width=s)
    d.rectangle([*P(-56, 6), *P(56, 0)], outline=(255, 255, 255), width=s)
    d.ellipse([*P(PORTAL[0] - 14, PORTAL[1] + 14), *P(PORTAL[0] + 14, PORTAL[1] - 14)], outline=(255, 255, 255), width=s)
    im.save(out)


def walls():
    """The base's walls and caps 1.2x out (tools/arc_base.luau's: 8 thick, 48 tall; caps 10
    wide, 2 tall, at 49, a stud in)."""
    b, d = W + 8, DEPTH  # (the side walls' outsides; the back wall's inside at DEPTH - 8)
    front = (b - 56) // 2  # the front walls run from the course's mouth (56) to the side walls
    return [
        ("back", "Wall", (0, 24, d - 4), (2 * b, 48, 8)), ("back", "Cap", (0, 49, d - 5), (2 * b, 2, 10)),
        ("left", "Wall", (-(W + 4), 24, (d - 8) / 2), (8, 48, d)), ("left", "Cap", (-(W + 3), 49, (d - 8) / 2 + 4), (10, 2, d - 12)),
        ("right", "Wall", (W + 4, 24, (d - 8) / 2), (8, 48, d)), ("right", "Cap", (W + 3, 49, (d - 8) / 2 + 4), (10, 2, d - 12)),
        ("frontleft", "Wall", (-(56 + front), 24, -4), (2 * front, 48, 8)), ("frontleft", "Cap", (-(56 + front + 3), 49, -3), (2 * front + 10, 2, 10)),
        ("frontright", "Wall", (56 + front, 24, -4), (2 * front, 48, 8)), ("frontright", "Cap", (56 + front + 3, 49, -3), (2 * front + 10, 2, 10)),
    ]


def write_luau(kind):
    rows = ["\t{ %d, %d, %d, %d, %d }," % (k, -W + i0 * CELL, j0 * CELL, (i1 - i0) * CELL, (j1 - j0) * CELL)
            for k, i0, j0, i1, j1 in rects(kind)]
    ws = ['\t{ "%s", "%s", Vector3.new(%g, %g, %g), Vector3.new(%g, %g, %g) },' % (a, n, *c, *sz) for a, n, c, sz in walls()]
    body = open(os.path.join(HERE, "world3_base.luau.in")).read()
    body = body.replace("--FLOOR--", "\n".join(rows)).replace("--WALLS--", "\n".join(ws))
    open(os.path.join(HERE, "world3_base.luau"), "w").write(body)
    return len(rows)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world3_base"
    os.makedirs(out, exist_ok=True)
    kind = layout()
    assert check(kind) == 0
    render(kind, os.path.join(out, "world3_base.png"))
    print("parts:", write_luau(kind))
    print({n: int((kind == k).sum()) for n, k in (("sand", SAND), ("wet", WET), ("grass", GRASS), ("water", WATER))})


if __name__ == "__main__":
    main()
