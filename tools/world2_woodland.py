"""World 2's fourth biome, the Woodland Maze (QM, Oct 13; draft): an autumn forest floor.

Run: python3 tools/world2_woodland.py [out_dir]
     renders the layout and writes tools/world2_woodland.luau, which lays it in Studio
     over World2's copied fourth-biome floor (World 1's Ocean).

Like the Crystal Cavern (tools/world2_woodland.py): a gradient from the walls in,
#79482E (darkest) along the walls, #8E5139, then #975939 (lightest) down the middle,
darkest never touching lightest. Scattered over it, drifts of fallen leaves: each
tile of a drift one of the leaf colours (orange #F26D39, yellow #FEEA5C, and a red
#D8432E standing in for the third, which QM's message gave as orange twice).

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
Z0, Z1 = -5904, -9024  # the fourth biome's near and far ends
OUT = int(math.ceil(half_width(Z1) / CELL)) * CELL  # 104
NX, NZ = 2 * OUT // CELL, (Z0 - Z1) // CELL
VOID, DARK, MID, LIGHT, ORANGE, YELLOW, RED = -1, 0, 1, 2, 3, 4, 5
LEAVES = (ORANGE, YELLOW, RED)
COLOURS = {  # part, checker
    DARK: [(121, 72, 46), (110, 65, 41)],  # #79482E
    MID: [(142, 81, 57), (130, 74, 52)],  # #8E5139
    LIGHT: [(151, 89, 57), (139, 81, 52)],  # #975939
    ORANGE: [(242, 109, 57), (228, 98, 48)],  # #F26D39
    YELLOW: [(254, 234, 92), (242, 218, 76)],  # #FEEA5C
    RED: [(216, 67, 46), (200, 58, 40)],  # #D8432E (a stand-in)
}


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
    # Darkest never touches lightest (or the planks): the middle shade between.
    for _ in range(2):
        p = np.pad(kind == DARK, 1)
        near = np.zeros_like(p[1:-1, 1:-1])
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                near |= p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]
        kind[near & (kind == LIGHT)] = MID
    # Fallen leaves: noise blobs a few tiles across, anywhere but against the walls; each
    # tile a leaf colour from a second, slower noise (so colours drift in drifts), a few
    # tiles flipped to another colour for a scattered look.
    rng = np.random.default_rng(seed)
    pile = noise(NX, NZ, 4.5, seed + 7) * 0.8 + noise(NX, NZ, 2, seed + 8) * 0.2
    hue = noise(NX, NZ, 6, seed + 9)
    for i in range(NX):
        for j in range(NZ):
            if kind[i, j] in (DARK, MID, LIGHT) and pile[i, j] > 0.74:
                x, z = centre(i, j)
                if abs(x) < half_width(z) - CELL * 1.5:
                    c = LEAVES[min(2, int(hue[i, j] * 3))]
                    kind[i, j] = c if rng.random() < 0.75 else LEAVES[int(rng.integers(0, 3))]
    return kind


def check(kind):
    bad = 0
    p = np.pad(kind == DARK, 1)
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            bad += int(((kind == LIGHT) & p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]).sum())
    return bad


def boxes(kind):
    out = []
    rows = BLOCK // CELL
    for j0 in range(0, NZ, rows):
        for k, i0, a, i1, b in rects(kind[:, j0:j0 + rows]):
            if k != VOID:
                out.append((int(k), -OUT + i0 * CELL, Z0 - (j0 + a) * CELL, (i1 - i0) * CELL, (b - a) * CELL))
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
                        col = COLOURS[k][(i * 2 + a + j * 2 + b) % 2]
                        x0, y0 = ox + (i * CELL + a * 4) * s, ((j - r * seg) * CELL + b * 4) * s
                        d.rectangle([x0, y0, x0 + 4 * s - 1, y0 + 4 * s - 1], fill=col)
        for j in range(r * seg, min(NZ, (r + 1) * seg)):
            z = Z0 - j * CELL
            for sg in (-1, 1):
                x0, x1 = sg * half_width(z), sg * half_width(z - CELL)
                d.line([P(x0, z), P(x1, z - CELL)], fill=(236, 232, 224), width=2 * s)
    im.save(out)


def write_luau(parts):
    floor = "\n".join("\t{ %d, %d, %d, %d, %d }," % p for p in parts)
    body = open(os.path.join(HERE, "world2_woodland.luau.in")).read()
    open(os.path.join(HERE, "world2_woodland.luau"), "w").write(body.replace("--FLOOR--", floor))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world2_woodland"
    os.makedirs(out, exist_ok=True)
    kind = layout()
    bad = check(kind)
    assert bad == 0, f"{bad} lightest tiles touch the darkest"
    parts = boxes(kind)
    assert all(p[3] <= 2048 and p[4] <= 2048 for p in parts)
    render(kind, os.path.join(out, "woodland_overhead.png"))
    write_luau(parts)
    print({n: int((kind == k).sum()) for n, k in (("dark", DARK), ("mid", MID), ("light", LIGHT), ("orange", ORANGE), ("yellow", YELLOW), ("red", RED))},
          "parts:", len(parts))


if __name__ == "__main__":
    main()
