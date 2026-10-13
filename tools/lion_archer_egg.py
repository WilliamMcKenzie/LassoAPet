"""The Lion Archer's egg, in take C's style (tools/ocean_eggs.py): the octo shell in sand
with a lapis and gold usekh collar round the bottom half, the lion's face on the layer
over the crack (kohl-lined googly eyes, a cream muzzle and nose), a lapis-and-gold
striped nemes on the top with a gold headband and the rearing cobra with its ruby, two
round ears, a braided beard under the muzzle, and a pair of fletched arrows poking out
of the top at the back like its quiver.

Run from the repo root: python3 tools/lion_archer_egg.py
Writes designs/eggs/c_style/LionArcherEgg.bbmodel, src/shared/Eggs/LionArcherEggModel.luau,
assets/ui/LionArcherEggRender.png and previews in /mnt/project-files/world2/tomb/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from lion_archer import (COAT, COAT_DARK, CREAM, MANE, NOSE, KOHL, GOLD, GOLD_DARK, LAPIS, TURQ,  # noqa: E402
                         CARNELIAN, RUBY, WHITE)

PUPIL = (30, 30, 45)


def lion_archer_egg():
    egg = shell([COAT_DARK, COAT, TURQ, GOLD, COAT, LAPIS, GOLD])
    # collar drops: carnelian beads hanging under the turquoise row
    z2 = -WIDTHS[1] / 2
    for i in range(5):
        x = -0.6 + 0.3 * i
        egg.block(f"CollarBead{i + 1}", (x - 0.09, 1 * LH + 0.12, z2 - 0.06), (x + 0.09, 2 * LH, z2 + 0.02), CARNELIAN)

    # face on the layer over the crack: eyes with kohl, muzzle and nose
    layer = 4
    z = -WIDTHS[layer] / 2
    y0, y1 = layer * LH + 0.03, layer * LH + LH
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.12, sx * 0.72))
        egg.block("Eye" + side, (xa, y0 + 0.05, z - 0.05), (xb, y1, z + 0.02), WHITE)
        pa, pb = sorted((sx * 0.25, sx * 0.6))
        egg.block("Pupil" + side, (pa, y0 + 0.08, z - 0.08), (pb, y1 - 0.1, z - 0.03), PUPIL)
        ka, kb = sorted((sx * 0.08, sx * 0.9))
        egg.block("Kohl" + side, (ka, y0, z - 0.07), (kb, y0 + 0.05, z + 0.02), KOHL)
        wa, wb = sorted((sx * 0.72, sx * 0.9))
        egg.block("KohlWing" + side, (wa, y0 + 0.08, z - 0.07), (wb, y0 + 0.18, z + 0.02), KOHL)
    # muzzle straddles the crack, on the bottom half, with the nose on top
    zb = -WIDTHS[3] / 2
    egg.block("Muzzle", (-0.38, 3 * LH + 0.12, zb - 0.22), (0.38, 4 * LH - 0.02, zb + 0.02), CREAM)
    egg.block("Nose", (-0.17, 4 * LH - 0.16, zb - 0.27), (0.17, 4 * LH - 0.02, zb - 0.2), NOSE)
    egg.block("Mouth", (-0.2, 3 * LH + 0.2, zb - 0.25), (0.2, 3 * LH + 0.25, zb - 0.2), NOSE)
    # braided beard under the muzzle: gold and lapis bands
    for k in range(3):
        egg.block(f"Beard{k + 1}", (-0.12, 3 * LH + 0.12 - 0.16 * (k + 1), zb - 0.2), (0.12, 3 * LH + 0.12 - 0.16 * k, zb - 0.02),
                  GOLD if k % 2 == 0 else LAPIS)

    # nemes: gold stripes up the lapis layer, a gold headband on its front
    z5 = -WIDTHS[5] / 2
    for i, x in enumerate((-0.6, -0.2, 0.2, 0.6)):
        egg.block(f"NemesStripe{i + 1}", (x - 0.08, 5 * LH + 0.1, z5 - 0.03), (x + 0.08, 6 * LH, z5 + 0.02), GOLD)
    egg.block("Headband", (-0.85, 5 * LH, z5 - 0.06), (0.85, 5 * LH + 0.12, z5 + 0.02), GOLD)
    # the cobra: body up the front, hood, ruby, head
    egg.block("CobraBody", (-0.07, 5 * LH, z5 - 0.12), (0.07, 6 * LH + 0.1, z5 - 0.04), GOLD)
    egg.block("CobraHood", (-0.18, 6 * LH - 0.12, z5 - 0.16), (0.18, 6 * LH + 0.2, z5 - 0.08), GOLD)
    egg.block("GlowCobraGem", (-0.07, 6 * LH - 0.04, z5 - 0.19), (0.07, 6 * LH + 0.1, z5 - 0.16), RUBY)
    egg.block("CobraHead", (-0.09, 6 * LH + 0.2, z5 - 0.26), (0.09, 6 * LH + 0.32, z5 - 0.04), GOLD_DARK)

    # round ears and the arrows out of the top
    top = N * LH
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.25, sx * 0.62))
        egg.block("Ear" + side, (xa, top - 0.25, -0.2), (xb, top + 0.15, 0.1), COAT)
        ia, ib = sorted((sx * 0.33, sx * 0.54))
        egg.block("EarIn" + side, (ia, top - 0.1, -0.23), (ib, top + 0.08, -0.2), MANE)
    for i, (x, h, fc) in enumerate(((-0.12, 0.7, CARNELIAN), (0.14, 0.55, WHITE))):
        egg.block(f"ArrowShaft{i + 1}", (x - 0.04, top - 0.1, 0.25), (x + 0.04, top + h, 0.33), (232, 210, 160))
        egg.block(f"ArrowFletchA{i + 1}", (x - 0.015, top + h - 0.3, 0.18), (x + 0.015, top + h, 0.4), fc)
        egg.block(f"ArrowFletchB{i + 1}", (x - 0.11, top + h - 0.3, 0.275), (x + 0.11, top + h, 0.305), fc)
    return egg


if __name__ == "__main__":
    O.EGGS = [("LionArcher", lion_archer_egg)]
    O.main(*sys.argv[1:], preview="/mnt/project-files/world2/tomb")
