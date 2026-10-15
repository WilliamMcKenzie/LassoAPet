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
from PIL import Image, ImageDraw

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

# The props (QM, Oct 15: "use the haloween harvest props ... as well as the previously made
# pumpkin assets. make thoughtful placements, should look aesthetic and feel sensible"):
# ServerStorage.HalloweenProps as stored (the trees 2x, the rest 1.5x: tools/halloween_props.luau).
# Footprint (x, z) in studs as stored, from /mnt/project-files/halloween/props/sizes.txt.
SIZE = {
    "LanternTree": (2.0, 10.6, 9.5), "Scarecrow": (1.5, 8.2, 3.8), "HayBale": (1.5, 3.6, 2.3),
    "HayStack": (1.5, 7.4, 2.5), "Pumpkin": (1.5, 4.6, 4.6), "PumpkinPile": (1.5, 9.1, 4.7),
    "JackOLantern": (1.5, 5.5, 5.9), "JackOLanternSmall": (1.5, 3.7, 3.9),
    "LeafPile": (1.5, 6.4, 6.6), "LeafScatter": (1.5, 6.8, 6.2),
}
BIG = {"LanternTree": 3, "Scarecrow": 2, "HayStack": 2, "PumpkinPile": 2}  # smashable obstacles: tier
# Little scenes like his picture, each against a wall: (item, along, in from the wall face,
# turn) - along runs down the course (+ = further on), turn in degrees on top of facing in.
SCENES = {
    "orchard": [("LanternTree", 0, 11, 0), ("HayStack", 15, 5, 0), ("Pumpkin", 9, 13, 20),
                ("LeafScatter", -4, 19, 0), ("Pumpkin", -12, 6, -15)],
    "scarecrow": [("Scarecrow", 0, 8, 0), ("HayBale", -8, 4, 0), ("HayBale", -8, 8, 90),
                  ("JackOLanternSmall", 7, 13, 10), ("LeafScatter", 1, 16, 0), ("Pumpkin", 11, 5, 0)],
    "pumpkins": [("PumpkinPile", 0, 6, 0), ("JackOLantern", -10, 12, 0), ("Pumpkin", 9, 13, 25),
                 ("LeafPile", 3, 15, 0), ("JackOLanternSmall", 13, 5, 0)],
    "hay": [("HayStack", 0, 5, 0), ("HayBale", 9, 11, 30), ("HayBale", 9, 4, 0),
            ("Pumpkin", -8, 11, 0), ("JackOLanternSmall", 2, 13, -10), ("LeafScatter", -10, 18, 0)],
}
LANE = 26  # nothing reaches further in from a wall than this: the middle stays clear to ride
# Where the scenes sit: the sides take turns every 64 studs, so the run never has two at once
# and the pattern carries on across any seam; a single loose piece opposite each.
SLOTS = [(-1, 32), (1, 96), (-1, 160), (1, 224)]
ORDER = [["orchard", "scarecrow", "pumpkins", "hay"], ["scarecrow", "orchard", "hay", "pumpkins"],
         ["pumpkins", "hay", "orchard", "scarecrow"], ["hay", "pumpkins", "scarecrow", "orchard"]]
LOOSE = ["LeafScatter", "Pumpkin", "LeafPile", "JackOLanternSmall"]


def radius(item):
    k, w, d = SIZE[item]
    return k * max(w, d) / 2


def place(n):
    """[(item, x, z, yaw degrees)]: z from 0 at the chunk's start going -z; yaw is
    CFrame.Angles(0, rad(yaw), 0) on a model facing -z: -90 faces +x, 90 faces -x, 180 +z."""
    out = []
    for (side, at), scene in zip(SLOTS, ORDER[n]):
        flip = (n + at // 64) % 2  # (mirror some scenes along the course so they don't repeat)
        for item, along, inn, turn in SCENES[scene]:
            along = -along if flip else along
            x = side * (HALF - inn)
            z = -(at + along)
            yaw = side * 120 + side * turn  # (in from the wall, turned 30 back toward the riders)
            out.append((item, x, z, yaw))
        lx = -side * (HALF - 6)
        out.append((LOOSE[(n + at // 64) % 4], lx, -(at + 8 * (1 if n % 2 else -1)), 0))
    for item, x, z, _ in out:
        r = radius(item) if item not in ("LeafScatter", "LeafPile") else 3
        assert HALF - abs(x) + r <= LANE + 6, (item, x)  # (in the wall band)
        assert -z - radius(item) > 8 and -z + radius(item) < LENGTH - 8, (item, z)  # (clear of the seams)
    return out



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


ICON = {  # render colours: (fill, outline)
    "LanternTree": ((200, 60, 40), (90, 30, 20)), "Scarecrow": ((90, 120, 60), (40, 60, 30)),
    "HayStack": ((220, 190, 90), (120, 90, 30)), "HayBale": ((220, 190, 90), (120, 90, 30)),
    "Pumpkin": ((230, 110, 30), (120, 50, 10)), "PumpkinPile": ((230, 110, 30), (120, 50, 10)),
    "JackOLantern": ((255, 200, 60), (150, 60, 10)), "JackOLanternSmall": ((255, 200, 60), (150, 60, 10)),
    "LeafPile": ((200, 70, 40), None), "LeafScatter": ((220, 120, 50), None),
}


def draw_props(im, props, ox, s, oz=0):
    d = ImageDraw.Draw(im)
    order = sorted(props, key=lambda p: p[0] not in ("LeafScatter", "LeafPile"))  # (leaves under)
    for item, x, z, yaw in order:
        k, w, dp = SIZE[item]
        w, dp = w * k / 2, dp * k / 2
        a = math.radians(yaw)
        # the footprint's corners: the model's x and z turned by yaw (Roblox: y up, ccw from above)
        pts = []
        for u, v in ((-w, -dp), (w, -dp), (w, dp), (-w, dp)):
            X = x + u * math.cos(a) + v * math.sin(a)
            Z = z - u * math.sin(a) + v * math.cos(a)
            pts.append((ox + (X + EDGE) * s, (oz - Z) * s))
        fill, line = ICON[item]
        if item in ("LanternTree", "Pumpkin", "JackOLantern", "JackOLanternSmall", "LeafPile", "LeafScatter"):
            cx, cy = ox + (x + EDGE) * s, (oz - z) * s
            r = max(w, dp) * s
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=line, width=s if line else 0)
        else:
            d.polygon(pts, fill=fill, outline=line, width=s)
        # which way it faces (-z of the model, turned)
        fx, fz = -math.sin(a), -math.cos(a)
        if item not in ("LeafPile", "LeafScatter"):
            cx, cy = ox + (x + EDGE) * s, (oz - z) * s
            d.line([cx, cy, cx + fx * max(w, dp) * 1.3 * s, cy - fz * max(w, dp) * 1.3 * s], fill=(40, 30, 40), width=s)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/pumpkin_patch"
    os.makedirs(out, exist_ok=True)
    kinds = [chunk(70 + 10 * n) for n in range(4)]
    for k in kinds:
        assert (k[:, 0] == kinds[0][:, 0]).all() and (k[:, -1] == kinds[0][:, 0]).all(), "seams differ"
        assert not specks(k == TAN).any()
    props = [place(n) for n in range(4)]
    draw(kinds, os.path.join(out, "pumpkin_chunks.png"))
    im = Image.open(os.path.join(out, "pumpkin_chunks.png"))
    for n in range(4):
        draw_props(im, props[n], n * (NX * CELL + 6) * 3, 3)
    im.save(os.path.join(out, "pumpkin_chunks.png"))
    rng = random.Random(5)
    picks = [rng.randrange(4) for _ in range(10)]
    draw([np.concatenate([kinds[p] for p in picks[:5]], axis=1), np.concatenate([kinds[p] for p in picks[5:]], axis=1)],
         os.path.join(out, "pumpkin_run.png"), s=2)
    im = Image.open(os.path.join(out, "pumpkin_run.png"))
    for col in range(2):
        for r, pk in enumerate(picks[col * 5:col * 5 + 5]):
            draw_props(im, props[pk], col * (NX * CELL + 6) * 2, 2, oz=-r * LENGTH)
    im.save(os.path.join(out, "pumpkin_run.png"))
    lines = []
    for n, k in enumerate(kinds):
        lines.append("\t{ -- Chunk%d" % (n + 1))
        for t, i0, j0, i1, j1 in rects(k):
            # local: x from -EDGE, z from 0 at the start edge going -z
            lines.append('\t\t{ "%s", %d, %d, %d, %d },' % (NAMES[t], -EDGE + i0 * CELL, -j1 * CELL, (i1 - i0) * CELL, (j1 - j0) * CELL))
        lines.append("\t},")
    plines = []
    for n in range(4):
        plines.append("\t{ -- Chunk%d" % (n + 1))
        for item, x, z, yaw in props[n]:
            plines.append('\t\t{ "%s", %.1f, %.1f, %d, %d },' % (item, x, z, yaw, BIG.get(item, 0)))
        plines.append("\t},")
    body = open(os.path.join(HERE, "pumpkin_chunks.luau.in")).read()
    body = body.replace("--LENGTH--", str(LENGTH)).replace("--CHUNKS--", "\n".join(lines)).replace("--PROPS--", "\n".join(plines))
    open(os.path.join(HERE, "pumpkin_chunks.luau"), "w").write(body)
    print("parts per chunk:", [len(rects(k)) for k in kinds], "props per chunk:", [len(p) for p in props], "width:", 2 * EDGE)


if __name__ == "__main__":
    main()
