"""Godlands mountains (QM, Oct 4): three giant rock formations, about as tall as
the course walls, that the endless Godlands throws across the path every so often
so the rider has to funnel past them:

  MountainLeft    grows out of the left wall: go right
  MountainRight   grows out of the right wall: go left
  MountainCenter  stands in the middle: pick a side

Each is a stepped, studded mountain (a height field on the 4-stud checker, every
step 4 studs up) in the Godlands' dark stone, snow on its highest ledges, a lava
stream running down its front face from a glowing crater into a lava pool at its
foot, loose rocks round its base and dead bushes and trees on its ledges.

Run: python3 tools/godlands_mountains.py [out_dir]
Writes godlands_mountains.png (each from the riding camera and up close) to
/mnt/project-files/biomes/godlands/.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, render  # noqa: E402
import terrain_assets as TA  # noqa: E402
from terrain_assets import rot  # noqa: E402
import godlands_concept as G  # noqa: E402

HALF_W = 56  # the course's half width (Config.CourseHalfWidth)
WALL_H = 48  # the course walls (Client/GodlandsStream)
CELL = 4  # the height field's grid: the floor's checker
STEP = 4  # studs per ledge
LENGTH = 80  # studs along the course
PEAK = 44  # studs: a little under the walls
OPEN_LANE = 48  # studs the side mountains leave open on the far side; the centre one leaves LANE_C a side
LANE_C = 30

ROCK = [(58, 56, 68), (72, 70, 84), (46, 44, 56)]  # dark stone, one shade a ledge
SNOW = (238, 241, 247)
LAVA = (255, 72, 0)
LAVA_HOT = (255, 150, 20)
CRUST = (34, 30, 40)  # the black rock lining the lava


def heights(kind, seed):
    """The height field: {(i, j): studs}, cell (i, j) centred at x = x0 + i*CELL, z = -j*CELL
    (z 0 at the near end, toward the rider), and the cells' x0."""
    rng = np.random.default_rng(seed)
    if kind == "Center":
        x0, x1 = -(HALF_W - LANE_C), HALF_W - LANE_C
    elif kind == "Left":
        x0, x1 = -HALF_W, HALF_W - OPEN_LANE
    else:
        x0, x1 = -(HALF_W - OPEN_LANE), HALF_W
    nx, nz = int((x1 - x0) // CELL), LENGTH // CELL
    phase = rng.uniform(0, 6.3, 4)
    out = {}
    for i in range(nx):
        x = x0 + (i + 0.5) * CELL
        for j in range(nz):
            z = (j + 0.5) / nz  # 0 near end .. 1 far end
            along = math.sin(math.pi * z) ** 0.7  # rises from both ends
            if kind == "Center":
                u = abs(x) / (x1 - x0) * 2  # 0 middle .. 1 edge
            elif kind == "Left":
                u = (x - x0) / (x1 - x0)  # 0 at the wall .. 1 open edge
            else:
                u = (x1 - x) / (x1 - x0)
            # a ragged edge: the open side wobbles in and out along the course
            wobble = 0.08 * math.sin(z * 9 + phase[0]) + 0.05 * math.sin(z * 17 + phase[1])
            across = max(0.0, 1 - (u / (1 + wobble)) ** 1.8)
            h = PEAK * along * across
            h += 3 * math.sin(x * 0.4 + phase[2]) * math.sin(z * 11 + phase[3])  # crags
            h = round(h / STEP) * STEP
            if h >= STEP:
                out[(i, j)] = min(h, PEAK)
    return out, x0


def lava_path(field, kind):
    """The cells the lava runs down: from the crater (the highest cell) down the
    front face (toward z 0, the rider) along the steepest way, to the foot."""
    top = max(field, key=lambda c: (field[c], -abs(c[1] - LENGTH // CELL // 2)))
    path = [top]
    i, j = top
    while True:
        best = None
        for di, dj in ((0, -1), (-1, -1), (1, -1)):  # always toward the rider, maybe sideways
            c = (i + di, j + dj)
            if c in field and (best is None or field[c] < field[best]):
                best = c
        if best is None:
            break
        path.append(best)
        i, j = best
    return path


def rects(cells):
    """Greedy merge of a set of (i, j) cells into rectangles (i0, j0, i1, j1), ends exclusive."""
    left = set(cells)
    out = []
    for c in sorted(cells):
        if c not in left:
            continue
        i, j = c
        j1 = j
        while (i, j1) in left:
            j1 += 1
        i1 = i + 1
        while all((i1, jj) in left for jj in range(j, j1)):
            i1 += 1
        for ii in range(i, i1):
            for jj in range(j, j1):
                left.discard((ii, jj))
        out.append((i, j, i1, j1))
    return out


def mountain(kind, seed=3):
    """The mountain's parts (Part, with .neon on the lava), its footprint (x, z, half x,
    half z) with z 0 at its near end, and its cell field."""
    field, x0 = heights(kind, seed)
    k = TA.Kit()
    lava = set(lava_path(field, kind))
    cx = lambda i: x0 + (i + 0.5) * CELL  # noqa: E731
    cz = lambda j: -(j + 0.5) * CELL  # noqa: E731
    # The rock: each ledge (all cells at least that high) as merged columns from the
    # ledge below up to it, so the parts stack like terraces.
    for level in range(STEP, PEAK + 1, STEP):
        cells = {c for c, h in field.items() if h >= level}
        for i0, j0, i1, j1 in rects(cells):
            colour = ROCK[(level // STEP) % 3]
            if level >= PEAK - STEP and not any((i, j) in lava for i in range(i0, i1) for j in range(j0, j1)):
                colour = SNOW if level == max(field[(i, j)] for i in range(i0, i1) for j in range(j0, j1)) else colour
            k.box("Rock", (x0 + i0 * CELL, level - STEP, -j1 * CELL), (x0 + i1 * CELL, level, -j0 * CELL), colour)
    # The lava: a glowing stream lying on each cell of its path, a black crust either
    # side, and the crater: a ring of crust round a hot pool on the top cell.
    path = lava_path(field, kind)
    for n, (i, j) in enumerate(path):
        h = field[(i, j)]
        k.at("Lava", (cx(i), h + 0.2, cz(j)), (CELL * 0.75, 0.4, CELL), LAVA if n % 2 else LAVA_HOT, plain=True)
        # where it spills off the ledge, a lavafall down the step's face to the next one
        below = field[path[n + 1]] if n + 1 < len(path) else 0
        if below < h:
            fx = (cx(i) + cx(path[n + 1][0])) / 2 if n + 1 < len(path) else cx(i)
            k.at("Lava", (fx, (h + below) / 2 + 0.2, cz(j) + CELL / 2), (CELL * 0.75, h - below, 0.8), LAVA_HOT, plain=True)
    top = max(lava, key=lambda c: field[c])
    h = field[top]
    for dx, dz in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        k.at("Rock", (cx(top[0]) + dx * 2.6, h + 1.0, cz(top[1]) + dz * 2.6),
             (1.4 if dx else 6.6, 2.0, 1.4 if dz else 6.6), CRUST)
    k.at("Lava", (cx(top[0]), h + 1.6, cz(top[1])), (3.8, 0.3, 3.8), LAVA_HOT, plain=True)
    # The pool at its foot, where the stream runs out, ringed with crust.
    foot = min(lava, key=lambda c: c[1])
    fx, fz = cx(foot[0]), cz(foot[1]) + CELL * 1.5
    k.at("Lava", (fx, 0.08, fz), (10, 0.16, 6), LAVA, plain=True)
    for dx, dz, w, d in ((-5.8, 0, 1.6, 7), (5.8, 0, 1.6, 7), (0, 3.6, 12, 1.2)):
        k.at("Rock", (fx + dx, 0.5, fz + dz), (w, 1.0, d), CRUST)
    # Snow lying on some of the ledges (the Godlands' grey snow lines).
    rng0 = np.random.default_rng(seed + 2)
    for (i, j), h in field.items():
        if (i, j) not in lava and h < PEAK - STEP and rng0.random() < 0.18 \
                and field.get((i, j - 1), 0) < h:  # an exposed front edge
            k.at("Rock", (cx(i), h + 0.3, cz(j)), (CELL, 0.6, CELL), SNOW)
    # Life: dead bushes and trees on ledges, loose rocks round the base.
    rng = np.random.default_rng(seed + 1)
    ledges = [c for c, h in field.items() if c not in lava and STEP * 2 <= h <= PEAK - STEP * 2
              and all(field.get((c[0] + di, c[1] + dj), 0) <= h for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for n, c in enumerate(rng.permutation(len(ledges))[:7]):
        i, j = ledges[c]
        builder = G.dead_tree if n % 3 == 0 else G.dead_bush
        sub = TA.Kit()
        builder(sub)
        M = T(cx(i), field[(i, j)], cz(j)) @ rot(rng.uniform(0, 360))
        for p in sub.parts:
            k.parts.append(Part(p.name, p.size, M @ p.cf, p.color, p.shape, p.plain))
    base = [c for c, h in field.items() if h == STEP]
    for n, c in enumerate(rng.permutation(len(base))[:6]):
        i, j = base[c]
        sub = TA.Kit()
        G.dark_stone(sub)
        M = T(cx(i) + rng.uniform(-1, 1), 0, cz(j) + rng.uniform(-1, 1)) @ rot(rng.uniform(0, 360))
        for p in sub.parts:
            k.parts.append(Part(p.name, p.size, M @ p.cf, p.color, p.shape, p.plain))
    for p in k.parts:
        p.neon = p.name == "Lava"
    # The footprint the ride crashes into: the cells at least two ledges high, so the
    # low skirt at the very edge can be grazed.
    solid = [c for c, h in field.items() if h >= STEP * 2]
    i0, i1 = min(c[0] for c in solid), max(c[0] for c in solid) + 1
    j0, j1 = min(c[1] for c in solid), max(c[1] for c in solid) + 1
    foot_print = ((x0 + i0 * CELL + x0 + i1 * CELL) / 2, -(j0 + j1) * CELL / 2, (i1 - i0) * CELL / 2, (j1 - j0) * CELL / 2)
    return k.parts, foot_print, field


def stage(parts, z0=-60, length=200):
    """The mountain on a stretch of Godlands floor between the walls."""
    out = []
    for i in range(2 * HALF_W // 8):
        for j in range(length // 8):
            c = G.SNOW[(i + j) % 2]
            out.append(Part("Floor", (8, 2, 8), T(-HALF_W + i * 8 + 4, -1, -j * 8 - 4 + 40), c, plain=True))
    for side in (-1, 1):
        out.append(Part("Wall", (8, WALL_H, length), T(side * (HALF_W + 4), WALL_H / 2, -length / 2 + 40), G.WALL[0], plain=True))
        out.append(Part("Cap", (10, 2, length), T(side * (HALF_W + 3), WALL_H + 1, -length / 2 + 40), G.WALL_CAP, plain=True))
    for p in parts:
        q = Part(p.name, p.size, T(0, 0, z0) @ p.cf, p.color, p.shape, p.plain)
        q.neon = getattr(p, "neon", False)
        out.append(q)
    # a horse-sized rider for scale, in the lane
    return out


def main(out):
    os.makedirs(out, exist_ok=True)
    kw = dict(W=760, H=560, fog=False, ground=False, outline=False)
    board = Image.new("RGB", (760 * 2, 560 * 3))
    d = ImageDraw.Draw(board)
    for r, (kind, label) in enumerate((("Left", "Left mountain: go right"), ("Right", "Right mountain: go left"),
                                       ("Center", "Centre mountain: pick a side"))):
        parts, fp, _ = mountain(kind)
        print(kind, len(parts), "parts, footprint", tuple(round(v, 1) for v in fp))
        scene = stage(parts)
        # the riding camera: behind and above, looking down the course
        board.paste(render(scene, eye=(0, 78, 40), target=(0, 0, -90), fov=60, **kw), (0, r * 560))
        board.paste(render(scene, eye=(70, 40, 30), target=(0, 18, -100), fov=55, **kw), (760, r * 560))
        d.text((12, r * 560 + 10), label, fill=(255, 255, 255), font=TA.font(26), stroke_width=3, stroke_fill=(0, 0, 0))
    board.save(os.path.join(out, "godlands_mountains.png"))
    print("wrote", out)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0] if args else "/mnt/project-files/biomes/godlands")
