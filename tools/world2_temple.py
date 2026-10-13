"""World 2's fifth biome, the Temple (QM, Oct 13; draft): an old rocky path through grass.

Run: python3 tools/world2_temple.py [out_dir]
     renders the layout and writes tools/world2_temple.luau, which lays it in Studio over
     World2's copied fifth-biome floor (World 1's Volcano) and paints its walls.

- An old rocky path #9E8D74 down the middle, wandering a little, grass #91B229 either
  side of it (a stud up, the path worn into it).
- In the first half, one or two little ponds in the grass, ringed by the path's rock,
  with a few lily pads. Their water is named Water (shallow, a stud down) and
  DeepWater (same level, deep only by its tint) so Studio can run the flowing-water texture over them.
- In the second half the rock spreads out to the dirt, the grass thins to the odd patch, and marble
  #C8C8C8 lies in it, a stud up, always with rock on all eight sides.
- Down both sides of the whole biome, a strip of #C8C8C8 dirt (the mesh thread's trees
  go in it later; QM scrapped the bonsai placeholders).
- Walls #C8C8C8 (QM: stone).

Laid out in game space after the funnel, like tools/world2_cavern.py.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects  # noqa: E402
from funnel_grid import half_width, map_x  # noqa: E402

HERE = os.path.dirname(__file__)
CELL, BAND, BLOCK = 8, 40, 1000
Z0, Z1 = -9024, -14064  # the fifth biome's near and far ends
OUT = int(math.ceil(half_width(Z1) / CELL)) * CELL  # 128
NX, NZ = 2 * OUT // CELL, (Z0 - Z1) // CELL
VOID, ROCK, GRASS, MARBLE, SIDE, WATER, DEEP = -1, 0, 1, 2, 3, 4, 5
COLOURS = {  # part, checker
    ROCK: [(158, 141, 116), (146, 130, 106)],  # #9E8D74
    GRASS: [(145, 178, 41), (133, 164, 35)],  # #91B229
    MARBLE: [(200, 200, 200), (186, 186, 186)],  # #C8C8C8
    SIDE: [(200, 200, 200), (190, 188, 184)],  # #C8C8C8 dirt
    WATER: [(70, 156, 204), (62, 144, 190)],  # (Studio's flowing texture goes over these)
    DEEP: [(44, 110, 168), (38, 99, 154)],
}
TOPS = {ROCK: 0, GRASS: 1, MARBLE: 1, SIDE: 1, WATER: -1, DEEP: -1}  # (all water level, QM: deep only its tint)
WALL, CAP = [(200, 200, 200), (186, 186, 186)], (176, 176, 176)
LILY = (86, 150, 50)
SIDE_W = 2  # tiles of dirt in from each wall


def centre(i, j):
    return -OUT + i * CELL + CELL / 2, Z0 - j * CELL - CELL / 2


def band_out(j):
    z_far = max(Z1, Z0 - (((j * CELL) // BAND) + 1) * BAND)
    return int(math.ceil(half_width(z_far) / CELL)) * CELL


def grow(mask):
    p = np.pad(mask, 1)
    out = mask.copy()
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            out |= p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]
    return out


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


def layout(seed=61):
    rng = np.random.default_rng(seed)
    wander = noise(1, NZ, 40, seed)[0] - 0.5  # the path's middle, drifting side to side
    edge = noise(NX, NZ, 4, seed + 1) - 0.5  # its ragged edge
    patches = noise(NX, NZ, 5, seed + 2) * 0.8 + noise(NX, NZ, 2, seed + 3) * 0.2
    inlay = noise(NX, NZ, 4, seed + 4) * 0.8 + noise(NX, NZ, 2, seed + 5) * 0.2
    kind = np.full((NX, NZ), GRASS)
    for j in range(NZ):
        out = band_out(j)
        t = j / NZ  # 0 at the near end, 1 at the far
        for i in range(NX):
            x, z = centre(i, j)
            if abs(x) > out:
                kind[i, j] = VOID
                continue
            hw = half_width(z)
            if hw - abs(x) < SIDE_W * CELL:
                kind[i, j] = SIDE
                continue
            # the path: about a third of the width, the grass either side of it; from
            # 40% to 60% of the way the grass outside it thins to the odd patch
            half = hw * 0.32 + edge[i, j] * 20
            mid = (wander[j] * 2) * hw * 0.3  # (the noise mostly stays near 0.5: doubled)
            thin = min(1, max(0, (t - 0.4) / 0.2))
            if abs(x - mid) < half:
                kind[i, j] = GRASS if t > 0.5 and patches[i, j] > 0.8 else ROCK
            elif patches[i, j] < 0.72 * thin:
                kind[i, j] = ROCK
    g = kind == GRASS
    g2 = drop_small(g, 6)
    kind[g & ~g2] = ROCK
    # Marble in the second half's rock, with rock on all eight sides (cells touching
    # anything else drop back to rock until none do).
    half_j = NZ // 2
    marble = (kind == ROCK) & (inlay > 0.66)
    marble[:, :half_j] = False
    marble[:, -1] = False  # (not against the next biome)
    while True:
        other = (kind != ROCK) & (kind != VOID)
        bad = marble & grow(other & ~marble)
        if not bad.any():
            break
        marble &= ~bad
    marble = drop_small(marble, 6)
    kind[marble] = MARBLE
    ponds = add_ponds(kind, rng, half_j)
    return kind, ponds


def add_ponds(kind, rng, half_j):
    """One or two ponds in the first half's grass: rounded water 5 to 8 tiles across
    (the middle deep), a ring of rock round it, a few lily pads. Returns the lily pads (x, z, r)."""
    lilies = []
    made = 0
    for _ in range(4000):
        if made >= 2:
            break
        w, h = int(rng.integers(5, 7)), int(rng.integers(6, 9))
        i0, j0 = int(rng.integers(1, NX - w - 1)), int(rng.integers(20, half_j - h - 20))
        if made and abs(j0 - ponds_j) < NZ // 6:
            continue
        ring = kind[i0 - 1:i0 + w + 1, j0 - 1:j0 + h + 1]
        if not np.all((ring == GRASS) | (ring == ROCK)) or (ring == GRASS).sum() < ring.size * 0.7:
            continue
        # a rounded pond: water inside an ellipse, deep in its middle, a ring of rock round it
        ci, cj = i0 + (w - 1) / 2, j0 + (h - 1) / 2
        for a in range(i0 - 1, i0 + w + 1):
            for b in range(j0 - 1, j0 + h + 1):
                e = ((a - ci) / (w / 2)) ** 2 + ((b - cj) / (h / 2)) ** 2
                if e <= 1.0:
                    kind[a, b] = DEEP if e <= 0.3 else WATER
        water = np.isin(kind, [WATER, DEEP])
        kind[grow(water) & ~water & (kind != VOID)] = ROCK
        x0, z0 = -OUT + i0 * CELL, Z0 - j0 * CELL
        pads = int(rng.integers(3, 6))
        for _ in range(60):
            if pads == 0:
                break
            lx, lz = x0 + rng.uniform(2.5, w * CELL - 2.5), z0 - rng.uniform(2.5, h * CELL - 2.5)
            li, lj = int((lx + OUT) // CELL), int((Z0 - lz) // CELL)
            if kind[li, lj] == WATER and all(math.hypot(lx - a, lz - b) > 5 for a, b, _ in lilies):
                lilies.append((round(lx, 1), round(lz, 1), round(float(rng.uniform(1.6, 2.6)), 1)))
                pads -= 1
        ponds_j = j0
        made += 1
    return lilies


def check(kind):
    """Marble only ever touches rock (or marble); water only ever touches rock (or water)."""
    bad = 0
    p = np.pad(kind, 1, constant_values=VOID)
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            n = p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]
            bad += int(((kind == MARBLE) & ~np.isin(n, [ROCK, MARBLE])).sum())
            bad += int((np.isin(kind, [WATER, DEEP]) & ~np.isin(n, [ROCK, WATER, DEEP])).sum())
    return bad


def boxes(kind):
    out = []
    rows = BLOCK // CELL
    for j0 in range(0, NZ, rows):
        for k, i0, a, i1, b in rects(kind[:, j0:j0 + rows]):
            if k != VOID:
                out.append((int(k), -OUT + i0 * CELL, Z0 - (j0 + a) * CELL, (i1 - i0) * CELL, (b - a) * CELL, TOPS[int(k)]))
    return out


def render(kind, lilies, out, s=2, rows=5):
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
        for x, z, rad in lilies:
            if here(z):
                d.ellipse([*P(x - rad, z + rad), *P(x + rad, z - rad)], fill=LILY)
        for j in range(r * seg, min(NZ, (r + 1) * seg)):
            z = Z0 - j * CELL
            for sg in (-1, 1):
                d.line([P(sg * half_width(z), z), P(sg * half_width(z - CELL), z - CELL)], fill=(120, 120, 120), width=2 * s)
    im.save(out)


def write_luau(parts, lilies):
    body = open(os.path.join(HERE, "world2_temple.luau.in")).read()
    body = body.replace("--FLOOR--", "\n".join("\t{ %d, %d, %d, %d, %d, %d }," % p for p in parts))
    body = body.replace("--LILIES--", "\n".join("\t{ %g, %g, %g }," % p for p in lilies))
    open(os.path.join(HERE, "world2_temple.luau"), "w").write(body)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world2_temple"
    os.makedirs(out, exist_ok=True)
    kind, lilies = layout()
    bad = check(kind)
    assert bad == 0, f"{bad} marble or water tiles touch something but rock"
    parts = boxes(kind)
    assert all(p[3] <= 2048 and p[4] <= 2048 for p in parts)
    render(kind, lilies, os.path.join(out, "temple_overhead.png"))
    write_luau(parts, lilies)
    names = ("rock", "grass", "marble", "side", "water", "deep")
    print({n: int((kind == k).sum()) for k, n in enumerate(names)}, "lilies:", len(lilies),
          "parts:", len(parts))


if __name__ == "__main__":
    main()
