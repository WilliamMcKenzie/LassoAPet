"""Gigacorn: World 3 Candyland's boss (after RotMG's Candyland Hunting Grounds boss). A huge,
fierce-but-fun candy unicorn that charges through the player during rides, and a Legendary
pet you can ride:
- a long spiralling candy-cane horn of turned red and white segments, a glowing tip
- a wild cotton-candy mane, forelock and tail: clusters of bubblegum, sky and lilac cubes
- bubblegum frosting over the rump and sky frosting over the withers, dripping down the
  sides, dusted with sprinkles
- a candy saddle: wafer blanket, bubblegum cushion, a cherry on the pommel, chocolate-bar
  saddle flaps studded with gumdrops and a red licorice girth
- peppermint swirl discs on the shoulders and haunches, a cherry candy heart on the chest
- waffle-cone hooves under lilac frosting cuffs
- big googly eyes under thick chocolate brows, flared nostrils, two sugar fangs, a licorice
  bridle with gumdrop rosettes and a chocolate chanfron the horn rises from

Standard quadruped bones (root, neck, EarL, EarR, Tail, Leg*) with quad_animations; every
bone rests at 0 with the tilts baked into the parts (convert WITHOUT --zyx).

    python3 tools/gigacorn.py [--still]
"""

import math
import os
import random
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal, quad_animations, LEGS  # noqa: E402
from partlib import T, Rx, Ry, Rz  # noqa: E402
from snow_designs import pyramid  # noqa: E402

COAT = C.WHITE
COAT_DK = C.CREAM_DK
LILAC = C.LILAC
LILAC_DK = (162, 104, 236)
FLUFF = [(C.BUBBLE, C.BUBBLE_DK), (C.SKY, C.SKY_DK), (LILAC, LILAC_DK)]
GLOW_TIP = (255, 120, 210)
NOSTRIL = (120, 30, 80)

# body box
X, Y0, Y1, Z0, Z1 = 2.3, 4.0, 8.0, -4.0, 4.4
CAPX = 2.55  # side caps round the flanks out to here


def turned(a, name, c, size, deg, color, bone, tilt=(0, 0)):
    """A box centred at c, turned deg about y (and tilt degrees about x, z)."""
    return C.rbox(a, name, size, T(*c) @ Ry(deg) @ Rx(tilt[0]) @ Rz(tilt[1]), color, bone)


def fluff(a, name, c, s, k, bone, wide=1.0, flat=False):
    """A cotton-candy puff of bold axis-aligned blocks: a big cube, a stepped cap on top,
    bumps out both sides and the back, and a darker block underneath for shading."""
    hi, lo = FLUFF[k % 3]
    nxt = FLUFF[(k + 1) % 3][0]
    c = np.array(c, float)
    h = s / 2
    w = h * wide

    def b(nm, d0, d1, col):
        a.box(name + nm, c + d0, c + d1, col, bone)

    b("", (-w, -h, -h), (w, h, h), hi)
    b("Dk", (-w * 0.8, -h - 0.22 * s, -h * 0.8), (w * 0.8, -h + 0.1, h * 0.8), lo)
    if not flat:
        b("Cap", (-w * 0.62, h - 0.05, -h * 0.62), (w * 0.62, h + 0.26 * s, h * 0.62), hi)
    b("Side", (-w - 0.24 * s, -h * 0.55, -h * 0.5), (w + 0.24 * s, h * 0.45, h * 0.6), nxt)
    b("Back", (-w * 0.55, -h * 0.6, h - 0.05), (w * 0.55, h * 0.5, h + 0.28 * s), hi)


def gumdrop(a, name, base_c, color, dark, axis="+y", w=0.42, bone="root"):
    """A sugared gumdrop: a dark base block and a bright stepped dome with a pyramid cap,
    standing out along axis from base_c."""
    k = "xyz".index(axis[1])
    s = 1 if axis[0] == "+" else -1
    c = np.array(base_c, float)

    def blk(nm, w0, h0, h1, col):
        lo, hi = c.copy(), c.copy()
        for i in range(3):
            if i == k:
                lo[i], hi[i] = sorted((c[i] + s * h0, c[i] + s * h1))
            else:
                lo[i], hi[i] = c[i] - w0 / 2, c[i] + w0 / 2
        a.box(nm, lo, hi, col, bone)
        return lo, hi

    blk(name, w, 0, 0.12, dark)
    lo, hi = blk(name + "Top", w * 0.8, 0.12, 0.3, color)
    blo, bhi = lo.copy(), hi.copy()
    if s > 0:
        blo[k] = bhi[k]
    else:
        bhi[k] = blo[k]
    pyramid(a, name + "Cap", blo, bhi, axis, 0.14, color, bone)


def prism_x(a, name, pts, x0, x1, color, bone):
    """A prism: a (y, z) outline extruded along x from x0 to x1."""
    lo = [(x0, y, z) for y, z in pts]
    hi = [(x1, y, z) for y, z in pts]
    faces = [np.array(lo[::-1]), np.array(hi)]
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        faces.append(np.array([lo[i], lo[j], hi[j], hi[i]]))
    p = C.Part(name, (1, 1, 1), np.eye(4), color, "Poly")
    p.polys = faces
    p.bone = bone
    a.parts.append(p)
    return p


def peppermint(a, name, c, r, sx, bone="root"):
    """A starlight peppermint on a side face (sx = -1 left, +1 right): a roundish white
    disc (four squares turned in 22.5 degree steps) on a darker rim of the same shape, and
    six red pie slices (triangular prisms) out from the centre."""
    c = np.array(c, float)
    x = c[0]
    o = (lambda d: x + sx * d)
    for i, deg in enumerate((0, 22.5, 45, 67.5)):
        s = 1.8 * r
        C.rbox(a, f"{name}Disc{i + 1}", (0.26, s, s), T(*(c + (sx * 0.13, 0, 0))) @ Rx(deg), C.WHITE, bone)
        C.rbox(a, f"{name}Rim{i + 1}", (0.16, s + 0.24, s + 0.24), T(*(c + (sx * 0.08, 0, 0))) @ Rx(deg), C.CHERRY_DK, bone)
    for k in range(6):
        t0, t1 = math.radians(60 * k + 6), math.radians(60 * k + 34)
        pts = [(c[1], c[2]), (c[1] + r * 0.84 * math.sin(t0), c[2] + r * 0.84 * math.cos(t0)),
               (c[1] + r * 0.84 * math.sin(t1), c[2] + r * 0.84 * math.cos(t1))]
        prism_x(a, f"{name}Slice{k + 1}", pts, *sorted((o(0.2), o(0.34))), C.CHERRY, bone)


def drips(a, name, color, dark, side, spans, top, bone="root"):
    """Frosting drips hanging off a slab edge. side: 'L', 'R' (x faces) or 'B' (back, +z).
    spans: [(centre along the face, width, length)]; each drip ends in a darker bulb."""
    for i, (u, w, ln) in enumerate(spans):
        y1, y0 = top, top - ln
        if side in "LR":
            sx = -1 if side == "L" else 1
            xa, xb = sorted((sx * X, sx * (CAPX + 0.17)))
            a.box(f"{name}{i + 1}", (xa, y0, u - w / 2), (xb, y1, u + w / 2), color, bone)
            xa, xb = sorted((sx * X, sx * (CAPX + 0.24)))
            a.box(f"{name}{i + 1}Drop", (xa, y0 - 0.3, u - w / 2 - 0.06), (xb, y0 + 0.12, u + w / 2 + 0.06), dark, bone)
        else:
            a.box(f"{name}{i + 1}", (u - w / 2, y0, Z1), (u + w / 2, y1, Z1 + 0.42), color, bone)
            a.box(f"{name}{i + 1}Drop", (u - w / 2 - 0.06, y0 - 0.3, Z1), (u + w / 2 + 0.06, y0 + 0.12, Z1 + 0.49), dark, bone)


def sprinkles(a, name, x0, x1, z0, z1, y, rng, n, avoid=()):
    cols = [c for c in C.SPRINKLES if c not in avoid]
    for i in range(n):
        p = (rng.uniform(x0, x1), y + 0.07, rng.uniform(z0, z1))
        turned(a, f"{name}{i + 1}", p, (0.18, 0.16, 0.48), 90 * (i % 2), cols[i % len(cols)], "root")


def heart(a, z, cx, ytop, px=0.3):
    rows = [".XX.XX.", "XXXXXXX", "XXXXXXX", ".XXXXX.", "..XXX..", "...X..."]
    for r, row in enumerate(rows):
        y1 = ytop - r * px
        runs, i = [], 0
        while i < len(row):
            if row[i] == "X":
                j = i
                while j < len(row) and row[j] == "X":
                    j += 1
                runs.append((i, j))
                i = j
            else:
                i += 1
        for k, (i0, i1) in enumerate(runs):
            col = C.CHERRY if r < 4 else C.CHERRY_DK
            a.box(f"Heart{r + 1}{'ab'[k]}", (cx + (i0 - 3.5) * px, y1 - px, z - 0.36), (cx + (i1 - 3.5) * px, y1, z), col, "root")
    # a sugar shine on the left lobe and a dark backing around the heart
    a.box("HeartShine", (cx - 2.2 * px, ytop - 1.6 * px, z - 0.44), (cx - 1.4 * px, ytop - 0.6 * px, z - 0.36), C.WHITE, "root")
    a.box("HeartBack", (cx - 3.8 * px, ytop - 4.3 * px, z - 0.16), (cx + 3.8 * px, ytop + 0.2 * px, z), C.STRAWB_DK, "root")
    a.box("HeartBack2", (cx - 1.8 * px, ytop - 6.3 * px, z - 0.16), (cx + 1.8 * px, ytop - 4.3 * px, z), C.STRAWB_DK, "root")


def gigacorn():
    rng = random.Random(7)

    a = Animal("Gigacorn", "Legendary")
    a.dims = dict(x=X, y0=Y0, y1=Y1, z0=Z0, z1=Z1)
    a.pivots["root"] = (0, (Y0 + Y1) / 2, (Z0 + Z1) / 2)

    # ---------------------------------------------------------------- body
    a.box("Body", (-X, Y0, Z0), (X, Y1, Z1), COAT, "root")
    C.sym(a, "Flank*", (X, Y0 + 0.4, Z0 + 0.35), (CAPX, Y1 - 0.4, Z1 - 0.35), COAT, "root")
    a.box("Rump", (-X + 0.4, Y0 + 0.4, Z1), (X - 0.4, Y1 - 0.4, Z1 + 0.25), COAT, "root")
    a.box("Breast", (-X + 0.4, Y0 + 0.4, Z0 - 0.25), (X - 0.4, Y1 - 0.4, Z0), COAT, "root")
    a.box("Belly", (-1.9, Y0 - 0.18, -2.1), (1.9, Y0, 2.5), LILAC, "root")
    a.box("BellyDk", (-1.5, Y0 - 0.3, -1.7), (1.5, Y0 - 0.18, 2.1), LILAC_DK, "root")
    heart(a, Z0 - 0.25, 0.0, 6.35)

    # ---- frosting: bubblegum over the rump, sky over the withers, with drips and sprinkles
    a.box("FrostRump", (-CAPX - 0.1, Y1 - 0.25, 1.75), (CAPX + 0.1, Y1 + 0.35, Z1 + 0.42), C.BUBBLE, "root")
    a.box("FrostRumpTop", (-X + 0.2, Y1 + 0.35, 2.0), (X - 0.2, Y1 + 0.55, Z1 + 0.15), C.BUBBLE, "root")
    a.box("FrostWither", (-CAPX - 0.1, Y1 - 0.25, Z0 - 0.42), (CAPX + 0.1, Y1 + 0.35, -1.55), C.SKY, "root")
    a.box("FrostWitherTop", (-X + 0.2, Y1 + 0.35, Z0 - 0.15), (X - 0.2, Y1 + 0.55, -1.8), C.SKY, "root")
    for side in "LR":
        drips(a, "DripRump" + side, C.BUBBLE, C.BUBBLE_DK, side,
              [(2.05, 0.5, 1.2), (2.75, 0.45, 0.55), (3.5, 0.55, 0.85), (4.15, 0.4, 1.45)], Y1 + 0.35)
        drips(a, "DripWither" + side, C.SKY, C.SKY_DK, side,
              [(-4.0, 0.42, 1.55), (-3.25, 0.5, 0.6), (-2.45, 0.42, 0.9), (-1.85, 0.4, 1.45)], Y1 + 0.35)
    drips(a, "DripBack", C.BUBBLE, C.BUBBLE_DK, "B", [(-1.85, 0.5, 1.4), (-1.15, 0.42, 0.7), (1.15, 0.42, 0.95), (1.85, 0.5, 1.6)], Y1 + 0.35)
    sprinkles(a, "Sprinkle", -1.9, 1.9, 2.15, 4.4, Y1 + 0.55, rng, 5, avoid=(C.BUBBLE,))
    sprinkles(a, "SprinkleW", -1.9, 1.9, -3.9, -2.0, Y1 + 0.55, rng, 3, avoid=(C.SKY,))

    # ---- peppermint swirls on the shoulders and haunches
    for side, sx in (("L", -1), ("R", 1)):
        peppermint(a, "MintS" + side, (sx * CAPX, 5.55, -2.75), 0.95, sx)
        peppermint(a, "MintH" + side, (sx * CAPX, 5.55, 3.15), 0.95, sx)

    # ---- candy saddle: wafer blanket, chocolate-bar flaps, bubblegum seat, cherry pommel
    a.box("Blanket", (-CAPX - 0.05, Y1 - 0.1, -1.6), (CAPX + 0.05, Y1 + 0.2, 1.8), C.PASTRY, "root")
    for i, z in enumerate((-0.8, 0.1, 1.0)):
        a.box(f"BlanketRib{i + 1}", (-CAPX - 0.1, Y1 + 0.2, z - 0.07), (CAPX + 0.1, Y1 + 0.26, z + 0.07), C.PASTRY_DK, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * X, sx * (CAPX + 0.18)))
        a.box("Flap" + side, (xa, 6.15, -1.45), (xb, Y1 + 0.2, 1.65), C.CHOC_DK, "root")
        for r in range(3):
            for col in range(2):
                za = -1.32 + col * 1.5
                ya = 6.28 + r * 0.6
                xa, xb = sorted((sx * (CAPX + 0.1), sx * (CAPX + 0.32)))
                a.box(f"Choc{side}{r + 1}{col + 1}", (xa, ya, za), (xb, ya + 0.48, za + 1.34), C.CHOC, "root")
        for i, z in enumerate((-1.0, -0.15, 0.7, 1.45)):
            gumdrop(a, f"Gum{side}{i + 1}", (sx * (CAPX + 0.18), 6.0, z), [C.LIME, C.ORANGE, C.GRAPE, C.LEMON][i],
                    [C.LIME_DK, C.ORANGE_DK, C.GRAPE_DK, C.LEMON_DK][i], ("-x" if sx < 0 else "+x"), 0.36)
        # red licorice girth down from the flap and under the belly, twisted in two reds
        for k in range(4):
            xa, xb = sorted((sx * X, sx * (CAPX + 0.14)))
            ya = 6.15 - (k + 1) * 0.54
            a.box(f"Girth{side}{k + 1}", (xa, ya, 0.0), (xb, ya + 0.54, 0.5), [C.CHERRY, C.CHERRY_DK][k % 2], "root")
    a.box("GirthBelly", (-X, Y0 - 0.42, 0.0), (X, Y0 - 0.18, 0.5), C.CHERRY, "root")
    a.box("Seat", (-1.4, Y1 + 0.2, -1.05), (1.4, Y1 + 0.7, 1.25), LILAC, "root")
    a.box("SeatDk", (-1.6, Y1 + 0.2, -1.25), (1.6, Y1 + 0.42, 1.45), LILAC_DK, "root")
    a.box("Pommel", (-0.6, Y1 + 0.2, -1.5), (0.6, Y1 + 1.15, -1.0), C.CHERRY, "root")
    a.box("PommelCap", (-0.45, Y1 + 1.15, -1.45), (0.45, Y1 + 1.3, -1.05), C.CHERRY_DK, "root")
    a.box("Cherry", (-0.36, Y1 + 1.3, -1.6), (0.36, Y1 + 1.95, -0.9), C.CHERRY, "root")
    a.box("CherryShine", (-0.28, Y1 + 1.7, -1.66), (-0.1, Y1 + 1.86, -1.6), C.WHITE, "root")
    C.beam(a, "CherryStem", (0, Y1 + 1.9, -1.25), (0.15, Y1 + 2.55, -1.05), 0.12, 0.12, C.LIME_DK, "root")
    C.beam(a, "CherryLeaf", (0.12, Y1 + 2.4, -1.1), (0.55, Y1 + 2.5, -1.05), 0.12, 0.28, C.LIME, "root")
    a.box("Cantle", (-1.4, Y1 + 0.2, 1.25), (1.4, Y1 + 1.15, 1.8), C.CHERRY, "root")
    a.box("CantleTrim", (-1.45, Y1 + 1.15, 1.2), (1.45, Y1 + 1.33, 1.85), C.LEMON, "root")
    for i, x in enumerate((-0.9, 0.0, 0.9)):
        gumdrop(a, f"GumCantle{i + 1}", (x, Y1 + 1.33, 1.52), [C.MINT, C.LEMON, C.ORANGE][i],
                [C.MINT_DK, C.LEMON_DK, C.ORANGE_DK][i], "+y", 0.36)

    # ---------------------------------------------------------------- legs: waffle-cone hooves
    for leg in LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        depth = 1.7
        za = Z0 + 0.001 if front else Z1 - 0.001 - depth
        zb = za + depth
        xa, xb = sorted((sx * 0.7, sx * 2.2))
        name = "Leg" + leg
        a.box(name, (xa, 1.75, za), (xb, Y0, zb), COAT, name)
        a.box("Cuff" + leg, (xa - 0.15, 1.25, za - 0.15), (xb + 0.15, 1.85, zb + 0.15), LILAC, name)
        a.box("CuffTop" + leg, (xa - 0.02, 1.85, za - 0.02), (xb + 0.02, 2.05, zb + 0.02), LILAC, name)
        a.box("CuffDk" + leg, (xa - 0.1, 1.1, za - 0.1), (xb + 0.1, 1.25, zb + 0.1), LILAC_DK, name)
        ha, hb, hc, hd = xa - 0.12, xb + 0.12, za - 0.12, zb + 0.12
        a.box("Hoof" + leg, (ha, 0, hc), (hb, 1.1, hd), C.PASTRY, name)
        for k, y in enumerate((0.33, 0.7)):
            a.box(f"WaffleRing{leg}{k + 1}", (ha - 0.06, y, hc - 0.06), (hb + 0.06, y + 0.09, hd + 0.06), C.PASTRY_DK, name)
        for k in (1, 2):
            x = ha + (hb - ha) * k / 3
            z = hc + (hd - hc) * k / 3
            a.box(f"WaffleX{leg}{k}", (x - 0.045, 0, hc - 0.06), (x + 0.045, 1.1, hd + 0.06), C.PASTRY_DK, name)
            a.box(f"WaffleZ{leg}{k}", (ha - 0.06, 0, z - 0.045), (hb + 0.06, 1.1, z + 0.045), C.PASTRY_DK, name)
        a.pivots[name] = ((xa + xb) / 2, Y0 - 0.025, zb - 0.05 if front else za + 0.05)

    # ---------------------------------------------------------------- neck and head
    N = "neck"
    a.box("Neck", (-1.45, 6.6, -5.2), (1.45, 9.9, -2.6), COAT, N)
    a.box("NeckUp", (-1.35, 9.5, -5.8), (1.35, 11.0, -3.2), COAT, N)
    a.box("Throat", (-1.2, 6.8, -5.45), (1.2, 9.6, -5.2), COAT, N)
    hz0, hz1, hy0, hy1 = -7.6, -3.8, 10.6, 13.3
    a.box("Head", (-1.55, hy0, hz0), (1.55, hy1, hz1), COAT, N)
    a.box("Jaw", (-1.3, 10.25, -7.4), (1.3, hy0, -4.6), COAT, N)
    a.box("Snout", (-1.3, 10.4, -9.4), (1.3, 12.1, hz0), COAT, N)
    a.wedge("Bridge", (-1.3, 12.1, -9.4), (1.3, hy1, hz0), COAT, N)
    a.box("Chin", (-1.05, 10.1, -9.25), (1.05, 10.4, -7.4), COAT_DK, N)
    a.box("Muzzle", (-1.38, 10.35, -9.55), (1.38, 11.5, -8.35), C.BUBBLE, N)
    a.box("MuzzleDk", (-1.25, 10.2, -9.45), (1.25, 10.35, -8.45), C.BUBBLE_DK, N)
    # flared nostrils, a grinning mouth and two sugar fangs
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.3, sx * 0.9))
        a.box("Nostril" + side, (xa, 10.85, -9.6), (xb, 11.25, -9.55), NOSTRIL, N)
        fa, fb = sorted((sx * 0.85, sx * 1.15))
        C.rbox(a, "Flare" + side, (0.3, 0.75, 0.3), T(sx * 1.0, 11.15, -9.5) @ Rz(-sx * 25), C.BUBBLE_DK, N)
        C.rbox(a, "NoseRidge" + side, (0.75, 0.22, 0.25), T(sx * 0.62, 11.38, -9.55) @ Rz(sx * 12), C.BUBBLE_DK, N)
        pyramid(a, "Fang" + side, (sx * 0.7 - 0.2, 10.5, -9.66), (sx * 0.7 + 0.2, 10.5, -9.36), "-y", 0.6, C.WHITE, N)
        ma, mb = sorted((sx * 1.38, sx * 1.44))
        C.rbox(a, "MouthSide" + side, (0.08, 0.13, 1.3), T(sx * 1.41, 10.6, -8.95) @ Rx(-12), C.CHOC_DK, N)
    a.box("Mouth", (-1.1, 10.5, -9.6), (1.1, 10.64, -9.55), C.CHOC_DK, N)

    # big googly eyes under thick, angry chocolate brows
    # googly eyes that wrap the head's front corners: a socket block bulges out of each
    # corner, with a white plate on its side and another on its front (seen head-on)
    ex, ey0, ey1, ez0, ez1 = 2.05, 11.5, 13.1, -8.1, -5.7
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.3, sx * ex))
        a.box("Socket" + side, (xa, ey0 - 0.05, ez0), (xb, ey1 + 0.05, ez1), COAT, N)
        fa, fb = sorted((sx * 1.36, sx * (ex - 0.06)))
        a.box("EyeFront" + side, (fa, ey0 + 0.05, ez0 - C.PLATE), (fb, ey1 - 0.05, ez0), C.EYE_WHITE, N)
        pa, pb = sorted((sx * 1.4, sx * 1.75))
        a.box("PupilFront" + side, (pa, ey0 + 0.2, ez0 - C.PLATE - 0.03), (pb, ey0 + 1.0, ez0 - C.PLATE + C.PUPIL_BACK), C.PUPIL, N)
    a.eyes(ex, ey0 + 0.05, ey1 - 0.05, ez0 + 0.06, ez1 - 0.1)
    for side, sx in (("L", -1), ("R", 1)):
        C.rbox(a, "Brow" + side, (0.85, 0.42, 2.7), T(sx * 1.62, 13.5, -6.85) @ Rz(sx * 14) @ Rx(-14), C.CHOC, N)
        # licorice bridle: noseband, cheek strap, a strap behind the eye, gumdrop rosettes
        a.box("Cheek" + side, tuple(sorted((sx * 1.55, sx * 1.7))) [0:1] + (11.18, -7.62), tuple(sorted((sx * 1.55, sx * 1.7)))[1:2] + (11.45, -4.9), C.CHERRY, N)
        a.box("CheekUp" + side, tuple(sorted((sx * 1.55, sx * 1.7)))[0:1] + (11.18, -5.25), tuple(sorted((sx * 1.55, sx * 1.7)))[1:2] + (hy1, -4.95), C.CHERRY, N)
        gumdrop(a, "Rosette" + side, (sx * 1.7, 11.32, -5.1), C.SKY, C.SKY_DK, ("-x" if sx < 0 else "+x"), 0.5, N)
    a.box("Noseband", (-1.42, 11.18, -8.35), (1.42, 13.02, -7.95), C.CHERRY, N)
    a.box("Crown", (-1.6, hy1, -5.25), (1.6, hy1 + 0.15, -4.95), C.CHERRY, N)

    # chocolate chanfron on the brow, studded with gumdrops; the horn rises from it
    a.box("Chanfron", (-1.25, hy1, -7.75), (1.25, hy1 + 0.3, -5.5), C.CHOC, N)
    a.box("ChanfronDk", (-1.35, hy1 - 0.2, -7.85), (1.35, hy1, -5.4), C.CHOC_DK, N)
    for side, sx in (("L", -1), ("R", 1)):
        gumdrop(a, "GumBrow" + side, (sx * 0.85, hy1 + 0.3, -6.1), C.MINT, C.MINT_DK, "+y", 0.34, N)

    # ---- the candy-cane horn: turned segments, alternating red and white, narrowing
    d = np.array((0, math.cos(math.radians(28)), -math.sin(math.radians(28))))
    base = np.array((0, hy1 + 0.3, -6.75))
    C.rbox(a, "HornCollar", (1.35, 0.4, 1.35), T(*(base + (0, 0.1, 0))) @ Ry(45), C.BUBBLE, N)
    C.rbox(a, "HornCollarDk", (1.15, 0.2, 1.15), T(*(base + (0, -0.05, 0))), C.BUBBLE_DK, N)
    n, seg = 9, 0.62
    p = base.copy()
    for i in range(n):
        w = 1.0 - 0.6 * i / (n - 1)
        q = p + d * seg
        col = C.CHERRY if i % 2 == 0 else C.WHITE
        C.rbox(a, f"Horn{i + 1}", (w, w, seg + 0.03), C.frame(p, q) @ Rz(25 * i), col, N)
        p = q
    tipw = 0.36
    M = np.eye(4)
    M[:3, 0], M[:3, 1], M[:3, 2] = (1, 0, 0), d, np.cross((1, 0, 0), d)
    M[:3, 3] = p - d * 0.02
    C.rpyr(a, "GlowHornTip", M @ Ry(25 * n), tipw, tipw, 1.1, GLOW_TIP, N)

    # ---- ears behind the horn, bubblegum inside
    a.upright_ears(0.95, hy1, -4.6, -4.2, 0.45, 1.75, COAT, C.BUBBLE)

    # ---- cotton-candy forelock and mane down the back of the neck
    fluff(a, "Forelock", (0, hy1 + 0.65, -5.3), 0.9, 0, N, wide=0.75)
    path = [((0, 13.75, -3.7), 1.35), ((0, 12.4, -3.05), 1.55), ((0, 11.0, -2.6), 1.6),
            ((0, 9.6, -2.35), 1.5), ((0, 8.55, -2.6), 1.15)]
    for i, (c, s) in enumerate(path):
        fluff(a, f"Mane{i + 1}", c, s, i + 1, N, wide=1.25)
    a.pivots[N] = (0, 7.0, -3.9)
    a.pivots["EarL"] = (-0.95, hy1, -4.6)
    a.pivots["EarR"] = (0.95, hy1, -4.6)

    # ---------------------------------------------------------------- cotton-candy tail
    a.box("TailRoot", (-0.45, 6.6, Z1 + 0.2), (0.45, 7.6, Z1 + 0.9), COAT, "Tail")
    tail = [((0, 7.1, 5.35), 1.15), ((0, 6.1, 6.0), 1.4), ((0, 4.85, 6.4), 1.5), ((0, 3.65, 6.45), 1.3)]
    for i, (c, s) in enumerate(tail):
        fluff(a, f"Tail{i + 1}" if i else "Tail", c, s, i, "Tail", wide=1.1)
    a.pivots["Tail"] = (0, 7.6, Z1 + 0.2)

    a.meta = {"seat": (0, round(Y1 + 0.7, 2), 0.1), "neck_loop": {"center": (0, 9.8, -4.0), "radius": 2.2}}
    a.animations = quad_animations
    return a


if __name__ == "__main__":
    C.publish(gigacorn(), still="--still" in sys.argv)
