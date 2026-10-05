"""Nether pen concepts: the pen you get once the Nether (after the Ocean, before
the Godlands) is open. Three takes, from a light restyle of the ranch fence to a
small forge, all at the level-5 size and in the Nether ground colours.

Run: python3 tools/nether_pen.py     renders /mnt/project-files/biomes/nether/nether_pen.png
"""

import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, render  # noqa: E402
import terrain_assets as TA  # noqa: E402
from badlands import SAND, STONE, LAVA, WALL  # noqa: E402

OUT = "/mnt/project-files/biomes/nether"
N = 17  # tiles a side (the Ocean size; the base has no room for more)
S = N * 4
GATE = 10
H0, H1 = -S / 2, S / 2  # x span; z from -S/2 (gap side) to S/2


def lava(size, cf, c=0):
    p = Part("Lava", size, cf, LAVA[c], plain=True)
    p.neon = True
    return p


def box(parts, lo, hi, color, name="Block", plain=False):
    c = [(a + b) / 2 for a, b in zip(lo, hi)]
    s = [b - a for a, b in zip(lo, hi)]
    parts.append(Part(name, s, T(*c), color, plain=plain))


def floor():
    parts = []
    for i in range(N):
        for j in range(N):
            x, z = H0 + i * 4 + 2, H0 + j * 4 + 2
            parts.append(Part("Floor", (4, 0.4, 4), T(x, 0.2, z), SAND[(i + j) % 2]))
    # the ground round the pen
    for i in range(-4, N + 4):
        for j in range(-6, N + 3):
            if 0 <= i < N and 0 <= j < N:
                continue
            x, z = H0 + i * 4 + 2, H0 + j * 4 + 2
            parts.append(Part("Ground", (4, 0.2, 4), T(x, 0.1, z), SAND[(i + j) % 2]))
    return parts


def runs():
    """Fence runs as (a, b) on the ground, the gap in the -z side."""
    g = GATE / 2
    return [((H0, H0), (-g, H0)), ((g, H0), (H1, H0)), ((H0, H0), (H0, H1)), ((H1, H0), (H1, H1)), ((H0, H1), (H1, H1))]


def along(a, b, step):
    L = math.dist(a, b)
    n = max(1, math.ceil(L / step - 1e-9))
    return [(a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n) for k in range(n + 1)], L


def take_a():
    """A: the ranch fence in red stone. Same posts and rails as every pen,
    posts dark red stone with a glowing lava block on top, rails red stone."""
    parts = []
    posts = set()
    for a, b in runs():
        pts, L = along(a, b, 6)
        posts.update((round(x, 3), round(z, 3)) for x, z in pts)
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        horiz = abs(b[0] - a[0]) > 1
        for y in (0.9, 3.3):
            size = (L, 0.6, 0.6) if horiz else (0.6, 0.6, L)
            parts.append(Part("Rail", size, T(mx, y, mz), STONE[1]))
    for x, z in posts:
        box(parts, (x - 0.7, 0, z - 0.7), (x + 0.7, 4.4, z + 0.7), WALL[1], "Post")
        parts.append(lava((1, 0.8, 1), T(x, 4.8, z)))
    return parts


def take_b():
    """B: a low studded red stone wall (2 blocks high, chunky merlons every
    other block) with a sunk lava channel running round the inside, and two
    gate pillars with lava pots."""
    parts = []
    for a, b in runs():
        pts, L = along(a, b, 4)
        horiz = abs(b[0] - a[0]) > 1
        for k in range(len(pts) - 1):
            (x0, z0), (x1, z1) = pts[k], pts[k + 1]
            cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
            w = math.dist(pts[k], pts[k + 1])
            size = (w, 2, 2) if horiz else (2, 2, w)
            for y in (1, 3):
                parts.append(Part("Wall", size, T(cx, y, cz), STONE[(k + int(y)) % 2]))
            if k % 2 == 0:
                parts.append(Part("Merlon", (min(w, 2), 1.5, 2) if horiz else (2, 1.5, min(w, 2)), T(cx, 4.75, cz), WALL[1]))
    # lava channel just inside the wall, sunk into the floor
    a, b = 2, 3.5  # the channel runs this far in from the wall line
    for (x0, z0, x1, z1) in ((H0 + a, H0 + a, -GATE / 2 - 1, H0 + b), (GATE / 2 + 1, H0 + a, H1 - a, H0 + b),
                             (H0 + a, H0 + a, H0 + b, H1 - a), (H1 - b, H0 + a, H1 - a, H1 - a),
                             (H0 + a, H1 - b, H1 - a, H1 - a)):
        parts.append(lava((x1 - x0, 0.3, z1 - z0), T((x0 + x1) / 2, 0.3, (z0 + z1) / 2)))
    for sx in (-1, 1):
        x = sx * (GATE / 2 + 1.5)
        box(parts, (x - 1.5, 0, H0 - 1.5), (x + 1.5, 7, H0 + 1.5), WALL[0], "Pillar")
        box(parts, (x - 2, 7, H0 - 2), (x + 2, 8, H0 + 2), STONE[1], "Bowl")
        parts.append(lava((3, 0.6, 3), T(x, 8.2, H0)))
    return parts


def take_c():
    """C: a small forge. The B wall, plus a corner pillar at each back corner
    and a gate arch: two pillars, a beam with a lava seam, lava drips down the
    pillars, and a lava pot on each corner pillar."""
    parts = take_b()
    parts = [p for p in parts if p.name not in ("Pillar", "Bowl", "Lava") or p.size[1] < 0.5]
    for sx in (-1, 1):
        x = sx * (GATE / 2 + 1.5)
        box(parts, (x - 1.5, 0, H0 - 1.5), (x + 1.5, 10, H0 + 1.5), WALL[0], "Pillar")
        parts.append(lava((0.4, 7, 0.8), T(x - sx * 1.6, 5.5, H0 - 1.6)))
    box(parts, (-GATE / 2 - 3, 10, H0 - 1.8), (GATE / 2 + 3, 12.5, H0 + 1.8), STONE[1], "Beam")
    parts.append(lava((GATE + 2, 0.6, 0.4), T(0, 11.2, H0 - 1.95)))
    for cx, cz in ((H0, H1), (H1, H1), (H0, H0), (H1, H0)):
        box(parts, (cx - 2, 0, cz - 2), (cx + 2, 8, cz + 2), WALL[0], "Pillar")
        box(parts, (cx - 2.5, 8, cz - 2.5), (cx + 2.5, 9, cz + 2.5), STONE[1], "Bowl")
        parts.append(lava((4, 0.6, 4), T(cx, 9.2, cz)))
    return parts


def label(img, text):
    d = ImageDraw.Draw(img)
    d.text((16, 12), text, fill=(255, 255, 255), font=TA.font(30), stroke_width=3, stroke_fill=(0, 0, 0))
    return img


def main():
    base = floor()
    takes = [("A: Red stone ranch fence", take_a()), ("B: Stone wall + lava channel", take_b()),
             ("C: Forge (B + gate arch, lava pots)", take_c())]
    W, H = 900, 620
    board = Image.new("RGB", (W * 2, H * len(takes)))
    for n, (name, parts) in enumerate(takes):
        scene = base + parts
        wide = render(scene, eye=(0, 80, -110), target=(0, 0, 4), fov=50, W=W, H=H, fog=False, ground=False)
        close = render(scene, eye=(-26, 14, -58), target=(0, 4, -30), fov=50, W=W, H=H, fog=False, ground=False)
        board.paste(label(wide, name), (0, H * n))
        board.paste(close, (W, H * n))
    board.save(os.path.join(OUT, "nether_pen.png"))


if __name__ == "__main__":
    main()
