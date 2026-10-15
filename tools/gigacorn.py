"""Gigacorn: World 3 Candyland's boss (after RotMG's Candyland Hunting Grounds boss). A huge,
fierce-but-fun candy unicorn that charges through the player during rides, and a Legendary
pet you can ride.

Clean and majestic (QM, Oct 15: "use meshes to enhance gigacorn, overall focus more on making
gigacorn clean and majestic and cooler looking"; was 363 parts of cube clusters, drips,
sprinkles, gumdrops and rosettes). Few, bold shapes:
- a tall, proud stance: a studded white body on long legs, lilac frosting cuffs over
  waffle-cone hooves, a smooth rounded chest and rump (meshes)
- the neck raised high and leaning forward, the head carried proudly, nose a little down
- a long spiralling candy-cane horn (smooth mesh bands, red and white, cut on a slant so the
  stripes wind round it) rising forward from the brow to a glowing pink tip
- a flowing cotton-candy mane, forelock and tail of a few big smooth curved locks (bubblegum,
  sky, lilac; meshes, each a chain of convex hulls sharing rings) sweeping back off the crest
- big googly eyes under determined grape brows, a rounded bubblegum muzzle
- a cherry candy saddle on a sky blanket with a starlight peppermint on each side

Standard quadruped bones (root, neck, EarL, EarR, Tail, Leg*) with quad_animations; every
bone rests at 0 with the tilts baked into the parts (convert WITHOUT --zyx). Meshes are named
Smooth... (smooth-shaded, studless); the converter merges them into one MeshPart per colour per
bone, named by the colour's hex (Gigacorn_<RRGGBB>_<bone>).

    python3 tools/gigacorn.py [--still]
    python3 tools/bbmodel_to_luau.py --meshes assets/meshes/Gigacorn designs/candyland/Gigacorn.bbmodel src/shared/Bosses/GigacornModel.luau
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal, quad_animations, LEGS  # noqa: E402
from partlib import T, Rx, Rz  # noqa: E402

COAT = C.WHITE
LILAC = C.LILAC
LILAC_DK = (162, 104, 236)
GLOW_TIP = (255, 120, 210)
NOSTRIL = (150, 40, 100)
BROW = C.GRAPE_DK

# body box
X, Y0, Y1, Z0, Z1 = 2.3, 4.8, 8.6, -3.9, 4.0


def unit(v):
    v = np.array(v, float)
    return v / np.linalg.norm(v)


def bezier(ctrl, t):
    """A point on the Bezier curve through control points ctrl at t (de Casteljau)."""
    P = [np.array(p, float) for p in ctrl]
    while len(P) > 1:
        P = [p * (1 - t) + q * t for p, q in zip(P, P[1:])]
    return P[0]


def rings_along(path, radii, seg, up=(0, 1.0, 0), flat=1.0):
    """Rings of seg points round each point of path, square to the path, their frames carried
    along the curve (parallel transport) so neighbouring rings line up without twisting. flat
    squashes the ring along the starting up direction (a lock wider than it is thick)."""
    path = [np.array(p, float) for p in path]
    out = []
    t = unit(path[1] - path[0])
    u = np.array(up, float) - t * (np.array(up, float) @ t)
    if np.linalg.norm(u) < 1e-6:
        u = np.cross(t, (1.0, 0, 0))
    u = unit(u)
    for i, c in enumerate(path):
        tn = unit(path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)])
        u = unit(u - tn * (u @ tn))
        v = np.cross(tn, u)
        r = radii[i]
        out.append([c + r * (flat * math.cos(2 * math.pi * k / seg) * u + math.sin(2 * math.pi * k / seg) * v)
                    for k in range(seg)])
    return out


def lock(a, name, ctrl, r0, color, bone, n=7, seg=7, flat=0.75, up=(0, 1.0, 0), shape=None):
    """A cotton-candy lock: a smooth tube along the Bezier curve ctrl, fat near its root and
    tapering to a soft point; one convex hull per segment, sharing rings with its neighbours."""
    ts = np.linspace(0, 1, n + 1)
    path = [bezier(ctrl, t) for t in ts]
    shape = shape or (lambda t: (0.72 + 0.9 * t) * (1 - t) ** 1.1 + 0.07)
    radii = [r0 * shape(t) for t in ts]
    R = rings_along(path, radii, seg, up, flat)
    for i in range(n):
        C.hull(a, name, R[i] + R[i + 1], color, bone)


def on_ellipsoid(c, r, d):
    """The point on the ellipsoid (centre c, radii r) along direction d from its centre, and the
    surface normal there."""
    d, r, c = unit(d), np.array(r, float), np.array(c, float)
    t = 1 / math.sqrt(float(np.sum((d / r) ** 2)))
    return c + d * t, unit(d / r ** 2)


def peppermint(a, name, c, sx, r=0.95):
    """A starlight peppermint on a side face (sx = -1 left, +1 right): a smooth white disc and
    three red pie slices standing a little proud of it."""
    c = np.array(c, float)
    M = np.stack([np.array((0, 0, 1.0)), np.array((sx, 0, 0.0)), np.cross((0, 0, 1.0), (sx, 0, 0.0))], axis=1)
    C.hull(a, "Smooth" + name, C.G.prism(c, r, 0.22, seg=14, M=M), COAT, "root")
    for k in range(3):
        a0 = 2 * math.pi * k / 3 + 0.3
        pts = []
        for x in (0.22, 0.3):
            pts.append(c + (sx * x, 0, 0))
            for j in range(4):
                ang = a0 + (math.pi / 3) * j / 3
                pts.append(c + (sx * x, r * 0.84 * math.sin(ang), r * 0.84 * math.cos(ang)))
        C.hull(a, "Smooth" + name + "Slice", pts, C.CHERRY, "root")


def horn(a, base, d, length, r0, r1, n=9, seg=10, slant=0.55):
    """The candy-cane horn: n smooth bands, red and white, between rings cut on a slant (so the
    stripes wind round it), each ring turned a little on the last; a glowing tip."""
    d = unit(d)
    w = unit(np.cross((1.0, 0, 0), d))  # square to the horn, toward the back
    e1 = unit(np.array((0.7, 0, 0)) + w * 0.7)  # the slant's direction
    e2 = np.cross(d, e1)
    rings = []
    for i in range(n + 1):
        f = i / n
        s = length * f
        r = r0 + (r1 - r0) * f
        k = slant * (1 - f * 0.85)
        ring = []
        for j in range(seg):
            ang = 2 * math.pi * (j + 0.35 * i) / seg
            ring.append(base + d * (s + k * r * math.cos(ang)) + r * (math.cos(ang) * e1 + math.sin(ang) * e2))
        rings.append(ring)
    for i in range(n):
        col = C.CHERRY if i % 2 == 0 else COAT
        C.hull(a, "SmoothHorn", rings[i] + rings[i + 1], col, "neck")
    tip = base + d * (length + 1.3)
    C.hull(a, "GlowHornTip", rings[-1] + [tip], GLOW_TIP, "neck")
    return tip


def gigacorn():
    a = Animal("Gigacorn", "Legendary")
    a.dims = dict(x=X, y0=Y0, y1=Y1, z0=Z0, z1=Z1)
    a.pivots["root"] = (0, (Y0 + Y1) / 2, (Z0 + Z1) / 2)
    N = "neck"

    # ---------------------------------------------------------------- body
    a.box("Body", (-X, Y0, Z0), (X, Y1, Z1), COAT, "root")
    # a smooth deep chest and a rounded rump
    C.hull(a, "SmoothChest", C.G.ellipsoid((0, 6.8, Z0 + 0.05), (2.15, 1.95, 0.85), seg=12, rings=6), COAT, "root")
    C.hull(a, "SmoothRump", C.G.ellipsoid((0, 6.9, Z1 - 0.05), (2.15, 1.85, 0.9), seg=12, rings=6), COAT, "root")
    a.box("Belly", (-1.8, Y0 - 0.2, -2.6), (1.8, Y0, 2.8), LILAC, "root")

    # ---- candy saddle on a sky blanket
    bz0, bz1 = -1.5, 1.7
    a.box("Blanket", (-X - 0.12, 6.9, bz0), (X + 0.12, Y1 + 0.15, bz1), C.SKY, "root")
    a.box("BlanketHem", (-X - 0.2, 6.65, bz0 - 0.1), (X + 0.2, 6.95, bz1 + 0.1), C.SKY_DK, "root")
    a.box("Seat", (-1.55, Y1 + 0.15, -1.0), (1.55, Y1 + 0.6, 1.3), C.CHERRY, "root")
    a.box("Cantle", (-1.55, Y1 + 0.6, 0.85), (1.55, Y1 + 1.25, 1.45), C.CHERRY_DK, "root")
    a.box("Pommel", (-0.55, Y1 + 0.6, -1.0), (0.55, Y1 + 1.35, -0.55), C.CHERRY_DK, "root")
    for sx, side in ((-1, "L"), (1, "R")):
        peppermint(a, "Mint" + side, (sx * (X + 0.12), 7.75 - 0.05, 0.1), sx, 0.85)

    # ---------------------------------------------------------------- legs: tall, frosting cuffs
    for leg in LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        depth = 1.55
        za = Z0 + 0.25 if front else Z1 - 0.25 - depth
        zb = za + depth
        xa, xb = sorted((sx * 0.75, sx * 2.1))
        name = "Leg" + leg
        a.box(name, (xa, 1.9, za), (xb, Y0, zb), COAT, name)
        a.box("Cuff" + leg, (xa - 0.15, 1.2, za - 0.15), (xb + 0.15, 1.95, zb + 0.15), LILAC, name)
        a.box("CuffRim" + leg, (xa - 0.1, 1.05, za - 0.1), (xb + 0.1, 1.2, zb + 0.1), LILAC_DK, name)
        a.box("Hoof" + leg, (xa - 0.05, 0, za - 0.05), (xb + 0.05, 1.05, zb + 0.05), C.PASTRY, name)
        a.box("HoofBand" + leg, (xa - 0.1, 0.4, za - 0.1), (xb + 0.1, 0.58, zb + 0.1), C.PASTRY_DK, name)
        a.pivots[name] = ((xa + xb) / 2, Y0 - 0.025, zb - 0.05 if front else za + 0.05)

    # ---------------------------------------------------------------- neck, raised high
    n0, n1 = np.array((0, 7.6, -2.75)), np.array((0, 13.0, -4.85))
    tilt = math.degrees(math.atan2(n1[2] - n0[2], n1[1] - n0[1]))  # negative: leaning forward
    L = float(np.linalg.norm(n1 - n0))
    C.rbox(a, "Neck", (2.5, L + 0.6, 2.6), T(*((n0 + n1) / 2)) @ Rx(-tilt), COAT, N)

    # ---------------------------------------------------------------- head, carried proudly
    hx, hy0, hy1, hz0, hz1 = 1.5, 12.4, 15.1, -7.3, -3.7
    a.box("Head", (-hx, hy0, hz0), (hx, hy1, hz1), COAT, N)
    a.box("Snout", (-1.25, 12.25, -9.2), (1.25, 14.0, hz0), COAT, N)
    a.wedge("Bridge", (-1.25, 14.0, -9.2), (1.25, hy1, hz0), COAT, N)
    a.box("Jaw", (-1.3, 12.0, -7.0), (1.3, hy0, -4.4), COAT, N)
    mc, mr = np.array((0, 12.95, -9.15)), np.array((1.42, 0.98, 0.8))
    C.hull(a, "SmoothMuzzle", C.G.ellipsoid(mc, mr, seg=12, rings=6), C.BUBBLE, N)
    for sx, side in ((-1, "L"), (1, "R")):
        p, nrm = on_ellipsoid(mc, mr, (sx * 0.5, 0.42, -0.75))
        C.stick(a, "Nostril" + side, p, nrm, (0.42, 0.26, 0.2), NOSTRIL, N, turn=-sx * 20, sink=0.55)
    p, nrm = on_ellipsoid(mc, mr, (0, -0.3, -1.0))
    C.stick(a, "Mouth", p, nrm, (1.0, 0.13, 0.3), C.CHOC_DK, N, sink=0.8)

    # big googly eyes and determined brows
    ey0, ey1, ez0, ez1 = 12.95, 14.85, -7.25, -5.05
    C.sym(a, "Lash*", (hx, ey0 - 0.15, ez0 - 0.15), (hx + 0.06, ey1 + 0.15, ez1 + 0.15), LILAC_DK, N)  # a lilac rim round each eye
    a.eyes(hx + 0.06, ey0, ey1, ez0, ez1)
    for sx, side in ((-1, "L"), (1, "R")):
        C.rbox(a, "Brow" + side, (0.55, 0.42, 2.3), T(sx * 1.55, 15.15, -6.2) @ Rz(sx * 16) @ Rx(-13), BROW, N)

    a.upright_ears(0.95, hy1, -4.75, -4.3, 0.5, 1.7, COAT, C.BUBBLE)
    a.pivots["EarL"] = (-0.95, hy1, -4.75)
    a.pivots["EarR"] = (0.95, hy1, -4.75)

    # ---- the candy-cane horn, rising forward from the brow
    base = np.array((0, hy1 - 0.3, -6.35))
    hd = unit((0, math.cos(math.radians(32)), -math.sin(math.radians(32))))
    C.hull(a, "SmoothHornCollar", C.G.prism(base + hd * 0.05, 0.92, 0.42, seg=12, top=0.82, M=C.G.frame(hd)), C.BUBBLE, N)
    horn(a, base + hd * 0.4, hd, 6.4, 0.62, 0.16)

    # ---- cotton-candy forelock and mane: big smooth locks sweeping back off the crest
    # forelock: from the poll, over the brow beside the horn
    lock(a, "SmoothManeBubble", [(0.35, hy1 + 0.2, -4.7), (1.0, hy1 + 1.5, -5.6), (1.7, hy1 + 0.4, -6.7)], 0.75, C.BUBBLE, N, n=6)
    # the crest of the neck, from the poll down to the withers: (root, colour, side)
    crest0 = np.array((0, hy1 + 0.1, -3.9))
    crest1 = np.array((0, 8.9, -1.3))
    cols = [C.SKY, LILAC, C.BUBBLE]
    mane = [(k / 7, cols[k % 3], 1 if k % 2 else -1) for k in range(8)]
    names = {C.SKY: "SmoothManeSky", LILAC: "SmoothManeLilac", C.BUBBLE: "SmoothManeBubble"}
    for k, (f, col, side) in enumerate(mane):
        root = crest0 + (crest1 - crest0) * f + (side * 0.3, 0, 0)
        big = 1.5 - 0.35 * f
        ctrl = [root,
                root + (side * 0.6, 0.7 - 0.2 * f, 1.1),
                root + (side * 1.6, -1.0, 2.0),
                root + (side * 2.0, -3.2 + 0.8 * f, 1.5)]
        lock(a, names[col], ctrl, big, col, N, n=7, flat=0.6, up=(-side, 0.3, 0))
    a.pivots[N] = (0, 7.6, -3.3)

    # ---------------------------------------------------------------- cotton-candy tail
    t0 = np.array((0, 8.1, Z1 - 0.1))
    a.box("TailRoot", (-0.55, 7.5, Z1 - 0.2), (0.55, 8.5, Z1 + 0.6), COAT, "Tail")
    tails = [(C.BUBBLE, "SmoothTailBubble", 0.0, 1.35, 0.0), (C.SKY, "SmoothTailSky", -1, 1.05, 0.5),
             (LILAC, "SmoothTailLilac", 1, 1.05, 0.5)]
    for col, nm, side, r0, drop in tails:
        ctrl = [t0 + (0, 0.1, 0.3), t0 + (side * 0.6, 2.6 - drop, 2.0), t0 + (side * 1.2, 0.8 - drop, 4.6),
                t0 + (side * 0.9, -3.6 - drop, 4.2)]
        lock(a, nm, ctrl, r0 * 1.25, col, "Tail", n=8, flat=0.65, up=(1.0, 0, 0))
    a.pivots["Tail"] = (0, 8.1, Z1 - 0.1)

    a.meta = {"seat": (0, round(Y1 + 0.6, 2), 0.15), "neck_loop": {"center": (0, 10.4, -3.75), "radius": 2.0}}
    a.animations = quad_animations
    return a


if __name__ == "__main__":
    C.publish(gigacorn(), still="--still" in sys.argv)
