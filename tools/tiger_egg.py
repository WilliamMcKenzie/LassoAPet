"""The Tiger's egg, in take C's style (tools/ocean_eggs.py), as the Lion's: the octo shell in
the Tiger's orange (tools/tiger_design.py) with a white bottom, a black stripe down each side,
front and back (split at the crack), round ears with white insides on top and a tail up the
back with a black ring and tip.

Run from the repo root: python3 tools/tiger_egg.py
Writes designs/eggs/c_style/TigerEgg.bbmodel, src/shared/Eggs/TigerEggModel.luau,
assets/ui/TigerEggRender.png and previews in /mnt/project-files/world2/temple/renders/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from tiger_design import COAT, WHITE, STRIPE  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402


def tiger_egg():
    egg = shell([WHITE, WHITE, COAT, COAT, COAT, COAT, COAT])
    # stripes: one block per layer on each flat face, layers 2 to 5
    for i in range(2, 6):
        w = WIDTHS[i] / 2
        y0, y1 = i * LH + 0.01, (i + 1) * LH - 0.01
        for name, lo, hi in (("L", (-w - 0.06, y0, -0.12), (-w + 0.05, y1, 0.12)),
                             ("R", (w - 0.05, y0, -0.12), (w + 0.06, y1, 0.12)),
                             ("F", (-0.12, y0, -w - 0.06), (0.12, y1, -w + 0.05)),
                             ("B", (-0.12, y0, w - 0.05), (0.12, y1, w + 0.06))):
            egg.block(f"Stripe{name}{i}", lo, hi, STRIPE)
    # round ears with white insides on top
    top = N * LH
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.15, sx * 0.48))
        egg.block("Ear" + side, (xa, top - 0.05, -0.15), (xb, top + 0.3, 0.15), COAT).bone = "top"
        ia, ib = sorted((sx * 0.22, sx * 0.4))
        egg.block("EarIn" + side, (ia, top, -0.2), (ib, top + 0.24, -0.15), WHITE).bone = "top"
    # tail up the back (beside the back stripe): a black ring and a black tip
    z = WIDTHS[2] / 2
    y = 2 * LH
    egg.block("Tail", (0.25, y, z - 0.05), (0.55, y + 0.3, z + 0.35), COAT)
    egg.block("Tail2", (0.25, y + 0.3, z + 0.05), (0.55, y + 0.65, z + 0.35), COAT)
    egg.block("TailRing", (0.23, y + 0.65, z + 0.03), (0.57, y + 0.8, z + 0.37), STRIPE)
    egg.block("Tail3", (0.25, y + 0.8, z + 0.05), (0.55, y + 1.0, z + 0.35), COAT)
    egg.block("TailTip", (0.25, y + 1.0, z + 0.05), (0.55, y + 1.25, z + 0.35), STRIPE)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Tiger", tiger_egg)]
    O.main("Tiger", preview="/mnt/project-files/world2/temple/renders")
