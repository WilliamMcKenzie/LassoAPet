"""Eggs for the desert pets, in take C's style (tools/horse_egg_takes.py round 3):
the octo shell, a coloured base, bold markings and each animal's own feature.
No faces and no flat plates: every detail is a block or wedge with depth.

  Cactus    Uncommon   in a terracotta pot, ribbed green, one arm up and one down, spines
  Scorpion  Rare       banded shell, two pincers out front, tail up the back and over the top
  Sandworm  Epic       banded like the worm, four dark mandibles bursting out of the top, back fins
  Snake     Legendary  gold with maroon bands, swept-back teal horns, a crest and back spikes

Run: python3 tools/desert_eggs.py
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png (cropped, for the reveal card) and previews in
/mnt/project-files/eggs/c_style/.
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import egg_designs as E  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell, back_ridge  # noqa: E402
from egg_designs import H  # noqa: E402
from partlib import Part, T, Ry, render  # noqa: E402
import bbmodel_to_luau  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")


def fin(egg, name, y0, y1, out, hw, color, z=None):
    """A swept fin on the egg's back: tall against the shell, sloping down and out."""
    i = min(int((y0 + y1) / 2 / LH), N - 1)
    z = WIDTHS[i] / 2 - 0.05 if z is None else z
    p = Part(name, (2 * hw, y1 - y0, out), T(0, (y0 + y1) / 2, z + out / 2) @ Ry(180), color, "Wedge")
    p.bone = "top" if (y0 + y1) / 2 > E.SPLIT else "bottom"
    egg.parts.append(p)
    return p


def ribs(egg, color, layers, hw=0.1, out=0.08):
    """Raised ridges down the front, back and both sides."""
    for i in layers:
        a = WIDTHS[i] / 2
        y0, y1 = i * LH, (i + 1) * LH
        egg.block(f"RibF{i}", (-hw, y0, -a - out), (hw, y1, -a + 0.05), color)
        egg.block(f"RibB{i}", (-hw, y0, a - 0.05), (hw, y1, a + out), color)
        egg.block(f"RibL{i}", (-a - out, y0, -hw), (-a + 0.05, y1, hw), color)
        egg.block(f"RibR{i}", (a - 0.05, y0, -hw), (a + out, y1, hw), color)


def cactus_egg():
    green, rib, spine = (118, 204, 64), (72, 150, 44), (214, 176, 96)
    pot, pot_dark = (222, 120, 70), (176, 84, 50)
    egg = shell([pot_dark, pot, green, green, green, green, green])
    # the pot's rim
    E.octo_layer(egg, "Rim", 2 * LH - 0.2, 2 * LH, WIDTHS[1] + 0.2, pot_dark, "bottom")
    ribs(egg, rib, range(2, N))
    # arms: the left one up (on the lid), the right one down (on the bottom)
    a4, a3 = WIDTHS[4] / 2, WIDTHS[3] / 2
    y = 4 * LH + 0.1
    egg.block("ArmL", (-a4 - 0.5, y, -0.2), (-a4 + 0.05, y + 0.36, 0.2), green)
    egg.block("ForearmL", (-a4 - 0.5, y + 0.36, -0.2), (-a4 - 0.14, y + 1.0, 0.2), green)
    y = 3 * LH
    egg.block("ArmR", (a3 - 0.05, y, -0.2), (a3 + 0.5, y + 0.36, 0.2), green)
    egg.block("ForearmR", (a3 + 0.14, y - 0.5, -0.2), (a3 + 0.5, y, 0.2), green)
    # three spines on top
    for k, (x, h) in enumerate(((-0.25, 0.4), (0, 0.55), (0.25, 0.4))):
        egg.block(f"Spine{k}", (x - 0.06, H - 0.05, -0.06), (x + 0.06, H + h, 0.06), spine).bone = "top"
    return egg


def scorpion_egg():
    shell_c, dark, joint, sting = (230, 160, 74), (184, 110, 50), (160, 70, 60), (70, 44, 40)
    egg = shell([dark, shell_c, shell_c, dark, shell_c, dark, shell_c])
    # pincers out the front on the bottom half: arm, hand, long outer finger, short inner one
    y0 = 3 * LH + 0.05
    for side, sx in (("L", -1), ("R", 1)):
        def X(a0, a1):
            return sorted((sx * a0, sx * a1))
        zf = -WIDTHS[3] / 2
        x0, x1 = X(0.55, 0.9)
        egg.block("Arm" + side, (x0, y0, zf - 0.35), (x1, y0 + 0.3, zf + 0.1), joint)
        x0, x1 = X(0.4, 1.05)
        egg.block("Hand" + side, (x0, y0 - 0.1, zf - 0.8), (x1, y0 + 0.4, zf - 0.35), shell_c)
        x0, x1 = X(0.8, 1.05)
        egg.block("FingerOut" + side, (x0, y0, zf - 1.35), (x1, y0 + 0.3, zf - 0.8), dark)
        x0, x1 = X(0.55, 0.8)
        egg.block("FingerOutTip" + side, (x0, y0 + 0.03, zf - 1.35), (x1, y0 + 0.27, zf - 1.15), sting)
        x0, x1 = X(0.4, 0.6)
        egg.block("FingerIn" + side, (x0, y0 + 0.03, zf - 1.05), (x1, y0 + 0.27, zf - 0.8), sting)
    # tail: plated segments up the back, over the top, the stinger hanging forward
    for i in range(1, N):
        z = WIDTHS[i] / 2
        egg.block(f"Tail{i}", (-0.24, i * LH, z - 0.05), (0.24, (i + 1) * LH, z + 0.3), joint if i % 2 else shell_c)
    egg.block("TailUp", (-0.24, H - 0.05, 0.3), (0.24, H + 0.45, 0.8), shell_c).bone = "top"
    egg.block("TailTop", (-0.24, H + 0.2, -0.3), (0.24, H + 0.55, 0.3), joint).bone = "top"
    egg.block("Stinger", (-0.14, H + 0.05, -0.62), (0.14, H + 0.45, -0.3), sting).bone = "top"
    return egg


def sandworm_egg():
    sand, plate, belly, dark, ivory = (228, 178, 104), (156, 98, 56), (248, 224, 172), (54, 40, 50), (250, 246, 232)
    egg = shell([belly, sand, plate, sand, plate, sand, plate])
    # four mandibles bursting out of the top, hooking inward, ivory tips
    t = H - 0.05
    for side, sx in (("L", -1), ("R", 1)):
        for end, sz in (("F", -1), ("B", 1)):
            def P(a0, a1, b0, b1):
                xa, xb = sorted((sx * a0, sx * a1))
                za, zb = sorted((sz * b0, sz * b1))
                return xa, za, xb, zb
            xa, za, xb, zb = P(0.32, 0.62, 0.32, 0.62)
            egg.block(f"Mand{end}{side}", (xa, t - 0.4, za), (xb, t + 0.3, zb), dark).bone = "top"
            xa, za, xb, zb = P(0.2, 0.5, 0.2, 0.5)
            egg.block(f"Mand{end}{side}Hook", (xa, t + 0.3, za), (xb, t + 0.55, zb), dark).bone = "top"
            xa, za, xb, zb = P(0.08, 0.3, 0.08, 0.3)
            egg.block(f"Mand{end}{side}Tip", (xa, t + 0.38, za), (xb, t + 0.55, zb), ivory).bone = "top"
    # dark swept fins down the back
    for i in (1, 3, 5):
        fin(egg, f"Fin{i}", i * LH + 0.05, (i + 1) * LH + 0.25, 0.45, 0.16, dark)
    return egg


def snake_egg():
    gold, cream, maroon, teal = (240, 186, 72), (252, 234, 186), (168, 48, 78), (48, 196, 214)
    egg = shell([cream, gold, maroon, gold, maroon, gold, gold])
    # swept-back horns: three steps up and back on each side of the crown
    t = H - 0.3
    for side, sx in (("L", -1), ("R", 1)):
        for k, (a0, a1, y0, y1, z0, z1) in enumerate(((0.2, 0.55, t, t + 0.5, -0.15, 0.3),
                                                      (0.26, 0.52, t + 0.4, t + 0.8, 0.2, 0.6),
                                                      (0.32, 0.48, t + 0.7, t + 1.0, 0.5, 0.85))):
            xa, xb = sorted((sx * a0, sx * a1))
            egg.block(f"Horn{side}{k}", (xa, y0, z0), (xb, y1, z1), teal).bone = "top"
    # a teal crest down the middle of the crown
    egg.block("Crest", (-0.08, H - 0.05, -0.4), (0.08, H + 0.3, 0.3), teal).bone = "top"
    # teal spikes down the back
    for i in (1, 3, 5):
        fin(egg, f"Spike{i}", i * LH + 0.05, (i + 1) * LH + 0.2, 0.42, 0.15, teal)
    return egg


EGGS = [("Cactus", cactus_egg), ("Scorpion", scorpion_egg), ("Sandworm", sandworm_egg), ("Snake", snake_egg)]
RENDER_VIEW = C.VIEWS[0]


def main(preview="/mnt/project-files/eggs/c_style"):
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    tile = 360
    sheet = Image.new("RGB", (tile * len(EGGS), tile * 2 + 50), (236, 236, 236))
    d = ImageDraw.Draw(sheet)
    bb_dir = os.path.join(ROOT, "designs", "eggs", "c_style")
    for c, (kind, fn) in enumerate(EGGS):
        egg = fn()
        name = kind + "Egg"
        C.build(egg, name, E.SPLIT, bb_dir)
        C.build(egg, name, E.SPLIT, preview)
        bbmodel_to_luau.main(os.path.join("designs", "eggs", "c_style", name + ".bbmodel"),
                             os.path.join(ROOT, "src", "shared", "Eggs", name + "Model.luau"))
        for r, view in enumerate(C.VIEWS):
            sheet.paste(render(egg.parts, W=tile, H=tile, fov=28, **view), (c * tile, 50 + r * tile))
        w = d.textlength(kind, font=font)
        d.text((c * tile + (tile - w) / 2, 10), kind, fill=(30, 30, 30), font=font)
        # the reveal card's render: same camera as the other eggs, cropped to the egg
        im = render(egg.parts, W=700, H=1100, fov=28, transparent=True, **RENDER_VIEW)
        im = im.crop(im.getbbox())
        im.save(os.path.join(ROOT, "assets", "ui", kind + "EggRender.png"))
        padded = Image.new("RGBA", (im.width + 16, im.height + 16))
        padded.paste(im, (8, 8))
        padded.save(os.path.join(preview, "renders", name + ".png"))
        print(kind, len(egg.parts), "parts, render", im.size)
    sheet.save(os.path.join(preview, "desert_eggs.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
