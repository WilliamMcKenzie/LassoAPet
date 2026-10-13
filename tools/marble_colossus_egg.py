"""The Marble Colossus's egg, in take C's style (tools/ocean_eggs.py): the octo shell in
the Colossus's marble with a grey-shaded bottom, a gold band round its middle (its
bracers) and gold pyramid spikes on top and round the ledge below it (its shoulder spikes).

Run from the repo root: python3 tools/marble_colossus_egg.py
Writes designs/eggs/c_style/MarbleColossusEgg.bbmodel, src/shared/Eggs/MarbleColossusEggModel.luau,
assets/ui/MarbleColossusEggRender.png and previews in /mnt/project-files/animals/marble_colossus/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, shell  # noqa: E402
from marble_colossus import MARBLE, SHADE, GOLD  # noqa: E402


def spike(egg, name, cx, cz, y, w, h):
    lo, hi = (cx - w / 2, y, cz - w / 2), (cx + w / 2, y, cz + w / 2)
    c = [np.array(p, float) for p in ((lo[0], y, lo[2]), (hi[0], y, lo[2]), (hi[0], y, hi[2]), (lo[0], y, hi[2]))]
    apex = np.array((cx, y + h, cz))
    faces = [c] + [[c[i], c[(i + 1) % 4], apex] for i in range(4)]
    return egg.poly(name, faces, GOLD, bone="top")


def marble_colossus_egg():
    egg = shell([SHADE, MARBLE, MARBLE, GOLD, MARBLE, MARBLE, MARBLE])
    top = N * LH
    spike(egg, "Spike1", 0, 0, top - 0.05, 0.6, 0.9)
    # four smaller ones round the ledge below the top layer
    for i, (x, z) in enumerate(((-0.68, 0), (0.68, 0), (0, -0.68), (0, 0.68))):
        spike(egg, f"Spike{i + 2}", x, z, top - LH - 0.02, 0.4, 0.6)
    return egg


if __name__ == "__main__":
    O.EGGS = [("MarbleColossus", marble_colossus_egg)]
    O.main("MarbleColossus", preview="/mnt/project-files/animals/marble_colossus")
