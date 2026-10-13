"""The Bloated Mummy's egg, in take C's style (tools/ocean_eggs.py): the octo shell wound in
bandages in the mummy's cream and two sand tones (tools/bloated_mummy.py), with two proud wraps
and a gold-and-lapis broad collar just under the crack. On the front of the cap a dark eye slit
holds two mismatched white plate eyes with glowing green pupils, with a bandage slipped down
across one; a little gold scarab amulet with lapis wings and a red sun hangs below the collar.
A gold headband with a lapis gem rings the cap, a knot sits on top, and two loose bandage ends
hang down the back. A torn hole on the left glows green with wisps drifting out; a teal scarab
crawls up the right.

Run from the repo root: python3 tools/bloated_mummy_egg.py
Writes designs/eggs/c_style/BloatedMummyEgg.bbmodel, src/shared/Eggs/BloatedMummyEggModel.luau,
assets/ui/BloatedMummyEggRender.png and previews in /mnt/project-files/world2/tomb/bloated_mummy/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, front_plate, shell  # noqa: E402
from temple_fox_egg import turned_box  # noqa: E402
from bloated_mummy import WRAP, SAND, SAND2, GAP, GLOW, WHITE, GOLD, GOLD_DARK, LAPIS, CARNELIAN, TEAL, BEETLE  # noqa: E402


def mummy_egg():
    egg = shell([SAND2, WRAP, SAND, WRAP, WRAP, SAND, WRAP])
    top = N * LH

    # proud wraps, and the broad collar just under the crack (gold over lapis)
    octo_layer(egg, "WrapA", 0.6, 0.82, WIDTHS[1] + 0.14, SAND2, "bottom")
    octo_layer(egg, "Collar", 1.62, 1.8, WIDTHS[3] + 0.14, GOLD, "bottom")
    octo_layer(egg, "CollarLapis", 1.5, 1.62, WIDTHS[3] + 0.1, LAPIS, "bottom")
    octo_layer(egg, "Headband", 2.56, 2.7, WIDTHS[5] + 0.1, GOLD, "top")

    # the face: a dark slit with mismatched googly eyes, a bandage slipped over the right one
    zf = -WIDTHS[4] / 2
    front_plate(egg, "EyeSlit", -0.62, 0.62, 1.9, 2.26, GAP, depth=0.03)
    egg.block("EyeL", (-0.52, 1.86, zf - 0.07), (-0.1, 2.28, zf - 0.03), WHITE).plain = True
    egg.block("GlowPupilL", (-0.4, 1.94, zf - 0.1), (-0.2, 2.14, zf - 0.07), GLOW)
    egg.block("EyeR", (0.12, 1.92, zf - 0.07), (0.44, 2.24, zf - 0.03), WHITE).plain = True
    egg.block("GlowPupilR", (0.2, 1.98, zf - 0.1), (0.36, 2.14, zf - 0.07), GLOW)
    turned_box(egg, "Slipped", (0.3, 2.1, zf), (-0.07, -0.3, -0.16), (0.07, 0.3, -0.11), -60, SAND2)
    egg.block("Mouth", (-0.3, 1.84, zf - 0.04), (-0.12, 1.88, zf - 0.02), GAP).plain = True

    # scarab amulet below the collar
    za = -WIDTHS[2] / 2
    egg.block("AmuletSun", (-0.1, 1.3, za - 0.08), (0.1, 1.46, za), CARNELIAN)
    egg.block("AmuletBody", (-0.16, 0.98, za - 0.1), (0.16, 1.3, za), GOLD)
    egg.block("AmuletGem", (-0.07, 1.08, za - 0.14), (0.07, 1.2, za - 0.1), TEAL)
    for s, sx in (("L", -1), ("R", 1)):
        turned_box(egg, "AmuletWing" + s, (sx * 0.16, 1.14, za), (0, -0.07, -0.07), (sx * 0.38, 0.07, 0), sx * 18, LAPIS)
    egg.block("HeadGem", (-0.1, 2.56, -WIDTHS[5] / 2 - 0.12), (0.1, 2.74, -WIDTHS[5] / 2 - 0.05), LAPIS)

    # knot on top, two loose ends down the back
    egg.block("Knot", (-0.18, top, -0.14), (0.18, top + 0.16, 0.14), SAND2).bone = "top"
    zb = WIDTHS[5] / 2
    for s, sx, ang in (("L", -1, -10), ("R", 1, 14)):
        turned_box(egg, "Loose" + s + "1", (sx * 0.2, 2.75, zb + 0.02), (-0.1, -0.5, 0), (0.1, 0, 0.05), ang, SAND if s == "L" else SAND2)
        turned_box(egg, "Loose" + s + "2", (sx * 0.2 + sx * 0.06, 2.27, WIDTHS[4] / 2 + 0.02), (-0.1, -0.45, 0), (0.1, 0, 0.05),
                   ang * 2, SAND if s == "L" else SAND2)

    # torn hole on the left, glowing, wisps drifting up
    xl = -WIDTHS[2] / 2
    egg.block("PlainHole", (xl - 0.03, 0.98, -0.25), (xl, 1.3, 0.15), GAP).plain = True
    egg.block("GlowHole", (xl - 0.05, 1.06, -0.15), (xl - 0.03, 1.22, 0.05), GLOW)
    for j, (dy, dx, sz) in enumerate([(0.35, 0.15, 0.1), (0.6, 0.28, 0.07)]):
        egg.block(f"GlowWisp{j + 1}", (xl - dx - sz, 1.14 + dy - sz / 2, -0.1 - sz / 2), (xl - dx, 1.14 + dy + sz / 2, -0.1 + sz / 2), GLOW)
    # teal scarab crawling up the right side
    xr = WIDTHS[1] / 2
    egg.block("ScarabShell", (xr, 0.55, -0.12), (xr + 0.12, 0.85, 0.12), TEAL)
    egg.block("ScarabHead", (xr + 0.01, 0.85, -0.07), (xr + 0.1, 0.95, 0.07), BEETLE)
    egg.block("ScarabBand", (xr + 0.005, 0.66, -0.13), (xr + 0.125, 0.7, 0.13), GOLD_DARK)

    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.plain = True
            p.neon = True
    return egg


if __name__ == "__main__":
    O.EGGS = [("BloatedMummy", mummy_egg)]
    O.main("BloatedMummy", preview="/mnt/project-files/world2/tomb/bloated_mummy")
