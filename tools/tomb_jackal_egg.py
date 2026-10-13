"""The Tomb Jackal's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
jackal's indigo-black (tools/tomb_jackal.py) over a black base, a gold usekh collar band
with a turquoise gem and gold drops on the front, gold and lapis nemes stripes down both
sides, a turquoise scarab with gold wings on the brow, very tall pointed ears with gold
insides and gold cuffs on top, and a gold ankh on the back.

Run from the repo root: python3 tools/tomb_jackal_egg.py
Writes designs/eggs/c_style/TombJackalEgg.bbmodel, src/shared/Eggs/TombJackalEggModel.luau,
assets/ui/TombJackalEggRender.png and previews in /mnt/project-files/world2/tomb/eggs/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import ear_half  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from tomb_jackal import FUR, GOLD, GOLD_DARK, LAPIS, PAW, TURQ  # noqa: E402


def jackal_egg():
    egg = shell([PAW, FUR, GOLD, FUR, FUR, FUR, FUR])
    # very tall pointed ears on top, gold insides and a gold cuff round each base
    top = N * LH
    base, hw, h = top - 0.45, 0.34, 1.55
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * 0.45
        for half, d in (("A", -1), ("B", 1)):
            ear_half(egg, f"Ear{side}{half}", [(x0, base), (x0 + d * hw, base), (x0, base + h)], -0.2, 0.2, FUR)
            ear_half(egg, f"EarIn{side}{half}", [(x0, base + 0.5), (x0 + d * hw * 0.55, base + 0.5), (x0, base + 1.25)], -0.25, -0.2, GOLD)
        egg.block(f"EarCuff{side}", (x0 - 0.38, base + 0.3, -0.24), (x0 + 0.38, base + 0.48, 0.24), GOLD)

    # usekh: a turquoise gem on the gold band's front and gold drops hanging below it
    zf = -WIDTHS[2] / 2
    y2 = 2 * LH
    egg.block("CollarGem", (-0.17, y2 + 0.1, zf - 0.08), (0.17, y2 + LH - 0.1, zf + 0.05), TURQ)
    zd = -WIDTHS[1] / 2
    for i, x in enumerate((-0.6, -0.3, 0.0, 0.3, 0.6)):
        drop = 0.32 if x else 0.42
        egg.block(f"Drop{i + 1}", (x - 0.08, y2 - drop, zd - 0.08), (x + 0.08, y2 + 0.02, zd + 0.05), GOLD_DARK)

    # nemes stripes down both sides, gold and lapis, two to a layer
    for layer in (3, 4, 5):
        w = WIDTHS[layer] / 2
        for k, c in enumerate((GOLD, LAPIS)):
            ya = layer * LH + k * LH / 2
            for side, sx in (("L", -1), ("R", 1)):
                xa, xb = sorted((sx * (w - 0.05), sx * (w + 0.06)))
                egg.block(f"Nemes{side}{layer}{k}", (xa, ya, -w * 0.35), (xb, ya + LH / 2, w * 0.7), c)

    # a turquoise scarab with gold wings on the brow
    zs = -WIDTHS[5] / 2
    y5 = 5 * LH
    egg.block("ScarabBody", (-0.14, y5 + 0.06, zs - 0.08), (0.14, y5 + 0.36, zs + 0.05), TURQ)
    egg.block("ScarabHead", (-0.08, y5 + 0.36, zs - 0.06), (0.08, y5 + 0.46, zs + 0.05), TURQ)
    egg.block("ScarabWingL", (-0.42, y5 + 0.14, zs - 0.06), (-0.14, y5 + 0.3, zs + 0.05), GOLD)
    egg.block("ScarabWingR", (0.14, y5 + 0.14, zs - 0.06), (0.42, y5 + 0.3, zs + 0.05), GOLD)

    # a gold ankh on the back: stem, crossbar and a loop
    zb = WIDTHS[3] / 2
    y3 = 3 * LH
    for name, lo, hi in (("AnkhStem", (-0.06, y3 + 0.02, 0), (0.06, y3 + 0.26, 0)),
                         ("AnkhBar", (-0.22, y3 + 0.2, 0), (0.22, y3 + 0.28, 0)),
                         ("AnkhLoopL", (-0.14, y3 + 0.28, 0), (-0.06, y3 + 0.44, 0)),
                         ("AnkhLoopR", (0.06, y3 + 0.28, 0), (0.14, y3 + 0.44, 0)),
                         ("AnkhLoopT", (-0.14, y3 + 0.44, 0), (0.14, y3 + 0.52, 0))):
        egg.block(name, (lo[0], lo[1], zb - 0.05), (hi[0], hi[1], zb + 0.07), GOLD)
    return egg


if __name__ == "__main__":
    O.EGGS = [("TombJackal", jackal_egg)]
    O.main(preview="/mnt/project-files/world2/tomb/eggs")
