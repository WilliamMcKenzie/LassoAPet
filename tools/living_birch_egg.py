"""The Living Birch's egg, in take C's style like Palm Guy's (tools/palm_guy_egg.py): the octo
shell in white birch bark with dark birch bands on every other layer and a few dark marks,
Palm Guy's face (two dark eyes over a tall mouth, which splits at the crack), and a chunky
little autumn canopy of leaf blocks on top, like the Living Birch's crown.

Run from the repo root: python3 tools/living_birch_egg.py [game]
Preview: LivingBirchEgg.bbmodel/.png in /mnt/project-files/animals/living_birch; `game` writes
the game's files (ocean_eggs.main: designs/eggs/c_style, Eggs/LivingBirchEggModel.luau,
assets/ui render).
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell  # noqa: E402
from living_birch import BARK, HEART, LEAF, MARK, MOUTH  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/animals/living_birch"
K, KY = 1.55, 1.35  # the canopy's spread and height


def living_birch_egg():
    egg = shell([BARK[1], BARK[0], BARK[1], BARK[0], BARK[1], BARK[0], BARK[1]])
    # birch bands low on every other layer, and a few short marks round the bottom half
    for i in (2, 4):
        bone = "top" if i >= CRACK_LAYER else "bottom"
        octo_layer(egg, f"{i}Band", i * LH, i * LH + 0.08, WIDTHS[i] + 0.1, MARK, bone)
    for k, (x0, x1, y, side) in enumerate(((0.15, 0.5, 1.2, -1), (-0.55, -0.2, 0.7, 1), (-0.4, -0.05, 1.5, 1))):
        z = side * WIDTHS[int(y / LH)] / 2
        egg.block(f"Mark{k}", (x0, y, z - 0.04), (x1, y + 0.1, z + 0.04), MARK).bone = "bottom"
    # Palm Guy's face: eyes on the top half, the tall mouth across the crack
    y = CRACK_LAYER * LH
    zf = -WIDTHS[CRACK_LAYER + 1] / 2
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.12, sx * 0.42))
        egg.block("Eye" + side, (x0, y + 0.45, zf - 0.05), (x1, y + 0.85, zf + 0.02), MOUTH).bone = "top"
    zm = -WIDTHS[CRACK_LAYER - 1] / 2
    egg.block("MouthTop", (-0.14, y, zf - 0.05), (0.14, y + 0.3, zf + 0.02), MOUTH).bone = "top"
    egg.block("MouthBottom", (-0.14, y - 0.4, zm - 0.05), (0.14, y, zm + 0.02), MOUTH).bone = "bottom"
    # the canopy: a red heart, a wide orange block, clumps round it and a yellow top
    t = N * LH
    for name, lo, hi, col in [
            ("Heart", (-0.45, t - 0.05, -0.45), (0.45, t + 0.15, 0.45), HEART),
            ("Leaves", (-0.62, t + 0.1, -0.6), (0.62, t + 0.6, 0.6), LEAF[0]),
            ("LeavesTop", (-0.42, t + 0.55, -0.4), (0.42, t + 0.9, 0.4), LEAF[3]),
            ("ClumpFL", (-0.72, t + 0.3, -0.7), (-0.3, t + 0.7, -0.28), LEAF[3]),
            ("ClumpFR", (0.25, t + 0.05, -0.72), (0.7, t + 0.42, -0.3), LEAF[1]),
            ("ClumpBL", (-0.7, t + 0.05, 0.25), (-0.25, t + 0.45, 0.7), LEAF[2]),
            ("ClumpBR", (0.3, t + 0.35, 0.25), (0.72, t + 0.75, 0.68), LEAF[2]),
            ("ClumpTop", (0.0, t + 0.85, -0.1), (0.3, t + 1.05, 0.2), LEAF[1])]:
        lo, hi = (lo[0] * K, t + (lo[1] - t) * KY, lo[2] * K), (hi[0] * K, t + (hi[1] - t) * KY, hi[2] * K)
        egg.block(name, lo, hi, col).bone = "top"
    return egg


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    egg = living_birch_egg()
    O.build(egg, "LivingBirchEgg", out)
    tile = 420
    sheet = Image.new("RGB", (tile * 2, tile))
    for r, view in enumerate(C.VIEWS):
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=30, **view), (r * tile, 0))
    sheet.save(os.path.join(out, "LivingBirchEgg.png"))
    print(len(egg.parts), "parts")


def game():
    O.EGGS = [("LivingBirch", living_birch_egg)]
    O.main("LivingBirch", preview=OUT)


if __name__ == "__main__":
    game() if sys.argv[1:2] == ["game"] else main(*sys.argv[1:])
