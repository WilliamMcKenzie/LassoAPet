"""The Majestic Unicorn's egg (QM: extremely detailed), in take C's style
(tools/ocean_eggs.py): the octo shell in pearl with a lilac layer over a gold base
(its hooves and socks), pearl ears with pink insides, gold brows, a twisted gold horn
with a pyramid tip, a rainbow forelock, a long rainbow mane cascading down the back
that flares out as it falls (as if blown back), a rainbow tail at the bottom, and a
gold-framed lilac gem on the front with gold spikes either side.

Run from the repo root: python3 tools/majestic_unicorn_egg.py
Writes designs/eggs/c_style/MajesticUnicornEgg.bbmodel, src/shared/Eggs/MajesticUnicornEggModel.luau,
assets/ui/MajesticUnicornEggRender.png and previews in /mnt/project-files/animals/majestic_unicorn/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, ears, shell, front_plate  # noqa: E402
from animal_designs import PINK  # noqa: E402
from partlib import Part, T, Ry  # noqa: E402
from majestic_unicorn import PEARL, LILAC, GOLD, RAINBOW  # noqa: E402

GEM = (200, 150, 250)


def pyramid(egg, name, base, apex, color):
    c = [np.array(p, float) for p in base]
    a = np.array(apex, float)
    return egg.poly(name, [c] + [[c[i], c[(i + 1) % 4], a] for i in range(4)], color, bone="top")


def majestic_unicorn_egg():
    egg = shell([GOLD, LILAC, PEARL, PEARL, PEARL, PEARL, PEARL])
    top = N * LH
    ears(egg, PEARL, PINK, x=0.38, hw=0.22, h=0.7, base=top - 0.05)

    # rainbow forelock over the top front, then the twisted gold horn out of it
    egg.block("Forelock", (-0.34, top - 0.05, -0.45), (0.34, top + 0.25, 0.15), RAINBOW[0]).bone = "top"
    y, w = top + 0.25, 0.34
    for i in range(4):
        h = 0.28
        p = Part(f"Horn{i}", (w, h, w), T(0, y + h / 2, -0.2) @ Ry(45 * (i % 2)), GOLD)
        p.bone = "top"
        egg.parts.append(p)
        y += h - 0.01
        w -= 0.06
    pyramid(egg, "HornTip", [(-w / 2, y, -0.2 - w / 2), (w / 2, y, -0.2 - w / 2), (w / 2, y, -0.2 + w / 2), (-w / 2, y, -0.2 + w / 2)],
            (0, y + 0.45, -0.2), GOLD)

    # gold brows above where its eyes would be, on the front of the top layer
    zf = -WIDTHS[N - 1] / 2
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.12, sx * 0.45))
        egg.block("Brow" + side, (xa, top - 0.22, zf - 0.08), (xb, top - 0.1, zf + 0.02), GOLD).bone = "top"

    # long rainbow mane down the back: a strand per layer, red at the top, flaring further
    # out the lower it gets, with a second, narrower strand on top of each (blown back)
    for k, i in enumerate(range(N - 1, 0, -1)):
        c = RAINBOW[k % 6]
        z = WIDTHS[i] / 2
        out = 0.22 + 0.07 * k
        hw = 0.34 - 0.025 * k
        egg.block(f"Mane{k}", (-hw, i * LH, z - 0.05), (hw, (i + 1) * LH, z + out), c)
        egg.block(f"ManeTip{k}", (-hw + 0.1, i * LH + 0.1, z + out - 0.01), (hw - 0.1, (i + 1) * LH - 0.06, z + out + 0.12), c)

    # rainbow tail at the bottom of the back, curling up and out
    zb = WIDTHS[1] / 2
    for k, (y0, y1, z0, z1) in enumerate(((LH * 0.4, LH * 1.1, 0.4, 0.75), (LH * 0.1, LH * 0.6, 0.65, 1.0), (LH * 0.0, LH * 0.35, 0.9, 1.2))):
        egg.block(f"Tail{k}", (-0.22, y0, zb + z0 - 0.4), (0.22, y1, zb + z1 - 0.4), RAINBOW[[5, 4, 3][k]])

    # gold-framed lilac gem on the front, gold spikes either side of it
    front_plate(egg, "GemFrame", -0.32, 0.32, 3 * LH + 0.04, 4 * LH - 0.04, GOLD, depth=0.08, plain=False)
    front_plate(egg, "Gem", -0.2, 0.2, 3 * LH + 0.13, 4 * LH - 0.13, GEM, depth=0.16, plain=False)
    zc = -WIDTHS[3] / 2
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.45, sx * 0.75))
        ym = 3.5 * LH
        pyramid(egg, "Star" + side, [(x0, ym - 0.15, zc), (x1, ym - 0.15, zc), (x1, ym + 0.15, zc), (x0, ym + 0.15, zc)],
                ((x0 + x1) / 2, ym, zc - 0.35), GOLD)

    # gold hooves peeking out under the lilac layer, one at each corner
    for sx in (-1, 1):
        for sz in (-1, 1):
            d = WIDTHS[0] / 2 * 0.62
            egg.block(f"Hoof{'L' if sx < 0 else 'R'}{'F' if sz < 0 else 'B'}",
                      (sx * d - 0.2, 0, sz * d - 0.2), (sx * d + 0.2, 0.3, sz * d + 0.2), GOLD)
    return egg


if __name__ == "__main__":
    O.EGGS = [("MajesticUnicorn", majestic_unicorn_egg)]
    O.main("MajesticUnicorn", preview="/mnt/project-files/animals/majestic_unicorn")
