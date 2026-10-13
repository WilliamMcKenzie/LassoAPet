"""The Eagle Sentry's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the falcon's
brown over a cream base ringed in gold, a little usekh collar on the front (gold, lapis,
turquoise and red bands with a glowing turquoise jewel), white plate eyes with black pupils under
angry gold brows and the black Horus markings, a slate hooked beak on a yellow cere, a nemes cap
striped lapis and gold with a gold cobra on the brow, a glowing sun disc on top, and barred
wings folded down both sides with gold edges and gold tips.

Run from the repo root: python3 tools/eagle_sentry_egg.py
Writes designs/eggs/c_style/EagleSentryEgg.bbmodel, src/shared/Eggs/EagleSentryEggModel.luau,
assets/ui/EagleSentryEggRender.png and previews in /mnt/project-files/world2/tomb/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell, front_plate, layer_of  # noqa: E402
from hawkmoth_egg import spike  # noqa: E402
from eagle_sentry import COLORS  # noqa: E402

(BROWN, DARK, CREAM, GOLD, GOLDDARK, LAPIS, TURQ, RED, YELLOW, SLATE, BLACK, WHITE, GLOWGOLD,
 GLOWTURQ) = (COLORS[k] for k in ("brown", "darkbrown", "cream", "gold", "golddark", "lapis", "turq", "red",
                                  "yellow", "slate", "black", "white", "glowgold", "glowturq"))


def fz(y, out=0.0):
    """The front face's z at height y, plus out further forward."""
    return -WIDTHS[layer_of(y)] / 2 - out


def eagle_sentry_egg():
    egg = shell([CREAM, BROWN, BROWN, BROWN, BROWN, GOLD, LAPIS])
    # the collar: bands across the front of layers 1-2, narrowing upward, a glowing jewel
    for k, (col, y0, hw) in enumerate(((RED, 0.46, 0.62), (TURQ, 0.58, 0.56), (GOLD, 0.7, 0.5), (LAPIS, 0.82, 0.42))):
        front_plate(egg, f"Collar{k}", -hw, hw, y0, y0 + 0.12, col, depth=0.06 + 0.02 * k, plain=False)
    z = fz(0.6, 0.14)
    egg.block("Glow_Jewel", (-0.09, 0.5, z - 0.04), (0.09, 0.68, z + 0.02), GLOWTURQ)
    # eyes up on layer 3, angry gold brows, the Horus lines back and the drops down
    z = fz(1.6)
    for s in (-1, 1):
        n = "LR"[s > 0]
        x0, x1 = sorted((s * 0.18, s * 0.66))
        egg.block(f"Eye{n}", (x0, 1.42, z - 0.05), (x1, 1.9, z + 0.01), WHITE)
        px0, px1 = sorted((s * 0.26, s * 0.48))
        egg.block(f"Pupil{n}", (px0, 1.5, z - 0.08), (px1, 1.72, z - 0.04), BLACK)
        bx0, bx1 = sorted((s * 0.12, s * 0.72))
        egg.block(f"Brow{n}", (bx0, 1.94, z - 0.1), (bx1, 2.04, z + 0.01), GOLDDARK)
        lx0, lx1 = sorted((s * 0.66, s * 0.84))
        egg.block(f"EyeLine{n}", (lx0, 1.42, z - 0.05), (lx1, 1.5, z + 0.01), BLACK)
        dx0, dx1 = sorted((s * 0.5, s * 0.6))
        egg.block(f"EyeDrop{n}", (dx0, 1.06, fz(1.2) - 0.05), (dx1, 1.42, fz(1.2) + 0.01), BLACK)
    # the beak: a yellow cere and a slate hook sticking out the front
    z = fz(1.3)
    egg.block("Cere", (-0.16, 1.36, z - 0.12), (0.16, 1.5, z + 0.01), YELLOW)
    egg.block("Beak", (-0.14, 1.14, z - 0.38), (0.14, 1.38, z - 0.1), SLATE)
    spike(egg, "BeakHook", (0, 1.16, z - 0.32), (0, 0.94, z - 0.26), (1, 0, 0), (0, 0, 1), 0.12, 0.06, SLATE)
    # the nemes: lapis stripes over the gold layer 5, a gold cobra on the brow
    y5 = 5 * LH
    z5 = WIDTHS[5] / 2
    for k, x in enumerate((-0.22, 0.22)):
        egg.block(f"CapStripe{k}", (x - 0.08, y5, -z5 - 0.04), (x + 0.08, y5 + LH, -z5 + 0.01), LAPIS).bone = "top"
        egg.block(f"CapStripeB{k}", (x - 0.08, y5, z5 - 0.01), (x + 0.08, y5 + LH, z5 + 0.04), LAPIS).bone = "top"
    egg.block("CobraBody", (-0.06, y5 + 0.1, -z5 - 0.14), (0.06, y5 + 0.4, -z5 - 0.02), GOLD).bone = "top"
    egg.block("CobraHood", (-0.13, y5 + 0.36, -z5 - 0.16), (0.13, y5 + 0.56, -z5 - 0.08), GOLD).bone = "top"
    egg.block("Glow_CobraEyes", (-0.08, y5 + 0.48, -z5 - 0.18), (0.08, y5 + 0.51, -z5 - 0.15), RED).bone = "top"
    # the sun disc on top, glowing in a gold rim
    top = N * LH
    egg.block("DiscStem", (-0.1, top - 0.05, -0.08), (0.1, top + 0.18, 0.08), GOLDDARK).bone = "top"
    for k, (w, h) in enumerate(((0.9, 0.5), (0.74, 0.74), (0.5, 0.9))):
        egg.block(f"Glow_Sun{k}", (-w / 2, top + 0.65 - h / 2, -0.06), (w / 2, top + 0.65 + h / 2, 0.06), GLOWGOLD).bone = "top"
        egg.block(f"SunRim{k}", (-w / 2 - 0.07, top + 0.65 - h / 2 - 0.07, 0.0), (w / 2 + 0.07, top + 0.65 + h / 2 + 0.07, 0.1), GOLDDARK).bone = "top"
    # wings folded down the sides: a brown slab, a gold edge, cream bars and gold tips
    for s in (-1, 1):
        n = "LR"[s > 0]
        x = s * WIDTHS[3] / 2
        x0, x1 = sorted((x, x + s * 0.18))
        e0, e1 = sorted((x, x + s * 0.22))
        egg.block(f"Wing{n}", (x0, 0.7, -0.3), (x1, 2.1, 0.8), BROWN).bone = "bottom"
        egg.block(f"WingEdge{n}", (e0, 1.86, -0.34), (e1, 2.14, 0.84), GOLD).bone = "bottom"
        for k, y in enumerate((1.0, 1.4)):
            egg.block(f"WingBar{n}{k}", (e0, y, -0.3), (e1, y + 0.1, 0.8), CREAM).bone = "bottom"
        for k, zz in enumerate((-0.1, 0.3, 0.7)):
            spike(egg, f"WingTip{n}{k}", (x + s * 0.09, 0.7, zz), (x + s * 0.09, 0.36, zz + 0.06), (0, 0, 1), (1, 0, 0),
                  0.13, 0.08, GOLD, bone="bottom")
    return egg


if __name__ == "__main__":
    O.EGGS = [("EagleSentry", eagle_sentry_egg)]
    O.main("EagleSentry", preview="/mnt/project-files/world2/tomb")
