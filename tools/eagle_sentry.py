"""Eagle Sentry: a World 2 Ancient Tomb animal (QM, Oct 13; Epic, flies like the Crystal Phoenix).
An original block take on the Tomb of the Ancients' falcon guardian: a big brown falcon in
Egyptian gold armour. A cream chest barred with brown chevrons under a layered usekh collar
(gold, lapis, turquoise, red rows with gold drops and a glowing turquoise jewel); a falcon head
with white plate eyes, angry gold brows and the black Horus eye markings, a slate hooked beak on
a yellow cere; a striped lapis-and-gold nemes headdress with a cobra on the brow and a glowing
sun disc above. Wide wings: gold-plated leading edges, gold pauldrons set with glowing Horus
eyes, a row of secondaries and six barred primaries fanned out with gold tips. A fanned barred
tail in a gold cuff, feathered thighs, yellow legs with gold anklets and black talons gripping a
long gold spear with a glowing head. A lapis saddle blanket with a gold frame and tassels, a red
seat, and a glowing Horus eye on each side drape.

Run: python3 tools/eagle_sentry.py [out_dir]

Phase 1 (model only, no animations yet). Built in Blockbench's ZYX Euler order; every bone rests
at 0 (wing sweep and dihedral baked into the cubes; points are pyramid meshes). Bones follow the
Phoenix: root (the body) -> neck (head, headdress, disc); root -> WingL, WingR, Tail, LegL, LegR
(the spear rides on LegR).
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402

horse_rig.EULER = "ZYX"
import snake_design as S  # noqa: E402
import angel_boss as AB  # noqa: E402  (box, axis_rot; sets S.SIZE = 1)
from hawkmoth import pyr, light_bg  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "EagleSentry"
MODEL = os.path.join(ROOT, "designs", "tomb", NAME + ".bbmodel")

COLORS = {"brown": (128, 78, 42),        # falcon back and wings
          "darkbrown": (84, 50, 28),     # flight feathers, bars
          "cream": (246, 232, 196),      # chest, feather bands
          "sand": (220, 201, 152),       # tomb sand #DCC998
          "gold": (246, 192, 44),
          "golddark": (204, 146, 30),
          "lapis": (36, 84, 196),
          "turq": (34, 196, 196),
          "red": (210, 52, 44),
          "yellow": (255, 206, 60),      # cere, legs
          "slate": (70, 72, 88),         # beak
          "black": (24, 20, 22),
          "white": (255, 255, 255),
          "glowgold": (255, 150, 24),    # sun disc
          "glowturq": (70, 246, 232)}    # jewels, Horus eyes, spearhead
TEX = {n: i for i, n in enumerate(COLORS)}
box = AB.box
R = AB.axis_rot

Y0 = 6.0   # body centre, before floor() lifts the lowest point GAP over y = 0
GAP = 1.0  # it flies: the spear in its talons never touches the ground
SCALE = 0.8  # built at 1.25x and shrunk: about 34 studs across the wings, near the Phoenix


def build():
    elements, groups = [], []

    def add_group(name, pivot, parent):
        g = S.group(name, pivot)
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    y0 = Y0
    T = TEX
    root = add_group("root", (0, y0, 0), None)

    # ---- body: brown, a cream chest barred with brown chevrons, cream belly
    put(root, [box("Body", (0, y0, 0), (6.0, 5.2, 8.0), T["brown"]),
               box("Chest", (0, y0 - 0.5, -3.6), (5.4, 4.0, 2.0), T["cream"]),
               box("Belly", (0, y0 - 2.55, 0.4), (5.2, 0.3, 6.4), T["cream"])])
    for k, y in enumerate((y0 - 1.75, y0 - 2.3)):
        for s in (-1, 1):
            for j, x in enumerate((0.75, 1.85)):
                put(root, [box(f"ChestBar{'LR'[s > 0]}{k + 1}{j + 1}", (s * x, y, -4.62), (1.0, 0.3, 0.1),
                               T["darkbrown"], R("z", -s * 22))])
    # scapular feathers stepping down the back behind the saddle
    for k, z in enumerate((3.2, 4.0)):
        for j, x in enumerate((-1.8, 0.0, 1.8)):
            put(root, [box(f"Scapular{k + 1}{j + 1}", (x, y0 + 2.55 - 0.3 * k, z), (1.7, 0.4, 1.4),
                           T["darkbrown" if (j + k) % 2 else "brown"])])

    # ---- usekh collar: concentric arcs on the chest, rows of gold / lapis / gold / turquoise / red
    ctop = y0 + 2.2
    rows = ("gold", "lapis", "gold", "turq", "red")
    for k, col in enumerate(rows):
        r = 1.0 + 0.6 * k
        n = 3 + 2 * k
        span = math.radians(140)
        for j in range(n):
            a = -span / 2 + span * (j + 0.5) / n
            L = 2 * r * math.sin(span / n / 2) + 0.12
            put(root, [box(f"Collar{k + 1}_{j + 1}", (r * math.sin(a), ctop - r * math.cos(a), -4.75 - 0.03 * k),
                           (L, 0.62, 0.3), T[col], R("z", math.degrees(a)))])
    for j in range(9):  # gold drops hanging off the last row
        a = math.radians(-60 + 15 * j)
        r = 3.75
        put(root, [pyr(f"CollarDrop{j + 1}", (r * math.sin(a), ctop - r * math.cos(a), -4.9),
                       (math.sin(a), -math.cos(a), 0), (math.cos(a), math.sin(a), 0), 0.8, 0.22, 0.12, T["gold"])])
    put(root, [box("Glow_CollarJewel", (0, ctop - 2.2, -5.05), (0.9, 0.9, 0.3), T["glowturq"], R("z", 45)),
               box("CollarJewelSet", (0, ctop - 2.2, -4.95), (1.3, 1.3, 0.2), T["golddark"], R("z", 45))])

    # ---- saddle: lapis blanket in a gold frame, side drapes with tassels and Horus eyes, red seat
    sz = 1.0
    sy = y0 + 2.6
    put(root, [box("Blanket", (0, sy + 0.1, sz), (6.2, 0.3, 4.8), T["lapis"]),
               box("BlanketTrimF", (0, sy + 0.18, sz - 2.35), (6.3, 0.3, 0.3), T["gold"]),
               box("BlanketTrimB", (0, sy + 0.18, sz + 2.35), (6.3, 0.3, 0.3), T["gold"]),
               box("Seat", (0, sy + 0.6, sz + 0.2), (3.2, 0.7, 3.0), T["red"]),
               box("SeatStripe", (0, sy + 0.62, sz + 0.2), (3.24, 0.7, 0.5), T["gold"]),
               box("Pommel", (0, sy + 0.95, sz - 1.55), (2.4, 1.4, 0.6), T["gold"]),
               box("PommelGem", (0, sy + 1.05, sz - 1.88), (0.7, 0.7, 0.1), T["lapis"]),
               box("Cantle", (0, sy + 0.9, sz + 1.95), (3.2, 1.2, 0.6), T["gold"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        x = s * 3.12
        put(root, [box(f"Drape{n}", (x, sy - 1.1, sz), (0.24, 2.6, 4.8), T["lapis"]),
                   box(f"DrapeTrim{n}", (x + s * 0.02, sy - 2.35, sz), (0.26, 0.4, 4.9), T["gold"]),
                   # the Horus eye on the drape: almond, pupil, brow, the drop and the curl
                   box(f"Glow_HorusEye{n}", (x + s * 0.13, sy - 0.9, sz), (0.1, 0.5, 1.4), T["glowturq"]),
                   box(f"HorusPupil{n}", (x + s * 0.17, sy - 0.9, sz - s * 0.0), (0.1, 0.5, 0.5), T["black"]),
                   box(f"Glow_HorusBrow{n}", (x + s * 0.13, sy - 0.35, sz), (0.1, 0.2, 1.6), T["glowturq"]),
                   box(f"Glow_HorusDrop{n}", (x + s * 0.13, sy - 1.45, sz - 0.25), (0.1, 0.7, 0.2), T["glowturq"]),
                   box(f"Glow_HorusCurl{n}", (x + s * 0.13, sy - 1.45, sz + 0.5), (0.1, 0.2, 0.8), T["glowturq"],
                       R("x", 30))])
        for j, z in enumerate((-1.8, -0.6, 0.6, 1.8)):
            put(root, [box(f"Tassel{n}{j + 1}", (x + s * 0.02, sy - 2.85, sz + z), (0.3, 0.6, 0.3),
                           T["red" if j % 2 else "gold"])])
    # gold girth strap round the belly
    put(root, [box("Girth", (0, y0 - 2.72, sz), (5.4, 0.1, 0.9), T["gold"])])

    # ---- neck and head
    neck = add_group("neck", (0, y0 + 1.6, -2.6), root)
    hy, hz = y0 + 4.8, -4.0
    put(neck, [box("Neck", (0, y0 + 2.3, -2.8), (3.6, 3.4, 3.6), T["brown"]),
               box("Head", (0, hy, hz), (4.4, 4.0, 4.6), T["brown"]),
               box("Face", (0, hy - 0.7, hz - 2.31), (3.6, 2.2, 0.1), T["cream"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        ex, ey, ez = s * 1.15, hy + 0.55, hz - 2.36
        put(neck, [box(f"Cheek{n}", (s * 2.21, hy - 0.8, hz - 0.6), (0.1, 1.8, 2.6), T["cream"]),
                   box(f"Eye{n}", (ex, ey, ez), (1.5, 1.5, 0.1), T["white"]),
                   box(f"Pupil{n}", (ex - s * 0.18, ey - 0.15, ez - 0.07), (0.75, 0.75, 0.05), T["black"]),
                   # angry gold brow slanting down to the middle
                   box(f"Brow{n}", (s * 1.15, hy + 1.55, hz - 2.45), (1.9, 0.45, 0.4), T["golddark"], R("z", s * 18)),
                   # Horus markings: the line back from the eye and the drop down the cheek
                   box(f"EyeLine{n}", (s * 2.0, ey - 0.5, hz - 2.36), (0.6, 0.35, 0.1), T["black"]),
                   box(f"EyeLineSide{n}", (s * 2.24, ey - 0.5, hz - 1.4), (0.1, 0.35, 2.0), T["black"]),
                   box(f"EyeDrop{n}", (s * 2.24, ey - 1.35, hz - 1.95), (0.1, 1.7, 0.45), T["black"])])
    # hooked slate beak on a yellow cere
    put(neck, [box("Cere", (0, hy - 0.2, hz - 2.6), (1.9, 1.1, 0.6), T["yellow"]),
               box("Beak", (0, hy - 0.55, hz - 3.5), (1.6, 1.2, 1.4), T["slate"]),
               box("BeakLower", (0, hy - 1.3, hz - 3.15), (1.2, 0.45, 1.1), T["black"]),
               pyr("BeakHook", (0, hy - 0.95, hz - 4.0), (0, -1, 0.35), (1, 0, 0), 1.3, 0.7, 0.3, T["slate"])])
    # nemes headdress: a gold cap striped lapis, a gold brow band with the cobra, striped lappets
    cy = hy + 2.15
    put(neck, [box("Cap", (0, cy, hz + 0.1), (4.8, 0.4, 4.6), T["gold"]),
               box("BrowBand", (0, hy + 2.0, hz - 2.4), (4.8, 0.5, 0.3), T["gold"]),
               box("BrowGem", (0, hy + 2.0, hz - 2.57), (0.6, 0.35, 0.1), T["lapis"])])
    for j, x in enumerate((-1.8, -0.6, 0.6, 1.8)):
        put(neck, [box(f"CapStripe{j + 1}", (x, cy + 0.02, hz + 0.1), (0.55, 0.42, 4.62), T["lapis"])])
    # the cobra: body rising off the band, the hood, a red glowing eye
    put(neck, [box("CobraBody", (0, hy + 2.6, hz - 2.6), (0.45, 1.0, 0.45), T["gold"]),
               box("CobraHood", (0, hy + 3.3, hz - 2.65), (1.1, 0.9, 0.3), T["gold"]),
               box("CobraHoodInner", (0, hy + 3.25, hz - 2.82), (0.6, 0.6, 0.06), T["lapis"]),
               box("CobraHead", (0, hy + 3.85, hz - 2.75), (0.5, 0.35, 0.6), T["gold"]),
               box("Glow_CobraEyes", (0, hy + 3.9, hz - 3.06), (0.45, 0.1, 0.05), T["red"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        M = R("z", -s * 9)
        base = np.array([s * 2.6, hy + 1.6, hz + 0.7])
        for j in range(6):
            off = M @ np.array([0, -0.7 * j, 0])
            put(neck, [box(f"Lappet{n}{j + 1}", base + off, (0.45, 0.72, 3.0), T["lapis" if j % 2 else "gold"], M)])
    # the queue at the back, wrapped in gold and lapis
    for j in range(4):
        put(neck, [box(f"Queue{j + 1}", (0, hy + 1.2 - 0.85 * j, hz + 2.45), (1.6 - 0.12 * j, 0.88, 0.5),
                       T["gold" if j % 2 == 0 else "lapis"])])
    # glowing sun disc on a gold stem, framed in gold
    dy, dz = hy + 5.0, hz + 0.9
    put(neck, [box("DiscStem", (0, cy + 0.75, dz), (0.9, 1.2, 0.6), T["golddark"])])
    for j, (w, h) in enumerate(((3.8, 2.0), (3.2, 3.2), (2.0, 3.8))):
        put(neck, [box(f"Glow_Sun{j + 1}", (0, dy, dz - 0.05), (w, h, 0.5), T["glowgold"]),
                   box(f"SunRim{j + 1}", (0, dy, dz + 0.12), (w + 0.6, h + 0.6, 0.4), T["golddark"])])
    # little horns of the disc mount (cow horns like Hathor's crown, gold)
    for s in (-1, 1):
        n = "LR"[s > 0]
        put(neck, [pyr(f"DiscHorn{n}", (s * 1.5, cy + 0.5, dz), (s * 0.5, 1, 0), (0, 0, 1), 2.3, 0.3, 0.3,
                       T["gold"])])

    # ---- wings: (x, y, z) in the wing frame, x out along the span, z back across the chord
    for s in (-1, 1):
        n = "LR"[s > 0]
        pivot = np.array([s * 2.9, y0 + 1.6, -1.2])
        node = add_group("Wing" + n, pivot, root)
        M = R("z", s * 10) @ R("y", -s * 6)
        P = lambda x, y, z: pivot + M @ np.array([s * x, y, z])  # noqa: E731
        Ry = lambda phi: M @ R("y", -s * phi)  # noqa: E731  (a piece turned phi deg back in the wing plane)
        ps = [box(f"Coverts{n}", P(4.8, 0, 1.3), (9.6, 0.8, 4.4), T["brown"], M),
              box(f"CovertsLow{n}", P(4.8, -0.05, 3.7), (9.4, 0.65, 1.0), T["darkbrown"], M),
              box(f"Edge{n}", P(5.2, 0.15, -1.25), (10.4, 1.0, 0.9), T["gold"], M),
              box(f"EdgeBand{n}", P(5.2, 0.15, -0.65), (10.2, 0.9, 0.3), T["lapis"], M),
              box(f"Pauldron{n}", P(1.2, 0.75, 0.6), (3.0, 1.0, 3.6), T["gold"], M),
              box(f"PauldronRim{n}", P(1.2, 0.8, 2.55), (3.1, 0.9, 0.35), T["lapis"], M),
              box(f"Glow_PauldronEye{n}", P(1.2, 1.28, 0.6), (1.4, 0.06, 0.6), T["glowturq"], M),
              box(f"PauldronPupil{n}", P(1.2, 1.31, 0.6), (0.5, 0.06, 0.5), T["black"], M)]
        for j in range(3):  # rivets along the gold edge
            ps.append(box(f"Rivet{n}{j + 1}", P(3.5 + 2.6 * j, 0.7, -1.25), (0.5, 0.2, 0.5), T["golddark"], M))
        # secondaries: a row of feathers trailing back, cream bands near their ends
        for j in range(6):
            x = 1.0 + 1.5 * j
            L = 4.6 + 0.25 * j
            ps += [box(f"Secondary{n}{j + 1}", P(x, -0.15, 4.2 + L / 2), (1.4, 0.5, L), T["darkbrown"], M),
                   box(f"SecondaryBand{n}{j + 1}", P(x, -0.15, 4.2 + L - 1.3), (1.44, 0.54, 0.6), T["cream"], M)]
        # primaries: six long barred feathers fanned out from the hand, gold tips
        for j in range(6):
            phi = 2 + 11 * j
            L = 8.0 - 0.5 * j
            d = np.array([math.cos(math.radians(phi)), 0, math.sin(math.radians(phi))])
            base = np.array([9.2, -0.1 - 0.04 * j, -0.6 + 0.85 * j])
            at = lambda u: P(*(base + d * u))  # noqa: E731
            ps += [box(f"Primary{n}{j + 1}", at(L / 2), (L, 0.5, 1.3), T["darkbrown"], Ry(phi)),
                   box(f"PrimaryBand{n}{j + 1}a", at(L * 0.4), (0.7, 0.54, 1.34), T["cream"], Ry(phi)),
                   box(f"PrimaryBand{n}{j + 1}b", at(L * 0.7), (0.7, 0.54, 1.34), T["cream"], Ry(phi))]
            tip_d = M @ np.array([s * d[0], 0, d[2]])
            ps.append(pyr(f"PrimaryTip{n}{j + 1}", at(L), tip_d, M @ np.array([-d[2], 0, s * d[0]]), 1.6, 0.65, 0.25, T["gold"]))
        put(node, ps)

    # ---- tail: seven barred feathers fanned back from a gold cuff
    tail = add_group("Tail", (0, y0 + 0.6, 3.8), root)
    put(tail, [box("TailCuff", (0, y0 + 0.6, 4.5), (4.0, 1.8, 1.2), T["gold"]),
               box("TailCuffBand", (0, y0 + 0.6, 4.5), (4.06, 0.5, 1.26), T["lapis"])])
    for j in range(7):
        psi = -36 + 12 * j
        L = 6.5 - 0.35 * abs(j - 3)
        d = np.array([math.sin(math.radians(psi)), -0.12, math.cos(math.radians(psi))])
        d /= np.linalg.norm(d)
        base = np.array([0, y0 + 0.55 + 0.05 * (3 - abs(j - 3)), 5.0])
        Mt = R("y", psi) @ R("x", 7)
        put(tail, [box(f"TailFeather{j + 1}", base + d * L / 2, (1.3, 0.45, L), T["brown" if j % 2 else "darkbrown"], Mt),
                   box(f"TailBand{j + 1}a", base + d * L * 0.45, (1.34, 0.5, 0.6), T["cream"], Mt),
                   box(f"TailBand{j + 1}b", base + d * L * 0.78, (1.34, 0.5, 0.6), T["cream"], Mt),
                   pyr(f"TailTip{j + 1}", base + d * L, d, Mt @ np.array([1.0, 0, 0]), 1.2, 0.6, 0.22, T["gold"])])

    # ---- legs: feathered thighs, yellow legs, gold anklets, toes curled over the spear
    ly = y0 - 6.0  # the spear's centre line
    for s in (-1, 1):
        n = "LR"[s > 0]
        node = add_group("Leg" + n, (s * 1.7, y0 - 2.0, 0.6), root)
        ps = [box(f"Thigh{n}", (s * 1.7, y0 - 2.7, 0.6), (2.0, 2.2, 2.4), T["brown"]),
              box(f"ThighFringe{n}", (s * 1.7, y0 - 3.7, 0.6), (2.1, 0.5, 2.5), T["cream"]),
              box(f"Shin{n}", (s * 1.3, y0 - 4.6, 0.6), (0.9, 2.2, 0.9), T["yellow"]),
              box(f"Anklet{n}", (s * 1.3, y0 - 4.3, 0.6), (1.2, 0.55, 1.2), T["gold"]),
              box(f"AnkletBand{n}", (s * 1.3, y0 - 4.7, 0.6), (1.15, 0.25, 1.15), T["lapis"]),
              box(f"Foot{n}", (s * 1.3, ly + 0.4, 0.6), (1.1, 0.5, 1.4), T["yellow"]),
              box(f"BackToe{n}", (s * 1.95, ly + 0.3, 0.6), (0.6, 0.4, 0.45), T["yellow"]),
              pyr(f"BackTalon{n}", (s * 2.2, ly + 0.3, 0.6), (s * 0.3, -1, 0), (0, 0, 1), 0.8, 0.2, 0.2, T["black"])]
        for j, dz in enumerate((-0.5, 0.0, 0.5)):
            ps += [box(f"Toe{n}{j + 1}", (s * 0.6, ly + 0.4, 0.6 + dz), (1.2, 0.38, 0.38), T["yellow"]),
                   pyr(f"Talon{n}{j + 1}", (s * 0.05, ly + 0.35, 0.6 + dz), (-s * 0.35, -1, 0), (0, 0, 1), 0.75,
                       0.17, 0.17, T["black"])]
        if s > 0:  # the spear rides on the right leg's bone
            ps += [box("SpearShaft", (0, ly, -1.5), (0.5, 0.5, 15.0), T["golddark"]),
                   box("SpearRingF", (0, ly, -8.2), (0.7, 0.7, 0.5), T["lapis"]),
                   box("SpearRingM", (0, ly, -1.5), (0.7, 0.7, 0.6), T["lapis"]),
                   box("SpearRingB", (0, ly, 5.2), (0.7, 0.7, 0.5), T["lapis"]),
                   box("SpearSocket", (0, ly, -9.2), (0.8, 0.8, 1.0), T["gold"]),
                   pyr("Glow_SpearHead", (0, ly, -9.7), (0, 0, -1), (1, 0, 0), 2.8, 0.75, 0.3, T["glowturq"]),
                   box("SpearTassel", (0, ly - 0.6, -8.7), (0.3, 0.8, 0.3), T["red"]),
                   pyr("SpearButt", (0, ly, 6.0), (0, 0, 1), (1, 0, 0), 1.0, 0.3, 0.3, T["gold"])]
        put(node, ps)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def shrink(model, k=SCALE):
    """Scale the whole build about the origin (cubes, meshes, bone pivots)."""
    sc = lambda v: [round(x * k, 4) for x in v]  # noqa: E731
    for e in model["elements"]:
        if "from" in e:
            for key in ("from", "to", "origin"):
                e[key] = sc(e[key])
        else:
            for vk, v in e["vertices"].items():
                e["vertices"][vk] = sc(v)
    for g in model["groups"]:
        g["origin"] = sc(g["origin"])


def floor(model):
    """Shift so the lowest point (the spear) hovers GAP over y = 0."""
    lo = min(q[:, 1].min() for p in S.posed(model) for q in p.polys)
    d = (GAP - lo) * S.BB
    for e in model["elements"]:
        if "from" in e:
            for k in ("from", "to", "origin"):
                e[k][1] = round(e[k][1] + d, 4)
        else:
            for v in e["vertices"].values():
                v[1] = round(v[1] + d, 4)
    for g in model["groups"]:
        g["origin"][1] = round(g["origin"][1] + d, 4)
    return GAP - lo


def posed(m):
    parts = S.posed(m)
    for p in parts:
        if p.name.startswith("Glow"):
            p.neon = True
    return parts


def main(out="/mnt/project-files/world2/tomb"):
    renders = os.path.join(out, "renders")
    os.makedirs(renders, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    shrink(m)
    shift = floor(m)
    with open(MODEL, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    parts = posed(m)
    P = np.concatenate([q for p in parts for q in p.polys])
    print("elements", len(m["elements"]), "shift", round(shift, 3), "bounds", P.min(0).round(1), P.max(0).round(1))
    # the 3/4 front view on a plain light background
    light_bg(render(parts, W=1200, H=1000, fov=30, eye=(-30, 20, -36), target=(1.5, 6, 1), transparent=True)).save(
        os.path.join(renders, NAME + ".png"))
    # a check sheet: next to the Horse, front, top, side
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([22, 0, -8]) for q in p.polys]
    cams = [dict(eye=(-34, 22, -44), target=(4, 5, 0)), dict(eye=(0, 9, -46), target=(0, 6, 0)),
            dict(eye=(0, 52, 6), target=(0, 5, 0)), dict(eye=(42, 9, 2), target=(0, 6, 0))]
    Wd, Ht = 640, 520
    sheet = Image.new("RGB", (Wd * 2, Ht * 2))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts + (hparts if i == 0 else []), W=Wd, H=Ht, fov=40, **cam), ((i % 2) * Wd, (i // 2) * Ht))
    sheet.save(os.path.join(out, NAME + "_sheet.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
