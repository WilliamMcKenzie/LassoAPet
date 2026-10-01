"""Eggs for the converted pets (tools/convert_designs.py), in take C's style like
the desert eggs: the octo shell, a coloured base, bold bands and each animal's own
feature. No faces and no flat plates. Twitch and hatch are the shared egg
animations (egg_designs.animations).

  Boar         brown with tan piglet bands, tusks up the front, small ears, dark mane and crest
  WhiteWolf    white over a grey base, pointed ears, grey saddle up the back, a bushy tail
  Troll        blue over fur shorts with a white trim, tusks, white topknot and ponytail
  SpineLizard  sand bands, an orange and maroon sail over the top with cream spine tips, fins down the back
  IceGolem     deep blue base, ice middle, snowy top with ice crystals bursting out
  IceDrake     cyan with white fur rings, swept-back pale horns, white spikes down the back

Run: python3 tools/convert_eggs.py
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png (cropped, for the reveal card) and previews in
/mnt/project-files/animals/converted/eggs/.
"""

import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import egg_designs as E  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell, back_ridge, ears  # noqa: E402
from egg_designs import H  # noqa: E402
from desert_eggs import fin  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402
import bbmodel_to_luau  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/converted/eggs"
SIDES = (("L", -1), ("R", 1))


def X(sx, a0, a1):
    return tuple(sorted((sx * a0, sx * a1)))


def spike(egg, name, lo, hi, axis, length, color, bone=None):
    """Square pyramid on a box footprint with no size along `axis` ('+y', '-z', ...)."""
    lo, hi = np.array(lo, float), np.array(hi, float)
    i = "xyz".index(axis[1])
    apex = (lo + hi) / 2
    apex[i] = lo[i] + (1 if axis[0] == "+" else -1) * length
    u, v = [j for j in range(3) if j != i]
    corners = []
    for du, dv in ((0, 0), (1, 0), (1, 1), (0, 1)):
        p = lo.copy()
        p[u] = hi[u] if du else lo[u]
        p[v] = hi[v] if dv else lo[v]
        corners.append(p)
    faces = [corners] + [[corners[j], corners[(j + 1) % 4], apex] for j in range(4)]
    return egg.poly(name, faces, color, bone)


def tusks(egg, color, y0=1.0, x=0.38, h=0.45, tip=0.32, w=0.22):
    """A tusk out of each side of the front: out a little, then up to a point. Bottom shell."""
    zf = -WIDTHS[2] / 2
    for side, sx in SIDES:
        x0, x1 = X(sx, x, x + w + 0.05)
        egg.block("Tusk" + side, (x0, y0, zf - 0.28), (x1, y0 + 0.2, zf + 0.05), color).bone = "bottom"
        x0, x1 = X(sx, x + 0.05, x + w + 0.05)
        egg.block("TuskUp" + side, (x0, y0 + 0.2, zf - 0.28), (x1, y0 + 0.2 + h, zf - 0.06), color).bone = "bottom"
        spike(egg, "TuskTip" + side, (x0, y0 + 0.2 + h, zf - 0.28), (x1, y0 + 0.2 + h, zf - 0.06), "+y", tip, color, "bottom")


def boar_egg():
    coat, tan, dark, hoof, ivory = (176, 108, 68), (236, 190, 136), (112, 66, 46), (86, 60, 52), (254, 246, 222)
    egg = shell([hoof, coat, tan, coat, tan, coat, coat])
    ears(egg, coat, dark, x=0.42, hw=0.3, h=0.75)
    tusks(egg, ivory)
    for k, (z, h) in enumerate(((-0.22, 0.35), (0.05, 0.5), (0.3, 0.38))):
        spike(egg, f"Crest{k}", (-0.14, H - 0.02, z - 0.14), (0.14, H - 0.02, z + 0.14), "+y", h, dark, "top")
    for i in (1, 2, 3, 4, 5):
        fin(egg, f"Mane{i}", i * LH + 0.05, (i + 1) * LH + 0.2, 0.35, 0.15, dark)
    return egg


def white_wolf_egg():
    white, grey = (244, 246, 250), (186, 200, 224)
    egg = shell([grey, white, white, white, white, white, white])
    ears(egg, white, grey, x=0.5, hw=0.3, h=0.95)
    back_ridge(egg, grey, range(2, N), name="Saddle", out=0.14, hw=0.42)
    z = WIDTHS[1] / 2
    egg.block("TailA", (-0.26, 0.5, z - 0.05), (0.26, 0.95, z + 0.45), white).bone = "bottom"
    egg.block("TailB", (-0.3, 0.85, z + 0.2), (0.3, 1.45, z + 0.75), white).bone = "bottom"
    egg.block("TailTip", (-0.26, 1.45, z + 0.25), (0.26, 1.75, z + 0.7), grey).bone = "bottom"
    return egg


def troll_egg():
    blue, fur, trim, hair, ivory = (76, 150, 234), (150, 100, 60), (250, 250, 252), (250, 250, 252), (254, 246, 226)
    egg = shell([fur, fur, blue, blue, blue, blue, blue])
    E.octo_layer(egg, "Trim", 2 * LH - 0.12, 2 * LH + 0.02, WIDTHS[2] + 0.12, trim, "bottom")
    tusks(egg, ivory, y0=1.05, x=0.32, h=0.5, tip=0.36, w=0.24)
    egg.block("Topknot", (-0.36, H - 0.05, -0.3), (0.36, H + 0.25, 0.36), hair).bone = "top"
    egg.block("Tie", (-0.2, H - 0.3, 0.36), (0.2, H + 0.05, 0.62), fur).bone = "top"
    back_ridge(egg, hair, range(2, N - 1), name="Ponytail", out=0.22, hw=0.2)
    return egg


def spine_lizard_egg():
    body, back, belly = (236, 178, 84), (206, 132, 60), (252, 234, 186)
    sail, sail2, tip = (246, 112, 40), (170, 50, 78), (254, 246, 222)
    egg = shell([belly, body, back, body, back, body, body])
    b = H - 0.05
    for k, (z0, z1, h) in enumerate(((-0.48, -0.24, 0.6), (-0.24, 0.0, 0.95), (0.0, 0.24, 1.1), (0.24, 0.48, 0.75))):
        col = sail if k % 2 == 0 else sail2
        egg.block(f"Sail{k}", (-0.14, b, z0), (0.14, b + h, z1), col).bone = "top"
        if k % 2 == 0:
            spike(egg, f"SailTip{k}", (-0.14, b + h, z0), (0.14, b + h, z1), "+y", 0.32, tip, "top")
    for i in (2, 3, 4, 5):
        fin(egg, f"Fin{i}", i * LH + 0.05, (i + 1) * LH + 0.22, 0.42, 0.13, sail if i % 2 else sail2)
    return egg


def ice_golem_egg():
    ice, deep, snow, crystal, crystal2 = (160, 218, 250), (82, 150, 226), (252, 253, 255), (96, 222, 255), (236, 250, 255)
    egg = shell([deep, deep, ice, ice, ice, snow, snow])
    t = H - 0.08
    for name, (x0, x1, z0, z1, h, col) in {
            "Crystal0": (-0.17, 0.17, -0.05, 0.3, 0.75, crystal), "Crystal1": (-0.46, -0.2, 0.0, 0.28, 0.45, crystal),
            "Crystal2": (0.2, 0.46, -0.1, 0.18, 0.55, crystal2)}.items():
        egg.block(name, (x0, t, z0), (x1, t + h, z1), col).bone = "top"
        spike(egg, name + "Tip", (x0, t + h, z0), (x1, t + h, z1), "+y", (x1 - x0) * 1.1, col, "top")
    z = WIDTHS[3] / 2
    egg.block("BackCrystal", (-0.15, 1.45, z - 0.05), (0.15, 1.75, z + 0.3), crystal).bone = "bottom"
    spike(egg, "BackCrystalTip", (-0.15, 1.45, z + 0.3), (0.15, 1.75, z + 0.3), "+z", 0.32, crystal, "bottom")
    return egg


def ice_drake_egg():
    cyan, plate, fur, horn, white = (56, 206, 238), (30, 164, 214), (252, 253, 255), (206, 236, 252), (236, 246, 255)
    egg = shell([plate, cyan, fur, cyan, fur, cyan, cyan])
    t = H - 0.3
    for side, sx in SIDES:
        for k, (a0, a1, y0, y1, z0, z1) in enumerate(((0.2, 0.55, t, t + 0.5, -0.15, 0.3),
                                                      (0.26, 0.52, t + 0.4, t + 0.8, 0.2, 0.6),
                                                      (0.32, 0.48, t + 0.7, t + 1.0, 0.5, 0.85))):
            xa, xb = X(sx, a0, a1)
            egg.block(f"Horn{side}{k}", (xa, y0, z0), (xb, y1, z1), horn if k < 2 else white).bone = "top"
    for i in (1, 3, 5):
        fin(egg, f"Spike{i}", i * LH + 0.05, (i + 1) * LH + 0.22, 0.45, 0.15, white)
    return egg


EGGS = [("Boar", boar_egg), ("WhiteWolf", white_wolf_egg), ("Troll", troll_egg),
        ("SpineLizard", spine_lizard_egg), ("IceGolem", ice_golem_egg), ("IceDrake", ice_drake_egg)]
TITLES = {"WhiteWolf": "White Wolf", "SpineLizard": "Spine Lizard", "IceGolem": "Ice Golem", "IceDrake": "Ice Drake"}


def main(preview=OUT):
    os.makedirs(os.path.join(preview, "renders"), exist_ok=True)
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    tile = 300
    sheet = Image.new("RGB", (tile * len(EGGS), tile * 2 + 44), (236, 236, 236))
    d = ImageDraw.Draw(sheet)
    bb_dir = os.path.join(ROOT, "designs", "eggs", "c_style")
    models = []
    for c, (kind, fn) in enumerate(EGGS):
        egg = fn()
        name = kind + "Egg"
        C.build(egg, name, E.SPLIT, bb_dir)
        C.build(egg, name, E.SPLIT, preview)
        models.append(json.load(open(os.path.join(bb_dir, name + ".bbmodel"))))
        bbmodel_to_luau.main(os.path.join("designs", "eggs", "c_style", name + ".bbmodel"),
                             os.path.join(ROOT, "src", "shared", "Eggs", name + "Model.luau"))
        for r, view in enumerate(C.VIEWS):
            sheet.paste(render(egg.parts, W=tile, H=tile, fov=28, **view), (c * tile, 44 + r * tile))
        title = TITLES.get(kind, kind)
        w = d.textlength(title, font=font)
        d.text((c * tile + (tile - w) / 2, 10), title, fill=(30, 30, 30), font=font)
        im = render(egg.parts, W=700, H=1100, fov=28, transparent=True, **C.VIEWS[0])
        im = im.crop(im.getbbox())
        im.save(os.path.join(ROOT, "assets", "ui", kind + "EggRender.png"))
        padded = Image.new("RGBA", (im.width + 16, im.height + 16))
        padded.paste(im, (8, 8))
        padded.save(os.path.join(preview, "renders", name + ".png"))
        print(kind, len(egg.parts), "parts")
    sheet.save(os.path.join(preview, "converted_eggs.png"))
    # twitch then hatch, all six side by side
    cam = dict(eye=(-6.5, 6.2, -7.5), target=(0, 2.2, 0), W=240, H=260, fov=36)
    frames = []
    for anim_name, n in (("twitch", 24), ("hatch", 40)):
        for i in range(n):
            tiles = []
            for m in models:
                anim = next(a for a in m["animations"] if a["name"] == anim_name)
                tiles.append(render(pose(m, anim, anim["length"] * i / n), **cam))
            im = Image.new("RGB", (cam["W"] * len(tiles), cam["H"]))
            for k, tl in enumerate(tiles):
                im.paste(tl, (cam["W"] * k, 0))
            frames.append(A.label(im, [anim_name] * len(tiles), 16))
    A.gif(os.path.join(preview, "converted_eggs_anims.gif"), frames, fps=20, hold=10)
    print("wrote", preview)


if __name__ == "__main__":
    main(*sys.argv[1:])
