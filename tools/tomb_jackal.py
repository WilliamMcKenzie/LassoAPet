"""Tomb Jackal: World 2 Ancient Tomb Rare (QM, Oct 13), an original block take on the
Tomb of the Ancients jackal: a tall, slim Anubis-style jackal in gold armour.

Indigo-black coat with a lighter belly, a long narrow snout with a black nose, very tall
pointed ears with gold insides and gold ear cuffs, Horse googly eyes with gold kohl
wings, and a striped nemes headdress: a gold/lapis striped cap on the head and striped
lappets hanging down both sides of the neck, with a turquoise scarab on the forehead.
A broad usekh collar (gold, lapis, turquoise and gold crescent bands with gold drops)
covers the chest. Gold armour: shoulder pauldrons with a lapis band and turquoise gem,
hip plates, studded spine plates, a red saddle with gold pommel and cantle over lapis
side drapes, each drape with a gold ankh. Gold bracers, knee guards and anklets on the
long legs, black paws with toes, and a long tail with gold rings.

Phase 1 is the model only. Same bones as every quadruped (root, neck, EarL, EarR, Tail,
Leg*), no turned parts, so the bones stay at 0.

    python3 tools/tomb_jackal.py

writes designs/tomb/TombJackal.bbmodel and the renders to /mnt/project-files/world2/tomb/renders/.
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402
from partlib import render  # noqa: E402
from horse_rig import pose  # noqa: E402

FUR = (58, 54, 84)
BELLY = (88, 82, 120)
NOSE = (24, 22, 30)
PAW = (34, 32, 46)
GOLD = (255, 196, 46)
GOLD_DARK = (226, 152, 28)
LAPIS = (38, 92, 214)
TURQ = (36, 204, 192)
RED = (214, 46, 52)
SAND = (220, 201, 152)


def sym(a, name, lo, hi, color, bone):
    """A box on the right side (x > 0) and its mirror on the left."""
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * lo[0], sx * hi[0]))
        b = bone.replace("*", side)
        a.box(name.replace("*", side), (xa, lo[1], lo[2]), (xb, hi[1], hi[2]), color, b)


def jackal():
    a = Animal("TombJackal", "Rare")
    x, y0, y1, z0, z1 = 1.5, 3.6, 6.2, -2.8, 3.2
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
    a.box("Chest", (-x, 3.2, z0), (x, y1, -1.2), FUR, "root")
    a.box("Body", (-x, y0, -1.2), (x, y1, z1), FUR, "root")
    a.box("Belly", (-1.1, y0 - 0.15, -1.0), (1.1, y0, 2.4), BELLY, "root")

    # ---- long legs: fur, gold bracer, gold anklet, black paw with two toes
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.4, sx * 1.3))
        za = z0 + 0.001 if front else z1 - 0.001 - 1.0
        zb = za + 1.0
        name = "Leg" + leg
        a.box(name, (xa, 0.8, za), (xb, y0, zb), FUR, name)
        a.box("Bracer" + leg, (xa - 0.08, 2.1, za - 0.08), (xb + 0.08, 2.6, zb + 0.08), GOLD, name)
        a.box("BracerBand" + leg, (xa - 0.1, 2.25, za - 0.1), (xb + 0.1, 2.45, zb + 0.1), LAPIS, name)
        a.box("Anklet" + leg, (xa - 0.08, 0.5, za - 0.08), (xb + 0.08, 0.8, zb + 0.08), GOLD, name)
        a.box("Paw" + leg, (xa, 0, za - 0.25), (xb, 0.5, zb), PAW, name)
        mid = (xa + xb) / 2
        a.box("ToeA" + leg, (xa + 0.05, 0, za - 0.5), (mid - 0.03, 0.3, za - 0.25), PAW, name)
        a.box("ToeB" + leg, (mid + 0.03, 0, za - 0.5), (xb - 0.05, 0.3, za - 0.25), PAW, name)
        if front:  # gold knee guard on the front of the leg
            a.box("Knee" + leg, (xa + 0.1, 2.75, za - 0.18), (xb - 0.1, 3.35, za), GOLD_DARK, name)
        a.pivots[name] = ((xa + xb) / 2, y0 - 0.025, zb - 0.05 if front else za + 0.05)

    # ---- neck, head and snout (neck bone)
    a.box("Neck", (-1.0, 5.4, -3.8), (1.0, 7.4, -2.2), FUR, "neck")
    hx, hy0, hy1, hz0, hz1 = 1.2, 6.8, 8.6, -5.2, -3.2
    a.box("Head", (-hx, hy0, hz0), (hx, hy1, hz1), FUR, "neck")
    a.box("Snout", (-0.6, 6.9, -7.6), (0.6, 7.7, hz0), FUR, "neck")
    a.box("SnoutBridge", (-0.45, 7.7, -6.6), (0.45, 7.95, hz0), FUR, "neck")
    a.box("Jaw", (-0.5, 6.5, -7.1), (0.5, 6.9, hz0 + 0.4), BELLY, "neck")
    a.box("Nose", (-0.35, 7.2, -7.8), (0.35, 7.75, -7.6), NOSE, "neck")
    a.box("MouthLine", (-0.62, 6.86, -7.62), (0.62, 6.94, -5.6), NOSE, "neck")
    a.eyes(hx, 7.5, 8.35, -5.0, -4.1)
    # gold kohl wings sweeping back from each eye
    sym(a, "Kohl*", (hx, 7.62, -4.1), (hx + 0.05, 7.78, -3.4), GOLD, "neck")
    sym(a, "KohlTip*", (hx, 7.45, -3.55), (hx + 0.05, 7.62, -3.4), GOLD, "neck")
    a.pivots["neck"] = (0, 6.0, -2.4)

    # ---- nemes headdress: striped cap over the head, a gold brow band, striped
    # lappets down both sides of the neck and a back flap
    a.box("Brow", (-hx - 0.05, 8.35, hz0 - 0.05), (hx + 0.05, 8.65, hz1 + 0.05), GOLD, "neck")
    stripes = [(-1.25, -0.75, GOLD), (-0.75, -0.25, LAPIS), (-0.25, 0.25, GOLD), (0.25, 0.75, LAPIS), (0.75, 1.25, GOLD)]
    for i, (xa, xb, c) in enumerate(stripes):
        a.box(f"Nemes{i + 1}", (xa, 8.65, -5.0), (xb, 8.95, hz1 + 0.6), c, "neck")
    lap = [GOLD, LAPIS, GOLD, LAPIS, GOLD, LAPIS, GOLD]
    for i, c in enumerate(lap):
        ya, yb = 8.6 - 0.45 * (i + 1), 8.6 - 0.45 * i
        w = 0.32 + 0.03 * i  # flaring out a little as they hang
        sym(a, f"Lappet{i + 1}*", (hx, ya, -3.9 - 0.05 * i), (hx + w, yb, -2.9), c, "neck")
    for i, c in enumerate([GOLD, LAPIS, GOLD, LAPIS]):
        ya, yb = 8.6 - 0.5 * (i + 1), 8.6 - 0.5 * i
        a.box(f"NemesBack{i + 1}", (-1.0 + 0.05 * i, ya, -2.6), (1.0 - 0.05 * i, yb, -2.1), c, "neck")
    a.box("NemesTail", (-0.4, 5.9, -2.5), (0.4, 6.6, -1.6), GOLD_DARK, "neck")

    # turquoise scarab on the forehead with gold wings
    a.box("ScarabBody", (-0.25, 8.0, hz0 - 0.2), (0.25, 8.5, hz0), TURQ, "neck")
    a.box("ScarabHead", (-0.15, 8.5, hz0 - 0.18), (0.15, 8.68, hz0 - 0.02), TURQ, "neck")
    sym(a, "ScarabWing*", (0.25, 8.15, hz0 - 0.14), (0.7, 8.4, hz0 - 0.02), GOLD, "neck")

    # ---- very tall pointed ears through the nemes: prism halves, gold insides,
    # two gold cuffs
    ey = 8.95
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        c = sx * 0.8
        for half, dx in (("A", -1), ("B", 1)):
            a.tri(f"{bone}{half}", [(c, ey), (c + dx * 0.55, ey), (c, ey + 2.6)], -4.3, -3.6, FUR, bone)
            a.tri(f"{bone}In{half}", [(c, ey + 0.15), (c + dx * 0.33, ey + 0.15), (c, ey + 2.0)], -4.36, -4.3, GOLD, bone)
        a.box(bone + "Cuff", (c - 0.5, ey, -4.38), (c + 0.5, ey + 0.25, -3.52), GOLD, bone)
        a.box(bone + "Cuff2", (c - 0.3, ey + 0.75, -4.38), (c + 0.3, ey + 0.95, -3.52), GOLD_DARK, bone)
        a.box(bone + "Gem", (c - 0.1, ey + 0.03, -4.46), (c + 0.1, ey + 0.22, -4.38), TURQ, bone)
        a.pivots[bone] = (c, ey, -3.95)

    # ---- usekh broad collar: a ring round the neck base and crescent bands on the chest
    a.box("CollarRing", (-1.3, 5.3, -4.0), (1.3, 5.75, -2.0), GOLD, "neck")
    bands = [(5.2, 5.6, 1.5, GOLD), (4.8, 5.2, 1.35, LAPIS), (4.4, 4.8, 1.15, TURQ), (4.05, 4.4, 0.95, GOLD), (3.75, 4.05, 0.7, RED)]
    for i, (ya, yb, w, c) in enumerate(bands):
        a.box(f"Usekh{i + 1}", (-w, ya, z0 - 0.15 - 0.02 * i), (w, yb, z0), c, "root")
    for i, dx in enumerate((-0.9, -0.45, 0.0, 0.45, 0.9)):
        drop = 3.45 if dx else 3.25
        a.box(f"Drop{i + 1}", (dx - 0.12, drop, z0 - 0.2), (dx + 0.12, 3.8, z0 - 0.05), GOLD, "root")
    sym(a, "UsekhSide*", (x, 4.4, -2.75), (x + 0.08, 5.6, -2.2), GOLD, "root")

    # ---- gold shoulder pauldrons: plate, lapis band, rim, turquoise gem
    sym(a, "Pauldron*", (x, 4.6, -2.7), (x + 0.25, 6.15, -1.1), GOLD, "root")
    sym(a, "PauldronBand*", (x + 0.25, 5.05, -2.6), (x + 0.32, 5.4, -1.2), LAPIS, "root")
    sym(a, "PauldronRim*", (x + 0.25, 4.6, -2.7), (x + 0.32, 4.8, -1.1), GOLD_DARK, "root")
    sym(a, "PauldronGem*", (x + 0.32, 5.6, -2.1), (x + 0.4, 5.9, -1.7), TURQ, "root")
    sym(a, "PauldronTop*", (0.6, y1, -2.7), (x + 0.25, y1 + 0.2, -1.1), GOLD, "root")

    # studded spine plates in front of the saddle, stepping up toward it
    for i, (za, zb) in enumerate(((-2.7, -2.15), (-2.05, -1.5))):
        a.box(f"Spine{i + 1}", (-0.45, y1, za), (0.45, y1 + 0.3 + 0.08 * i, zb), GOLD, "root")

    # ---- saddle: lapis side drapes with gold trim and an ankh, red seat, gold
    # pommel and cantle
    dz0, dz1 = -0.9, 2.2
    a.box("SaddleBlanket", (-x - 0.05, y1, dz0), (x + 0.05, y1 + 0.12, dz1), SAND, "root")
    sym(a, "Drape*", (x, 4.3, dz0 + 0.1), (x + 0.1, y1 + 0.12, dz1 - 0.1), LAPIS, "root")
    sym(a, "DrapeHem*", (x, 4.1, dz0 + 0.1), (x + 0.14, 4.35, dz1 - 0.1), GOLD, "root")
    sym(a, "DrapeEdgeF*", (x, 4.1, dz0), (x + 0.14, y1 + 0.12, dz0 + 0.15), GOLD, "root")
    sym(a, "DrapeEdgeB*", (x, 4.1, dz1 - 0.15), (x + 0.14, y1 + 0.12, dz1), GOLD, "root")
    # ankh on each drape: stem, crossbar and a loop of four blocks
    ax, ac = x + 0.1, 0.65
    sym(a, "AnkhStem*", (ax, 4.5, ac - 0.12), (ax + 0.06, 5.25, ac + 0.12), GOLD, "root")
    sym(a, "AnkhBar*", (ax, 5.15, ac - 0.45), (ax + 0.06, 5.35, ac + 0.45), GOLD, "root")
    sym(a, "AnkhLoopL*", (ax, 5.35, ac - 0.3), (ax + 0.06, 5.85, ac - 0.12), GOLD, "root")
    sym(a, "AnkhLoopR*", (ax, 5.35, ac + 0.12), (ax + 0.06, 5.85, ac + 0.3), GOLD, "root")
    sym(a, "AnkhLoopT*", (ax, 5.85, ac - 0.3), (ax + 0.06, 6.0, ac + 0.3), GOLD, "root")
    a.box("Seat", (-0.95, y1 + 0.12, -0.4), (0.95, y1 + 0.42, 1.8), RED, "root")
    a.box("SeatStripe", (-0.25, y1 + 0.42, -0.4), (0.25, y1 + 0.46, 1.8), GOLD, "root")
    a.box("Pommel", (-0.7, y1 + 0.12, -0.8), (0.7, y1 + 0.85, -0.4), GOLD, "root")
    a.box("PommelGem", (-0.18, y1 + 0.4, -0.88), (0.18, y1 + 0.7, -0.8), TURQ, "root")
    a.box("Cantle", (-0.95, y1 + 0.12, 1.8), (0.95, y1 + 0.95, 2.2), GOLD, "root")
    a.box("CantleBand", (-0.97, y1 + 0.5, 1.78), (0.97, y1 + 0.65, 2.22), LAPIS, "root")

    # ---- gold hip armour: side plates with lapis stripes and a striped rump plate
    sym(a, "Hip*", (x, 4.5, 2.25), (x + 0.22, y1, z1 - 0.05), GOLD, "root")
    sym(a, "HipStripeA*", (x + 0.22, 5.4, 2.35), (x + 0.28, 5.6, z1 - 0.15), LAPIS, "root")
    sym(a, "HipStripeB*", (x + 0.22, 4.85, 2.35), (x + 0.28, 5.05, z1 - 0.15), LAPIS, "root")
    sym(a, "HipGem*", (x + 0.28, 5.12, 2.55), (x + 0.36, 5.33, 2.85), TURQ, "root")
    for i, c in enumerate((GOLD, LAPIS, GOLD)):
        za = 2.25 + 0.3 * i
        a.box(f"Rump{i + 1}", (-x - 0.05, y1, za), (x + 0.05, y1 + 0.18, za + 0.3), c, "root")

    # ---- long tail with gold rings, curving down to a dark tip
    a.box("Tail", (-0.3, 5.2, z1), (0.3, 5.8, z1 + 1.6), FUR, "Tail")
    a.box("TailRing1", (-0.38, 5.12, z1 + 0.3), (0.38, 5.88, z1 + 0.55), GOLD, "Tail")
    a.box("Tail2", (-0.32, 3.4, z1 + 1.1), (0.32, 5.2, z1 + 1.7), FUR, "Tail")
    a.box("TailRing2", (-0.4, 4.3, z1 + 1.02), (0.4, 4.55, z1 + 1.78), GOLD, "Tail")
    a.box("TailRing3", (-0.4, 3.85, z1 + 1.02), (0.4, 4.05, z1 + 1.78), LAPIS, "Tail")
    a.box("TailTip", (-0.42, 2.5, z1 + 1.0), (0.42, 3.4, z1 + 1.8), PAW, "Tail")
    a.pivots["Tail"] = (0, 5.8, z1)

    a.meta = {"seat": (0, 6.7, 0.7), "neck_loop": {"center": (0, 7.6, -4.2), "radius": 2.0}}
    a.animations = quad_animations
    return a


CAM = dict(eye=(-19, 12, -21), target=(0, 5.0, -1.2), W=560, H=560, fov=32)
BACK = dict(eye=(-16, 11, 20), target=(0, 5.2, 0.6), W=560, H=560, fov=38)
SIDE = dict(eye=(-28, 6, -1), target=(0, 5.0, -1), W=560, H=560, fov=36)


def main(out=os.path.join(A.ROOT, "designs", "tomb"), shots="/mnt/project-files/world2/tomb/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = jackal()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    shot = render(pose(m, None, 0), transparent=True, **CAM)
    bg = Image.new("RGBA", shot.size, (242, 242, 238, 255))
    Image.alpha_composite(bg, shot).convert("RGB").save(os.path.join(shots, a.name + ".png"))
    horse = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel")))
    tiles = [render(pose(horse, None, 0), **CAM), render(pose(m, None, 0), **CAM),
             render(pose(m, None, 0), **SIDE), render(pose(m, None, 0), **BACK)]
    im = Image.new("RGB", (560 * len(tiles), 560))
    for i, t in enumerate(tiles):
        im.paste(t, (560 * i, 0))
    A.label(im, ["Horse (for size)", f"Tomb Jackal · {a.rarity}", "Side", "Back"]).save(
        os.path.join(shots, a.name + "_sheet.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
