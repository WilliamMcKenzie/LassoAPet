"""Eggs for World 2's Crimson Lands animals, in take C's style (tools/ocean_eggs.py): the octo
shell in the animal's colours, its feature on top or at the crack, no face.

  Eyeworm      crimson with purple rings, a worm tip poking out of the top
  Maw          crimson with purple lips either side of the crack and ivory fangs across it
  IvorySpider  ivory with a bone-grey bottom, four bent bone legs on its shoulders and a
               red hourglass on top

Run from the repo root: python3 tools/crimson_eggs.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/animals/crimson_eggs/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell  # noqa: E402

CRIMSON, PURPLE = (170, 22, 48), (122, 44, 168)
IVORY, BONE, RED = (246, 240, 226), (200, 190, 174), (220, 24, 40)
TOP = N * LH
CRACK = CRACK_LAYER * LH


def eyeworm_egg():
    egg = shell([PURPLE, CRIMSON, PURPLE, CRIMSON, PURPLE, CRIMSON, CRIMSON])
    egg.block("Worm", (-0.3, TOP - 0.1, -0.3), (0.3, TOP + 0.45, 0.3), CRIMSON).bone = "top"
    egg.block("WormRing", (-0.34, TOP + 0.1, -0.34), (0.34, TOP + 0.22, 0.34), PURPLE).bone = "top"
    egg.block("WormTip", (-0.22, TOP + 0.45, -0.22), (0.22, TOP + 0.6, 0.22), PURPLE).bone = "top"
    return egg


def fang(egg, name, x, y_base, y_tip, z0, z1, w=0.24, bone="top"):
    c = [np.array(p, float) for p in ((x - w / 2, y_base, z0), (x + w / 2, y_base, z0), (x + w / 2, y_base, z1), (x - w / 2, y_base, z1))]
    apex = np.array((x, y_tip, (z0 + z1) / 2))
    egg.poly(name, [c] + [[c[i], c[(i + 1) % 4], apex] for i in range(4)], IVORY, bone=bone)


def maw_egg():
    egg = shell([CRIMSON, CRIMSON, CRIMSON, PURPLE, PURPLE, CRIMSON, CRIMSON])
    z0, z1 = -WIDTHS[CRACK_LAYER - 1] / 2 - 0.14, -WIDTHS[CRACK_LAYER - 1] / 2 + 0.02
    for i, x in enumerate((-0.75, -0.25, 0.25, 0.75)):
        fang(egg, f"TopFang{i}", x, CRACK + 0.04, CRACK - 0.34, z0, z1, bone="top")
    for i, x in enumerate((-0.5, 0.0, 0.5)):
        fang(egg, f"BottomFang{i}", x, CRACK - 0.04, CRACK + 0.28, z0, z1, bone="bottom")
    return egg


def ivory_spider_egg():
    egg = shell([BONE, IVORY, IVORY, IVORY, IVORY, IVORY, IVORY])
    y = 5 * LH  # the shoulder ledge
    r = WIDTHS[5] / 2
    for i, (sx, sz) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
        x, z = sx * (r - 0.12), sz * (r - 0.35)
        egg.block(f"Leg{i}", (x - 0.09, y - 0.05, z - 0.09), (x + 0.09, y + 0.55, z + 0.09), BONE).bone = "top"
        egg.block(f"Foot{i}", (min(x, x + sx * 0.4) - 0.09, y + 0.46, z - 0.09), (max(x, x + sx * 0.4) + 0.09, y + 0.64, z + 0.09), BONE).bone = "top"
    egg.block("Hourglass1", (-0.22, TOP - 0.05, -0.32), (0.22, TOP + 0.05, -0.06), RED).bone = "top"
    egg.block("Hourglass2", (-0.22, TOP - 0.05, 0.06), (0.22, TOP + 0.05, 0.32), RED).bone = "top"
    egg.block("Hourglass3", (-0.08, TOP - 0.05, -0.06), (0.08, TOP + 0.05, 0.06), RED).bone = "top"
    return egg


KINDS = [("Eyeworm", eyeworm_egg), ("Maw", maw_egg), ("IvorySpider", ivory_spider_egg)]

if __name__ == "__main__":
    O.EGGS = KINDS
    O.main(*(sys.argv[1:] or [k for k, _ in KINDS]), preview="/mnt/project-files/animals/crimson_eggs")
