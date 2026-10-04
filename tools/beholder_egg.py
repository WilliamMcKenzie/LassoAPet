"""The Beholder's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
Beholder's orange (tools/beholder_design.py) over a lighter base, its big eye on the
front under a dark brow, and six stubby tentacles round the bottom, curling up to
darker tips.

Run from the repo root: python3 tools/beholder_egg.py
Writes designs/eggs/c_style/BeholderEgg.bbmodel, src/shared/Eggs/BeholderEggModel.luau,
assets/ui/BeholderEggRender.png and previews in /mnt/project-files/animals/beholder/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from beholder_design import COLORS  # noqa: E402
from horse_egg_takes import LH, WIDTHS, shell  # noqa: E402
from partlib import Part, T, Ry  # noqa: E402


def beholder_egg():
    body, dark, light, rim = COLORS["body"], COLORS["dark"], COLORS["light"], COLORS["rim"]
    white, black, brow = COLORS["white"], COLORS["black"], COLORS["brow"]
    egg = shell([light, body, body, body, body, body, body])
    # the eye on the front, layers 3 and 4: rim, white, pupil, glint
    z = WIDTHS[3] / 2
    yc = 3.5 * LH
    for name, w, h, out, col in (("EyeRim", 0.95, 0.95, 0.06, rim), ("EyeRimY", 0.75, 1.1, 0.06, rim),
                                 ("Eye", 0.75, 0.75, 0.12, white), ("EyeY", 0.55, 0.9, 0.12, white),
                                 ("Pupil", 0.36, 0.42, 0.18, black)):
        egg.block(name, (-w / 2, yc - h / 2, -z - out), (w / 2, yc + h / 2, -z + 0.05), col)
    egg.block("Glint", (-0.12, yc + 0.04, -z - 0.22), (-0.02, yc + 0.14, -z - 0.16), white)
    egg.block("Brow", (-0.5, yc + 0.6, -z - 0.14), (0.5, yc + 0.76, -z + 0.05), brow)
    egg.block("TopBump", (-0.22, 7 * LH - 0.02, -0.22), (0.22, 7 * LH + 0.12, 0.22), dark)
    # six tentacles out along the floor, curling up at darker tips
    for k in range(6):
        yaw = 30 + 60 * k
        r0, r1, w = WIDTHS[0] / 2 - 0.15, WIDTHS[1] / 2 + 0.4, 0.34
        for name, lo, hi, col in ((f"Tentacle{k}", (-w / 2, 0, -r1), (w / 2, 0.3, -r0), body),
                                  (f"Curl{k}", (-w / 2 + 0.03, 0, -r1 - 0.26), (w / 2 - 0.03, 0.46, -r1 + 0.02), body),
                                  (f"Tip{k}", (-w / 2 + 0.06, 0.46, -r1 - 0.23), (w / 2 - 0.06, 0.6, -r1 - 0.01), dark)):
            mid = [(a + b) / 2 for a, b in zip(lo, hi)]
            p = Part(name, [b - a for a, b in zip(lo, hi)], Ry(yaw) @ T(*mid), col)
            p.bone = "bottom"
            p.yaw = yaw
            egg.parts.append(p)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Beholder", beholder_egg)]
    O.main("Beholder", preview="/mnt/project-files/animals/beholder")
