"""The Orange Butterfly's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
butterfly's colours (tools/orange_butterfly.py), a brown bottom, bright orange with two sunny
yellow bands, autumn orange at the crown; little wings out of its sides (orange forewings
with autumn tips and a cream spot, yellow hindwings with a brown eye spot) and two antennae
on top with orange tips.

Run from the repo root: python3 tools/orange_butterfly_egg.py
Writes designs/eggs/c_style/OrangeButterflyEgg.bbmodel, src/shared/Eggs/OrangeButterflyEggModel.luau,
assets/ui/OrangeButterflyEggRender.png and previews in /mnt/project-files/animals/orange_butterfly/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from orange_butterfly import COLORS  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402

C = COLORS


def butterfly_egg():
    egg = shell([C["body"], C["stripe"], C["orange"], C["orange"], C["stripe"], C["orange"], C["edge"]])
    # wings out of each side, a little behind the middle: forewing high, hindwing under it
    for side, sx in (("L", -1), ("R", 1)):
        w = WIDTHS[3] / 2 - 0.1

        def blk(name, x0, x1, y0, y1, color, z0=0.05, z1=0.25):
            xa, xb = sorted((sx * x0, sx * x1))
            return egg.block(name + side, (xa, y0, z0), (xb, y1, z1), color)
        blk("WingF", w, w + 0.75, 1.75, 2.75, C["orange"])
        blk("WingFTip", w + 0.75, w + 1.05, 1.95, 2.75, C["edge"])
        blk("WingFSpot", w + 0.6, w + 0.9, 2.3, 2.6, C["spot"], 0.0, 0.3)
        w2 = WIDTHS[2] / 2 - 0.1
        blk("WingB", w2, w2 + 0.65, 0.95, 1.75, C["yellow"])
        blk("WingBSpot", w2 + 0.25, w2 + 0.5, 1.2, 1.45, C["eyespot"], 0.0, 0.3)
    # antennae on top, orange tips
    top = N * LH
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.18, sx * 0.3))
        egg.block("Antenna" + side, (xa, top - 0.05, -0.06), (xb, top + 0.6, 0.06), C["body"]).bone = "top"
        xa, xb = sorted((sx * 0.12, sx * 0.36))
        egg.block("AntennaTip" + side, (xa, top + 0.6, -0.12), (xb, top + 0.84, 0.12), C["orange"]).bone = "top"
    return egg


if __name__ == "__main__":
    O.EGGS = [("OrangeButterfly", butterfly_egg)]
    O.main("OrangeButterfly", preview="/mnt/project-files/animals/orange_butterfly")
