"""Meadow ground concept: the meadow's grass checker with sunken dirt patches.

Run: python3 tools/meadow_ground.py [out_dir]

Same approach as tools/desert_ground.py: noise patches on an 8-stud grid so the
checker lines up. The dirt uses the walls' colours and sits a stud below the
grass (QM: grass > dirt).
"""

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, render  # noqa: E402
from desert_ground import noise, CELL, HALF_W  # noqa: E402

GRASS = [(77, 196, 63), (105, 255, 74)]  # the meadow's GroundColors
DIRT = [(225, 150, 104), (248, 170, 114)]  # the meadow's WallColors
DIRT_DOWN = 1
WALL = [(225, 150, 104), (248, 170, 114)]
LENGTH = 200


def layout(nz, seed=11):
    nx = 2 * HALF_W // CELL
    n = noise(nx, nz, 3, seed) * 0.75 + noise(nx, nz, 1.5, seed + 1) * 0.25
    kind = (n > 0.6).astype(int)
    kind[0, :] = kind[-1, :] = 0  # grass along the walls, so sunken dirt never opens a gap under them
    return kind


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


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/meadow_ground")
