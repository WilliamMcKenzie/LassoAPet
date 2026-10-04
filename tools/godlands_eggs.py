"""Eggs for the Godlands pets, in take C's style like tools/snow_eggs.py (same shell,
renders and outputs; this only adds the eggs).

  Loong  Legendary  green over a tan base with a gold band, bone horns sweeping back off
                    the top, red whiskers curling out the front, red spikes down the back

Run from the repo root: python3 tools/godlands_eggs.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/eggs/c_style/godlands/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import snow_eggs as S  # noqa: E402
from desert_eggs import fin  # noqa: E402
from egg_designs import H  # noqa: E402
from horse_egg_takes import LH, WIDTHS, shell  # noqa: E402


def loong_egg():
    # the Loong's own colours (designs/godlands/Loong.bbmodel)
    green, tan, gold, amber = (121, 146, 53), (233, 197, 115), (255, 216, 21), (227, 142, 22)
    red, bone = (150, 28, 36), (226, 214, 190)
    egg = shell([tan, green, green, gold, green, green, green])
    # amber trim under the gold band
    for i, z in ((3, WIDTHS[3] / 2),):
        egg.block("Trim", (-0.5, i * LH - 0.06, -z - 0.04), (0.5, i * LH + 0.06, -z + 0.02), amber)

    # horns: up off the crown, then swept back, with a tine forward
    def horn(side, sx, X):
        y0 = H - 0.05
        xa, xb = X(0.16, 0.34)
        egg.block("Horn" + side, (xa, y0, -0.1), (xb, y0 + 0.5, 0.08), bone).bone = "top"
        egg.block("HornBack" + side, (xa, y0 + 0.36, 0.08), (xb, y0 + 0.54, 0.62), bone).bone = "top"
        egg.block("HornTine" + side, (xa, y0 + 0.36, -0.3), (xb, y0 + 0.5, -0.1), bone).bone = "top"
        xa, xb = X(0.16, 0.34)
        egg.block("HornTip" + side, (xa, y0 + 0.54, 0.44), (xb, y0 + 0.74, 0.62), bone).bone = "top"
    S.sides(horn)

    # whiskers: out of the front, then curling down and back in
    def whisker(side, sx, X):
        y, zf = 5 * LH + 0.1, -WIDTHS[5] / 2
        xa, xb = X(0.2, 0.8)
        egg.block("Whisker" + side, (xa, y, zf - 0.12), (xb, y + 0.14, zf + 0.02), red).bone = "top"
        xa, xb = X(0.68, 0.8)
        egg.block("WhiskerDown" + side, (xa, y - 0.5, zf - 0.12), (xb, y, zf + 0.02), red)
        xa, xb = X(0.5, 0.8)
        egg.block("WhiskerCurl" + side, (xa, y - 0.64, zf - 0.12), (xb, y - 0.5, zf + 0.02), red)
    S.sides(whisker)
    # red spikes down the back
    for i in (1, 2, 3, 4, 5):
        fin(egg, f"Spike{i}", i * LH + 0.05, (i + 1) * LH + (0.2 if i % 2 else 0.05), 0.4 if i % 2 else 0.26, 0.12, red)
    return egg


EGGS = [("Loong", loong_egg)]

if __name__ == "__main__":
    S.EGGS = EGGS
    S.main(*sys.argv[1:], preview="/mnt/project-files/eggs/c_style/godlands")
