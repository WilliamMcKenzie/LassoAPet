"""Meadow ground concept: the meadow's grass checker with sunken dirt patches.

Run: python3 tools/meadow_ground.py            render a preview
     python3 tools/meadow_ground.py --map      also write it into src/world/World.rbxmx

Same approach as tools/desert_ground.py: noise patches on an 8-stud grid so the
checker lines up. The dirt uses the walls' colours and sits a stud below the
grass (QM: grass > dirt). The columns along the walls, the start and the
nests stay grass (sunken dirt would open a gap under a wall or drop a nest).
In the map the meadow's one Ground part becomes rectangles named "Ground"
(grass) and "Dirt"; Config.Biomes Meadow.Patches holds the dirt colours.
"""

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, render  # noqa: E402
from desert_ground import noise, rects, write_patches, CELL, HALF_W  # noqa: E402

GRASS = [(77, 196, 63), (105, 255, 74)]  # the meadow's GroundColors
DIRT = [(225, 150, 104), (248, 170, 114)]  # the meadow's WallColors
DIRT_DOWN = 1
WALL = [(225, 150, 104), (248, 170, 114)]
LENGTH = 200
MEADOW_LENGTH = 2168  # (QM, Oct 11: the pacing ladder, tools/course_resize.py; was 760)
NESTS = [(-20, -470), (22, -600), (-20, -1174), (22, -1304), (-20, -1878), (22, -2008), (0, -2144)]
NEST_CLEAR = 10
START_CLEAR = 16  # studs of grass after the start line


def layout(nz, seed=11):
    nx = 2 * HALF_W // CELL
    n = noise(nx, nz, 3, seed) * 0.75 + noise(nx, nz, 1.5, seed + 1) * 0.25
    kind = (n > 0.6).astype(int)
    kind[0, :] = kind[-1, :] = 0  # grass along the walls, so sunken dirt never opens a gap under them
    kind[:, : START_CLEAR // CELL] = 0
    for i in range(nx):
        for j in range(nz):
            x, z = -HALF_W + i * CELL + CELL / 2, -j * CELL - CELL / 2
            if any(abs(x - a) < NEST_CLEAR + CELL / 2 and abs(z - b) < NEST_CLEAR + CELL / 2 for a, b in NESTS):
                kind[i, j] = 0
    return kind


def map_boxes(kind):
    """(name, centre, size) per rectangle: grass tops at 0, dirt DIRT_DOWN lower, bottoms at -2."""
    out = []
    for k, i0, j0, i1, j1 in rects(kind):
        top = -DIRT_DOWN if k else 0
        x0, x1 = -HALF_W + i0 * CELL, -HALF_W + i1 * CELL
        z0, z1 = -j0 * CELL, -j1 * CELL
        out.append((("Ground", "Dirt")[k], ((x0 + x1) / 2, (top - 2) / 2, (z0 + z1) / 2), (x1 - x0, top + 2, z0 - z1)))
    return out


def take(kind):
    parts = []
    nx, nz = kind.shape
    for i in range(nx):
        for j in range(nz):
            k = kind[i, j]
            top = -DIRT_DOWN if k else 0
            for di in (0, 1):
                for dj in (0, 1):
                    x = -HALF_W + i * CELL + di * 4 + 2
                    z = -j * CELL - dj * 4 - 2
                    c = (GRASS, DIRT)[k][(di + dj) % 2]
                    parts.append(Part("Floor", (4, top + 2, 4), T(x, (top - 2) / 2, z), c))
    for side in (-1, 1):
        for zi in range(LENGTH // 4):
            for yi in range(4):
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, -zi * 4 - 2),
                                  WALL[(zi + yi) % 2], plain=True))
    kw = dict(W=800, H=520, fog=False, ground=False)
    ride = render(parts, eye=(0, 70, 30), target=(0, 0, -70), fov=50, **kw)
    close = render(parts, eye=(-30, 14, -20), target=(-4, 0, -62), fov=45, **kw)
    return ride, close


def main(out):
    os.makedirs(out, exist_ok=True)
    kind = layout(LENGTH // CELL)
    ride, close = take(kind)
    board = Image.new("RGB", (800, 1040))
    board.paste(ride, (0, 0))
    board.paste(close, (0, 520))
    board.save(os.path.join(out, "meadow_dirt.png"))
    print("wrote", out, "dirt cells:", int(kind.sum()), "of", kind.size)
    if "--map" in sys.argv:
        full = layout(MEADOW_LENGTH // CELL)
        print("wrote", write_patches(r"RBX00000003|MGND\d+", "MGND", map_boxes(full)), "meadow floor parts")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0] if args else "/mnt/project-files/biomes/meadow_ground")
