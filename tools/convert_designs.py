"""QM's old Blockbench models rebuilt in the Lasso For Eggs style (static drafts for QM to vet).

Run: python3 tools/convert_designs.py [out_dir]         the lineup + every model
     python3 tools/convert_designs.py one <name> [dir]  one close render + its model

  Boar         the old boar kept as it was: big pink nose, eyes under angry
               brows, tusks, dark tufts round the face
  WhiteWolf    the timber wolf's shape (tall bent legs, big ruff, low head,
               long tail) in the White Wolf's white and ice blue
  Troll        the cave horror as the winter Troll: blue, hunched, long arms,
               its mask kept (red eye, scarred white eye), tusks, white
               ponytail, spiked wooden club
  SpineLizard  a desert Epic: low sprawling lizard with a tall striped sail
  IceGolem     the rock demon in ice: knuckle-walking, ice crystals on its back
  IceDrake     the nether drake in the Ice Dragon's colours: cyan scales,
               white fur at the joints, red eyes

Each builder works in the old model's own units (16 to a Minecraft block) and
scales them by K into studs, so the proportions and QM's bone poses carry over.
Every block is axis-aligned inside its bone and every bone is 0 in the flat
rest; the pose comes from bone rest rotations (the old models' own, where they
had them; an old element that was rotated becomes its own small bone). Details
have real depth: the only thin plates are the standard eyes. Models go to
designs/converted/<Name>.bbmodel.
"""

import json
import os
import shutil
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, look_at, part_faces, render, write_bbmodel  # noqa: E402
import animal_designs as A  # noqa: E402
from animal_designs import Animal, EYE_WHITE, PUPIL, PLATE, PUPIL_BACK  # noqa: E402
from horse_rig import pose  # noqa: E402
from snake_design import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODELS = os.path.join(ROOT, "designs", "converted")
OUT = "/mnt/project-files/animals/converted"
SIDES = (("L", -1), ("R", 1))


def X(sx, a0, a1):
    """x extent mirrored to one side (sx = -1 left, +1 right), low to high."""
    return tuple(sorted((sx * a0, sx * a1)))


class Conv(Animal):
    """An Animal built in the old model's units: every coordinate is multiplied by k."""

    def __init__(self, name, rarity, k):
        super().__init__(name, rarity)
        self.k = k
        self.rest = {}
        self.bone_order = [("root", None)]
        self.pivots = {"root": (0, 0, 0)}

    def bone(self, name, parent, pivot, rest=(0, 0, 0)):
        self.bone_order.append((name, parent))
        self.pivots[name] = tuple(np.array(pivot, float) * self.k)
        if any(rest):
            self.rest[name] = tuple(rest)
        return name

    def b(self, name, lo, hi, color, bone):
        return Animal.box(self, name, np.array(lo, float) * self.k, np.array(hi, float) * self.k, color, bone)

    def pyr(self, name, lo, hi, axis, length, color, bone):
        """Square pyramid standing on one face of a box footprint (a box with no
        size along `axis`); axis '+x', '-y', ... is the way the point sticks out."""
        lo, hi = np.array(lo, float) * self.k, np.array(hi, float) * self.k
        i = "xyz".index(axis[1])
        s = 1 if axis[0] == "+" else -1
        apex = (lo + hi) / 2
        apex[i] = lo[i] + s * length * self.k
        u, v = [j for j in range(3) if j != i]
        corners = []
        for du, dv in ((0, 0), (1, 0), (1, 1), (0, 1)):
            p = lo.copy()
            p[u] = hi[u] if du else lo[u]
            p[v] = hi[v] if dv else lo[v]
            corners.append(p)
        p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
        p.polys = [np.array(corners)] + [np.array([corners[j], corners[(j + 1) % 4], apex]) for j in range(4)]
        p.bone = bone
        self.parts.append(p)
        return p

    def prism(self, name, pts, z0, z1, color, bone):
        """Triangle (x, y) extruded along z."""
        k = self.k
        pts = [(x * k, y * k) for x, y in pts]
        z0, z1 = z0 * k, z1 * k
        faces = [[(x, y, z0) for x, y in pts], [(x, y, z1) for x, y in pts[::-1]]]
        for a, c in ((0, 1), (1, 2), (2, 0)):
            faces.append([(pts[a][0], pts[a][1], z0), (pts[a][0], pts[a][1], z1),
                          (pts[c][0], pts[c][1], z1), (pts[c][0], pts[c][1], z0)])
        p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
        p.polys = [np.array(f, float) for f in faces]
        p.bone = bone
        self.parts.append(p)
        return p

    def front_eye(self, side, x0, x1, y0, y1, z, bone, pupil=PUPIL, frac=0.6, eye=EYE_WHITE):
        """Standard eye on a front (-z) face: white plate, pupil plate on it set
        PUPIL_BACK up from the plate's bottom edge. pupil=None: plain eye."""
        k = self.k
        x0, x1, y0, y1, z = x0 * k, x1 * k, y0 * k, y1 * k, z * k
        Animal.box(self, "Eye" + side, (x0, y0, z - PLATE), (x1, y1, z), eye, bone)
        if pupil is None:
            return
        w = (x1 - x0) * frac
        c = (x0 + x1) / 2
        Animal.box(self, "Pupil" + side, (c - w / 2, y0 + PUPIL_BACK, z - PLATE - 0.03),
                   (c + w / 2, y1 - (y1 - y0) * 0.2, z - PLATE), pupil, bone)

    def side_eye(self, side, sx, x, y0, y1, z0, z1, bone, pupil=PUPIL, eye=EYE_WHITE, slit=False):
        """Standard eye on a side (+-x) face, pupil toward the front, PUPIL_BACK from the front edge."""
        k = self.k
        x, y0, y1, z0, z1 = x * k, y0 * k, y1 * k, z0 * k, z1 * k
        Animal.box(self, "Eye" + side, (*X(sx, x, x + PLATE)[:1], y0, z0), (X(sx, x, x + PLATE)[1], y1, z1), eye, bone)
        xa, xb = X(sx, x, x + PLATE + 0.03)
        if slit:
            zc = (z0 + z1) / 2
            Animal.box(self, "Slit" + side, (xa, y0 + (y1 - y0) * 0.08, zc - 0.13 + PUPIL_BACK),
                       (xb, y1 - (y1 - y0) * 0.08, zc + 0.13 + PUPIL_BACK), pupil, bone)
        else:
            Animal.box(self, "Pupil" + side, (xa, y0 + (y1 - y0) * 0.1, z0 + PUPIL_BACK),
                       (xb, y0 + (y1 - y0) * 0.7, z0 + (z1 - z0) * 0.5 + PUPIL_BACK), pupil, bone)


# ---------------------------------------------------------------- boar

def boar():
    """The old boar: a tall shoulder hump over a shorter back, a big head pitched
    down, a big pink nose, eyes under angry tan brows, tusks curling up, dark
    tufts flaring off the cheeks and a mane down the back."""
    c = dict(coat=(176, 108, 68), dark=(112, 66, 46), tan=(236, 190, 136), nose=(248, 150, 158),
             nostril=(130, 50, 70), tusk=(254, 246, 222), hoof=(86, 60, 52))
    a = Conv("Boar", "New", 0.38)
    a.pivots["root"] = np.array((0, 12, 2)) * a.k
    # legs: short and thick, dark trotters
    for side, sx in SIDES:
        for end, z0, z1 in (("F", -8.5, -4.5), ("H", 6.0, 10.0)):
            bone = a.bone("Leg" + end + side, "root", (sx * 4.3, 7.5, (z0 + z1) / 2))
            x0, x1 = X(sx, 2.3, 6.3)
            a.b("Leg" + end + side, (x0, 2, z0), (x1, 7.5, z1), c["coat"], bone)
            a.b("Hoof" + end + side, (x0, 0, z0), (x1, 2, z1), c["hoof"], bone)
    # body: the shoulders stand taller and wider than the back
    a.b("Back", (-6.2, 6.5, -4), (6.2, 16.5, 10.5), c["coat"], "root")
    a.b("Shoulders", (-8, 6.2, -9), (8, 19, -2), c["coat"], "root")
    # mane: a dark ridge down the spine with spikes standing up out of it
    a.b("Mane", (-1.6, 19, -8.5), (1.6, 20, -2.5), c["dark"], "root")
    for i, (z, y, h) in enumerate(((-7.5, 20, 3.2), (-5.5, 20, 3.8), (-3.5, 20, 3.0), (-1, 16.5, 2.2), (2, 16.5, 2.4), (5, 16.5, 2.0))):
        a.pyr(f"Tuft{i}", (-1.3, y, z - 1.3), (1.3, y, z + 1.3), "+y", h, c["dark"], "root")
    # head: pitched down off the shoulders' front
    head = a.bone("neck", "root", (0, 13, -9), (-14, 0, 0))
    a.b("Head", (-6.2, 7, -19), (6.2, 18.5, -9), c["coat"], head)
    a.b("Nose", (-3.4, 8, -22.5), (3.4, 14, -19), c["nose"], head)
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.8, 2.2)
        a.b("Nostril" + side, (x0, 9.8, -22.8), (x1, 12.2, -22.5), c["nostril"], head)
    a.b("Jaw", (-4, 5.8, -21), (4, 8, -12), c["dark"], head)
    # eyes above the nose, angry brows over them
    for side, sx in SIDES:
        x0, x1 = X(sx, 1.1, 5.1)
        a.front_eye(side, x0, x1, 14.4, 17.6, -19, head)
        brow = a.bone("Brow" + side, head, (sx * 3.2, 18, -19.5), (0, 0, sx * 16))
        x0, x1 = X(sx, 0.6, 6)
        a.b("Brow" + side, (x0, 17.2, -21), (x1, 19, -18.5), c["tan"], brow)
    # tusks: out of the nose's lower corners, then up to a point, leaning out
    for side, sx in SIDES:
        tusk = a.bone("Tusk" + side, head, (sx * 3.4, 9, -20.5), (0, 0, -sx * 20))
        x0, x1 = X(sx, 3.4, 5.6)
        a.b("Tusk" + side, (x0, 7.6, -21.8), (x1, 9.4, -20), c["tusk"], tusk)
        x0, x1 = X(sx, 4.0, 5.6)
        a.b("TuskUp" + side, (x0, 9.4, -21.8), (x1, 13, -20.2), c["tusk"], tusk)
        a.pyr("TuskTip" + side, (x0, 13, -21.8), (x1, 13, -20.2), "+y", 2.2, c["tusk"], tusk)
    # tufts round the face: dark cheek fur with spikes flaring out and back,
    # a beard under the jaw, a crest on top between small ears
    for side, sx in SIDES:
        x0, x1 = X(sx, 6.2, 7.4)
        a.b("Cheek" + side, (x0, 7, -17), (x1, 16, -10), c["dark"], head)
        ax = "-x" if sx < 0 else "+x"
        xs = sx * 7.4
        for i, (y, z, h) in enumerate(((8.5, -14.5, 3.4), (11.5, -13, 4.2), (14.5, -14.5, 3.4))):
            a.pyr(f"CheekTuft{side}{i}", (xs, y - 1.4, z - 1.6), (xs, y + 1.4, z + 1.6), ax, h, c["dark"], head)
        ear = a.bone("Ear" + side, head, (sx * 4.3, 18.5, -12))
        a.prism("Ear" + side + "A", [(sx * 4.3, 18.5), (sx * 2.6, 18.5), (sx * 4.3, 22.5)], -13, -11, c["coat"], ear)
        a.prism("Ear" + side + "B", [(sx * 4.3, 18.5), (sx * 6.0, 18.5), (sx * 4.3, 22.5)], -13, -11, c["coat"], ear)
    for i, x in enumerate((-2, 2)):
        a.pyr(f"Beard{i}", (x - 1.3, 5.8, -18), (x + 1.3, 5.8, -15), "-y", 2.4, c["dark"], head)
    for i, z in enumerate((-16.5, -13.5)):
        a.pyr(f"Crest{i}", (-1.3, 18.5, z - 1.3), (1.3, 18.5, z + 1.3), "+y", 3.0 if i else 2.4, c["dark"], head)
    # tail: a short string down the back with a dark tuft
    tail = a.bone("Tail", "root", (0, 15, 10.5), (-24, 0, 0))
    a.b("Tail", (-0.7, 10, 10.5), (0.7, 15, 11.9), c["coat"], tail)
    a.pyr("TailTuft", (-1.2, 10, 10.2), (1.2, 10, 12.2), "-y", 2.6, c["dark"], tail)
    a.meta = {"seat": (0, 19 * a.k, -3 * a.k), "neck_loop": {"center": (0, 13 * a.k, -12 * a.k), "radius": 7 * a.k}}
    return a


# ---------------------------------------------------------------- white wolf

def white_wolf():
    """The timber wolf's shape and pose (its own bone rotations): tall bent legs,
    a big ruff over the shoulders, a low head with a long snout, a long tail,
    in the White Wolf's white and ice blue."""
    c = dict(white=(244, 246, 250), grey=(186, 200, 224), dark=(120, 136, 170), nose=(46, 52, 70),
             ice=(40, 170, 240), claw=(70, 78, 104), fang=(255, 255, 255))
    a = Conv("WhiteWolf", "Rare", 0.3)
    a.pivots["root"] = np.array((0, 18, 8)) * a.k
    a.b("Torso", (-6, 14, -4), (6, 25, 20), c["white"], "root")
    a.b("Saddle", (-5, 25, -2), (5, 26.5, 17), c["grey"], "root")
    # the ruff: a big block over the shoulders, the chest sloping in under it
    a.b("Ruff", (-8, 20, -13), (8, 27.5, -2), c["white"], "root")
    a.b("RuffTop", (-6.5, 27.5, -11), (6.5, 29, -2), c["grey"], "root")
    chest = a.bone("Chest", "root", (0, 20, -13), (22.5, 0, 0))
    a.b("Chest", (-7, 16, -13), (7, 20, -3), c["white"], chest)
    # head: low and forward, the snout long, front-facing ice eyes
    head = a.bone("neck", "root", (0, 23, -12.5))
    a.b("Head", (-4.5, 19, -21), (4.5, 27, -13), c["white"], head)
    a.b("Snout", (-2.2, 20, -28), (2.2, 24, -21), c["white"], head)
    a.b("Nose", (-1.5, 22.3, -29), (1.5, 24.4, -27.6), c["nose"], head)
    for side, sx in SIDES:
        x0, x1 = X(sx, 1.2, 3.8)
        a.front_eye(side, x0, x1, 23.8, 26, -21, head, pupil=c["ice"], frac=0.62)
        # two fangs down off the snout's front corners
        x0, x1 = X(sx, 0.9, 2.1)
        a.pyr("Fang" + side, (x0, 20, -27.8), (x1, 20, -26.6), "-y", 2.0, c["fang"], head)
        # cheek fur flaring out behind the eyes
        ax = "-x" if sx < 0 else "+x"
        for i, (y, h) in enumerate(((20.5, 2.6), (23.5, 3.2))):
            a.pyr(f"CheekTuft{side}{i}", (sx * 4.5, y - 1.4, -19), (sx * 4.5, y + 1.4, -15.5), ax, h, c["white"], head)
        # pointed ears, leaning out
        ear = a.bone("Ear" + side, head, (sx * 3, 27, -16), (0, 0, -sx * 12))
        a.prism("Ear" + side + "A", [(sx * 3, 27), (sx * 0.6, 27), (sx * 3, 32)], -17.2, -15, c["white"], ear)
        a.prism("Ear" + side + "B", [(sx * 3, 27), (sx * 5.2, 27), (sx * 3, 32)], -17.2, -15, c["white"], ear)
        a.prism("Ear" + side + "In", [(sx * 3, 27.4), (sx * 1.6, 27.4), (sx * 3, 30.4)], -17.6, -17.2, c["grey"], ear)
    jaw = a.bone("Jaw", head, (0, 19, -21))
    a.b("Jaw", (-1.8, 17.2, -26.5), (1.8, 19, -13), c["grey"], jaw)
    # legs: the timber wolf's bends, big paws with dark claws
    for side, sx in SIDES:
        for end, (hip, knee, paw, zs) in (
                ("F", ((5.5, 21.8, -4.8, -27.5), (8.5, 13, -4.5, 42.5), (8.5, 0.1, -8.3, -15), (-9, -2))),
                ("H", ((5.5, 21.2, 14.8, 27.5), (8.5, 12.5, 14.5, -42.5), (8.5, -0.5, 20.3, 15), (11, 20)))):
            up = a.bone("Leg" + end + side, "root", (sx * hip[0], hip[1], hip[2]), (hip[3], 0, 0))
            x0, x1 = X(sx, 6, 11)
            a.b("Thigh" + end + side, (x0, 12.5, zs[0]), (x1, 25.5, zs[1]), c["white"], up)
            lo = a.bone("Shin" + end + side, up, (sx * knee[0], knee[1], knee[2]), (knee[3], 0, 0))
            z0, z1 = (-9, -4) if end == "F" else (15, 20)
            a.b("Shin" + end + side, (x0, -1, z0), (x1, 14, z1), c["white"], lo)
            p = a.bone("Paw" + end + side, lo, (sx * paw[0], paw[1], paw[2]), (paw[3], 0, 0))
            x0, x1 = X(sx, 5, 12)
            z0, z1 = (-12.8, -4.8) if end == "F" else (12.2, 20.2)
            y0 = -2.4 if end == "F" else -3.2
            a.b("Paw" + end + side, (x0, y0, z0), (x1, y0 + 3, z1), c["grey"], p)
            for i, xc in enumerate((6.4, 8.5, 10.6)):
                xa, xb = X(sx, xc - 0.8, xc + 0.8)
                a.pyr(f"Claw{end}{side}{i}", (xa, y0, z0), (xb, y0 + 1.6, z0), "-z", 2.4, c["claw"], p)
    # tail: three pieces, dipping then lifting, a grey tip
    t = a.bone("Tail", "root", (0, 18, 17), (18, 0, 0))
    a.b("Tail1", (-3, 16, 18), (3, 20.5, 27.2), c["white"], t)
    t2 = a.bone("Tail2", t, (0, 18, 26.2), (-12, 0, 0))
    a.b("Tail2", (-3.4, 15.2, 26.2), (3.4, 21.2, 35.2), c["white"], t2)
    t3 = a.bone("Tail3", t2, (0, 18, 34.2), (-14, 0, 0))
    a.b("Tail3", (-3.6, 14.6, 34.2), (3.6, 21.4, 40), c["white"], t3)
    a.b("TailTip", (-3.2, 15, 40), (3.2, 21, 44.5), c["grey"], t3)
    a.meta = {"seat": (0, 26.5 * a.k, 4 * a.k), "neck_loop": {"center": (0, 23 * a.k, -14 * a.k), "radius": 5.5 * a.k}}
    return a


# ---------------------------------------------------------------- troll

def troll():
    """The cave horror as the winter Troll: a huge hunched chest, long arms down
    to the ground, short legs; its mask kept, bone white, with a red eye and a
    scarred white eye in the holes; tusks up out of the jaw, a white ponytail,
    fur shorts, and a spiked wooden club in the right fist."""
    c = dict(skin=(76, 150, 234), dark=(50, 110, 200), mask=(238, 234, 222), hole=(34, 44, 78), red=(236, 36, 48),
             scar=(246, 132, 178), hair=(250, 250, 252), fur=(150, 100, 60), trim=(250, 250, 252),
             tusk=(254, 246, 226), claw=(236, 244, 255), wood=(160, 104, 56), wood_dark=(118, 74, 40), spike=(210, 216, 228))
    a = Conv("Troll", "Epic", 0.45)
    a.pivots["root"] = np.array((0, 13, 9.5)) * a.k
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 5.5, 9, 9.5))
        x0, x1 = X(sx, 2.5, 8.5)
        a.b("Leg" + side, (x0, 1.5, 7), (x1, 7, 12), c["skin"], leg)
        a.b("Foot" + side, (x0, 0, 5), (x1, 1.5, 12), c["dark"], leg)
        for i, xc in enumerate((3.8, 5.5, 7.2)):
            xa, xb = X(sx, xc - 0.7, xc + 0.7)
            a.pyr(f"Toe{side}{i}", (xa, 0, 5), (xb, 1.4, 5), "-z", 1.4, c["claw"], leg)
    # fur shorts over the hips and the tops of the legs, a white trim
    a.b("Shorts", (-8.8, 7, 6.6), (8.8, 13.5, 12.4), c["fur"], "root")
    a.b("Trim", (-9.1, 6.2, 6.3), (9.1, 7.2, 12.7), c["trim"], "root")
    # the hunched body: belly, a huge chest, the head hanging off the front
    body = a.bone("Torso", "root", (0, 13.2, 10))
    a.b("Belly", (-6.8, 13.5, 6.4), (6.8, 22, 12.4), c["skin"], body)
    a.b("Chest", (-10.5, 22, 5), (10.5, 31, 14), c["skin"], body)
    head = a.bone("neck", body, (0, 25.8, 5))
    a.b("Head", (-3.5, 20.6, -3), (3.5, 29, 5), c["skin"], head)
    # the mask: a bone-white slab with two eye holes, a dark mouth band with teeth
    a.b("MaskTop", (-5.5, 25, -5), (5.5, 30, -3), c["mask"], head)
    a.b("MaskNose", (-1.3, 22.8, -5.6), (1.3, 26.2, -5), c["mask"], head)
    a.b("MaskMid", (-3.5, 23, -5), (3.5, 25, -3), c["mask"], head)
    a.b("MaskMouth", (-5.5, 21, -4.6), (5.5, 23, -3), c["hole"], head)
    a.b("MaskChin", (-5.5, 20.2, -5), (5.5, 21, -3), c["mask"], head)
    for i, x in enumerate((-4.4, -2.2, 0, 2.2, 4.4)):
        a.pyr(f"Tooth{i}", (x - 0.8, 23, -4.9), (x + 0.8, 23, -4.1), "-y", 1.4, c["mask"], head)
    # eye holes: his right eye is red, his left is white and scarred through the mask
    for side, sx in SIDES:
        x0, x1 = X(sx, 1.4, 4.6)
        a.b("Hole" + side, (x0, 26.2, -5.15), (x1, 28.4, -5), c["hole"], head)
    a.front_eye("L", -4.2, -1.8, 26.5, 28.1, -5.15, head, pupil=None)
    a.front_eye("R", 1.8, 4.2, 26.5, 28.1, -5.15, head, pupil=c["red"], frac=0.62, eye=c["red"])
    for i, (y0, y1) in enumerate(((28.4, 30.6), (24.6, 26.2))):
        a.b(f"Scar{i}", (-3.35, y0, -5.4), (-2.65, y1, -5.0), c["scar"], head)
    # jaw: jutting out under the mask, two tusks standing up off it
    jaw = a.bone("Jaw", head, (0, 21, -2))
    a.b("Jaw", (-4, 18.2, -6.4), (4, 20.4, -1), c["skin"], jaw)
    for side, sx in SIDES:
        x0, x1 = X(sx, 2.4, 3.8)
        a.b("Tusk" + side, (x0, 20.4, -6.4), (x1, 23, -5), c["tusk"], jaw)
        a.pyr("TuskTip" + side, (x0, 23, -6.4), (x1, 23, -5), "+y", 1.6, c["tusk"], jaw)
    # hair: a white cap over the mask's top, tied back into a ponytail
    a.b("Hair", (-4, 29, -3.5), (4, 30.6, 5), c["hair"], head)
    # the ponytail lies back over the hunched shoulders and hangs down behind
    pony = a.bone("Ponytail", head, (0, 30.6, 5))
    a.b("Tie", (-1.5, 30.4, 4), (1.5, 32.4, 6), c["fur"], pony)
    a.b("Ponytail", (-1.3, 31, 6), (1.3, 32.4, 14), c["hair"], pony)
    a.b("PonytailEnd", (-1.5, 22, 14), (1.5, 32.4, 16.4), c["hair"], pony)
    # arms: long, knuckles near the ground, white claws
    for side, sx in SIDES:
        arm = a.bone("Arm" + side, body, (sx * 12.8, 28, 8.5), (-6, 0, 0))
        x0, x1 = X(sx, 10.5, 15.8)
        a.b("Arm" + side, (x0, 12, 5), (x1, 31.5, 12), c["skin"], arm)
        x0, x1 = X(sx, 10, 16.5)
        a.b("Fist" + side, (x0, 5.6, 4.2), (x1, 12, 12.6), c["skin"], arm)
        for i, zc in enumerate((5.8, 8.4, 11)):
            xa, xb = X(sx, 12.6, 15.8)
            a.pyr(f"Claw{side}{i}", (xa, 5.6, zc - 0.8), (xb, 5.6, zc + 0.8), "-y", 1.2, c["claw"], arm)
    # the club: through the right fist, raised forward, a thick spiked head
    bat = a.bone("Bat", "ArmR", (13.25, 8.8, 8.4), (58, 0, 0))
    a.b("BatHandle", (12.3, 7.9, -6), (14.2, 9.7, 11), c["wood_dark"], bat)
    a.b("BatHead", (11, 6.6, -20), (15.5, 11, -6), c["wood"], bat)
    a.b("BatCap", (11.6, 7.2, -21), (14.9, 10.4, -20), c["wood"], bat)
    n = 0
    for z, off in ((-16.6, -1.1), (-10, 1.1)):
        for axis, lo, hi in (("-x", (11, 8.8 + off - 0.9, z - 0.9), (11, 8.8 + off + 0.9, z + 0.9)),
                             ("+x", (15.5, 8.8 - off - 0.9, z - 0.9), (15.5, 8.8 - off + 0.9, z + 0.9)),
                             ("-y", (13.25 - off - 0.9, 6.6, z - 0.9), (13.25 - off + 0.9, 6.6, z + 0.9)),
                             ("+y", (13.25 + off - 0.9, 11, z - 0.9), (13.25 + off + 0.9, 11, z + 0.9))):
            a.pyr(f"Spike{n}", lo, hi, axis, 1.8, c["spike"], bat)
            n += 1
    a.meta = {"seat": (0, 31 * a.k, 9.5 * a.k), "neck_loop": {"center": (0, 25 * a.k, 0), "radius": 6 * a.k}}
    return a


# ---------------------------------------------------------------- spine lizard

def spine_lizard():
    """A desert Epic from the spine lizard: a long low body on sprawled legs, a
    tall sail of striped blocks with spines poking out the top, a long head
    whose top jaw lifts, a long tail with a spiky crest at the end."""
    c = dict(body=(236, 178, 84), back=(206, 132, 60), belly=(252, 234, 186), sail=(250, 150, 52),
             sail2=(252, 204, 76), ray=(170, 50, 78), tip=(254, 246, 222), eye=(255, 214, 64), slit=(40, 20, 20),
             tooth=(254, 250, 236), mouth=(238, 104, 146), claw=(254, 246, 222))
    a = Conv("SpineLizard", "Epic", 0.34)
    a.pivots["root"] = np.array((0, 5, 2)) * a.k
    lift = 3  # the body stands a little off the ground on its bent legs
    L = lambda y: y + lift  # noqa: E731
    a.b("Body", (-7, L(0), -10), (7, L(9), 13), c["body"], "root")
    a.b("Belly", (-5.5, L(-0.8), -8.5), (5.5, L(0), 11.5), c["belly"], "root")
    a.b("BackStripe", (-4, L(9), -9), (4, L(10), 12.5), c["back"], "root")
    # the sail: columns stepping up to the middle, orange and gold stripes,
    # a maroon spine up the middle of every other one, poking out the top
    tops = [16, 21, 25.5, 29, 31, 29, 25.5, 21, 16]
    for i, top in enumerate(tops):
        z0 = -14 + i * 4
        a.b(f"Sail{i}", (-0.8, L(10), z0), (0.8, L(top), z0 + 4), c["sail"] if i % 2 == 0 else c["sail2"], "root")
        if i % 2 == 0:
            a.b(f"Ray{i}", (-1.2, L(10), z0 + 1.1), (1.2, L(top + 1.4), z0 + 2.9), c["ray"], "root")
            a.pyr(f"RayTip{i}", (-1.2, L(top + 1.4), z0 + 1.1), (1.2, L(top + 1.4), z0 + 2.9), "+y", 2.4, c["tip"], "root")
    # head: long and flat, raised a little; the top jaw lifts off the bottom
    head = a.bone("neck", "root", (0, L(4), -10), (8, 0, 0))
    a.b("Head", (-5, L(0), -19), (5, L(8), -10), c["body"], head)
    a.b("HeadTop", (-3.4, L(8), -18), (3.4, L(9), -11), c["back"], head)
    a.b("Chin", (-4, L(0), -27), (4, L(2), -19), c["belly"], head)
    a.b("Mouth", (-3, L(1.9), -26), (3, L(2.1), -19), c["mouth"], head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 5, L(4.4), L(7.2), -18, -14.4, head, pupil=c["slit"], eye=c["eye"], slit=True)
    jaw = a.bone("Jaw", head, (0, L(4), -19), (0, 0, 0))
    a.b("Snout", (-4, L(2), -27), (4, L(6), -19), c["body"], jaw)
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.8, 2.2)
        a.b("Nostril" + side, (x0, L(4.6), -27.3), (x1, L(5.4), -27), c["slit"], jaw)
        for i, z in enumerate((-25.5, -22.5, -19.8)):
            x0, x1 = X(sx, 2.6, 3.8)
            a.pyr(f"Upper_tooth{side}{i}", (x0, L(2), z - 0.6), (x1, L(2), z + 0.6), "-y", 1.4, c["tooth"], jaw)
    # legs: short, splayed out and bent down to wide clawed feet
    for side, sx in SIDES:
        for end, z0, z1, spin in (("F", -10.4, -3.4, 55), ("H", 9.2, 16.2, 30)):
            hip = a.bone("Leg" + end + side, "root", (sx * 6.8, L(4), (z0 + z1) / 2), (0, sx * spin if end == "F" else -sx * spin, sx * -34))
            x0, x1 = X(sx, 5.8, 13)
            a.b("Leg" + end + side, (x0, L(1.5), z0), (x1, L(6), z1), c["body"], hip)
            foot = a.bone("Foot" + end + side, hip, (sx * 12.5, L(1.5), (z0 + z1) / 2), (0, 0, sx * 34))
            x0, x1 = X(sx, 11.5, 18)
            a.b("Foot" + end + side, (x0, L(-0.6), z0 + 1), (x1, L(1.5), z1 - 1), c["body"], foot)
            for i, zc in enumerate((z0 + 2.2, (z0 + z1) / 2, z1 - 2.2)):
                ax = "-x" if sx < 0 else "+x"
                a.pyr(f"Claw{end}{side}{i}", (sx * 18, L(-0.6), zc - 0.8), (sx * 18, L(1), zc + 0.8), ax, 2.2, c["claw"], foot)
    # tail: two pieces, dipping to the ground, a spiky crest at the end
    t = a.bone("Tail", "root", (0, L(4.5), 13), (10, 0, 0))
    a.b("Tail1", (-4.5, L(0.5), 13), (4.5, L(8), 31), c["body"], t)
    a.b("Tail1Stripe", (-3, L(8), 14), (3, L(9), 30), c["back"], t)
    t2 = a.bone("Tail2", t, (0, L(3), 31), (-8, 0, 0))
    a.b("Tail2", (-2.6, L(0.8), 31), (2.6, L(5.6), 47), c["body"], t2)
    a.b("Tail2Tip", (-1.8, L(1.4), 47), (1.8, L(5), 53), c["back"], t2)
    for i, (z, h) in enumerate(((35, 2.4), (39.5, 3.2), (44, 2.6))):
        a.pyr(f"Crest{i}", (-1, L(5.6), z - 1.4), (1, L(5.6), z + 1.4), "+y", h, c["ray"], t2)
    a.meta = {"seat": (0, L(10) * a.k, 8 * a.k), "neck_loop": {"center": (0, L(5) * a.k, -13 * a.k), "radius": 6 * a.k}}
    return a


# ---------------------------------------------------------------- ice golem

def ice_golem():
    """The rock demon in ice: a huge chest and shoulders, a small head sunk low
    in front under a snowy brow, knuckles on the ground, short legs, and ice
    crystals growing out of its back where the rocks were."""
    c = dict(ice=(160, 218, 250), deep=(82, 150, 226), frost=(214, 240, 255), snow=(252, 253, 255),
             crystal=(96, 222, 255), crystal2=(236, 250, 255), pupil=(30, 60, 140))
    a = Conv("IceGolem", "New", 0.4)
    a.pivots["root"] = np.array((0, 16, 8)) * a.k
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 6.5, 10, 9))
        x0, x1 = X(sx, 2.8, 10.2)
        a.b("Leg" + side, (x0, 0, 5.6), (x1, 10.5, 12.4), c["deep"], leg)
    a.b("Hips", (-7.5, 9.5, 3.5), (7.5, 18, 14.5), c["ice"], "root")
    body = a.bone("Torso", "root", (0, 18, 9))
    a.b("Chest", (-13, 18, 1), (13, 32, 14), c["ice"], body)
    a.b("Hump", (-7.5, 23, 14), (7.5, 32, 20), c["ice"], body)
    a.b("SnowCap", (-13.3, 32, 0.7), (13.3, 33.4, 14.3), c["snow"], body)
    # crystals: the old model's three rocks, tipped back, now ice columns to a point
    for name, (x0, x1, z0, z1, top, tilt, lean) in {
            "Crystal0": (-4, 4, 3, 10, 48, 34, 0), "Crystal1": (-11, -5.5, 4, 9.5, 43, 30, 16),
            "Crystal2": (5.5, 11, 4, 9.5, 43, 30, -16), "Crystal3": (-2.5, 2.5, 13, 18, 39, 44, 0)}.items():
        cb = a.bone(name, body, ((x0 + x1) / 2, 32, (z0 + z1) / 2), (tilt, 0, lean))
        col = c["crystal"] if name != "Crystal3" else c["crystal2"]
        a.b(name, (x0, 31, z0), (x1, top, z1), col, cb)
        a.pyr(name + "Tip", (x0, top, z0), (x1, top, z1), "+y", (x1 - x0) * 0.9, col, cb)
    # the head: small, sunk forward, a snow brow and a long icicle nose
    head = a.bone("neck", body, (0, 25.6, 1.2), (-6, 0, 0))
    a.b("Head", (-5.4, 17.5, -9.4), (5.4, 28, 1.2), c["ice"], head)
    brow = a.bone("Brow", head, (0, 28.2, -1), (-12, 0, 0))
    a.b("Brow", (-6, 27, -10.6), (6, 29.4, -1), c["snow"], brow)
    a.b("Nose", (-1.8, 20.5, -12), (1.8, 26.5, -9.4), c["ice"], head)
    a.pyr("NoseTip", (-1.8, 20.5, -12), (1.8, 20.5, -9.4), "-y", 2.6, c["ice"], head)
    for side, sx in SIDES:
        x0, x1 = X(sx, 2.2, 4.8)
        a.front_eye(side, x0, x1, 23, 25.6, -9.4, head, pupil=c["pupil"], frac=0.62)
    a.b("Mouth", (-3.4, 18.6, -9.6), (3.4, 19.6, -9.4), c["deep"], head)
    # arms: thick upper arms, huge deep-blue forearms, knuckles on the ground
    for side, sx in SIDES:
        arm = a.bone("Arm" + side, body, (sx * 12.8, 28.6, 5.7))
        x0, x1 = X(sx, 12.5, 19.5)
        a.b("Shoulder" + side, (x0, 26, 0.5), (x1, 33, 10.5), c["ice"], arm)
        a.b("SnowShoulder" + side, (x0 - 0.3 * (sx < 0), 33, 0.2), (x1 + 0.3 * (sx > 0), 34.2, 10.8), c["snow"], arm)
        x0, x1 = X(sx, 13, 19)
        a.b("UpperArm" + side, (x0, 15, 1.5), (x1, 26, 9.5), c["ice"], arm)
        fore = a.bone("Forearm" + side, arm, (sx * 15.75, 15.1, 7))
        x0, x1 = X(sx, 11.5, 20.5)
        a.b("Forearm" + side, (x0, 4, -0.5), (x1, 15, 11), c["deep"], fore)
        x0, x1 = X(sx, 12, 20)
        a.b("Knuckles" + side, (x0, 0, -1.5), (x1, 4, 10), c["deep"], fore)
        for i, zc in enumerate((1, 4.3, 7.6)):
            xa, xb = X(sx, 13, 18)
            a.b(f"Finger{side}{i}", (xa, 0, zc - 1.4 - 1.5), (xb, 2.6, zc + 1.4 - 1.5), c["frost"], fore)
    a.meta = {"seat": (0, 34 * a.k, 9 * a.k), "neck_loop": {"center": (0, 23 * a.k, -4 * a.k), "radius": 7 * a.k}}
    return a


# ---------------------------------------------------------------- ice drake

def ice_drake():
    """The nether drake's shape and pose (its own bone rotations): a hunched
    wingless drake, long clawed arms, big bent back legs, a horned head low on
    a short neck, a long tail ending in an ice blade. In the Ice Dragon's
    colours: cyan scales, white fur rings at the joints, red eyes, white spikes."""
    c = dict(cyan=(56, 206, 238), plate=(30, 164, 214), fur=(252, 253, 255), belly=(196, 240, 252),
             horn=(206, 236, 252), spike=(236, 246, 255), eye=(236, 44, 64), slit=(40, 12, 24), mouth=(238, 104, 146))
    a = Conv("IceDrake", "Legendary", 0.34)
    a.pivots["root"] = np.array((0, 18, 0)) * a.k

    def ring(name, lo, hi, bone, out=1.0):
        a.b(name, (lo[0] - out, lo[1] - out, lo[2]), (hi[0] + out, hi[1] + out, hi[2]), c["fur"], bone)

    body = a.bone("Torso", "root", (0, 21, 12))
    a.b("Chest", (-10, 14, -18), (10, 25, -7), c["cyan"], body)
    a.b("ChestFront", (-6, 15, -21), (6, 23, -18), c["belly"], body)
    ring("Waist", (-7, 14, -7), (7, 22, -4.5), body, 0.6)
    a.b("Middle", (-7, 14, -4.5), (7, 22, 2), c["cyan"], body)
    a.b("Hips", (-8, 14, 2), (8, 22, 13), c["cyan"], body)
    a.b("BackPlate", (-7, 25, -16.5), (7, 26.4, -8.5), c["plate"], body)
    a.b("HipPlate", (-5.5, 22, 3.5), (5.5, 23.2, 11.5), c["plate"], body)
    for i, (z, y, h) in enumerate(((-15, 26.4, 4.2), (-11, 26.4, 5.2), (-4.5, 22, 3.2), (1, 22, 3.2), (6, 23.2, 3.8), (10, 23.2, 3))):
        a.pyr(f"Spike{i}", (-1.5, y, z - 1.5), (1.5, y, z + 1.5), "+y", h, c["spike"], body)
    # neck and head, the old model's bend; horns sweep back, jaw a little open
    neck = a.bone("neck", body, (0, 18, -16), (-17.5, 0, 0))
    ring("NeckRing", (-4, 14, -19), (4, 22, -16), neck, 0.8)
    a.b("Neck", (-4, 14, -26), (4, 22, -19), c["cyan"], neck)
    a.pyr("SpikeNeck", (-1.2, 22, -24), (1.2, 22, -21), "+y", 3, c["spike"], neck)
    head = a.bone("Head", neck, (0, 18.2, -25.9), (20, 0, 0))
    a.b("Skull", (-4.5, 17.5, -32), (4.5, 24, -25), c["cyan"], head)
    a.b("Brow", (-5, 23, -33), (5, 25, -29), c["plate"], head)
    a.b("Snout", (-3, 18, -38), (3, 22.5, -32), c["cyan"], head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 4.5, 20, 22.6, -31.5, -28.2, head, pupil=c["slit"], eye=c["eye"], slit=True)
        for i, z in enumerate((-37, -34.8, -32.6)):
            x0, x1 = X(sx, 1.8, 2.8)
            a.pyr(f"Upper_tooth{side}{i}", (x0, 18, z - 0.5), (x1, 18, z + 0.5), "-y", 1.2, c["spike"], head)
        horn = a.bone("Horn" + side, head, (sx * 3.2, 24.5, -29), (-32, sx * 18, 0))
        x0, x1 = X(sx, 1.8, 4.6)
        a.b("Horn" + side, (x0, 23.5, -30.5), (x1, 26.3, -25.5), c["horn"], horn)
        x0, x1 = X(sx, 2.3, 4.1)
        a.b("HornMid" + side, (x0, 24, -25.5), (x1, 25.8, -21.5), c["horn"], horn)
        a.pyr("SpikeHorn" + side, (x0, 24, -21.5), (x1, 25.8, -21.5), "+z", 4, c["spike"], horn)
    jaw = a.bone("Jaw", head, (0, 17.5, -26), (-15, 0, 0))
    a.b("Jaw", (-3, 15, -37), (3, 17.5, -26), c["belly"], jaw)
    a.b("Mouth", (-2.2, 17.4, -36), (2.2, 17.7, -27), c["mouth"], jaw)
    # arms: the old bends, a fur ring at the elbow, three white claws fanned forward
    for side, sx in SIDES:
        arm = a.bone("Arm" + side, body, (sx * 13.5, 18, -12.2), (27.5, 0, 0))
        x0, x1 = X(sx, 10, 17)
        a.b("Shoulder" + side, (x0, 12, -16), (x1, 22, -7), c["cyan"], arm)
        a.b("Elbow" + side, (x0, 12, -7), (x1, 18, 0), c["cyan"], arm)
        fore = a.bone("Forearm" + side, arm, (sx * 13.5, 12, -2), (17.5, 0, 0))
        x0, x1 = X(sx, 10.3, 16.7)
        a.b("ElbowRing" + side, (x0, 11, -3.8), (x1, 13.4, 1.6), c["fur"], fore)
        x0, x1 = X(sx, 11, 16)
        a.b("Forearm" + side, (x0, 4, -3.1), (x1, 11, 0.9), c["cyan"], fore)
        hand = a.bone("Hand" + side, fore, (sx * 13.5, 5.3, -2.9), (-45, 0, 0))
        x0, x1 = X(sx, 11, 16)
        a.b("Hand" + side, (x0, 1.4, -8), (x1, 5.4, -2), c["cyan"], hand)
        for i, xc in enumerate((11.9, 13.5, 15.1)):
            xa, xb = X(sx, xc - 0.7, xc + 0.7)
            a.pyr(f"Claw{side}{i}", (xa, 1.4, -8), (xb, 3.2, -8), "-z", 3, c["spike"], hand)
    # back legs: the old leg rotations, a big thigh, long shin, clawed foot
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 10.5, 19, 8.8), (68.12, sx * 23.4, -sx * 9.06))
        x0, x1 = X(sx, 7, 16)
        a.b("Thigh" + side, (x0, 13, 5), (x1, 23, 14), c["cyan"], leg)
        x0, x1 = X(sx, 7, 15)
        a.b("Knee" + side, (x0, 13, 14), (x1, 21, 22), c["cyan"], leg)
        shin = a.bone("Shin" + side, leg, (sx * 10.5, 26, 20), (-75, 0, 0))
        x0, x1 = X(sx, 8, 13)
        a.b("Shin" + side, (x0, 18, 19.5), (x1, 29.9, 23.5), c["cyan"], shin)
        x0, x1 = X(sx, 7.3, 13.7)
        a.b("Ankle" + side, (x0, 15.9, 18.8), (x1, 18, 24.2), c["fur"], shin)
        foot = a.bone("Foot" + side, shin, (sx * 9.5, 18.4, 20.3), (4.92, sx * -1.41, sx * 12.39))
        x0, x1 = X(sx, 8, 11.5)
        a.b("Foot" + side, (x0, 14.5, 14.6), (x1, 18.5, 21.6), c["cyan"], foot)
        for i, xc in enumerate((8.4, 9.75, 11.1)):
            xa, xb = X(sx, xc - 0.6, xc + 0.6)
            a.pyr(f"ClawH{side}{i}", (xa, 14.5, 14.6), (xb, 16.2, 14.6), "-z", 2.6, c["spike"], foot)
    # tail: three pieces, the last an ice blade
    t = a.bone("Tail", "root", (0, 22, 13.2), (42.5, 0, 0))
    ring("TailRing", (-4, 14, 13), (4, 22, 15), t, 0.6)
    a.b("Tail1", (-4, 14, 15), (4, 22, 34), c["cyan"], t)
    a.pyr("SpikeTail1", (-1.2, 22, 22), (1.2, 22, 25), "+y", 3, c["spike"], t)
    t1 = a.bone("Tail2", t, (0, 18, 34), (-35, 0, 0))
    ring("TailRing1", (-2.6, 14.6, 34), (2.6, 21.4, 36), t1, 0.5)
    a.b("Tail2", (-2.6, 14.6, 36), (2.6, 21.4, 52), c["cyan"], t1)
    a.pyr("SpikeTail2", (-1, 21.4, 42), (1, 21.4, 45), "+y", 2.6, c["spike"], t1)
    t2 = a.bone("Tail3", t1, (0, 18, 52), (-30, 0, 0))
    a.b("Tail3", (-1.8, 15.6, 52), (1.8, 20.4, 60), c["cyan"], t2)
    a.b("Blade", (-0.9, 14.6, 56), (0.9, 23, 66), c["spike"], t2)
    a.pyr("SpikeBlade", (-0.9, 14.6, 66), (0.9, 23, 66), "+z", 5, c["spike"], t2)
    a.meta = {"seat": (0, 26 * a.k, 0), "neck_loop": {"center": (0, 18 * a.k, -21 * a.k), "radius": 5.5 * a.k}}
    return a


# ---------------------------------------------------------------- build + render

CREATURES = [boar, white_wolf, troll, spine_lizard, ice_golem, ice_drake]
NAMES = {"WhiteWolf": "White Wolf", "SpineLizard": "Spine Lizard", "IceGolem": "Ice Golem", "IceDrake": "Ice Drake"}
PLAIN = ("Eye", "Pupil", "Nostril", "Mouth", "Slit", "Upper_tooth", "Tooth", "Claw", "Spike", "Tusk", "Fang",
         "Hole", "Scar", "Toe", "Crest", "Tuft", "Beard", "RayTip", "NoseTip", "TailTuft")


def rest_model(a):
    """The .bbmodel with the bones' rest rotations, and its posed parts."""
    model, groups = write_bbmodel(a.parts, a.name, None, bones=a.bones())
    for bone, r in a.rest.items():
        groups[bone]["rotation"] = [round(float(x), 3) for x in r]
    return model, posed(model)


def lift(a, dy):
    for p in a.parts:
        if p.shape == "Poly":
            p.polys = [q + np.array([0, dy, 0]) for q in p.polys]
        else:
            p.cf[1, 3] += dy
    a.pivots = {n: (v[0], v[1] + dy, v[2]) for n, v in a.pivots.items()}
    a.meta["seat"] = (a.meta["seat"][0], a.meta["seat"][1] + dy, a.meta["seat"][2])
    nl = a.meta["neck_loop"]["center"]
    a.meta["neck_loop"]["center"] = (nl[0], nl[1] + dy, nl[2])


def build(fn):
    """(animal, model dict, posed parts) with the posed model standing on y = 0."""
    a = fn()
    model, parts = rest_model(a)
    drop = min(q[:, 1].min() for p in parts for q in p.polys)
    if abs(drop) > 0.01:
        lift(a, -drop)
        model, parts = rest_model(a)
    for p in parts:
        if p.name.startswith(PLAIN):
            p.plain = True
    return a, model, parts


def save_model(a, model):
    os.makedirs(MODELS, exist_ok=True)
    path = os.path.join(MODELS, a.name + ".bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    return path


def points(parts):
    return np.concatenate([np.concatenate([w for w, _ in part_faces(p)]) for p in parts])


def bounds(parts):
    pts = points(parts)
    return pts.min(0), pts.max(0)


Q34_DIR = np.array([-19, 12, -21], float) / np.linalg.norm([-19, 12, -21])


def lineup(out):
    tiles = [("Horse · for size", pose(A.qm_horse("A"), None, 0))]
    for fn in CREATURES:
        a, model, parts = build(fn)
        save_model(a, model)
        tiles.append((f"{NAMES.get(a.name, a.name)} · {a.rarity}", parts))
    H, fov, dist, ty = 420, 30, 80, 8.0
    ims = []
    for name, parts in tiles:
        lo, hi = bounds(parts)
        target = np.array([(lo[0] + hi[0]) / 2, ty, (lo[2] + hi[2]) / 2])
        eye = target + Q34_DIR * dist
        e, r, u, f = look_at(eye, target)
        focal = (H / 2) / np.tan(np.radians(fov) / 2)
        d = points(parts) - e
        xs = focal * (d @ r) / (d @ f)
        W = int(max(130, 2 * max(abs(xs.min()), abs(xs.max())) + 16))
        ims.append((name, render(parts, eye=eye, target=target, W=W, H=H, fov=fov)))
    sheet = Image.new("RGB", (sum(im.width for _, im in ims), H))
    x = 0
    for _, im in ims:
        sheet.paste(im, (x, 0))
        x += im.width
    if sheet.width > 1600:
        k = 1600 / sheet.width
        sheet = sheet.resize((1600, round(H * k)), Image.LANCZOS)
        ims = [(n, im.resize((round(im.width * k), sheet.height))) for n, im in ims]
    path = os.path.join(out, "converted_lineup.png")
    label_tiles(sheet, ims).save(path)
    print("wrote", path)


def label_tiles(sheet, ims, size=15):
    from PIL import ImageDraw
    band = 44
    out = Image.new("RGB", (sheet.width, sheet.height + band), (255, 255, 255))
    out.paste(sheet, (0, band))
    d = ImageDraw.Draw(out)
    x = 0
    for name, im in ims:
        for row, text in enumerate(name.split(" · ")):
            tw = d.textlength(text, font=A.font(size))
            d.text((x + (im.width - tw) / 2, 4 + row * 19), text, fill=(20, 20, 20), font=A.font(size))
        x += im.width
    return out


def one(name, out, W=380):
    """Close look at one animal: 3/4 front, side, 3/4 back, front."""
    fn = next(f for f in CREATURES if f.__name__.replace("_", "") == name.lower().replace("_", ""))
    a, model, parts = build(fn)
    path = save_model(a, model)
    shutil.copy(path, os.path.join(out, a.name + ".bbmodel"))
    lo, hi = bounds(parts)
    c = (lo + hi) / 2
    radius = np.linalg.norm(hi - lo) / 2
    fov = 34
    dist = radius / np.tan(np.radians(fov) / 2) * 0.97
    views = [(-19, 12, -21), (-1, 0.15, -0.02), (17, 11, 20), (-0.12, 0.2, -1)]
    sheet = Image.new("RGB", (W * len(views), W))
    for i, v in enumerate(views):
        v = np.array(v, float) / np.linalg.norm(v)
        sheet.paste(render(parts, eye=c + v * dist, target=c, W=W, H=W, fov=fov), (i * W, 0))
    path = os.path.join(out, f"{a.name}.png")
    A.label(sheet, [f"{NAMES.get(a.name, a.name)} · {a.rarity}", "side", "back", "front"], 17).save(path)
    print("wrote", path, len(a.parts), "parts")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "one":
        target = args[2] if len(args) > 2 else OUT
        os.makedirs(target, exist_ok=True)
        one(args[1], target)
    else:
        target = args[0] if args else OUT
        os.makedirs(target, exist_ok=True)
        lineup(target)
        for fn in CREATURES:
            one(fn.__name__, target)
