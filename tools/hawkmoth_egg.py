"""The Hawkmoth's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the moth's
dark charcoal with two autumn-orange rings like its abdomen, its cream skull on the front
(black sockets, nose and teeth), two glowing orange eyes above it under a black brow, sharp dark wings swept
back on both sides with pyramid points, and two horn antennae on top with orange tips.

Run from the repo root: python3 tools/hawkmoth_egg.py
Writes designs/eggs/c_style/HawkmothEgg.bbmodel, src/shared/Eggs/HawkmothEggModel.luau,
assets/ui/HawkmothEggRender.png and previews in /mnt/project-files/world2/woodland/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell, front_plate, layer_of  # noqa: E402
from hawkmoth import COLORS  # noqa: E402

FUR, DARK, ORANGE, SKULL, BLACK, WING, GLOW = (COLORS[k] for k in ("fur", "furdark", "orange", "skull", "black", "wing", "glow"))


def spike(egg, name, base, apex, wv, tv, hw, ht, color, bone=None):
    """A pyramid: base rectangle centred on base (half sizes hw along wv, ht along tv), apex."""
    b, wv, tv = (np.array(v, float) for v in (base, wv, tv))
    c = [b - wv * hw - tv * ht, b + wv * hw - tv * ht, b + wv * hw + tv * ht, b - wv * hw + tv * ht]
    a = np.array(apex, float)
    egg.poly(name, [c] + [[c[i], c[(i + 1) % 4], a] for i in range(4)], color, bone=bone)


def fz(y, out=0.0):
    """The front face's z at height y, plus out further forward."""
    return -WIDTHS[layer_of(y)] / 2 - out


def hawkmoth_egg():
    egg = shell([DARK, ORANGE, FUR, FUR, FUR, FUR, ORANGE])
    # the skull on the front, a raised plate over layers 2-3 with its sockets, nose and teeth on it
    front_plate(egg, "Skull", -0.55, 0.55, 1.05, 1.75, SKULL, depth=0.12, plain=False)
    front_plate(egg, "SkullJaw", -0.35, 0.35, 0.8, 1.05, SKULL, depth=0.12, plain=False)
    z = fz(1.5, 0.12)
    for s in (-1, 1):
        egg.block(f"Socket{'LR'[s > 0]}", (s * 0.08 - (0.3 if s < 0 else 0), 1.4, z - 0.05), (s * 0.08 + (0.3 if s > 0 else 0), 1.66, z + 0.01), BLACK)
    z = fz(1.2, 0.12)
    egg.block("SkullNose", (-0.08, 1.14, z - 0.05), (0.08, 1.3, z + 0.01), BLACK)
    z = fz(0.9, 0.12)
    egg.block("SkullTeeth", (-0.25, 0.88, z - 0.05), (0.25, 0.94, z + 0.01), BLACK)
    # glowing orange eyes up on the top half, under a black brow
    z = fz(2.1)
    for s in (-1, 1):
        n = "LR"[s > 0]
        egg.block(f"Glow_Eye{n}", (s * 0.1 - (0.36 if s < 0 else 0), 1.9, z - 0.06), (s * 0.1 + (0.36 if s > 0 else 0), 2.14, z + 0.01), ORANGE)
    egg.block("Brow", (-0.5, 2.14, z - 0.1), (0.5, 2.26, z + 0.01), BLACK)
    # wings swept back down the sides: a dark slab with an orange band and a pyramid point
    for s in (-1, 1):
        n = "LR"[s > 0]
        x = s * WIDTHS[3] / 2
        egg.block(f"Wing{n}", (min(x, x + s * 0.18), 0.9, -0.1), (max(x, x + s * 0.18), 2.0, 0.9), WING).bone = "bottom"
        egg.block(f"WingBand{n}", (min(x, x + s * 0.2), 1.3, -0.1), (max(x, x + s * 0.2), 1.45, 0.9), ORANGE).bone = "bottom"
        spike(egg, f"WingTip{n}", (x + s * 0.09, 1.45, 0.9), (x + s * 0.09, 1.25, 1.35), (0, 1, 0), (1, 0, 0), 0.55, 0.09, BLACK, bone="bottom")
    # horn antennae on top, leaning out and back, orange pyramid tips
    top = N * LH
    for s in (-1, 1):
        n = "LR"[s > 0]
        x0 = s * 0.35
        egg.block(f"Antenna{n}", (x0 - 0.1, top - 0.1, -0.1), (x0 + 0.1, top + 0.45, 0.1), BLACK).bone = "top"
        spike(egg, f"AntennaTip{n}", (x0, top + 0.45, 0), (x0 + s * 0.12, top + 0.8, 0.05), (1, 0, 0), (0, 0, 1), 0.1, 0.1, ORANGE, bone="top")
    return egg


if __name__ == "__main__":
    O.EGGS = [("Hawkmoth", hawkmoth_egg)]
    O.main("Hawkmoth", preview="/mnt/project-files/world2/woodland")
