"""The Firebird's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
Firebird's orange with dark grey feather bands, and its black crest as two spikes on top.

Run from the repo root: python3 tools/firebird_egg.py
Writes designs/eggs/c_style/FirebirdEgg.bbmodel, src/shared/Eggs/FirebirdEggModel.luau,
assets/ui/FirebirdEggRender.png and previews in /mnt/project-files/animals/firebird/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import ears, shell  # noqa: E402
from firebird_design import BLACK, GREY, ORANGE, ORANGE_DARK  # noqa: E402


def firebird_egg():
    egg = shell([ORANGE_DARK, ORANGE_DARK, ORANGE, GREY, ORANGE, GREY, ORANGE])
    ears(egg, BLACK, None, x=0.3, hw=0.3, h=1.0)  # the crest
    return egg


if __name__ == "__main__":
    O.EGGS = [("Firebird", firebird_egg)]
    O.main("Firebird", preview="/mnt/project-files/animals/firebird")
