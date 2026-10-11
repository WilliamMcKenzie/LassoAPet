"""The Firebird's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
Firebird's orange with dark grey feather bands, and its black crest as two spikes on top.

Run from the repo root: python3 tools/firebird_egg.py (generated design; `qm` renders QM's edit)
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


def generated():
    O.EGGS = [("Firebird", firebird_egg)]
    O.main("Firebird", preview="/mnt/project-files/animals/firebird")


def qm_render():
    """QM's hand-edited egg (designs/eggs/c_style/FirebirdEgg.bbmodel, three-spike crest) is
    the game's now: convert it with `bbmodel_to_luau.py designs/eggs/c_style/FirebirdEgg.bbmodel
    src/shared/Eggs/FirebirdEggModel.luau`, then this writes its UI picture.
    Run: python3 tools/firebird_egg.py qm"""
    import json
    from horse_egg_takes import VIEWS
    from partlib import render
    from snow_rig import posed
    m = json.load(open(os.path.join(O.ROOT, "designs", "eggs", "c_style", "FirebirdEgg.bbmodel")))
    im = render(posed(m, None, 0), W=1100, H=1100, fov=28, transparent=True, **VIEWS[0])
    im = im.crop(im.getbbox())
    im.save(os.path.join(O.ROOT, "assets", "ui", "FirebirdEggRender.png"))
    im.save("/mnt/project-files/animals/firebird/FirebirdEgg_QM.png")
    print("render", im.size)


if __name__ == "__main__":
    qm_render() if sys.argv[1:2] == ["qm"] else generated()
