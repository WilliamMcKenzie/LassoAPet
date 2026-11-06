"""World 1 Meadow's new animals' eggs (QM, Nov 6), in take C's style (tools/horse_egg_takes.py,
as the Pinto's and the Rhino's): the octo shell in each animal's colours.
  Zebra     white with black bands, the Pinto's ears and a black forelock and ridge
  Gecko     green over a pale bottom, two orange bands, big googly eyes on top
  Elephant  grey, big flat ears out the sides, a trunk down the front, two tusks
The alphas (Alpha Rhino, Alpha Fish, Golden Pig) hatch from their base's egg (Eggs/Egg.luau).

Run from the repo root: python3 tools/meadow_eggs.py
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/animals/meadow/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, CRACK_LAYER, shell, ears, back_ridge, PINK  # noqa: E402
from zebra_design import WHITE, BLACK, HOOF  # noqa: E402
from gecko_design import GREEN, BELLY, SPOT  # noqa: E402

EYE_WHITE, PUPIL = (255, 255, 255), (20, 20, 20)
GREY, TUSK = (156, 152, 166), (246, 238, 214)


def zebra_egg():
    egg = shell([HOOF, WHITE, BLACK, WHITE, BLACK, WHITE, WHITE])
    ears(egg, WHITE, PINK)
    egg.block("Forelock", (-0.36, 2.7, -0.62), (0.36, 3.4, 0.2), BLACK).bone = "top"
    egg.block("Crest", (-0.26, 3.2, 0.2), (0.26, 3.5, 0.7), BLACK).bone = "top"
    back_ridge(egg, BLACK, range(CRACK_LAYER, N))
    return egg


def gecko_egg():
    egg = shell([BELLY, GREEN, SPOT, GREEN, SPOT, GREEN, GREEN])
    top = N * LH
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.1, sx * 0.65))
        egg.block("EyeBump" + side, (xa, top - 0.1, -0.4), (xb, top + 0.35, 0.1), GREEN).bone = "top"
        ea, eb = sorted((sx * 0.14, sx * 0.61))
        egg.block("Eye" + side, (ea, top - 0.05, -0.45), (eb, top + 0.31, -0.4), EYE_WHITE).bone = "top"
        pa, pb = sorted((sx * 0.26, sx * 0.5))
        egg.block("Pupil" + side, (pa, top, -0.48), (pb, top + 0.22, -0.45), PUPIL).bone = "top"
    return egg


def elephant_egg():
    egg = shell([GREY] * N)
    # big flat ears out the sides of the top
    y = 4 * LH + 0.1
    w = WIDTHS[4] / 2
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * (w - 0.05), sx * (w + 0.15)))
        egg.block("Ear" + side, (xa, y, -0.6), (xb, y + 1.0, 0.4), GREY).bone = "top"
    # trunk down the front, tusks either side of it
    zf = -WIDTHS[3] / 2
    egg.block("Trunk", (-0.25, 2 * LH, zf - 0.3), (0.25, 4 * LH + 0.2, zf + 0.05), GREY)
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.4, sx * 0.62))
        egg.block("Tusk" + side, (xa, 3 * LH, zf - 0.45), (xb, 3 * LH + 0.22, zf + 0.05), TUSK)
    return egg


if __name__ == "__main__":
    for kind, fn in (("Zebra", zebra_egg), ("Gecko", gecko_egg), ("Elephant", elephant_egg)):
        O.EGGS = [(kind, fn)]
        O.main(kind, preview="/mnt/project-files/animals/meadow")
