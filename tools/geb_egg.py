"""Geb's egg, in take C's style (tools/ocean_eggs.py): the octo shell on a gold base, the
bull's green-brown earth below split by glowing green cracks, a turquoise collar band, the
god's green skin above with glowing gold eyes lined in black kohl, and a gold-and-green
striped nemes for the cap with a lapis headband and striped lappets down the sides. A gold
goose stands on top with a glowing sun disc behind it.

Run from the repo root: python3 tools/geb_egg.py
Writes designs/eggs/c_style/GebEgg.bbmodel, src/shared/Eggs/GebEggModel.luau,
assets/ui/GebEggRender.png and previews in /mnt/project-files/world2/tomb/geb/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, front_plate, shell  # noqa: E402
from geb import GOLD, EARTH, EARTH_DK, SKIN, SKIN_DK, TURQ, LAPIS, LIFE, EYE, DARK, ORANGE  # noqa: E402


def geb_egg():
    egg = shell([GOLD, EARTH_DK, EARTH, EARTH, SKIN, GOLD, GOLD])
    top = N * LH

    # turquoise collar between the earth and the god, a lapis headband under the nemes
    octo_layer(egg, "Collar", 3 * LH - 0.07, 3 * LH + 0.07, WIDTHS[2] + 0.1, TURQ, "bottom")
    octo_layer(egg, "Headband", 5 * LH - 0.06, 5 * LH + 0.06, WIDTHS[4] + 0.08, LAPIS, "top")

    # glowing green life cracks up the earth
    for name, x0, x1, y0, y1 in (("GlowCrackA", -0.55, -0.45, 1.1 * LH, 2.4 * LH), ("GlowCrackB", -0.55, -0.2, 2.3 * LH, 2.45 * LH),
                                 ("GlowCrackC", -0.3, -0.2, 2.45 * LH, 2.9 * LH), ("GlowCrackD", 0.35, 0.45, 1.3 * LH, 2.0 * LH),
                                 ("GlowCrackE", 0.45, 0.75, 1.9 * LH, 2.0 * LH)):
        front_plate(egg, name, x0, x1, y0, y1, LIFE, depth=0.05)

    # glowing gold eyes with black kohl liner flicking out at the sides
    for s in (-1, 1):
        side = "LR"[s > 0]
        xa, xb = sorted((s * 0.18, s * 0.6))
        front_plate(egg, "GlowEye" + side, xa, xb, 4.35 * LH, 4.7 * LH, EYE, depth=0.05)
        c = s * 0.39
        front_plate(egg, "Pupil" + side, c - 0.07, c + 0.07, 4.38 * LH, 4.67 * LH, DARK, depth=0.07)
        xa, xb = sorted((s * 0.15, s * 0.78))
        front_plate(egg, "PlainLiner" + side, xa, xb, 4.7 * LH, 4.82 * LH, DARK, depth=0.06)
        xa, xb = sorted((s * 0.6, s * 0.82))
        front_plate(egg, "PlainLinerTail" + side, xa, xb, 4.22 * LH, 4.35 * LH, DARK, depth=0.06)

    # nemes stripes down the front of the cap
    for k, x in enumerate((-0.6, -0.2, 0.2, 0.6)):
        front_plate(egg, f"NemesStripe{k + 1}", x - 0.08, x + 0.08, 5.1 * LH, 6.0 * LH, SKIN_DK, depth=0.05, plain=False)
    # striped lappets hanging down the sides of the face
    for s in (-1, 1):
        side = "LR"[s > 0]
        x0, x1 = sorted((s * WIDTHS[4] / 2, s * (WIDTHS[4] / 2 + 0.14)))
        for k, c in enumerate((GOLD, SKIN_DK, GOLD)):
            y1 = 5 * LH - k * 0.32
            egg.block(f"Lappet{side}{k + 1}", (x0, y1 - 0.32, -0.45), (x1, y1, 0.05), c).bone = "top"

    # gold goose on the top, a glowing sun disc behind it
    egg.block("GooseBody", (-0.22, top - 0.04, -0.2), (0.22, top + 0.26, 0.3), GOLD).bone = "top"
    egg.block("GooseTail", (-0.16, top + 0.12, 0.3), (0.16, top + 0.3, 0.44), GOLD).bone = "top"
    egg.block("GooseNeck", (-0.08, top + 0.26, -0.24), (0.08, top + 0.68, -0.08), GOLD).bone = "top"
    egg.block("GooseHead", (-0.11, top + 0.62, -0.34), (0.11, top + 0.82, -0.06), GOLD).bone = "top"
    egg.block("GooseBeak", (-0.05, top + 0.66, -0.5), (0.05, top + 0.74, -0.34), ORANGE).bone = "top"
    for s in (-1, 1):
        x0, x1 = sorted((s * 0.11, s * 0.125))
        egg.block("PlainGooseEye" + "LR"[s > 0], (x0, top + 0.72, -0.28), (x1, top + 0.78, -0.22), DARK).bone = "top"
    egg.block("GlowSunDisc", (-0.3, top + 0.2, 0.44), (0.3, top + 0.8, 0.5), ORANGE).bone = "top"

    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.plain = True
            p.neon = True
    return egg


if __name__ == "__main__":
    O.EGGS = [("Geb", geb_egg)]
    O.main("Geb", preview="/mnt/project-files/world2/tomb/geb")
