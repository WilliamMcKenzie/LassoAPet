"""The Rolling Log's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the log's
bark (tools/rolling_log.py), darker at the bottom, with raised dark bark strips down the
front and back, a pale cut-log end with a growth ring on each side, and a twig with a tuft
of autumn leaves on top.

Run from the repo root: python3 tools/rolling_log_egg.py
Writes designs/eggs/c_style/RollingLogEgg.bbmodel, src/shared/Eggs/RollingLogEggModel.luau,
assets/ui/RollingLogEggRender.png and previews in /mnt/project-files/world2/woodland/renders/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from rolling_log import BARK, BARK_DARK, WOOD, RING, CORE, LEAF, LEAF_GOLD  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell  # noqa: E402


def rolling_log_egg():
    egg = shell([BARK_DARK, BARK, BARK, BARK, BARK, BARK, BARK])
    # bark strips: up the front and back, standing a little off the shell
    for name, sz, x0, x1, l0, l1 in (("StripF", -1, -0.5, -0.22, 1, 5), ("StripF2", -1, 0.25, 0.5, 2, 4),
                                     ("StripB", 1, -0.2, 0.1, 1, 4), ("StripB2", 1, 0.3, 0.55, 3, 6)):
        for i in range(l0, l1):  # a piece per layer, on that layer's face
            z = WIDTHS[i] / 2
            za, zb = sorted((sz * (z - 0.05), sz * (z + 0.08)))
            piece = egg.block(f"{name}_{i}", (x0, i * LH, za), (x1, (i + 1) * LH, zb), BARK_DARK)
            if i >= CRACK_LAYER:
                piece.bone = "top"  # (lifts off with the top when it hatches)
    # cut-log ends on both sides: pale wood, a darker ring, a warm core
    w = WIDTHS[2] / 2
    y = 2.5 * LH + 0.1
    for side, sx in (("L", -1), ("R", 1)):
        for i, (r, c) in enumerate(((0.55, WOOD), (0.38, RING), (0.26, WOOD), (0.12, CORE))):
            xa, xb = sorted((sx * (w + i * 0.03), sx * (w + (i + 1) * 0.03)))
            egg.block(f"End{side}{i + 1}", (xa, y - r, -r), (xb, y + r, r), c)
    # a twig on top with autumn leaves
    top = N * LH
    egg.block("Twig", (-0.1, top - 0.05, -0.1), (0.1, top + 0.45, 0.1), BARK_DARK).bone = "top"
    egg.block("Leaf1", (-0.32, top + 0.45, -0.32), (0.32, top + 0.75, 0.32), LEAF).bone = "top"
    egg.block("Leaf2", (-0.16, top + 0.75, -0.16), (0.16, top + 0.95, 0.16), LEAF_GOLD).bone = "top"
    egg.block("Leaf3", (0.1, top + 0.2, -0.16), (0.42, top + 0.42, 0.16), LEAF_GOLD).bone = "top"
    return egg


if __name__ == "__main__":
    O.EGGS = [("RollingLog", rolling_log_egg)]
    O.main("RollingLog", preview="/mnt/project-files/world2/woodland/renders")
