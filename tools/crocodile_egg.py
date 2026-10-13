"""The Crocodile's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
Crocodile's green (tools/crocodile_design.py) with its pale belly at the bottom, a pink
mouth band across the front with pyramid teeth up off it like the dinos', a row of dark
scutes up the back and two eye bumps on top with googly eyes looking forward.

Run from the repo root: python3 tools/crocodile_egg.py
Writes designs/eggs/c_style/CrocodileEgg.bbmodel, src/shared/Eggs/CrocodileEggModel.luau,
assets/ui/CrocodileEggRender.png and previews in /mnt/project-files/animals/crocodile/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from crocodile_design import GREEN, DARK, BELLY, TOOTH, MOUTH  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from bone_rex_egg import pyr  # noqa: E402

WHITE, BLACK = (255, 255, 255), (20, 20, 20)


def crocodile_egg():
    egg = shell([BELLY, BELLY, GREEN, GREEN, GREEN, GREEN, GREEN])
    # pink mouth band across the front of layer 2, teeth pointing up off it
    w = WIDTHS[2] / 2
    y = 2 * LH
    egg.block("Mouth", (-w + 0.35, y + 0.05, -w - 0.05), (w - 0.35, y + 0.25, -w + 0.1), MOUTH)
    for i, x in enumerate((-0.75, -0.25, 0.25, 0.75)):
        pyr(egg, f"Tooth{i + 1}", (x, y + 0.25, -w - 0.02), (0, 1, 0), 0.11, 0.3, TOOTH)
    # dark scutes up the back
    for i in range(3):
        k = 2 + i
        z = WIDTHS[k] / 2
        egg.block(f"Scute{i + 1}", (-0.25, k * LH + 0.15, z - 0.05), (0.25, (k + 1) * LH - 0.15, z + 0.12), DARK)
    # eye bumps on top, googly eyes facing forward
    top = N * LH
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.12, sx * 0.55))
        egg.block("EyeBump" + side, (xa, top - 0.1, -0.35), (xb, top + 0.3, 0.05), GREEN).bone = "top"
        ea, eb = sorted((sx * 0.16, sx * 0.51))
        egg.block("Eye" + side, (ea, top - 0.05, -0.4), (eb, top + 0.26, -0.35), WHITE).bone = "top"
        pa, pb = sorted((sx * 0.26, sx * 0.44))
        egg.block("Pupil" + side, (pa, top, -0.43), (pb, top + 0.18, -0.4), BLACK).bone = "top"
    return egg


if __name__ == "__main__":
    O.EGGS = [("Crocodile", crocodile_egg)]
    O.main("Crocodile", preview="/mnt/project-files/animals/crocodile")
