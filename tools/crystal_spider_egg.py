"""The Crystal Spider's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
spider's periwinkle blue with dark leg-coloured bands, three crystals on top like its
abdomen's (a big cyan one between a pink and a smaller cyan).

Run from the repo root: python3 tools/crystal_spider_egg.py
Writes designs/eggs/c_style/CrystalSpiderEgg.bbmodel, src/shared/Eggs/CrystalSpiderEggModel.luau,
assets/ui/CrystalSpiderEggRender.png and previews in /mnt/project-files/animals/crystal_spider/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, shell  # noqa: E402
from crystal_centipede_egg import crystal  # noqa: E402
from crystal_spider import COLORS  # noqa: E402

BODY, DARK, CYAN, PINK = COLORS["body"], COLORS["dark"], COLORS["cyan"], COLORS["pink"]


def crystal_spider_egg():
    egg = shell([DARK, BODY, DARK, BODY, BODY, DARK, BODY])
    top = N * LH
    crystal(egg, "Crystal1", 0, 0, top - 0.1, 0.5, 0.65, 0.45, CYAN)
    crystal(egg, "Crystal2", -0.68, 0.1, top - LH - 0.05, 0.36, 0.45, 0.32, PINK)
    crystal(egg, "Crystal3", 0.68, -0.1, top - LH - 0.05, 0.32, 0.35, 0.28, CYAN)
    return egg


if __name__ == "__main__":
    O.EGGS = [("CrystalSpider", crystal_spider_egg)]
    O.main("CrystalSpider", preview="/mnt/project-files/animals/crystal_spider")
