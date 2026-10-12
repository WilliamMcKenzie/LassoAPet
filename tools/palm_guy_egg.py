"""Palm Guy's egg, in take C's style (tools/ocean_eggs.py), like the T-Rex's (tools/trex_egg.py):
the octo shell in the Cycad's bark browns, a dark ring at every other layer like the trunk's
joints, the Cactus's face (two dark eyes over a tall mouth, which splits at the crack), and a
leafy heart on top with fronds hanging over the sides.

Run from the repo root: python3 tools/palm_guy_egg.py [game]
Preview: PalmGuyEgg.bbmodel/.png in /mnt/project-files/animals/palm_guy; `game` writes the game's
files (ocean_eggs.main: designs/eggs/c_style, Eggs/PalmGuyEggModel.luau, assets/ui render).
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell  # noqa: E402
from palm_guy import BARK, FACE, LEAF, LEAF_DARK, RING  # noqa: E402
from partlib import render  # noqa: E402
from trex_egg import faces  # noqa: E402

OUT = "/mnt/project-files/animals/palm_guy"


def palm_guy_egg():
    egg = shell([BARK[1], BARK[0], BARK[1], BARK[0], BARK[1], BARK[0], BARK[1]])
    # the trunk's joints: a dark ring low on every other layer
    for i in (2, 4):
        bone = "top" if i >= CRACK_LAYER else "bottom"
        octo_layer(egg, f"{i}Ring", i * LH, i * LH + 0.12, WIDTHS[i] + 0.12, RING, bone)
    # the Cactus's face: eyes on the top half, the tall mouth across the crack
    y = CRACK_LAYER * LH
    zf = -WIDTHS[CRACK_LAYER + 1] / 2
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.12, sx * 0.42))
        egg.block("Eye" + side, (x0, y + 0.45, zf - 0.05), (x1, y + 0.85, zf + 0.02), FACE).bone = "top"
    zm = -WIDTHS[CRACK_LAYER - 1] / 2
    egg.block("MouthTop", (-0.14, y, zf - 0.05), (0.14, y + 0.3, zf + 0.02), FACE).bone = "top"
    egg.block("MouthBottom", (-0.14, y - 0.4, zm - 0.05), (0.14, y, zm + 0.02), FACE).bone = "bottom"
    # a leafy heart on top, fronds hanging over the four sides and the four corners
    top = N * LH
    a6, _ = faces(WIDTHS[N - 1])
    egg.block("Heart", (-0.4, top - 0.02, -0.4), (0.4, top + 0.35, 0.4), LEAF_DARK).bone = "top"
    for k, (dx, dz) in enumerate(((1, 0), (-1, 0), (0, 1), (0, -1), (0.7, 0.7), (-0.7, 0.7), (0.7, -0.7), (-0.7, -0.7))):
        col = LEAF[k % 3]
        diag = dx and dz
        w = 0.32 if diag else 0.42
        for j, (r0, r1, y0, y1) in enumerate(((0.2, a6 - 0.05, top + 0.08, top + 0.26), (a6 - 0.05, a6 + 0.35, top - 0.12, top + 0.12))):
            if diag:
                cx, cz = dx * (r0 + r1) / 2, dz * (r0 + r1) / 2
                h = (r1 - r0) / 2 * 0.75 + w / 2
                lo, hi = (cx - h, y0, cz - h), (cx + h, y1, cz + h)
            elif dx:
                x0, x1 = sorted((dx * r0, dx * r1))
                lo, hi = (x0, y0, -w / 2), (x1, y1, w / 2)
            else:
                z0, z1 = sorted((dz * r0, dz * r1))
                lo, hi = (-w / 2, y0, z0), (w / 2, y1, z1)
            egg.block(f"Frond{k}{j}", lo, hi, col).bone = "top"
        if not diag:  # the tip hanging down the side
            r0, r1 = a6 + 0.2, a6 + 0.38
            if dx:
                x0, x1 = sorted((dx * r0, dx * r1))
                lo, hi = (x0, top - 0.55, -w * 0.4), (x1, top - 0.1, w * 0.4)
            else:
                z0, z1 = sorted((dz * r0, dz * r1))
                lo, hi = (-w * 0.4, top - 0.55, z0), (w * 0.4, top - 0.1, z1)
            egg.block(f"Frond{k}Tip", lo, hi, LEAF[(k + 1) % 3]).bone = "top"
    return egg


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    egg = palm_guy_egg()
    O.build(egg, "PalmGuyEgg", out)
    tile = 420
    sheet = Image.new("RGB", (tile * 2, tile))
    for r, view in enumerate(C.VIEWS):
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=30, **view), (r * tile, 0))
    sheet.save(os.path.join(out, "PalmGuyEgg.png"))
    print(len(egg.parts), "parts")


def game():
    O.EGGS = [("PalmGuy", palm_guy_egg)]
    O.main("PalmGuy", preview=OUT)


if __name__ == "__main__":
    game() if sys.argv[1:2] == ["game"] else main(*sys.argv[1:])
