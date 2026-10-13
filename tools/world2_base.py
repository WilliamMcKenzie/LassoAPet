"""World 2's home base floor (QM, Oct 13): yellow grass, darker yellow grass, brown dirt.

Run: python3 tools/world2_base.py [out_dir]
     renders the layout (and World 1's, in World 2's colours, to compare) and writes
     tools/world2_base.luau, which lays it in Studio over World2's copied base floor.

The three tiles are a gradient: bright grass never touches dirt, not even at a corner;
there's always darker grass between (QM). The darker grass rings every bit of dirt, one
to three tiles thick, and lies in a few patches out in the bright grass too.

The dirt differs from World 1's on purpose but plays the same: a yard in the middle,
a lane from it to the home line, and a short path from the yard to each pen's gate
(World 1 had patches between the pens). No dirt
within a tile of a wall (the sunk dirt would open a hole under it). Same 8-stud cells
as World 1's base (tools/arc_base.py), so the 4-stud checker lines up.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects  # noqa: E402

HERE = os.path.dirname(__file__)
W, DEPTH, CELL = 176, 272, 8  # x -176..176, z 0..272 (the floor runs under the back wall)
NX, NZ = 2 * W // CELL, DEPTH // CELL
OFFSET_X = 1000  # World2 sits 1000 studs over (tools/world2_terrain.luau)
BRIGHT, DARK, DIRT = 0, 1, 2
# The pens at their biggest (tools/lobby_plants.luau), 88 square, facing the yard.
PENS = [(0, 218), (-110.3, 188.6), (110.3, 188.6), (-120.1, 74.8), (120.1, 74.8)]
PEN_HALF = 44
YARD = (0, 96)
PORTAL = (-63.5, 24.6)
COLOURS = {  # part, checker (tools/world2_meadow.luau)
    BRIGHT: [(206, 168, 58), (190, 152, 46)],
    DARK: [(182, 144, 44), (166, 130, 36)],
    DIRT: [(142, 101, 60), (128, 89, 52)],  # (QM: 20% lighter)
}


def centre(i, j):
    return -W + i * CELL + CELL / 2, j * CELL + CELL / 2


def gate(c):
    dx, dz = YARD[0] - c[0], YARD[1] - c[1]
    d = math.hypot(dx, dz)
    return c[0] + dx / d * PEN_HALF, c[1] + dz / d * PEN_HALF


def seg_dist(p, a, b):
    ax, az = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((p[0] - a[0]) * ax + (p[1] - a[1]) * az) / (ax * ax + az * az)))
    return math.hypot(p[0] - a[0] - t * ax, p[1] - a[1] - t * az)


def in_pen(x, z, grow=0):
    for c in PENS:
        a = math.atan2(YARD[0] - c[0], YARD[1] - c[1])
        u = (x - c[0]) * math.cos(a) - (z - c[1]) * math.sin(a)
        v = (x - c[0]) * math.sin(a) + (z - c[1]) * math.cos(a)
        if abs(u) < PEN_HALF + grow and abs(v) < PEN_HALF + grow:
            return True
    return False


def layout(seed=13):
    wob = noise(NX, NZ, 3, seed) - 0.5  # the dirt's ragged edge
    ring = noise(NX, NZ, 2.5, seed + 1)  # how thick the darker grass is
    spots = noise(NX, NZ, 3.5, seed + 2) * 0.7 + noise(NX, NZ, 1.5, seed + 3) * 0.3  # darker patches
    kind = np.full((NX, NZ), BRIGHT)
    for i in range(NX):
        for j in range(NZ):
            x, z = centre(i, j)
            # how far inside the dirt: > 0 is dirt
            yard = 1 - math.hypot(x / 64, (z - 100) / 52)
            lane = (22 - abs(x) + max(0, 12 - z) * 0.6) / 22 if z < 100 else -1  # flares onto the line
            paths = max(1 - seg_dist((x, z), YARD, gate(c)) / 9 for c in PENS)
            f = max(yard * 1.6, lane, paths) + wob[i, j] * 0.9
            if f > 0 and not in_pen(x, z) and abs(x) < W - 12 and z < 252 and math.hypot(x - PORTAL[0], z - PORTAL[1]) > 20:
                kind[i, j] = DIRT
    dirt = kind == DIRT
    # darker grass: every tile within 1 of dirt, out to 2 or 3 where the noise says
    near = [np.zeros_like(dirt) for _ in range(4)]
    near[0] = dirt
    for r in range(1, 4):
        g = near[r - 1].copy()
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                g |= np.roll(np.roll(near[r - 1], di, 0), dj, 1)
        near[r] = g
    reach = np.where(ring > 0.62, 3, np.where(ring > 0.42, 2, 1))
    for r in (1, 2, 3):
        kind[(near[r] & ~dirt) & (reach >= r)] = DARK
    kind[(spots > 0.72) & (kind == BRIGHT)] = DARK
    return kind


def check(kind):
    """Bright grass never touches dirt, even at a corner."""
    bad = 0
    for i in range(NX):
        for j in range(NZ):
            if kind[i, j] != BRIGHT:
                continue
            for di in (-1, 0, 1):
                for dj in (-1, 0, 1):
                    a, b = i + di, j + dj
                    if 0 <= a < NX and 0 <= b < NZ and kind[a, b] == DIRT:
                        bad += 1
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
        a = math.atan2(YARD[0] - c[0], YARD[1] - c[1])
        pts = [P(c[0] + u * math.cos(a) + v * math.sin(a), c[1] - u * math.sin(a) + v * math.cos(a))
               for u, v in ((-44, -44), (44, -44), (44, 44), (-44, 44))]
        d.polygon(pts, outline=(70, 46, 30), width=s)
    d.rectangle([*P(-56, 6), *P(56, 0)], outline=(255, 255, 255), width=s)
    d.ellipse([*P(PORTAL[0] - 12, PORTAL[1] + 12), *P(PORTAL[0] + 12, PORTAL[1] - 12)], outline=(236, 232, 224), width=s)
    im.save(out)


def world1():
    """World 1's base floor (tools/arc_base.luau's FLOOR) on the same grid."""
    import re
    src = open(os.path.join(HERE, "arc_base.luau")).read()
    kind = np.full((NX, NZ), BRIGHT)
    for m in re.finditer(r"\{ ([01]), (-?\d+), (-?\d+), (\d+), (\d+) \}", src):
        d, x, z, sx, sz = map(int, m.groups())
        kind[(x + W) // CELL:(x + sx + W) // CELL, z // CELL:(z + sz) // CELL] = DIRT if d else BRIGHT
    return kind


RAISED = 3  # the light grass a stud up (QM, Oct 13): a kind of its own in the Luau
PEN_FLAT = 64  # the ground stays flat this far round each pen's middle (its floor is at 0), as tools/world2_grass_step.luau


def raise_grass(kind):
    """The light grass a stud above the dark, but under the pens and the start line's row."""
    out = kind.copy()
    for i in range(NX):
        for j in range(1, NZ):
            x, z = -W + i * CELL + CELL / 2, j * CELL + CELL / 2
            if kind[i, j] == BRIGHT and all(math.hypot(x - c[0], z - c[1]) >= PEN_FLAT for c in PENS):
                out[i, j] = RAISED
    return out


def write_luau(kind):
    boxes = rects(raise_grass(kind))
    rows = []
    for k, i0, j0, i1, j1 in boxes:
        rows.append("\t{ %d, %d, %d, %d, %d }," % (k, -W + i0 * CELL, j0 * CELL, (i1 - i0) * CELL, (j1 - j0) * CELL))
    body = open(os.path.join(HERE, "world2_base.luau.in")).read()
    open(os.path.join(HERE, "world2_base.luau"), "w").write(body.replace("--FLOOR--", "\n".join(rows)))
    return len(boxes)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world2_base"
    os.makedirs(out, exist_ok=True)
    kind = layout()
    bad = check(kind)
    assert bad == 0, f"{bad} bright tiles touch dirt"
    render(kind, os.path.join(out, "world2_base.png"))
    render(world1(), os.path.join(out, "world1_base.png"))
    n = write_luau(kind)
    counts = {name: int((kind == k).sum()) for name, k in (("bright", BRIGHT), ("dark", DARK), ("dirt", DIRT))}
    print(counts, "touching:", bad, "parts:", n)


if __name__ == "__main__":
    main()
