"""The Rolling Log's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the log's
bark (tools/rolling_log.py), darker at the bottom, with raised dark bark strips down the
front and back, a pale cut-log end with a growth ring on each side, and steel spikes on top
and out the front and back, like the log's (QM: the Clash Royale log).

Run from the repo root: python3 tools/rolling_log_egg.py
Writes designs/eggs/c_style/RollingLogEgg.bbmodel, src/shared/Eggs/RollingLogEggModel.luau,
assets/ui/RollingLogEggRender.png and previews in /mnt/project-files/world2/woodland/renders/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from rolling_log import BARK, BARK_DARK, WOOD, RING, CORE, STEEL, STEEL_DARK  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell  # noqa: E402


def spike(egg, name, base, apex, color, bone):
    c = [np.array(p, float) for p in base]
    a = np.array(apex, float)
    return egg.poly(name, [c] + [[c[i], c[(i + 1) % 4], a] for i in range(4)], color, bone=bone)


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
    # a steel spike on top and one out the front and back, like the log's
    top = N * LH
    egg.block("CollarUp", (-0.26, top - 0.05, -0.26), (0.26, top + 0.1, 0.26), STEEL_DARK).bone = "top"
    spike(egg, "SpikeUp", [(-0.2, top + 0.1, -0.2), (0.2, top + 0.1, -0.2), (0.2, top + 0.1, 0.2), (-0.2, top + 0.1, 0.2)],
          (0, top + 0.7, 0), STEEL, "top")
    z, y = WIDTHS[3] / 2, 3.5 * LH
    for d, sz in (("Front", -1), ("Back", 1)):
        za, zb = sorted((sz * (z - 0.05), sz * (z + 0.1)))
        egg.block("Collar" + d, (-0.26, y - 0.26, za), (0.26, y + 0.26, zb), STEEL_DARK)
        zf = sz * (z + 0.1)
        spike(egg, "Spike" + d, [(-0.2, y - 0.2, zf), (0.2, y - 0.2, zf), (0.2, y + 0.2, zf), (-0.2, y + 0.2, zf)],
              (0, y, zf + sz * 0.5), STEEL, "bottom")
    return egg


if __name__ == "__main__":
    O.EGGS = [("RollingLog", rolling_log_egg)]
    O.main("RollingLog", preview="/mnt/project-files/world2/woodland/renders")
