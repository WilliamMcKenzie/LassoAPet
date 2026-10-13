"""The Jade and Garnet Statues' eggs, in take C's style (tools/ocean_eggs.py): the octo
shell in the statue's stone with a darker base, a gold band round the middle (its
collar), a scowl of black eyes with glowing pupils on the front, and its crest on top:
the Jade's gold flame crown, the Garnet's two gold horns sweeping back.

Run from the repo root: python3 tools/temple_statues_egg.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/world2/temple/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from temple_statues import STONES, GOLD, EYE_BLACK  # noqa: E402


def spike(egg, name, cx, cz, y, w, h, color=GOLD, axis=(0, 1, 0)):
    lo, hi = (cx - w / 2, cz - w / 2), (cx + w / 2, cz + w / 2)
    c = [np.array(p, float) for p in ((lo[0], y, lo[1]), (hi[0], y, lo[1]), (hi[0], y, hi[1]), (lo[0], y, hi[1]))]
    apex = np.array((cx, y, cz)) + np.array(axis, float) * h
    faces = [c] + [[c[i], c[(i + 1) % 4], apex] for i in range(4)]
    return egg.poly(name, faces, color, bone="top")


def statue_egg(stone):
    s = STONES[stone]
    egg = shell([s["dark"], s["main"], s["main"], GOLD, s["main"], s["main"], s["light"]])
    # eyes on the front of the layer above the band, glowing pupils
    layer = 4
    z = -WIDTHS[layer] / 2
    y0, y1 = layer * LH + 0.08, layer * LH + LH - 0.06
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.15, sx * 0.75))
        egg.block("Eye" + side, (xa, y0, z - 0.05), (xb, y1, z + 0.02), EYE_BLACK)
        pa, pb = sorted((sx * 0.3, sx * 0.6))
        egg.block("GlowPupil" + side, (pa, y0 + 0.06, z - 0.08), (pb, y1 - 0.12, z - 0.03), s["glow"])
    top = N * LH
    if s["crest"] == "crown":
        for i, (x, h) in enumerate(((-0.34, 0.5), (0, 0.8), (0.34, 0.5))):
            spike(egg, f"Crown{i + 1}", x, 0, top - 0.05, 0.32, h)
    else:
        for side, sx in (("L", -1), ("R", 1)):
            egg.block("Horn" + side, (sx * 0.3 - 0.13, top - 0.05, -0.2), (sx * 0.3 + 0.13, top + 0.35, 0.1), GOLD)
            spike(egg, "HornTip" + side, sx * 0.3, -0.05, top + 0.2, 0.26, 0.55, axis=(0, 0.45, 0.9))
    return egg


if __name__ == "__main__":
    O.EGGS = [("JadeStatue", lambda: statue_egg("Jade")), ("GarnetStatue", lambda: statue_egg("Garnet"))]
    O.main(*sys.argv[1:], preview="/mnt/project-files/world2/temple")
