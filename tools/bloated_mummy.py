"""Bloated Mummy: World 2 Ancient Tomb's Uncommon (QM, Oct 13: the final biome's animals are
very detailed). After the Tomb of the Ancients enemy that "flashes and grows": a fat, round,
waddling mummy, funny rather than scary.

A stepped ball of a body wrapped in cream bandages, each wrap a little tilted so they look
wound on by hand, in the tomb's two sand tones. A small wrapped head sits hunched on the front
of the ball with a dark eye slit and two mismatched white plate eyes with glowing green pupils;
one bandage has slipped down over the right eye and a crooked little "o" mouth peeks out under
it. Zombie arms reach forward with gold cuffs and wrapped three-finger mitts; stubby legs with
gold anklets. Gold treasure: a broad Egyptian collar in gold, lapis and carnelian with a fringe
of beads, a gold scarab amulet with lapis wings and a red sun disc on a gold chain, a gold
headband with a lapis gem. Torn holes glow green inside with little green wisps floating out,
and a teal scarab beetle crawls out of one. Loose bandage ends hang from the head, wrists and
side, and one trails behind on the ground.

Bones: root (body, seat on top behind the head), neck (head), ArmL/R, LegFL/FR, Tail (the
trailing bandage). Animations: the Living Mushrooms' fat waddle (tools/living_mushroom_rig.py) with the zombie arms bobbing
up and down, and the trailing bandage swishing behind.

    python3 tools/bloated_mummy.py

writes designs/tomb/BloatedMummy.bbmodel and /mnt/project-files/world2/tomb/renders/BloatedMummy.png.
"""

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal  # noqa: E402
from partlib import T, Rx, Ry, Rz, render  # noqa: E402
from horse_rig import pose  # noqa: E402

WRAP = (242, 232, 200)  # fresh bandage
SAND = (220, 201, 152)  # #DCC998
SAND2 = (208, 184, 134)  # #D0B886
GRIME = (176, 150, 104)  # dirty edges and seams
GAP = (62, 46, 36)  # the dark inside showing through
GLOW = (120, 255, 110)
WHITE, PUPIL = (255, 255, 255), GLOW
GOLD = (240, 190, 24)
GOLD_DARK = (196, 140, 16)
LAPIS = (40, 92, 206)
CARNELIAN = (226, 72, 40)
TEAL = (36, 196, 186)
BEETLE = (24, 30, 36)

P = 0.08  # how far a wrap sits proud of what it wraps

# the body: a stepped ball, (y0, y1, half width, half depth), bottom to top
LAYERS = [(1.0, 1.6, 2.2, 1.9, SAND2), (1.6, 2.4, 2.9, 2.5, SAND), (2.4, 5.4, 3.3, 2.9, WRAP),
          (5.4, 6.2, 2.9, 2.5, SAND), (6.2, 6.8, 2.2, 1.9, SAND2)]
HX, HZ = 3.3, 2.9  # the fat middle
CHAMFER = 0.5  # corners cut off each layer
# wraps round the middle: (y, height, tilt about x, colour)
BANDS = [(2.75, 0.45, 5, SAND), (3.45, 0.4, -4, SAND2), (4.2, 0.45, 3, SAND), (4.95, 0.4, -5, SAND2)]
# head (hunched on the front of the ball)
HD = dict(x=1.7, y0=6.3, y1=9.1, z0=-3.0, z1=0.0)


def build():
    a = Animal("BloatedMummy", "Uncommon")
    a.bone_order = [("root", None), ("neck", "root"), ("ArmL", "root"), ("ArmR", "root"),
                    ("LegFL", "root"), ("LegFR", "root"), ("Tail", "root")]
    a.animations = animations

    def rbox(name, c, size, color, bone, R=None):
        p = a.box(name, np.array(c) - np.array(size) / 2, np.array(c) + np.array(size) / 2, color, bone)
        if R is not None:
            p.cf = T(*c) @ R
        return p

    def strip(name, start, angles, seg, w, t, color, bone, along="x"):
        """A loose bandage end: a chain of thin blocks, each hanging from the end of the last.
        angles = [(tilt about x, tilt about z)] per block; 0, 0 hangs straight down.
        along: the strip's flat face points along x (sideways) or z (front/back)."""
        p = np.array(start, float)
        for i, (ax, az) in enumerate(angles):
            R = Ry(0) @ Rx(ax) @ Rz(az)
            d = R[:3, :3] @ np.array([0, -1.0, 0])
            size = (t, seg, w) if along == "x" else (w, seg, t)
            rbox(f"{name}{i + 1}", p + d * seg / 2, size, color, bone, R)
            p = p + d * (seg - 0.06)
        return p

    def ring(name, y, h, hx, hz, color, R=None, ch=None):
        """A layer or wrap with its corners cut off (two crossed blocks), so the ball reads round."""
        ch = CHAMFER if ch is None else ch
        rbox(name + "W", (0, y, 0), (2 * hx, h, 2 * (hz - ch)), color, "root", R)
        rbox(name + "D", (0, y, 0), (2 * (hx - ch), h, 2 * hz), color, "root", R)

    # ---------------------------------------------------------------- body
    for i, (y0, y1, hx, hz, c) in enumerate(LAYERS):
        ring(f"Body{i + 1}", (y0 + y1) / 2, y1 - y0, hx, hz, c, ch=0.4 if i in (0, 4) else CHAMFER)
    a.pivots["root"] = (0, 3.9, 0)
    a.dims = dict(x=HX, y0=1.0, y1=6.8, z0=-HZ, z1=HZ)
    # hand-wound wraps round the middle, each a little tilted, and thin grime seams
    for i, (y, h, tilt, c) in enumerate(BANDS):
        ring(f"Wrap{i + 1}", y, h, HX + P, HZ + P, c, Rx(tilt))
    for i, (y, hx, hz) in enumerate([(1.6, 2.9, 2.5), (5.4, 2.9, 2.5)]):
        ring(f"Seam{i + 1}", y, 0.12, hx + 0.04, hz + 0.04, GRIME)
    # a wrap round each of the upper and lower steps
    ring("WrapLow", 2.0, 0.35, 2.9 + P, 2.5 + P, SAND2, Rz(4))
    ring("WrapHigh", 5.8, 0.35, 2.9 + P, 2.5 + P, WRAP, Rz(-4))
    # diagonal strips: one down each front hip, an X across the back
    for s, sx in (("L", -1), ("R", 1)):
        rbox("HipStrip" + s, (sx * 1.9, 3.1, -HZ - 0.12), (0.55, 2.2, 0.1), SAND2, "root", Rz(sx * 38))
    rbox("BackStrip1", (0, 3.9, HZ + 0.12), (0.6, 4.6, 0.1), SAND, "root", Rz(40))
    rbox("BackStrip2", (0, 3.9, HZ + 0.2), (0.6, 4.6, 0.1), SAND2, "root", Rz(-40))
    # a patch on the left flank with two cross stitches
    a.box("Patch", (-HX - 0.12, 3.0, 0.6), (-HX - 0.04, 4.0, 1.8), SAND2, "root")
    for i, z in enumerate((0.9, 1.5)):
        rbox(f"Stitch{i + 1}A", (-HX - 0.15, 3.5, z), (0.05, 0.5, 0.1), GAP, "root", Rx(45))
        rbox(f"Stitch{i + 1}B", (-HX - 0.15, 3.5, z), (0.05, 0.5, 0.1), GAP, "root", Rx(-45))

    # torn holes: dark inside, glowing green deeper in, wisps drifting out
    holes = [("HoleL", (-HX - 0.06, 2.9, -1.3), "x", (1.0, 0.8)),
             ("HoleF", (-1.3, 1.95, -2.5 - 0.06), "z", (0.9, 0.6)),
             ("HoleB", (1.2, 4.6, HZ + 0.06), "z", (0.8, 0.7))]
    for name, c, ax, (w, h) in holes:
        c = np.array(c)
        out = np.sign(c[0]) if ax == "x" else np.sign(c[2])
        k = 0 if ax == "x" else 2
        size = np.array([w, h, w]); size[k] = 0.06
        a.box("Plain" + name, c - size / 2, c + size / 2, GAP, "root").plain = True
        c2 = c.copy(); c2[k] += out * 0.04
        s2 = size * np.array([0.55, 0.5, 0.55]); s2[k] = 0.06
        g = a.box("Glow" + name, c2 - s2 / 2, c2 + s2 / 2, GLOW, "root")
        g.neon = True
        for j, (dy, d, sz) in enumerate([(0.7, 0.35, 0.28), (1.35, 0.6, 0.2), (1.9, 0.5, 0.14)]):
            wc = c.copy(); wc[1] += dy; wc[k] += out * d
            wc[2 if k == 0 else 0] += (-0.2, 0.15, -0.05)[j]
            a.box(f"GlowWisp{name[4:]}{j + 1}", wc - sz / 2, wc + sz / 2, GLOW, "root").neon = True
    # a little teal scarab crawling out of the left hole, heading forward
    sx0, sy0, sz0 = -HX - 0.06, 2.9, -1.3
    a.box("ScarabShell", (sx0 - 0.4, sy0 - 0.35, sz0 - 0.2), (sx0, sy0 + 0.35, sz0 + 0.6), TEAL, "root")
    a.box("PlainScarabSeam", (sx0 - 0.43, sy0 - 0.03, sz0 - 0.2), (sx0 - 0.4, sy0 + 0.03, sz0 + 0.6), BEETLE, "root").plain = True
    a.box("ScarabBand", (sx0 - 0.42, sy0 - 0.37, sz0 + 0.0), (sx0 - 0.02, sy0 + 0.37, sz0 + 0.12), GOLD, "root")
    a.box("ScarabHead", (sx0 - 0.32, sy0 - 0.2, sz0 - 0.5), (sx0 - 0.05, sy0 + 0.2, sz0 - 0.2), BEETLE, "root")
    for i, dy in enumerate((-0.12, 0.12)):
        a.box(f"ScarabHorn{i + 1}", (sx0 - 0.24, sy0 + dy - 0.04, sz0 - 0.7), (sx0 - 0.12, sy0 + dy + 0.04, sz0 - 0.5), BEETLE, "root")
    for i, (dz, s) in enumerate([(-0.1, -1), (-0.1, 1), (0.2, -1), (0.2, 1), (0.5, -1), (0.5, 1)]):
        a.box(f"ScarabLeg{i + 1}", (sx0 - 0.15, sy0 + s * 0.35, sz0 + dz - 0.04),
              (sx0 - 0.05, sy0 + s * 0.55, sz0 + dz + 0.04), BEETLE, "root")

    # ---------------------------------------------------------------- collar and amulet
    # broad collar: stepped rings round the base of the head, gold / lapis / gold / carnelian
    hz0, hz1 = HD["z0"], HD["z1"]
    for i, (y0, y1, grow, c) in enumerate([(5.8, 6.05, 0.95, GOLD), (6.05, 6.25, 0.7, LAPIS),
                                           (6.25, 6.4, 0.5, GOLD), (6.4, 6.55, 0.3, CARNELIAN)]):
        a.box(f"Collar{i + 1}", (-HD["x"] - grow, y0, hz0 - grow * 0.5), (HD["x"] + grow, y1, hz1 + grow), c, "root")
    # bead fringe down the front of the upper step, under the collar
    fz = -2.5 - 0.06
    for i, x in enumerate(np.linspace(-2.2, 2.2, 7)):
        c = GOLD if i % 2 == 0 else LAPIS
        drop = 0.75 if i in (2, 3, 4) else 0.55
        a.box(f"Bead{i + 1}", (x - 0.2, 5.85 - drop, fz - 0.18), (x + 0.2, 5.85, fz), c, "root")
        a.box(f"BeadTip{i + 1}", (x - 0.1, 5.85 - drop - 0.18, fz - 0.16), (x + 0.1, 5.85 - drop, fz - 0.02), GOLD_DARK, "root")
    # gold chain from the fringe down to the scarab amulet on the belly
    az = -HZ - 0.1
    for s, sx in (("L", -1), ("R", 1)):
        for j, t in enumerate((0.2, 0.5, 0.8)):
            x = sx * (0.9 - 0.55 * t)
            y = 5.15 - 0.6 * t
            a.box(f"Chain{s}{j + 1}", (x - 0.11, y - 0.11, az - 0.12 - P), (x + 0.11, y + 0.11, az + 0.02), GOLD, "root")
    am = -HZ - P - 0.1
    a.box("AmuletBody", (-0.55, 3.55, am - 0.25), (0.55, 4.55, am), GOLD, "root")
    a.box("AmuletHead", (-0.35, 4.55, am - 0.2), (0.35, 4.85, am), GOLD_DARK, "root")
    a.box("PlainAmuletSplit", (-0.04, 3.6, am - 0.28), (0.04, 4.5, am - 0.24), GOLD_DARK, "root").plain = True
    a.box("AmuletSun", (-0.3, 4.85, am - 0.18), (0.3, 5.3, am - 0.02), CARNELIAN, "root")
    a.box("AmuletGem", (-0.22, 3.85, am - 0.34), (0.22, 4.25, am - 0.24), TEAL, "root")
    for s, sx in (("L", -1), ("R", 1)):
        rbox("AmuletWing" + s, (sx * 1.15, 4.25, am - 0.1), (1.2, 0.5, 0.14), LAPIS, "root", Rz(sx * 18))
        rbox("AmuletWingTip" + s, (sx * 1.25, 3.85, am - 0.08), (1.0, 0.32, 0.12), GOLD, "root", Rz(sx * 26))
        a.box("AmuletLeg" + s, (sx * 0.55 - 0.08, 3.3, am - 0.15), (sx * 0.55 + 0.08, 3.6, am - 0.05), GOLD_DARK, "root")

    # ---------------------------------------------------------------- head
    x, y0, y1, z0, z1 = HD["x"], HD["y0"], HD["y1"], HD["z0"], HD["z1"]
    a.box("Head", (-x, y0, z0), (x, y1, z1), WRAP, "neck")
    a.box("HeadTop", (-x + 0.35, y1, z0 + 0.35), (x - 0.35, y1 + 0.45, z1 - 0.35), SAND, "neck")
    a.box("HeadKnot", (-0.35, y1 + 0.45, z0 + 1.0), (0.35, y1 + 0.75, z1 - 1.2), SAND2, "neck")
    a.pivots["neck"] = (0, y0 + 0.3, (z0 + z1) / 2)
    for i, (y, h, tilt, c) in enumerate([(6.75, 0.35, 6, SAND), (7.25, 0.3, -5, SAND2), (8.85, 0.3, -4, SAND2)]):
        rbox(f"HeadWrap{i + 1}", (0, y, (z0 + z1) / 2), (2 * (x + P), h, z1 - z0 + 2 * P), c, "neck", Rx(tilt))
    # dark eye slit with mismatched googly plate eyes, glowing green pupils (set back from the edges)
    fz = z0 - 0.04
    a.box("EyeSlit", (-x + 0.15, 7.5, fz - 0.03), (x - 0.15, 8.6, fz + 0.04), GAP, "neck").plain = True
    a.box("EyeL", (-1.35, 7.35, fz - 0.1), (-0.15, 8.55, fz - 0.03), WHITE, "neck")
    a.box("GlowPupilL", (-0.95, 7.65, fz - 0.14), (-0.45, 8.15, fz - 0.1), PUPIL, "neck").neon = True
    a.box("EyeR", (0.35, 7.6, fz - 0.1), (1.2, 8.45, fz - 0.03), WHITE, "neck")
    a.box("GlowPupilR", (0.55, 7.75, fz - 0.14), (0.95, 8.15, fz - 0.1), PUPIL, "neck").neon = True
    # brow wrap over the slit, and a bandage slipped down across the right eye
    rbox("BrowWrap", (0, 8.75, fz - 0.06), (2 * x + 0.1, 0.3, 0.12), SAND, "neck", Rz(-3))
    rbox("Slipped", (0.75, 8.2, fz - 0.2), (1.4, 0.38, 0.1), SAND2, "neck", Rz(-28))
    rbox("SlippedEnd", (1.55, 7.55, fz - 0.2), (0.38, 0.8, 0.1), SAND2, "neck", Rz(-12))
    # crooked little "o" mouth
    a.box("Mouth", (-0.75, 6.75, fz - 0.06), (-0.25, 7.15, fz + 0.02), GAP, "neck")
    a.box("MouthLip", (-0.85, 6.65, fz - 0.03), (-0.15, 6.75, fz + 0.02), GRIME, "neck")
    # gold headband with a lapis gem and turquoise studs
    a.box("Headband", (-x - P - 0.02, 9.1 - 0.02, z0 - P - 0.02), (x + P + 0.02, 9.1 + 0.25, z1 + P + 0.02), GOLD, "neck")
    a.box("HeadGem", (-0.3, 9.0, z0 - P - 0.16), (0.3, 9.5, z0 - P - 0.02), LAPIS, "neck")
    a.box("HeadGemRim", (-0.4, 8.95, z0 - P - 0.1), (0.4, 9.55, z0 - P - 0.04), GOLD_DARK, "neck")
    for s, sx in (("L", -1), ("R", 1)):
        a.box("HeadStud" + s, (sx * 1.1 - 0.13, 9.06, z0 - P - 0.12), (sx * 1.1 + 0.13, 9.29, z0 - P - 0.02), TEAL, "neck")
    # two long bandage ends hanging off the back of the head, flaring out
    for s, sx in (("L", -1), ("R", 1)):
        strip("HeadTail" + s, (sx * 0.6, 9.0, z1 + P + 0.05), [(-35, sx * 10), (-18, sx * 16), (-6, sx * 22)],
              0.9, 0.5, 0.1, SAND if s == "L" else SAND2, "neck", along="z")

    # ---------------------------------------------------------------- arms (reaching forward)
    for s, sx in (("L", -1), ("R", 1)):
        bone = "Arm" + s
        xa, xb = sorted((sx * 3.05, sx * 4.15))
        xm = (xa + xb) / 2
        a.box("Arm" + s, (xa, 4.1, -4.7), (xb, 5.1, -0.4), WRAP, bone)
        a.pivots[bone] = (xm, 4.6, -0.8)
        for j, (zc, tilt, c) in enumerate([(-1.3, 8, SAND), (-2.3, -7, SAND2), (-3.1, 6, SAND)]):
            rbox(f"ArmWrap{s}{j + 1}", (xm, 4.6, zc), (xb - xa + 2 * P, 1.0 + 2 * P, 0.35), c, bone, Rx(tilt))
        a.box("Cuff" + s, (xa - 0.1, 4.0, -4.25), (xb + 0.1, 5.2, -3.7), GOLD, bone)
        a.box("CuffGem" + s, (xm - 0.18, 4.42, -4.18), (xm + 0.18, 4.78, -3.77), LAPIS, bone)
        rbox("CuffGemSide" + s, (xb + 0.13 if sx > 0 else xa - 0.13, 4.6, -3.98), (0.06, 0.4, 0.3), CARNELIAN, bone)
        # wrapped mitt: palm, three stubby fingers, a thumb on top
        a.box("Hand" + s, (xa + 0.05, 4.15, -5.4), (xb - 0.05, 5.05, -4.7), SAND, bone)
        for f, xf in enumerate(np.linspace(xa + 0.25, xb - 0.25, 3)):
            a.box(f"Finger{s}{f + 1}", (xf - 0.15, 4.2 + 0.05 * f, -5.95 + 0.08 * abs(f - 1)), (xf + 0.15, 4.6 + 0.05 * f, -5.4), WRAP, bone)
        a.box("Thumb" + s, (xm - 0.18, 5.05, -5.3), (xm + 0.18, 5.4, -4.8), WRAP, bone)
        # a loose end dangling from the wrist
        strip("ArmTail" + s, (xm + sx * 0.15, 4.05, -3.2), [(10, -sx * 6), (22, -sx * 10), (34, -sx * 14)],
              0.55, 0.32, 0.08, SAND2, bone)

    # ---------------------------------------------------------------- legs (stubby)
    for s, sx in (("L", -1), ("R", 1)):
        bone = "LegF" + s
        xa, xb = sorted((sx * 0.7, sx * 2.1))
        xm = (xa + xb) / 2
        a.box("Leg" + s, (xa, 0.35, -0.8), (xb, 1.4, 0.7), WRAP, bone)
        a.pivots[bone] = (xm, 1.35, 0)
        rbox("LegWrap" + s, (xm, 1.05, -0.05), (xb - xa + 2 * P, 0.3, 1.5 + 2 * P), SAND2, bone, Rx(-6))
        a.box("Anklet" + s, (xa - 0.08, 0.35, -0.88), (xb + 0.08, 0.6, 0.78), GOLD, bone)
        a.box("Foot" + s, (xa - 0.05, 0.0, -1.5), (xb + 0.05, 0.35, 0.8), SAND, bone)
        for t, xt in enumerate(np.linspace(xa + 0.3, xb - 0.3, 3)):
            a.box(f"Toe{s}{t + 1}", (xt - 0.17, 0.0, -1.85), (xt + 0.17, 0.3, -1.5), WRAP, bone)

    # ---------------------------------------------------------------- loose ends on the body
    strip("SideTail", (HX + P + 0.05, 3.55, -1.2), [(4, 14), (8, 4), (14, -8)], 0.8, 0.45, 0.08, SAND, "root")
    # the long one trailing behind along the ground (its own bone so it can drag and flap)
    tz = 2.5 + 0.06
    a.pivots["Tail"] = (0.6, 1.9, tz)
    p = strip("Trail", (0.6, 1.9, tz), [(-15, 0), (-40, 0), (-75, 0)], 0.9, 0.55, 0.1, SAND2, "Tail", along="z")
    rbox("TrailEnd1", (0.6, 0.06, p[2] + 0.5), (0.55, 0.1, 1.2), SAND2, "Tail")
    rbox("TrailEnd2", (0.75, 0.08, p[2] + 1.55), (0.55, 0.1, 1.0), SAND2, "Tail", Ry(-14))
    rbox("TrailEnd3", (1.15, 0.2, p[2] + 2.2), (0.55, 0.1, 0.6), SAND2, "Tail", Ry(-30) @ Rx(-22))

    a.meta = {"seat": (0, 6.85, 1.15), "neck_loop": {"center": (0, 7.6, -1.5), "radius": 2.3}}
    return a


def animations():
    """idle / walk / gallop from the Living Mushrooms (same bone names, 10 Blockbench units per
    stud), and the trailing bandage (Tail) swishing side to side and lifting at speed."""
    from living_mushroom_rig import animations as waddle
    import math
    out = {}
    for name, (L, tracks) in waddle(1.0).items():
        tracks = dict(tracks)
        swish, lift, n = {"idle": (6, 0, 1), "walk": (14, 6, 1), "gallop": (20, 14, 2)}[name]
        tracks["Tail"] = [{"channel": "rotation", "interp": "catmullrom", "keys": [
            (round(L * k / 16, 4), (lift * (0.5 + 0.5 * math.sin(2 * math.pi * n * k / 16)),
                                    swish * math.sin(2 * math.pi * k / 16), 0)) for k in range(17)]}]
        # the zombie arms reach forward, so they bob up and down (X) instead of swinging
        bob, sway, ph = {"idle": (4, 3, 0.5), "walk": (10, 6, 0.5), "gallop": (18, 4, 0.25)}[name]
        for arm, sx, off in (("ArmL", -1, 0.0), ("ArmR", 1, ph)):
            tracks[arm] = [{"channel": "rotation", "interp": "catmullrom", "keys": [
                (round(L * k / 16, 4), (bob * math.sin(2 * math.pi * (k / 16 + off)),
                                        sx * sway * math.sin(2 * math.pi * (k / 16 + off + 0.25)), 0)) for k in range(17)]}]
        out[name] = (L, tracks)
    return out


CAM = dict(eye=(-15, 11, -22), target=(0, 4.4, -0.6), W=640, H=640, fov=32)
BG = (238, 238, 232)


def shot(m, cam=CAM):
    im = render(pose(m, None, 0), transparent=True, **cam)
    bg = Image.new("RGBA", im.size, BG + (255,))
    bg.alpha_composite(im)
    return bg.convert("RGB")


def main(out=os.path.join(A.ROOT, "designs", "tomb"), renders="/mnt/project-files/world2/tomb/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(renders, exist_ok=True)
    a = build()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    shot(m).save(os.path.join(renders, a.name + ".png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
