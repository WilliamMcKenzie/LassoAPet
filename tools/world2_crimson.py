"""World 2's second biome, the Crimson Lands (QM, Oct 13; draft): its floor and stone plates.

Run: python3 tools/world2_crimson.py [out_dir]
     renders the layout and writes tools/world2_crimson.luau, which lays it in Studio
     over World2's copied second-biome floor (World 1's Desert).

Three tiles in a gradient: crimson ground #791425, brighter crimson #902C2B in
patches, and grey-rose stone #775656. Stone is only ever a single tile (the gradient's
peak) and always has brighter crimson on all eight sides (QM). Round the stone tiles,
on the brighter crimson, lie the stone plates from World 1's base (the StoneTile
meshes) on 4-stud checker squares, a few per stone tile and a few more further out,
so each stone tile reads as a stone patch fading into the crimson.

Laid out in game space after the funnel, like tools/world2_meadow_ground.py (8-stud
cells on x multiples of 8, each 40-stud band out to its widest end, under the walls).
Nothing stone within a tile of a wall; no plates under an obstacle or by a nest.
"""

import math
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects, NESTS as DESERT_NESTS  # noqa: E402
from funnel_grid import half_width, map_x  # noqa: E402

HERE = os.path.dirname(__file__)
WORLD = os.path.join(HERE, "..", "src", "world", "World.rbxmx")
CELL, BAND, BLOCK = 8, 40, 1000
Z0, Z1 = -2168, -3984  # the second biome's near and far ends
OUT = int(math.ceil(half_width(Z1) / CELL)) * CELL  # 80
NX, NZ = 2 * OUT // CELL, (Z0 - Z1) // CELL
VOID, GROUND, BRIGHT, STONE = -1, 0, 1, 2
COLOURS = {  # part, checker
    GROUND: [(121, 20, 37), (110, 17, 33)],  # #791425
    BRIGHT: [(144, 44, 43), (132, 38, 38)],  # #902C2B
    STONE: [(119, 86, 86), (108, 77, 77)],  # #775656
}
PLATE = [(119, 86, 86), (132, 98, 98)]  # the plates: the stone's colour and a touch lighter
GROW = 1.35 ** 0.8  # the funnel grows this biome's obstacles and nests (tools/funnel.luau)
NEST_CLEAR = 16


def centre(i, j):
    return -OUT + i * CELL + CELL / 2, Z0 - j * CELL - CELL / 2


def band_out(j):
    z_far = max(Z1, Z0 - (((j * CELL) // BAND) + 1) * BAND)
    return int(math.ceil(half_width(z_far) / CELL)) * CELL


def obstacles():
    """(x, z, radius) of the copied Desert obstacles in game space (their Base parts, funnelled)."""
    s = open(WORLD).read()
    a = s.index('<string name="Name">Obstacles</string>')
    out = []
    for m in re.finditer(r'<string name="Name">Base</string>.*?<CoordinateFrame name="CFrame"><X>([^<]*)</X><Y>[^<]*</Y><Z>([^<]*)</Z>.*?<Vector3 name="size"><X>([^<]*)</X><Y>[^<]*</Y><Z>([^<]*)</Z>', s[a:], re.S):
        x, z, sx, sz = map(float, m.groups())
        if Z1 < z < Z0:
            out.append((float(map_x(x, z)), z, max(sx, sz) / 2 * GROW))
    return out


def nests():
    return [(float(map_x(x, z)), z) for x, z in DESERT_NESTS]


def layout(seed=41):
    rng = np.random.default_rng(seed)
    patch = noise(NX, NZ, 3.4, seed) * 0.7 + noise(NX, NZ, 1.6, seed + 1) * 0.3
    kind = np.full((NX, NZ), GROUND)
    inside = np.zeros((NX, NZ), bool)  # far enough off the walls for stone
    for j in range(NZ):
        out = band_out(j)
        for i in range(NX):
            x, z = centre(i, j)
            if abs(x) > out:
                kind[i, j] = VOID
            elif abs(x) < half_width(z) - CELL * 1.5:
                inside[i, j] = True
    kind[(patch > 0.56) & (kind == GROUND)] = BRIGHT
    # Stone peaks: single tiles deep in the brighter patches (all eight sides bright), spaced out.
    order = [(i, j) for i in range(1, NX - 1) for j in range(1, NZ - 1)]
    rng.shuffle(order)
    order.sort(key=lambda c: -patch[c])  # the brightest middles first
    stones = []
    for i, j in order:
        if not inside[i, j] or patch[i, j] < 0.66 or rng.random() < 0.45:
            continue
        if any(max(abs(i - a), abs(j - b)) < 5 for a, b in stones):
            continue
        stones.append((i, j))
    for i, j in stones:  # (two tiles of bright crimson round each, room for its plates: QM wanted bigger stone patches)
        a, b = slice(max(i - 2, 0), i + 3), slice(max(j - 2, 0), j + 3)
        kind[a, b] = np.where(kind[a, b] == VOID, VOID, BRIGHT)
        kind[i, j] = STONE
    return kind, stones


def plates(kind, stones, seed=43):
    """Stone plates: (x, z, variant, yaw degrees) on 4-stud squares (4k + 2) of bright crimson
    round each stone tile: nearly all the squares beside it, most of the next ring out, a
    few in the ring past that, so each stone patch is about five tiles across (QM: bigger)."""
    rng = np.random.default_rng(seed)
    obs, nst = obstacles(), nests()
    out = []

    def free(x, z):
        i, j = int((x + OUT) // CELL), int((Z0 - z) // CELL)
        if not (0 <= i < NX and 0 <= j < NZ) or kind[i, j] != BRIGHT:
            return False
        if abs(x) > half_width(z) - 4:
            return False
        if any(math.hypot(x - a, z - b) < r + 3 for a, b, r in obs):
            return False
        if any(math.hypot(x - a, z - b) < NEST_CLEAR for a, b in nst):
            return False
        return all(math.hypot(x - a, z - b) > 3.9 for a, b, _, _ in out)

    for i, j in stones:
        x0, z0 = -OUT + i * CELL, Z0 - j * CELL  # the stone tile's corner (low x, near z)
        ring1 = [(x0 + dx, z0 - dz) for dx in (-2, 2, 6, 10) for dz in (-2, 2, 6, 10)
                 if not (0 < dx < 8 and 0 < dz < 8)]  # the 12 squares touching the tile
        ring2 = [(x0 + dx, z0 - dz) for dx in (-6, -2, 2, 6, 10, 14) for dz in (-6, -2, 2, 6, 10, 14)
                 if dx in (-6, 14) or dz in (-6, 14)]  # the 20 squares one further out
        ring3 = [(x0 + dx, z0 - dz) for dx in range(-10, 19, 4) for dz in range(-10, 19, 4)
                 if dx in (-10, 18) or dz in (-10, 18)]  # the 28 squares further out still
        rng.shuffle(ring1)
        rng.shuffle(ring2)
        rng.shuffle(ring3)
        for spots, n in ((ring1, rng.integers(9, 13)), (ring2, rng.integers(9, 15)), (ring3, rng.integers(3, 8))):
            k = 0
            for x, z in spots:
                if k >= n:
                    break
                if free(x, z):
                    out.append((x, z, int(rng.integers(1, 4)), int(rng.integers(0, 4)) * 90 + int(rng.integers(-8, 9))))
                    k += 1
    return out


def check(kind):
    """Every stone tile is alone and has bright crimson on all eight sides."""
    bad = 0
    for i, j in zip(*np.nonzero(kind == STONE)):
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                if (di or dj) and not (0 <= i + di < NX and 0 <= j + dj < NZ and kind[i + di, j + dj] == BRIGHT):
                    bad += 1
    return bad


def boxes(kind):
    out = []
    rows = BLOCK // CELL
    for j0 in range(0, NZ, rows):
        for k, i0, a, i1, b in rects(kind[:, j0:j0 + rows]):
            if k != VOID:
                out.append((int(k), -OUT + i0 * CELL, Z0 - (j0 + a) * CELL, (i1 - i0) * CELL, (b - a) * CELL))
    return out


def render(kind, pl, out, s=2, rows=4):
    seg = int(math.ceil(NZ / rows))
    w, h = NX * CELL * s, seg * CELL * s
    im = Image.new("RGB", (rows * (w + 20), h), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for r in range(rows):
        ox = r * (w + 20)

        def P(x, z):
            return ox + (x + OUT) * s, (Z0 - z - r * seg * CELL) * s

        def here(z):
            return r * seg * CELL <= Z0 - z < (r + 1) * seg * CELL

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
        for x, z, v, yaw in pl:
            if here(z):
                c = math.cos(math.radians(yaw)) * 1.7, math.sin(math.radians(yaw)) * 1.7
                pts = [P(x + c[0] * a - c[1] * b, z + c[1] * a + c[0] * b) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
                d.polygon(pts, fill=PLATE[v % 2], outline=(96, 66, 66))
        for x, z, rad in obstacles():
            if here(z):
                d.ellipse([*P(x - rad, z + rad), *P(x + rad, z - rad)], outline=(60, 60, 70), width=s)
        for x, z in nests():
            if here(z):
                d.ellipse([*P(x - 6, z + 6), *P(x + 6, z - 6)], outline=(255, 255, 255), width=s)
        for j in range(r * seg, min(NZ, (r + 1) * seg)):
            z = Z0 - j * CELL
            for sg in (-1, 1):
                d.line([P(sg * half_width(z), z), P(sg * half_width(z - CELL), z - CELL)], fill=(236, 232, 224), width=2 * s)
    im.save(out)


def write_luau(parts, pl):
    floor = "\n".join("\t{ %d, %d, %d, %d, %d }," % p for p in parts)
    plates_ = "\n".join("\t{ %g, %g, %d, %d }," % p for p in pl)
    body = open(os.path.join(HERE, "world2_crimson.luau.in")).read()
    open(os.path.join(HERE, "world2_crimson.luau"), "w").write(body.replace("--FLOOR--", floor).replace("--PLATES--", plates_))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world2_crimson"
    os.makedirs(out, exist_ok=True)
    kind, stones = layout()
    bad = check(kind)
    assert bad == 0, f"{bad} stone tiles not ringed by bright crimson"
    pl = plates(kind, stones)
    parts = boxes(kind)
    assert all(p[3] <= 2048 and p[4] <= 2048 for p in parts)
    render(kind, pl, os.path.join(out, "crimson_overhead.png"))
    write_luau(parts, pl)
    print({n: int((kind == k).sum()) for n, k in (("ground", GROUND), ("bright", BRIGHT), ("stone", STONE))},
          "plates:", len(pl), "parts:", len(parts))


if __name__ == "__main__":
    main()
