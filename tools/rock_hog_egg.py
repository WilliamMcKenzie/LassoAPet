"""The Rock Hog's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the Rock
Hog's Basalt colours (slate coat, a navy band, dark hoof base) with its two fiery horns
on top, stepping out and up from dark red to a yellow tip (Glow parts are Neon in game).

Run from the repo root: python3 tools/rock_hog_egg.py
Writes designs/eggs/c_style/RockHogEgg.bbmodel, src/shared/Eggs/RockHogEggModel.luau,
assets/ui/RockHogEggRender.png and previews in /mnt/project-files/animals/rockhog/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import ear_half  # noqa: E402
from horse_egg_takes import H, shell  # noqa: E402
from rock_hog import SCHEMES  # noqa: E402

S = SCHEMES["Basalt"]


def rock_hog_egg():
    egg = shell([S["hooves"], S["coat"], S["coat"], S["mane"], S["coat"], S["coat"], S["coat"]])
    for side, sx in (("L", -1), ("R", 1)):
        y = H - 0.1
        for i, (x, hw, h) in enumerate(((0.28, 0.2, 0.24), (0.36, 0.17, 0.24), (0.44, 0.13, 0.24))):
            egg.block(f"GlowHorn{side}{i}", (sx * x - hw, y, -hw), (sx * x + hw, y + h, hw), S["horn"][i])
            y += h
        x, hw = 0.44 * sx, 0.13
        for half, d in (("A", -1), ("B", 1)):
            ear_half(egg, f"GlowHornTip{side}{half}", [(x, y), (x + d * hw, y), (x, y + 0.45)], -hw, hw, S["horn"][3])
    return egg


if __name__ == "__main__":
    O.EGGS = [("RockHog", rock_hog_egg)]
    O.main("RockHog", preview="/mnt/project-files/animals/rockhog")
