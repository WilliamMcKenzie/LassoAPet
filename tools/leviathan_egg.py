"""The Leviathan's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
Leviathan's aqua (tools/leviathan_design.py) over a white base, three red feathery gill
stalks fanning out from each side near the top (its axolotl gills), a pale ridge down
the back, and a ring of ivory fangs round the middle pointing down.

Run from the repo root: python3 tools/leviathan_egg.py
Writes designs/eggs/c_style/LeviathanEgg.bbmodel, src/shared/Eggs/LeviathanEggModel.luau,
assets/ui/LeviathanEggRender.png and previews in /mnt/project-files/animals/leviathan/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from leviathan_design import COLORS  # noqa: E402
from horse_egg_takes import LH, WIDTHS, shell  # noqa: E402
from partlib import Part, T, Ry  # noqa: E402


def turned(egg, name, lo, hi, col, yaw):
    mid = [(a + b) / 2 for a, b in zip(lo, hi)]
    p = Part(name, [b - a for a, b in zip(lo, hi)], Ry(yaw) @ T(*mid), col)
    p.bone = "top" if mid[1] > 4 * LH else "bottom"
    p.yaw = yaw
    egg.parts.append(p)


def leviathan_egg():
    aqua, pale, belly = COLORS["aqua"], COLORS["pale"], COLORS["belly"]
    gill, gilldark, ivory = COLORS["gill"], COLORS["gilldark"], COLORS["ivory"]
    egg = shell([belly, belly, aqua, aqua, aqua, aqua, aqua])
    # gills: three stalks out of each side of layer 5, fanning up, level and down
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * WIDTHS[5] / 2
        for k, dy in enumerate((0.32, 0.0, -0.32)):
            y = 5 * LH + LH / 2 + dy
            L = 0.85 if k == 1 else 0.7
            xa, xb = sorted((x0 - sx * 0.05, x0 + sx * L))
            egg.block(f"Gill{side}{k}", (xa, y - 0.1, -0.1), (xb, y + 0.1, 0.1), gill)
            xt = x0 + sx * (L + 0.06)
            egg.block(f"GillTip{side}{k}", (min(xt, xt - sx * 0.14), y - 0.1, -0.1), (max(xt, xt - sx * 0.14), y + 0.1, 0.1), gilldark)
    # a pale ridge down the back
    for layer in (3, 4, 5):
        z = WIDTHS[layer] / 2
        egg.block(f"Ridge{layer}", (-0.15, layer * LH + 0.06, z - 0.05), (0.15, (layer + 1) * LH - 0.06, z + 0.1), pale)
    egg.block("RidgeTop", (-0.15, 7 * LH - 0.02, -0.2), (0.15, 7 * LH + 0.12, 0.2), pale)
    # a ring of ivory fangs round the middle (top of layer 2), pointing down, for its jaw
    for k in range(8):
        yaw = 22.5 + 45 * k
        r = WIDTHS[2] / 2
        turned(egg, f"Fang{k}", (-0.14, 2 * LH + 0.1, -r - 0.1), (0.14, 3 * LH - 0.02, -r + 0.04), ivory, yaw)
        turned(egg, f"FangTip{k}", (-0.07, 2 * LH - 0.2, -r - 0.08), (0.07, 2 * LH + 0.1, -r + 0.02), ivory, yaw)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Leviathan", leviathan_egg)]
    O.main("Leviathan", preview="/mnt/project-files/animals/leviathan")
