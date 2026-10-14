"""The Fox's and Nine-tailed Fox's eggs, in take C's style (tools/ocean_eggs.py): the octo
shell in each fox's colours (tools/temple_fox.py), a black base for the stockings and a white
band for the chest, pointed ears with dark tips on top and the shrine bib on the front.
The Fox has one bushy white-tipped tail up its back; the Nine-tailed Fox has nine small
ones fanned out on its back (turned boxes, about Z) and a gold bell under its bib.

Run from the repo root: python3 tools/temple_fox_egg.py
Writes designs/eggs/c_style/{Fox,NineTailedFox}Egg.bbmodel, src/shared/Eggs/*EggModel.luau,
assets/ui/*EggRender.png and previews in /mnt/project-files/world2/temple/eggs/.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import ear_half  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from temple_fox import BLACK, CREAM, FOX, GOLD_BELL, NINE, WHITE  # noqa: E402


def turned_box(egg, name, origin, lo, hi, deg, color):
    """A box given straight up from origin, turned deg about Z round it."""
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    ox, oy, oz = origin

    def at(x, y, z):
        return (ox + c * x - s * y, oy + s * x + c * y, oz + z)
    (x0, y0, z0), (x1, y1, z1) = lo, hi
    v = {(i, j, k): at((x0, x1)[i], (y0, y1)[j], (z0, z1)[k]) for i in (0, 1) for j in (0, 1) for k in (0, 1)}
    quads = [[(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)], [(0, 0, 1), (0, 1, 1), (0, 1, 0), (0, 0, 0)],
             [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)], [(0, 0, 1), (0, 0, 0), (1, 0, 0), (1, 0, 1)],
             [(1, 0, 1), (1, 1, 1), (0, 1, 1), (0, 0, 1)], [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]]
    return egg.poly(name, [[v[q] for q in quad] for quad in quads], color)


def fox_egg(v):
    coat = v["coat"]
    egg = shell([BLACK, WHITE, WHITE, coat, coat, coat, coat])
    # pointed ears on top, cream insides and dark tips (a hair bigger, so no shared faces)
    top = N * LH
    base, hw, h = top - 0.45, 0.36, 1.15
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * 0.5
        for half, d in (("A", -1), ("B", 1)):
            ear_half(egg, f"Ear{side}{half}", [(x0, base), (x0 + d * hw, base), (x0, base + h)], -0.2, 0.2, coat)
            ear_half(egg, f"EarTip{side}{half}", [(x0, base + 0.72), (x0 + d * (hw * 0.4 + 0.03), base + 0.72), (x0, base + h + 0.03)],
                     -0.22, 0.22, v["tip"])
            ear_half(egg, f"EarIn{side}{half}", [(x0, base + 0.5), (x0 + d * hw * 0.5, base + 0.5), (x0, base + 0.95)], -0.25, -0.2, CREAM)
    # shrine bib on the front, pointing down over the white band
    zf = -WIDTHS[3] / 2
    yb = 3 * LH + 0.25
    for half, d in (("A", -1), ("B", 1)):
        ear_half(egg, f"Bib{half}", [(0, yb), (d * 0.42, yb), (0, yb - 0.75)], zf - 0.08, zf + 0.06, v["bib"])
    if v is NINE:
        egg.block("Bell", (-0.13, yb - 0.95, zf - 0.3), (0.13, yb - 0.7, zf - 0.04), GOLD_BELL)
        # nine small tails fanned out on the back, each a little further out than the one inside it
        zb = WIDTHS[2] / 2
        for i in range(9):
            k = i - 4
            o = (0, 2.4 * LH, zb + 0.05 + 0.04 * abs(k) + 0.02 * (k > 0))
            L = 1.55 - 0.07 * abs(k)
            turned_box(egg, f"Tail{i + 1}", o, (-0.15, 0, -0.1), (0.15, L - 0.35, 0.1), -18 * k, coat)
            turned_box(egg, f"Tail{i + 1}Tip", o, (-0.12, L - 0.35, -0.08), (0.12, L, 0.08), -18 * k, WHITE)
    else:
        # one bushy tail up the back to a white tip
        z = WIDTHS[2] / 2
        y = 1 * LH + 0.1
        egg.block("Tail", (-0.15, y, z - 0.05), (0.15, y + 0.3, z + 0.3), coat)
        egg.block("TailBush", (-0.28, y + 0.3, z + 0.02), (0.28, y + 1.0, z + 0.5), coat)
        egg.block("TailTip", (-0.2, y + 1.0, z + 0.08), (0.2, y + 1.35, z + 0.44), WHITE)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Fox", lambda: fox_egg(FOX)), ("NineTailedFox", lambda: fox_egg(NINE))]
    O.main(preview="/mnt/project-files/world2/temple/eggs")
