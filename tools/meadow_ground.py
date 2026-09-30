"""Meadow ground concept: the meadow's grass checker with patches of a lighter grass.

Run: python3 tools/meadow_ground.py [out_dir]

Same approach as tools/desert_ground.py: noise patches on an 8-stud grid so the
checker lines up. Renders two takes: A with the light grass flush, B with it a
stud higher (like the desert's sandstone).
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, render  # noqa: E402
from desert_ground import noise, CELL, HALF_W  # noqa: E402
from animal_designs import font  # noqa: E402

GRASS = [(77, 196, 63), (105, 255, 74)]  # the meadow's GroundColors
LIGHT = [(150, 226, 96), (178, 246, 124)]
WALL = [(225, 150, 104), (248, 170, 114)]
LENGTH = 200


def layout(nz, seed=11):
    nx = 2 * HALF_W // CELL
    n = noise(nx, nz, 3, seed) * 0.75 + noise(nx, nz, 1.5, seed + 1) * 0.25
    return (n > 0.6).astype(int)


def take(kind, raised):
    parts = []
    nx, nz = kind.shape
    for i in range(nx):
        for j in range(nz):
            k = kind[i, j]
            top = 1 if (k and raised) else 0
            for di in (0, 1):
                for dj in (0, 1):
                    x = -HALF_W + i * CELL + di * 4 + 2
                    z = -j * CELL - dj * 4 - 2
                    c = (GRASS, LIGHT)[k][(di + dj) % 2]
                    parts.append(Part("Floor", (4, top + 1, 4), T(x, (top - 1) / 2, z), c))
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
    band = 40
    board = Image.new("RGB", (1600, 2 * 520 + band), (255, 255, 255))
    d = ImageDraw.Draw(board)
    for col, (label, raised) in enumerate((("A: light grass flush", False), ("B: light grass a stud higher", True))):
        ride, close = take(kind, raised)
        board.paste(ride, (col * 800, band))
        board.paste(close, (col * 800, band + 520))
        d.text((col * 800 + 12, 10), label, fill=(20, 20, 20), font=font(20))
    board.save(os.path.join(out, "meadow_ground.png"))
    print("wrote", out, "light cells:", int(kind.sum()), "of", kind.size)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/meadow_ground")
