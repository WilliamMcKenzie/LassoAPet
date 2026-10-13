"""Nut's egg, in take C's style (tools/ocean_eggs.py): a night-sky base dotted with glowing
stars, her white linen robe with a gold ankh on the front, a gold and turquoise usekh collar
under the crack, and a lapis wig cap banded with a gold diadem and a glowing brow jewel.
Little royal blue and turquoise wings fold out at the sides, and a gold-rimmed night-sky orb
with a glowing star stands on top.

Run from the repo root: python3 tools/nut_egg.py
Writes designs/eggs/c_style/NutEgg.bbmodel, src/shared/Eggs/NutEggModel.luau,
assets/ui/NutEggRender.png and previews in /mnt/project-files/world2/tomb/nut/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, front_plate, shell  # noqa: E402
from crystal_elephant_egg import point  # noqa: E402
from nut import WHITE, GOLD, TURQ, ROYAL, NIGHT, HAIR, STAR, ORB  # noqa: E402


def nut_egg():
    egg = shell([NIGHT, NIGHT, WHITE, WHITE, HAIR, HAIR, HAIR])
    top = N * LH

    # glowing stars on the night-sky hem, a gold band where it meets the robe
    for k, (x, y) in enumerate(((-0.55, 0.45), (0.1, 0.75), (0.6, 0.35), (-0.15, 0.2), (0.45, 1.1))):
        front_plate(egg, f"GlowHemStar{k + 1}", x - 0.07, x + 0.07, y * LH * 1.4, y * LH * 1.4 + 0.14, STAR, depth=0.04)
    octo_layer(egg, "Hem", 2 * LH - 0.06, 2 * LH + 0.06, WIDTHS[1] + 0.08, GOLD, "bottom")

    # a gold ankh on the robe's front
    front_plate(egg, "Ankh", -0.06, 0.06, 2.25 * LH, 3.1 * LH, GOLD, depth=0.05, plain=False)
    front_plate(egg, "AnkhBar", -0.22, 0.22, 2.95 * LH, 3.1 * LH, GOLD, depth=0.05, plain=False)
    front_plate(egg, "AnkhLoopL", -0.14, -0.06, 3.1 * LH, 3.55 * LH, GOLD, depth=0.05, plain=False)
    front_plate(egg, "AnkhLoopR", 0.06, 0.14, 3.1 * LH, 3.55 * LH, GOLD, depth=0.05, plain=False)
    front_plate(egg, "AnkhLoopT", -0.14, 0.14, 3.55 * LH, 3.68 * LH, GOLD, depth=0.05, plain=False)

    # the usekh collar under the crack: gold over turquoise
    octo_layer(egg, "CollarT", 3.78 * LH, 4 * LH - 0.01, WIDTHS[3] + 0.12, GOLD, "bottom")
    octo_layer(egg, "CollarB", 3.6 * LH, 3.78 * LH, WIDTHS[3] + 0.1, TURQ, "bottom")

    # gold diadem round the wig with a glowing brow jewel
    octo_layer(egg, "Diadem", 5.3 * LH, 5.6 * LH, WIDTHS[5] + 0.16, GOLD, "top")
    zf = -(WIDTHS[5] + 0.16) / 2
    egg.block("GlowBrowGem", (-0.12, 5.25 * LH, zf - 0.05), (0.12, 5.65 * LH, zf), TURQ).bone = "top"

    # folded little wings at the sides, gold bar on top, feathers stepping down
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * WIDTHS[3] / 2
        xs = lambda a, b: sorted((x0 + sx * a, x0 + sx * b))
        for k, (col, y0, y1, out) in enumerate(((GOLD, 3.3, 3.55, 0.42), (ROYAL, 2.9, 3.3, 0.36),
                                                (TURQ, 2.45, 2.9, 0.3), (NIGHT, 1.9, 2.45, 0.24))):
            a, b = xs(-0.02, out)
            egg.block(f"Wing{side}{k + 1}", (a, y0 * LH, -0.15 - 0.05 * k), (b, y1 * LH, 0.5 + 0.08 * k), col).bone = "bottom"
        a, b = xs(0.05, 0.2)
        egg.block(f"GlowWingStar{side}", (a, 2.0 * LH, 0.1), (b, 2.12 * LH + 0.04, 0.24), STAR).bone = "bottom"

    # the night-sky orb on top
    egg.block("OrbStem", (-0.1, top - 0.04, -0.1), (0.1, top + 0.12, 0.1), GOLD).bone = "top"
    egg.block("OrbRim", (-0.36, top + 0.12, -0.07), (0.36, top + 0.84, 0.07), GOLD).bone = "top"
    egg.block("Orb", (-0.28, top + 0.2, -0.1), (0.28, top + 0.76, 0.1), ORB).bone = "top"
    egg.block("GlowOrbStar", (-0.08, top + 0.4, -0.13), (0.08, top + 0.56, 0.13), STAR).bone = "top"
    point(egg, "OrbFinial", (0, top + 0.84, 0), (0, 1, 0), 0.08, 0.25, GOLD, "top")
    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.plain = True
            p.neon = True
    return egg


if __name__ == "__main__":
    O.EGGS = [("Nut", nut_egg)]
    O.main("Nut", preview="/mnt/project-files/world2/tomb/nut")
