"""Four takes on the horse egg (designs/eggs/Egg6_PonyOcto.bbmodel) with the
horse features made bigger, each leaning on a different horse feature:

  D  Mane & tail   a dark mane from the crown down the back, and a tail
  E  Horse head    a real snout sticking out the front, the horse's side eyes
  F  Horseshoe     a big gold horseshoe on the front
  G  On legs       the egg stands on four little horse legs with hooves

All keep the Octo Pony body, crack and bones, with ears 1.5x taller.

    python3 tools/horse_egg_takes.py OUT_DIR
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import egg_designs as E  # noqa: E402
from egg_designs import BROWN, CREAM, HOOF, ORANGE, PINK, BLACK, H, Egg, octo_layer, ear_half, snap, radius  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render, write_bbmodel  # noqa: E402

WHITE = (255, 255, 255)
PUPIL = (30, 30, 45)
NOSTRIL = (70, 44, 36)
GOLD = (255, 196, 40)
GOLD_DARK = (190, 120, 20)

N, CRACK_LAYER = 7, 4
LH = H / N
WIDTHS = [snap(2 * radius((i + 0.5) * LH)) for i in range(N)]


def body(ears=1.5, tuft=True):
    """The current horse egg's body and crack, with bigger ears."""
    egg = Egg()
    crack = CRACK_LAYER * LH
    for i in range(N):
        octo_layer(egg, i, i * LH, (i + 1) * LH, WIDTHS[i], CREAM if i < 2 else ORANGE,
                   "top" if i >= CRACK_LAYER else "bottom")
    inner = min(WIDTHS[CRACK_LAYER - 1], WIDTHS[CRACK_LAYER]) - 0.16
    octo_layer(egg, "InsideBottom", crack, crack + 0.02, inner, BLACK, "bottom")
    octo_layer(egg, "InsideTop", crack - 0.02, crack, inner, BLACK, "top")
    b = H - 0.05
    hw, ht = 0.25, 0.7 * ears
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * 0.35
        for half, d in (("A", -1), ("B", 1)):
            ear_half(egg, f"Ear{side}{half}", [(x0, b), (x0 + d * hw, b), (x0, b + ht)], -0.15, 0.15, ORANGE)
            ear_half(egg, f"EarIn{side}{half}", [(x0, b + 0.1), (x0 + d * hw * 0.55, b + 0.1), (x0, b + ht * 0.68)], -0.19, -0.15, PINK)
    if tuft:
        egg.block("Tuft", (-0.15, b, 0.15), (0.15, H + 0.3, 0.5), BROWN).bone = "top"
    return egg


def layer_of(y):
    return min(int(y / LH), N - 1)


def front_plate(egg, name, x0, x1, y0, y1, color, depth=0.06, plain=True):
    """A plate on the egg's front (-Z), split where it crosses layers so each
    piece sits flush on its own layer's face."""
    cuts = sorted({y0, y1} | {i * LH for i in range(N + 1) if y0 < i * LH < y1})
    for k, (a, b) in enumerate(zip(cuts, cuts[1:])):
        z = -WIDTHS[layer_of((a + b) / 2)] / 2
        p = egg.block(f"{name}{k}" if len(cuts) > 2 else name, (x0, a, z - depth), (x1, b, z), color)
        p.plain = plain


def mane_and_tail():
    egg = body(tuft=False)
    # mane: a dark crest standing off the back of the top shell, crown to crack
    for i in range(CRACK_LAYER, N):
        z = WIDTHS[i] / 2
        egg.block(f"Mane{i}", (-0.2, i * LH, z - 0.05), (0.2, (i + 1) * LH, z + 0.3), BROWN)
    egg.block("ManeTop", (-0.2, H - 0.05, -0.1), (0.2, H + 0.3, 0.8), BROWN).bone = "top"
    # tail: hangs off the lower back
    z = WIDTHS[1] / 2
    egg.block("Tail", (-0.2, 0.05, z - 0.05), (0.2, 2 * LH, z + 0.45), BROWN)
    egg.block("TailRoot", (-0.2, 2 * LH, WIDTHS[2] / 2 - 0.05), (0.2, 3 * LH, WIDTHS[2] / 2 + 0.3), BROWN)
    return egg


def horse_head():
    egg = body()
    # snout out the front of the top shell, nostrils on its tip
    zf = -WIDTHS[4] / 2
    egg.block("Snout", (-0.5, 1.95, zf - 0.6), (0.5, 2.6, -0.85), ORANGE).bone = "top"
    for sx in (-1, 1):
        a, b = sorted((sx * 0.12, sx * 0.36))
        p = egg.block(f"Nostril{'L' if sx < 0 else 'R'}", (a, 2.2, zf - 0.63), (b, 2.36, zf - 0.6), NOSTRIL)
        p.plain = True
    # eyes on the sides like the horse's, pupils toward the front
    x5 = WIDTHS[5] / 2
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * x5, sx * (x5 + 0.05)))
        egg.block("Eye" + side, (xa, 2.32, -0.4), (xb, 2.72, 0.0), WHITE).plain = True
        xa, xb = sorted((sx * x5, sx * (x5 + 0.08)))
        egg.block("Pupil" + side, (xa, 2.36, -0.4), (xb, 2.62, -0.18), PUPIL).plain = True
    return egg


def horseshoe():
    egg = body()
    y0, y1 = 0.5, 1.75
    front_plate(egg, "ShoeBase", -0.5, 0.5, y0, y0 + 0.26, GOLD, plain=False)
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.5, sx * 0.24))
        front_plate(egg, "ShoeArm" + side, xa, xb, y0 + 0.24, y1, GOLD, plain=False)
        # nail holes
        xm = sx * 0.37
        for k, y in enumerate((0.95, 1.25, 1.55)):
            front_plate(egg, f"Nail{side}{k}", xm - 0.05, xm + 0.05, y - 0.05, y + 0.05, GOLD_DARK, depth=0.08)
    return egg


LEG_LIFT = 0.5


def on_legs():
    egg = body()
    for p in egg.parts:
        if p.shape == "Poly":
            p.polys = [q + np.array([0, LEG_LIFT, 0]) for q in p.polys]
        else:
            p.cf = p.cf.copy()
            p.cf[1, 3] += LEG_LIFT
    for sx in (-1, 1):
        for sz in (-1, 1):
            n = f"{'F' if sz < 0 else 'H'}{'L' if sx < 0 else 'R'}"
            x, z = sx * 0.38, sz * 0.36
            egg.block("Leg" + n, (x - 0.17, 0.2, z - 0.17), (x + 0.17, LEG_LIFT + 0.12, z + 0.17), ORANGE).bone = "bottom"
            egg.block("Hoof" + n, (x - 0.17, 0, z - 0.17), (x + 0.17, 0.2, z + 0.17), HOOF).bone = "bottom"
    return egg


TAKES = [
    ("D", "Mane & tail", mane_and_tail, E.SPLIT),
    ("E", "Horse head", horse_head, E.SPLIT),
    ("F", "Horseshoe", horseshoe, E.SPLIT),
    ("G", "On legs", on_legs, E.SPLIT + LEG_LIFT),
]


def build(egg, name, split, out):
    bones = [("egg", None, (0, 0, 0)), ("bottom", "egg", (0, 0, 0)), ("top", "egg", (0, split, 0))]
    model, groups = write_bbmodel(egg.parts, name, None, bones=bones)
    write_animations(model, groups, E.animations())
    import json
    with open(os.path.join(out, name + ".bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))


VIEWS = [dict(eye=(-3.5, 4.6, -10.5), target=(0, 2.05, 0)), dict(eye=(7.0, 4.6, 8.2), target=(0, 2.05, 0))]


def main(out):
    os.makedirs(out, exist_ok=True)
    current = ("Now", "Current", lambda: E.octo_pony(), E.SPLIT)
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 18)
    tile = 380
    cols = [current] + TAKES
    sheet = Image.new("RGB", (tile * len(cols), tile * 2 + 50), (236, 236, 236))
    d = ImageDraw.Draw(sheet)
    for c, (key, title, fn, split) in enumerate(cols):
        egg = fn()
        if key != "Now":
            build(egg, f"HorseEgg_{key}", split, out)
        for r, view in enumerate(VIEWS):
            lift = LEG_LIFT if key == "G" else 0
            im = render(egg.parts, W=tile, H=tile, fov=26, eye=tuple(np.add(view["eye"], (0, lift, 0))),
                        target=tuple(np.add(view["target"], (0, lift, 0))))
            sheet.paste(im, (c * tile, 50 + r * tile))
        label = title if key == "Now" else f"{key}  {title}"
        w = d.textlength(label, font=font)
        d.text((c * tile + (tile - w) / 2, 10), label, fill=(30, 30, 30), font=font)
    d.text((10, 50 + tile + 6), "back", fill=(90, 90, 90), font=small)
    d.text((10, 56), "front", fill=(90, 90, 90), font=small)
    sheet.save(os.path.join(out, "compare.png"))
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "designs/eggs/horse_v3")


# ---------------------------------------------------------------- round 2: take C's style
# QM liked the Player pens thread's take C (/mnt/project-files/eggs/horse_v2/HorseEgg_C):
# big ears on the shoulders, a chunky forelock, a white blaze down the front, a
# mane down the back and a dark hoof-coloured base. These riff on it.

BLAZE = (205, 205, 200)


def take_c(ear_h=1.2, blaze_w=0.5, forelock_front=-0.62):
    egg = Egg()
    crack = CRACK_LAYER * LH
    for i in range(N):
        col = HOOF if i == 0 else CREAM if i == 1 else ORANGE
        octo_layer(egg, i, i * LH, (i + 1) * LH, WIDTHS[i], col, "top" if i >= CRACK_LAYER else "bottom")
    inner = min(WIDTHS[CRACK_LAYER - 1], WIDTHS[CRACK_LAYER]) - 0.16
    octo_layer(egg, "InsideBottom", crack, crack + 0.02, inner, BLACK, "bottom")
    octo_layer(egg, "InsideTop", crack - 0.02, crack, inner, BLACK, "top")
    b = 2.6929
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * 0.6
        for half, d in (("A", -1), ("B", 1)):
            ear_half(egg, f"Ear{side}{half}", [(x0, b), (x0 + d * 0.38, b), (x0, b + ear_h)], -0.2, 0.2, ORANGE)
            ear_half(egg, f"EarIn{side}{half}", [(x0, b + 0.15), (x0 + d * 0.21, b + 0.15), (x0, b + ear_h * 0.58)], -0.25, -0.2, PINK)
    egg.block("Forelock", (-0.36, 2.7, forelock_front), (0.36, 3.4, 0.2), BROWN).bone = "top"
    egg.block("Crest", (-0.26, 3.2, 0.2), (0.26, 3.5, 0.7), BROWN).bone = "top"
    for i in range(CRACK_LAYER, N):
        z = WIDTHS[i] / 2
        egg.block(f"Mane{i}", (-0.26, i * LH, z - 0.05), (0.26, (i + 1) * LH, z + 0.25), BROWN)
    hw = blaze_w / 2
    for i in range(2, N):
        w = min(hw, 0.2) if i == N - 1 else hw
        front_plate(egg, f"Blaze{i}", -w, w, i * LH, (i + 1) * LH, BLAZE, depth=0.05, plain=False)
    return egg


def c_face():
    """C + the horse's eyes either side of the blaze and nostrils at its foot."""
    egg = take_c()
    y = 5 * LH
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.3, sx * 0.62))
        front_plate(egg, "Eye" + side, xa, xb, y + 0.04, y + 0.4, WHITE, depth=0.05)
        xa, xb = sorted((sx * 0.3, sx * 0.48))
        front_plate(egg, "Pupil" + side, xa, xb, y + 0.08, y + 0.3, PUPIL, depth=0.08)
    y = 2 * LH
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.08, sx * 0.2))
        front_plate(egg, "Nostril" + side, xa, xb, y + 0.12, y + 0.26, NOSTRIL, depth=0.08)
    return egg


def c_muzzle():
    """C + the blaze opening into a white muzzle band low on the front."""
    egg = take_c()
    front_plate(egg, "Muzzle", -0.5, 0.5, 2 * LH, 3 * LH, BLAZE, depth=0.06, plain=False)
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.18, sx * 0.36))
        front_plate(egg, "Nostril" + side, xa, xb, 2 * LH + 0.14, 2 * LH + 0.32, NOSTRIL, depth=0.09)
    return egg


def c_tail():
    """C + the mane running all the way down the back into a tail."""
    egg = take_c()
    for i in range(1, CRACK_LAYER):
        z = WIDTHS[i] / 2
        egg.block(f"Stripe{i}", (-0.26, i * LH, z - 0.05), (0.26, (i + 1) * LH, z + 0.25), BROWN)
    z = WIDTHS[1] / 2
    egg.block("Tail", (-0.22, -0.1, z + 0.2), (0.22, 2 * LH, z + 0.6), BROWN)
    return egg


def c_bold():
    """C pushed further: taller ears, a wider blaze, the forelock tipping over the front."""
    return take_c(ear_h=1.55, blaze_w=0.75, forelock_front=-0.8)


TAKES_C = [
    ("C", "C (pens thread)", take_c),
    ("C1", "C + face", c_face),
    ("C2", "C + white muzzle", c_muzzle),
    ("C3", "C + mane to tail", c_tail),
    ("C4", "C bolder", c_bold),
]


def main_c(out):
    os.makedirs(out, exist_ok=True)
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    tile = 380
    sheet = Image.new("RGB", (tile * len(TAKES_C), tile * 2 + 50), (236, 236, 236))
    d = ImageDraw.Draw(sheet)
    for c, (key, title, fn) in enumerate(TAKES_C):
        egg = fn()
        if key != "C":
            build(egg, f"HorseEgg_{key}", E.SPLIT, out)
        for r, view in enumerate(VIEWS):
            sheet.paste(render(egg.parts, W=tile, H=tile, fov=26, **view), (c * tile, 50 + r * tile))
        w = d.textlength(title, font=font)
        d.text((c * tile + (tile - w) / 2, 10), title, fill=(30, 30, 30), font=font)
    sheet.save(os.path.join(out, "compare.png"))
    print("wrote", out)
