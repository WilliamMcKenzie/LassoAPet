"""The Buffalo's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the Buffalo's
brown (tools/buffalo_design.py) with dark hooves at the bottom and its dark shaggy fur over
the top three layers, cream horns out the sides of the top that turn up at grey tips, a
fluffy tuft between them, and a tasselled tail down the back.

Run from the repo root: python3 tools/buffalo_egg.py
Writes designs/eggs/c_style/BuffaloEgg.bbmodel, src/shared/Eggs/BuffaloEggModel.luau,
assets/ui/BuffaloEggRender.png and previews in /mnt/project-files/animals/buffalo/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from buffalo_design import COAT, FUR, HORN, HORN_TIP, HOOF  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402


def buffalo_egg():
    egg = shell([HOOF, COAT, COAT, COAT, FUR, FUR, FUR])
    y = 5 * LH + 0.1
    w = WIDTHS[5] / 2
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * (w - 0.35), sx * (w + 0.45)))
        egg.block("Horn" + side, (xa, y, -0.2), (xb, y + 0.3, 0.15), HORN).bone = "top"
        ta, tb = sorted((sx * (w + 0.15), sx * (w + 0.45)))
        egg.block("HornUp" + side, (ta, y + 0.3, -0.2), (tb, y + 0.65, 0.15), HORN).bone = "top"
        egg.block("HornTip" + side, (ta + 0.04, y + 0.65, -0.16), (tb - 0.04, y + 0.85, 0.11), HORN_TIP).bone = "top"
    top = N * LH
    egg.block("Tuft", (-0.4, top - 0.05, -0.3), (0.4, top + 0.25, 0.3), FUR).bone = "top"
    z = WIDTHS[2] / 2
    egg.block("Tail", (-0.12, 2 * LH + 0.3, z - 0.05), (0.12, 3 * LH + 0.3, z + 0.2), COAT)
    egg.block("TailTuft", (-0.18, 2 * LH - 0.1, z - 0.02), (0.18, 2 * LH + 0.3, z + 0.28), FUR)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Buffalo", buffalo_egg)]
    O.main("Buffalo", preview="/mnt/project-files/animals/buffalo")
