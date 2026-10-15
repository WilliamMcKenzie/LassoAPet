"""Beach bushes for World 3 (QM, Oct 15): the leafy clumps by the walls in his screenshot.
Broad pointed leaves fanning out from the ground, each folded along its midrib so one
half is light and the other dark (Camo and Parsley green, the World 3 palm frond colours).

Run: python3 tools/w3_bushes.py
Writes design/w3_bushes/<Name>.obj, pieces/<Name>_<i>.obj + colours.txt, sizes.txt and
bushes_lineup.png.
"""

import math
import os

import numpy as np

from w3props import HERE, build_set, lineup_row, stack

OUT = os.path.join(HERE, "..", "design", "w3_bushes")
LIGHT = (58, 125, 21)  # Camo (QM's palm fronds, Oct 14)
DARK = (44, 101, 29)  # Parsley green


def leaf(base, yaw, length, width, rise, droop, fold=0.35, thick=0.25):
    """One broad pointed leaf: a midrib arching out from base along yaw, two halves folded
    down from it like a shallow V. Returns (light halves, dark halves), two segments each."""
    d = np.array((math.cos(yaw), 0, math.sin(yaw)))
    side = np.array((-d[2], 0, d[0]))
    up = np.array((0, 1, 0))

    def rib(t):
        return np.asarray(base, float) + d * length * t + up * (rise * length * t - droop * t * t)

    def w(t):  # widest a little past the middle, a sharp point at the tip
        return width * (0.25 + 0.75 * math.sin(math.pi * min(t / 0.55, 1.0) * 0.5)) if t < 0.55 else width * (1 - t) / 0.45

    halves = ([], [])
    for t0, t1 in ((0.0, 0.55), (0.55, 1.0)):
        for k, sgn in enumerate((1, -1)):
            pts = []
            for t in (t0, t1):
                c = rib(t)
                e = c + side * sgn * w(t) - up * fold * w(t)
                for p in (c, e):
                    pts += [p, p + up * thick]
            halves[k].append(np.array(pts))
    return halves


def bush(rng, n, length, width):
    """A mound of leaves in three rings: n low arching leaves outside, then a taller ring,
    then a few nearly upright ones in the middle."""
    light, dark = [], []
    rings = ((n, 1.0, 0.95, 0.5, 0.0), (max(3, n // 2), 0.85, 1.6, 0.4, 0.4), (3, 0.7, 2.6, 0.3, 0.9))
    for count, ls, rise, droop, a0 in rings:
        for i in range(count):
            yaw = a0 + 2 * math.pi * i / count + rng.uniform(-0.2, 0.2)
            L = length * ls * rng.uniform(0.92, 1.08)
            a, b = leaf((0, 0, 0), yaw, L, width * ls ** 0.5, rise=rise / L * length * 0.45, droop=L * droop)
            light += a
            dark += b
    return [("Leaves", LIGHT, light), ("Leaves", DARK, dark)]


def beach_bush(rng):
    """A big beach bush (about 9 across, 4 tall): sixteen broad leaves in three rings."""
    return bush(rng, 8, 4.6, 1.8)


def beach_bush_small(rng):
    """A small beach bush (about 6 across, 3 tall): twelve leaves in three rings."""
    return bush(rng, 6, 3.2, 1.35)


ITEMS = [
    ("BeachBush", beach_bush, 2, "Beach bush"),
    ("BeachBushSmall", beach_bush_small, 3, "Small beach bush"),
]

SAND = [(240, 218, 160), (228, 204, 146)]


def main():
    built, sizes = build_set(OUT, ITEMS)
    row = lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS], SAND, ppst=48)
    stack([row], os.path.join(OUT, "bushes_lineup.png"), "Beach bushes (1x; figure is 5 studs)")


if __name__ == "__main__":
    main()
