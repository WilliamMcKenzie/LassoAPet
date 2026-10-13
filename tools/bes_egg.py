"""Bes's egg (World 2 Ancient Tomb Legendary), in take C's style (tools/ocean_eggs.py) but
carved as Bes himself: a sandstone shell on a gold base under a gold nemes cap with a blue
band, two glowing turquoise eyes in dark sockets with blue kohl lines and an angry brow, a
lion nose and a dark mouth, a braided gold-and-blue false beard, striped lappets down the
sides, a gold usekh collar ring with turquoise and blue bands, a glowing scarab and a
glowing crack on the front, a ruby cobra on the brow, and his crown of five fanned plumes
on top with glowing tips.

Run from the repo root: python3 tools/bes_egg.py
Writes designs/eggs/c_style/BesEgg.bbmodel, src/shared/Eggs/BesEggModel.luau,
assets/ui/BesEggRender.png and previews in /mnt/project-files/world2/tomb/bes/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, front_plate, shell  # noqa: E402
from partlib import Part, T, Rz  # noqa: E402
from bes import SAND, SAND2, GLYPH, GOLD, GOLD2, LAPIS, TURQ, RUBY, GLOW, DARK  # noqa: E402

TOP = N * LH


def bes_egg():
    egg = shell([GOLD2, SAND, SAND2, SAND, SAND, SAND, GOLD])

    def blk(name, lo, hi, color, bone="top"):
        p = egg.block(name, lo, hi, color)
        p.bone = bone
        if name.startswith("Glow"):
            p.plain = True
            p.neon = True
        return p

    # nemes band round the brow, the gold cap above it
    octo_layer(egg, "NemesBand", 6 * LH - 0.15, 6 * LH - 0.03, WIDTHS[5] + 0.08, LAPIS, "top")
    # usekh collar: a gold ring, turquoise and blue bands on the front under it
    octo_layer(egg, "Collar", 3 * LH - 0.06, 3 * LH + 0.08, WIDTHS[2] + 0.08, GOLD, "bottom")
    front_plate(egg, "CollarTurq", -0.8, 0.8, 3 * LH - 0.2, 3 * LH - 0.06, TURQ, depth=0.08, plain=False)
    front_plate(egg, "CollarLapis", -0.6, 0.6, 3 * LH - 0.32, 3 * LH - 0.2, LAPIS, depth=0.08, plain=False)

    # face on the brow layer: sockets, glowing eyes, kohl lines, angry brow
    zf = -WIDTHS[5] / 2
    for side, sx in (("L", -1), ("R", 1)):
        x = sorted((sx * 0.1, sx * 0.62))
        blk("EyeSocket" + side, (x[0], 5 * LH + 0.06, zf - 0.04), (x[1], 5 * LH + 0.3, zf + 0.02), GLYPH)
        x = sorted((sx * 0.16, sx * 0.56))
        blk("GlowEye" + side, (x[0], 5 * LH + 0.1, zf - 0.07), (x[1], 5 * LH + 0.27, zf - 0.03), GLOW)
        x = sorted((sx * 0.14, sx * 0.76))
        blk("Kohl" + side, (x[0], 5 * LH + 0.02, zf - 0.07), (x[1], 5 * LH + 0.07, zf - 0.02), LAPIS)
        p = Part("Brow" + side, np.array([0.56, 0.12, 0.1]), T(sx * 0.36, 5 * LH + 0.34, zf - 0.08) @ Rz(sx * 14), DARK)
        p.bone = "top"
        egg.parts.append(p)
    # lion nose and mouth on the layer below, the braided false beard under them
    zm = -WIDTHS[4] / 2
    blk("Nose", (-0.14, 5 * LH - 0.22, zm - 0.12), (0.14, 5 * LH + 0.04, zm), SAND2)
    blk("Mouth", (-0.3, 4 * LH + 0.1, zm - 0.04), (0.3, 4 * LH + 0.18, zm + 0.01), GLYPH)
    blk("Beard", (-0.14, 4 * LH - 0.3, zm - 0.18), (0.14, 4 * LH + 0.08, zm - 0.04), LAPIS)
    blk("BeardTip", (-0.18, 4 * LH - 0.44, zm - 0.2), (0.18, 4 * LH - 0.3, zm - 0.02), GOLD)
    # striped lappets down both sides
    for side, sx in (("L", -1), ("R", 1)):
        xo = sx * WIDTHS[4] / 2
        x = sorted((xo, xo + sx * 0.06))
        for i in range(3):
            y0 = 4 * LH + 0.04 + i * 0.14
            blk(f"Lappet{side}{i + 1}", (x[0], y0, -0.3), (x[1], y0 + 0.14, 0.3), GOLD if i % 2 else LAPIS)

    # ruby cobra on the brow
    zt = -WIDTHS[6] / 2
    blk("Uraeus", (-0.08, 6 * LH, zt - 0.08), (0.08, 6 * LH + 0.32, zt + 0.02), GOLD)
    blk("UraeusGem", (-0.06, 6 * LH + 0.18, zt - 0.12), (0.06, 6 * LH + 0.28, zt - 0.08), RUBY)

    # glowing scarab low on the front, a glowing crack climbing from it
    z2 = -WIDTHS[1] / 2
    blk("GlowScarab", (-0.16, LH + 0.12, z2 - 0.07), (0.16, LH + 0.36, z2 + 0.02), GLOW, "bottom")
    for side, sx in (("L", -1), ("R", 1)):
        x = sorted((sx * 0.16, sx * 0.34))
        blk("ScarabWing" + side, (x[0], LH + 0.16, z2 - 0.05), (x[1], LH + 0.32, z2 + 0.02), TURQ, "bottom")
    z3 = -WIDTHS[3] / 2
    for i, (x0, y0, x1, y1) in enumerate(((0.3, 3 * LH + 0.12, 0.36, 3 * LH + 0.42), (0.36, 3 * LH + 0.36, 0.56, 3 * LH + 0.42),
                                          (0.5, 3 * LH + 0.42, 0.56, 4 * LH - 0.02))):
        blk(f"GlowCrack{i + 1}", (x0, y0, z3 - 0.05), (x1, y1, z3 + 0.02), GLOW, "bottom")

    # Bes's plume crown: five feathers fanned up from a gold base with a ruby band
    blk("CrownBase", (-0.34, TOP, -0.2), (0.34, TOP + 0.12, 0.2), GOLD2)
    blk("CrownBand", (-0.36, TOP + 0.03, -0.22), (0.36, TOP + 0.09, 0.22), RUBY)
    for i, ang in enumerate((-30, -15, 0, 15, 30)):
        h = 0.95 - abs(ang) / 30 * 0.25
        r = Rz(-ang)
        d = r[:3, :3] @ np.array([0, 1, 0])
        base = np.array([ang / 15 * 0.12, TOP + 0.1, 0])
        for name, size, at, col, neon in ((f"Plume{i + 1}", (0.13, h, 0.1), base + d * h / 2, GOLD if i % 2 == 0 else TURQ, False),
                                          (f"GlowPlumeTip{i + 1}", (0.14, 0.14, 0.11), base + d * (h + 0.07), GLOW, True)):
            p = Part(name, np.array(size), T(*at) @ r, col)
            p.bone = "top"
            p.neon = p.plain = neon
            egg.parts.append(p)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Bes", bes_egg)]
    O.main("Bes", preview="/mnt/project-files/world2/tomb/bes")
