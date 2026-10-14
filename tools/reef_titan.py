"""Reef Titan: World 3 Cnidaria (the reef), GIGA RARE (1 in 1000). An ancient colossal sea
turtle carrying a whole living reef on its back. A stepped dome of deep sea-green shell
tiers, each lipped with gold-ochre scute rims over dark stops; on top a garden of staghorn
coral (pink and orange), brain coral domes, lattice fan corals, tube sponges, glowing sea
anemones, a giant clam with a glowing pearl, the ruins of a little sunken temple and a
school of tiny fish circling it all. A mossy stone platform at the front of the shell is the
rider's seat. A wise old head with a hooked beak, googly eyes under bushy white brows,
barnacles and a kelp beard; long front flippers, paddle back flippers, a short tail.

    python3 tools/reef_titan.py [--gif]

writes designs/cnidaria/ReefTitan.bbmodel and previews in
/mnt/project-files/world3/cnidaria/renders/. ZYX, every bone rests at 0. Faces -Z.
Bones: root -> Head -> Beard -> Beard2; root -> FlipperFL/FR -> FlipperFLb/FRb;
root -> FlipperBL/BR; root -> Tail; root -> Anemone1..5 (tentacle crowns); root -> Kelp1..4;
root -> ClamLid; root -> Fish1..3 (circle the reef).

  idle    slow flipper strokes, gentle bob and roll, head looking about
  walk    steady strokes, nosing forward
  gallop  big fast power strokes, nosed down, kelp streaming
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from cnidaria_kit import TAU, Build, finish, rot, track  # noqa: E402

NAME = "ReefTitan"
COLORS = {
    # the turtle
    "shell": (20, 128, 100), "shell2": (12, 96, 78), "shell3": (44, 168, 128), "rim": (226, 164, 34),
    "rim2": (184, 118, 20), "dark": (26, 34, 38), "belly": (240, 206, 104), "belly2": (196, 150, 60),
    "skin": (86, 168, 120), "skin2": (50, 116, 86), "spot": (150, 214, 140), "beak": (246, 186, 58),
    "beak2": (176, 112, 30), "brow": (238, 240, 228), "barn": (226, 220, 204), "barn2": (70, 70, 74),
    "white": (255, 255, 255), "pupil": (20, 22, 30), "mouth": (60, 24, 30),
    # the reef
    "stone": (232, 226, 204), "stone2": (184, 176, 152), "moss": (96, 206, 70), "moss2": (52, 150, 48),
    "pink": (255, 84, 150), "pinktip": (255, 176, 214), "orange": (255, 122, 30), "orangetip": (255, 214, 90),
    "brain": (255, 206, 50), "brain2": (196, 120, 20), "brainp": (178, 92, 236), "brainp2": (106, 44, 168),
    "fan": (214, 52, 220), "fan2": (255, 52, 74), "sponge": (110, 82, 255), "sponge2": (255, 150, 30),
    "hole": (30, 20, 50), "stalk": (255, 120, 170), "glow": (110, 255, 226), "glow2": (255, 120, 236),
    "clam": (70, 116, 236), "clam2": (40, 70, 178), "mantle": (110, 236, 255), "pearl": (255, 250, 236),
    "fishy": (255, 226, 30), "fishb": (40, 170, 255), "fishs": (24, 30, 60), "kelp": (76, 196, 64), "kelp2": (36, 128, 50),
}

# shell tiers: (centre y, height, half-width x, half-length z)
TIERS = ((7.0, 1.6, 10.0, 12.2), (8.5, 1.4, 9.3, 11.3), (9.8, 1.3, 8.1, 9.9), (11.0, 1.2, 6.6, 8.2),
         (12.1, 1.0, 4.8, 6.2))
TOP = TIERS[-1][0] + TIERS[-1][1] / 2  # 12.6
SEAT = (0.0, TOP + 0.85, -3.4)  # top of the mossy platform


def inside(x, z, ax, az, k=0.97):
    return (x / ax) ** 2 + (z / az) ** 2 <= k


def surf(x, z):
    """Top of the shell at (x, z)."""
    h = TIERS[0][0]
    for y, hh, ax, az in TIERS:
        if inside(x, z, ax, az):
            h = y + hh / 2
    return h


def ell(a, ax, az):
    """Point on an ellipse at angle a (0 = back, +Z) and the yaw (deg) that turns local +X along it."""
    p = np.array([ax * math.sin(a), 0, az * math.cos(a)])
    t = np.array([ax * math.cos(a), 0, -az * math.sin(a)])
    return p, math.degrees(math.atan2(-t[2], t[0]))


def build():
    b = Build(NAME, COLORS)
    root = b.group("root", (0, 9, 0))
    shell(b, root)
    head(b, root)
    flippers(b, root)
    reef(b, root)
    return b.model()


# ---------------------------------------------------------------- shell

def shell(b, root):
    # plastron (belly), with dark seams
    b.box(root, "Plastron", (0, 5.5, 0.4), (14.6, 1.4, 20), "belly")
    b.box(root, "Plastron2", (0, 5.5, 0.4), (17.4, 1.0, 15), "belly")
    # stepped dome: crossed slabs per tier
    for k, (y, h, ax, az) in enumerate(TIERS):
        c = ("shell2", "shell", "shell", "shell", "shell3")[k]
        b.box(root, f"Tier{k}a", (0, y, 0), (2 * ax, h, 2 * az * 0.72), c)
        b.box(root, f"Tier{k}b", (0, y, 0), (2 * ax * 0.72, h, 2 * az), c)
        b.box(root, f"Tier{k}c", (0, y, 0), (2 * ax * 0.9, h, 2 * az * 0.9), c)
    # a dark stop line under the rim
    b.box(root, "RimStopA", (0, TIERS[0][0] - 0.75, 0), (2 * 10.6, 0.4, 2 * 12.8 * 0.72), "dark")
    b.box(root, "RimStopB", (0, TIERS[0][0] - 0.75, 0), (2 * 10.6 * 0.72, 0.4, 2 * 12.8), "dark")
    # marginal scutes: a serrated gold rim round the bottom tier, dark stops between
    y0, h0, ax0, az0 = TIERS[0]
    n = 22
    for i in range(n):
        a = TAU * (i + 0.5) / n
        p, yaw = ell(a, ax0 + 0.35, az0 + 0.35)
        if abs(math.sin(a)) < 0.25 and math.cos(a) < 0:
            continue  # the neck comes out here
        b.box(root, f"Marg{i}", p + (0, y0 - 0.1, 0), (2.5, 1.3, 1.1), "rim" if i % 2 else "rim2", rot(("y", yaw)))
    # scute lips round each upper tier
    for k, (y, h, ax, az) in enumerate(TIERS[1:], 1):
        n = (10, 10, 8, 6)[k - 1]
        L = TAU * math.sqrt((ax * ax + az * az) / 2) / n
        for i in range(n):
            a = TAU * (i + 0.5) / n
            p, yaw = ell(a, ax + 0.1, az + 0.1)
            b.box(root, f"Lip{k}_{i}", p + (0, y + h / 2 - 0.15, 0), (L * 0.85, 0.6, 0.8), "rim", rot(("y", yaw)))
    # barnacles on the shell flanks
    rng = np.random.default_rng(7)
    for i in range(6):
        a = TAU * (i + rng.uniform(0, 0.6)) / 6
        k = int(rng.integers(0, 3))
        y, h, ax, az = TIERS[k]
        p, yaw = ell(a, ax + 0.15, az + 0.15)
        barnacle(b, root, f"ShellBarn{i}", p + (0, y + 0.2, 0), 0.8 + 0.3 * rng.uniform(), rot(("y", yaw), ("x", 70)))


def barnacle(b, node, name, c, s, M=None):
    M = np.eye(3) if M is None else M
    c = np.array(c, float)
    b.box(node, name, c, (s, s * 0.8, s), "barn", M)
    b.box(node, name + "Hole", c + M @ np.array([0, s * 0.42, 0]), (s * 0.45, 0.1, s * 0.45), "barn2", M)


# ---------------------------------------------------------------- head

def head(b, root):
    # neck: wrinkly bands
    for i, (z, w, hgt, c) in enumerate(((-11.5, 5.2, 4.0, "skin"), (-12.9, 5.0, 3.8, "skin2"), (-14.2, 4.8, 3.7, "skin"))):
        b.box(root, f"Neck{i}", (0, 7.6 + 0.25 * i, z), (w, hgt, 1.5), c)
    H = b.group("Head", (0, 8.0, -12.5), root)
    hc = np.array([0, 9.6, -17.6])
    b.box(H, "Skull", hc, (5.6, 4.4, 5.6), "skin")
    b.box(H, "SkullTop", hc + (0, 2.5, 0.3), (4.6, 1.0, 4.6), "skin")
    b.box(H, "Cheeks", hc + (0, -0.5, -0.3), (6.2, 2.6, 4.2), "skin")
    b.box(H, "Jowl", hc + (0, -2.3, -0.2), (5.0, 1.2, 5.0), "skin2")
    # three big scale plates on the crown, one cheek spot each side
    for i, (x, z, w) in enumerate(((0, -0.9, 2.4), (-1.4, 1.3, 1.8), (1.4, 1.3, 1.8))):
        b.box(H, f"Scale{i}", hc + (x, 3.05, z), (w, 0.35, w * 0.9), "spot" if i == 0 else "skin2")
    for s in (-1, 1):
        b.box(H, f"Spot{'LR'[s > 0]}", hc + (s * 3.12, -0.4, 1.0), (0.14, 1.0, 1.4), "spot")
    # beak: a hooked upper bill (pyramid tip) over a darker jaw
    b.box(H, "Beak", hc + (0, 0.2, -3.4), (3.6, 2.0, 1.8), "beak")
    b.box(H, "BeakTop", hc + (0, 1.2, -3.0), (2.8, 0.6, 1.6), "beak")
    b.spike(H, "BeakHook", hc + (0, -0.2, -4.0), hc + (0, -1.7, -4.7), 1.8, "beak", d=1.2)
    b.box(H, "Jaw", hc + (0, -1.55, -3.0), (3.2, 1.0, 1.6), "beak2")
    b.box(H, "Mouth", hc + (0, -0.95, -2.95), (3.8, 0.22, 1.5), "mouth")
    # big googly eyes under heavy white brows
    for s in (-1, 1):
        sd = "LR"[s > 0]
        e = hc + (s * 2.25, 1.05, -2.85)
        n = np.array([s * 0.45, 0.05, -0.89])
        b.box(H, f"Socket{sd}", e - n * 0.4, (2.8, 2.8, 1.0), "skin2", rot(("y", -s * 27)))
        b.eye(H, sd, e + n * 0.15, n, 2.6, look=(-s * 0.35, -0.1))
        b.box(H, f"Brow{sd}", e + (s * 0.15, 1.75, 0.15), (3.2, 0.9, 1.8), "brow", rot(("y", -s * 27), ("z", -s * 12)))
    for i, (x, y, z, sz, M) in enumerate(((1.3, 3.2, 1.6, 0.8, None), (-1.7, 2.95, -0.2, 0.65, None),
                                          (3.05, -0.2, 0.2, 0.7, rot(("z", -90))))):
        barnacle(b, H, f"Barn{i}", hc + (x, y, z), sz, M)
    # kelp beard: three strands on their own bone, a lower bone for the ends
    bd = b.group("Beard", hc + (0, -2.6, -2.2), H)
    bd2 = b.group("Beard2", hc + (0, -3.9, -2.0), bd)
    for i, x in enumerate((-1.4, 0, 1.4)):
        c, c2 = ("kelp", "kelp2") if i != 1 else ("kelp2", "kelp")
        top = hc + (x, -2.6, -2.5 + abs(x) * 0.3)
        mid = hc + (x * 1.15, -3.9, -2.1 + abs(x) * 0.3)
        end = hc + (x * 1.6, -5.0 - 0.5 * (i == 1), -1.7)
        b.bar(bd, f"Kelp{i}a", top, mid, 1.2, c, d=0.6)
        b.box(bd, f"KelpLeaf{i}", (top + mid) / 2 + (0.5 * (1 if i != 1 else -1), -0.2, 0), (0.8, 1.2, 0.3), c2,
              rot(("z", 25 if i != 1 else -25)))
        b.bar(bd2, f"Kelp{i}b", mid, end, 0.75, c, d=0.45)


# ---------------------------------------------------------------- flippers and tail

def flippers(b, root):
    for s in (-1, 1):
        sd = "LR"[s > 0]
        # front: long and tapering, swept back
        sh = np.array([s * 7.6, 6.6, -8.2])
        F = b.group(f"FlipperF{sd}", sh, root)
        el = np.array([s * 12.6, 6.4, -7.6])
        b.box(F, f"Shoulder{sd}", sh + (s * 0.6, 0, 0), (3.0, 2.4, 3.0), "skin2")
        b.bar(F, f"Arm{sd}", sh, el, 2.6, "skin", d=1.6, roll=0)
        b.box(F, f"ArmScale{sd}", (sh + el) / 2 + (0, 0.85, -0.3), (3.0, 0.3, 1.4), "spot")
        Fb = b.group(f"FlipperF{sd}b", el, F)
        pts = [el, el + (s * 3.0, -0.2, 0.9), el + (s * 5.8, -0.4, 2.3), el + (s * 8.2, -0.6, 4.0), el + (s * 9.8, -0.7, 5.6)]
        ws = (3.2, 3.0, 2.5, 1.8, 1.0)
        for i in range(4):
            b.bar(Fb, f"Blade{sd}{i}", pts[i], pts[i + 1], ws[i], "skin" if i % 2 == 0 else "skin2", d=1.2 - 0.12 * i, roll=90, over=0.6)
            mid = (pts[i] + pts[i + 1]) / 2
            # leading-edge scales and top patches
            if i % 2 == 0:
                b.box(Fb, f"Patch{sd}{i}", mid + (0, 0.45 - 0.05 * i, 0.2), (ws[i] * 0.55, 0.25, ws[i] * 0.5), "spot", rot(("y", -s * 25)))
        b.spike(Fb, f"Claw{sd}", pts[1] + (0, 0.1, -1.3), pts[1] + (s * 0.3, 0.1, -2.4), 0.7, "beak2")
        # back: a broad paddle
        hp = np.array([s * 6.4, 6.2, 9.4])
        B = b.group(f"FlipperB{sd}", hp, root)
        b.box(B, f"Hip{sd}", hp, (2.6, 2.0, 2.6), "skin2")
        p1, p2 = hp + (s * 2.6, -0.2, 2.0), hp + (s * 4.4, -0.4, 4.4)
        b.bar(B, f"Leg{sd}", hp, p1, 2.2, "skin", d=1.2, roll=90)
        b.bar(B, f"Paddle{sd}", p1, p2, 3.0, "skin", d=0.8, roll=90, over=0.4)
        b.box(B, f"PaddleTip{sd}", p2 + (s * 0.5, 0, 0.6), (2.0, 0.6, 1.6), "skin2", rot(("y", -s * 40)))
        b.box(B, f"PaddleSpot{sd}", (p1 + p2) / 2 + (0, 0.42, 0), (1.4, 0.2, 1.2), "spot", rot(("y", -s * 40)))
    T = b.group("Tail", (0, 6.2, 11.6), root)
    b.box(T, "Tail1", (0, 6.1, 13.0), (2.6, 1.8, 2.8), "skin")
    b.box(T, "Tail2", (0, 5.9, 14.7), (1.6, 1.2, 1.8), "skin2")
    b.spike(T, "TailTip", (0, 5.8, 15.5), (0, 5.5, 17.0), 1.0, "skin2")


# ---------------------------------------------------------------- the reef on top

def reef(b, root):
    seat(b, root)
    temple(b, root, np.array([0.0, TOP, 3.6]))
    for i, (x, z, c, ht, sd) in enumerate(((-5.4, -1.2, "pink", 4.6, 1), (5.8, 3.0, "pink", 4.0, 2), (-3.6, 8.2, "pink", 3.6, 3),
                                           (5.0, -4.2, "orange", 4.2, 4), (-6.8, 4.6, "orange", 4.4, 5))):
        staghorn(b, root, f"Stag{i}", np.array([x, surf(x, z) - 0.3, z]), c, ht, sd)
    for i, (x, z, r, c) in enumerate(((-7.0, -5.2, 1.9, "brain"), (3.0, 8.0, 1.7, "brainp"), (7.8, -0.8, 1.5, "brain"))):
        brain(b, root, f"Brain{i}", np.array([x, surf(x, z) - 0.2, z]), r, c)
    for i, (x, z, yaw, c, s) in enumerate(((7.6, 2.6, 90, "fan", 1.0), (-2.6, -7.6, 15, "fan2", 0.9), (-7.6, 7.4, -50, "fan2", 1.0))):
        fan(b, root, f"Fan{i}", np.array([x, surf(x, z) - 0.2, z]), yaw, c, s)
    for i, (x, z, c) in enumerate(((6.4, -6.6, "sponge"), (-0.8, 9.6, "sponge2"), (-8.6, -1.6, "sponge2"))):
        sponges(b, root, f"Sponge{i}", np.array([x, surf(x, z) - 0.2, z]), c, i)
    for i, (x, z, g) in enumerate(((-3.6, -6.0, "glow"), (3.4, -1.0, "glow2"), (-7.6, 1.6, "glow2"), (8.4, -4.2, "glow"))):
        anemone(b, root, i + 1, np.array([x, surf(x, z) - 0.2, z]), g)
    clam(b, root, np.array([5.0, surf(5.0, 6.8) - 0.2, 6.8]))
    kelp(b, root)
    fish(b, root)


def seat(b, root):
    x, y, z = SEAT
    b.box(root, "SeatSlab", (x, TOP + 0.3, z), (4.8, 0.6, 4.4), "stone")
    b.box(root, "SeatSlab2", (x, TOP + 0.05, z), (5.4, 0.3, 5.0), "stone2")
    b.box(root, "MossSeat", (x, TOP + 0.7, z + 0.1), (4.2, 0.3, 3.8), "moss")
    for i, (dx, dz, w, d) in enumerate(((-2.2, -1.9, 1.4, 1.2), (2.3, 0.9, 1.3, 1.6), (0.6, -2.3, 1.8, 0.9))):
        b.box(root, f"MossDrip{i}", (x + dx, TOP + 0.45, z + dz), (w, 0.55, d), "moss2")
    # a low mossy backrest stone behind the rider
    b.box(root, "SeatBack", (x, TOP + 1.0, z + 2.5), (3.6, 1.4, 0.8), "stone2")
    b.box(root, "SeatBackMoss", (x, TOP + 1.8, z + 2.5), (3.8, 0.3, 1.0), "moss")


def temple(b, root, c):
    b.box(root, "TempleBase", c + (0, 0.3, 0.2), (6.6, 0.6, 5.0), "stone2")
    b.box(root, "TempleStep", c + (0, 0.75, 0.4), (5.6, 0.4, 4.0), "stone")
    b.box(root, "TempleMoss", c + (-1.6, 1.0, -0.7), (1.8, 0.15, 1.4), "moss")
    b.box(root, "TempleMoss2", c + (2.0, 0.6, 1.9), (1.4, 0.2, 1.2), "moss2")
    top = c[1] + 0.95

    def column(name, x, z, h, broken=False):
        b.box(root, name + "Foot", (c[0] + x, top + 0.25, c[2] + z), (1.0, 0.5, 1.0), "stone2")
        b.box(root, name + "Shaft", (c[0] + x, top + 0.5 + h / 2, c[2] + z), (0.8, h, 0.8), "stone")
        if not broken:
            b.box(root, name + "Cap", (c[0] + x, top + 0.7 + h, c[2] + z), (1.1, 0.4, 1.1), "stone2")
        else:
            b.box(root, name + "Break", (c[0] + x + 0.1, top + 0.55 + h, c[2] + z), (0.6, 0.35, 0.5), "stone", rot(("z", 25)))
    # the arch at the back
    column("ColA", -1.7, 1.4, 3.0)
    column("ColB", 1.7, 1.4, 3.0)
    b.box(root, "Lintel", c + (0, top - c[1] + 4.15, 1.4), (4.6, 0.6, 1.2), "stone")
    b.box(root, "Pediment", c + (0, top - c[1] + 4.65, 1.4), (3.4, 0.4, 1.0), "stone2")
    b.box(root, "Pediment2", c + (0, top - c[1] + 5.0, 1.4), (1.8, 0.35, 0.9), "stone")
    b.box(root, "Keystone", c + (0, top - c[1] + 3.7, 0.85), (0.7, 0.8, 0.3), "rim")
    # broken columns at the front corners
    column("ColC", -2.0, -1.2, 1.4, broken=True)
    column("ColD", 2.0, -1.0, 0.8, broken=True)
    # a fallen drum rolled off the steps, and a toppled capital
    b.box(root, "Fallen", c + (2.9, 0.75, -2.4), (0.7, 0.7, 2.0), "stone", rot(("y", 30)))
    b.box(root, "FallenCap", c + (-3.0, 0.4, 1.2), (1.0, 0.4, 1.0), "stone2", rot(("y", 20), ("z", 15)))
    # vines draping the arch
    b.bar(root, "Vine1", c + (-1.95, top - c[1] + 4.3, 0.85), c + (-1.95, top - c[1] + 1.6, 0.85), 0.25, "moss2")
    b.bar(root, "Vine2", c + (0.8, top - c[1] + 4.0, 0.75), c + (1.0, top - c[1] + 3.0, 0.75), 0.25, "moss")
    b.box(root, "VineLeaf", c + (-1.95, top - c[1] + 2.4, 0.7), (0.5, 0.4, 0.2), "moss")
    # a little gold idol in the doorway
    b.box(root, "Idol", c + (0, top - c[1] + 0.5, 1.6), (0.7, 1.0, 0.6), "rim")
    b.box(root, "IdolHead", c + (0, top - c[1] + 1.3, 1.6), (0.55, 0.5, 0.5), "rim2")


def staghorn(b, root, name, base, c, ht, seed):
    """A trunk that forks into three upturned branches, each ending in a pyramid tip."""
    rng = np.random.default_rng(seed)
    tip = c + "tip"
    trunk = base + (rng.uniform(-0.2, 0.2), ht * 0.42, rng.uniform(-0.2, 0.2))
    b.box(root, name + "Foot", base + (0, 0.25, 0), (1.6, 0.6, 1.6), c)
    b.bar(root, name + "Trunk", base, trunk, 1.0, c, over=0.2)
    sp = rng.uniform(0, TAU)
    for j in range(3):
        a = sp + j * TAU / 3 + rng.uniform(-0.3, 0.3)
        out = np.array([math.cos(a), 0, math.sin(a)])
        L = ht * rng.uniform(0.5, 0.65)
        end = trunk + out * L * 0.55 + np.array([0, L * 0.6, 0])
        b.bar(root, f"{name}Br{j}", trunk, end, 0.8, c, over=0.25)
        d = end - trunk
        d /= np.linalg.norm(d)
        b.spike(root, f"{name}Tip{j}", end, end + (d + np.array([0, 0.6, 0])) * 0.55, 0.85, tip)


def brain(b, root, name, base, r, c):
    c2 = c + "2"
    b.box(root, name + "a", base + (0, r * 0.35, 0), (2 * r, r * 0.7, 2 * r * 0.66), c)
    b.box(root, name + "b", base + (0, r * 0.35, 0), (2 * r * 0.66, r * 0.7, 2 * r), c)
    b.box(root, name + "c", base + (0, r * 0.85, 0), (2 * r * 0.78, r * 0.5, 2 * r * 0.78), c)
    b.box(root, name + "d", base + (0, r * 1.15, 0), (2 * r * 0.5, r * 0.3, 2 * r * 0.5), c)
    # two bold grooves across the top
    for i, (z, ang) in enumerate(((-0.35, 12), (0.35, -12))):
        b.box(root, f"{name}Groove{i}", base + (0, r * 1.13, z * r), (r * 1.5, r * 0.36, 0.28 * r), c2, rot(("y", ang)))
    b.box(root, f"{name}Band", base + (0, r * 0.62, 0), (2 * r * 0.82, 0.25 * r, 2 * r * 0.82), c2)


def fan(b, root, name, base, yaw, c, s):
    M = rot(("y", yaw))
    u = M @ np.array([1.0, 0, 0])
    up = np.array([0, 1.0, 0])
    b.box(root, name + "Stem", base + (0, 0.45 * s, 0), (0.8, 1.0 * s, 0.8), c, M)
    p0 = base + up * 0.85 * s
    rays = []
    for k, a in enumerate((-55, -27, 0, 27, 55)):
        d = math.cos(math.radians(a)) * up + math.sin(math.radians(a)) * u
        L = (3.8 - 0.3 * abs(k - 2)) * s
        rays.append((d, L))
        b.bar(root, f"{name}Ray{k}", p0, p0 + d * L, 0.5, c, d=0.5, over=0.15)
    for k in range(4):
        a0 = p0 + rays[k][0] * rays[k][1] * 0.72
        a1 = p0 + rays[k + 1][0] * rays[k + 1][1] * 0.72
        b.bar(root, f"{name}Web{k}", a0, a1, 0.45, c, d=0.45, over=0.12)


def sponges(b, root, name, base, c, seed):
    rng = np.random.default_rng(seed + 20)
    for k, (dx, dz, h, w) in enumerate(((0, 0, 3.4, 1.3), (1.1, 0.6, 2.4, 1.1), (-1.0, 0.7, 1.8, 1.0))):
        tilt = rot(("y", rng.uniform(0, 90)), ("x", rng.uniform(-8, 8)))
        cpos = base + (dx, h / 2, dz)
        b.box(root, f"{name}_{k}", cpos, (w, h, w), c, tilt)
        b.box(root, f"{name}Hole{k}", cpos + tilt @ np.array([0, h / 2 + 0.03, 0]), (w * 0.6, 0.05, w * 0.6), "hole", tilt)


def anemone(b, root, i, base, g):
    b.box(root, f"AnemStalk{i}", base + (0, 0.6, 0), (1.5, 1.2, 1.5), "stalk")
    b.box(root, f"AnemDisc{i}", base + (0, 1.3, 0), (2.3, 0.4, 2.3), "stalk")
    crown = b.group(f"Anemone{i}", base + (0, 1.4, 0), root)
    for k in range(5):
        a = TAU * k / 5 + i
        d = np.array([math.cos(a) * 0.5, 1.0, math.sin(a) * 0.5])
        p = base + (0, 1.4, 0) + np.array([math.cos(a), 0, math.sin(a)]) * 0.65
        e = p + d / np.linalg.norm(d) * 1.5
        b.bar(crown, f"Tent{i}_{k}", p, e, 0.4, "stalk")
        b.box(crown, f"Glow{i}_{k}", e, (0.6, 0.6, 0.6), g)


def clam(b, root, base):
    yaw = -143  # the hinge toward the shell centre, opening out to the back-right where chasers see the pearl
    M = rot(("y", yaw))
    b.box(root, "ClamBase", base + (0, 0.35, 0), (3.6, 0.7, 2.6), "clam2", M)
    b.box(root, "ClamLow", base + (0, 0.9, 0), (4.0, 0.6, 3.0), "clam", M)
    b.box(root, "ClamMantle", base + (0, 1.25, 0), (3.6, 0.2, 2.6), "mantle", M)
    for k in range(3):  # scalloped edge teeth
        b.box(root, f"ClamTooth{k}", base + M @ np.array([-1.3 + 1.3 * k, 1.15, -1.5]), (0.8, 0.5, 0.4), "clam", M)
    b.box(root, "GlowPearl", base + M @ np.array([0, 1.8, -0.3]), (1.1, 1.1, 1.1), "pearl")
    hinge = base + M @ np.array([0, 1.25, 1.4])
    lid = b.group("ClamLid", hinge, root)
    L = M @ rot(("x", 55))
    cen = hinge + L @ np.array([0, 0.3, -1.45])
    b.box(lid, "ClamTop", cen, (4.0, 0.6, 3.0), "clam", L)
    b.box(lid, "ClamTop2", cen + L @ np.array([0, 0.45, 0.2]), (3.2, 0.4, 2.2), "clam2", L)
    b.box(lid, "ClamLidMantle", cen + L @ np.array([0, -0.35, 0]), (3.6, 0.15, 2.6), "mantle", L)
    for k in range(3):
        b.box(lid, f"ClamLidTooth{k}", cen + L @ np.array([-1.3 + 1.3 * k, -0.15, -1.5]), (0.8, 0.5, 0.4), "clam", L)


def kelp(b, root):
    """Four kelp streamers off the back of the shell on their own bones."""
    for i, (x, z) in enumerate(((-4.0, 10.8), (4.0, 10.6), (-7.8, 7.6), (7.8, 7.4))):
        y = surf(x * 0.9, z * 0.9) - 0.3
        p = np.array([x, y, z])
        g = b.group(f"Kelp{i + 1}", p, root)
        d = np.array([x * 0.08, 1.0, 0.35])
        prev = p
        for k in range(3):
            nxt = prev + d / np.linalg.norm(d) * 1.6 + np.array([0.35 * (-1) ** k, 0, 0])
            b.bar(g, f"KelpStrand{i}_{k}", prev, nxt, 0.7, "kelp" if k % 2 == 0 else "kelp2", d=0.4, over=0.1)
            prev = nxt
        b.box(g, f"KelpFloat{i}", prev + (0, 0.3, 0), (0.8, 0.8, 0.8), "moss")


def fish(b, root):
    """Three tiny reef fish circling over the reef, each on a bone turning about the centre."""
    piv = np.array([0, TOP, 2.0])
    for i, (r, h, c, a0) in enumerate(((8.5, 6.0, "fishy", 0.0), (9.5, 7.2, "fishb", 2.1), (7.8, 5.2, "fishy", 4.2))):
        g = b.group(f"Fish{i + 1}", piv, root)
        a = a0
        pos = piv + np.array([r * math.sin(a), h, r * math.cos(a)])
        fwd = np.array([math.cos(a), 0, -math.sin(a)])  # +Y turn moves it this way
        yaw = math.degrees(math.atan2(-fwd[0], -fwd[2]))  # local -Z along fwd
        M = rot(("y", yaw))
        b.box(g, f"Fish{i}Body", pos, (0.9, 1.3, 1.9), c, M)
        b.box(g, f"Fish{i}Stripe", pos + M @ np.array([0, 0, 0.1]), (0.95, 1.35, 0.4), "fishs" if c == "fishy" else "white", M)
        b.box(g, f"Fish{i}Tail", pos + M @ np.array([0, 0, 1.3]), (0.3, 1.3, 0.7), c, M)
        for s in (-1, 1):
            b.eye(g, f"Fish{i}{'LR'[s > 0]}", pos + M @ np.array([s * 0.47, 0.15, -0.5]), M @ np.array([s, 0, -0.3]), 0.5)


# ---------------------------------------------------------------- animations

def animations():
    def swim(L, stroke, sweep, bob, roll, lean, look, beats=1, fast=False):
        w = TAU * beats

        def flip_f(s, u):
            ph = w * u
            down = stroke * (0.25 + 0.75 * math.sin(ph))  # + = flipper tip down; strokes more down than up
            back = sweep * math.sin(ph - 1.2)  # trails the downstroke: sweeps back on the power stroke
            twist = 10 * math.cos(ph)
            return (twist, s * back, s * down)

        tr = {
            "root": [track(L, lambda u: (lean + 2.0 * math.sin(w * u + 0.8), 0, roll * math.sin(TAU * u)), 24),
                     track(L, lambda u: (0, bob * math.sin(w * u + 1.2), 0), 24, "position")],
            "Head": [track(L, lambda u: (4 * math.sin(TAU * u + 0.5) - lean * 0.6, look * math.sin(TAU * u), -roll * 0.6 * math.sin(TAU * u)), 24)],
            "Beard": [track(L, lambda u: (8 + 6 * math.sin(w * u - 0.5) + (12 if fast else 0), 0, 5 * math.sin(TAU * u)), 16)],
            "Beard2": [track(L, lambda u: (8 * math.sin(w * u - 1.4) + (14 if fast else 0), 0, 6 * math.sin(TAU * u - 1)), 16)],
            "Tail": [track(L, lambda u: (4 * math.sin(w * u), 6 * math.sin(TAU * u), 0), 16)],
            "ClamLid": [track(L, lambda u: (-6 + 6 * math.sin(TAU * u), 0, 0), 12)],
        }
        for sd, s in (("L", 1), ("R", -1)):
            tr[f"FlipperF{sd}"] = [track(L, lambda u, s=s: flip_f(s, u), 24)]
            tr[f"FlipperF{sd}b"] = [track(L, lambda u, s=s: (0, s * 0.35 * sweep * math.sin(w * u - 1.8),
                                                              s * 0.45 * stroke * math.sin(w * u - 0.7)), 24)]
            tr[f"FlipperB{sd}"] = [track(L, lambda u, s=s: (0, s * 14 * math.sin(w * u + 2.0), s * 10 * math.sin(w * u + 0.6)), 16)]
        for i in range(1, 5):
            tr[f"Anemone{i}"] = [track(L, lambda u, i=i: (5 * math.sin(TAU * u + i) + (8 if fast else 0), 0, 6 * math.sin(TAU * u + 2 * i)), 12)]
        for i in range(1, 5):
            tr[f"Kelp{i}"] = [track(L, lambda u, i=i: (12 * math.sin(w * u + i) + (30 if fast else 8), 0, 10 * math.sin(TAU * u + i)), 16)]
        for i in range(1, 4):
            turns = (1, 1, 2)[i - 1] if L >= 2 else 1
            tr[f"Fish{i}"] = [track(L, lambda u, t=turns: (0, 360 * t * u, 0), 32, interp="linear"),
                              track(L, lambda u, i=i: (0, 6 * math.sin(TAU * u * 2 + i), 0), 16, "position")]
        return tr

    return {"idle": (4.0, swim(4.0, 22, 18, 5, 3, 0, 18)),
            "walk": (2.0, swim(2.0, 30, 26, 7, 3, -4, 10)),
            "gallop": (1.0, swim(1.0, 40, 34, 10, 4, -10, 4, fast=True))}


if __name__ == "__main__":
    finish(build(), animations(), dict(eye=(-40, 32, -46), target=(0, 9, 0), fov=34), sheet_target=(0, 9, 0))
