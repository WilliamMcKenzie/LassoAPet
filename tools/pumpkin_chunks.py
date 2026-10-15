"""The Halloween world's Pumpkin Patch floor as roadwork chunks (QM, Oct 15: "design like 4
chunks and we will randomly pick ones and lay them down like roadwork"; the biome is
infinite and procedural).

Run: python3 tools/pumpkin_chunks.py [out_dir]
     renders the four chunks side by side and a random run of ten, and writes
     tools/pumpkin_chunks.luau, which builds them in Studio as Models in
     ServerStorage.PumpkinPatchChunks (Chunk1..4) for the game to lay end to end.

Each chunk is LENGTH studs long and the course's width where the Pumpkin Patch starts (its
outer columns run on under the walls). His autumn picture: tan flagstones ("Ground") down
the middle, sage green ("Grass") and brown ("Dirt") mixed any old how along the walls (QM:
"no real rules to how its layered"). Any chunk follows any other: every chunk's first and
last rows are the same (a set band of green along each wall), so the seams never show.
No patch under 2x2. All flush (tops at 0).

Each Model's pivot is the middle of its start edge, at floor height, looking down the
course (-z): chunk n+1 goes at chunk n's pivot moved LENGTH on.
"""

import math
import os
import random
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import noise, rects  # noqa: E402

HERE = os.path.dirname(__file__)
CELL, LENGTH = 8, 256
HALF = 56 + 0.005 * (2168 + 1816)  # the course's half width where the Pumpkin Patch starts (~75.9)
EDGE = int(math.ceil(HALF / CELL)) * CELL + CELL  # a column on under each wall (88)
NX, NZ = 2 * EDGE // CELL, LENGTH // CELL
TAN, GREEN, BROWN = 0, 1, 2
NAMES = {TAN: "Ground", GREEN: "Grass", BROWN: "Dirt"}
COLOURS = {
    TAN: [(214, 184, 134), (204, 174, 124)],
    GREEN: [(136, 156, 104), (126, 146, 96)],
    BROWN: [(160, 112, 74), (148, 102, 66)],
}
SEAM = 3  # rows at each end that fade to the set seam band
SEAM_REACH = 20  # the seam's green band, studs in from each wall


def shift(m, di, dj):
    p = np.pad(m, 1, mode="edge")
    return p[1 + di:1 + di + m.shape[0], 1 + dj:1 + dj + m.shape[1]]


def specks(m):
    ok = np.zeros_like(m)
    for di in (0, -1):
        for dj in (0, -1):
            ok |= np.all([shift(m, di + a, dj + b) for a in (0, 1) for b in (0, 1)], axis=0)
    return m & ~ok


def no_specks(m):
    for _ in range(4):
        m = m & ~specks(m)
        m = m | specks(~m)
    return m


def chunk(seed):
    rag = noise(NX, NZ, 3, seed)
    blobs = noise(NX, NZ, 2, seed + 1)
    xs = -EDGE + CELL * np.arange(NX) + CELL / 2
    wall = HALF - np.abs(xs)[:, None] * np.ones((1, NZ))  # studs in from the wall
    reach = 8 + rag * 36
    for j in range(NZ):  # (ease to the seam band at both ends)
        t = min(j, NZ - 1 - j)
        if t < SEAM:
            reach[:, j] = SEAM_REACH + (reach[:, j] - SEAM_REACH) * t / SEAM
    band = (wall < reach) | ((blobs > 0.78) & (wall < 50))
    band[:, :1] = band[:, -1:] = wall[:, :1] < SEAM_REACH
    band = no_specks(band)
    band[:, :1] = band[:, -1:] = wall[:, :1] < SEAM_REACH  # (the seams exact)
    kind = np.full((NX, NZ), TAN)
    kind[band] = GREEN
    # green or brown picked at random per 16-stud block (2x2 tiles)
    rng = np.random.default_rng(seed)
    pick = rng.random((NX // 2 + 1, NZ // 2 + 1)) < 0.45
    blocks = np.kron(pick, np.ones((2, 2), bool))[:NX, :NZ]
    brown = band & blocks & ~specks(band & blocks)
    brown[:, :2] = brown[:, -2:] = False  # (the seams all green)
    kind[brown] = BROWN
    return kind


def draw(kinds, out, s=3, gap=6):
    im = Image.new("RGB", ((NX * CELL + gap) * s * len(kinds), NZ * CELL * s), (60, 50, 66))
    px = im.load()
    for n, kind in enumerate(kinds):
        ox = n * (NX * CELL + gap) * s
        for i in range(NX):
            x = -EDGE + i * CELL + CELL / 2
            for j in range(NZ):
                for a in range(2):
                    for b in range(2):
                        col = (60, 50, 66) if abs(x) > HALF else COLOURS[int(kind[i, j])][(i * 2 + a + j * 2 + b) % 2]
                        for u in range(4 * s):
                            for v in range(4 * s):
                                px[ox + (i * CELL + a * 4) * s + u, (j * CELL + b * 4) * s + v] = col
    im.save(out)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/pumpkin_patch"
    os.makedirs(out, exist_ok=True)
    kinds = [chunk(70 + 10 * n) for n in range(4)]
    for k in kinds:
        assert (k[:, 0] == kinds[0][:, 0]).all() and (k[:, -1] == kinds[0][:, 0]).all(), "seams differ"
        assert not specks(k == TAN).any()
    draw(kinds, os.path.join(out, "pumpkin_chunks.png"))
    rng = random.Random(5)
    run = [kinds[rng.randrange(4)] for _ in range(10)]
    draw([np.concatenate(run[:5], axis=1), np.concatenate(run[5:], axis=1)], os.path.join(out, "pumpkin_run.png"), s=2)
    lines = []
    for n, k in enumerate(kinds):
        lines.append("\t{ -- Chunk%d" % (n + 1))
        for t, i0, j0, i1, j1 in rects(k):
            # local: x from -EDGE, z from 0 at the start edge going -z
            lines.append('\t\t{ "%s", %d, %d, %d, %d },' % (NAMES[t], -EDGE + i0 * CELL, -j1 * CELL, (i1 - i0) * CELL, (j1 - j0) * CELL))
        lines.append("\t},")
    body = open(os.path.join(HERE, "pumpkin_chunks.luau.in")).read()
    body = body.replace("--LENGTH--", str(LENGTH)).replace("--CHUNKS--", "\n".join(lines))
    open(os.path.join(HERE, "pumpkin_chunks.luau"), "w").write(body)
    print("parts per chunk:", [len(rects(k)) for k in kinds], "width:", 2 * EDGE)


if __name__ == "__main__":
    main()
