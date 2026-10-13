"""The Living Mushrooms' eggs, in take C's style (tools/ocean_eggs.py): the octo shell's
bottom in the mushroom's cream body, the top three layers in its cap colour, and for the
spotted ones (purple and red) raised white spots on the top layers.

Run from the repo root: python3 tools/living_mushroom_egg.py
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/animals/living_mushroom/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from living_mushroom import KINDS, STEM, STEM_DARK, SPOT, darker  # noqa: E402


def mushroom_egg(kind):
    _size, cap, spots, _k = KINDS[kind]

    def make():
        egg = shell([STEM_DARK, STEM, STEM, darker(cap), cap, cap, cap])
        if spots:
            # small raised spots on the top three layers' faces and crown
            for i, (layer, x, z) in enumerate(((4, -1, 0), (4, 0, 1), (5, 1, 0), (5, 0, -1), (6, 0.3, 0.3))):
                y0 = layer * LH + LH * 0.25
                r = WIDTHS[layer] / 2
                if layer == 6:
                    top = N * LH
                    egg.block(f"Spot{i + 1}", (-0.2 + x * 0.3, top - 0.02, -0.2 + z * 0.3), (0.2 + x * 0.3, top + 0.06, 0.2 + z * 0.3), SPOT).bone = "top"
                    continue
                lo = [x * r - 0.2 if x else -0.2, y0, z * r - 0.2 if z else -0.2]
                hi = [x * r + 0.2 if x else 0.2, y0 + LH * 0.5, z * r + 0.2 if z else 0.2]
                if x:
                    lo[0], hi[0] = sorted((x * r - 0.04 * x, x * r + 0.06 * x))
                if z:
                    lo[2], hi[2] = sorted((z * r - 0.04 * z, z * r + 0.06 * z))
                egg.block(f"Spot{i + 1}", lo, hi, SPOT).bone = "top"
        return egg
    return make


if __name__ == "__main__":
    O.EGGS = [(k, mushroom_egg(k)) for k in KINDS]
    O.main(*KINDS, preview="/mnt/project-files/animals/living_mushroom")
