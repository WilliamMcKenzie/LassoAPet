"""The Bunny's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
Cottontail's tan (tools/bunny_design.py) with a cream bottom and belly, two tall
block ears with pink insides on top, and a white cotton tail on the back.

Run from the repo root: python3 tools/bunny_egg.py
Writes designs/eggs/c_style/BunnyEgg.bbmodel, src/shared/Eggs/BunnyEggModel.luau,
assets/ui/BunnyEggRender.png and previews in /mnt/project-files/animals/bunny/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from bunny_design import TAKES, TAIL  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, front_plate, shell  # noqa: E402
from animal_designs import PINK  # noqa: E402


def bunny_egg():
    coat, light = TAKES["A"]["coat"], TAKES["A"]["light"]
    egg = shell([light, light, coat, coat, coat, coat, coat])
    front_plate(egg, "Belly", -0.45, 0.45, 2 * LH, 3.5 * LH, light, depth=0.05, plain=False)
    top = N * LH
    # tall block ears, a pink block on the front of each
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.16, sx * 0.6))
        egg.block("Ear" + side, (xa, top - 0.05, -0.15), (xb, top + 1.3, 0.15), coat)
        ia, ib = sorted((sx * 0.26, sx * 0.5))
        egg.block("EarIn" + side, (ia, top + 0.1, -0.23), (ib, top + 1.15, -0.15), PINK)
    # cotton tail on the back
    z = WIDTHS[2] / 2
    egg.block("Tail", (-0.3, 2 * LH, z - 0.05), (0.3, 2 * LH + 0.6, z + 0.35), TAIL)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Bunny", bunny_egg)]
    O.main("Bunny", preview="/mnt/project-files/animals/bunny")
