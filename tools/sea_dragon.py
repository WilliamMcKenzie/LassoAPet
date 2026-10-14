"""Abyssal Sea Dragon: World 3 Cnidaria (the reef), GIGA-RARE chase animal (1 in 1000), XXL.

An eastern-style long sea dragon swimming through the deep: a serpentine body of eight
segment bones, deep navy over an indigo back with bright teal flanks and turquoise belly
plates (dark stops between them), a glowing crest of cyan and electric-violet fin spines
down the back, glowing photophores along the flanks, four small webbed clawed limbs
and a big vertical fan tail. At rest the body lies in a gentle S-curve (baked into the
cubes; every bone still rests at 0). The head is fierce but friendly: big googly
eyes under angry brows, swept-back golden antler horns, long golden whiskers with glowing
tips, gill frills, an open jaw full of pyramid teeth and a little spiky beard.

    python3 tools/sea_dragon.py [--gif]

writes designs/cnidaria/AbyssalDragon.bbmodel and previews in
/mnt/project-files/world3/cnidaria/renders/. ZYX, every bone rests at 0, faces -Z.

Bones:
  root (the first body segment: the rider sits here, just behind the head)
    -> neck (the head; the lasso loops round it) -> Jaw, WhiskerL/R, GillL/R
    -> LegFL, LegFR (front paddles)
    -> Seg2 -> Seg3 -> Seg4 (LegBL, LegBR) -> Seg5 -> Seg6 -> Seg7 -> Seg8 -> TailFin

  idle    hovering: a slow sinuous wave down the body, the head looking about, the jaw
          breathing open and shut, whiskers and fins drifting
  walk    swimming: a travelling wave (side to side and some up and down), fins rippling,
          the paddles stroking
  gallop  racing: a fast, wide, rolling wave, head low and forward, jaw wide, fins swept
          back, the tail fan whipping
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from cnidaria_kit import TAU, Build, finish, rot, track  # noqa: E402

NAME = "AbyssalDragon"
COLORS = {
    "navy": (24, 30, 112), "indigo": (62, 40, 176), "royal": (40, 78, 214), "dark": (10, 10, 36),
    "teal": (0, 184, 196), "turq": (44, 236, 214), "tealdark": (0, 108, 138),
    "glowc": (40, 244, 255), "glowv": (176, 60, 255), "fin": (110, 52, 236), "fin2": (60, 120, 255),
    "gold": (255, 206, 60), "golddark": (206, 120, 20), "ivory": (255, 250, 228),
    "mouth": (130, 14, 56), "tongue": (255, 84, 136), "white": (255, 255, 255), "pupil": (16, 10, 30),
}
YC = 6.2  # the body's centre line (it swims clear of the ground; the paddles reach down)
OV = 0.6  # each segment reaches this far forward past its joint, so bending opens no gaps
# (bone, z front, z back, half width, half height): front to tail
SEGS = [("root", 0.0, 5.6, 2.7, 2.6), ("Seg2", 5.6, 10.0, 2.62, 2.5), ("Seg3", 10.0, 14.2, 2.48, 2.36),
        ("Seg4", 14.2, 18.2, 2.3, 2.2), ("Seg5", 18.2, 21.9, 2.06, 1.98), ("Seg6", 21.9, 25.3, 1.78, 1.72),
        ("Seg7", 25.3, 28.4, 1.46, 1.42), ("Seg8", 28.4, 31.2, 1.12, 1.1)]
BODY = [s[0] for s in SEGS[1:]]
I3 = np.eye(3)


def V(*p):
    return np.array(p, float)


def basis(p0, p1, normal):
    """Rotation whose local +Y runs p0 -> p1 and whose local +Z is as close to `normal` as it can be."""
    y = np.array(p1, float) - np.array(p0, float)
    y /= np.linalg.norm(y)
    z = np.array(normal, float)
    z = z - y * (z @ y)
    if np.linalg.norm(z) < 1e-6:
        z = np.cross(y, [1.0, 0, 0])
    z /= np.linalg.norm(z)
    x = np.cross(y, z)
    return np.stack([x, y, z], axis=1)


class Kit:
    """Extra shapes over the cnidaria Build: flat bars and flat blade spikes."""

    def __init__(self, b):
        self.b = b

    def fbar(self, node, name, p0, p1, w, d, color, normal=(1, 0, 0), over=0.0):
        p0, p1 = V(*p0), V(*p1)
        L = np.linalg.norm(p1 - p0) + 2 * over
        return self.b.box(node, name, (p0 + p1) / 2, (w, L, d), color, basis(p0, p1, normal))

    def blade(self, node, name, base, tip, w, d, color, normal=(1, 0, 0)):
        """A pyramid from a w (across) x d (thick, along `normal`) base to `tip`."""
        base, tip = V(*base), V(*tip)
        return self.b.pyramid(node, name, base, w / 2, d / 2, np.linalg.norm(tip - base), color, basis(base, tip, normal))


# ---------------------------------------------------------------- body

def segment(b, k, node, name, z0, z1, hw, hh, idx):
    """An octagonal-ish chunk: navy top over teal flanks, an indigo ridge, turquoise belly
    plates with dark stops, a glowing spine pair, photophores and royal scale plates."""
    zf = z0 - OV
    L = z1 - zf
    zc = (zf + z1) / 2
    y = YC
    # crossed slabs (wide-flat and narrow-tall), split navy above / teal below
    b.box(node, name + "Back", (0, y + 0.33 * hh, zc), (2 * hw, 0.66 * hh, L), "navy")
    b.box(node, name + "Flank", (0, y - 0.33 * hh, zc), (2 * hw, 0.66 * hh, L), "teal")
    b.box(node, name + "Top", (0, y + 0.5 * hh, zc), (1.42 * hw, hh, L - 0.04), "navy")
    b.box(node, name + "Under", (0, y - 0.5 * hh, zc), (1.42 * hw, hh, L - 0.04), "teal")
    # chamfers on the upper edges (45 degree bars), indigo
    for s in (-1, 1):
        b.box(node, name + "Bevel" + "LR"[s > 0], (s * 0.86 * hw, y + 0.68 * hh, zc), (0.42 * hw, 0.42 * hw, L - 0.08),
              "indigo", rot(("z", 45)))
    # ridge down the back
    b.box(node, name + "Ridge", (0, y + hh + 0.14, zc + 0.1), (0.72 * hw, 0.3, L - 0.3), "indigo")
    # belly: dark keel, turquoise plates separated by dark stops
    b.box(node, name + "Keel", (0, y - hh - 0.08, zc), (1.16 * hw, 0.2, L - 0.1), "dark")
    n = 2
    pl = (L - 0.25) / n
    for j in range(n):
        zz = zf + 0.12 + pl * (j + 0.5)
        b.box(node, f"{name}Plate{j + 1}", (0, y - hh - 0.22, zz), (1.3 * hw, 0.36, pl - 0.26), "turq")
    for s in (-1, 1):
        side = "LR"[s > 0]
        # royal scale plates on the upper flank, lightly tilted out
        b.box(node, name + "Scale" + side, (s * (hw + 0.06), y + 0.42 * hh, zc + 0.1),
              (0.3, 0.42 * hh, L * 0.55), "royal", rot(("z", -s * 8)))
        # glowing photophores along the teal flank: alternate cyan / violet down the body
        b.box(node, f"GlowDot{name}{side}", (s * (hw + 0.08), y - 0.36 * hh, zc + 0.2),
              (0.3, 0.75, 0.75), "glowv" if idx % 2 == 0 else "glowc")
    # the glowing dorsal crest: a dark socket and a blade spine, raked back
    if idx > 0:
        H = 1.0 + 2.6 * hh / 2.6 * (1.0 if idx < 7 else 0.8)
        zs = zc - 0.2
        top = y + hh + 0.28
        b.box(node, name + "Socket", (0, top + 0.12, zs), (0.8, 0.5, 1.5), "dark")
        k.blade(node, "Glow" + name + "Spine", (0, top + 0.3, zs), (0, top + 0.3 + H, zs + 0.9 * H * 0.75),
                1.5, 0.55, "glowc" if idx % 2 else "glowv", normal=(1, 0, 0))
        # a little violet membrane at the spine's foot, joining the crest into one fin
        b.box(node, name + "Membrane", (0, top + 0.45, zs + 1.2), (0.3, 0.7, L - 1.2), "fin")


def leg(b, k, parent, name, s, shoulder, scale=1.0):
    """A small paddle limb: navy upper arm, teal forearm, a webbed turquoise hand, three ivory
    claws and a glowing elbow fin."""
    sh = V(*shoulder)
    g = b.group(name, sh, parent)
    elbow = sh + V(s * 1.3, -1.4, -0.9) * scale
    wrist = elbow + V(s * 0.3, -1.9, -0.9) * scale
    b.box(g, name + "Shoulder", sh, (1.6 * scale, 1.6 * scale, 1.8 * scale), "navy")
    b.bar(g, name + "Upper", sh, elbow, 1.1 * scale, "navy", over=0.3)
    b.box(g, name + "Elbow", elbow, (0.95 * scale,) * 3, "indigo")
    b.bar(g, name + "Fore", elbow, wrist, 0.85 * scale, "teal", over=0.25)
    k.blade(g, "Glow" + name + "Fin", elbow + V(0, 0.1, 0.2), elbow + V(s * 0.9, 0.5, 2.0) * scale, 0.9 * scale, 0.25,
            "glowv", normal=(s, 0, 0))
    hand = wrist + V(s * 0.1, -0.35, -0.5) * scale
    b.box(g, name + "Hand", hand, (1.5 * scale, 0.5 * scale, 1.5 * scale), "turq")
    b.box(g, name + "Web", hand + V(0, -0.05, -0.75) * scale, (1.9 * scale, 0.3, 0.9 * scale), "tealdark")
    for j, dx in enumerate((-0.62, 0.0, 0.62)):
        base = hand + V(dx * scale, -0.05, -1.0 * scale)
        b.spike(g, f"{name}Claw{j + 1}", base, base + V(dx * 0.5, -0.7, -0.9) * scale, 0.36 * scale, "ivory")
    return g


# ---------------------------------------------------------------- head

def head(b, k, root):
    y = YC
    h = b.group("neck", (0, y, 0.2), root)
    # skull and snout: navy, teal cheeks below
    b.box(h, "Skull", (0, y + 1.1, -3.0), (5.8, 4.6, 6.6), "navy")
    b.box(h, "Crown", (0, y + 3.55, -2.6), (4.2, 0.4, 5.0), "indigo")
    b.box(h, "Cheeks", (0, y - 0.55, -2.8), (6.2, 1.5, 5.2), "teal")
    b.box(h, "Chin", (0, y - 1.05, -2.6), (4.2, 0.5, 4.6), "turq")
    b.box(h, "Snout", (0, y + 0.2, -8.4), (4.2, 1.7, 4.4), "navy")
    b.box(h, "NoseBulb", (0, y + 0.95, -10.1), (3.4, 1.0, 1.5), "indigo")
    for s in (-1, 1):
        b.box(h, "Nostril" + "LR"[s > 0], (s * 0.8, y + 1.5, -10.4), (0.6, 0.18, 0.6), "dark")
        b.box(h, "LipSide" + "LR"[s > 0], (s * 2.1, y - 0.35, -8.4), (0.3, 0.6, 4.2), "teal")
    b.box(h, "Gums", (0, y - 0.62, -8.35), (3.7, 0.25, 4.3), "mouth")
    b.box(h, "Throat", (0, y - 1.0, -5.2), (3.4, 1.2, 2.2), "mouth")
    # upper teeth: fangs at the front corners, small teeth along the sides
    for s in (-1, 1):
        sd = "LR"[s > 0]
        b.pyramid(h, "Fang" + sd, (s * 1.45, y - 0.72, -10.15), 0.32, 0.32, 1.15, "ivory", rot(("x", 180)))
        b.pyramid(h, "ToothFront" + sd, (s * 0.5, y - 0.72, -10.3), 0.24, 0.24, 0.65, "ivory", rot(("x", 180)))
        for j, z in enumerate((-8.9, -7.5)):
            b.pyramid(h, f"Tooth{sd}{j + 1}", (s * 1.62, y - 0.72, z), 0.25, 0.25, 0.75, "ivory", rot(("x", 180)))
    # eyes: big googly plates on dark sockets, angry brows
    for s in (-1, 1):
        sd = "LR"[s > 0]
        c = V(s * 1.6, y + 2.3, -6.36)
        nrm = V(s * 0.42, 0.12, -1.0)
        nrm /= np.linalg.norm(nrm)
        up = V(0, 1, 0)
        x = np.cross(up, nrm)
        x /= np.linalg.norm(x)
        M = np.stack([x, np.cross(nrm, x), nrm], axis=1)
        b.box(h, "Socket" + sd, c - nrm * 0.12, (2.6, 2.85, 0.3), "dark", M)
        b.eye(h, sd, c + nrm * 0.04, nrm, (2.2, 2.5), look=(-s * 0.35, -0.2))
        b.bar(h, "Brow" + sd, (s * 0.3, y + 3.45, -6.75), (s * 2.95, y + 4.25, -6.1), 0.62, "dark", d=0.7, over=0.15)
        b.bar(h, "BrowRidge" + sd, (s * 0.6, y + 3.4, -6.0), (s * 2.8, y + 3.85, -5.0), 0.8, "indigo", d=1.4)
    # swept-back golden antler horns with a forward tine
    for s in (-1, 1):
        sd = "LR"[s > 0]
        p0 = V(s * 1.3, y + 3.5, -3.9)
        p1 = V(s * 1.95, y + 5.1, -2.6)
        p2 = V(s * 2.9, y + 6.4, -0.9)
        p3 = V(s * 3.7, y + 7.6, 1.2)
        b.box(h, "HornBase" + sd, p0 + V(0, -0.05, 0), (1.3, 0.6, 1.3), "golddark")
        b.bar(h, "Horn" + sd + "1", p0, p1, 0.95, "gold", over=0.25)
        b.box(h, "HornRing" + sd, p1, (1.05, 1.05, 1.05), "golddark", rot(("y", 20 * s), ("z", -25 * s)))
        b.bar(h, "Horn" + sd + "2", p1, p2, 0.82, "gold", over=0.2)
        b.spike(h, "HornTip" + sd, p2, p3, 0.72, "gold")
        mid = (p1 + p2) / 2
        b.spike(h, "HornTine" + sd, mid, mid + V(s * 0.3, 1.6, -1.0), 0.5, "gold")
    # a short glowing mane between the horns, kept low in front of the seat
    for j, (z, H) in enumerate(((-2.4, 1.6), (-0.9, 1.3))):
        b.box(h, f"ManeSocket{j + 1}", (0, y + 3.85, z), (0.8, 0.35, 1.2), "dark")
        k.blade(h, f"GlowMane{j + 1}", (0, y + 3.95, z), (0, y + 3.95 + H, z + 0.9), 1.2, 0.45, "glowv" if j else "glowc")
    # cheek spikes sweeping back
    for s in (-1, 1):
        sd = "LR"[s > 0]
        k.blade(h, "CheekSpike" + sd, (s * 2.7, y - 0.4, -2.2), (s * 4.4, y - 0.1, 0.3), 1.1, 0.4, "turq", normal=(0, 1, 0))
    # whiskers: long golden barbels from the snout, waving on their own bones, glowing tips
    for s in (-1, 1):
        sd = "LR"[s > 0]
        p = V(s * 2.15, y + 0.3, -9.9)
        g = b.group("Whisker" + sd, p, h)
        pts = [p, p + V(s * 2.0, 0.5, 0.4), p + V(s * 3.8, 0.7, 2.1), p + V(s * 5.0, 0.1, 4.3), p + V(s * 5.6, -0.9, 6.5)]
        for j in range(4):
            b.bar(g, f"Whisker{sd}{j + 1}", pts[j], pts[j + 1], 0.5 - 0.06 * j, "gold", over=0.12)
        b.box(g, "GlowWhiskerTip" + sd, pts[-1], (0.55, 0.55, 0.55), "glowc")
        b.box(g, "WhiskerRoot" + sd, p, (0.75, 0.75, 0.75), "golddark")
    # gill frills: three turquoise blades with violet glowing spurs fanning back
    for s in (-1, 1):
        sd = "LR"[s > 0]
        p = V(s * 2.65, y + 0.9, -1.4)
        g = b.group("Gill" + sd, p, h)
        for j, (dy, dz, L) in enumerate(((1.6, 2.0, 3.1), (0.1, 2.6, 3.6), (-1.4, 2.1, 3.0))):
            tip = p + V(s * 2.0, dy, dz) * (L / 3.2)
            k.blade(g, ("GlowGill" if j == 1 else "Gill") + f"{sd}{j + 1}", p, tip, 1.5, 0.35,
                    "glowv" if j == 1 else "turq", normal=(s, 0, 0.3))
        b.box(g, "GillRoot" + sd, p, (0.6, 2.4, 1.2), "fin")
    # the lower jaw, hinged at the back and built a little open; a spiky turquoise beard
    hinge = V(0, y - 1.15, -2.4)
    jaw = b.group("Jaw", hinge, h)
    M = rot(("x", -11))

    def J(p):
        return hinge + M @ (V(*p) - hinge)
    b.box(jaw, "JawBone", J((0, y - 1.85, -6.1)), (3.9, 1.2, 7.4), "teal", M)
    b.box(jaw, "JawBelly", J((0, y - 2.5, -6.0)), (3.1, 0.3, 6.8), "turq", M)
    b.box(jaw, "JawGums", J((0, y - 1.2, -6.4)), (3.4, 0.2, 6.2), "mouth", M)
    b.box(jaw, "Tongue", J((0, y - 1.05, -6.2)), (1.6, 0.25, 4.6), "tongue", M)
    for s in (-1, 1):
        sd = "LR"[s > 0]
        for j, (x, z, H) in enumerate(((0.75, -9.3, 0.85), (1.5, -7.9, 0.7))):
            b.pyramid(jaw, f"ToothLow{sd}{j + 1}", J((s * x, y - 1.15, z)), 0.26, 0.26, H, "ivory", M)
    for j, (x, z) in enumerate(((0, -9.1), (-1.0, -8.0), (1.0, -8.0))):
        base = J((x, y - 2.55, z))
        k.blade(jaw, f"Beard{j + 1}", base, base + V(x * 0.5, -1.9 + 0.3 * (j > 0), 1.3), 0.9, 0.35, "turq",
                normal=(1, 0, 0))
    return h


# ---------------------------------------------------------------- model

def build():
    b = Build(NAME, COLORS)
    k = Kit(b)
    _, z0, z1, hw, hh = SEGS[0]
    root = b.group("root", (0, YC, (z0 + z1) / 2))
    segment(b, k, root, "Seg1", z0, z1, hw, hh, 0)
    # the seat: a dark scale pad on the back, a gold crest lip in front of the rider
    top = YC + hh + 0.28
    b.box(root, "SeatPad", (0, top, 3.0), (2.9, 0.22, 3.6), "royal")
    b.box(root, "SeatCrest", (0, top + 0.3, 0.75), (3.0, 0.75, 0.6), "gold")
    b.box(root, "SeatCrestBack", (0, top + 0.12, 5.1), (2.4, 0.4, 0.5), "golddark")
    head(b, k, root)
    for s in (-1, 1):
        leg(b, k, root, "LegF" + "LR"[s > 0], s, (s * 2.35, YC - 1.3, 2.4))
    parent = root
    for idx, (name, z0, z1, hw, hh) in enumerate(SEGS[1:], start=1):
        node = b.group(name, (0, YC, z0), parent)
        segment(b, k, node, name, z0, z1, hw, hh, idx)
        if name == "Seg4":
            for s in (-1, 1):
                leg(b, k, node, "LegB" + "LR"[s > 0], s, (s * 2.0, YC - 1.2, 16.4), 0.9)
        parent = node
    # the tail: a big vertical fan of violet blades with turquoise ribs and glowing tips
    zt = SEGS[-1][2]
    tf = b.group("TailFin", (0, YC, zt - 0.4), parent)
    b.box(tf, "TailStock", (0, YC, zt + 0.3), (1.6, 1.8, 2.2), "navy")
    b.box(tf, "TailStockBelly", (0, YC - 0.75, zt + 0.3), (1.2, 0.5, 2.0), "turq")
    p = V(0, YC, zt + 0.6)
    for j, a in enumerate((-58, -38, -18, 0, 18, 38, 58)):
        L = 7.6 - 1.4 * abs(a) / 58 + (1.0 if abs(a) == 58 else 0)
        d = V(0, math.sin(math.radians(a)), math.cos(math.radians(a)))
        tip = p + d * L
        col = "fin" if j in (0, 6) else "fin2"
        k.blade(tf, (f"GlowTail{j + 1}" if j % 2 else f"TailRay{j + 1}"), p, tip, 3.0, 0.5,
                ("glowc" if j % 4 == 1 else "glowv") if j % 2 else col, normal=(1, 0, 0))
    b.box(tf, "TailHub", p + V(0, 0, 0.3), (0.9, 1.4, 1.4), "dark")
    m = b.model()
    s_curve(m)
    return m


# ---------------------------------------------------------------- the resting S-curve

CURVE_AMP = 1.9  # studs of side-to-side swing in the resting S (QM-coordinator, Oct 14: was straight)
CURVE_LEN = 26.0  # studs per full side-to-side wave


def curve_x(z):
    z0 = SEGS[1][1]
    return 0.0 if z <= z0 else CURVE_AMP * math.sin(TAU * (z - z0) / CURVE_LEN) * min(1.0, (z - z0) / 4.0)


def euler_m(r):
    """Blockbench ZYX Euler (degrees) -> rotation matrix (Rz Ry Rx)."""
    return rot(("z", r[2]), ("y", r[1]), ("x", r[0]))


def s_curve(m):
    """Bake the gentle resting S into the body: every Seg (with its limbs) is moved rigidly so
    its pivot sits on the end of the one before and it is yawed along the curve. Bones stay
    at 0; the yaw lives in the cubes and the pyramid vertices."""
    from angel_boss import rot_to_zyx
    groups = {g["uuid"]: g for g in m["groups"]}
    elems = {e["uuid"]: e for e in m["elements"]}
    owner, gowner = {}, {}  # element / group uuid -> the body bone that carries it

    def walk(node, seg):
        g = groups[node["uuid"]]
        if g["name"] in BODY or g["name"] == "root":
            seg = g["name"]
        if g["name"] == "TailFin":
            seg = BODY[-1]
        gowner[node["uuid"]] = seg
        for c in node["children"]:
            if isinstance(c, dict):
                walk(c, seg)
            else:
                owner[c] = seg
    for n in m["outliner"]:
        walk(n, "root")
    xf = {"root": (np.eye(3), np.zeros(3))}  # bone -> (R, t) in studs: p' = R p + t
    prev = "root"
    for name, z0, z1, hw, hh in SEGS[1:]:
        R0, t0 = xf[prev]
        P = V(0, YC, z0)
        P2 = R0 @ P + t0  # the pivot rides on the end of the segment before
        zm = P2[2] + (z1 - z0)
        yaw = math.degrees(math.atan2(curve_x(zm) - P2[0], zm - P2[2]))
        R = rot(("y", yaw))
        xf[name] = (R, P2 - R @ P)
        prev = name
    for uid, seg in owner.items():
        R, t = xf[seg]
        if seg == "root":
            continue
        e = elems[uid]
        o = np.array(e["origin"], float) / 10
        o2 = R @ o + t
        if e["type"] == "mesh":
            e["origin"] = [round(float(c) * 10, 4) for c in o2]
            e["vertices"] = {k: [round(float(c), 4) for c in R @ np.array(v, float)] for k, v in e["vertices"].items()}
        else:
            lo, hi = np.array(e["from"], float) / 10, np.array(e["to"], float) / 10
            c = (lo + hi) / 2
            assert np.allclose(c, o, atol=1e-3), e["name"]
            h = (hi - lo) / 2
            e["origin"] = [round(float(v) * 10, 4) for v in o2]
            e["from"] = [round(float(v) * 10, 4) for v in o2 - h]
            e["to"] = [round(float(v) * 10, 4) for v in o2 + h]
            r = rot_to_zyx(R @ euler_m(e["rotation"]))
            e["rotation"] = [0.0 if abs(v) < 1e-3 else v for v in r]
    for uid, seg in gowner.items():
        if seg == "root":
            continue
        R, t = xf[seg]
        g = groups[uid]
        g["origin"] = [round(float(c) * 10, 4) for c in R @ (np.array(g["origin"], float) / 10) + t]


# ---------------------------------------------------------------- animations

def animations():
    def swim(L, amp, vamp, lag, grow, neck_x, look, jaw_open, jaw_amp, fin_amp, fin_sweep, leg_amp, bob, beats=1):
        w = TAU * beats
        tr = {}
        for j, bone in enumerate(BODY):
            a = amp * (1 + grow * j)
            v = vamp * (1 + 0.5 * grow * j)
            tr[bone] = [track(L, lambda u, a=a, v=v, j=j: (
                v * math.sin(w * u - lag * (j + 1) + 1.2), a * math.sin(w * u - lag * (j + 1)), 0), 24)]
        tr["TailFin"] = [track(L, lambda u: (0.6 * vamp * math.sin(w * u - lag * 9 + 1.2),
                                             1.3 * amp * math.sin(w * u - lag * 9), 0), 24)]
        tr["root"] = [track(L, lambda u: (0.4 * vamp * math.sin(w * u + 1.2), -0.45 * amp * math.sin(w * u + 0.5),
                                          -0.25 * amp * math.sin(w * u)), 24),
                      track(L, lambda u: (0, bob * math.sin(w * u + 0.4), 0), 24, "position")]
        tr["neck"] = [track(L, lambda u: (neck_x + 0.5 * vamp * math.sin(w * u - 0.5),
                                          look * math.sin(TAU * u) + 0.4 * amp * math.sin(w * u + 0.5), 0), 24)]
        tr["Jaw"] = [track(L, lambda u: (-jaw_open - jaw_amp * (0.5 + 0.5 * math.sin(w * u)), 0, 0), 16)]
        for s, sd in ((-1, "L"), (1, "R")):
            tr["Whisker" + sd] = [track(L, lambda u, s=s: (
                10 * math.sin(w * u - 1.0), -s * fin_sweep * 0.5 + 12 * math.sin(w * u - 1.6), s * 8 * math.sin(w * u - 0.6)), 24)]
            tr["Gill" + sd] = [track(L, lambda u, s=s: (0, -s * fin_sweep * 0.4 + s * 0.6 * fin_amp * math.sin(w * u), 0), 16)]
            for lg, ph in (("LegF", 0.0), ("LegB", math.pi)):
                tr[lg + sd] = [track(L, lambda u, s=s, ph=ph: (
                    leg_amp * math.sin(w * u + ph + (s > 0) * math.pi * 0.5), 0, s * 0.3 * leg_amp * math.cos(w * u + ph)), 16)]
        return tr

    return {
        "idle": (3.0, swim(3.0, 6, 3, 0.75, 0.12, 6, 14, 6, 8, 12, 0, 12, 4)),
        "walk": (1.4, swim(1.4, 11, 4, 0.85, 0.14, 2, 0, 5, 5, 20, 10, 24, 5)),
        "gallop": (0.7, swim(0.7, 16, 6, 0.85, 0.16, -4, 0, 16, 8, 26, 34, 36, 7)),
    }


if __name__ == "__main__":
    finish(build(), animations(), dict(eye=(-38, 26, -36), target=(0, 6, 10), fov=40),
           sheet_target=(0, 6.2, 12), sheet_dist=0.9)
