"""The Kitten's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
ginger's orange (tools/kitten_design.py) with a white bottom, two bold dark tabby
bands, pointed pink-lined ears on top and a striped tail with a white tip up
the back.

Run from the repo root: python3 tools/kitten_egg.py
Writes designs/eggs/c_style/KittenEgg.bbmodel, src/shared/Eggs/KittenEggModel.luau,
assets/ui/KittenEggRender.png and previews in /mnt/project-files/animals/kitten/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from kitten_design import WHITE  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, ears, shell  # noqa: E402
from animal_designs import PINK  # noqa: E402

COAT, DARK = (244, 150, 58), (204, 104, 34)


def kitten_egg():
    egg = shell([WHITE, WHITE, COAT, DARK, COAT, DARK, COAT])
    ears(egg, COAT, PINK, x=0.5, hw=0.42, h=0.95)
    # tail up the back: a coat block, a dark ring, a white tip
    z = WIDTHS[2] / 2
    y = 2 * LH
    egg.block("Tail", (-0.18, y, z - 0.05), (0.18, y + 0.35, z + 0.4), COAT)
    egg.block("Tail2", (-0.18, y + 0.35, z + 0.04), (0.18, y + 0.8, z + 0.4), COAT)
    egg.block("TailRing", (-0.18, y + 0.8, z + 0.04), (0.18, y + 1.0, z + 0.4), DARK)
    egg.block("TailTip", (-0.18, y + 1.0, z + 0.04), (0.18, y + 1.4, z + 0.4), WHITE)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Kitten", kitten_egg)]
    O.main("Kitten", preview="/mnt/project-files/animals/kitten")
