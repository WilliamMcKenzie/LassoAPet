"""The Chicken's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
Chicken's white (tools/chicken_design.py) with an orange bottom like its feet, a
yellow beak block on the front, the red wattle under it, red eyes with black
pupils either side, and little wing slabs on the sides.

Run from the repo root: python3 tools/chicken_egg.py
Writes designs/eggs/c_style/ChickenEgg.bbmodel, src/shared/Eggs/ChickenEggModel.luau,
assets/ui/ChickenEggRender.png and previews in /mnt/project-files/animals/chicken/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from chicken_design import COL  # noqa: E402
from horse_egg_takes import LH, PUPIL, WIDTHS, shell  # noqa: E402


def chicken_egg():
    white, wing = COL["white"], COL["wing"]
    egg = shell([COL["leg"], white, white, white, white, white, white])
    # face on the fifth layer: beak in the middle, red eyes either side, the wattle under the beak
    z = -WIDTHS[5] / 2
    egg.block("Beak", (-0.32, 5 * LH, z - 0.4), (0.32, 5 * LH + 0.32, z + 0.05), COL["beak"])
    zw = -WIDTHS[4] / 2
    egg.block("Wattle", (-0.16, 4 * LH + 0.1, zw - 0.15), (0.16, 5 * LH + 0.02, zw + 0.05), COL["wattle"])
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.4, sx * 0.78))
        p = egg.block("Eye" + side, (xa, 5 * LH + 0.05, z - 0.05), (xb, 5 * LH + 0.4, z), COL["eye"])
        p.plain = True
        xa, xb = sorted((sx * 0.46, sx * 0.64))
        p = egg.block("Pupil" + side, (xa, 5 * LH + 0.1, z - 0.08), (xb, 5 * LH + 0.3, z - 0.05), PUPIL)
        p.plain = True
    # wing slabs on the sides of the widest layers
    x = WIDTHS[2] / 2
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * (x - 0.05), sx * (x + 0.2)))
        egg.block("Wing" + side, (xa, 1.5 * LH, -0.6), (xb, 3.6 * LH, 0.6), wing)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Chicken", chicken_egg)]
    O.main("Chicken", preview="/mnt/project-files/animals/chicken")
