"""The Giant Golem's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
golem's stone, dark at the bottom and paler up top under a moss cap, split by a glowing
orange band with lava cracks running down from it. An angry face on the front (a heavy
brow, glowing orange eyes, a glowing maw and two stone fangs), boulder shoulders on the
sides, a crown of rock spikes on the right of the cap and a little autumn tree on the
left (the golem's two shoulders), a spike ridge down the back, and two big stone fists
at the front bottom.

Run from the repo root: python3 tools/giant_golem_egg.py
Writes designs/eggs/c_style/GiantGolemEgg.bbmodel, src/shared/Eggs/GiantGolemEggModel.luau,
assets/ui/GiantGolemEggRender.png and previews in /mnt/project-files/world2/woodland/giant_golem/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, front_plate, shell  # noqa: E402
from crystal_elephant_egg import point  # noqa: E402
from giant_golem import STONE, DARK, LIGHT, MOSS, LEAF, LEAF2, BARK, GLOW  # noqa: E402


def glow(egg, name, lo, hi):
    p = egg.block("Glow" + name, lo, hi, GLOW)
    p.plain = True
    return p


def giant_golem_egg():
    egg = shell([DARK, DARK, STONE, STONE, STONE, LIGHT, MOSS])
    top = N * LH

    # glowing orange band round the middle, lava cracks running down the front from it
    first = len(egg.parts)
    octo_layer(egg, "Band", 3 * LH - 0.06, 3 * LH + 0.06, WIDTHS[2] + 0.1, GLOW, "bottom")
    for p in egg.parts[first:]:
        p.name = "Glow" + p.name
    front_plate(egg, "GlowCrackA", -0.5, -0.4, 1.9 * LH, 3 * LH, GLOW, depth=0.04, plain=False)
    front_plate(egg, "GlowCrackB", -0.4, -0.15, 1.9 * LH, 2.05 * LH, GLOW, depth=0.04, plain=False)
    front_plate(egg, "GlowCrackC", 0.35, 0.45, 1.2 * LH, 3 * LH, GLOW, depth=0.04, plain=False)
    front_plate(egg, "GlowCrackD", 0.45, 0.7, 1.2 * LH, 1.35 * LH, GLOW, depth=0.04, plain=False)

    # face: heavy brow, glowing eyes under it, glowing maw, two fangs
    zf = -WIDTHS[5] / 2
    egg.block("Brow", (-0.62, 5.05 * LH, zf - 0.3), (0.62, 5.7 * LH, zf + 0.4), LIGHT).bone = "top"
    egg.block("BrowRidge", (-0.12, 5.05 * LH, zf - 0.4), (0.12, 5.85 * LH, zf + 0.2), LIGHT).bone = "top"
    for s in (-1, 1):
        n = "LR"[s > 0]
        xa, xb = sorted((s * 0.12, s * 0.5))
        front_plate(egg, "GlowEye" + n, xa, xb, 4.45 * LH, 5.0 * LH, GLOW, depth=0.07, plain=False)
        point(egg, "Horn" + n, (s * 0.45, 5.7 * LH, zf - 0.05), (s * 0.3, 1, -0.2), 0.12, 0.4, DARK, "top")
    front_plate(egg, "GlowMaw", -0.35, 0.35, 4.05 * LH, 4.2 * LH, GLOW, depth=0.06, plain=False)
    zm = -WIDTHS[4] / 2
    for s in (-1, 1):
        n = "LR"[s > 0]
        point(egg, "Fang" + n, (s * 0.25, 4.0 * LH, zm - 0.06), (0, -1, 0), 0.07, 0.22, LIGHT, "top")

    # boulder shoulders on the sides of the top shell, a glowing vein on each
    for s in (-1, 1):
        n = "LR"[s > 0]
        x = s * WIDTHS[4] / 2
        xa, xb = sorted((x - s * 0.1, x + s * 0.3))
        egg.block("Shoulder" + n, (xa, 4.0 * LH, -0.55), (xb, 5.4 * LH, 0.45), STONE).bone = "top"
        xa, xb = sorted((x + s * 0.3, x + s * 0.34))
        glow(egg, "ShoulderVein" + n, (xa, 4.4 * LH, -0.12), (xb, 5.0 * LH, -0.02)).bone = "top"

    # right of the cap: a crown of rock spikes
    for k, (x, z, d, h) in enumerate(((0.3, -0.05, (0.35, 1, -0.1), 0.6), (0.18, 0.25, (0.2, 1, 0.3), 0.42),
                                       (0.45, 0.2, (0.6, 1, 0.2), 0.35))):
        point(egg, f"Spike{k + 1}", (x, top - 0.05, z), d, 0.13, h, DARK, "top")
    # left of the cap: a little autumn tree
    egg.block("Trunk", (-0.4, top - 0.05, -0.05), (-0.26, top + 0.42, 0.09), BARK).bone = "top"
    egg.block("Canopy", (-0.6, top + 0.35, -0.24), (-0.06, top + 0.72, 0.28), LEAF).bone = "top"
    egg.block("CanopyTop", (-0.48, top + 0.72, -0.12), (-0.18, top + 0.9, 0.16), LEAF2).bone = "top"

    # spike ridge down the back
    for k, (i, h) in enumerate(((5.0, 0.35), (3.9, 0.45), (2.4, 0.35))):
        z = WIDTHS[int(i)] / 2
        point(egg, f"Back{k + 1}", (0, i * LH, z - 0.05), (0, 0.5, 1), 0.13, h, DARK)

    # two big stone fists at the front bottom with knuckles, dark feet behind
    for s in (-1, 1):
        n = "LR"[s > 0]
        z = -WIDTHS[0] / 2
        xa, xb = sorted((s * 0.25, s * 0.85))
        egg.block("Fist" + n, (xa, 0, z - 0.45), (xb, 0.5, z + 0.3), STONE)
        for k in range(3):
            ka, kb = sorted((s * (0.27 + 0.2 * k), s * (0.43 + 0.2 * k)))
            egg.block(f"Knuckle{n}{k + 1}", (ka, 0, z - 0.6), (kb, 0.38 if k % 2 else 0.44, z - 0.45), LIGHT)
        xa, xb = sorted((s * 0.2, s * 0.62))
        egg.block("Foot" + n, (xa, 0, 0.15), (xb, 0.28, 0.6), DARK)
    return egg


if __name__ == "__main__":
    O.EGGS = [("GiantGolem", giant_golem_egg)]
    O.main("GiantGolem", preview="/mnt/project-files/world2/woodland/giant_golem")
