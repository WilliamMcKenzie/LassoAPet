"""The Lion's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the Lion's gold
(tools/lion_design.py) with a cream bottom, its mane as two brown layers near the top with
a darker ruff sticking out round them, small round ears on top and a tail up the back ending
in a dark tuft.

Run from the repo root: python3 tools/lion_egg.py
Writes designs/eggs/c_style/LionEgg.bbmodel, src/shared/Eggs/LionEggModel.luau,
assets/ui/LionEggRender.png and previews in /mnt/project-files/animals/lion/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from lion_design import COAT, CREAM, MANE, MANE_DARK  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402


def lion_egg():
    egg = shell([CREAM, CREAM, COAT, COAT, MANE, MANE, COAT])
    # ruff: four dark blocks sticking out of the mane's sides, front and back
    w = WIDTHS[4] / 2
    for name, lo, hi in (("RuffL", (-w - 0.15, 4 * LH + 0.05, -0.45), (-w + 0.05, 5 * LH - 0.05, 0.45)),
                         ("RuffR", (w - 0.05, 4 * LH + 0.05, -0.45), (w + 0.15, 5 * LH - 0.05, 0.45)),
                         ("RuffF", (-0.45, 4 * LH + 0.05, -w - 0.15), (0.45, 5 * LH - 0.05, -w + 0.05)),
                         ("RuffB", (-0.45, 4 * LH + 0.05, w - 0.05), (0.45, 5 * LH - 0.05, w + 0.15))):
        egg.block(name, lo, hi, MANE_DARK)
    # small round ears on top
    top = N * LH
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.15, sx * 0.48))
        egg.block("Ear" + side, (xa, top - 0.05, -0.15), (xb, top + 0.3, 0.15), COAT).bone = "top"
        ia, ib = sorted((sx * 0.22, sx * 0.4))
        egg.block("EarIn" + side, (ia, top, -0.2), (ib, top + 0.24, -0.15), MANE_DARK).bone = "top"
    # tail up the back to a dark tuft
    z = WIDTHS[2] / 2
    y = 2 * LH
    egg.block("Tail", (-0.15, y, z - 0.05), (0.15, y + 0.3, z + 0.35), COAT)
    egg.block("Tail2", (-0.15, y + 0.3, z + 0.05), (0.15, y + 0.8, z + 0.35), COAT)
    egg.block("TailTuft", (-0.24, y + 0.8, z - 0.02), (0.24, y + 1.2, z + 0.44), MANE_DARK)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Lion", lion_egg)]
    O.main("Lion", preview="/mnt/project-files/animals/lion")
