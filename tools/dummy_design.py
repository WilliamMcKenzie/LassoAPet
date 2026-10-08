"""Lasso training dummies (QM, Oct 8): something to throw your lasso at to train lasso strength.

Run: python3 tools/dummy_design.py [out_dir]

Four takes for QM to pick from:
  A  Stitched horse   a sackcloth Horse sewn from patches, X eyes, stuck on a wooden pole mid-leap
  B  Target dummy     the classic: post, crossbar arms, straw sack body, bullseye on the chest
  C  Roping steer     what real cowboys practise on: a steer head stuck in a hay bale on sawhorse legs
  D  Spring horse     a barrel horse on a big spring, so it bobs and bucks when lassoed

Static props (no bones), built in studs at Horse scale with the same parts as the animals.
"""

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, horse_body, PINK, EYE_WHITE  # noqa: E402
from partlib import Part, T, Rx, Rz, render  # noqa: E402

SACK = (214, 180, 118)
SACK_DARK = (186, 148, 90)
PATCH_RED = (232, 86, 76)
PATCH_BLUE = (84, 150, 230)
THREAD = (70, 44, 30)
ROPE = (232, 196, 120)
WOOD = (166, 108, 62)
WOOD_DARK = (122, 78, 44)
STRAW = (250, 214, 92)
STRAW_DARK = (226, 184, 60)
RED = (230, 62, 62)
WHITE = (250, 250, 246)
BONE = (246, 238, 220)
HORN = (240, 232, 210)
STEER = (150, 90, 52)
METAL = (150, 156, 170)
BLACK = (34, 30, 40)


def pivot(p, at, R):
    """Rotate a part about a world point."""
    p.cf = T(*at) @ R @ T(*(-np.array(at))) @ p.cf


def rot_bone(a, bone, R):
    for p in a.parts:
        if p.bone == bone:
            pivot(p, a.pivots[bone], R)


def x_eye(a, x, yc, zc, size=1.0, bone="neck", side="both", back=None):
    """White eye plate with a black X stitched over it; on the head's sides (x) or front (back=z)."""
    h = size / 2
    sides = (("L", -1), ("R", 1)) if back is None else (("F", 0),)
    for s, sx in sides:
        if back is None:
            xa, xb = sorted((sx * x, sx * (x + A.PLATE)))
            a.box("Eye" + s, (xa, yc - h, zc - h), (xb, yc + h, zc + h), EYE_WHITE, bone)
            for k, ang in enumerate((45, -45)):
                p = Part(f"EyeX{s}{k}", (0.06, size * 1.25, 0.2), T(sx * (x + A.PLATE + 0.03), yc, zc) @ Rx(ang), BLACK, plain=True)
                p.bone = bone
                a.parts.append(p)
        else:
            a.box("Eye" + s + str(x), (x - h, yc - h, back - A.PLATE), (x + h, yc + h, back), EYE_WHITE, bone)
            for k, ang in enumerate((45, -45)):
                p = Part(f"EyeX{x}{k}", (0.2, size * 1.25, 0.06), T(x, yc, back - A.PLATE - 0.03) @ Rz(ang), BLACK, plain=True)
                p.bone = bone
                a.parts.append(p)


def stitches_z(a, name, x_face, y, z0, z1, n, bone="root", span=0.5):
    """A row of stitches across a seam running along z on a side face (x_face = +-x of the face)."""
    sx = 1 if x_face > 0 else -1
    for i in range(n):
        z = z0 + (z1 - z0) * (i + 0.5) / n
        xa, xb = sorted((x_face, x_face + sx * (A.PLATE + 0.02)))
        a.box(f"Plain{name}{i}", (xa, y - span / 2, z - 0.08), (xb, y + span / 2, z + 0.08), THREAD, bone)


def stitches_y(a, name, x_face, z, y0, y1, n, bone="root", span=0.5):
    """Stitches across a seam running up and down on a side face."""
    sx = 1 if x_face > 0 else -1
    for i in range(n):
        y = y0 + (y1 - y0) * (i + 0.5) / n
        xa, xb = sorted((x_face, x_face + sx * (A.PLATE + 0.02)))
        a.box(f"Plain{name}{i}", (xa, y - 0.08, z - span / 2), (xb, y + 0.08, z + span / 2), THREAD, bone)


def sewn_patch(a, name, x_face, y0, y1, z0, z1, color, bone="root"):
    """A coloured fabric patch on a side face with stitches round its edge."""
    sx = 1 if x_face > 0 else -1
    xa, xb = sorted((x_face, x_face + sx * A.PLATE))
    a.box("Plain" + name, (xa, y0, z0), (xb, y1, z1), color, bone)
    f = x_face + sx * A.PLATE
    nz, ny = max(2, round((z1 - z0) / 0.45)), max(2, round((y1 - y0) / 0.45))
    stitches_z(a, name + "T", f, y1, z0, z1, nz, bone, 0.35)
    stitches_z(a, name + "B", f, y0, z0, z1, nz, bone, 0.35)
    stitches_y(a, name + "F", f, z0, y0, y1, ny, bone, 0.35)
    stitches_y(a, name + "K", f, z1, y0, y1, ny, bone, 0.35)


def post(a, name, x, z, y0, y1, w=0.8, color=WOOD):
    a.box(name, (x - w / 2, y0, z - w / 2), (x + w / 2, y1, z + w / 2), color, "root")


def stand(a, y_top, x=0, z=0.3):
    """Wooden pole into a chunky cross-shaped foot."""
    post(a, "Pole", x, z, 0.8, y_top)
    a.box("FootX", (x - 3, 0, z - 0.6), (x + 3, 0.8, z + 0.6), WOOD_DARK, "root")
    a.box("FootZ", (x - 0.6, 0, z - 3), (x + 0.6, 0.8, z + 3), WOOD_DARK, "root")
    a.box("Collar", (x - 0.7, 0.8, z - 0.7), (x + 0.7, 1.4, z + 0.7), WOOD_DARK, "root")


# ---------------------------------------------------------------- A: stitched horse

def stitched_horse():
    a = Animal("DummyHorse", "Common")
    horse_body(a, coat=SACK, mane=ROPE, hoof=SACK_DARK, ear_inner=PATCH_RED)
    for n in ("EyeL", "EyeR", "PupilL", "PupilR"):
        a.remove(n)
    x_eye(a, 1.1, 9.6, -3.0)
    for side in (-1, 1):
        # seam where the neck is sewn on, a patch on each flank, a seam down the snout
        stitches_y(a, f"Neck{side}", side * 0.9, -1.9, 5.3, 8.2, 5, "neck")
        stitches_y(a, f"Head{side}", side * 1.1, -2.0, 8.4, 10.4, 4, "neck")
        sewn_patch(a, f"Patch{side}", side * 1.6, 4.0, 5.9, 0.2 if side < 0 else -2.0, 2.4 if side < 0 else -0.2,
                   PATCH_BLUE if side < 0 else PATCH_RED)
        stitches_z(a, f"Belly{side}", side * 1.6, 3.8, -2.4, 3.0, 9)
    # mid-leap: legs out, nose up, tail streaming; the whole horse up on the pole
    for leg in ("LegFL", "LegFR"):
        rot_bone(a, leg, Rx(55))
    for leg in ("LegHL", "LegHR"):
        rot_bone(a, leg, Rx(-55))
    rot_bone(a, "Tail", Rx(-60))
    rot_bone(a, "EarL", Rx(-35))
    rot_bone(a, "EarR", Rx(-35))
    lift = 4.5
    for p in a.parts:
        pivot(p, (0, 5, 0.3), Rx(12))
        p.cf = T(0, lift, 0) @ p.cf
    stand(a, 3.5 + lift + 0.2, z=0.3)
    return a


# ---------------------------------------------------------------- B: target dummy

def target_dummy():
    a = Animal("TargetDummy", "Common")
    stand(a, 10.5, z=0)
    # straw sack body tied off at the waist and neck, crossbar arms with straw sticking out
    a.box("Body", (-1.8, 4.2, -1.1), (1.8, 8.8, 1.1), SACK, "root")
    a.box("Waist", (-1.85, 4.6, -1.15), (1.85, 5.0, 1.15), ROPE, "root")
    a.box("Arms", (-4.4, 7.4, -0.4), (4.4, 8.2, 0.4), WOOD, "root")
    for s, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.8, sx * 3.6))
        a.box("Sleeve" + s, (xa, 7.1, -0.7), (xb, 8.5, 0.7), SACK_DARK, "root")
        xa, xb = sorted((sx * 4.4, sx * 5.2))
        a.box("Hand" + s, (xa, 7.3, -0.6), (xb, 8.3, 0.6), STRAW, "root")
    # bullseye on the chest: red, white, red, white, red
    for i, (w, c) in enumerate(((1.5, RED), (1.15, WHITE), (0.8, RED), (0.45, WHITE), (0.2, RED))):
        z = -1.1 - A.PLATE * (i + 1)
        a.box(f"Plain{i}Ring", (-w, 6.5 - w, z), (w, 6.5 + w, z + A.PLATE), c, "root")
    # head: sack with a tie at the neck, X eyes, stitched smile
    a.box("Neck", (-0.7, 8.8, -0.7), (0.7, 9.2, 0.7), ROPE, "root")
    a.box("Head", (-1.3, 9.2, -1.2), (1.3, 11.6, 1.2), SACK, "root")
    a.box("Tuft", (-0.5, 11.6, -0.5), (0.5, 12.2, 0.5), STRAW, "root")
    x_eye(a, -0.6, 10.7, None, 0.75, "root", back=-1.2)
    x_eye(a, 0.6, 10.7, None, 0.75, "root", back=-1.2)
    for i in range(5):
        x = -0.8 + i * 0.4
        a.box(f"PlainMouth{i}", (x - 0.08, 9.65, -1.2 - A.PLATE - 0.02), (x + 0.08, 10.05, -1.2), THREAD, "root")
    a.box("PlainMouthLine", (-0.9, 9.8, -1.2 - A.PLATE), (0.9, 9.9, -1.2), THREAD, "root")
    return a


# ---------------------------------------------------------------- C: roping steer

def roping_steer():
    a = Animal("RopingSteer", "Common")
    # sawhorse: plank on top, two splayed leg pairs
    a.box("Plank", (-0.9, 4.0, -3.4), (0.9, 4.5, 3.4), WOOD, "root")
    for end, z in (("F", -2.6), ("B", 2.6)):
        for s, sx in (("L", -1), ("R", 1)):
            p = Part(f"Leg{end}{s}", (0.6, 4.6, 0.6), T(sx * 1.0, 2.1, z) @ Rz(sx * 18), WOOD_DARK)
            p.bone = "root"
            a.parts.append(p)
        a.box(f"Brace{end}", (-1.5, 1.4, z - 0.25), (1.5, 1.8, z + 0.25), WOOD_DARK, "root")
    # hay bale body with two twine bands
    a.box("Bale", (-1.7, 4.5, -2.6), (1.7, 7.3, 3.0), STRAW, "root")
    for i, z in enumerate((-1.0, 1.4)):
        a.box(f"Plain{i}Twine", (-1.75, 4.45, z - 0.15), (1.75, 7.35, z + 0.15), STRAW_DARK, "root")
    # steer head stuck in the front: wide face, pale muzzle, long horns
    a.box("Head", (-1.2, 5.6, -4.2), (1.2, 8.2, -2.6), STEER, "root")
    a.box("Muzzle", (-1.0, 5.4, -4.9), (1.0, 6.6, -3.6), (236, 196, 170), "root")
    for s, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.35, sx * 0.7))
        a.box("Nostril" + s, (xa, 5.9, -4.95), (xb, 6.2, -4.9), (90, 50, 40), "root")
    a.box("Blaze", (-0.4, 6.6, -4.25), (0.4, 8.0, -4.2), WHITE, "root")
    a.box("HornBase", (-1.6, 7.6, -3.6), (1.6, 8.2, -3.0), HORN, "root")
    for s, sx in (("L", -1), ("R", 1)):
        a.tri("HornTip" + s, [(sx * 1.6, 7.6), (sx * 3.2, 7.6), (sx * 1.6, 9.2)], -3.6, -3.0, HORN, "root")
        xa, xb = sorted((sx * 1.2, sx * 1.9))
        a.box("Ear" + s, (xa, 6.9, -3.0), (xb, 7.4, -2.7), STEER, "root")
    A.Animal.eyes(a, 1.2, 6.9, 7.8, -4.0, -3.1, "root")
    return a


# ---------------------------------------------------------------- D: spring horse

def spring_horse():
    a = Animal("SpringHorse", "Common")
    # spring: stacked square coils, offset like a helix, on a metal plate
    a.box("Plate", (-2.0, 0, -2.0), (2.0, 0.5, 2.0), METAL, "root")
    for i in range(6):
        y = 0.5 + i * 0.6
        o = 0.25 if i % 2 else -0.25
        for k, (lo, hi) in enumerate((((-1.2, y, -1.2 + o), (1.2, y + 0.35, -0.8 + o)),
                                      ((-1.2, y, 0.8 + o), (1.2, y + 0.35, 1.2 + o)),
                                      ((-1.2, y, -0.8 + o), (-0.8, y + 0.35, 0.8 + o)),
                                      ((0.8, y, -0.8 + o), (1.2, y + 0.35, 0.8 + o)))):
            a.box(f"Coil{i}{k}", lo, hi, (210, 70, 70), "root")
    # barrel body with hoops, plank neck and head, rope mane and tail, stubby wooden legs
    y = 4.2
    a.box("Barrel", (-1.7, y, -2.7), (1.7, y + 3.2, 3.0), WOOD, "root")
    for i, z in enumerate((-2.0, 0.15, 2.3)):
        a.box(f"Plain{i}Hoop", (-1.75, y - 0.05, z - 0.2), (1.75, y + 3.25, z + 0.2), METAL, "root")
    a.box("Neck", (-0.8, y + 2.0, -2.6), (0.8, y + 4.6, -1.2), WOOD, "root")
    a.box("Head", (-1.0, y + 4.2, -4.4), (1.0, y + 6.0, -1.2), WOOD, "root")
    a.box("Snout", (-1.0, y + 4.2, -5.2), (1.0, y + 5.2, -4.4), WOOD_DARK, "root")
    for s, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.3, sx * 0.7))
        a.box("Nostril" + s, (xa, y + 4.6, -5.25), (xb, y + 4.9, -5.2), BLACK, "root")
    A.Animal.eyes(a, 1.0, y + 4.9, y + 5.8, -3.7, -2.8, "root")
    a.upright_ears(0.65, y + 6.0, -2.0, -1.6, 0.3, 1.0, WOOD, PINK)
    a.box("Mane", (-0.35, y + 3.2, -1.2), (0.35, y + 6.6, -0.5), ROPE, "root")
    a.box("Tail", (-0.4, y + 0.6, 3.0), (0.4, y + 3.0, 3.8), ROPE, "root")
    a.wedge("TailTip", (-0.4, y - 0.2, 3.0), (0.4, y + 0.6, 3.8), ROPE, "root", "down_back")
    for leg, (sx, z) in {"FL": (-1, -2.3), "FR": (1, -2.3), "HL": (-1, 2.0), "HR": (1, 2.0)}.items():
        xa, xb = sorted((sx * 0.6, sx * 1.4))
        a.box("Leg" + leg, (xa, y - 1.2, z - 0.4), (xb, y, z + 0.4), WOOD_DARK, "root")
    # a saddle so it reads as a toy horse
    a.box("Saddle", (-1.8, y + 2.2, -0.9), (1.8, y + 3.5, 1.0), RED, "root")
    # bucking: nose up a little
    for p in a.parts:
        if p.name not in ("Plate",) and not p.name.startswith("Coil"):
            pivot(p, (0, y, 0), Rx(10))
    return a


TAKES = [("A: Stitched horse", stitched_horse), ("B: Target dummy", target_dummy),
         ("C: Roping steer", roping_steer), ("D: Spring horse", spring_horse)]


def tiles(parts_list, cam):
    ims = [render(parts, **cam) for parts in parts_list]
    im = Image.new("RGB", (cam["W"] * len(ims), cam["H"]))
    for i, t in enumerate(ims):
        im.paste(t, (cam["W"] * i, 0))
    return im


def main(out="/mnt/project-files/design/dummies"):
    os.makedirs(out, exist_ok=True)
    built = [(n, fn()) for n, fn in TAKES]
    names = [n for n, _ in built]
    parts = [a.parts for _, a in built]
    q34 = dict(eye=(-23, 15, -25), target=(0, 6.8, -0.5), W=420, H=480, fov=38, outline=False)
    side = dict(eye=(-32, 8, -1), target=(0, 6.8, -1), W=420, H=420, fov=36, outline=False)
    front = dict(eye=(-7, 11, -29), target=(0, 7.6, 0), W=420, H=420, fov=36, outline=False)
    rows = [A.label(tiles(parts, q34), names, 24), tiles(parts, side), tiles(parts, front)]
    sheet = Image.new("RGB", (rows[0].width, sum(r.height for r in rows)), (255, 255, 255))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height
    sheet.save(os.path.join(out, "dummy_takes.png"))
    # size check next to the real Horse
    horse = render(__import__('horse_rig').pose(__import__("json").load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel"))), None, 0), **q34)
    line = Image.new("RGB", (420 * 5, 480))
    line.paste(horse, (0, 0))
    line.paste(tiles(parts, q34), (420, 0))
    A.label(line, ["Horse"] + names, 22).save(os.path.join(out, "dummy_lineup.png"))
    for n, a in built:
        print(n, len(a.parts), "parts")
    print("written to", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
