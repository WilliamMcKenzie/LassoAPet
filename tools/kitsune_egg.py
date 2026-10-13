"""The Kitsune's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the fox's
white over a red base, tied round the middle with a straw shrine rope and a gold bell on
the front. Red markings flare up the front, tall fox ears with red insides stand on the
cap with a glowing wish jewel on a gold mount between them, and five little tails fan up
from the back, each tipped with a blue spirit flame.

Run from the repo root: python3 tools/kitsune_egg.py
Writes designs/eggs/c_style/KitsuneEgg.bbmodel, src/shared/Eggs/KitsuneEggModel.luau,
assets/ui/KitsuneEggRender.png and previews in /mnt/project-files/world2/temple/kitsune/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, front_plate, shell, ears  # noqa: E402
from crystal_elephant_egg import axes, point  # noqa: E402
from kitsune import WHITE, RED, GOLD, STRAW, SPIRIT, JEWEL  # noqa: E402


def kitsune_egg():
    egg = shell([RED, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE])
    top = N * LH

    # straw shrine rope round the middle, a gold bell hanging from it
    octo_layer(egg, "Rope", 3 * LH - 0.07, 3 * LH + 0.07, WIDTHS[2] + 0.1, STRAW, "bottom")
    zf = -WIDTHS[2] / 2
    egg.block("Bell", (-0.2, 3 * LH - 0.5, zf - 0.32), (0.2, 3 * LH - 0.07, zf - 0.02), GOLD)
    egg.block("BellKnob", (-0.08, 3 * LH - 0.07, zf - 0.24), (0.08, 3 * LH + 0.02, zf - 0.1), GOLD)

    # red markings flaring up the front of the cap, a red flame on the brow
    for s in (-1, 1):
        xa, xb = sorted((s * 0.15, s * 0.5))
        front_plate(egg, "Mark" + "LR"[s > 0], xa, xb, 4.6 * LH, 4.8 * LH, RED, depth=0.05, plain=False)
        xa, xb = sorted((s * 0.42, s * 0.6))
        front_plate(egg, "Flare" + "LR"[s > 0], xa, xb, 4.8 * LH, 5.3 * LH, RED, depth=0.05, plain=False)
    front_plate(egg, "BrowFlame", -0.07, 0.07, 5.0 * LH, 5.6 * LH, RED, depth=0.05, plain=False)

    # tall fox ears, the wish jewel between them on a gold mount
    ears(egg, WHITE, RED, x=0.42, hw=0.3, h=1.0, base=top - 0.05)
    egg.block("JewelMount", (-0.14, top - 0.05, -0.14), (0.14, top + 0.08, 0.14), GOLD).bone = "top"
    egg.block("GlowJewel", (-0.11, top + 0.08, -0.11), (0.11, top + 0.3, 0.11), JEWEL).bone = "top"
    point(egg, "GlowJewelFlame", (0, top + 0.3, 0), (0, 1, 0), 0.08, 0.3, SPIRIT, "top")

    # five tails fanned up from the back, blue flame tips
    for k, ang in enumerate((-60, -30, 0, 30, 60)):
        a = np.radians(ang)
        d = np.array([np.sin(a) * 0.8, 1.3, 0.55])
        base = np.array([np.sin(a) * 0.25, 4.3 * LH, WIDTHS[4] / 2 - 0.12])
        length = 0.75 if k % 2 else 0.95
        dd, u, v = axes(d)
        hw = 0.14
        ring = lambda c: [c + (sa * u + sb * v) * hw for sa, sb in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        lo, hi = ring(base), ring(base + dd * length)
        egg.poly(f"Tail{k + 1}", [lo[::-1], hi] + [[lo[i], lo[(i + 1) % 4], hi[(i + 1) % 4], hi[i]] for i in range(4)],
                 WHITE, bone="top")
        point(egg, f"GlowFlame{k + 1}", base + dd * length, d, hw, 0.38, SPIRIT, "top")
    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.plain = True
            p.neon = True
    return egg


if __name__ == "__main__":
    O.EGGS = [("Kitsune", kitsune_egg)]
    O.main("Kitsune", preview="/mnt/project-files/world2/temple/kitsune")
