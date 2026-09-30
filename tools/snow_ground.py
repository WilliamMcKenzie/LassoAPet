"""Snow biome ground concept: snow paths winding between cold grass and frozen ponds.

Run: python3 tools/snow_ground.py [out_dir]     render a preview

After QM's reference (their other game): big teal grass fields and pale blue
ice ponds, with light snow running between them like paths. Same approach as
tools/desert_ground.py: noise patches on an 8-stud grid so the 4-stud checker
lines up. Snow is the base at 0, cold grass sits flush, and ice is sunk a stud
like a frozen pond. The columns along the walls, the start and the nests stay
snow, so sunken ice never opens a gap under a wall or drops a nest.
"""

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, render  # noqa: E402
from desert_ground import noise, CELL, HALF_W  # noqa: E402

SNOW = [(228, 234, 242), (244, 247, 251)]
GRASS = [(80, 160, 166), (96, 176, 180)]  # cold grass, the reference's teal
ICE = [(160, 188, 244), (178, 202, 250)]
WALL = [(126, 164, 214), (146, 182, 228)]
ICE_DOWN = 1
LENGTH = 200  # studs shown in the preview
SNOW_LENGTH = 6840  # 3x the desert (QM)
NESTS = []  # placed later with the course
START_CLEAR = 16
KINDS = ("Ground", "Grass", "Ice")


def layout(nz, seed=21):
    """Kind per 8-stud cell: 0 snow, 1 cold grass, 2 ice."""
    nx = 2 * HALF_W // CELL
    a = noise(nx, nz, 3.5, seed) * 0.75 + noise(nx, nz, 1.6, seed + 1) * 0.25
    b = noise(nx, nz, 3.5, seed + 2) * 0.75 + noise(nx, nz, 1.6, seed + 3) * 0.25
    kind = np.zeros((nx, nz), int)
    kind[a > 0.55] = 1
    kind[(b > 0.55) & (b - 0.55 > a - 0.55)] = 2
    # a snow margin between grass and ice, like the reference's paths
    for i in range(nx):
        for j in range(nz):
            if kind[i, j] == 2 and any(0 <= i + di < nx and 0 <= j + dj < nz and kind[i + di, j + dj] == 1
                                       for di in (-1, 0, 1) for dj in (-1, 0, 1)):
                kind[i, j] = 0
    ice = kind == 2
    ice[0, :] = ice[-1, :] = False
    kind[(kind == 2) & ~ice] = 0
    kind[:, : START_CLEAR // CELL] = 0
    return kind


def take(kind):
    parts = []
    nx, nz = kind.shape
    for i in range(nx):
        for j in range(nz):
            k = kind[i, j]
            top = -ICE_DOWN if k == 2 else 0
            for di in (0, 1):
                for dj in (0, 1):
                    x = -HALF_W + i * CELL + di * 4 + 2
                    z = -j * CELL - dj * 4 - 2
                    c = (SNOW, GRASS, ICE)[k][(di + dj) % 2]
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
    board.save(os.path.join(out, "snow_ground.png"))
    print("wrote", out, {KINDS[k]: int((kind == k).sum()) for k in range(3)})


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0] if args else "/mnt/project-files/biomes/snow")
