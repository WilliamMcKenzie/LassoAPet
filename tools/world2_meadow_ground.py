"""World 2's first biome floor (QM, Oct 13): yellow grass, darker yellow grass, brown dirt.

Run: python3 tools/world2_meadow_ground.py [out_dir]
     renders the layout and writes tools/world2_meadow_ground.luau, which lays it in
     Studio over World2's copied first-biome floor.

Same rule as the base (tools/world2_base.py): the three tiles are a gradient, so bright
grass never touches dirt, not even at a corner; darker grass rings every bit of dirt,
one to three tiles thick, and lies in a few patches out in the bright grass too.

Laid out in game space, after the funnel (World2 is a copy of the funnelled World):
8-stud cells on x multiples of 8, so the 4-stud checker lines up. The floor reaches
out under the angled walls (each 40-stud band as wide as its far, widest end). No dirt
within two tiles of a wall, under an obstacle or by a nest, or in the first two rows
past the home line, where the base's own dirt lane meets it.
"""

import json
import math
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects  # noqa: E402
from funnel_grid import half_width, map_x  # noqa: E402
import world2_base as base  # noqa: E402

HERE = os.path.dirname(__file__)
WORLD = os.path.join(HERE, "..", "src", "world", "World.rbxmx")
CELL, BAND, BLOCK = 8, 40, 1000  # parts never cross a BAND line; merged no longer than BLOCK (<= 2048)
LENGTH = 2168  # the first biome (Config Meadow)
OUT = int(math.ceil(half_width(-LENGTH) / CELL)) * CELL  # 72: the widest the floor gets
NX, NZ = 2 * OUT // CELL, int(math.ceil(LENGTH / CELL))
VOID, BRIGHT, DARK, DIRT = -1, base.BRIGHT, base.DARK, base.DIRT
NESTS = [(-20, -470), (22, -600), (-20, -1174), (22, -1304), (-20, -1878), (22, -2008), (0, -2144)]  # tools/meadow_ground.py
NEST_CLEAR = 14


def centre(i, j):
    return -OUT + i * CELL + CELL / 2, -j * CELL - CELL / 2


def band_out(j):
    """Half width of the floor in row j: its band's far end, rounded out to a cell."""
    z_far = -min(LENGTH, ((j * CELL) // BAND + 1) * BAND)
    return int(math.ceil(half_width(z_far) / CELL)) * CELL


def obstacles():
    """(x, z, radius) of the first biome's obstacles in game space (their Base parts, funnelled)."""
    s = open(WORLD).read()
    out = []
    a = s.index('<string name="Name">Obstacles</string>')
    for m in re.finditer(r'<string name="Name">Base</string>.*?<CoordinateFrame name="CFrame"><X>([^<]*)</X><Y>[^<]*</Y><Z>([^<]*)</Z>.*?<Vector3 name="size"><X>([^<]*)</X><Y>[^<]*</Y><Z>([^<]*)</Z>', s[a:], re.S):
        x, z, sx, sz = map(float, m.groups())
        if -LENGTH - 20 < z < 0:
            out.append((float(map_x(x, z)), z, max(sx, sz) / 2))
    return out


def tidy(dirt, allowed, keep=8):
    """Smooth the dirt (a cell is dirt when most of its 3x3 is, twice; no lone strands)
    and drop any patch smaller than `keep` cells."""
    for _ in range(2):
        p = np.pad(dirt, 1).astype(int)
        n = sum(p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ] for di in (-1, 0, 1) for dj in (-1, 0, 1))
        dirt = (dirt & (n >= 4) | (n >= 6)) & allowed
    seen = np.zeros_like(dirt)
    for i in range(NX):
        for j in range(NZ):
            if dirt[i, j] and not seen[i, j]:
                comp, todo = [], [(i, j)]
                seen[i, j] = True
                while todo:
                    a, b = todo.pop()
                    comp.append((a, b))
                    for c, d in ((a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)):
                        if 0 <= c < NX and 0 <= d < NZ and dirt[c, d] and not seen[c, d]:
                            seen[c, d] = True
                            todo.append((c, d))
                if len(comp) < keep:
                    for a, b in comp:
                        dirt[a, b] = False
    return dirt


def layout(seed=29):
    wob = noise(NX, NZ, 3.2, seed) * 0.7 + noise(NX, NZ, 1.6, seed + 1) * 0.3
    ring = noise(NX, NZ, 2.5, seed + 2)
    spots = noise(NX, NZ, 3.5, seed + 3) * 0.7 + noise(NX, NZ, 1.5, seed + 4) * 0.3
    obs = obstacles()
    kind = np.full((NX, NZ), BRIGHT)
    allowed = np.zeros((NX, NZ), bool)
    for j in range(NZ):
        out = band_out(j)
        for i in range(NX):
            x, z = centre(i, j)
            if abs(x) > out:
                kind[i, j] = VOID
                continue
            if j < 2 or abs(x) > half_width(z) - 2 * CELL:
                continue
            if any(math.hypot(x - nx, z - nz) < NEST_CLEAR + CELL for nx, nz in [(float(map_x(a, b)), b) for a, b in NESTS]):
                continue
            if any(math.hypot(x - ox, z - oz) < r + CELL for ox, oz, r in obs):
                continue
            allowed[i, j] = True
    dirt = tidy((wob >= 0.62) & allowed, allowed)
    kind[dirt] = DIRT
    near = [dirt]
    for _ in range(3):
        g = near[-1].copy()
        p = np.pad(near[-1], 1)
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                g |= p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]
        near.append(g)
    reach = np.where(ring > 0.72, 3, np.where(ring > 0.55, 2, 1))  # (mostly one tile: the course is narrow)
    for r in (1, 2, 3):
        kind[near[r] & (kind == BRIGHT) & (reach >= r)] = DARK
    kind[(spots > 0.8) & (kind == BRIGHT)] = DARK
    # The home line: the base's first row of cells lies against row 0 here.
    b = base.layout()
    for i in range(NX):
        x = -OUT + i * CELL + CELL / 2
        for dx in (-CELL, 0, CELL):
            bi = int((x + dx + base.W) // CELL)
            if 0 <= bi < base.NX and b[bi, 0] == DIRT and kind[i, 0] == BRIGHT:
                kind[i, 0] = DARK
    return kind


def check(kind):
    """Bright grass never touches dirt, even at a corner, here or across the home line."""
    bad = 0
    p = np.pad(kind == DIRT, 1)
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            bad += int(((kind == BRIGHT) & p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]).sum())
    b = base.layout()
    for i in range(NX):
        x = -OUT + i * CELL + CELL / 2
        for dx in (-CELL, 0, CELL):
            bi = int((x + dx + base.W) // CELL)
            if 0 <= bi < base.NX and ((b[bi, 0] == DIRT and kind[i, 0] == BRIGHT) or (b[bi, 0] == BRIGHT and kind[i, 0] == DIRT)):
                bad += 1
    return bad


def boxes(kind):
    """(kind, x0, z_top, sx, sz) parts, merged within each BLOCK of rows (VOID cells keep the edges exact)."""
    out = []
    rows = BLOCK // CELL
    for j0 in range(0, NZ, rows):
        sub = kind[:, j0:j0 + rows]
        for k, i0, a, i1, b in rects(sub):
            if k == VOID:
                continue
            out.append((int(k), -OUT + i0 * CELL, -(j0 + a) * CELL, (i1 - i0) * CELL, (b - a) * CELL))
    return out


def render(kind, out, s=2, rows=4):
    seg = int(math.ceil(NZ / rows))
    w, h = NX * CELL * s, seg * CELL * s
    im = Image.new("RGB", (rows * (w + 20), h), (255, 255, 255))
    d = ImageDraw.Draw(im)
    obs = obstacles()
    for r in range(rows):
        ox = r * (w + 20)
        for j in range(r * seg, min(NZ, (r + 1) * seg)):
            for i in range(NX):
                k = int(kind[i, j])
                if k == VOID:
                    continue
                for a in range(2):
                    for b in range(2):
                        col = base.COLOURS[k][(i * 2 + a + j * 2 + b) % 2]
                        x0, y0 = ox + (i * CELL + a * 4) * s, ((j - r * seg) * CELL + b * 4) * s
                        d.rectangle([x0, y0, x0 + 4 * s - 1, y0 + 4 * s - 1], fill=col)

        def P(x, z):
            return ox + (x + OUT) * s, (-z - r * seg * CELL) * s

        for x, z, rad in obs:
            if r * seg * CELL <= -z < (r + 1) * seg * CELL:
                d.ellipse([*P(x - rad, z + rad), *P(x + rad, z - rad)], outline=(150, 150, 160), width=s)
        for a, z in NESTS:
            x = float(map_x(a, z))
            if r * seg * CELL <= -z < (r + 1) * seg * CELL:
                d.ellipse([*P(x - 6, z + 6), *P(x + 6, z - 6)], outline=(255, 255, 255), width=s)
        for j in range(r * seg, min(NZ, (r + 1) * seg)):
            z = -j * CELL
            for sgn in (-1, 1):
                x = sgn * half_width(z)
                d.point(P(x, z), fill=(236, 232, 224))
                d.line([P(x, z), P(sgn * half_width(z - CELL), z - CELL)], fill=(236, 232, 224), width=2 * s)
    im.save(out)


def write_luau(parts):
    rows = ["\t{ %d, %d, %d, %d, %d }," % p for p in parts]
    body = open(os.path.join(HERE, "world2_meadow_ground.luau.in")).read()
    open(os.path.join(HERE, "world2_meadow_ground.luau"), "w").write(body.replace("--FLOOR--", "\n".join(rows)))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world2_base"
    os.makedirs(out, exist_ok=True)
    kind = layout()
    bad = check(kind)
    assert bad == 0, f"{bad} bright tiles touch dirt"
    parts = boxes(kind)
    assert all(p[3] <= 2048 and p[4] <= 2048 for p in parts)
    render(kind, os.path.join(out, "world2_meadow.png"))
    write_luau(parts)
    print({n: int((kind == k).sum()) for n, k in (("bright", BRIGHT), ("dark", DARK), ("dirt", DIRT))}, "parts:", len(parts))


if __name__ == "__main__":
    main()
