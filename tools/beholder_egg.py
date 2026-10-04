"""The Beholder's egg, in take C's style (tools/ocean_eggs.py), as plain as the Beholder
(QM, Oct 4): the octo shell all in its orange (tools/beholder_design.py), a square
white eye plate with a square pupil on the front, and six stubby tentacles round the
bottom, curling up to darker tips.

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
    body, dark = COLORS["body"], COLORS["dark"]
    white, black = COLORS["white"], COLORS["black"]
    egg = shell([body] * 7)
    # the eye on the front, like the Beholder's now (QM, Oct 4): a square white plate
    # and a square pupil, nothing else
    z = WIDTHS[3] / 2
    yc = 3.5 * LH
    egg.block("Eye", (-0.5, yc - 0.5, -z - 0.06), (0.5, yc + 0.5, -z + 0.05), white)
    egg.block("Pupil", (-0.22, yc - 0.22, -z - 0.12), (0.22, yc + 0.22, -z - 0.05), black)
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
