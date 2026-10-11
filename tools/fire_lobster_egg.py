"""The Fire Lobster's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
lobster's red and orange bands, two antennae standing up off the top and arching
back with glowing tips, and a little crusher claw on each side.

Run from the repo root: python3 tools/fire_lobster_egg.py [out_dir]
Writes FireLobsterEgg.bbmodel and FireLobsterEgg.png to out_dir (not in game).
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import H, LH, WIDTHS, shell  # noqa: E402
from partlib import render  # noqa: E402
from fire_lobster_design import LAVA, ORANGE, RED, RED_DARK  # noqa: E402

OUT = "/mnt/project-files/animals/firelobster"


def fire_lobster_egg():
    egg = shell([RED_DARK, RED_DARK, RED, ORANGE, RED, ORANGE, RED])
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.15, sx * 0.35))
        # antennae: up off the top, then back, glowing at the tip
        egg.block("Antenna" + side, (x0, H, -0.3), (x1, H + 1.1, -0.1), RED_DARK)
        egg.block(f"Antenna{side}2", (x0, H + 0.9, -0.1), (x1, H + 1.1, 0.6), RED_DARK)
        egg.block("GlowAntenna" + side, (x0, H + 0.9, 0.6), (x1, H + 1.1, 0.85), LAVA)
        # a crusher claw on each side of the widest layer: a dark arm out, a red hand,
        # two dark fingers forward
        w = WIDTHS[3] / 2
        y = 3 * LH
        xa, xb = sorted((sx * w, sx * (w + 0.25)))
        egg.block("ClawArm" + side, (xa, y + 0.08, -0.2), (xb, y + 0.38, 0.2), RED_DARK)
        xa, xb = sorted((sx * (w + 0.15), sx * (w + 0.7)))
        egg.block("ClawHand" + side, (xa, y - 0.05, -0.6), (xb, y + 0.5, 0.1), RED)
        xa, xb = sorted((sx * (w + 0.42), sx * (w + 0.7)))
        egg.block("ClawOut" + side, (xa, y, -1.15), (xb, y + 0.45, -0.6), RED_DARK)
        xa, xb = sorted((sx * (w + 0.15), sx * (w + 0.32)))
        egg.block("ClawIn" + side, (xa, y + 0.05, -0.95), (xb, y + 0.4, -0.6), RED_DARK)
    return egg


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    egg = fire_lobster_egg()
    O.build(egg, "FireLobsterEgg", out)
    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.neon = True
    tile = 420
    sheet = Image.new("RGB", (tile * 2, tile))
    for r, view in enumerate(C.VIEWS):
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=30, **view), (r * tile, 0))
    sheet.save(os.path.join(out, "FireLobsterEgg.png"))
    print(len(egg.parts), "parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
