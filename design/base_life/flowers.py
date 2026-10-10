"""QM's pixel-art "ground flower" (Oct 10): a yellow centre square with 4 red squares round it,
scattered flat on the base grass. Run: python3 design/base_life/flowers.py [px] -> flowers_*.png"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import base_life as B  # noqa: E402
from base_life import A, Part, T, C, RC, PEN, W, D  # noqa: E402

YELLOW, RED = (255, 214, 40), (226, 38, 72)


def in_pen(x, z, pad=4):
    for p in A.pens():
        t = math.radians(p["a"])
        dx, dz = x - p["x"], z - p["z"]
        along, out = -dx * math.sin(t) + dz * math.cos(t), dx * math.cos(t) + dz * math.sin(t)
        if abs(along) < PEN / 2 + pad and abs(out) < PEN / 2 + pad:
            return True
    return False


def flower(x, z, px):
    out = [Part("Flower", (px, 0.1, px), T(x, 0.05, z), YELLOW, plain=True)]
    for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        out.append(Part("Flower", (px, 0.1, px), T(x + dx * px, 0.05, z + dz * px), RED, plain=True))
    return out


def scatter(kind, px, gap, seed=7):
    rnd = random.Random(seed)
    pts = []
    for _ in range(20000):
        x = round(rnd.uniform(-W + 4, W - 4) / px) * px
        z = round(rnd.uniform(4, D - 4) / px) * px
        i, j = int((x + W) // 4), int(z // 4)
        if kind[i, j] or in_pen(x, z) or any(math.hypot(x - a, z - b) < gap for a, b in pts):
            continue
        # every square of the cross must sit on grass
        if any(kind[int((x + W + dx) // 4) % kind.shape[0], int((z + dz) // 4) % kind.shape[1]]
               for dx in (-1.5 * px, 1.5 * px) for dz in (-1.5 * px, 1.5 * px)):
            continue
        pts.append((x, z))
    return pts


B.VIEWS["close"] = dict(eye=(-20, 26, 176), target=(-66, 0, 232), fov=60, W=1600, H=900)

if __name__ == "__main__":
    px = float(sys.argv[1]) if len(sys.argv) > 1 else 1.0
    gap = float(sys.argv[2]) if len(sys.argv) > 2 else 12
    kind = B.ground()
    parts = B.base_scene()
    pts = scatter(kind, px, gap)
    for x, z in pts:
        parts += flower(x, z, px)
    print(len(pts), "flowers")
    tag = f"flowers_px{px:g}"
    for view in sys.argv[3:] or ["top", "home", "close"]:
        B.shoot(parts, tag, view, f"Ground flowers ({px:g}-stud squares)")
