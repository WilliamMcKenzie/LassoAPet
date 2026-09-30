"""Desert ground concept: patchy sand, dry grass and raised sandstone checker.

Run: python3 tools/desert_ground.py [out_dir]

Sand is the base floor (outside the walls is sky, as in game). Dry grass patches sit flush with it. Sandstone
plateaus stand one stud higher. Every patch is made of whole 4-stud tiles, so
each type keeps its own 4-stud checker, lined up with the others. Patches come
from smoothed value noise at tile resolution, so they read as natural blobs.
"""

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import partlib  # noqa: E402
from partlib import Part, T, render  # noqa: E402

TILE = 4
HALF_W = 56  # corridor half width (Config.CourseHalfWidth)
LENGTH = 200  # how much corridor to show
SAND = [(232, 188, 102), (250, 214, 130)]  # the desert's current ground colours
GRASS = [(184, 172, 70), (200, 188, 86)]
STONE = [(206, 146, 84), (222, 164, 100)]
WALL = [(206, 118, 72), (226, 138, 88)]
STONE_UP = 1  # sandstone stands this many studs above the sand


def noise(nx, nz, cell, seed):
    """Value noise: random values on a coarse grid, smoothly upsampled."""
    rng = np.random.default_rng(seed)
    gx, gz = nx // cell + 2, nz // cell + 2
    g = rng.random((gx, gz))
    xs, zs = np.arange(nx) / cell, np.arange(nz) / cell
    x0, z0 = xs.astype(int), zs.astype(int)
    fx, fz = xs - x0, zs - z0
    sx, sz = fx * fx * (3 - 2 * fx), fz * fz * (3 - 2 * fz)
    a = g[x0][:, z0]
    b = g[x0 + 1][:, z0]
    c = g[x0][:, z0 + 1]
    d = g[x0 + 1][:, z0 + 1]
    sx, sz = sx[:, None], sz[None, :]
    return (a * (1 - sx) + b * sx) * (1 - sz) + (c * (1 - sx) + d * sx) * sz


def layout(nx, nz, seed=3):
    """0 sand, 1 dry grass, 2 sandstone, per tile."""
    n1 = noise(nx, nz, 6, seed) * 0.75 + noise(nx, nz, 3, seed + 1) * 0.25
    n2 = noise(nx, nz, 5, seed + 2) * 0.75 + noise(nx, nz, 2, seed + 3) * 0.25
    kind = np.zeros((nx, nz), int)
    kind[n2 > 0.62] = 1
    kind[n1 > 0.64] = 2
    # a one-tile sandstone speck reads as noise, not a plateau: drop it
    for i in range(nx):
        for j in range(nz):
            if kind[i, j] == 2:
                nb = sum(kind[a, b] == 2 for a, b in ((i - 1, j), (i + 1, j), (i, j - 1), (i, j + 1))
                         if 0 <= a < nx and 0 <= b < nz)
                if nb < 2:
                    kind[i, j] = 0
    return kind


def build(kind):
    nx, nz = kind.shape
    parts = []
    for i in range(nx):
        for j in range(nz):
            k = kind[i, j]
            x, z = -HALF_W + i * TILE + TILE / 2, -j * TILE - TILE / 2
            chk = (i + j) % 2
            if k < 2:
                parts.append(Part("Floor", (TILE, 1, TILE), T(x, -0.5, z), (SAND, GRASS)[k][chk]))
            else:
                parts.append(Part("Stone", (TILE, STONE_UP + 1, TILE), T(x, (STONE_UP - 1) / 2, z), STONE[chk]))
    for side in (-1, 1):
        for zi in range(LENGTH // TILE):
            for yi in range(4):
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, -zi * 4 - 2),
                                  WALL[(zi + yi) % 2], plain=True))
    return parts


def main(out):
    os.makedirs(out, exist_ok=True)
    kind = layout(2 * HALF_W // TILE, LENGTH // TILE)
    parts = build(kind)
    # the ride camera: high behind the rider, looking down the course
    ride = render(parts, eye=(0, 70, 30), target=(0, 0, -70), W=1000, H=640, fov=50, fog=False, ground=False)
    ride.save(os.path.join(out, "desert_ground_ride.png"))
    # low and close so the one-stud step shows
    close = render(parts, eye=(-30, 14, -20), target=(-4, 0, -62), W=1000, H=640, fov=45, fog=False, ground=False)
    close.save(os.path.join(out, "desert_ground_close.png"))
    board = Image.new("RGB", (1000, 1280))
    board.paste(ride, (0, 0))
    board.paste(close, (0, 640))
    board.save(os.path.join(out, "desert_ground.png"))
    print("wrote", out, "tiles:", {k: int((kind == k).sum()) for k in (0, 1, 2)})


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/desert_ground")
