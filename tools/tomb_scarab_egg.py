"""The Scarab's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the scarab's
teal over a gold base and a lapis band (tools/tomb_scarab.py), a gold seam down the top
like the split of its wing cases, a winged sun on the front (a glowing red sun in a gold
ring, stepped gold wings), a gold horn on the brow, two short antennae with gold fan clubs
on top, and six dark little legs round the base.

Run from the repo root: python3 tools/tomb_scarab_egg.py
Writes designs/eggs/c_style/ScarabEgg.bbmodel, src/shared/Eggs/ScarabEggModel.luau,
assets/ui/ScarabEggRender.png and previews in /mnt/project-files/world2/tomb/eggs/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from crystal_elephant_egg import point  # noqa: E402
from tomb_scarab import COLORS  # noqa: E402

TEAL, DARK, LAPIS, GOLD, GOLDD, UNDER, RED = (COLORS[k] for k in ("teal", "tealdark", "lapis", "gold", "golddark", "under", "red"))


def scarab_egg():
    egg = shell([GOLD, LAPIS, TEAL, TEAL, TEAL, TEAL, DARK])
    top = N * LH
    # a gold band between the lapis and the teal
    octo_layer(egg, "Band", 2 * LH - 0.06, 2 * LH + 0.06, WIDTHS[2] + 0.1, GOLD, "bottom")
    # the gold seam: over the top and down the back, like the split between the wing cases
    w6 = WIDTHS[6] / 2
    egg.block("Seam", (-0.08, top - 0.02, -w6 + 0.1), (0.08, top + 0.07, w6 - 0.1), GOLD).bone = "top"
    for i in range(3, N):
        z = WIDTHS[i] / 2
        egg.block(f"SeamBack{i}", (-0.08, i * LH, z - 0.05), (0.08, (i + 1) * LH, z + 0.06), GOLD).bone = \
            "top" if i >= 4 else "bottom"
    # winged sun on the front: a gold ring, a glowing red sun, stepped gold wings
    zf = -WIDTHS[3] / 2
    yc = 3.5 * LH
    egg.block("SunRing", (-0.26, yc - 0.26, zf - 0.08), (0.26, yc + 0.26, zf + 0.04), GOLD)
    egg.block("GlowSun", (-0.18, yc - 0.18, zf - 0.12), (0.18, yc + 0.18, zf - 0.08), RED)
    for s in (-1, 1):
        for k, (w, h, dy) in enumerate(((0.22, 0.24, 0.04), (0.2, 0.17, 0.08), (0.16, 0.1, 0.12))):
            x0 = 0.26 + 0.2 * k
            xa, xb = sorted((s * x0, s * (x0 + w)))
            egg.block(f"SunWing{'LR'[s > 0]}{k + 1}", (xa, yc + dy - h / 2, zf - 0.04 + 0.03 * k),
                      (xb, yc + dy + h / 2, zf + 0.06 + 0.03 * k), GOLD)
    # a gold horn on the brow and two antennae with fan clubs on top
    zt = -WIDTHS[5] / 2
    point(egg, "Horn", (0, 5.4 * LH, zt + 0.05), (0, 0.8, -0.6), 0.1, 0.35, GOLD, "top")
    for s in (-1, 1):
        n = "LR"[s > 0]
        x = s * 0.3
        egg.block(f"Antenna{n}", (x - 0.05, top - 0.05, -0.25), (x + 0.05, top + 0.4, -0.15), UNDER).bone = "top"
        for k in range(3):
            y = top + 0.36 + 0.08 * k
            egg.block(f"Club{n}{k + 1}", (x - 0.12, y, -0.32), (x + 0.12, y + 0.05, -0.08), GOLD if k != 1 else GOLDD).bone = "top"
    # six little dark legs round the base, three a side
    w0 = WIDTHS[0] / 2
    for s in (-1, 1):
        for k, z in enumerate((-0.35, 0.0, 0.35)):
            xa, xb = sorted((s * (w0 - 0.05), s * (w0 + 0.25)))
            egg.block(f"Leg{'LR'[s > 0]}{k + 1}", (xa, 0.0, z - 0.07), (xb, 0.25, z + 0.07), UNDER)
            xa, xb = sorted((s * (w0 + 0.15), s * (w0 + 0.3)))
            egg.block(f"Foot{'LR'[s > 0]}{k + 1}", (xa, 0.0, z - 0.09), (xb, 0.1, z + 0.09), GOLD)
    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.plain = True
            p.neon = True
    return egg


if __name__ == "__main__":
    O.EGGS = [("Scarab", scarab_egg)]
    O.main("Scarab", preview="/mnt/project-files/world2/tomb/eggs")
