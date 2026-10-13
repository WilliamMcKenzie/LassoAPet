"""The Crystal Centipede's egg, in take C's style (tools/ocean_eggs.py): the octo shell in
the centipede's purple with dark leg-coloured bands, a cyan crystal (cube shaft + pyramid
tip) standing on top and two smaller pink ones on the ledge below it.

Run from the repo root: python3 tools/crystal_centipede_egg.py
Writes designs/eggs/c_style/CrystalCentipedeEgg.bbmodel, src/shared/Eggs/CrystalCentipedeEggModel.luau,
assets/ui/CrystalCentipedeEggRender.png and previews in /mnt/project-files/animals/crystal_centipede/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, shell  # noqa: E402

BODY, LEG = (124, 72, 200), (72, 44, 124)
CYAN, PINK = (0, 190, 231), (229, 131, 251)


def crystal(egg, name, cx, cz, y, w, h, tip, color):
    egg.block(name, (cx - w / 2, y, cz - w / 2), (cx + w / 2, y + h, cz + w / 2), color).bone = "top"
    t = y + h
    c = [np.array(p, float) for p in ((cx - w / 2, t, cz - w / 2), (cx + w / 2, t, cz - w / 2),
                                      (cx + w / 2, t, cz + w / 2), (cx - w / 2, t, cz + w / 2))]
    apex = np.array((cx, t + tip, cz))
    egg.poly(name + "Tip", [c] + [[c[i], c[(i + 1) % 4], apex] for i in range(4)], color, bone="top")


def crystal_centipede_egg():
    egg = shell([LEG, BODY, BODY, LEG, BODY, BODY, BODY])
    top = N * LH
    crystal(egg, "Crystal1", 0, 0, top - 0.1, 0.5, 0.6, 0.45, CYAN)
    crystal(egg, "Crystal2", -0.68, 0.1, top - LH - 0.05, 0.36, 0.45, 0.32, PINK)
    crystal(egg, "Crystal3", 0.68, -0.1, top - LH - 0.05, 0.36, 0.35, 0.3, PINK)
    return egg


if __name__ == "__main__":
    O.EGGS = [("CrystalCentipede", crystal_centipede_egg)]
    O.main("CrystalCentipede", preview="/mnt/project-files/animals/crystal_centipede")
