"""The Crystal Elephant's egg (QM: "insanely epic"), in take C's style (tools/ocean_eggs.py):
the octo shell in crystal-purple armour below and the elephant's lavender skin above, split
by a glowing cyan band. A crown of crystals on top (a tall cyan one, two pink ones leaning
out and two small cyan ones behind), big lavender ears, a trunk down the front between two
glowing crystal tusks, a purple head plate with a glowing cyan ridge, a ring of crystal
spikes jutting out of the armour, and a ridge of crystals down the back.

Run from the repo root: python3 tools/crystal_elephant_egg.py
Writes designs/eggs/c_style/CrystalElephantEgg.bbmodel, src/shared/Eggs/CrystalElephantEggModel.luau,
assets/ui/CrystalElephantEggRender.png and previews in /mnt/project-files/animals/crystal_elephant/.
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, front_plate, shell  # noqa: E402
from crystal_elephant import COLORS  # noqa: E402

SKIN, SKIN_DARK = COLORS["skin"], COLORS["skin_dark"]
ARMOR, ARMOR_DARK = COLORS["armor"], COLORS["armor_dark"]
CYAN, PINK, GLOW = COLORS["cyan"], COLORS["pink"], COLORS["glow"]


def axes(d):
    d = np.array(d, float) / np.linalg.norm(d)
    a = np.cross(d, [0, 1, 0] if abs(d[1]) < 0.9 else [1, 0, 0])
    a /= np.linalg.norm(a)
    return d, a, np.cross(d, a)


def point(egg, name, base, d, hw, h, color, bone=None):
    """A pyramid: square base (half-size hw) at base, apex h along d."""
    d, a, b = axes(d)
    base = np.array(base, float)
    q = [base + (sa * a + sb * b) * hw for sa, sb in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    t = base + d * h
    return egg.poly(name, [q] + [[q[i], q[(i + 1) % 4], t] for i in range(4)], color, bone=bone)


def shard(egg, name, base, d, hw, shaft, tip, color, bone=None):
    """A crystal like the cavern props: a square shaft and a pyramid tip, leaning along d."""
    dd, a, b = axes(d)
    base = np.array(base, float)
    ring = lambda c: [c + (sa * a + sb * b) * hw for sa, sb in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    lo, hi = ring(base), ring(base + dd * shaft)
    faces = [lo[::-1], hi] + [[lo[i], lo[(i + 1) % 4], hi[(i + 1) % 4], hi[i]] for i in range(4)]
    egg.poly(name, faces, color, bone=bone)
    point(egg, name + "Tip", base + dd * shaft, d, hw, tip, color, bone=bone)


def crystal_elephant_egg():
    egg = shell([ARMOR_DARK, ARMOR, ARMOR, SKIN, SKIN, SKIN, SKIN])
    top = N * LH

    # a glowing cyan band between the armour and the skin
    first = len(egg.parts)
    octo_layer(egg, "Band", 3 * LH - 0.06, 3 * LH + 0.06, WIDTHS[2] + 0.1, CYAN, "bottom")
    for p in egg.parts[first:]:
        p.name = "Glow" + p.name

    # crown of crystals on top
    shard(egg, "Crown", (0, top - 0.05, 0.05), (0, 1, 0.12), 0.28, 0.7, 0.6, CYAN, "top")
    for s in (-1, 1):
        n = "LR"[s > 0]
        shard(egg, "Crown" + n, (s * 0.3, top - 0.05, -0.05), (s * 0.55, 1, 0), 0.2, 0.45, 0.42, PINK, "top")
        shard(egg, "CrownBack" + n, (s * 0.22, top - 0.05, 0.36), (s * 0.3, 1, 0.5), 0.12, 0.22, 0.25, CYAN, "top")

    # big ears on the sides of the top shell, darker inside
    for s in (-1, 1):
        n = "LR"[s > 0]
        x = s * WIDTHS[4] / 2
        xa, xb = sorted((x - s * 0.05, x + s * 0.12))
        egg.block("Ear" + n, (xa, 3.9 * LH, -0.35), (xb, 6.3 * LH, 0.55), SKIN).bone = "top"
        xa, xb = sorted((x + s * 0.12, x + s * 0.17))
        egg.block("EarIn" + n, (xa, 4.2 * LH, -0.2), (xb, 6.0 * LH, 0.4), SKIN_DARK).bone = "top"

    # head plate on the front of the top shell with a glowing cyan ridge and brow crystal
    front_plate(egg, "HeadPlate", -0.36, 0.36, 5 * LH + 0.04, 6 * LH - 0.04, ARMOR, depth=0.08, plain=False)
    front_plate(egg, "GlowRidge", -0.08, 0.08, 5 * LH + 0.04, 6 * LH - 0.04, CYAN, depth=0.14, plain=False)
    zf = -WIDTHS[5] / 2
    point(egg, "BrowCrystal", (0, 6 * LH - 0.04, zf - 0.1), (0, 1, -0.45), 0.12, 0.38, CYAN, "top")

    # trunk down the front, curling out at the bottom
    for k, (i0, i1, out) in enumerate(((3.0, 4.6, 0.18), (1.8, 3.0, 0.22), (1.1, 1.8, 0.36))):
        z = -WIDTHS[int(i0)] / 2
        egg.block(f"Trunk{k}", (-0.2 + 0.02 * k, i0 * LH, z - out), (0.2 - 0.02 * k, i1 * LH, z + 0.05), SKIN)

    # glowing crystal tusks either side of the trunk: out and forward, tips sweeping up
    for s in (-1, 1):
        n = "LR"[s > 0]
        z = -WIDTHS[3] / 2
        egg.block("GlowTusk" + n, (s * 0.36 - 0.11, 3.0 * LH, z - 0.7), (s * 0.36 + 0.11, 3.0 * LH + 0.22, z + 0.02), GLOW)
        point(egg, "GlowTuskTip" + n, (s * 0.36, 3.0 * LH + 0.11, z - 0.7), (0, 0.9, -1), 0.11, 0.6, GLOW)

    # ring of crystal spikes jutting out of the armour, cyan and pink in turn (none at the front,
    # where the trunk and tusks are)
    y = 2.2 * LH
    r = WIDTHS[2] / 2 - 0.02
    for k in range(1, 8):
        ang = math.radians(45 * k)
        d = np.array([math.sin(ang), 0.35, -math.cos(ang)])
        base = np.array([math.sin(ang) * r, y, -math.cos(ang) * r])
        point(egg, f"Spike{k}", base, d, 0.16, 0.6, CYAN if k % 2 else PINK, "bottom")

    # ridge of crystals down the back
    for k, (i, h, c) in enumerate(((5.3, 0.3, PINK), (4.2, 0.4, CYAN), (3.4, 0.3, PINK))):
        z = WIDTHS[int(i)] / 2
        shard(egg, f"Back{k}", (0, i * LH, z - 0.1), (0, 0.6, 1), 0.14, h, 0.3, c)

    # dark armoured feet under the bottom layer
    for sx in (-1, 1):
        for sz in (-1, 1):
            d = WIDTHS[0] / 2 * 0.6
            egg.block(f"Foot{'L' if sx < 0 else 'R'}{'F' if sz < 0 else 'B'}",
                      (sx * d - 0.22, 0, sz * d - 0.22), (sx * d + 0.22, 0.28, sz * d + 0.22), ARMOR_DARK)
    return egg


if __name__ == "__main__":
    O.EGGS = [("CrystalElephant", crystal_elephant_egg)]
    O.main("CrystalElephant", preview="/mnt/project-files/animals/crystal_elephant")
