"""Rock Candy Dragon: World 3 Candyland giga-rare chase pet (about 1 in 1000 spawns).

A big flying dragon made of rock candy. Head, neck, body, tail and legs are one bright
cherry red (darker cherry stop on the undersides) with a cream-and-white sugar belly; the
faceted body segments are chunky crystallised sugar. The rainbow lives on the rock-candy
clusters along the spine (lemon, orange, lime, mint, sky, periwinkle, grape, bubblegum
crystals nose to tail, each a square shaft and a pyramid tip, with white sugar crystals
mixed in and some tips glowing) and in the wings: bat-dragon wings with a white candy-stick
arm, three white finger sticks fanning from the wrist (one red band each) and thick
stained-glass hard-candy panes between them (grape, sky, lime), scalloped along the back
edge. Big googly plate eyes, white crystal horns with glowing pink tips, a toothy grin,
lollipop-swirl cheeks; the tail ends in a candy stick and a big grape swirl lollipop. No
saddle: the rider sits on the back between the wings (meta seat). Legs hang under it.

Bones (each at 0, rests baked into the parts, so convert WITHOUT --zyx):
  root, neck (neck + head), WingL/WingL2, WingR/WingR2 (flap about Z), Tail1 > Tail2 > Tail3,
  LegFL, LegFR, LegHL, LegHR.

  idle    hovers, slow deep wingbeats, neck and tail rippling
  walk    quicker beats, nosing forward
  gallop  big fast beats, diving into the chase, tail streaming

    python3 tools/rock_candy_dragon.py [--still]
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal  # noqa: E402
from candy_common import T, Rx, Ry, Rz, TAU, track  # noqa: E402

NAME = "RockCandyDragon"
PERI = (112, 124, 252)      # between sky and grape on the tail
PERI_DK = (74, 84, 214)
CANE = C.CHERRY             # candy-cane stripes on the wing bones
CRYSTAL = (236, 246, 255)   # sugar-white crystal (horns, claws)
GLOW_PINK = (255, 170, 220)
GLOW_W = (230, 250, 255)
LEMON_P = (255, 240, 150)   # pastel sugar crystal colours for the spine clusters
LILAC_P = (226, 196, 255)
MINT_P = (170, 246, 214)
SKY_P = (170, 224, 255)


def lighten(c, k=0.45):
    return tuple(int(v + (255 - v) * k) for v in c)


def rock_candy_dragon():
    a = Animal(NAME, "Legendary")
    a.bone_order = [("root", None), ("neck", "root"),
                    ("WingL", "root"), ("WingL2", "WingL"), ("WingR", "root"), ("WingR2", "WingR"),
                    ("Tail1", "root"), ("Tail2", "Tail1"), ("Tail3", "Tail2"),
                    ("LegFL", "root"), ("LegFR", "root"), ("LegHL", "root"), ("LegHR", "root")]

    def rbox(name, size, M, color, bone):
        return C.rbox(a, name, size, M, color, bone)

    def rpyr(name, M, w, d, h, color, bone):
        return C.rpyr(a, name, M, w, d, h, color, bone)

    def beam(name, p0, p1, w, h, color, bone, pad=0.0):
        return C.beam(a, name, p0, p1, w, h, color, bone, pad)

    def crystal(name, base, d, w, shaft, tip, color, tipcolor, bone, roll=0.0, glow=False):
        """A sugar crystal: a square shaft from base along d, a pyramid tip on the end."""
        base = np.array(base, float)
        d = np.array(d, float)
        d /= np.linalg.norm(d)
        M = C.frame(base, base + d * shaft) @ Rz(roll)
        rbox(name, (w, w, shaft), M, color, bone)
        rpyr(("Glow" if glow else "") + name + "Tip", M @ T(0, 0, shaft / 2) @ Rx(90), w, w, tip, tipcolor, bone)

    def octo(name, z0, z1, hx, hy, cy, c, color, bone, dark=None):
        """A faceted gem segment along z: a tall box, a wide box and four chamfer prisms."""
        a.box(name, (-hx + c, cy - hy, z0), (hx - c, cy + hy, z1), color, bone)
        a.box(name + "W", (-hx, cy - hy + c, z0), (hx, cy + hy - c, z1), color, bone)
        for k, (sx, sy) in enumerate(((1, 1), (-1, 1), (1, -1), (-1, -1))):
            ax, ay = sx * (hx - c), cy + sy * (hy - c)
            col = color if sy > 0 else (dark or color)
            a.tri(f"{name}F{k + 1}", [(ax, ay), (ax + sx * c, ay), (ax, ay + sy * c)], z0, z1, col, bone)

    def swirl(name, center, normal, r, colors, bone, thick=0.6, glow_core=None):
        """A lollipop: stacked octagon discs facing along normal, each smaller and
        standing a little prouder (both faces), so the rings read as a candy swirl."""
        nx = np.array(normal, float) / np.linalg.norm(normal)
        c = np.array(center, float)
        M = C.frame(c - nx * 0.01, c + nx * 0.01)  # local z along the normal
        n = len(colors)
        for i, col in enumerate(colors):
            rr = r * (1 - i / (n + 0.4))
            th = thick + 0.24 * i
            nm = ("Glow" if glow_core and i == n - 1 else "") + f"{name}{i + 1}"
            for k, (fx, fy) in enumerate(((1.0, 0.6), (0.6, 1.0), (0.86, 0.86))):  # a stepped round disc
                rbox(f"{nm}{'abc'[k]}", (rr * 2 * fx, rr * 2 * fy, th), M, col, bone)

    # ================================================================ body (root)
    # nose-to-tail rainbow: head cherry, neck orange, chest lemon, back lime, rump mint, tail sky > periwinkle > grape
    cy = 7.2
    segs = [("Chest", -4.8, -1.6, 3.2, 2.8, C.CHERRY, C.CHERRY_DK),
            ("Back", -1.6, 1.6, 2.9, 2.45, C.CHERRY, C.CHERRY_DK),
            ("Rump", 1.6, 4.6, 2.6, 2.25, C.CHERRY, C.CHERRY_DK)]
    for name, z0, z1, hx, hy, col, dk in segs:
        octo(name, z0, z1, hx, hy, cy, 1.0, col, "root", dk)
    # broad shoulders over the front legs
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 2.6, sx * 3.6))
        a.box("Shoulder" + side, (xs[0], 6.2, -4.5), (xs[1], 8.9, -2.0), C.CHERRY_DK, "root")
    # darker sugar collars where the segments meet (proud rings, no coplanar faces)
    for i, (z, hx, hy, col) in enumerate(((-1.6, 2.75, 2.5, C.CHERRY_DK), (1.6, 2.65, 2.4, C.CHERRY_DK))):
        a.box(f"Collar{i + 1}", (-hx - 0.2 + 0.9, cy - hy - 0.02, z - 0.22), (hx + 0.2 - 0.9, cy + hy + 0.15, z + 0.22), col, "root")
        a.box(f"CollarW{i + 1}", (-hx - 0.15, cy - hy + 0.9, z - 0.22), (hx + 0.15, cy + hy - 0.9, z + 0.22), col, "root")
    # sugar-white belly plates
    for i in range(6):
        z0 = -4.3 + i * 1.45
        a.box(f"Belly{i + 1}", (-1.45, cy - 2.55, z0), (1.45, cy - 2.2, z0 + 1.25), C.WHITE if i % 2 == 0 else C.CREAM, "root")
    # chest plate under the neck
    a.box("ChestPlate", (-1.6, 4.9, -5.15), (1.6, 8.4, -4.7), C.CREAM, "root")

    # big rock-candy clusters on both flanks (two crystals splaying out of one spot)
    clusters = [(0.0, 5.6, C.LIME, C.LIME_DK), (3.1, 5.9, C.SKY, C.SKY_DK)]
    for side, sx in (("L", -1), ("R", 1)):
        for j, (z, y, col, dk) in enumerate(clusters):
            hx = 2.8 if abs(z) < 1.6 else 2.5
            base = (sx * (hx - 0.4), y, z)
            crystal(f"Rock{side}{j + 1}a", base, (sx, 0.25, -0.15), 1.0, 1.0, 1.0, dk,
                    lighten(col, 0.55), "root", 0, j == 1)
            crystal(f"Rock{side}{j + 1}b", base, (sx * 0.7, -0.5, 0.5), 0.7, 0.8, 0.7, col, lighten(col, 0.3), "root", 0)

    # spine: a row of chunky rock-candy clusters in pastel sugar colours
    def cluster(name, base, bone, s=1.0, cols=(C.WHITE, LILAC_P, MINT_P), glow=0):
        base = np.array(base, float)
        specs = [((0, 1, 0.35), 0.85, 1.0, 1.1), ((0.75, 0.75, 0.2), 0.6, 0.6, 0.8), ((-0.7, 0.8, 0.5), 0.6, 0.7, 0.8)]
        for k, ((dx, dy, dz), w, sh, tp) in enumerate(specs[:3 if s > 0.7 else 2]):
            col = cols[k % len(cols)]
            crystal(f"{name}{'abc'[k]}", base + (dx * 0.3 * s, 0, 0), (dx, dy, dz), w * s, sh * s, tp * s, col,
                    GLOW_PINK if k == glow else lighten(col, 0.4), bone, 0, k == glow)

    cluster("Spine1", (0, cy + 2.5, -4.0), "root", 1.6, (C.LEMON, LEMON_P, C.WHITE))
    cluster("Spine2", (0, cy + 2.4, -2.3), "root", 1.3, (C.LIME, C.WHITE, lighten(C.LIME, 0.5)), glow=1)
    cluster("Spine3", (0, cy + 2.0, 2.4), "root", 1.4, (C.MINT, MINT_P, C.WHITE))
    cluster("Spine4", (0, cy + 1.9, 3.9), "root", 1.2, (C.SKY, C.WHITE, SKY_P), glow=2)

    top = cy + 2.45  # 9.65, the Back segment's top: the rider sits here between the wings

    # ---- legs hanging under it in flight: chunky thigh, shin, foot, crystal claws (pyramids)
    for side, sx in (("L", -1), ("R", 1)):
        def lb(name, x0, x1, y0, y1, z0, z1, col, bone):
            xa, xb = sorted((sx * x0, sx * x1))
            return a.box(name + side, (xa, y0, z0), (xb, y1, z1), col, bone)
        # front legs, under the shoulders, reaching a little forward
        bone = "LegF" + side
        a.pivots[bone] = (sx * 2.6, 6.0, -3.2)
        lb("UpperArm", 1.9, 3.3, 3.6, 6.2, -4.1, -2.4, C.CHERRY, bone)
        lb("Forearm", 2.0, 3.2, 2.2, 3.8, -4.5, -3.0, C.CHERRY_DK, bone)
        lb("Hand", 1.9, 3.3, 1.6, 2.3, -4.9, -2.9, C.CHERRY_DK, bone)
        for k in range(3):
            x = sx * (2.15 + 0.45 * k)
            rpyr(f"ClawF{side}{k + 1}", T(x, 1.95, -4.9) @ Rx(-90), 0.36, 0.5, 0.6, CRYSTAL, bone)
        # hind legs: big drumstick thighs, shins swept back, long feet
        bone = "LegH" + side
        a.pivots[bone] = (sx * 2.5, 6.2, 3.0)
        lb("Thigh", 1.7, 3.4, 3.8, 7.6, 1.6, 4.4, C.CHERRY, bone)
        lb("Shin", 1.9, 3.2, 2.0, 4.0, 3.0, 4.8, C.CHERRY_DK, bone)
        lb("Foot", 1.8, 3.3, 1.4, 2.1, 2.3, 4.9, C.CHERRY_DK, bone)
        for k in range(3):
            x = sx * (2.05 + 0.5 * k)
            rpyr(f"ClawH{side}{k + 1}", T(x, 1.75, 2.3) @ Rx(-90), 0.38, 0.5, 0.65, CRYSTAL, bone)

    # ================================================================ neck and head
    a.pivots["neck"] = (0, 8.0, -4.4)
    neck_pts = [np.array(p) for p in ((0, 7.8, -4.0), (0, 9.4, -5.8), (0, 11.0, -7.4))]
    neck_w = [2.5, 2.2]
    for k in range(2):
        beam(f"Neck{k + 1}", neck_pts[k], neck_pts[k + 1], neck_w[k], neck_w[k], C.CHERRY, "neck", pad=1.0)
        rbox(f"NeckFacet{k + 1}", (neck_w[k] * 0.86, neck_w[k] * 0.86, np.linalg.norm(neck_pts[k + 1] - neck_pts[k]) + 0.6),
             C.frame(neck_pts[k], neck_pts[k + 1]) @ Rz(45), C.CHERRY_DK, "neck")
        # cream throat plates
        mid = (neck_pts[k] + neck_pts[k + 1]) / 2
        d = (neck_pts[k + 1] - neck_pts[k]) / np.linalg.norm(neck_pts[k + 1] - neck_pts[k])
        rbox(f"Throat{k + 1}", (neck_w[k] * 0.62, 0.4, 1.6), C.frame(mid, mid + d) @ T(0, -neck_w[k] / 2 - 0.05, 0), C.CREAM, "neck")
    for i, t in enumerate((0.35, 1.05)):
        p = neck_pts[0] + (neck_pts[2] - neck_pts[0]) * (t / 1.6)
        cluster(f"NeckSpine{i + 1}", p + (0, 0.9, 0.2), "neck", 1.15, ((C.ORANGE, C.WHITE, lighten(C.ORANGE, 0.5)) if i else (C.LEMON, C.WHITE, LEMON_P)), glow=0 if i else 3)

    # head: chunky cherry skull, snout with an open toothy grin, googly eyes on the face
    HR, HR_DK = C.CHERRY, C.CHERRY_DK
    a.box("Skull", (-1.95, 10.5, -10.6), (1.95, 14.2, -6.9), HR, "neck")
    a.box("SkullTop", (-1.6, 14.2, -10.3), (1.6, 14.55, -7.2), HR, "neck")
    a.box("SkullBack", (-1.65, 10.8, -6.9), (1.65, 13.8, -6.5), HR_DK, "neck")
    a.box("Snout", (-1.45, 10.62, -13.4), (1.45, 12.4, -10.6), HR, "neck")
    a.box("SnoutTop", (-1.2, 12.4, -13.1), (1.2, 12.65, -10.6), HR, "neck")
    a.wedge("Bridge", (-0.3, 12.4, -11.4), (0.3, 12.95, -10.6), HR_DK, "neck")
    a.box("Jaw", (-1.3, 9.2, -12.9), (1.3, 9.95, -8.6), HR_DK, "neck")
    a.box("JawBack", (-1.7, 9.5, -8.6), (1.7, 10.6, -7.1), HR_DK, "neck")
    a.box("Chin", (-0.8, 8.95, -12.7), (0.8, 9.2, -11.2), HR_DK, "neck")
    a.box("Mouth", (-1.25, 9.9, -12.8), (1.25, 10.66, -8.65), (70, 16, 40), "neck")  # dark gap of the grin
    a.box("PlainTongue", (-0.75, 9.95, -12.3), (0.75, 10.15, -9.4), C.BUBBLE, "neck")
    for i, x in enumerate((-1.05, -0.52, 0.0, 0.52, 1.05)):  # top teeth along the front
        rpyr(f"Tooth{i + 1}", T(x, 10.66, -13.15) @ Rx(180), 0.34, 0.3, 0.45 if i % 2 == 0 else 0.32, C.WHITE, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        for i, z in enumerate((-12.3, -11.4, -10.5, -9.6)):
            rpyr(f"Tooth{side}{i + 1}", T(sx * 1.17, 10.66, z) @ Rx(180), 0.28, 0.32, 0.42 if i % 2 == 0 else 0.3, C.WHITE, "neck")
        for i, z in enumerate((-12.4, -10.0)):
            rpyr(f"Fang{side}{i + 1}", T(sx * 1.0, 9.95, z), 0.32, 0.32, 0.45, C.WHITE, "neck")
        xs = sorted((sx * 0.35, sx * 0.75))
        a.box("Nostril" + side, (xs[0], 11.8, -13.45), (xs[1], 12.15, -13.38), HR_DK, "neck")
    C.front_eyes(a, 0.98, 12.55, 14.15, -10.6, 1.7, "neck", look=0.15)
    for side, sx in (("L", -1), ("R", 1)):
        # chunky brows tilted down toward the middle (a cheeky look)
        rbox("Brow" + side, (1.6, 0.4, 0.6), T(sx * 1.0, 14.35, -10.6) @ Rz(sx * 8), HR_DK, "neck")
        # swirled lollipop cheeks
        swirl("Cheek" + side, (sx * 1.95, 11.7, -8.5), (sx, 0, 0), 1.1, [C.STRAWB, C.WHITE, C.STRAWB], "neck", thick=0.5)
        # big sugar-crystal horns sweeping back, with a smaller pair below
        crystal("Horn" + side, (sx * 1.15, 13.9, -8.0), (sx * 0.38, 0.62, 0.75), 0.95, 2.6, 1.7, CRYSTAL, GLOW_PINK, "neck", 0, True)
        crystal("HornBand" + side, (sx * 1.15, 13.9, -8.0) + np.array((sx * 0.38, 0.62, 0.75)) / np.linalg.norm((0.38, 0.62, 0.75)) * 0.9,
                (sx * 0.38, 0.62, 0.75), 1.08, 0.45, 0.01, C.GRAPE, C.GRAPE, "neck")
        crystal("Horn2" + side, (sx * 1.75, 12.9, -7.6), (sx * 0.85, 0.3, 0.7), 0.6, 1.4, 1.0, CRYSTAL, GLOW_W, "neck", 0, False)
        # crystal frills behind the jaw
        for k, (dy, dz) in enumerate(((0.2, 0.9), (-0.4, 0.8))):
            crystal(f"Frill{side}{k + 1}", (sx * 1.6, 10.6 - 0.5 * k, -7.4), (sx * 0.7, dy, dz), 0.55, 0.8, 0.8,
                    HR_DK if k else HR, lighten(HR, 0.4), "neck", 0)
    for i, z in enumerate((-9.6, -8.4)):  # crest between the horns
        crystal(f"Crest{i + 1}", (0, 14.4, z), (0, 1, 0.5), 0.6 + 0.15 * i, 0.4, 0.8 + 0.3 * i, HR,
                lighten(HR, 0.6) if i else lighten(HR, 0.3), "neck", 45, i == 1)

    # ================================================================ tail: Tail1 > Tail2 > Tail3, lollipop tip
    tails = [("Tail1", 4.6, 8.6, 2.0, 1.85, 7.0, C.CHERRY, C.CHERRY_DK),
             ("Tail2", 8.6, 12.4, 1.5, 1.4, 6.7, C.CHERRY, C.CHERRY_DK),
             ("Tail3", 12.4, 15.8, 1.05, 1.0, 6.4, C.CHERRY, C.CHERRY_DK)]
    for bone, z0, z1, hx, hy, ty, col, dk in tails:
        a.pivots[bone] = (0, ty, z0)
        octo(bone, z0 - 0.3, z1, hx, hy, ty, 0.6 if hx > 1.2 else 0.4, col, bone, dk)
        cluster(f"{bone}Spine", (0, ty + hy - 0.2, (z0 + z1) / 2), bone, hx * 0.75,
                {"Tail1": (PERI, C.WHITE, SKY_P), "Tail2": (C.GRAPE, C.WHITE, LILAC_P), "Tail3": (C.BUBBLE, C.WHITE, LILAC_P)}[bone], glow=0 if bone == "Tail2" else 3)
    # candy stick and the big grape swirl lollipop
    a.box("TailStick", (-0.35, 6.05, 15.7), (0.35, 6.75, 17.4), C.WHITE, "Tail3")
    a.box("TailStickBand", (-0.4, 6.0, 16.3), (0.4, 6.8, 16.75), C.CHERRY, "Tail3")
    swirl("Lolly", (0, 6.4, 19.4), (1, 0, 0), 2.4, [C.GRAPE, C.WHITE, C.BUBBLE, C.WHITE, GLOW_PINK], "Tail3", thick=0.8, glow_core=True)
    a.box("LollyRim", (-0.5, 6.4 - 0.5, 17.1), (0.5, 6.4 + 0.5, 17.4), C.GRAPE_DK, "Tail3")

    # ================================================================ wings
    # Bat-dragon wings: a candy-stick arm out to the wrist, three finger sticks fanning out
    # and back from the wrist, thick hard-candy membrane between them with a scalloped
    # trailing edge (each pane dips between the finger tips). The panes are
    # stained glass, one rainbow colour per pane (grape, sky, lime), darker stop at the trailing edge.
    ARM = 5.6                                   # shoulder to wrist, along the wing
    fingers = [(86, 8.2), (52, 8.8), (16, 7.2)]  # (angle from the arm toward the back, length)
    panes = [(C.GRAPE, C.GRAPE_DK), (C.SKY, C.SKY_DK), (C.LIME, C.LIME_DK)]
    root_edge = 5.6                              # how far back the membrane reaches at the body
    for side, sx in (("L", -1), ("R", 1)):
        inner, outer = "Wing" + side, "Wing" + side + "2"
        root = np.array([sx * 2.6, 9.0, -2.9])
        W = T(*root) @ Rz(sx * 20) @ Ry(-sx * 10)

        def wpt(u, w, v=0.0):
            return (W @ np.array([sx * u, v, w, 1.0]))[:3]

        def strip(name, u, w, phi, r0, r1, width, thick, col, bone):
            """A box in the wing plane from radius r0 to r1 along angle phi (deg from the arm
            direction toward the back), measured from (u, w)."""
            M = W @ T(sx * u, 0, w) @ Ry(sx * (90 - phi)) @ T(0, 0, (r0 + r1) / 2)
            return rbox(name, (width, thick, r1 - r0), M, col, bone)

        a.pivots[inner] = tuple(root)
        a.pivots[outer] = tuple(wpt(ARM, 0))
        # arm: white candy stick, one red band, a pink knuckle at the wrist
        strip("Arm" + side, -0.4, 0, 0, 0, ARM + 0.3, 0.95, 0.95, C.WHITE, inner)
        strip("ArmBand" + side, -0.4, 0, 0, ARM * 0.45, ARM * 0.45 + 0.6, 1.05, 1.05, C.CHERRY, inner)
        rbox("Wrist" + side, (1.3, 1.3, 1.3), W @ T(sx * ARM, 0, 0), C.STRAWB, outer)
        rpyr("GlowThumb" + side, W @ T(sx * ARM, 0, -0.6) @ Rx(-90), 0.75, 0.75, 1.2, GLOW_PINK, outer)
        # fingers: white candy sticks, one red band, crystal claw tips
        for k, (phi, ln) in enumerate(fingers):
            strip(f"Finger{side}{k + 1}", ARM, 0, phi, 0.4, ln, 0.7, 0.85, C.WHITE, outer)
            strip(f"FingerBand{side}{k + 1}", ARM, 0, phi, ln * 0.5, ln * 0.5 + 0.45, 0.8, 0.95, C.CHERRY, outer)
            rpyr(f"FingerTip{side}{k + 1}", W @ T(sx * ARM, 0, 0) @ Ry(sx * (90 - phi)) @ T(0, 0, ln) @ Rx(90),
                 0.7, 0.85, 1.0, CRYSTAL, outer)
        # membranes fanning between the fingers (outer bone), a scalloped edge
        nst = 6
        for p in range(2):
            (pa, la), (pb, lb) = fingers[p], fingers[p + 1]
            col, dk = panes[p + 1]
            for j in range(nst):
                t = (j + 0.5) / nst
                phi = pa + (pb - pa) * t
                R = la + (lb - la) * t - 1.7 * math.sin(math.pi * t) - 0.2
                step = math.radians(abs(pb - pa) / nst)
                cutr = R * 0.6
                th = 0.55 if j % 2 == 0 else 0.62
                strip(f"Pane{side}{p + 1}{j + 1}", ARM, 0, phi, 0.3, cutr, cutr * step * 1.25 + 0.2, th, col, outer)
                strip(f"PaneDk{side}{p + 1}{j + 1}", ARM, 0, phi, cutr - 0.05, R, R * step * 1.2, th + 0.02, dk, outer)
        # the grape membrane between the body and the first finger (inner bone), scalloped too
        tip1 = np.array([ARM + fingers[0][1] * math.cos(math.radians(fingers[0][0])), fingers[0][1] * math.sin(math.radians(fingers[0][0]))])
        nin = 5
        for j in range(nin):
            t = (j + 0.5) / nin
            u = 0.3 + (tip1[0] - 0.6) * t
            R = root_edge + (tip1[1] - root_edge) * t - 1.5 * math.sin(math.pi * t)
            wd = (tip1[0] - 0.6) / nin + 0.12
            th = 0.55 if j % 2 == 0 else 0.62
            strip(f"PaneRoot{side}{j + 1}", u, 0, 90, 0.2, R * 0.6, wd, th, panes[0][0], inner)
            strip(f"PaneRootDk{side}{j + 1}", u, 0, 90, R * 0.6 - 0.05, R, wd, th + 0.02, panes[0][1], inner)

    # ================================================================ wrap up
    a.pivots["root"] = (0, cy, 0)
    lo, hi = C.extent(a)
    a.meta = {"seat": (0, round(top, 2), -0.2), "neck_loop": {"center": (0, 9.4, -5.8), "radius": 1.9}}
    for p in a.parts:
        if "In" in p.name and not p.name.startswith(("Eye", "Pupil", "Plain", "Mouth", "Nostril")):
            raise ValueError("'In' in a part name makes it plain: " + p.name)
    a.animations = animations
    return a


def animations():
    """Wings beat about Z (outer half lagging), the neck and tail ripple, the body bobs
    against the beats, the tucked legs dangle."""
    def moves(L, beats, amp, bias, pitch, bob, ripple, n):
        w = lambda u, ph=0.0: math.sin(TAU * (beats * u - ph))
        t = {"root": [track(L, lambda u: (pitch + 2 * w(u, 0.3), 0, 0), n),
                      track(L, lambda u: (0, -bob * w(u, 0.25), 0), n, "position")],
             "neck": [track(L, lambda u: (-pitch * 0.7 + 4 * w(u, 0.55), 6 * math.sin(TAU * u) if beats < 3 else 0, 0), n)]}
        for side, sx in (("L", -1), ("R", 1)):
            t["Wing" + side] = [track(L, lambda u, sx=sx: (0, 0, sx * (bias + amp * w(u))), n)]
            t["Wing" + side + "2"] = [track(L, lambda u, sx=sx: (0, 0, sx * 0.5 * amp * w(u, 0.15)), n)]
        for i in range(3):
            t[f"Tail{i + 1}"] = [track(L, lambda u, i=i: (ripple * (0.5 + 0.25 * i) * w(u, 0.2 + 0.12 * i) + pitch * 0.3,
                                                          ripple * 0.8 * math.sin(TAU * (u - 0.15 * i)), 0), n)]
        for leg in ("FL", "FR", "HL", "HR"):
            ph = 0.1 if leg[0] == "F" else 0.35
            t["Leg" + leg] = [track(L, lambda u, ph=ph: (6 * w(u, ph) - pitch * 0.5, 0, 0), n)]
        return t

    return {"idle": (2.0, moves(2.0, 2, 22, 4, 0, 4, 5, 32)),
            "walk": (1.0, moves(1.0, 2, 28, 4, -6, 5, 8, 24)),
            "gallop": (0.6, moves(0.6, 2, 36, 6, -12, 6, 11, 24))}


def close_cams(lo, hi, size):
    """Tighter framing than candy_common's (the wings make the box mostly air)."""
    c = (lo + hi) / 2
    d = float(np.linalg.norm(hi - lo)) * 0.95
    dirs = [(-0.62, 0.62, -0.62), (-1, 0.12, 0), (0.55, 0.5, 0.66), (0, 0.15, -1), (0, 1, 0.02)]
    return [dict(eye=tuple(c + np.array(v) / np.linalg.norm(v) * d), target=tuple(c), W=size, H=size, fov=40) for v in dirs]


def main():
    from PIL import Image
    import animal_designs as A
    from horse_rig import pose
    still = "--still" in sys.argv
    a = rock_candy_dragon()
    model = C.publish(a, still=True)
    lo, hi = C.extent(a)
    rest = pose(model, None, 0)
    C.shot(rest, **close_cams(lo, hi, 900)[0]).save(os.path.join(C.SHOTS, NAME + ".png"))
    sheet = Image.new("RGB", (1000, 1000))
    for i, cam in enumerate(close_cams(lo, hi, 500)[:4]):
        sheet.paste(C.shot(rest, **cam), ((i % 2) * 500, (i // 2) * 500))
    sheet.save(os.path.join(C.SHOTS, NAME + "_views.png"))
    if "--top" in sys.argv:
        C.shot(rest, **close_cams(lo, hi, 700)[4]).save(os.path.join(C.SHOTS, NAME + "_top.png"))
    if still:
        return
    frames = []
    side, hero = close_cams(lo, hi, 400)[1], close_cams(lo, hi, 400)[0]
    for name in ("idle", "walk", "gallop"):
        anim = A.anim_named(model, name)
        nf = max(12, int(anim["length"] * 20))
        for k in range(nf):
            ps = pose(model, anim, k / nf * anim["length"])
            im = Image.new("RGB", (800, 400))
            im.paste(C.shot(ps, **side), (0, 0))
            im.paste(C.shot(ps, **hero), (400, 0))
            frames.append(A.label(im, ["run" if name == "gallop" else name] * 2))
    A.gif(os.path.join(C.SHOTS, NAME + "_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main()
