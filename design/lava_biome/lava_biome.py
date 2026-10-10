"""QM (Oct 10): a lava / volcano biome that stays bright: warm browns (more brown than
black), orange lava, the standard rock meshes, and lava cracks in the floor the way
ViewportStencil (github.com/sebasvcx/ViewportStencil) draws them: a hole that opens
into glowing geometry under the floor, no floor cut.

Here the stencil is faked the same way it works in game: the floor is rendered with
each crack's opening as a key colour, the crack insides are rendered on their own, and
the key pixels take the insides. Run: python3 design/lava_biome/lava_biome.py"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
import partlib  # noqa: E402
from partlib import Part, T  # noqa: E402
import rock_meshes as RM  # noqa: E402

OUT = "/mnt/project-files/design/lava_biome"

# ---- palette (all warm browns; nothing near black)
BASE = [(156, 98, 66), (168, 108, 74)]       # the floor: baked-earth brown checker
ASH = [(184, 124, 84), (196, 134, 92)]       # flush lighter patches
CRUST = [(124, 78, 58), (136, 86, 64)]       # raised rock plates, +1
LAVA = [(255, 116, 24), (255, 146, 40)]      # lava pools, sunk 1, Neon
WALL = [(170, 92, 58), (186, 104, 66)]
ROCK = (112, 78, 66)                         # the rock meshes, with per-piece shades
ROCK_SHADES = [(126, 88, 74), (112, 76, 64), (142, 100, 84), (118, 82, 70), (134, 92, 76)]
# the crack's inside, top to bottom: scorched rim, deep orange, hot yellow (Neon)
CRACK = [((186, 70, 32), 0.0), ((255, 112, 20), 0.12), ((255, 168, 36), 0.45), ((255, 226, 110), 0.8)]
KEY = (254, 0, 254)  # the stencil key (Neon faces are drawn at their colour)
SKY = np.array([89, 217, 253.0])  # Config.Sky "Flat"

HALF_W = 56
Z0, LENGTH = 0, 220


def noise(seed, cell):
    rng = np.random.default_rng(seed)
    g = rng.random((80, 40))

    def at(x, z):
        u, v = (x + 200) / cell, (-z) / cell
        i, j = int(u), int(v)
        fu, fv = u - i, v - j
        fu, fv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)
        a, b, c, d = g[j % 80, i % 40], g[j % 80, (i + 1) % 40], g[(j + 1) % 80, i % 40], g[(j + 1) % 80, (i + 1) % 40]
        return (a * (1 - fu) + b * fu) * (1 - fv) + (c * (1 - fu) + d * fu) * fv
    return at


N_ASH, N_CRUST, N_LAVA = noise(3, 26), noise(7, 22), noise(11, 18)


def kind(x, z, cracks):
    for cx, cz, s in cracks:  # the floor round a crack stays plain
        if math.hypot(x - cx, z - cz) < s * 1.9:
            return "base"
    edge = abs(x) > HALF_W - 22  # pools and plates keep to the sides; the middle stays plain-ish
    if edge and N_LAVA(x, z) > 0.72:
        return "lava"
    if N_CRUST(x, z) > (0.62 if edge else 0.8):
        return "crust"
    if N_ASH(x, z) > 0.6:
        return "ash"
    return "base"


def floor_parts(cracks, z_hi, z_lo):
    parts = []
    for zi in range(int((z_hi - z_lo) // 4)):
        for xi in range(HALF_W // 2):
            x, z = -HALF_W + xi * 4 + 2, z_hi - zi * 4 - 2
            # patches snap to 8-stud cells like the other biomes
            k = kind(math.floor(x / 8) * 8 + 4, math.floor(z / 8) * 8 + 4, cracks)
            top = {"base": 0, "ash": 0, "crust": 1, "lava": -1}[k]
            col = {"base": BASE, "ash": ASH, "crust": CRUST, "lava": LAVA}[k][(xi + zi) % 2]
            p = Part("Floor", (4, top + 2, 4), T(x, (top - 2) / 2, z), col, plain=(k == "lava"))
            if k == "lava":
                p.neon = True
                p.color = tuple(c / 1.2 for c in col)
            parts.append(p)
    for side in (-1, 1):
        for zi in range(int((z_hi - z_lo) // 4)):
            for yi in range(4):
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, z_hi - zi * 4 - 2),
                                  WALL[(zi + yi) % 2], plain=True))
    return parts


# ---- cracks
def crack_shape(cx, cz, size, rng):
    """A crack as a centre blob plus jagged tapering branches: (blob ring, segments)."""
    r0 = size * 0.4
    ring = []
    nb = 9
    for i in range(nb):
        a = 2 * math.pi * i / nb + rng.uniform(-0.15, 0.15)
        r = r0 * rng.uniform(0.7, 1.15)
        ring.append((cx + r * math.cos(a), cz + r * math.sin(a)))
    segs = []

    def branch(x, z, ang, w, steps, depth):
        for _ in range(steps):
            ang += rng.uniform(-0.6, 0.6)
            ln = size * rng.uniform(0.28, 0.45)
            nx, nz = x + ln * math.cos(ang), z + ln * math.sin(ang)
            w2 = max(w * rng.uniform(0.45, 0.65), 0.12)
            segs.append(((x, z), (nx, nz), w, w2))
            if depth < 1 and rng.random() < 0.45:
                branch(nx, nz, ang + rng.choice([-1, 1]) * rng.uniform(0.7, 1.2), w2 * 0.8, 2, depth + 1)
            x, z, w = nx, nz, w2

    nbr = int(rng.integers(4, 7))
    for i in range(nbr):
        a = 2 * math.pi * i / nbr + rng.uniform(-0.4, 0.4)
        sx, sz = cx + r0 * 0.7 * math.cos(a), cz + r0 * 0.7 * math.sin(a)
        branch(sx, sz, a, size * rng.uniform(0.2, 0.27), int(rng.integers(2, 4)), 0)
    return ring, segs


def face(pts, color, neon, toward):
    """One flat face as its own Poly part, wound to face the point `toward`."""
    pts = [np.array(p, float) for p in pts]
    n = np.cross(pts[1] - pts[0], pts[2] - pts[0])
    if np.dot(n, np.array(toward, float) - np.mean(pts, 0)) < 0:
        pts = pts[::-1]
    p = Part("Crack", (1, 1, 1), np.eye(4), tuple(c / 1.2 for c in color) if neon else color, shape="Poly", plain=True)
    p.polys = [np.array(pts)]
    p.neon = neon
    return p


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def banded(top_a, top_b, bot_a, bot_b, toward):
    """A wall from a top edge down to a bottom edge, in the crack's glow bands."""
    out = []
    stops = [t for _, t in CRACK] + [1.0]
    for (col, t0), t1 in zip(CRACK, stops[1:]):
        out.append(face([lerp(top_a, bot_a, t0), lerp(top_b, bot_b, t0), lerp(top_b, bot_b, t1), lerp(top_a, bot_a, t1)],
                        col, t0 > 0, toward))
    return out


def crack_parts(cx, cz, size, seed):
    rng = np.random.default_rng(seed)
    ring, segs = crack_shape(cx, cz, size, rng)
    mask, inside = [], []
    Y = 0.04
    dmax = size * 0.55
    # blob: a cone down to its deepest point
    bottom = (cx, -dmax, cz)
    above = (cx, 3 * dmax, cz)
    mask.append(face([(x, Y, z) for x, z in ring], KEY, True, (cx, 10, cz)))
    for i in range(len(ring)):
        (x0, z0), (x1, z1) = ring[i], ring[(i + 1) % len(ring)]
        inside += banded((x0, 0, z0), (x1, 0, z1), bottom, bottom, above)
    for (x0, z0), (x1, z1), w0, w1 in segs:
        dx, dz = x1 - x0, z1 - z0
        ln = math.hypot(dx, dz)
        nx, nz = -dz / ln, dx / ln
        d0, d1 = dmax * min(1, w0 / (size * 0.2)) * 0.9, dmax * min(1, w1 / (size * 0.2)) * 0.9
        L0, L1 = (x0 + nx * w0, z0 + nz * w0), (x1 + nx * w1, z1 + nz * w1)
        R0, R1 = (x0 - nx * w0, z0 - nz * w0), (x1 - nx * w1, z1 - nz * w1)
        mask.append(face([(L0[0], Y, L0[1]), (L1[0], Y, L1[1]), (R1[0], Y, R1[1]), (R0[0], Y, R0[1])], KEY, True, (x0, 10, z0)))
        # a joint so bends don't leave gaps
        mask.append(face([(x0 + w0, Y, z0), (x0, Y, z0 + w0), (x0 - w0, Y, z0), (x0, Y, z0 - w0)], KEY, True, (x0, 10, z0)))
        b0, b1 = (x0, -d0, z0), (x1, -d1, z1)
        up = ((x0 + x1) / 2, 3 * dmax, (z0 + z1) / 2)
        inside += banded((L0[0], 0, L0[1]), (L1[0], 0, L1[1]), b0, b1, up)
        inside += banded((R0[0], 0, R0[1]), (R1[0], 0, R1[1]), b0, b1, up)
        # end caps (the walls at each end of a segment, so ends don't show through)
        for (px, pz), w, d, sgn in (((x0, z0), w0, d0, 1), ((x1, z1), w1, d1, -1)):
            inside += banded((px + nx * w, 0, pz + nz * w), (px - nx * w, 0, pz - nz * w), (px, -d, pz), (px, -d, pz),
                             (px + sgn * dx / ln * 3, 3 * dmax, pz + sgn * dz / ln * 3))
    return mask, inside


# ---- rocks
BUILD = {n[4:]: (f, s) for n, f, s, _ in RM.ROCKS}


def rock(name, x, z, yaw, scale):
    chunks = RM.build(*BUILD[name])
    out = []
    for i, ch in enumerate(chunks):
        ch = [[v * scale for v in t] for t in ch]
        out += RM.as_parts([ch], x, z, yaw=yaw, color=ROCK_SHADES[i % len(ROCK_SHADES)])
    return out


def scene(z_hi, z_lo, cracks, rocks):
    parts = floor_parts(cracks, z_hi, z_lo)
    for r in rocks:
        parts += rock(*r)
    mask, inside = [], []
    for i, (cx, cz, s) in enumerate(cracks):
        m, ins = crack_parts(cx, cz, s, 100 + i)
        mask += m
        inside += ins
    return parts, mask, inside


def shot(parts, mask, inside, eye, target, W, H, fov):
    partlib.SKY_TOP = partlib.SKY_BOT = SKY
    a = np.array(partlib.render(parts + mask, eye=eye, target=target, W=W, H=H, fov=fov, fog=False, outline=False,
                                ground=False))
    b = np.array(partlib.render(inside, eye=eye, target=target, W=W, H=H, fov=fov, fog=False, outline=False,
                                ground=False, studs=False))
    key = (a[..., 0] >= 250) & (a[..., 1] <= 4) & (a[..., 2] >= 250)
    hole = (np.abs(b.astype(int) - SKY.astype(int)).sum(-1) < 6)  # (seams inside a crack: the hot bottom)
    b[hole] = CRACK[-1][0]
    a[key] = b[key]
    return Image.fromarray(a)


CRACKS = [(-6, -40, 13), (22, -96, 10), (-24, -128, 9), (8, -170, 12), (-14, -205, 8)]
ROCKS = [("Boulder", -44, -22, 30, 2.2), ("Pebble", -38, -34, 0, 2.8), ("Crag", 44, -60, 200, 1.7),
         ("Stone", 38, -48, 90, 2.4), ("Slab", -46, -88, 140, 1.9), ("Boulder", 46, -132, 260, 2.2),
         ("Pebble", 40, -142, 30, 2.8), ("Crag", -44, -160, 60, 1.7), ("Stone", -36, -172, 10, 2.4),
         ("Boulder", 44, -196, 120, 2.2), ("Slab", -46, -214, 300, 1.9)]

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    parts, mask, inside = scene(10, -230, CRACKS, ROCKS)
    ride = shot(parts, mask, inside, eye=(0, 72, 36), target=(0, 0, -60), W=1400, H=900, fov=52)
    ride.save(os.path.join(OUT, "lava_ride.png"))
    print("ride")
    close = shot(parts, mask, inside, eye=(10, 20, -2), target=(-6, -2, -42), W=1400, H=900, fov=48)
    close.save(os.path.join(OUT, "lava_crack_close.png"))
    print("close")
    sheet = Image.new("RGB", (1400, 1800 + 40), (255, 255, 255))
    sheet.paste(ride, (0, 0))
    sheet.paste(close, (0, 940))
    d = ImageDraw.Draw(sheet)
    d.text((16, 904), "Lava biome: ride view (top), close-up of a crack (bottom)",
           font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26), fill=(20, 20, 20))
    sheet.save(os.path.join(OUT, "lava_biome.png"))
    print("wrote", OUT)
