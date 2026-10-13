"""The Catfish's egg: the Fish's take-C egg (horse_egg_takes.fish_c) in the Catfish's olive green
and cream (tools/catfish.py), with a long dark whisker out of each side of its front that sweeps
out and back, drooping a step per block.

Run from the repo root: python3 tools/catfish_egg.py
Writes designs/eggs/c_style/CatfishEgg.bbmodel, src/shared/Eggs/CatfishEggModel.luau,
assets/ui/CatfishEggRender.png and previews in /mnt/project-files/world2/temple/.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, WIDTHS, fish_c  # noqa: E402
from partlib import Part, T, Ry  # noqa: E402
from catfish import PALETTE, WHISKER  # noqa: E402

RECOLOR = {(60, 140, 230): PALETTE[2], (170, 215, 250): PALETTE[0], (30, 90, 190): PALETTE[10]}
SEGS = [(0, 0.5), (30, 0.48), (60, 0.44)]  # (degrees back from sideways, length)
T_ = 0.17


def catfish_egg():
    egg = fish_c()
    for p in egg.parts:
        p.color = RECOLOR.get(tuple(p.color), p.color)
    for side, s in (("L", -1), ("R", 1)):
        x, y, z = s * 0.55, 2.6 * LH, -WIDTHS[2] / 2 - 0.02
        for i, (ang, length) in enumerate(SEGS):
            a = math.radians(ang)
            dx, dz = s * math.cos(a), math.sin(a)
            cx, cz = x + dx * length / 2, z + dz * length / 2
            p = Part(f"Whisker{side}{i + 1}", (length + T_, T_, T_), T(cx, y, cz) @ Ry(-s * ang), PALETTE[WHISKER])
            egg.parts.append(p)
            x, z, y = x + dx * length, z + dz * length, y - 0.06
    return egg


if __name__ == "__main__":
    O.EGGS = [("Catfish", catfish_egg)]
    O.main("Catfish", preview="/mnt/project-files/world2/temple")
