"""Nether biome concept: red sand floor, raised red stone, sunken lava, and a
sideways lava geyser on the walls.

Run: python3 tools/nether_ground.py     render the ground options and the geyser

Same recipe as the other biomes: an 8-stud grid of whole checker tiles, three
kinds of ground picked by smoothed noise. Red sand is the base, red stone
stands a stud higher, lava sits a stud lower and glows (Neon).
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, render  # noqa: E402
from desert_ground import noise, HALF_W, CELL  # noqa: E402
import terrain_assets as TA  # noqa: E402

OUT = "/mnt/project-files/biomes/nether"
SAND = [(156, 64, 44), (172, 76, 52)]
STONE = [(104, 36, 34), (120, 44, 40)]
LAVA = [(255, 110, 20), (255, 150, 40)]
WALL = [(84, 30, 30), (100, 38, 36)]
STONE_UP, LAVA_DOWN = 1, 1
LENGTH = 240

OPTIONS = {
    "A": "Lava rivers",   # winding channels, stone blobs (first reference)
    "B": "Lava pools",    # round pools and stone shelves
    "C": "Crumbled",      # busy small patches (second reference)
}


def layout(opt, nz, seed=11):
    """Kind per 8-stud cell: 0 sand, 1 stone, 2 lava."""
    nx = 2 * HALF_W // CELL
    kind = np.zeros((nx, nz), int)
    if opt == "A":
        s = noise(nx, nz, 3.5, seed) * 0.8 + noise(nx, nz, 1.5, seed + 1) * 0.2
        r = noise(nx, nz, 4, seed + 2) * 0.85 + noise(nx, nz, 2, seed + 3) * 0.15
        kind[s > 0.6] = 1
        kind[np.abs(r - 0.5) < 0.06] = 2  # a contour line of noise makes a winding river
    elif opt == "B":
        s = noise(nx, nz, 3, seed + 4) * 0.75 + noise(nx, nz, 1.5, seed + 5) * 0.25
        l = noise(nx, nz, 2.5, seed + 6) * 0.75 + noise(nx, nz, 1.2, seed + 7) * 0.25
        kind[s > 0.6] = 1
        kind[l > 0.66] = 2
    else:
        s = noise(nx, nz, 1.6, seed + 8) * 0.6 + noise(nx, nz, 0.9, seed + 9) * 0.4
        l = noise(nx, nz, 1.8, seed + 10) * 0.7 + noise(nx, nz, 1, seed + 11) * 0.3
        kind[s > 0.52] = 1
        kind[l > 0.68] = 2
    return kind


def floor(kind, length=LENGTH):
    parts = []
    nx, nz = kind.shape
    for i in range(nx):
        for j in range(min(nz, length // CELL)):
            k = kind[i, j]
            top = (0, STONE_UP, -LAVA_DOWN)[k]
            pal = (SAND, STONE, LAVA)[k]
            for di in (0, 1):
                for dj in (0, 1):
                    x = -HALF_W + i * CELL + di * 4 + 2
                    z = -j * CELL - dj * 4 - 2
                    p = Part(("Ground", "Stone", "Lava")[k], (4, top + 2, 4), T(x, (top - 2) / 2, z),
                             pal[(di + dj) % 2], plain=(k == 2))
                    p.neon = k == 2
                    parts.append(p)
    return parts


def walls(length=LENGTH):
    parts = []
    for side in (-1, 1):
        for zi in range(length // 4):
            for yi in range(-1, 5):
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, -zi * 4 - 2),
                                  WALL[(zi + yi) % 2], plain=True))
    return parts


def lava(name, size, cf, c=0):
    p = Part(name, size, cf, LAVA[c], plain=True)
    p.neon = True
    return p


def geyser(side, z, y=6, spray=0.0):
    """A red stone vent poking out of the wall, mouth facing the corridor.
    spray 0 = idle (lava bubbling in the mouth); 0..1 = how far the jet has reached.
    The jet shoots across, then arcs down onto the floor."""
    s = -side  # direction into the corridor
    wx = side * HALF_W
    parts = []
    # chunky cone: three steps of red stone, widest at the wall
    for k, (w, d) in enumerate(((10, 3), (8, 2.5), (6, 2))):
        x = wx + s * (sum((3, 2.5, 2)[:k]) + d / 2)
        parts.append(Part("Vent", (d, w, w), T(x, y, z), STONE[k % 2]))
    # rim: four lips round the mouth
    mx = wx + s * 8
    for dy, dz, sz in ((2.5, 0, (1, 1, 6)), (-2.5, 0, (1, 1, 6)), (0, 2.5, (1, 4, 1)), (0, -2.5, (1, 4, 1))):
        parts.append(Part("Rim", sz, T(mx, y + dy, z + dz), SAND[1]))
    # glowing mouth
    parts.append(lava("Mouth", (0.6, 4, 4), T(mx - s * 0.2, y, z), 1))
    # drips down the wall below the vent
    parts.append(lava("Drip", (0.6, y - 1, 1.2), T(wx + s * 0.4, (y - 1) / 2, z + 1.5)))
    parts.append(lava("Drip", (0.6, y - 3, 1), T(wx + s * 0.4, (y - 3) / 2, z - 2)))
    if spray > 0:
        reach = 80 * spray
        n = int(reach / 3)
        for i in range(n):
            t = i * 3
            h = y + 0.25 * t - 0.0045 * t * t  # rises a little, then falls
            if h < 0.5:
                break
            w = 3.6 + 0.04 * t
            parts.append(lava("Jet", (3.2, w, w), T(mx + s * (t + 1.5), h, z + np.sin(t * 0.35) * 0.6), i % 2))
        # blobs flicked off the stream
        rng = np.random.default_rng(abs(int(z)))
        for _ in range(int(10 * spray)):
            t = rng.uniform(4, reach)
            h = y + 0.25 * t - 0.0045 * t * t + rng.uniform(1.5, 4)
            parts.append(lava("Blob", (1.2, 1.2, 1.2), T(mx + s * t, max(h, 1), z + rng.uniform(-4, 4)), 1))
        # splash pool where it lands
        land = None
        for t in np.arange(0, reach, 0.5):
            if y + 0.25 * t - 0.0045 * t * t < 0.5:
                land = t
                break
        if land is not None:
            for dx, dz2, w in ((0, 0, 8), (3, 3, 4), (-2, -4, 4)):
                parts.append(lava("Splash", (w, 0.4, w), T(mx + s * land + dx, 0.2, z + dz2), 1))
    return parts


def label(img, text):
    d = ImageDraw.Draw(img)
    d.text((16, 12), text, fill=(255, 255, 255), font=TA.font(30), stroke_width=3, stroke_fill=(0, 0, 0))
    return img


def topdown(kind, W=400, length=800):
    nx, nz = kind.shape
    nz = min(nz, length // CELL)
    img = np.zeros((nz * 2, nx * 2, 3), np.uint8)
    for i in range(nx):
        for j in range(nz):
            pal = (SAND, STONE, LAVA)[kind[i, j]]
            for di in (0, 1):
                for dj in (0, 1):
                    img[j * 2 + dj, i * 2 + di] = pal[(di + dj) % 2]
    im = Image.fromarray(img)
    return im.resize((W, int(W * nz / nx)), Image.NEAREST)


def main():
    os.makedirs(OUT, exist_ok=True)
    kw = dict(W=1000, H=620, fog=False, ground=False)
    geysers = geyser(1, -150, spray=1.0) + geyser(-1, -200) + geyser(1, -230, spray=0.5)
    sheets = []
    for opt, name in OPTIONS.items():
        kind = layout(opt, 1600 // CELL)
        parts = floor(kind) + walls() + geysers
        ride = label(render(parts, eye=(0, 70, 30), target=(0, 0, -70), fov=50, **kw), f"{opt}: {name}")
        close = render(parts, eye=(-30, 14, -20), target=(-4, 0, -62), fov=45, **kw)
        top = topdown(kind, W=300, length=1600)
        board = Image.new("RGB", (1000 + 300 + 20, 1240), (30, 14, 12))
        board.paste(ride, (0, 0))
        board.paste(close, (0, 620))
        board.paste(top.crop((0, 0, 300, 1240)), (1020, 0))
        board.save(os.path.join(OUT, f"nether_{opt}.png"))
        sheets.append(board)
        print("option", opt, {k: int((kind == i).sum()) for i, k in enumerate(("sand", "stone", "lava"))})

    # the geyser on its own: idle, building up, full spray
    base = floor(layout("B", 120 // CELL), 120) + walls(120)
    shots = []
    for sp, title in ((0, "Idle"), (0.45, "Starting"), (1.0, "Full spray")):
        parts = base + geyser(1, -60, spray=sp)
        im = render(parts, eye=(-40, 30, -10), target=(30, 4, -60), fov=48, W=700, H=520, fog=False, ground=False)
        shots.append(label(im, title))
    close = label(render(base + geyser(1, -60), eye=(36, 9, -44), target=(52, 6, -60), fov=40, W=700, H=520,
                         fog=False, ground=False), "Vent up close")
    sheet = Image.new("RGB", (1400, 1040))
    for n, im in enumerate(shots + [close]):
        sheet.paste(im, ((n % 2) * 700, (n // 2) * 520))
    sheet.save(os.path.join(OUT, "lava_geyser.png"))


if __name__ == "__main__":
    main()
