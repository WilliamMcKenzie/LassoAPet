"""The Living Crystals' eggs, in take C's style (tools/ocean_eggs.py): the octo shell in the
crystal's colour with a lighter facet band and a darker bottom (its legs), the Cactus's
face colour band at the crack, and a crystal (cube shaft + pyramid tip) on top.

Run from the repo root: python3 tools/living_crystal_egg.py
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/animals/living_crystal/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, shell  # noqa: E402
from crystal_centipede_egg import crystal  # noqa: E402
from living_crystal import KINDS  # noqa: E402


def crystal_egg(kind):
    main, light, dark = KINDS[kind]

    def make():
        egg = shell([dark, main, main, light, main, main, main])
        top = N * LH
        crystal(egg, "Crystal1", 0, 0, top - 0.1, 0.55, 0.7, 0.5, light)
        return egg
    return make


if __name__ == "__main__":
    O.EGGS = [(k, crystal_egg(k)) for k in KINDS]
    O.main(*KINDS, preview="/mnt/project-files/animals/living_crystal")
