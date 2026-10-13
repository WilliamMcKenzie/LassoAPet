"""World 2's sixth and last biome, the Ancient Tomb (QM, Oct 13; draft): royal sand and gold.

Run: python3 tools/world2_tomb.py [out_dir]
     renders the layout and writes tools/world2_tomb.luau, which lays it in Studio over
     World2's copied last-biome floor (World 1's Jurassic) and paints its walls.

- Sand in two tones, #DCC998 and #D0B886, drifting in dune patches.
- Tiled stretches: long runs where the sand floor carries a diamond lattice of the darker
  tone, a diamond every 64 studs (the tomb's old paving).
- A gold causeway (#E2C200, checker #C4A703) a stud up down the middle, four tiles
  wide, buried by the drifts here and there.
- Every so often a royal dais, symmetric about the course's middle: a border of the
  darker gold a stud up, then gold two studs up, in one of three plans (solid, a ring round a
  sunken sand court, twin halls either side of the causeway).
- Walls #D3B742.
- The course runs on forever past here (Config.Endless: the stretch from Cut + Length
  to Cut is laid again and again), so that stretch starts and ends on a lattice
  threshold row, so each repeat meets the last on the same paving.

Laid out in game space after the funnel, like tools/world2_cavern.py.
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
Z0, Z1 = -14064, -21744  # the last biome's near and far ends
LOOP = (-21504 + 1536, -21504)  # Config.Endless: Cut + Length .. Cut, laid again and again
OUT = int(math.ceil(half_width(Z1) / CELL)) * CELL  # 144
NX, NZ = 2 * OUT // CELL, (Z0 - Z1) // CELL
VOID, SAND, DUNE, LINE, GOLD, DAIS, FRAME = -1, 0, 1, 2, 3, 4, 5
COLOURS = {  # part, checker
    SAND: [(220, 201, 152), (210, 191, 142)],  # #DCC998
    DUNE: [(208, 184, 134), (198, 174, 124)],  # #D0B886
    LINE: [(208, 184, 134), (198, 174, 124)],  # the lattice's lines: the darker sand
    GOLD: [(226, 194, 0), (196, 167, 3)],  # #E2C200 / #C4A703
    DAIS: [(226, 194, 0), (196, 167, 3)],
    FRAME: [(196, 167, 3), (180, 152, 2)],  # the daises' border: the darker gold
}
NAMES = {SAND: "Sand", DUNE: "Dune", LINE: "Paving", GOLD: "Gold", DAIS: "Gold", FRAME: "Frame"}
TOPS = {SAND: 0, DUNE: 0, LINE: 0, GOLD: 1, DAIS: 2, FRAME: 1}
WALL, CAP = [(211, 183, 66), (196, 168, 54)], (186, 158, 46)  # #D3B742


def centre(i, j):
    return -OUT + i * CELL + CELL / 2, Z0 - j * CELL - CELL / 2


def band_out(j):
    z_far = max(Z1, Z0 - (((j * CELL) // BAND) + 1) * BAND)
    return int(math.ceil(half_width(z_far) / CELL)) * CELL


def row(z):
    return int((Z0 - z) // CELL)


def layout(seed=83):
    rng = np.random.default_rng(seed)
    dunes = noise(NX, NZ, 5, seed) * 0.8 + noise(NX, NZ, 2, seed + 1) * 0.2
    drift = noise(NX, NZ, 4, seed + 2) * 0.8 + noise(NX, NZ, 1.6, seed + 3) * 0.2
    kind = np.full((NX, NZ), SAND)
    inside = np.zeros((NX, NZ), bool)
    for j in range(NZ):
        out = band_out(j)
        for i in range(NX):
            x, z = centre(i, j)
            if abs(x) > out:
                kind[i, j] = VOID
            elif abs(x) < half_width(z) - CELL:
                inside[i, j] = True
    kind[(dunes > 0.6) & (kind == SAND)] = DUNE

    # Tiled stretches: about a third of the length in runs of 300 to 600 studs, a diamond lattice.
    tiled = np.zeros(NZ, bool)
    j = int(rng.integers(10, 40))
    while j < NZ:
        n = int(rng.integers(38, 76))
        tiled[j:j + n] = True
        j += n + int(rng.integers(60, 120))
    lo, hi = row(LOOP[0]), row(LOOP[1])
    tiled[lo:hi] = True  # (the endless stretch is all paving, so its repeats join)
    ii, jj = np.meshgrid(np.arange(NX), np.arange(NZ), indexing="ij")
    lattice = ((ii + jj) % 8 == 0) | ((ii - jj) % 8 == 0)  # (a diamond every 64 studs)
    paved = tiled[None, :] & (kind != VOID)
    kind[paved] = SAND
    kind[paved & lattice] = LINE

    # The causeway: four tiles of gold down the middle, a stud up, in long stretches.
    mid = NX // 2
    cause = np.zeros(NZ, bool)
    j = int(rng.integers(5, 20))
    while j < NZ:
        n = int(rng.integers(50, 120))
        cause[j:j + n] = True
        j += n + int(rng.integers(20, 60))
    for j in np.nonzero(cause)[0]:
        kind[mid - 2:mid + 2, j] = GOLD  # (x -16..16)

    # The daises, every 560 to 760 studs, symmetric about x = 0.
    j = int(rng.integers(30, 50))
    plan = int(rng.integers(0, 3))
    while j < NZ - 20:
        if lo - 16 < j < hi + 2:  # (none across the endless stretch's seams)
            j = hi + 4
            continue
        half_cells = int(half_width(Z0 - j * CELL) * rng.uniform(0.6, 0.78) // CELL)
        length = int(rng.integers(16, 26))
        a, b = mid - half_cells, mid + half_cells
        kind[a:b, j:j + length] = FRAME
        kind[a + 1:b - 1, j + 1:j + length - 1] = DAIS
        if plan == 1:  # a ring of gold round a sunken court of paving
            court = (slice(a + 3, b - 3), slice(j + 3, j + length - 3))
            kind[court] = np.where(lattice[court], LINE, SAND)
        elif plan == 2:  # twin halls either side of the causeway's line
            kind[mid - 3:mid + 3, j + 1:j + length - 1] = FRAME
            kind[mid - 2:mid + 2, j:j + length] = GOLD
        plan = (plan + 1) % 3
        j += length + int(rng.integers(70, 95))

    # Drifts: sand blown over the causeway and the paving here and there (not the daises).
    blown = (drift > 0.74) & np.isin(kind, [GOLD, LINE]) & ~((jj >= lo) & (jj < hi))
    kind[blown] = DUNE
    kind[~inside & np.isin(kind, [GOLD, DAIS, FRAME])] = SAND
    return kind


def boxes(kind):
    top = np.vectorize(lambda k: TOPS.get(int(k), 0))(kind)
    key = np.where(kind == VOID, -1, kind * 10 + top)
    out = []
    rows = BLOCK // CELL
    for j0 in range(0, NZ, rows):
        for k, i0, a, i1, b in rects(key[:, j0:j0 + rows]):
            if k != -1:
                out.append((int(k) // 10, -OUT + i0 * CELL, Z0 - (j0 + a) * CELL, (i1 - i0) * CELL, (b - a) * CELL, int(k) % 10))
    return out


def render(kind, out, s=1, rows=6):
    seg = int(math.ceil(NZ / rows))
    w, h = NX * CELL * s, seg * CELL * s
    im = Image.new("RGB", (rows * (w + 16), h), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for r in range(rows):
        ox = r * (w + 16)
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
                d.line([(ox + (x0 + OUT) * s, (j - r * seg) * CELL * s), (ox + (x1 + OUT) * s, (j + 1 - r * seg) * CELL * s)],
                       fill=WALL[0], width=3)
            if Z0 - j * CELL in (LOOP[0], LOOP[1]):
                d.line([(ox, (j - r * seg) * CELL * s), (ox + w, (j - r * seg) * CELL * s)], fill=(200, 40, 40), width=2)
    im.save(out)


def write_luau(parts):
    body = open(os.path.join(HERE, "world2_tomb.luau.in")).read()
    body = body.replace("--FLOOR--", "\n".join("\t{ %d, %d, %d, %d, %d, %d }," % p for p in parts))
    open(os.path.join(HERE, "world2_tomb.luau"), "w").write(body)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world2_tomb"
    os.makedirs(out, exist_ok=True)
    kind = layout()
    parts = boxes(kind)
    assert all(p[3] <= 2048 and p[4] <= 2048 for p in parts)
    render(kind, os.path.join(out, "tomb_overhead.png"))
    write_luau(parts)
    print({NAMES[k] + str(k): int((kind == k).sum()) for k in NAMES}, "parts:", len(parts))


if __name__ == "__main__":
    main()
