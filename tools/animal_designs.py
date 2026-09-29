"""Five more animals in the Toy horse's style, each rarer and fancier than the
last, plus a matching egg for each. Exported as rigged Blockbench models that
reuse the horse's bones and idle / walk / gallop animations, with previews.

Run: python3 tools/animal_designs.py [out_dir] [egg_out_dir]

  Horse    Common     (existing, Horse7_ToyRig.bbmodel)
  Cow      Uncommon   farm: black patches, pink muzzle, horns, floppy side ears
  Zebra    Rare       wild: horse build cut into black and white stripes
  Rhino    Epic       wild: bulky and low, head out front, two horns, armour bands
  Giraffe  Epic       wild: long legs and neck, patches, ossicones
  Unicorn  Legendary  exotic: white horse, rainbow mane and tail, gold horn and hooves

Same rules as the horse: every block axis-aligned and flush, slopes only from
wedges, eyes and patches are thin plates. Bones match the horse so the same
animations fit: legs and neck bend forward only, tail lifts back, ears fold back.
"""

import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, Rx, Ry, render, write_bbmodel  # noqa: E402
from horse_rig import animations as horse_animations, pose, write_animations  # noqa: E402
import egg_designs as E  # noqa: E402

WHITE = (248, 248, 244)
EYE_WHITE = (255, 255, 255)
PUPIL = (30, 30, 45)
PINK = (242, 150, 192)
HOOF = (74, 78, 102)

PLATE = 0.05  # how far patches and eyes stand off a face

LEGS = ("FL", "FR", "HL", "HR")


class Animal:
    def __init__(self, name, rarity):
        self.name, self.rarity = name, rarity
        self.parts = []
        self.pivots = {}
        self.meta = {}

    def box(self, name, lo, hi, color, bone):
        lo, hi = np.array(lo, float), np.array(hi, float)
        plain = name.startswith(("Eye", "Pupil", "Nostril", "Plain"))
        p = Part(name, hi - lo, T(*((lo + hi) / 2)), color, plain=plain)
        p.bone = bone
        self.parts.append(p)
        return p

    def wedge(self, name, lo, hi, color, bone, orient="up_front"):
        """up_front: tall at the back, slope faces forward (a plain WedgePart).
        up_back: tall at the front. down_back: flat top and front, slope faces down and back."""
        lo, hi = np.array(lo, float), np.array(hi, float)
        R = {"up_front": np.eye(4), "up_back": Ry(180), "down_back": Rx(180)}[orient]
        p = Part(name, hi - lo, T(*((lo + hi) / 2)) @ R, color, "Wedge")
        p.bone = bone
        self.parts.append(p)
        return p

    def tri(self, name, pts, z0, z1, color, bone):
        """Right-triangle prism, (x, y) points with the right angle first, extruded along z."""
        faces = [[(x, y, z0) for x, y in pts], [(x, y, z1) for x, y in pts[::-1]]]
        for a, b in ((0, 1), (1, 2), (2, 0)):
            faces.append([(pts[a][0], pts[a][1], z0), (pts[a][0], pts[a][1], z1),
                          (pts[b][0], pts[b][1], z1), (pts[b][0], pts[b][1], z0)])
        plain = "In" in name
        p = Part(name, (1, 1, 1), np.eye(4), color, "Poly", plain)
        p.polys = [np.array(f, float) for f in faces]
        p.bone = bone
        self.parts.append(p)
        return p

    # ------------------------------------------------ shared body parts

    def body(self, x, y0, y1, z0, z1, color, bands=None):
        """Body block; bands = [(z0, z1, color)] cut it into flush slices."""
        self.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
        self.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
        if not bands:
            self.box("Body", (-x, y0, z0), (x, y1, z1), color, "root")
            return
        for i, (a, b, c) in enumerate(bands):
            self.box(f"Body{i + 1}", (-x, y0, a), (x, y1, b), c, "root")

    def legs(self, xin, xout, depth, hoof_h, color, hoof, segments=None):
        """Four legs under the body, flush with its front, back and sides.
        segments = [(y0, y1, color)] replaces the single leg block (stripes)."""
        d = self.dims
        y0 = d["y0"]
        for leg in LEGS:
            sx = -1 if leg[1] == "L" else 1
            front = leg[0] == "F"
            z0 = d["z0"] + 0.001 if front else d["z1"] - 0.001 - depth
            z1 = z0 + depth
            xa, xb = sorted((sx * xin, sx * xout))
            name = "Leg" + leg
            if segments:
                for i, (a, b, c) in enumerate(segments):
                    self.box(f"{name}{i + 1}" if i else name, (xa, a, z0), (xb, b, z1), c, name)
            else:
                self.box(name, (xa, hoof_h, z0), (xb, y0, z1), color, name)
            self.box("Hoof" + leg, (xa, 0, z0), (xb, hoof_h, z1), hoof, name)
            # pivot on the top-back edge, so the leg only swings forward
            self.pivots[name] = ((xa + xb) / 2, y0 - 0.025, z1 - 0.05)

    def tail(self, w, y_top, y_bot, depth, color, tip_color=None, tip_h=0.8, bands=None):
        d = self.dims
        z0, z1 = d["z1"], d["z1"] + depth
        tip = y_bot + tip_h
        if bands:
            for i, (a, b, c) in enumerate(bands):
                self.box(f"Tail{i + 1}" if i else "Tail", (-w, a, z0), (w, b, z1), c, "Tail")
        else:
            self.box("Tail", (-w, tip, z0), (w, y_top, z1), color, "Tail")
        self.wedge("TailTip", (-w, y_bot, z0), (w, tip, z1), tip_color or color, "Tail", "down_back")
        self.pivots["Tail"] = (0, y_top, z0)

    def eyes(self, x, y0, y1, z0, z1, bone="neck"):
        """White plates on both sides of the head, pupils looking forward."""
        py1 = y0 + (y1 - y0) * 0.7
        pz1 = z0 + (z1 - z0) * 0.5
        for side, sx in (("L", -1), ("R", 1)):
            xa, xb = sorted((sx * x, sx * (x + PLATE)))
            self.box("Eye" + side, (xa, y0, z0), (xb, y1, z1), EYE_WHITE, bone)
            pa, pb = sorted((sx * x, sx * (x + PLATE + 0.03)))
            self.box("Pupil" + side, (pa, y0 + (y1 - y0) * 0.1, z0), (pb, py1, pz1), PUPIL, bone)

    def upright_ears(self, cx, base, z0, z1, half, h, color, inner=PINK):
        """Horse ears: two right-triangle halves each, pink inner plate on the front."""
        for side, sx in (("L", -1), ("R", 1)):
            c = sx * cx
            bone = "Ear" + side
            for half_name, dx in (("A", -1), ("B", 1)):
                self.tri(f"Ear{side}{half_name}", [(c, base), (c + dx * half, base), (c, base + h)], z0, z1, color, bone)
                self.tri(f"Ear{side}In{half_name}", [(c, base + 0.08), (c + dx * half * 0.55, base + 0.08), (c, base + h * 0.69)],
                         z0 - 0.06, z0, inner, bone)
            self.pivots[bone] = (c, base, z0)

    def side_ears(self, x, x_out, y0, y1, z0, z1, color, inner=PINK):
        """Floppy ears sticking out sideways, inner colour on the front."""
        for side, sx in (("L", -1), ("R", 1)):
            bone = "Ear" + side
            xa, xb = sorted((sx * x, sx * x_out))
            self.box("Ear" + side, (xa, y0, z0), (xb, y1, z1), color, bone)
            ia, ib = sorted((sx * (x + 0.1), sx * (x_out - 0.1)))
            self.box(f"Ear{side}In", (ia, y0 + 0.08, z0 - PLATE), (ib, y1 - 0.08, z0), inner, bone)
            self.pivots[bone] = (sx * x, y0, z0)

    def patch(self, name, face, a0, a1, b0, b1, color, bone="root", box=None):
        """Thin plate on a block face. face in L, R (x sides: a = z, b = y),
        T (top: a = x, b = z), F (front: a = x, b = y). box = (lo, hi) of the block."""
        (x0, y0, z0), (x1, y1, z1) = box
        if face == "L":
            return self.box(name, (x0 - PLATE, b0, a0), (x0, b1, a1), color, bone)
        if face == "R":
            return self.box(name, (x1, b0, a0), (x1 + PLATE, b1, a1), color, bone)
        if face == "T":
            return self.box(name, (a0, y1, b0), (a1, y1 + PLATE, b1), color, bone)
        if face == "F":
            return self.box(name, (a0, b0, z0 - PLATE), (a1, b1, z0), color, bone)
        raise ValueError(face)

    def bones(self):
        order = [("root", None), ("neck", "root"), ("EarL", "neck"), ("EarR", "neck"), ("Tail", "root")]
        order += [("Leg" + leg, "root") for leg in LEGS]
        return [(n, p, self.pivots[n]) for n, p in order]


def horse_like(a, coat, mane, hoof=HOOF, body_bands=None, leg_segments=None, neck_bands=None, tail_bands=None,
               tail_tip=None, ear=None, ear_inner=PINK, muzzle=None, cap=True):
    """The Toy horse's layout (same numbers as Horse7_ToyRig), with hooks for recolouring."""
    ear = ear or coat
    a.body(1.6, 3.5, 6.5, -2.7, 3.3, coat, body_bands)
    a.legs(0.5, 1.6, 1.1, 0.8, coat, hoof, leg_segments)
    if neck_bands:
        for i, (y0, y1, c) in enumerate(neck_bands):
            a.box(f"Neck{i + 1}" if i else "Neck", (-0.9, y0, -2.699), (0.9, y1, -1.099), c, "neck")
    else:
        a.box("Neck", (-0.9, 5.1, -2.699), (0.9, 8.3, -1.099), coat, "neck")
    a.box("Head", (-1.1, 8.3, -3.9), (1.1, 10.5, -1.1), coat, "neck")
    a.box("Snout", (-1.1, 8.3, -5.1), (1.1, 9.7, -3.9), muzzle or coat, "neck")
    a.wedge("Bridge", (-1.1, 9.7, -5.1), (1.1, 10.5, -3.9), muzzle or coat, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.3, sx * 0.8))
        a.box("Nostril" + side, (xa, 8.9, -5.15), (xb, 9.2, -5.1), (70, 44, 36), "neck")
    a.eyes(1.1, 9.1, 10.1, -3.5, -2.5)
    a.upright_ears(0.75, 10.5, -1.5, -1.1, 0.35, 1.2, ear, ear_inner)
    a.pivots["neck"] = (0, 6.444, -2.7835)
    if mane is not None:
        a.box("NeckFill", (-0.9, 4.1, -1.099), (0.9, 6.5, 0.101), mane, "neck")
        a.wedge("Mane", (-0.9, 6.5, -1.1), (0.9, 8.3, 0.1), mane, "neck", "up_back")
        if cap:
            a.box("Cap", (-0.4, 10.5, -2.3), (0.4, 11.1, -1.1), mane, "neck")
    a.tail(0.4, 6.5, 3.5, 0.8, mane, tail_tip, bands=tail_bands)
    a.meta = {"seat": (0, 7.3, 1), "neck_loop": {"center": (0, 7.4, -1.9), "radius": 1.35}}


# ---------------------------------------------------------------- the five

def cow():
    a = Animal("Cow", "Uncommon")
    black, muzzle, horn, hoof = (40, 40, 46), (240, 166, 176), (236, 222, 184), (62, 62, 72)
    # wider and lower than the horse, short sturdy legs
    a.body(1.8, 3.0, 6.4, -2.9, 3.5, WHITE)
    body = ((-1.8, 3.0, -2.9), (1.8, 6.4, 3.5))
    a.legs(0.6, 1.8, 1.2, 0.6, WHITE, hoof)
    # black patches, not mirrored so they look natural
    a.patch("SpotL1", "L", -2.4, -0.4, 4.0, 6.4, black, box=body)
    a.patch("SpotL2", "L", 1.1, 2.6, 3.5, 5.5, black, box=body)
    a.patch("SpotR1", "R", -1.4, 0.6, 4.5, 6.4, black, box=body)
    a.patch("SpotR2", "R", 1.6, 3.1, 3.0, 4.5, black, box=body)
    a.patch("SpotT1", "T", -1.8, -0.3, -0.4, 0.6, black, box=body)
    a.patch("SpotT2", "T", 0.2, 1.8, 1.6, 3.1, black, box=body)
    a.patch("SpotT3", "T", -1.8, -0.8, 2.6, 3.5, black, box=body)
    # short thick neck, square head with a big pink muzzle
    a.box("Neck", (-1.0, 4.6, -2.899), (1.0, 7.6, -1.199), WHITE, "neck")
    a.box("Head", (-1.2, 7.6, -3.9), (1.2, 9.6, -1.0), WHITE, "neck")
    a.box("Snout", (-1.2, 7.6, -5.0), (1.2, 8.9, -3.9), muzzle, "neck")
    a.wedge("Bridge", (-1.2, 8.9, -5.0), (1.2, 9.6, -3.9), WHITE, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.35, sx * 0.85))
        a.box("Nostril" + side, (xa, 8.2, -5.05), (xb, 8.5, -5.0), (170, 90, 104), "neck")
    head = ((-1.2, 7.6, -3.9), (1.2, 9.6, -1.0))
    a.patch("SpotHead", "L", -3.9, -2.2, 8.9, 9.6, black, "neck", box=head)
    a.patch("SpotNeck", "R", -2.4, -1.2, 6.4, 7.6, black, "neck", box=((-1.0, 4.6, -2.9), (1.0, 7.6, -1.2)))
    a.eyes(1.2, 8.4, 9.3, -3.5, -2.6)
    # horns: out, then up
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.5, sx * 1.5))
        a.box("Horn" + side, (xa, 9.6, -2.0), (xb, 10.0, -1.6), horn, "neck")
        xa, xb = sorted((sx * 1.1, sx * 1.5))
        a.box("HornTip" + side, (xa, 10.0, -2.0), (xb, 10.6, -1.6), horn, "neck")
    a.side_ears(1.2, 2.0, 8.9, 9.3, -1.5, -1.1, WHITE, muzzle)
    a.pivots["neck"] = (0, 6.35, -2.98)
    a.box("Cap", (-0.5, 9.6, -2.8), (0.5, 9.9, -2.0), black, "neck")
    # thin tail with a black tuft
    a.tail(0.3, 6.4, 3.0, 0.6, WHITE, black, tip_h=1.2)
    a.box("Tuft", (-0.3, 4.2, 3.5), (0.3, 4.8, 4.1), black, "Tail")
    a.meta = {"seat": (0, 7.2, 1.2), "neck_loop": {"center": (0, 7.0, -2.0), "radius": 1.5}}
    return a


def zebra():
    a = Animal("Zebra", "Rare")
    black = (36, 36, 42)
    # stripes are flush slices of the body, legs and neck: no plates to z-fight
    z, bands = -2.7, []
    for i, w in enumerate((1.0, 0.5, 1.0, 0.5, 1.0, 0.5, 1.0, 0.5)):
        bands.append((z, z + w, WHITE if i % 2 == 0 else black))
        z += w
    legs = [(0.8, 1.6, WHITE), (1.6, 2.1, black), (2.1, 3.5, WHITE)]
    neck = [(5.1, 7.0, WHITE), (7.0, 7.5, black), (7.5, 8.3, WHITE)]
    tail = [(4.3, 5.4, WHITE), (5.4, 5.9, black), (5.9, 6.5, WHITE)]
    horse_like(a, WHITE, black, (40, 40, 48), bands, legs, neck, tail, tail_tip=black,
               ear_inner=black, muzzle=(58, 58, 66))
    # black stripe over the forehead and a taller mohawk
    for p in a.parts:
        if p.name == "Cap":
            a.parts.remove(p)
            break
    a.box("Mohawk", (-0.3, 10.5, -2.5), (0.3, 11.4, -1.1), black, "neck")
    head = ((-1.1, 8.3, -3.9), (1.1, 10.5, -1.1))
    a.patch("StripeHeadL", "L", -2.3, -1.8, 8.3, 10.5, black, "neck", box=head)
    a.patch("StripeHeadR", "R", -2.3, -1.8, 8.3, 10.5, black, "neck", box=head)
    return a


def rhino():
    a = Animal("Rhino", "Epic")
    grey, dark, horn, hoof = (150, 156, 170), (112, 118, 134), (240, 232, 208), (84, 88, 102)
    # bulky and low; darker skin folds cut into the body
    bands = [(-3.2, -1.2, grey), (-1.2, -0.7, dark), (-0.7, 1.8, grey), (1.8, 2.3, dark), (2.3, 3.6, grey)]
    a.body(2.0, 2.8, 6.6, -3.2, 3.6, grey, bands)
    a.legs(0.6, 2.0, 1.4, 0.6, grey, hoof)
    # no neck to speak of: a thick block on the body's front, the head hung low in front of it
    a.box("Neck", (-1.5, 3.6, -4.2), (1.5, 6.2, -3.199), grey, "neck")
    a.box("Head", (-1.2, 3.4, -6.6), (1.2, 5.6, -4.2), grey, "neck")
    a.box("Snout", (-1.2, 3.4, -7.4), (1.2, 4.8, -6.6), grey, "neck")
    a.wedge("Bridge", (-1.2, 4.8, -7.4), (1.2, 5.6, -6.6), grey, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.4, sx * 0.9))
        a.box("Nostril" + side, (xa, 3.9, -7.45), (xb, 4.2, -7.4), (60, 62, 74), "neck")
    # big horn on the nose, small one behind it
    a.box("HornBase", (-0.4, 5.6, -6.6), (0.4, 6.0, -5.6), horn, "neck")
    a.wedge("Horn", (-0.4, 6.0, -6.6), (0.4, 7.8, -5.6), horn, "neck")
    a.wedge("Horn2", (-0.3, 5.6, -5.2), (0.3, 6.6, -4.6), horn, "neck")
    a.eyes(1.2, 4.4, 5.2, -5.6, -4.8)
    a.upright_ears(0.95, 6.2, -3.9, -3.5, 0.35, 1.0, grey, (206, 150, 170))
    a.pivots["neck"] = (0, 6.2, -3.2)
    # short tail with a dark tuft
    a.tail(0.3, 6.4, 4.0, 0.6, grey, dark, tip_h=0.8)
    a.meta = {"seat": (0, 7.4, 2.2), "neck_loop": {"center": (0, 5.2, -3.7), "radius": 1.9}}
    return a


def giraffe():
    a = Animal("Giraffe", "Epic")
    yellow, brown, muzzle, hoof, knob = (240, 190, 80), (164, 94, 42), (248, 222, 160), (82, 58, 42), (92, 54, 34)
    a.body(1.5, 5.0, 7.6, -2.6, 2.6, yellow)
    body = ((-1.5, 5.0, -2.6), (1.5, 7.6, 2.6))
    a.legs(0.5, 1.5, 1.0, 0.7, yellow, hoof)
    for i, (face, a0, a1, b0, b1) in enumerate((
            ("L", -2.1, -1.1, 6.1, 7.1), ("L", -0.6, 0.6, 5.6, 6.8), ("L", 1.1, 2.1, 6.3, 7.3),
            ("R", -2.1, -0.9, 5.7, 6.9), ("R", -0.4, 0.6, 6.4, 7.4), ("R", 1.0, 2.2, 5.5, 6.6),
            ("T", -1.2, -0.2, -1.8, -0.8), ("T", 0.3, 1.3, -0.3, 0.9), ("T", -1.1, 0.1, 1.2, 2.2))):
        a.patch(f"Spot{i + 1}", face, a0, a1, b0, b1, brown, box=body)
    # one patch per leg, above the knee
    for leg in LEGS:
        sx = -1 if leg[1] == "L" else 1
        z0 = -2.599 if leg[0] == "F" else 1.599
        lb = ((min(sx * 0.5, sx * 1.5), 0.7, z0), (max(sx * 0.5, sx * 1.5), 5.0, z0 + 1.0))
        a.patch("SpotLeg" + leg, "L" if sx < 0 else "R", z0 + 0.2, z0 + 0.8, 3.2, 4.0, brown, "Leg" + leg, box=lb)
    # the long neck, with patches up both sides and a short mane
    a.box("Neck", (-0.7, 6.2, -2.599), (0.7, 13.0, -1.199), yellow, "neck")
    neck = ((-0.7, 6.2, -2.6), (0.7, 13.0, -1.2))
    for i, (face, y0) in enumerate((("L", 8.0), ("L", 10.6), ("R", 9.2), ("R", 11.6))):
        a.patch(f"SpotNeck{i + 1}", face, -2.4, -1.4, y0, y0 + 0.9, brown, "neck", box=neck)
    a.box("Mane", (-0.2, 7.6, -1.199), (0.2, 13.0, -1.0), brown, "neck")
    a.box("Head", (-0.9, 13.0, -3.4), (0.9, 14.8, -1.0), yellow, "neck")
    a.box("Snout", (-0.9, 13.0, -4.6), (0.9, 14.2, -3.4), muzzle, "neck")
    a.wedge("Bridge", (-0.9, 14.2, -4.6), (0.9, 14.8, -3.4), yellow, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.25, sx * 0.65))
        a.box("Nostril" + side, (xa, 13.5, -4.65), (xb, 13.8, -4.6), (120, 80, 50), "neck")
        # ossicones with dark knobs
        xa, xb = sorted((sx * 0.25, sx * 0.65))
        a.box("Ossicone" + side, (xa, 14.8, -1.8), (xb, 15.6, -1.4), yellow, "neck")
        a.box("Knob" + side, (xa, 15.6, -1.8), (xb, 15.9, -1.4), knob, "neck")
    a.eyes(0.9, 13.7, 14.5, -3.0, -2.2)
    a.side_ears(0.9, 1.6, 14.2, 14.5, -1.4, -1.0, yellow, muzzle)
    a.pivots["neck"] = (0, 7.55, -2.68)
    a.tail(0.25, 7.6, 4.6, 0.5, yellow, knob, tip_h=0.9)
    a.meta = {"seat": (0, 8.4, 0.8), "neck_loop": {"center": (0, 8.6, -1.9), "radius": 1.1}}
    return a


RAINBOW = [(236, 72, 72), (248, 150, 50), (250, 214, 60), (96, 200, 90), (70, 150, 236), (160, 100, 220)]


def unicorn():
    a = Animal("Unicorn", "Legendary")
    white, gold, lilac = (252, 250, 255), (255, 200, 60), (206, 170, 240)
    tail = [(6.5 - 0.5 * (i + 1), 6.5 - 0.5 * i, c) for i, c in enumerate(RAINBOW[:5])][::-1]
    horse_like(a, white, None, gold, tail_bands=tail, tail_tip=RAINBOW[5], ear_inner=PINK)
    # the tail's banded blocks run 4.0..6.5; its tip wedge sits under them
    for p in a.parts:
        if p.name == "TailTip":
            a.parts.remove(p)
            break
    a.wedge("TailTip", (-0.4, 3.2, 3.3), (0.4, 4.0, 4.1), RAINBOW[5], "Tail", "down_back")
    # rainbow mane: locks stepping further back as they go down the neck
    for i, c in enumerate(RAINBOW):
        y1 = 8.3 - 0.3 * i
        a.box(f"Mane{i + 1}" if i else "Mane", (-0.9, y1 - 0.3, -1.1), (0.9, y1, -0.9 + 0.2 * i), c, "neck")
    a.box("NeckFill", (-0.9, 4.1, -1.099), (0.9, 6.5, 0.101), RAINBOW[5], "neck")
    a.box("Cap", (-0.4, 10.5, -2.3), (0.4, 11.1, -1.1), lilac, "neck")
    # stepped gold horn on the forehead
    for i, (w, y0, y1) in enumerate(((0.3, 10.5, 11.0), (0.2, 11.0, 11.6), (0.1, 11.6, 12.3))):
        a.box(f"Horn{i + 1}" if i else "Horn", (-w, y0, -3.3 - w), (w, y1, -3.3 + w), gold, "neck")
    return a


ANIMALS = [cow, zebra, rhino, giraffe, unicorn]


# ---------------------------------------------------------------- eggs

def octo_egg(colors, pieces=None, crack_layer=4):
    """Octo Stack egg like the horse's: 7 octagonal layers, black crack plates.
    colors: one per layer. pieces: {(layer, piece): color} to paint patches,
    piece in Mid, Front, Back, CornerLF, CornerRF, CornerLB, CornerRB."""
    egg = E.Egg()
    n = 7
    h = E.H / n
    crack = crack_layer * h
    widths = [E.snap(2 * E.radius((i + 0.5) * h)) for i in range(n)]
    for i in range(n):
        E.octo_layer(egg, i, i * h, (i + 1) * h, widths[i], colors[i], "top" if i >= crack_layer else "bottom")
    for (i, piece), c in (pieces or {}).items():
        for p in egg.parts:
            if p.name == f"L{i}{piece}":
                p.color = c
    inner = min(widths[crack_layer - 1], widths[crack_layer]) - 0.16
    E.octo_layer(egg, "InsideBottom", crack, crack + 0.02, inner, E.BLACK, "bottom")
    E.octo_layer(egg, "InsideTop", crack - 0.02, crack, inner, E.BLACK, "top")
    egg.widths, egg.h = widths, h
    return egg


def top_block(egg, name, lo, hi, color):
    egg.block(name, lo, hi, color).bone = "top"


def pony_ears(egg, color, inner, x0=0.35, h=0.7):
    b = E.H - 0.05
    for side, sx in (("L", -1), ("R", 1)):
        c = sx * x0
        for half, d in (("A", -1), ("B", 1)):
            E.ear_half(egg, f"Ear{side}{half}", [(c, b), (c + d * 0.25, b), (c, b + h)], -0.15, 0.15, color)
            E.ear_half(egg, f"EarIn{side}{half}", [(c, b + 0.08), (c + d * 0.13, b + 0.08), (c, b + h * 0.64)], -0.19, -0.15, inner)


def side_ears(egg, color, inner):
    """Ears lying on the shelf of layer 5, poking out of the top layer's sides."""
    y0 = 6 * egg.h
    top = egg.widths[6] / 2
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * top, sx * (top + 0.4)))
        top_block(egg, "Ear" + side, (xa, y0, -0.15), (xb, y0 + 0.2, 0.15), color)
        ia, ib = sorted((sx * (top + 0.08), sx * (top + 0.32)))
        top_block(egg, f"EarIn{side}", (ia, y0 + 0.04, -0.19), (ib, y0 + 0.16, -0.15), inner)


def cow_egg():
    white, black, muzzle, horn = WHITE, (40, 40, 46), (240, 166, 176), (236, 222, 184)
    egg = octo_egg([muzzle] * 2 + [white] * 5, {
        (2, "CornerLB"): black, (2, "Back"): black, (3, "Front"): black, (3, "CornerRF"): black,
        (4, "CornerRF"): black, (5, "CornerLF"): black, (4, "CornerLF"): black, (6, "Back"): black})
    t = E.H - 0.05
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.15, sx * 0.55))
        top_block(egg, "Horn" + side, (xa, t, -0.15), (xb, t + 0.25, 0.15), horn)
        xa, xb = sorted((sx * 0.35, sx * 0.55))
        top_block(egg, "HornTip" + side, (xa, t + 0.25, -0.15), (xb, t + 0.55, 0.15), horn)
    side_ears(egg, white, muzzle)
    return egg


def zebra_egg():
    white, black = WHITE, (36, 36, 42)
    egg = octo_egg([white if i % 2 == 0 else black for i in range(7)])
    pony_ears(egg, white, black)
    top_block(egg, "Mohawk", (-0.1, E.H - 0.05, -0.1), (0.1, E.H + 0.45, 0.5), black)
    return egg


def rhino_egg():
    grey, dark, horn = (150, 156, 170), (112, 118, 134), (240, 232, 208)
    egg = octo_egg([dark, grey, dark, grey, grey, dark, grey])
    t = E.H - 0.05
    w = egg.widths[6] / 2
    p = Part("Horn", (0.4, 0.75, 0.5), T(0, t + 0.375, -w + 0.25), horn, "Wedge")
    p.bone = "top"
    egg.parts.append(p)
    pony_ears(egg, grey, (206, 150, 170), x0=0.3, h=0.45)
    for p in egg.parts:
        if p.name.startswith("Ear"):
            p.polys = [q + np.array([0, 0, 0.3]) for q in p.polys]
    return egg


def giraffe_egg():
    yellow, brown, muzzle, knob = (240, 190, 80), (164, 94, 42), (248, 222, 160), (92, 54, 34)
    egg = octo_egg([muzzle] * 2 + [yellow] * 5, {
        (2, "CornerLF"): brown, (2, "CornerRB"): brown, (3, "Back"): brown, (3, "Mid"): brown,
        (4, "Front"): brown, (4, "CornerRB"): brown, (5, "CornerLB"): brown, (5, "CornerRF"): brown,
        (6, "Mid"): brown})
    t = E.H - 0.05
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.15, sx * 0.4))
        top_block(egg, "Ossicone" + side, (xa, t, -0.1), (xb, t + 0.5, 0.15), yellow)
        top_block(egg, "Knob" + side, (xa, t + 0.5, -0.1), (xb, t + 0.7, 0.15), knob)
    side_ears(egg, yellow, muzzle)
    return egg


def unicorn_egg():
    white, gold = (252, 250, 255), (255, 200, 60)
    egg = octo_egg([gold, white, white, gold, white, white, white])
    pony_ears(egg, white, PINK, x0=0.42, h=0.55)
    t = E.H - 0.05
    for i, (w, y0, y1) in enumerate(((0.18, 0, 0.35), (0.12, 0.35, 0.7), (0.06, 0.7, 1.1))):
        top_block(egg, f"Horn{i + 1}" if i else "Horn", (-w, t + y0, -0.3 - w), (w, t + y1, -0.3 + w), gold)
    # rainbow tuft behind the horn, stepping down toward the back
    for i, c in enumerate(RAINBOW):
        z0 = -0.05 + 0.1 * i
        top_block(egg, f"Tuft{i + 1}" if i else "Tuft", (-0.12, t, z0), (0.12, t + 0.55 - 0.06 * i, z0 + 0.1), c)
    return egg


EGGS = {"Cow": cow_egg, "Zebra": zebra_egg, "Rhino": rhino_egg, "Giraffe": giraffe_egg, "Unicorn": unicorn_egg}


# ---------------------------------------------------------------- export + previews

def build_animal(a, out):
    model, groups = write_bbmodel(a.parts, a.name, None, bones=a.bones())
    write_animations(model, groups, horse_animations())
    with open(os.path.join(out, a.name + ".bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    return model


def font(size):
    try:
        return ImageFont.truetype("DejaVuSans-Bold.ttf", size)
    except OSError:
        return ImageFont.load_default()


TILE_W, TILE_H = 300, 440
Q34 = dict(eye=(-22, 15, -24), target=(0, 7.2, -0.5), W=TILE_W, H=TILE_H, fov=36)
SIDE = dict(eye=(-34, 7.5, -1), target=(0, 7.2, -1), W=TILE_W, H=TILE_H, fov=34)


def lineup(models, anim_name=None, t=0.0, cam=Q34):
    """One tile per animal, same camera and scale, so sizes compare."""
    tiles = []
    for m in models:
        anim = next((x for x in m["animations"] if x["name"] == anim_name), None) if anim_name else None
        tiles.append(render(pose(m, anim, t), **cam))
    im = Image.new("RGB", (TILE_W * len(tiles), tiles[0].height))
    for i, tile in enumerate(tiles):
        im.paste(tile, (TILE_W * i, 0))
    return im


def label(im, names, top=True, size=22):
    band = 40
    out = Image.new("RGB", (im.width, im.height + band), (255, 255, 255))
    out.paste(im, (0, band if top else 0))
    d = ImageDraw.Draw(out)
    w = im.width / len(names)
    for i, text in enumerate(names):
        tw = d.textlength(text, font=font(size))
        d.text((w * i + (w - tw) / 2, 8 if top else im.height + 8), text, fill=(20, 20, 20), font=font(size))
    return out


def main(out="designs/animals", egg_out="designs/animals/eggs"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(egg_out, exist_ok=True)
    horse = json.load(open(os.path.join(os.path.dirname(__file__), "..", "designs", "horses", "Horse7_ToyRig.bbmodel")))
    horse_egg = json.load(open(os.path.join(os.path.dirname(__file__), "..", "designs", "eggs", "Egg6_PonyOcto.bbmodel")))
    models, eggs, names, meta = [horse], [horse_egg], ["Horse · Common"], {}
    for fn in ANIMALS:
        a = fn()
        models.append(build_animal(a, out))
        names.append(f"{a.name} · {a.rarity}")
        meta[a.name] = dict(rarity=a.rarity, **a.meta)
        egg = EGGS[a.name]()
        eggs.append(E.build(egg, a.name + "Egg", egg_out))
        print(f"{a.name}: {len(a.parts)} parts, egg {len(egg.parts)} parts")
    with open(os.path.join(out, "meta.json"), "w") as f:
        json.dump(meta, f, indent=1)

    label(lineup(models), names).save(os.path.join(out, "lineup.png"))
    label(lineup(models, cam=SIDE), names).save(os.path.join(out, "lineup_side.png"))

    # gallop lineup
    fps, L = 20, 0.6
    frames = [lineup(models, "gallop", i / fps).resize((TILE_W * len(models) * 2 // 3, TILE_H * 2 // 3)) for i in range(int(L * fps))]
    frames[0].save(os.path.join(out, "gallop.gif"), save_all=True, append_images=frames[1:], duration=int(1000 / fps), loop=0)

    # eggs: still, twitch and hatch, one tile each like the animals
    cam = dict(eye=(-6.5, 5.2, -7.5), target=(0, 1.9, 0), W=TILE_W, H=300, fov=34)

    def egg_frame(anim_name, t):
        return lineup(eggs, anim_name, t, cam)

    label(egg_frame(None, 0), [n.split(" ·")[0] + " Egg" for n in names]).save(os.path.join(egg_out, "eggs.png"))
    for anim_name, length in (("twitch", 1.2), ("hatch", 2.0)):
        frames = [egg_frame(anim_name, i / fps).resize((TILE_W * 4, 200)) for i in range(int(length * fps))]
        frames += [frames[-1]] * 8
        frames[0].save(os.path.join(egg_out, f"{anim_name}.gif"), save_all=True, append_images=frames[1:],
                       duration=int(1000 / fps), loop=0)
    print("previews written")


if __name__ == "__main__":
    main(*sys.argv[1:])
