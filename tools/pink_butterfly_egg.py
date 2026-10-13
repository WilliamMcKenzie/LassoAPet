"""The Pink Butterfly's egg, in take C's style (tools/ocean_eggs.py): the octo shell with a plum
base (its body), bubblegum and pale pink bands and a hot-pink crown, little stepped wings out
each side (pale by the shell, hot pink at the tips: forewings above the crack, hindwings below)
and two antennae on top with bubblegum tips.

Run from the repo root: python3 tools/pink_butterfly_egg.py
Writes designs/eggs/c_style/PinkButterflyEgg.bbmodel, src/shared/Eggs/PinkButterflyEggModel.luau,
assets/ui/PinkButterflyEggRender.png and previews in /mnt/project-files/animals/pink_butterfly/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from pink_butterfly import COLORS  # noqa: E402

C = COLORS


def pink_butterfly_egg():
    egg = shell([C["body"], C["body"], C["pink"], C["pale"], C["pink"], C["pink"], C["hot"]])
    # wings: (layer, height, inner reach, tip reach)
    for wing, layer, y0, y1, reach in (("Fore", 4, 1.85, 3.0, 1.3), ("Hind", 2, 0.85, 1.7, 1.0)):
        r = WIDTHS[layer] / 2
        for s, n in ((-1, "L"), (1, "R")):
            xa, xb, xc = r - 0.1, r + reach * 0.55, r + reach
            lo = lambda a, b: (min(s * a, s * b), y0, 0.05)  # noqa: E731
            hi = lambda a, b: (max(s * a, s * b), y1, 0.2)  # noqa: E731
            egg.block(f"Wing{wing}{n}", lo(xa, xb), hi(xa, xb), C["pink"])
            egg.block(f"Wing{wing}Spot{n}", (min(s * (xb - 0.35), s * (xb - 0.05)), (y0 + y1) / 2 - 0.15, 0.0), (max(s * (xb - 0.35), s * (xb - 0.05)), (y0 + y1) / 2 + 0.15, 0.25), C["white"])
            egg.block(f"Wing{wing}Tip{n}", (min(s * xb, s * xc), y0 + 0.1, 0.05), (max(s * xb, s * xc), y1 - 0.1, 0.2), C["hot"])
    top = N * LH
    for s, n in ((-1, "L"), (1, "R")):
        x = s * 0.35
        egg.block(f"Antenna{n}", (x - 0.06, top - 0.05, -0.06), (x + 0.06, top + 0.6, 0.06), C["body"]).bone = "top"
        egg.block(f"AntennaTip{n}", (x - 0.15, top + 0.6, -0.15), (x + 0.15, top + 0.9, 0.15), C["stripe"]).bone = "top"
    return egg


if __name__ == "__main__":
    O.EGGS = [("PinkButterfly", pink_butterfly_egg)]
    O.main("PinkButterfly", preview="/mnt/project-files/animals/pink_butterfly")
