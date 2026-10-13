"""World 2's second biome, the Crimson Lands (QM, Oct 13; draft): its floor and stone plates.

Run: python3 tools/world2_crimson.py [out_dir]
     renders the layout and writes tools/world2_crimson.luau, which lays it in Studio
     over World2's copied second-biome floor (World 1's Desert).

Three tiles in a gradient: crimson ground #791425, brighter crimson #902C2B a stud
higher, and grey-rose stone #775656 a stud higher again. The stone lies in real tile
patches, big, sometimes joined up and sometimes running into a wall (QM), always with
brighter crimson between it and the crimson ground, one or two tiles of it. A few of
World 1's base stone plates (the StoneTile meshes) lie on the brighter crimson along
the stone's edges.

Laid out in game space after the funnel, like tools/world2_meadow_ground.py (8-stud
cells on x multiples of 8, each 40-stud band out to its widest end, under the walls).
No plates against a wall.
"""

import math
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects  # noqa: E402
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
TOPS = {GROUND: 0, BRIGHT: 1, STONE: 2}  # tile heights (QM: height variation): crimson, a step up, the stone peak another
PLATE = [(119, 86, 86), (132, 98, 98)]  # the plates: the stone's colour and a touch lighter
GROW = 1.35 ** 0.8  # the funnel grows this biome's obstacles and nests (tools/funnel.luau)


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


def grow(mask, n=1):
    """Cells within n tiles (8-way) of the mask."""
    for _ in range(n):
        p = np.pad(mask, 1)
        mask = mask.copy()
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                mask |= p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]
    return mask


def drop_small(mask, keep):
    """The mask without its (4-way) pieces smaller than keep cells."""
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


def layout(seed=41):
    """Stone in real tile patches (QM, Oct 13: bigger, sometimes joined, sometimes running
    into a wall), each ringed by one or two tiles of brighter crimson, on crimson ground."""
    stone_n = noise(NX, NZ, 4.2, seed) * 0.75 + noise(NX, NZ, 1.8, seed + 1) * 0.25
    walls_n = noise(NX, NZ, 9, seed + 2)  # stretches where the stone runs to the walls
    ring = noise(NX, NZ, 2.5, seed + 3)
    glow = noise(NX, NZ, 3.4, seed + 4) * 0.7 + noise(NX, NZ, 1.6, seed + 5) * 0.3
    kind = np.full((NX, NZ), GROUND)
    for j in range(NZ):
        out = band_out(j)
        for i in range(NX):
            x, z = centre(i, j)
            if abs(x) > out:
                kind[i, j] = VOID
                continue
            near_wall = abs(x) > half_width(z) - CELL * 2.5
            if near_wall and walls_n[i, j] > 0.55:
                stone_n[i, j] += 0.14  # (pulls the stone out to the wall there)
    floor = kind != VOID
    stone = (stone_n > 0.64) & floor
    p = np.pad(stone, 1).astype(int)
    n = sum(p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ] for di in (-1, 0, 1) for dj in (-1, 0, 1))
    stone = ((stone & (n >= 4)) | (n >= 6)) & floor  # (smoothed: no lone strands)
    stone = drop_small(stone, 5)
    reach = np.where(ring > 0.6, 2, 1)
    bright = (grow(stone, 1) | (grow(stone, 2) & (reach == 2)) | (glow > 0.7)) & floor & ~stone
    kind[bright] = BRIGHT
    kind[stone] = STONE
    return kind


def plates(kind, seed=43):
    """A few stone plates: (x, z, variant, yaw degrees) on 4-stud squares (4k + 2) of the
    brighter crimson right beside the stone, about one bright tile in five along its edge."""
    rng = np.random.default_rng(seed)
    edge = grow(kind == STONE, 1) & (kind == BRIGHT)
    out = []
    for i, j in zip(*np.nonzero(edge)):
        if rng.random() > 0.2:
            continue
        x = -OUT + i * CELL + 2 + 4 * int(rng.integers(0, 2))
        z = Z0 - j * CELL - 2 - 4 * int(rng.integers(0, 2))
        if abs(x) > half_width(z) - 4:
            continue
        out.append((x, z, int(rng.integers(1, 4)), int(rng.integers(0, 4)) * 90 + int(rng.integers(-8, 9))))
    return out


def check(kind):
    """Stone never touches the crimson ground: brighter crimson always between."""
    p = np.pad(kind == STONE, 1)
    return int(sum(((kind == GROUND) & p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]).sum()
                   for di in (-1, 0, 1) for dj in (-1, 0, 1)))


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
        for j in range(r * seg, min(NZ, (r + 1) * seg)):
            z = Z0 - j * CELL
            for sg in (-1, 1):
                d.line([P(sg * half_width(z), z), P(sg * half_width(z - CELL), z - CELL)], fill=(236, 232, 224), width=2 * s)
    im.save(out)


def write_luau(parts, pl):
    floor = "\n".join("\t{ %d, %d, %d, %d, %d, %d }," % p for p in parts)
    plates_ = "\n".join("\t{ %g, %g, %d, %d, %d }," % (*p, TOPS[BRIGHT]) for p in pl)  # (plates lie on the bright crimson)
    body = open(os.path.join(HERE, "world2_crimson.luau.in")).read()
    open(os.path.join(HERE, "world2_crimson.luau"), "w").write(body.replace("--FLOOR--", floor).replace("--PLATES--", plates_))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world2_crimson"
    os.makedirs(out, exist_ok=True)
    kind = layout()
    bad = check(kind)
    assert bad == 0, f"{bad} stone tiles touch the crimson ground"
    pl = plates(kind)
    top = np.vectorize(lambda k: TOPS.get(int(k), 0))(kind)
    parts = boxes(kind, top)
    assert all(p[3] <= 2048 and p[4] <= 2048 for p in parts)
    render(kind, pl, os.path.join(out, "crimson_overhead.png"))
    write_luau(parts, pl)
    print({n: int((kind == k).sum()) for n, k in (("ground", GROUND), ("bright", BRIGHT), ("stone", STONE))},
          "plates:", len(pl), "parts:", len(parts))


if __name__ == "__main__":
    main()
