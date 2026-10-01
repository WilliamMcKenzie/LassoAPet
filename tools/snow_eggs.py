"""Eggs for the snow pets, in take C's style (tools/horse_egg_takes.py round 3,
same as tools/desert_eggs.py): the octo shell, a coloured base, bold markings and
each animal's own feature. No faces and no flat plates: every detail is a block
or wedge with depth.

  Penguin    Uncommon   black with a white belly, an orange beak, orange feet, flippers on the sides
  Snowman    Rare       three snowballs (shaded undersides), coal buttons, a carrot nose,
                        twig arms and a tiny top hat
  PolarBear  Epic       cream with a grey base, round ears, paws gripping the sides with
                        blue claws, a pale hump down the back
  IceWyvern  Legendary  cyan with white bands, pale-ice antlers with forward tines,
                        folded wings on the sides, ice spikes down the back

Run from the repo root: python3 tools/snow_eggs.py
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png (cropped, for the reveal card) and previews in
/mnt/project-files/eggs/c_style/snow/.
"""

import copy
import math
import os
import sys

import numpy as np

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import egg_designs as E  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import LH, WIDTHS, shell, back_ridge, paint  # noqa: E402
from egg_designs import H  # noqa: E402
from partlib import Part, T, Ry, Rz, look_at, render  # noqa: E402
from desert_eggs import fin  # noqa: E402
import bbmodel_to_luau  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")


def sides(fn):
    """Call fn(side, sx, X) for the left (-X) and right (+X) side; X(a0, a1)
    gives the sorted x range for distances a0, a1 out from the middle."""
    for side, sx in (("L", -1), ("R", 1)):
        fn(side, sx, lambda a0, a1, sx=sx: sorted((sx * a0, sx * a1)))


def wedge(egg, name, lo, hi, color, rot=None, frame=None):
    """A WedgePart filling the box lo..hi, turned by rot about its own centre;
    lo/hi are in `frame`'s space (default: the egg's)."""
    size = [h - l for l, h in zip(lo, hi)]
    mid = [(l + h) / 2 for l, h in zip(lo, hi)]
    cf = (frame if frame is not None else T()) @ T(*mid) @ (rot if rot is not None else T())
    p = Part(name, size, cf, color, "Wedge")
    p.bone = "top" if cf[1, 3] > E.SPLIT else "bottom"
    egg.parts.append(p)
    return p


def penguin_egg():
    black, white, orange, dark_orange = (34, 36, 50), (246, 246, 248), (255, 150, 40), (226, 110, 24)
    egg = shell([black] * 7)
    # the white belly down the front, up to a white face patch under the beak
    paint(egg, white, *(f"L{i}Front" for i in range(6)))
    # beak out the front of the lid, a step down at the tip
    zf = -WIDTHS[5] / 2
    egg.block("Beak", (-0.18, 2.38, zf - 0.3), (0.18, 2.62, zf + 0.05), orange)
    egg.block("BeakTip", (-0.1, 2.36, zf - 0.48), (0.1, 2.52, zf - 0.3), dark_orange)

    # flippers hanging off the sides, flaring out at the tip
    def flipper(side, sx, X):
        a = WIDTHS[3] / 2
        xa, xb = X(a - 0.05, a + 0.16)
        egg.block("Flipper" + side, (xa, 1.1, -0.3), (xb, 1.74, 0.3), black)
        xa, xb = X(a + 0.04, a + 0.28)
        egg.block("FlipperMid" + side, (xa, 0.72, -0.24), (xb, 1.1, 0.26), black)
        xa, xb = X(a + 0.14, a + 0.36)
        egg.block("FlipperTip" + side, (xa, 0.45, -0.16), (xb, 0.72, 0.22), black)
    sides(flipper)

    # orange feet poking out at the base, three toes each
    def foot(side, sx, X):
        z0 = -WIDTHS[0] / 2
        x0, x1 = X(0.08, 0.56)
        egg.block("Foot" + side, (x0, 0, z0 - 0.25), (x1, 0.16, z0 + 0.3), orange)
        for k, a in enumerate((0.08, 0.26, 0.44)):
            xa, xb = X(a, a + 0.12)
            egg.block(f"Toe{side}{k}", (xa, 0, z0 - 0.42), (xb, 0.12, z0 - 0.25), dark_orange)
    sides(foot)
    # a stubby tail at the back
    z = WIDTHS[0] / 2
    egg.block("Tail", (-0.22, 0.04, z - 0.05), (0.22, 0.3, z + 0.28), black)
    return egg


def snowman_egg():
    snow, shade, coal, carrot, twig, hat, band = ((248, 250, 253), (204, 220, 238), (44, 44, 54), (255, 140, 36),
                                                 (112, 72, 42), (36, 36, 44), (200, 40, 50))
    # three snowballs stacked: layers 0-2, 3-4 and 5-6, each with a shaded underside
    egg = shell([shade, snow, snow, shade, snow, shade, snow])
    # coal buttons down the front of the body
    for k, i in enumerate((2, 3, 4)):
        zf = -WIDTHS[i] / 2
        ym = (i + 0.5) * LH
        egg.block(f"Button{k}", (-0.12, ym - 0.12, zf - 0.12), (0.12, ym + 0.12, zf + 0.05), coal)
    # carrot nose poking out of the head, stepping down to a point
    zf, y = -WIDTHS[5] / 2, 5 * LH + 0.15
    egg.block("Carrot0", (-0.14, y, zf - 0.22), (0.14, y + 0.26, zf + 0.05), carrot)
    egg.block("Carrot1", (-0.1, y + 0.04, zf - 0.44), (0.1, y + 0.22, zf - 0.22), carrot)
    egg.block("Carrot2", (-0.06, y + 0.08, zf - 0.62), (0.06, y + 0.18, zf - 0.44), carrot)

    # twig arms out of the sides of the middle ball, each forked up at the end
    def arm(side, sx, X):
        a, y = WIDTHS[3] / 2, 3 * LH + 0.08
        xa, xb = X(a - 0.05, a + 0.62)
        egg.block("Arm" + side, (xa, y, -0.07), (xb, y + 0.14, 0.07), twig)
        xa, xb = X(a + 0.48, a + 0.62)
        egg.block("Hand" + side, (xa, y + 0.14, -0.07), (xb, y + 0.48, 0.07), twig)
        xa, xb = X(a + 0.22, a + 0.34)
        egg.block("Twig" + side, (xa, y + 0.14, -0.06), (xb, y + 0.34, 0.06), twig)
    sides(arm)
    # a tiny top hat with a red band
    egg.block("HatBrim", (-0.44, H - 0.03, -0.44), (0.44, H + 0.06, 0.44), hat).bone = "top"
    egg.block("HatBand", (-0.3, H + 0.06, -0.3), (0.3, H + 0.16, 0.3), band).bone = "top"
    egg.block("HatCrown", (-0.28, H + 0.16, -0.28), (0.28, H + 0.56, 0.28), hat).bone = "top"
    return egg


def polar_bear_egg():
    cream, base, inner, claw, hump = (248, 246, 238), (176, 186, 200), (214, 200, 198), (58, 168, 228), (226, 230, 238)
    egg = shell([base, cream, cream, cream, cream, cream, cream])

    # round ears on the lid's shoulders: stepped in at the top so they read round
    def ear(side, sx, X):
        y0 = 6 * LH - 0.03
        xa, xb = X(0.3, 0.92)
        egg.block("Ear" + side, (xa, y0, -0.16), (xb, y0 + 0.62, 0.16), cream).bone = "top"
        xa, xb = X(0.38, 0.84)
        egg.block("EarMid" + side, (xa, y0 + 0.62, -0.16), (xb, y0 + 0.74, 0.16), cream).bone = "top"
        xa, xb = X(0.48, 0.74)
        egg.block("EarCap" + side, (xa, y0 + 0.74, -0.16), (xb, y0 + 0.82, 0.16), cream).bone = "top"
        xa, xb = X(0.44, 0.78)
        egg.block("EarIn" + side, (xa, y0 + 0.3, -0.21), (xb, y0 + 0.66, -0.16), inner).bone = "top"
    sides(ear)

    # paws gripping the sides of the body, three blue claws hooking round the front
    def paw(side, sx, X):
        a = WIDTHS[2] / 2
        y0 = 2 * LH + 0.02
        xa, xb = X(a - 0.05, a + 0.3)
        egg.block("Paw" + side, (xa, y0, -0.55), (xb, y0 + 0.62, 0.25), cream)
        xa, xb = X(a - 0.02, a + 0.24)
        egg.block("Pad" + side, (xa, y0 + 0.08, 0.25), (xb, y0 + 0.54, 0.35), hump)
        for k in range(3):
            y = y0 + 0.06 + k * 0.2
            xa, xb = X(a - 0.18, a + 0.22)
            egg.block(f"Claw{side}{k}", (xa, y, -0.7), (xb, y + 0.11, -0.55), claw)
            xa, xb = X(a - 0.3, a - 0.1)
            egg.block(f"ClawTip{side}{k}", (xa, y, -0.82), (xb, y + 0.11, -0.66), claw)
    sides(paw)
    # the pet's pale hump down the back
    back_ridge(egg, hump, range(2, 6), name="Hump", out=0.14, hw=0.45)
    return egg


def ice_wyvern_egg():
    cyan, white, deep, ice, membrane = (44, 190, 226), (238, 248, 255), (24, 110, 168), (214, 236, 248), (176, 226, 246)
    egg = shell([deep, cyan, white, cyan, cyan, white, cyan])

    # antlers: a beam up from the crown, leaning out, with three tines pointing forward
    def antler(side, sx, X):
        y0 = H - 0.05
        xa, xb = X(0.2, 0.38)
        egg.block(f"Antler{side}0", (xa, y0, 0.0), (xb, y0 + 0.5, 0.18), ice).bone = "top"
        xa, xb = X(0.28, 0.46)
        egg.block(f"Antler{side}1", (xa, y0 + 0.5, 0.0), (xb, y0 + 1.0, 0.18), ice).bone = "top"
        for k, (y, length, x0) in enumerate(((y0 + 0.28, 0.36, 0.2), (y0 + 0.6, 0.42, 0.28), (y0 + 0.86, 0.48, 0.28))):
            xa, xb = X(x0, x0 + 0.16)
            wedge(egg, f"Tine{side}{k}", (xa, y, -length), (xb, y + 0.16, 0.02), ice).bone = "top"
        # the beam's top bends back
        xa, xb = X(0.28, 0.46)
        egg.block(f"Antler{side}2", (xa, y0 + 0.86, 0.18), (xb, y0 + 1.02, 0.38), ice).bone = "top"
    sides(antler)

    # small wings folded against the sides: a cyan arm, two ice membranes hanging off it
    def wing(side, sx, X):
        a = WIDTHS[3] / 2
        y = 3 * LH + 0.2
        xa, xb = X(a - 0.05, a + 0.22)
        egg.block("WingShoulder" + side, (xa, y - 0.08, -0.6), (xb, y + 0.24, -0.25), cyan)
        xa, xb = X(a + 0.06, a + 0.2)
        egg.block("WingClaw" + side, (xa, y + 0.24, -0.58), (xb, y + 0.42, -0.42), white)
        # spar and membranes run back from the shoulder, swept out 28 degrees
        frame = T(sx * (a + 0.1), y, -0.4) @ Ry(sx * 28)
        wedge(egg, "WingSpar" + side, (-0.09, 0, 0), (0.09, 0.24, 1.35), cyan, Ry(180), frame)
        wedge(egg, "WingA" + side, (-0.05, -0.6, 0.05), (0.05, 0, 0.7), membrane, Rz(180), frame)
        wedge(egg, "WingB" + side, (-0.05, -0.85, 0.62), (0.05, 0, 1.3), membrane, Rz(180), frame)
    sides(wing)
    # ice spikes down the back
    for i in (1, 2, 3, 4, 5):
        fin(egg, f"Spike{i}", i * LH + 0.05, (i + 1) * LH + (0.2 if i % 2 else 0.05), 0.42 if i % 2 else 0.28, 0.13, ice)
    return egg


EGGS = [("Penguin", penguin_egg), ("Snowman", snowman_egg), ("PolarBear", polar_bear_egg), ("IceWyvern", ice_wyvern_egg)]
RENDER_VIEW = C.VIEWS[0]
SCALE_EGG = ("Horse", C.take_c)


def moved(parts, dx):
    out = []
    for p in parts:
        q = copy.copy(p)
        q.cf = p.cf.copy()
        q.cf[0, 3] += dx
        out.append(q)
    return out


def main(preview="/mnt/project-files/eggs/c_style/snow"):
    os.makedirs(os.path.join(preview, "renders"), exist_ok=True)
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    tile = 360
    sheet = Image.new("RGB", (tile * len(EGGS), tile * 2 + 50), (236, 236, 236))
    d = ImageDraw.Draw(sheet)
    bb_dir = os.path.join(ROOT, "designs", "eggs", "c_style")
    eggs = []
    for c, (kind, fn) in enumerate(EGGS):
        egg = fn()
        eggs.append((kind, egg))
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
    sheet.save(os.path.join(preview, "snow_eggs.png"))

    # lineup: an existing egg for scale, then the four snow eggs, in one scene.
    # The camera looks down +Z, so screen-right is -X: lay the row out along -X.
    row = [(SCALE_EGG[0] + " (scale)", SCALE_EGG[1]())] + eggs
    gap = 3.6
    xs = [gap * ((len(row) - 1) / 2 - k) for k in range(len(row))]
    parts = []
    for x, (_, egg) in zip(xs, row):
        parts += moved(egg.parts, x)
    W, Hh, fov = 1600, 520, 30
    eye, target = (-2.0, 5.5, -17.0), (0, 1.9, 0)
    im = render(parts, eye=eye, target=target, W=W, H=Hh, fov=fov)
    out = Image.new("RGB", (W, Hh + 44), (236, 236, 236))
    out.paste(im, (0, 44))
    d = ImageDraw.Draw(out)
    small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    eye_, r, u, f = look_at(eye, target)
    focal = (Hh / 2) / math.tan(math.radians(fov) / 2)
    for x, (label, _) in zip(xs, row):
        p = np.array([x, 1.6, 0.0]) - eye_
        sx = W / 2 + focal * (p @ r) / (p @ f)
        w = d.textlength(label, font=small)
        d.text((sx - w / 2, 10), label, fill=(30, 30, 30), font=small)
    out.save(os.path.join(preview, "snow_lineup.png"))

if __name__ == "__main__":
    main(*sys.argv[1:])
