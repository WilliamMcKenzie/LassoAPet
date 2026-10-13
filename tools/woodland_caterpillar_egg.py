"""The Caterpillar's egg, in take C's style (tools/ocean_eggs.py): the octo shell in bands of
the caterpillar's green and lime with a pale belly band at the bottom, and its two dark
green antennae with orange tips standing on top.

Run from the repo root: python3 tools/woodland_caterpillar_egg.py
Writes designs/eggs/c_style/CaterpillarEgg.bbmodel, src/shared/Eggs/CaterpillarEggModel.luau,
assets/ui/CaterpillarEggRender.png and previews in /mnt/project-files/world2/woodland/caterpillar/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, shell  # noqa: E402

GREEN, LIME, BELLY = (112, 206, 58), (156, 226, 70), (196, 232, 96)
STALK, ORANGE = (46, 122, 44), (242, 109, 57)


def caterpillar_egg():
    egg = shell([BELLY, GREEN, LIME, GREEN, LIME, GREEN, LIME])
    top = N * LH
    for s in (-1, 1):
        x = s * 0.32
        egg.block(f"Antenna{s}", (x - 0.09, top - 0.1, -0.09), (x + 0.09, top + 0.6, 0.09), STALK).bone = "top"
        egg.block(f"AntennaTip{s}", (x - 0.18, top + 0.55, -0.18), (x + 0.18, top + 0.91, 0.18), ORANGE).bone = "top"
    return egg


if __name__ == "__main__":
    O.EGGS = [("Caterpillar", caterpillar_egg)]
    O.main("Caterpillar", preview="/mnt/project-files/world2/woodland/caterpillar")
