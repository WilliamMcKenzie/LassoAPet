"""World 2's third biome, the Crystal Cavern (QM, Oct 13; draft): its floor and walls.

Run: python3 tools/world2_cavern.py [out_dir]
     renders the layout and writes tools/world2_cavern.luau, which lays it in Studio over
     World2's copied third-biome floor (World 1's Tundra) and paints its walls.

Walls #384867. The floor is a gradient from the walls in: #5A6D8F (darkest) along
the walls, #6281A7, then #74BAD5 (lightest) down the middle, the bands wavering so
they read as natural. Darkest never touches lightest: there's always the middle shade
between. Each shade is a step: the light middle at 0, the middle shade a stud up, the
darkest two, so the floor rises toward the walls. Twice along the biome the light middle turns to wooden planks for a long
stretch (boards across the course, a few hundred studs each), their ends ragged.

Laid out in game space after the funnel, like tools/world2_meadow_ground.py.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects  # noqa: E402
from funnel_grid import half_width  # noqa: E402

HERE = os.path.dirname(__file__)
CELL, BAND, BLOCK = 8, 40, 1000
Z0, Z1 = -3984, -5904  # the third biome's near and far ends
OUT = int(math.ceil(half_width(Z1) / CELL)) * CELL  # 88
NX, NZ = 2 * OUT // CELL, (Z0 - Z1) // CELL
VOID, DARK, MID, LIGHT, PLANKS = -1, 0, 1, 2, 3
COLOURS = {  # part, checker
    DARK: [(90, 109, 143), (82, 99, 131)],  # #5A6D8F
    MID: [(98, 129, 167), (89, 118, 153)],  # #6281A7
    LIGHT: [(116, 186, 213), (105, 171, 197)],  # #74BAD5
    PLANKS: [(150, 98, 56), (132, 84, 46)],  # boards, alternating
}
WALL = [(56, 72, 103), (48, 62, 90)]  # #384867, checker
CAP = (44, 57, 82)
TOPS = {DARK: 2, MID: 1, LIGHT: 0, PLANKS: 0}  # tile heights (QM): the floor steps up toward the walls
STRETCHES = [(0.18, 0.34), (0.6, 0.8)]  # the plank stretches, as fractions of the biome's length


def centre(i, j):
    return -OUT + i * CELL + CELL / 2, Z0 - j * CELL - CELL / 2


def band_out(j):
    z_far = max(Z1, Z0 - (((j * CELL) // BAND) + 1) * BAND)
    return int(math.ceil(half_width(z_far) / CELL)) * CELL


def layout(seed=53):
    a = noise(NX, NZ, 3, seed) * 0.7 + noise(NX, NZ, 1.5, seed + 1) * 0.3  # dark band's wobble
    b = noise(NX, NZ, 3, seed + 2) * 0.7 + noise(NX, NZ, 1.5, seed + 3) * 0.3  # light band's wobble
    kind = np.full((NX, NZ), LIGHT)
    for j in range(NZ):
        out = band_out(j)
        for i in range(NX):
            x, z = centre(i, j)
            if abs(x) > out:
                kind[i, j] = VOID
                continue
            d = (half_width(z) - abs(x)) / CELL  # tiles in from the wall
            if d < 1 + a[i, j] * 2.4:
                kind[i, j] = DARK
            elif d < 3 + b[i, j] * 3:
                kind[i, j] = MID
    # Planks: the light middle, for two long stretches, each row's ends a tile in or out.
    rng = np.random.default_rng(seed)
    for f0, f1 in STRETCHES:
        j0, j1 = int(f0 * NZ), int(f1 * NZ)
        j0 += int(rng.integers(-2, 3))
        for j in range(j0, j1):
            row = kind[:, j]
            light = np.nonzero(row == LIGHT)[0]
            if len(light) == 0:
                continue
            lo, hi = light.min(), light.max()
            if j in (j0, j1 - 1) or rng.random() < 0.3:  # ragged ends and edges
                lo, hi = lo + int(rng.integers(0, 2)), hi - int(rng.integers(0, 2))
            for i in range(lo, hi + 1):
                if row[i] == LIGHT:
                    kind[i, j] = PLANKS
    # Darkest never touches lightest (or the planks): the middle shade between.
    for _ in range(2):
        p = np.pad(kind == DARK, 1)
        near = np.zeros_like(p[1:-1, 1:-1])
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                near |= p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]
        kind[near & ((kind == LIGHT) | (kind == PLANKS))] = MID
    return kind


def check(kind):
    bad = 0
    p = np.pad(kind == DARK, 1)
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            bad += int((((kind == LIGHT) | (kind == PLANKS)) & p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]).sum())
    return bad


def boxes(kind, top):
    """(kind, x0, z_top, sx, sz, top) parts, merged by kind and height within each BLOCK of rows."""
    key = np.where(kind == VOID, -1, kind * 10 + top)
    out = []
    rows = BLOCK // CELL
    for j0 in range(0, NZ, rows):
        for k, i0, a, i1, b in rects(key[:, j0:j0 + rows]):
            if k != -1:
                out.append((int(k) // 10, -OUT + i0 * CELL, Z0 - (j0 + a) * CELL, (i1 - i0) * CELL, (b - a) * CELL, int(k) % 10))
    return out


def render(kind, out, s=2, rows=4):
    seg = int(math.ceil(NZ / rows))
    w, h = NX * CELL * s, seg * CELL * s
    im = Image.new("RGB", (rows * (w + 20), h), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for r in range(rows):
        ox = r * (w + 20)

        def P(x, z):
            return ox + (x + OUT) * s, (Z0 - z - r * seg * CELL) * s

        for j in range(r * seg, min(NZ, (r + 1) * seg)):
            for i in range(NX):
                k = int(kind[i, j])
                if k == VOID:
                    continue
                for a in range(2):
                    for b in range(2):
                        # (planks: boards across the course, 4 studs deep, alternating)
                        col = COLOURS[k][(b + j * 2) % 2] if k == PLANKS else COLOURS[k][(i * 2 + a + j * 2 + b) % 2]
                        x0, y0 = ox + (i * CELL + a * 4) * s, ((j - r * seg) * CELL + b * 4) * s
                        d.rectangle([x0, y0, x0 + 4 * s - 1, y0 + 4 * s - 1], fill=col)
        for j in range(r * seg, min(NZ, (r + 1) * seg)):
            z = Z0 - j * CELL
            for sg in (-1, 1):
                x0, x1 = sg * half_width(z), sg * half_width(z - CELL)
                d.polygon([P(x0, z), P(x1, z - CELL), P(sg * (OUT + 4), z - CELL), P(sg * (OUT + 4), z)], fill=WALL[0])
    im.save(out)


def write_luau(parts):
    floor = "\n".join("\t{ %d, %d, %d, %d, %d, %d }," % p for p in parts)
    body = open(os.path.join(HERE, "world2_cavern.luau.in")).read()
    open(os.path.join(HERE, "world2_cavern.luau"), "w").write(body.replace("--FLOOR--", floor))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world2_cavern"
    os.makedirs(out, exist_ok=True)
    kind = layout()
    bad = check(kind)
    assert bad == 0, f"{bad} lightest tiles touch the darkest"
    top = np.vectorize(lambda k: TOPS.get(int(k), 0))(kind)
    parts = boxes(kind, top)
    assert all(p[3] <= 2048 and p[4] <= 2048 for p in parts)
    render(kind, os.path.join(out, "cavern_overhead.png"))
    write_luau(parts)
    print({n: int((kind == k).sum()) for n, k in (("dark", DARK), ("mid", MID), ("light", LIGHT), ("planks", PLANKS))},
          "parts:", len(parts))


if __name__ == "__main__":
    main()
