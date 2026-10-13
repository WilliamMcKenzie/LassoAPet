"""The Marble Fish's egg: the Fish's take-C egg (horse_egg_takes.fish_c) in the Marble Fish's
yellows (tools/marble_fish.py), with a twisted marble horn at the front of its top.

Run from the repo root: python3 tools/marble_fish_egg.py
Writes designs/eggs/c_style/MarbleFishEgg.bbmodel, src/shared/Eggs/MarbleFishEggModel.luau,
assets/ui/MarbleFishEggRender.png and previews in /mnt/project-files/animals/marble_fish/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import H, fish_c  # noqa: E402
from partlib import Part, T, Ry  # noqa: E402
from marble_fish import PALETTE  # noqa: E402

RECOLOR = {(60, 140, 230): PALETTE[2], (170, 215, 250): PALETTE[0], (30, 90, 190): PALETTE[10]}


def marble_fish_egg():
    egg = fish_c()
    for p in egg.parts:
        p.color = RECOLOR.get(tuple(p.color), p.color)
    y, w, z = H - 0.05, 0.36, -0.55
    for i in range(4):
        h = 0.26
        p = Part(f"Horn{i}", (w, h, w), T(0, y + h / 2, z) @ Ry(45 * (i % 2)), PALETTE[12] if i % 2 == 0 else PALETTE[14])
        p.bone = "top"
        egg.parts.append(p)
        y += h - 0.01
        w -= 0.07
    a = w * 0.8 / 2
    c = [np.array(v, float) for v in ((-a, y, z - a), (a, y, z - a), (a, y, z + a), (-a, y, z + a))]
    apex = np.array((0, y + 0.45, z))
    egg.poly("HornTip", [c] + [[c[i], c[(i + 1) % 4], apex] for i in range(4)], PALETTE[12], bone="top")
    return egg


if __name__ == "__main__":
    O.EGGS = [("MarbleFish", marble_fish_egg)]
    O.main("MarbleFish", preview="/mnt/project-files/animals/marble_fish")
