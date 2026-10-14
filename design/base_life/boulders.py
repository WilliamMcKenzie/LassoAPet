"""QM (Oct 10): a boulder on each of the 4 dirt patches between the pens.
Patch spots read off QM's top-down screenshot of the live base (mirrored pairs)."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import base_life as B  # noqa: E402
from base_life import A, W, place, big_rock  # noqa: E402

PATCHES = [(-57, 225, 1), (57, 225, 1), (-148, 130, 0), (148, 130, 0)]  # x, z, back pair?


def scene(rocks=True, scale=2.6):
    kind = B.ground()
    for x, z, _ in PATCHES:  # blocky dirt patch, like the live ones
        for i in range(kind.shape[0]):
            for j in range(kind.shape[1]):
                cx, cz = -W + i * 4 + 2, j * 4 + 2
                dx, dz = abs(cx - x), abs(cz - z)
                if dx <= 10 and dz <= 14 or dx <= 14 and dz <= 10:
                    kind[i, j] = 1
    B.ground = lambda: kind
    parts = B.base_scene()
    if rocks:
        for n, (x, z, back) in enumerate(PATCHES):
            yaw = (35, -145, 80, -20)[n]
            parts += place(big_rock(bool(back)), x, z, yaw, scale)
    return parts


B.VIEWS["close"] = dict(eye=(-10, 40, 150), target=(-57, 0, 225), fov=60, W=1600, H=900)

if __name__ == "__main__":
    s = float(sys.argv[1]) if len(sys.argv) > 1 else 2.6
    parts = scene(scale=s)
    for view in sys.argv[2:] or ["top", "home", "close"]:
        B.shoot(parts, f"boulders_s{s:g}", view, "Boulders on the dirt patches")
