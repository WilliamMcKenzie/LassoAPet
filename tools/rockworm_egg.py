"""The Rockworm's egg, in take C's style (tools/ocean_eggs.py): the Sandworm egg's banded
shell in the Rockworm's basalt (light belly base, slate and navy bands), its two lava
fangs bursting out of the top, and glowing lava fins down its back (Glow* = Neon).

Run from the repo root: python3 tools/rockworm_egg.py
Writes designs/eggs/c_style/RockwormEgg.bbmodel, src/shared/Eggs/RockwormEggModel.luau,
assets/ui/RockwormEggRender.png and previews in /mnt/project-files/animals/rockworm/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from desert_eggs import fin  # noqa: E402
from egg_designs import ear_half  # noqa: E402
from horse_egg_takes import H, LH, shell  # noqa: E402
from rockworm import COLORS  # noqa: E402

BELLY, COAT, PLATE, LAVA = COLORS["belly"], COLORS["sand"], COLORS["plate"], COLORS["lava"]


def rockworm_egg():
    egg = shell([BELLY, COAT, PLATE, COAT, PLATE, COAT, PLATE])
    # two fangs out of the top, hooked forward like QM's
    t = H - 0.1
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.18, sx * 0.48))
        egg.block(f"Fang{side}", (x0, t - 0.2, -0.45), (x1, t + 0.45, -0.1), LAVA).bone = "top"
        xc = sx * 0.33
        for half, d in (("A", -1), ("B", 1)):
            ear_half(egg, f"FangTip{side}{half}", [(xc, t + 0.45), (xc + d * 0.15, t + 0.45), (xc, t + 0.85)], -0.45, -0.1, LAVA)
    # glowing lava fins down the back
    for i in (1, 3, 5):
        fin(egg, f"GlowFin{i}", i * LH + 0.05, (i + 1) * LH + 0.25, 0.45, 0.16, LAVA)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Rockworm", rockworm_egg)]
    O.main("Rockworm", preview="/mnt/project-files/animals/rockworm")
