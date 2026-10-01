"""Ocean biome ground concept: sea-floor sand with seagrass beds and deep blue
trenches, coral clusters, under a blue haze with bubbles.

Run: python3 tools/ocean_ground.py [out_dir]     render a preview
     python3 tools/ocean_ground.py --map           also write it into src/world/World.rbxmx

Same approach as tools/snow_ground.py: noise patches on an 8-stud grid so the
4-stud checker lines up. Sand is the base at 0, seagrass beds stand a stud
higher, and trenches are sunk a stud. The columns along the walls, the start
and the nests stay sand.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, Ry, render  # noqa: E402
from desert_ground import noise, rects, write_patches, CELL, HALF_W  # noqa: E402
import terrain_assets as TA  # noqa: E402

SAND = [(236, 214, 164), (246, 228, 184)]
GRASS = [(64, 178, 122), (80, 196, 138)]  # seagrass
TRENCH = [(70, 150, 214), (86, 166, 228)]
WALL = [(36, 108, 196), (52, 128, 214)]
HAZE = np.array([60, 150, 235.0])  # the blue the distance fades into
TRENCH_DOWN = 1
GRASS_UP = 1
LENGTH = 200  # studs shown in the preview
OCEAN_LENGTH = 6840  # same as the snow (a default; QM can stretch it)
Z_START = -9880  # the ocean's near edge (the snow's far one)
NESTS = [(16, -10240), (-14, -10940), (18, -11740), (-16, -12640), (14, -13640), (-18, -14740), (16, -15840)]
NEST_CLEAR = 14
START_CLEAR = 16
KINDS = ("Ground", "Grass", "Trench")


def layout(nz, seed=41, z_start=0):
    """Kind per 8-stud cell: 0 sand, 1 seagrass, 2 trench."""
    nx = 2 * HALF_W // CELL
    a = noise(nx, nz, 3.0, seed) * 0.7 + noise(nx, nz, 1.4, seed + 1) * 0.3
    b = noise(nx, nz, 4.0, seed + 2) * 0.75 + noise(nx, nz, 1.6, seed + 3) * 0.25
    kind = np.zeros((nx, nz), int)
    kind[a > 0.7] = 1
    kind[(b > 0.62) & (kind == 0)] = 2
    # a sand margin between seagrass and trench
    for i in range(nx):
        for j in range(nz):
            if kind[i, j] == 2 and any(0 <= i + di < nx and 0 <= j + dj < nz and kind[i + di, j + dj] == 1
                                       for di in (-1, 0, 1) for dj in (-1, 0, 1)):
                kind[i, j] = 0
    kind[0, :][kind[0, :] == 2] = 0
    kind[-1, :][kind[-1, :] == 2] = 0
    kind[:, : START_CLEAR // CELL] = 0
    for i in range(nx):
        for j in range(nz):
            x, z = -HALF_W + i * CELL + CELL / 2, z_start - j * CELL - CELL / 2
            if any(abs(x - a) < NEST_CLEAR + CELL / 2 and abs(z - b) < NEST_CLEAR + CELL / 2 for a, b in NESTS):
                kind[i, j] = 0
    return kind


def full_layout():
    return layout(OCEAN_LENGTH // CELL, z_start=Z_START)


def map_boxes(kind):
    out = []
    for k, i0, j0, i1, j1 in rects(kind):
        top = (0, GRASS_UP, -TRENCH_DOWN)[k]
        x0, x1 = -HALF_W + i0 * CELL, -HALF_W + i1 * CELL
        z0, z1 = Z_START - j0 * CELL, Z_START - j1 * CELL
        out.append((KINDS[k], ((x0 + x1) / 2, (top - 2) / 2, (z0 + z1) / 2), (x1 - x0, top + 2, z0 - z1)))
    return out


# a few coral clusters for the preview: (builder, x, z, yaw)
PREVIEW_CORAL = [
    (TA.reef_rock, -30, -60, 20), (TA.tube_coral, -18, -50, 0), (TA.brain_coral, -40, -76, 40),
    (TA.branch_coral, 34, -40, 10), (TA.fan_coral, 42, -46, 70), (TA.tube_coral, 28, -30, 60),
    (TA.brain_coral, 50, -100, 0), (TA.fan_coral, -46, -130, 80), (TA.branch_coral, 10, -120, 30),
    (TA.tube_coral, 18, -126, 0), (TA.reef_rock, 30, -170, -20), (TA.brain_coral, -12, -160, 20),
    (TA.tube_coral, -50, -24, 0), (TA.branch_coral, -24, -190, 0),
]


def scene(kind):
    parts = []
    nx, nz = kind.shape
    for i in range(nx):
        for j in range(nz):
            k = kind[i, j]
            top = (0, GRASS_UP, -TRENCH_DOWN)[k]
            for di in (0, 1):
                for dj in (0, 1):
                    x = -HALF_W + i * CELL + di * 4 + 2
                    z = -j * CELL - dj * 4 - 2
                    c = (SAND, GRASS, TRENCH)[k][(di + dj) % 2]
                    parts.append(Part("Floor", (4, top + 2, 4), T(x, (top - 2) / 2, z), c))
    for side in (-1, 1):
        for zi in range(LENGTH // 4):
            for yi in range(5):
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, -zi * 4 - 2),
                                  WALL[(zi + yi) % 2], plain=True))
    for builder, x, z, yaw in PREVIEW_CORAL:
        k = TA.Kit()
        builder(k)
        M = T(x, 0, z) @ Ry(yaw)
        parts += [Part(p.name, p.size, M @ p.cf, p.color, p.shape, p.plain) for p in k.parts]
    return parts


def underwater(img, seed=3, strength=0.5):
    """Blue haze, stronger toward the top (the distance), plus a bubble field."""
    a = np.asarray(img, float)
    H, W = a.shape[:2]
    ys = np.linspace(1, 0, H)[:, None, None]
    haze = 0.14 + strength * ys ** 1.6
    a = a * (1 - haze) + HAZE * haze
    out = Image.fromarray(a.clip(0, 255).astype(np.uint8)).convert("RGBA")
    layer = Image.new("RGBA", out.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = np.random.default_rng(seed)
    for _ in range(70):
        x, y = rng.uniform(0, W), rng.uniform(0, H)
        r = rng.uniform(3, 12) * (0.5 + y / H)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(220, 240, 255, 60), outline=(255, 255, 255, 200), width=2)
        d.ellipse((x - r * 0.5, y - r * 0.55, x - r * 0.1, y - r * 0.15), fill=(255, 255, 255, 220))
    return Image.alpha_composite(out, layer).convert("RGB")


def main(out):
    os.makedirs(out, exist_ok=True)
    kind = layout(LENGTH // CELL)
    parts = scene(kind)
    kw = dict(W=800, H=520, fog=False, ground=False)
    ride = render(parts, eye=(0, 70, 30), target=(0, 0, -70), fov=50, **kw)
    close = render(parts, eye=(-6, 18, -10), target=(-20, 2, -60), fov=50, **kw)
    board = Image.new("RGB", (1600, 1040))
    board.paste(ride, (0, 0))
    board.paste(close, (0, 520))
    board.paste(underwater(ride), (800, 0))
    board.paste(underwater(close, 5), (800, 520))
    d = ImageDraw.Draw(board)
    for x, y, t in ((10, 10, "ground + coral"), (810, 10, "with blue haze + bubbles")):
        d.text((x, y), t, fill=(255, 255, 255), font=TA.font(20), stroke_width=2, stroke_fill=(0, 0, 0))
    board.save(os.path.join(out, "ocean_ground.png"))
    print("wrote", out, {KINDS[k]: int((kind == k).sum()) for k in range(3)})
    if "--map" in sys.argv:
        print("wrote", write_patches(r"OGND\d+", "OGND", map_boxes(full_layout()), template=r"DGND00000"),
              "ocean floor parts")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0] if args else "/mnt/project-files/biomes/ocean")
