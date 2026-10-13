"""Lion Archer: World 2 Ancient Tomb's Rare (QM, Oct 13: the Tomb of the Ancients' "Tomb
Gang" lion-headed archer, as a rideable animal; the final biome, so very detailed).

A sphinx-like lion, told apart from the Meadow Lion (orange mane ring), the Tiger and the
Temple guardian statues by its pharaoh headdress: a lapis-and-gold striped nemes over the
head with lappets hanging down onto the chest, a gold headband with a cobra (uraeus) and
a glowing red gem on the brow, a braided false beard, kohl-lined googly eyes, and only a
dark brown fringe of mane peeking out under it. A broad usekh collar of gold, turquoise,
lapis and carnelian bead rows on the chest; a lapis saddle cloth with gold borders and an
Eye of Horus on each flank; a red leather saddle; a quiver of red and white fletched
arrows leaning back on the right flank; a big red recurve bow with gold tips strapped
along the left flank; gold cuffs, armbands and claws; a long tail ringed in gold.

Same bones as every quadruped (root, neck, EarL, EarR, Tail, Leg*), quad animations.
The quiver and the bow are built already turned (single-axis rests baked into the
parts, every bone at 0).

    python3 tools/lion_archer.py [out_dir] [renders_dir]

writes designs/tomb/LionArcher.bbmodel and the 3/4 render LionArcher.png.
"""

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402
from partlib import Part, T, Rx, render  # noqa: E402
from horse_rig import pose  # noqa: E402
from snow_designs import pyramid, front_eye  # noqa: E402

COAT = (238, 192, 112)
COAT_DARK = (214, 160, 84)
CREAM = (255, 238, 204)
MANE = (122, 66, 36)
NOSE = (92, 48, 40)
KOHL = (28, 26, 40)
GOLD = (252, 200, 40)
GOLD_DARK = (206, 150, 22)
LAPIS = (34, 86, 210)
LAPIS_DARK = (24, 56, 150)
TURQ = (40, 200, 190)
CARNELIAN = (220, 60, 40)
LEATHER = (176, 74, 40)
LEATHER_DARK = (116, 48, 28)
BOW = (196, 46, 40)
STRING = (250, 246, 232)
WHITE = (255, 255, 255)
RUBY = (255, 70, 60)


def lion_archer():
    a = Animal("LionArcher", "Rare")

    def rbox(name, size, M, color, bone):
        p = Part(name, size, M, color)
        p.bone = bone
        a.parts.append(p)
        return p

    def seg(name, p0, p1, w, t, color, bone, x):
        """A box from (z, y) p0 to p1 in the plane at x: w wide (x), t thick, turned about X only."""
        (z0, y0), (z1, y1) = p0, p1
        dz, dy = z1 - z0, y1 - y0
        L = math.hypot(dz, dy)
        th = math.degrees(math.atan2(-dy, dz))
        return rbox(name, (w, t, L), T(x, (y0 + y1) / 2, (z0 + z1) / 2) @ Rx(th), color, bone)

    # ---- body
    x, y0, y1, z0, z1 = 1.8, 3.0, 6.2, -3.0, 3.6
    a.body(x, y0, y1, z0, z1, COAT)
    a.box("Belly", (-1.5, y0 - 0.12, -2.2), (1.5, y0, 2.8), CREAM, "root")
    # muscle on the haunches
    for side, sx in (("L", -1), ("R", 1)):
        ha, hb = sorted((sx * x, sx * (x + 0.25)))
        a.box("Haunch" + side, (ha, 3.6, 2.4), (hb, 5.7, 3.5), COAT_DARK, "root")

    # ---- legs: big paws, gold cuffs, armbands with a lapis gem on the front legs
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.5, sx * 1.75))
        za = z0 + 0.001 if front else z1 - 0.001 - 1.3
        zb = za + 1.3
        name = "Leg" + leg
        a.box(name, (xa, 0.8, za), (xb, y0, zb), COAT, name)
        a.box("Cuff" + leg, (xa - 0.08 * (sx < 0), 0.75, za - 0.08), (xb + 0.08 * (sx > 0), 1.15, zb + 0.08), GOLD, name)
        a.box("Paw" + leg, (xa - 0.1 * (sx < 0), 0, za - 0.45), (xb + 0.1 * (sx > 0), 0.75, zb), CREAM, name)
        cw = (xb - xa) / 3
        for k in range(3):
            cx = xa + cw * (k + 0.5)
            pyramid(a, f"Claw{leg}{k + 1}", (cx - 0.15, 0.05, za - 0.45), (cx + 0.15, 0.35, za - 0.45), "-z", 0.35, WHITE, name)
        if front:
            a.box("Armband" + leg, (xa - 0.08 * (sx < 0), 2.1, za - 0.08), (xb + 0.08 * (sx > 0), 2.45, zb + 0.08), GOLD, name)
            ca, cb = (xa + xb) / 2 - 0.2, (xa + xb) / 2 + 0.2
            a.box("ArmGem" + leg, (ca, 2.12, za - 0.14), (cb, 2.43, za - 0.08), LAPIS, name)
        a.pivots[name] = ((xa + xb) / 2, y0 - 0.025, zb - 0.05 if front else za + 0.05)

    # the collar's top over the shoulders
    a.box("CollarTop", (-1.85, y1, z0), (1.85, y1 + 0.1, -2.2), GOLD, "root")
    a.box("CollarTopTurq", (-1.85, y1, -2.2), (1.85, y1 + 0.08, -1.8), TURQ, "root")

    # ---- saddle cloth: lapis with gold borders, an Eye of Horus on each flank
    a.box("Cloth", (-1.95, y1, -1.5), (1.95, y1 + 0.12, 2.4), LAPIS, "root")
    a.box("ClothTrimF", (-1.97, y1, -1.7), (1.97, y1 + 0.14, -1.5), GOLD, "root")
    a.box("ClothTrimB", (-1.97, y1, 2.4), (1.97, y1 + 0.14, 2.6), GOLD, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * x, sx * 1.95))
        a.box("Drape" + side, (xa, 4.3, -1.5), (xb, y1, 2.4), LAPIS, "root")
        ta, tb = sorted((sx * x, sx * 1.98))
        a.box("DrapeHem" + side, (ta, 4.05, -1.7), (tb, 4.3, 2.6), GOLD, "root")
        a.box("DrapeTrimF" + side, (ta, 4.3, -1.7), (tb, y1, -1.5), GOLD, "root")
        a.box("DrapeTrimB" + side, (ta, 4.3, 2.4), (tb, y1, 2.6), GOLD, "root")
        # Eye of Horus: white eye, black pupil, kohl brow, tail and teardrop
        ea, eb = sorted((sx * 1.95, sx * 2.0))
        pa, pb = sorted((sx * 2.0, sx * 2.04))
        a.box("HorusEye" + side, (ea, 5.25, -0.1), (eb, 5.65, 1.1), WHITE, "root")
        a.box("HorusPupil" + side, (pa, 5.25, 0.3), (pb, 5.65, 0.7), KOHL, "root")
        a.box("HorusBrow" + side, (ea, 5.8, -0.2), (eb, 5.95, 1.2), KOHL, "root")
        a.box("HorusLid" + side, (ea, 5.65, -0.2), (eb, 5.75, 1.4), KOHL, "root")
        a.box("HorusTail" + side, (ea, 5.65, 1.3), (eb, 5.75, 1.75), KOHL, "root")
        a.box("HorusDrop" + side, (ea, 4.75, 0.45), (eb, 5.25, 0.6), KOHL, "root")
        a.box("HorusCurl" + side, (ea, 4.75, 0.6), (eb, 4.9, 1.0), KOHL, "root")

    # ---- saddle: red leather seat, gold pommel, high cantle
    a.box("Saddle", (-1.1, y1 + 0.12, -0.7), (1.1, y1 + 0.42, 1.7), LEATHER, "root")
    a.box("SaddleRim", (-1.15, y1 + 0.12, -0.75), (1.15, y1 + 0.22, 1.75), GOLD, "root")
    a.box("Pommel", (-0.45, y1 + 0.42, -0.75), (0.45, y1 + 0.9, -0.35), GOLD, "root")
    a.box("Cantle", (-1.1, y1 + 0.42, 1.35), (1.1, y1 + 1.0, 1.75), LEATHER_DARK, "root")
    a.box("CantleGold", (-1.12, y1 + 0.9, 1.33), (1.12, y1 + 1.06, 1.77), GOLD, "root")

    # ---- quiver on the right flank, leaning back, full of fletched arrows
    qx, qc, qang, qlen = 2.42, (5.8, 2.0), 25, 3.2
    up = np.array([math.cos(math.radians(qang)), math.sin(math.radians(qang))])  # (y, z)
    def qpt(t, d=0.0):
        """point t studs up the quiver's axis (y, z) from its centre."""
        return (qc[0] + up[0] * t, qc[1] + up[1] * t + d)
    Q = Rx(qang)
    yy, zz = qpt(0)
    rbox("Quiver", (0.85, qlen, 0.85), T(qx, yy, zz) @ Q, LEATHER, "root")
    for i, t in enumerate((-1.45, 0.0, 1.4)):
        yy, zz = qpt(t)
        rbox(f"QuiverBand{i + 1}", (0.95, 0.22, 0.95), T(qx, yy, zz) @ Q, GOLD, "root")
    yy, zz = qpt(-1.75)
    rbox("QuiverCap", (0.7, 0.3, 0.7), T(qx, yy, zz) @ Q, GOLD_DARK, "root")
    # an ankh on the quiver's outside face
    yy, zz = qpt(0.65)
    rbox("QuiverAnkhLoop", (0.06, 0.45, 0.4), T(qx + 0.45, yy, zz) @ Q, GOLD, "root")
    yy, zz = qpt(-0.55)
    rbox("QuiverAnkhStem", (0.06, 0.95, 0.14), T(qx + 0.45, yy, zz) @ Q, GOLD, "root")
    yy, zz = qpt(0.15)
    rbox("QuiverAnkhBar", (0.06, 0.14, 0.6), T(qx + 0.45, yy, zz) @ Q, GOLD, "root")
    yy, zz = qpt(0.65)
    rbox("QuiverAnkhHole", (0.07, 0.2, 0.16), T(qx + 0.46, yy, zz) @ Q, LEATHER, "root")
    # strap from the quiver over the cloth
    a.box("QuiverStrap", (1.95, 4.9, 1.45), (1.98, y1, 1.75), LEATHER_DARK, "root")
    # arrows: shafts out of the top, red and white fletching in a cross
    arrows = [(-0.2, -0.18, 0.0, (220, 50, 46)), (0.2, -0.15, 0.3, WHITE), (-0.18, 0.2, 0.15, WHITE), (0.18, 0.18, 0.45, (220, 50, 46))]
    for i, (dx, dz, extra, fc) in enumerate(arrows):
        t0 = qlen / 2
        yy, zz = qpt(t0 + 0.55 + extra / 2, dz)
        rbox(f"ArrowShaft{i + 1}", (0.12, 1.1 + extra, 0.12), T(qx + dx, yy, zz) @ Q, (232, 210, 160), "root")
        yy, zz = qpt(t0 + 0.75 + extra, dz)
        rbox(f"ArrowFletchA{i + 1}", (0.05, 0.6, 0.36), T(qx + dx, yy, zz) @ Q, fc, "root")
        rbox(f"ArrowFletchB{i + 1}", (0.36, 0.6, 0.05), T(qx + dx, yy, zz) @ Q, fc, "root")
        yy, zz = qpt(t0 + 1.12 + extra, dz)
        rbox(f"ArrowNock{i + 1}", (0.16, 0.12, 0.16), T(qx + dx, yy, zz) @ Q, GOLD, "root")

    # ---- recurve bow strapped along the left flank (in the plane x = bx), string out
    bx = -2.18
    # (z, y) points from the lower tip to the upper tip: recurve, limb, grip, limb, recurve
    pts = [(-2.25, 3.15), (-2.15, 3.6), (-1.55, 4.15), (-0.8, 4.45), (0.0, 4.5),
           (0.8, 4.45), (1.55, 4.15), (2.15, 3.6), (2.25, 3.15)]
    # tilt the whole bow so it runs diagonally (lower at the front, rising to the back)
    tilt = math.radians(-14)
    cz, cy = 0.5, 4.9
    def place(p):
        z, y = p[0] * 1.35, 4.0 + (p[1] - 4.0) * 1.2
        return (cz + z * math.cos(tilt) - (y - 4.0) * math.sin(tilt), cy + z * math.sin(tilt) + (y - 4.0) * math.cos(tilt) - 0.5)
    P = [place(p) for p in pts]
    for i in range(len(P) - 1):
        tip = i in (0, len(P) - 2)
        seg(f"Bow{i + 1}", P[i], P[i + 1], 0.24, 0.26, GOLD if tip else BOW, "root", bx)
    # grip wrap round the middle, gold rings either side
    g0, g1 = place((-0.45, 4.48)), place((0.45, 4.48))
    seg("BowGrip", g0, g1, 0.32, 0.36, LEATHER_DARK, "root", bx)
    for i, zc in enumerate((-0.55, 0.55)):
        seg(f"BowRing{i + 1}", place((zc - 0.08, 4.48)), place((zc + 0.08, 4.48)), 0.36, 0.4, GOLD, "root", bx)
    # tips: little gold knobs; the string straight between them
    seg("BowString", place((-2.15, 3.45)), place((2.15, 3.45)), 0.06, 0.06, STRING, "root", bx + 0.02)
    # straps tying the bow to the drape
    for i, zc in enumerate((-0.9, 1.3)):
        yy = place((zc, 4.3))[1]
        a.box(f"BowStrap{i + 1}", (-2.38, yy - 0.5, zc + 0.4), (-1.98, yy + 0.4, zc + 0.62), LEATHER_DARK, "root")

    # ---- neck under the head
    a.box("Neck", (-1.2, 3.9, -4.2), (1.2, 7.0, -2.6), COAT, "neck")

    # ---- head: lion face, cream muzzle, kohl-lined googly eyes on the front
    hx, hy0, hy1, hz0, hz1 = 1.35, 6.0, 8.6, -6.0, -3.4
    a.box("Head", (-hx, hy0, hz0), (hx, hy1, hz1), COAT, "neck")
    a.box("Muzzle", (-0.95, hy0, -6.7), (0.95, 7.1, hz0), CREAM, "neck")
    a.box("MuzzleTop", (-0.6, 7.1, -6.5), (0.6, 7.4, hz0), COAT, "neck")
    a.box("Nose", (-0.42, 6.85, -6.78), (0.42, 7.25, -6.5), NOSE, "neck")
    a.box("MouthLine", (-0.06, 6.4, -6.75), (0.06, 6.85, -6.7), NOSE, "neck")
    a.box("Mouth", (-0.55, 6.32, -6.75), (0.55, 6.44, -6.7), NOSE, "neck")
    a.box("Chin", (-0.7, 5.75, -6.5), (0.7, hy0, -5.4), CREAM, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        # whisker dots
        for k, (wy, wz) in enumerate(((6.85, -6.45), (6.6, -6.25))):
            wa, wb = sorted((sx * 0.95, sx * 1.0))
            a.box(f"Whisker{side}{k + 1}", (wa, wy - 0.06, wz - 0.06), (wb, wy + 0.06, wz + 0.06), NOSE, "neck")
        ea, eb = sorted((sx * 0.2, sx * 1.2))
        front_eye(a, side, ea, eb, 7.3, 8.15, hz0, "neck")
        # kohl: a line under the eye running out past it, and a wing at the outer corner
        ka, kb = sorted((sx * 0.15, sx * 1.4))
        a.box("Kohl" + side, (ka, 7.18, hz0 - 0.06), (kb, 7.3, hz0 - 0.01), KOHL, "neck")
        wa, wb = sorted((sx * 1.2, sx * 1.4))
        a.box("KohlWing" + side, (wa, 7.3, hz0 - 0.06), (wb, 7.55, hz0 - 0.01), KOHL, "neck")
        ba, bb = sorted((sx * 0.15, sx * 1.25))
        a.box("Brow" + side, (ba, 8.25, hz0 - 0.1), (bb, 8.4, hz0), MANE, "neck")

    # ---- mane: only a dark fringe peeks out under the headdress, round the face and chest
    a.box("ManeChin", (-1.45, 5.45, -5.4), (1.45, hy0, -4.1), MANE, "neck")
    # ---- usekh collar: a bib of bead rows on the neck's front, widening down, gold drops
    rows = [(5.15, 5.45, GOLD), (4.8, 5.15, TURQ), (4.5, 4.8, GOLD), (4.2, 4.5, LAPIS), (3.9, 4.2, CARNELIAN)]
    for i, (ra, rb, c) in enumerate(rows):
        w = 0.85 + 0.05 * i
        a.box(f"Collar{i + 1}", (-w, ra, -4.45 - 0.05 * i), (w, rb, -4.2), c, "neck")
    for i in range(5):
        cx = -0.72 + 0.36 * i
        a.box(f"CollarDrop{i + 1}", (cx - 0.11, 3.55, -4.62), (cx + 0.11, 3.9, -4.4), GOLD, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        ma, mb = sorted((sx * hx, sx * 1.62))
        a.box("ManeCheek" + side, (ma, 5.6, -5.6), (mb, 7.0, -4.0), MANE, "neck")
    a.box("ManeNape", (-1.35, 5.6, -2.7), (1.35, 7.4, -1.9), MANE, "neck")

    # ---- nemes headdress: striped cap, side panels, lappets on the chest, the queue behind
    cap_y0, cap_y1 = hy1, 9.2
    nx = 1.62
    stripes = 9
    for i in range(stripes):
        xa = -nx + 2 * nx * i / stripes
        xb = -nx + 2 * nx * (i + 1) / stripes
        a.box(f"Nemes{i + 1}", (xa, cap_y0, -5.95), (xb, cap_y1 - 0.05 * abs(i - 4), -3.0), LAPIS if i % 2 == 0 else GOLD, "neck")
    a.box("Headband", (-1.66, 8.25, -6.08), (1.66, 8.65, -5.85), GOLD, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * hx, sx * nx))
        # side panels down the sides of the head, horizontal stripes
        for k in range(4):
            ya, yb = 8.6 - 0.6 * (k + 1), 8.6 - 0.6 * k
            a.box(f"NemesSide{side}{k + 1}", (xa, max(ya, 7.0), -5.85), (xb, yb, -3.0), GOLD if k % 2 else LAPIS, "neck")
        # lappets hanging in front of the shoulders
        la, lb = sorted((sx * 1.0, sx * 1.75))
        for k in range(6):
            ya, yb = 7.0 - 0.45 * (k + 1), 7.0 - 0.45 * k
            a.box(f"Lappet{side}{k + 1}", (la, ya, -5.15), (lb, yb, -4.45), LAPIS if k % 2 == 0 else GOLD, "neck")
        a.box("LappetEnd" + side, (la - 0.03, 4.05 - 0.25, -5.2), (lb + 0.03, 4.3, -4.4), GOLD_DARK, "neck")
    # the queue: the cloth gathered at the back of the head, a braid down the nape
    a.box("NemesBack", (-1.45, 7.2, -3.0), (1.45, 9.0, -2.6), LAPIS_DARK, "neck")
    for k in range(3):
        a.box(f"Queue{k + 1}", (-0.4, 6.0 + 0.4 * k, -2.6), (0.4, 6.4 + 0.4 * k, -2.2), GOLD if k % 2 else LAPIS, "neck")

    # ---- uraeus: a rearing gold cobra on the brow with a glowing ruby on its hood
    a.box("CobraBody", (-0.16, 8.6, -6.15), (0.16, 9.35, -5.9), GOLD, "neck")
    a.box("CobraHood", (-0.42, 9.2, -6.22), (0.42, 9.85, -6.02), GOLD, "neck")
    a.box("GlowCobraGem", (-0.15, 9.38, -6.28), (0.15, 9.68, -6.22), RUBY, "neck").neon = True
    a.box("CobraHead", (-0.2, 9.85, -6.45), (0.2, 10.1, -5.95), GOLD_DARK, "neck")

    # ---- false beard: a braid of gold and lapis bands under the chin, flaring at the end
    for k in range(4):
        a.box(f"Beard{k + 1}", (-0.28, 5.55 - 0.32 * (k + 1), -6.35), (0.28, 5.55 - 0.32 * k, -5.85), GOLD if k % 2 == 0 else LAPIS, "neck")
    a.box("BeardTip", (-0.36, 4.0, -6.42), (0.36, 4.27, -5.78), GOLD_DARK, "neck")

    # ---- round ears up through the cap's corners
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        xa, xb = sorted((sx * 0.85, sx * 1.5))
        a.box(bone, (xa, cap_y1 - 0.25, -4.7), (xb, 9.9, -4.05), COAT, bone)
        ia, ib = sorted((sx * 1.0, sx * 1.35))
        a.box(bone + "In", (ia, cap_y1 - 0.05, -4.75), (ib, 9.75, -4.7), MANE, bone)
        a.box(bone + "Ring", (xa - 0.04, cap_y1 - 0.25, -4.74), (xb + 0.04, cap_y1, -4.01), GOLD, bone)
        a.pivots[bone] = ((xa + xb) / 2, cap_y1 - 0.2, -4.4)
    a.pivots["neck"] = (0, 6.2, -3.2)

    # ---- tail: off the rump, down, ringed in gold, a dark tuft with a gold cap
    a.box("Tail", (-0.3, 5.3, z1), (0.3, 5.9, z1 + 1.7), COAT, "Tail")
    a.box("Tail2", (-0.3, 3.6, z1 + 1.1), (0.3, 5.3, z1 + 1.7), COAT, "Tail")
    a.box("TailRing1", (-0.36, 5.24, z1 + 0.6), (0.36, 5.96, z1 + 0.85), GOLD, "Tail")
    a.box("TailRing2", (-0.36, 4.5, z1 + 1.04), (0.36, 4.75, z1 + 1.76), GOLD, "Tail")
    a.box("TailCap", (-0.4, 3.45, z1 + 1.0), (0.4, 3.75, z1 + 1.8), GOLD, "Tail")
    a.box("TailTuft", (-0.5, 2.5, z1 + 0.9), (0.5, 3.45, z1 + 1.9), MANE, "Tail")
    a.pivots["Tail"] = (0, 5.9, z1)

    a.meta = {"seat": (0, 6.85, 0.5), "neck_loop": {"center": (0, 6.4, -4.4), "radius": 2.4}}
    a.animations = quad_animations
    return a


CAM = dict(eye=(-16, 11.5, -24), target=(0, 5.6, -0.8), W=900, H=900, fov=27)
VIEWS = [dict(eye=(-16, 11.5, -24), target=(0, 5.2, -0.6)), dict(eye=(-28, 6, 0), target=(0, 5.2, 0)),
         dict(eye=(26, 9, 8), target=(0, 5.2, 0)), dict(eye=(14, 13, 22), target=(0, 5.2, 0))]
BG = (238, 238, 232)


def shot(parts, **cam):
    im = render(parts, transparent=True, **cam)
    bg = Image.new("RGBA", im.size, BG + (255,))
    bg.alpha_composite(im)
    return bg.convert("RGB")


def main(out=os.path.join(A.ROOT, "designs", "tomb"), renders="/mnt/project-files/world2/tomb/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(renders, exist_ok=True)
    a = lion_archer()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    ps = pose(m, None, 0)
    for p in ps:
        p.neon = p.name.startswith("Glow")
    shot(ps, **CAM).save(os.path.join(renders, a.name + ".png"))
    sheet = Image.new("RGB", (1000, 1000))
    for i, cam in enumerate(VIEWS):
        sheet.paste(shot(ps, W=500, H=500, fov=36, **cam), ((i % 2) * 500, (i // 2) * 500))
    sheet.save(os.path.join(renders, a.name + "_views.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
