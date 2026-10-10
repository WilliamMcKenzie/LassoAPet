"""Base "bring it to life" concepts (QM, Oct 10): three clean, readable takes on the
current arc base. Run: python3 design/base_life/base_life.py  -> renders PNGs here.
Concept renders only; nothing is written to the map."""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, os.path.join(HERE, "..", "base_arc"))  # (before tools: tools has its own arc_base)
import arc_base as A  # noqa: E402
from partlib import Part, T, Ry, Rx, Rz, render  # noqa: E402
import terrain_assets as TA  # noqa: E402

# the base's colours on stamina-loop (Oct 10)
A.GRASS[:] = [(113, 173, 31), (122, 190, 25)]
A.DIRT[:] = [(206, 146, 84), (222, 164, 100)]
A.WALL[:] = [(197, 126, 70), (211, 142, 75)]
ROCK, ROCK_L, ROCK_D = (150, 172, 205), (178, 196, 222), (124, 144, 178)
W, D, C, RC, PEN = A.W, A.D, A.CENTRE, A.RC, A.PEN


def polar(a, r):
    t = math.radians(a)
    return C[0] + r * math.cos(t), C[1] + r * math.sin(t)


def place(kit, x, z, yaw=0.0, s=1.0, y=0.0):
    M = T(x, y, z) @ Ry(yaw)
    out = []
    for q in kit.parts:
        cf = q.cf.copy()
        cf[:3, 3] *= s
        out.append(Part(q.name, q.size * s, M @ cf, q.color, plain=q.plain))
    return out


def big_rock(split):
    k = TA.Kit()
    if split:
        k.at("R", (-1.9, 2.8, 0), (4.2, 7.0, 6.4), ROCK, TA.rot(8, 0, 10))
        k.at("R", (-2.3, 6.4, 0.2), (3.4, 0.8, 5.4), ROCK_L, TA.rot(8, 0, 10))
        k.at("R", (2.1, 2.2, 0.3), (4.0, 5.6, 6.0), ROCK_D, TA.rot(-6, 4, -12))
    else:
        k.at("R", (0.2, 2.6, 0.3), (7.6, 6.4, 6.6), ROCK, TA.rot(18, 7, -9))
        k.at("R", (-0.4, 5.9, 0.0), (5.4, 1.4, 4.8), ROCK_L, TA.rot(24, 6, -12))
        k.at("R", (-4.0, 1.4, -1.4), (3.6, 4.0, 3.4), ROCK_D, TA.rot(-20, -6, 16))
    return k


def pen_floor(p):
    """Level-1 pens stand on a dirt checker."""
    out = []
    t = math.radians(p["a"])
    R = Ry(-math.degrees(math.atan2(math.sin(t), math.cos(t))) + 90)
    h = PEN / 2
    for i in range(int(PEN // 4)):
        for j in range(int(PEN // 4)):
            x, z = A.local(p, -h + i * 4 + 2, -h + j * 4 + 2)
            out.append(Part("PenFloor", (4, 0.4, 4), T(x, 0.2, z) @ R, A.DIRT[(i + j) % 2]))
    return out


def ground():
    """The arc base's ground, minus its stray meadow specks (the live base has none)."""
    kind = A.ground_kind()
    nx, nz = kind.shape
    for i in range(nx):
        for j in range(nz):
            x, z = -W + i * 4 + 2, j * 4 + 2
            if math.hypot(x - C[0], z - C[1]) > RC - PEN / 2 + 4 and not (z < C[1] and abs(x) < 60):
                kind[i, j] = 0
    return kind


def base_scene():
    kind = ground()
    parts = A.floor_parts(kind) + A.wall_parts()
    for p in A.pens():
        parts += pen_floor(p) + A.fence(p)
    # the 4 big rocks: a crag in each back corner, a boulder in each front corner
    parts += place(big_rock(False), -W + 18, D - 18, 30, 3.6)
    parts += place(big_rock(False), W - 18, D - 18, -120, 3.6)
    parts += place(big_rock(True), -W + 16, 16, 70, 2.8)
    parts += place(big_rock(True), W - 16, 16, -40, 2.8)
    k = TA.Kit()  # Carl and the podium, as blocks where they stand
    k.box("Carl", (-112, 0, 16), (-96, 9, 24), (240, 210, 170))
    k.box("Podium", (98, 0, 14), (110, 3, 26), (230, 60, 60))
    k.box("Podium", (99, 3, 15), (109, 5, 25), (245, 245, 245))
    parts += k.parts
    return parts


# the grass wedges between pens, out by the walls: where every concept puts its things
WEDGES = [polar(115, 152), polar(65, 152), polar(165, 150), polar(15, 150)]

# ------------------------------------------------------------------ A: blossom trees
PINK, PINK_L, PINK_D = (255, 150, 196), (255, 190, 220), (232, 112, 168)
BARK = (140, 92, 58)


def blossom_tree():
    k = TA.Kit()
    k.box("Trunk", (-1.6, 0, -1.6), (1.6, 9, 1.6), BARK)
    k.box("Trunk", (-1.0, 6, -1.0), (4.5, 7.6, 1.0), BARK)
    k.box("Crown", (-7, 9, -7), (7, 15, 7), PINK)
    k.box("Crown", (-5.5, 15, -5.5), (5.5, 18.5, 5.5), PINK_L)
    k.box("Crown", (-8.5, 10, -4), (-7, 14, 4), PINK_D)
    k.box("Crown", (7, 10, -4), (8.5, 14, 4), PINK_D)
    k.box("Crown", (-4, 10, 7), (4, 14, 8.5), PINK_D)
    k.box("Crown", (-4, 10, -8.5), (4, 14, -7), PINK_D)
    k.box("Crown", (1, 12, 3), (7.5, 17, 9), PINK_L)
    # fallen petals: a few flat pink tiles on the grass round it
    rng = np.random.default_rng(3)
    for _ in range(9):
        a, r = rng.uniform(0, 6.28), rng.uniform(6, 13)
        k.at("Petal", (r * math.cos(a), 0.15, r * math.sin(a)), (1.6, 0.3, 1.6), PINK_L, Ry(rng.uniform(0, 90)))
    return k


def concept_a():
    parts = base_scene()
    for i, (x, z) in enumerate(WEDGES):
        parts += place(blossom_tree(), x, z, 25 * i, 1.6)
    return parts


# ------------------------------------------------------------------ B: ponds
WATER, WATER_L, PAD, PAD_D, REED = (64, 170, 245), (120, 205, 255), (90, 200, 70), (60, 160, 50), (60, 150, 45)
STONE_RIM = (200, 206, 214)


def pond(rx=14, rz=10):
    k = TA.Kit()
    for i in range(-rx // 2, rx // 2):
        for j in range(-rz // 2, rz // 2):
            cx, cz = i * 2 + 1, j * 2 + 1
            e = (cx / rx) ** 2 + (cz / rz) ** 2
            if e < 1:
                k.at("Water", (cx, 0.1, cz), (2, 0.4, 2), WATER if (i + j) % 2 else WATER_L)
            elif e < 1.45:
                k.at("Rim", (cx, 0.5, cz), (2, 1.0, 2), STONE_RIM)
    for (x, z) in ((-6, -2), (3, 3), (6, -4)):
        k.at("Pad", (x, 0.45, z), (3.2, 0.3, 3.2), PAD)
        k.at("Pad", (x + 0.6, 0.65, z + 0.4), (0.8, 0.3, 0.8), (255, 120, 170))  # a flower on it
    for (x, z) in ((-12, 5), (-13, 3), (12, -6), (13, -4)):
        k.at("Reed", (x, 2.5, z), (0.8, 5, 0.8), REED)
        k.at("Reed", (x, 5.3, z), (1.2, 1.6, 1.2), (150, 100, 60))
    return k


def duck():
    k = TA.Kit()
    k.box("Duck", (-1.4, 0.3, -2), (1.4, 2.3, 2), (255, 255, 255))
    k.box("Duck", (-1.0, 2.0, 1), (1.0, 4.0, 3), (255, 255, 255))
    k.box("Duck", (-0.6, 2.8, 3), (0.6, 3.4, 4.2), (255, 170, 40))
    return k


def concept_b():
    parts = base_scene()
    for i, (x, z) in enumerate(WEDGES):
        a = math.degrees(math.atan2(z - C[1], x - C[0]))
        parts += place(pond(), x, z, -a + 90, 1.5)
        if i < 2:
            parts += place(duck(), x + 4, z - 2, 40 + 90 * i, 1.4, y=0.4)
    return parts


# ------------------------------------------------------------------ C: ranch
HAY, HAY_L, HAY_D = (238, 200, 80), (250, 222, 120), (210, 168, 56)
WOOD, WOOD_D, VANE, VANE_D = (176, 110, 64), (140, 84, 48), (250, 250, 250), (230, 70, 60)


def hay(n=3):
    k = TA.Kit()
    spots = [(-3.2, 0, 0), (3.2, 0, 0), (0, 4, 0)][:n]
    for (x, y, z) in spots:
        k.box("Hay", (x - 3, y, z - 2.2), (x + 3, y + 4, z + 2.2), HAY)
        k.box("Hay", (x - 3, y + 4, z - 2.2), (x + 3, y + 4.4, z + 2.2), HAY_L)
        for b in (-1.6, 1.6):
            k.box("Band", (x + b - 0.3, y - 0.01, z - 2.25), (x + b + 0.3, y + 4.41, z + 2.25), HAY_D)
    return k


def windmill():
    k = TA.Kit()
    for sx in (-1, 1):  # a tapered lattice tower, as four legs and cross braces
        for sz in (-1, 1):
            k.at("Leg", (sx * 3.2, 11, sz * 3.2), (1.2, 22, 1.2), WOOD, Rz(-sx * 6) @ Rx(sz * 6))
    for y in (5, 11, 17):
        w = 7.6 - y * 0.25
        k.box("Brace", (-w, y, -w), (w, y + 1, w), WOOD_D)
        k.box("Brace", (-w + 1, y, -w + 1), (w - 1, y + 1, w - 1), (0, 0, 0))  # (hollow look: inner box dark)
    k.parts = [q for q in k.parts if q.color != (0, 0, 0)]
    k.box("Hub", (-1.6, 21, -2.4), (1.6, 24.6, 1.6), WOOD_D)
    for i in range(8):  # the wheel: eight blades, red and white
        k.at("Blade", (0, 22.8, -2.8), (1.6, 13, 0.5), VANE if i % 2 else VANE_D, Rz(i * 22.5) @ T(0, 6.5, 0))
    k.at("Tail", (0, 22.8, 5), (0.5, 4, 7), VANE_D)
    k.at("Trough", (0, 1.2, -7), (8, 2.4, 3), WOOD)
    k.at("Trough", (0, 2.3, -7), (7, 0.3, 2), WATER)
    return k


def concept_c():
    parts = base_scene()
    (x0, z0), (x1, z1), (x2, z2), (x3, z3) = WEDGES
    parts += place(windmill(), x0, z0, 160, 1.5)
    parts += place(hay(3), x1, z1, -30, 1.6)
    parts += place(hay(2), x2, z2, 75, 1.6)
    parts += place(hay(2), x3, z3, -70, 1.6)
    return parts


VIEWS = {  # QM's top-down camera, and standing at the home line
    "top": dict(eye=(0, 300, -120), target=(0, 0, 140), fov=50, W=1600, H=1000),
    "home": dict(eye=(0, 70, -10), target=(0, 0, 170), fov=62, W=1600, H=900),
}


def shoot(parts, name, view, title):
    v = VIEWS[view]
    img = render(parts, eye=v["eye"], target=v["target"], W=v["W"], H=v["H"], fov=v["fov"], fog=False,
                 ground=False, outline=False).convert("RGB")
    if title:
        dr = ImageDraw.Draw(img)
        fnt = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 40)
        dr.text((30, 24), title, font=fnt, fill="white", stroke_width=5, stroke_fill="black")
    path = os.path.join(HERE, f"{name}_{view}.png")
    img.save(path)
    print("wrote", path)


CONCEPTS = {
    "now": (base_scene, "Now"),
    "A_blossom": (concept_a, "A: Blossom trees"),
    "B_ponds": (concept_b, "B: Lily ponds"),
    "C_ranch": (concept_c, "C: Ranch"),
}

if __name__ == "__main__":
    which = sys.argv[1:] or list(CONCEPTS)
    for name in which:
        fn, title = CONCEPTS[name]
        parts = fn()
        print(name, len(parts), "parts")
        for view in VIEWS:
            shoot(parts, name, view, title)
