"""Giant meadow rocks for the base walls (QM, Oct 9): same tilted-chunk style as the
meadow Stone/Boulder (grey body, lit cap, dark chunk), scaled up to wall size.
Run from anywhere: python3 big_rocks.py [--lineup] [--base]"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, HERE)
import partlib  # noqa: E402
from partlib import Part, T, Ry, render  # noqa: E402
import terrain_assets as TA  # noqa: E402
from terrain_assets import GREY, GREY_D, GREY_L, rot  # noqa: E402

MOSS, MOSS_L = (70, 168, 58), (98, 200, 74)  # the Bush's greens


def chunk(k, name, c, size, r, color=GREY, cap=True, moss=False):
    """A tilted block with a lit (or mossy) cap slab on top, like the Boulder."""
    k.at(name, c, size, color, r)
    if cap or moss:
        top = np.array(c, float) + (r[:3, :3] @ np.array([0, size[1] / 2 + 0.4, 0]))
        k.at(name, tuple(top), (size[0] - 1.6, 0.8, size[2] - 1.6), MOSS_L if moss else GREY_L, r)


def bush_at(k, x, y, z, s=1.0):
    sub = TA.Kit()
    TA.bush(sub)
    for q in sub.parts:
        cf = q.cf.copy()
        cf[:3, 3] = cf[:3, 3] * s + np.array([x, y, z])
        k.parts.append(Part(q.name, q.size * s, cf, q.color))


# Local frame for all three: the wall's face is the z = 0 plane and the rock sits in
# +z. The corner crag also backs onto a second wall, the x = 0 plane, sitting in +x.

def corner_crag(k):
    """Fills a corner: a tall mossy-topped block in the corner, stepping down to
    smaller chunks along both walls. About 40 x 40, 30 high."""
    chunk(k, "Crag", (11, 14, 11), (22, 28, 22), rot(12, 3, -4), moss=True)
    chunk(k, "Crag", (27, 9, 8), (15, 18, 14), rot(-14, 0, 7))
    chunk(k, "Crag", (8, 9.5, 27), (14, 19, 15), rot(22, -6, 0))
    chunk(k, "Crag", (22, 4.5, 22), (12, 9, 12), rot(38, 5, 5), GREY_D)
    chunk(k, "Crag", (37, 2.2, 5), (6, 4.4, 6), rot(25, 0, 10), GREY_D, cap=False)
    chunk(k, "Crag", (5, 2.2, 37), (6, 4.4, 6), rot(-30, 8, 0), cap=False)
    chunk(k, "Crag", (30, 1.6, 30), (4, 3.2, 4), rot(10, 0, 0))
    bush_at(k, 11, 29.0, 11, 1.2)  # a bush up on the mossy top
    bush_at(k, 33, 0, 16, 0.9)
    bush_at(k, 16, 0, 34, 0.9)


def wall_shelf(k):
    """A long low run of rock along a wall: three big chunks leaning on it. 40 x 15, 20 high."""
    chunk(k, "Shelf", (-13, 7, 6.5), (16, 14, 13), rot(8, -4, 6))
    chunk(k, "Shelf", (3, 10, 7), (18, 20, 14), rot(-6, -3, -4), moss=True)
    chunk(k, "Shelf", (17, 5.5, 7.5), (12, 11, 12), rot(20, 0, 8), GREY_D)
    chunk(k, "Shelf", (-23, 2, 9), (5, 4, 5), rot(30, 0, 0), cap=False)
    chunk(k, "Shelf", (9, 1.8, 16), (4, 3.6, 4), rot(-20, 0, 0))
    bush_at(k, -4, 0, 14.5, 0.9)


def tor(k):
    """A tall stack of three chunks against a wall, with a bush on top. 18 across, 32 high."""
    chunk(k, "Tor", (0, 6.5, 8), (17, 13, 15), rot(10, -3, 4), GREY_D)
    chunk(k, "Tor", (1, 17, 7.5), (13, 9, 12), rot(-12, 2, -6))
    chunk(k, "Tor", (-0.5, 25, 7), (9, 7, 9), rot(18, 0, 5), moss=True)
    bush_at(k, -0.5, 29.2, 7, 0.8)
    chunk(k, "Tor", (10, 2, 15), (5, 4, 5), rot(20, 0, 0), cap=False)


ASSETS = {"CornerCrag": (corner_crag, 42), "WallShelf": (wall_shelf, 50), "Tor": (tor, 22)}


RED, RED_D, YELLOW, STEM = (232, 52, 52), (196, 32, 40), (255, 214, 64), (60, 150, 50)


def flower_one(k, x, z, h):
    """One blocky red flower: a stem, two leaves, a plus of red petals round a yellow middle."""
    k.box("Flower", (x - 0.2, 0, z - 0.2), (x + 0.2, h, z + 0.2), STEM)
    k.box("Flower", (x - 0.7, h * 0.4, z - 0.15), (x - 0.2, h * 0.4 + 0.3, z + 0.15), MOSS_L)
    k.box("Flower", (x + 0.2, h * 0.6, z - 0.15), (x + 0.7, h * 0.6 + 0.3, z + 0.15), MOSS_L)
    k.box("Flower", (x - 1.0, h, z - 0.35), (x + 1.0, h + 0.5, z + 0.35), RED)
    k.box("Flower", (x - 0.35, h, z - 1.0), (x + 0.35, h + 0.5, z + 1.0), RED)
    k.box("Flower", (x - 0.7, h + 0.05, z - 0.7), (x + 0.7, h + 0.45, z + 0.7), RED_D)
    k.box("Flower", (x - 0.3, h + 0.5, z - 0.3), (x + 0.3, h + 0.8, z + 0.3), YELLOW)


def flowers(k):
    """A small patch of five red flowers at a few heights, about 6 across."""
    for x, z, h in ((0, 0, 2.2), (2.2, 1.0, 1.6), (-1.8, 1.4, 1.8), (0.8, -2.2, 1.4), (-2.4, -1.4, 1.2)):
        flower_one(k, x, z, h)


ASSETS["RedFlowers"] = (flowers, 7)


def wall_block(k, x0, x1, z0, z1, h=48):
    for x in np.arange(x0, x1, 4):
        for z in np.arange(z0, z1, 4):
            for y in range(h // 4):
                c = TA_WALL[(int(x // 4) + int(z // 4) + y) % 2]
                k.parts.append(Part("Wall", (4, 4, 4), T(x + 2, y * 4 + 2, z + 2), c, plain=True))


TA_WALL = [(225, 150, 104), (248, 170, 114)]


def place(builder, x, z, yaw):
    k = TA.Kit()
    builder(k)
    M = T(x, 0, z) @ Ry(yaw)
    return [Part(q.name, q.size, M @ q.cf, q.color) for q in k.parts]


def lineup():
    """Each rock against a stretch of wall, a figure for scale; camera out in the yard."""
    k = TA.Kit()
    parts = []
    # corner crag: corner at (-70, 0); walls along z = 0 (behind) and x = -70 (left)
    parts += place(corner_crag, -70, 0, 0)  # local +x -> world +x, +z -> +z
    parts += place(wall_shelf, 10, 0, 0)
    parts += place(tor, 62, 0, 0)
    for fx, fz in ((-36, 40), (-50, 46), (20, 22), (-6, 20), (72, 24)):
        parts += place(flowers, fx, fz, fx * 7)
    wall_block(k, -74, 80, -4, 0, 48)
    wall_block(k, -74, -70, 0, 50, 48)
    for x in (-38, -8, 30, 50):
        TA.figure(TA.Shifted(k, x) if hasattr(TA, "Shifted") else k)
    for p in k.parts:
        if p.name in ("Leg", "Torso", "Arm", "Head"):
            p.cf = T(0, 0, 24) @ p.cf
    parts += k.parts
    partlib.GROUND = np.array((105, 255, 74), float)
    partlib.GROUND2 = np.array((77, 196, 63), float)
    img = render(parts, eye=(-10, 70, 150), target=(0, 10, 10), W=1500, H=760, fov=42, fog=False, outline=False)
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 30)
    for text, x in (("Corner crag", 250), ("Wall shelf", 800), ("Tor", 1250)):
        d.text((x, 40), text, font=f, fill="white", anchor="mm", stroke_width=4, stroke_fill="black")
    img.save(os.path.join(HERE, "big_rocks_lineup.png"))




# ------------------------------------------------------------------ in the arc base

W, D = 176, 264
# (asset, x, z, yaw): yaw turns the local frame (rock in +z off the wall, crag also +x)
# 0 = front-left corner / front wall, 90 = left wall / back-left corner,
# 180 = back wall / back-right corner, -90 = right wall / front-right corner.
BIG = [
    ("CornerCrag", -W, D, 90), ("CornerCrag", W, D, 180),
    ("Tor", -W + 20, 0, 0), ("Tor", W - 20, 0, 0),
    ("WallShelf", -76, D, 180), ("WallShelf", 76, D, 180),
    ("WallShelf", -W, 140, 90), ("WallShelf", W, 140, -90),
    ("Tor", -W, 204, 90), ("Tor", W, 204, -90),
]


def footprint(name, x, z, yaw):
    k = TA.Kit()
    ASSETS[name][0](k)
    pts = []
    M = T(x, 0, z) @ Ry(yaw)
    for q in k.parts:
        for sx in (-1, 1):
            for sz in (-1, 1):
                p = M @ q.cf @ np.array([sx * q.size[0] / 2, 0, sz * q.size[2] / 2, 1])
                pts.append(p[[0, 2]])
    return np.array(pts)


def check():
    import arc_base as A
    bad = []
    for name, x, z, yaw in BIG:
        pts = footprint(name, x, z, yaw)
        lo, hi = pts.min(0), pts.max(0)
        print(f"{name:10s} at ({x},{z}) yaw {yaw}: x {lo[0]:.0f}..{hi[0]:.0f}, z {lo[1]:.0f}..{hi[1]:.0f}")
        for p in A.pens():
            t = math.radians(p["a"])
            for px, pz in pts:
                dx, dz = px - p["x"], pz - p["z"]
                along, out = -dx * math.sin(t) + dz * math.cos(t), dx * math.cos(t) + dz * math.sin(t)
                if abs(along) < A.PEN / 2 + 4 and abs(out) < A.PEN / 2 + 4:
                    bad.append((name, x, z, p["i"]))
                    break
        for cx, cz in (A.CARL, A.PODIUM):
            if np.any((np.abs(pts[:, 0] - cx) < 14) & (np.abs(pts[:, 1] - cz) < 10)):
                bad.append((name, x, z, "Carl/podium"))
    print("overlaps:", sorted(set(bad)))


def flower_spots(A, kind):
    """Patches on grass only: a pair at each big rock's foot, plus a scatter out in
    the grass round the pens (never in a pen, the yard or a ride lane)."""
    rng = np.random.default_rng(9)
    out = []

    def ok(x, z):
        i, j = int((x + A.W) // 4), int(z // 4)
        if not (0 < i < kind.shape[0] - 1 and 0 < j < kind.shape[1] - 1) or kind[i, j]:
            return False
        for p in A.pens():
            t = math.radians(p["a"])
            dx, dz = x - p["x"], z - p["z"]
            along, o = -dx * math.sin(t) + dz * math.cos(t), dx * math.cos(t) + dz * math.sin(t)
            if abs(along) < A.PEN / 2 + 4 and abs(o) < A.PEN / 2 + 4:
                return False
        for name, bx, bz, yaw in BIG:
            pts = footprint(name, bx, bz, yaw)
            if np.any(np.hypot(pts[:, 0] - x, pts[:, 1] - z) < 4):
                return False
        return all(np.hypot(x - a, z - b) > 10 for a, b in out)

    for name, bx, bz, yaw in BIG:
        pts = footprint(name, bx, bz, yaw)
        c = pts.mean(0)
        inward = np.array([-(bx > 0) * 2 + 1 if abs(bx) == W else 0, -1 if bz == D else (1 if bz == 0 else 0)], float)
        for side in (-1, 1):
            for _ in range(20):
                x, z = c + inward * rng.uniform(14, 24) + np.array([inward[1], -inward[0]]) * side * rng.uniform(6, 16)
                if ok(x, z):
                    out.append((x, z))
                    break
    for _ in range(400):
        if len(out) >= 34:
            break
        x, z = rng.uniform(-A.W + 8, A.W - 8), rng.uniform(8, A.D - 8)
        if ok(x, z):
            out.append((x, z))
    return out


def base():
    import arc_base as A
    keep = []
    for n, x, z, yaw in A.clusters():  # drop the small knots the big rocks replace
        if any(np.hypot(x - bx, z - bz) < 30 for _, bx, bz, _ in BIG):
            continue
        keep.append((n, x, z, yaw))
    A.clusters = lambda: keep
    parts, kind = A.scene()
    for name, x, z, yaw in BIG:
        parts += place(ASSETS[name][0], x, z, yaw)
    for x, z in flower_spots(A, kind):
        parts += place(flowers, x, z, (x * 13 + z * 7) % 360)
    eye, target, fov = (0, 760, -170), (0, 0, 128), 30
    img = render(parts, eye=eye, target=target, W=1400, H=1200, fov=fov, fog=False, ground=False, outline=False)
    img.save(os.path.join(HERE, "big_rocks_overhead.png"))
    img = render(parts, eye=(0, 110, -40), target=(0, 0, 150), W=1400, H=800, fov=62, fog=False, ground=False, outline=False)
    img.save(os.path.join(HERE, "big_rocks_from_home_line.png"))
    img = render(parts, eye=(60, 70, 120), target=(-150, 8, 240), W=1400, H=800, fov=55, fog=False, ground=False, outline=False)
    img.save(os.path.join(HERE, "big_rocks_back_corner.png"))


if "--check" in sys.argv:
    check()
if "--base" in sys.argv:
    base()

if "--lineup" in sys.argv:
    lineup()
