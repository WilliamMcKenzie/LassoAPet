"""Arc base concept (QM, Oct 9): five pens on a smooth arc round a natural dirt
yard, meadow grass/dirt checker, meadow rocks and bushes along the walls.
Run: python3 design/base_arc/arc_base.py (renders arc_overhead.png and arc_from_home_line.png here)
Concept render only; nothing is written to the map."""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "tools")
sys.path.insert(0, REPO)
from partlib import Part, T, Ry, render, look_at  # noqa: E402
import terrain_assets as TA  # noqa: E402
from desert_ground import noise  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
GRASS = [(77, 196, 63), (105, 255, 74)]
DIRT = [(225, 150, 104), (248, 170, 114)]
WALL = [(225, 150, 104), (248, 170, 114)]
RAIL, POST = (204, 108, 52), (62, 62, 72)

W, D = 176, 264          # base: x -W..W, z 0..D inside the walls
CORR = 56                # course corridor half width at the home line
CENTRE = (0.0, 90.0)     # the arc's centre, middle of the yard
RC = 130                 # pen centres sit this far from it
ANGLES = [90, 140, 40, 190, -10]   # claim order: back, then out to the front corners
PEN, GATE = 68, 10       # pen at its biggest; gap in the fence facing the yard
WALL_H = 48


def pens():
    out = []
    for i, a in enumerate(ANGLES):
        t = math.radians(a)
        cx, cz = CENTRE[0] + RC * math.cos(t), CENTRE[1] + RC * math.sin(t)
        out.append(dict(i=i + 1, a=a, x=cx, z=cz))
    return out


def local(p, lx, lz):
    """Pen local frame: +lz points out from the yard (to the pen's back), lx along the arc."""
    t = math.radians(p["a"])
    ox, oz = math.cos(t), math.sin(t)       # outward
    sx, sz = -oz, ox                         # along the arc
    return p["x"] + lx * sx + lz * ox, p["z"] + lx * sz + lz * oz


def yaw_of(p):
    # Ry(yaw) turns local +x onto the arc tangent
    t = math.radians(p["a"])
    return math.degrees(math.atan2(math.cos(t), -math.sin(t))) * -1 + 0


# ------------------------------------------------------------------ ground

def ground_kind():
    """0 grass, 1 dirt, per 4-stud tile; i over x, j over z (z = 0 at the home line)."""
    nx, nz = 2 * W // 4, D // 4
    big = noise(nx, nz, 10, 21) * 0.75 + noise(nx, nz, 4, 22) * 0.25
    isl = noise(nx, nz, 6, 25)
    fine = noise(nx, nz, 3, 23) * 0.75 + noise(nx, nz, 1.5, 24) * 0.25
    kind = np.zeros((nx, nz), int)
    for i in range(nx):
        for j in range(nz):
            x, z = -W + i * 4 + 2, j * 4 + 2
            r = math.hypot(x - CENTRE[0], z - CENTRE[1])
            wob = (big[i, j] - 0.5) * 46
            yard = r < RC - PEN / 2 - 12 + wob
            lane = z < CENTRE[1] and abs(x) < 38 + wob and z > 6
            island = isl[i, j] > 0.8 and r < RC - PEN / 2 - 34  # grass islands left in the yard
            stray = fine[i, j] > 0.70 and r > RC - PEN / 2 + 2  # meadow dirt patches out in the grass
            kind[i, j] = int(((yard or lane) and not island) or stray)
    for p in pens():  # the gate's apron joins the yard
        for i in range(nx):
            for j in range(nz):
                x, z = -W + i * 4 + 2, j * 4 + 2
                t = math.radians(p["a"])
                dx, dz = x - p["x"], z - p["z"]
                along, out = -dx * math.sin(t) + dz * math.cos(t), dx * math.cos(t) + dz * math.sin(t)
                if abs(along) < 9 and -PEN / 2 - 14 < out < -PEN / 2 + 1:
                    kind[i, j] = 1
                if abs(along) < PEN / 2 + 3 and -PEN / 2 + 1 < out < PEN / 2 + 3:
                    kind[i, j] = 0  # pens stand on grass
    # QM (Oct 9): no dirt against any wall, or the sunk tiles leave holes under it.
    # Two grass tiles along every wall, the front wall either side of the corridor too.
    kind[:2, :] = kind[-2:, :] = 0
    kind[:, -2:] = 0
    for i in range(nx):
        if abs(-W + i * 4 + 2) > CORR - 8:
            kind[i, :2] = 0
    return kind


def floor_parts(kind):
    parts = []
    nx, nz = kind.shape
    for i in range(nx):
        for j in range(nz):
            x, z = -W + i * 4 + 2, j * 4 + 2
            k = kind[i, j]
            top = -1 if k else 0
            parts.append(Part("Floor", (4, top + 2, 4), T(x, (top - 2) / 2, z), (GRASS, DIRT)[k][(i + j) % 2]))
    for i in range(2 * CORR // 4):
        for j in range(1, 40):
            parts.append(Part("Floor", (4, 2, 4), T(-CORR + i * 4 + 2, -1, -j * 4 + 2), GRASS[(i + j) % 2]))
    return parts


def wall_parts(h=WALL_H):
    parts = []

    def column(x, z, k):
        for y in range(h // 4):
            parts.append(Part("Wall", (4, 4, 4), T(x, y * 4 + 2, z), WALL[(k + y) % 2], plain=True))

    for j in range(-1, D // 4 + 1):
        column(-W - 2, j * 4 + 2, j)
        column(W + 2, j * 4 + 2, j)
    for i in range(-1, 2 * W // 4 + 1):
        column(-W + i * 4 + 2, D + 2, i)
        x = -W + i * 4 + 2
        if abs(x) > CORR:
            column(x, -2, i)
    for j in range(1, 40):
        column(-CORR - 2, -j * 4 + 2, j)
        column(CORR + 2, -j * 4 + 2, j)
    return parts


# ------------------------------------------------------------------ props

def fence(p):
    parts = []
    t = math.radians(p["a"])
    R = Ry(-math.degrees(math.atan2(math.sin(t), math.cos(t))) + 90)  # local x -> tangent

    def put(name, size, lx, y, lz, color, yaw=0.0):
        x, z = local(p, lx, lz)
        parts.append(Part(name, size, T(x, y, z) @ R @ Ry(yaw), color))

    h = PEN / 2
    runs = [((-h, -h), (-GATE / 2, -h)), ((GATE / 2, -h), (h, -h)), ((-h, -h), (-h, h)), ((h, -h), (h, h)),
            ((-h, h), (h, h))]
    for (ax, az), (bx, bz) in runs:
        L = math.hypot(bx - ax, bz - az)
        n = max(1, math.ceil(L / 6))
        horiz = abs(bz - az) < 1e-6
        for k in range(n + 1):
            put("Post", (1.2, 4, 1.2), ax + (bx - ax) * k / n, 2, az + (bz - az) * k / n, POST)
        mx, mz = (ax + bx) / 2, (az + bz) / 2
        for y in (0.9, 3.3):
            put("Rail", (L, 0.5, 0.5) if horiz else (0.5, 0.5, L), mx, y, mz, RAIL)
    return parts


def bull(x, z, yaw):
    """A placeholder mechanical bull on a round padded mat."""
    k = TA.Kit()
    for r, c in ((9, (214, 58, 52)), (7, (240, 92, 80))):
        for a in range(0, 180, 15):  # a 12-sided mat out of crossed slabs
            k.at("Mat", (0, 0.3 if r == 9 else 0.45, 0), (2 * r, 0.6 if r == 9 else 0.9, 2 * r * math.tan(math.radians(7.5))), c, Ry(a))
    k.box("Base", (-1.2, 0, -1.2), (1.2, 3, 1.2), (90, 90, 100))
    k.box("Body", (-1.8, 3, -4), (1.8, 6, 3), (120, 72, 40))
    k.box("Head", (-1.4, 4, -6.4), (1.4, 6.6, -4), (120, 72, 40))
    k.box("Horn", (-3.4, 6, -5.6), (3.4, 6.8, -4.8), (245, 240, 225))
    k.box("Saddle", (-1.9, 6, -1.5), (1.9, 6.6, 1.5), (200, 40, 40))
    M = T(x, 0, z) @ Ry(yaw)
    return [Part(q.name, q.size, M @ q.cf, q.color) for q in k.parts]


ASSET = {"Stone": TA.stone, "Bush": TA.bush, "Boulder": TA.boulder, "BoulderSplit": TA.boulder_b}


def asset(name, x, z, yaw, scale=1.0):
    k = TA.Kit()
    ASSET[name](k)
    M = T(x, 0, z) @ Ry(yaw)
    out = []
    for q in k.parts:
        cf = q.cf.copy()
        cf[:3, 3] *= scale
        out.append(Part(q.name, q.size * scale, M @ cf, q.color))
    return out


def clusters():
    """Meadow-style knots against the walls: a boulder with smalls strung along it,
    in the grass wedges between pens and in the corners. The yard stays clear."""
    rng = np.random.default_rng(5)
    spots = []
    # corners and wall wedges (x, z, wall normal yaw)
    knots = [(-W + 8, D - 8), (W - 8, D - 8), (-W + 8, 150), (W - 8, 150), (-58, D - 8), (58, D - 8),
             (-W + 8, 12), (W - 8, 12), (-120, D - 8), (120, D - 8), (-W + 8, 210), (W - 8, 210)]
    for kx, kz in knots:
        spots.append(("Boulder" if rng.random() < 0.6 else "BoulderSplit", kx, kz, rng.uniform(0, 360)))
        for dx, dz in ((10, 0), (-10, 0), (0, -10), (0, 10)):
            x, z = kx + dx + rng.uniform(-1.5, 1.5), kz + dz + rng.uniform(-1.5, 1.5)
            if abs(x) <= W - 4 and 4 <= z <= D - 4 and rng.random() < 0.8:
                spots.append(("Bush" if rng.random() < 0.5 else "Stone", x, z, rng.uniform(0, 360)))
    # a few smalls at the yard's edge between gates, like the meadow's scatter
    for a in (115, 65, 165, 15):
        t = math.radians(a)
        r = RC - PEN / 2 + 4
        spots.append(("Bush", CENTRE[0] + r * math.cos(t), CENTRE[1] + r * math.sin(t), rng.uniform(0, 360)))
        spots.append(("Stone", CENTRE[0] + (r - 8) * math.cos(t + 0.06), CENTRE[1] + (r - 8) * math.sin(t + 0.06),
                      rng.uniform(0, 360)))
    return spots


def bull_spots():
    out = []
    for p in pens():
        x, z = local(p, 18, -PEN / 2 - 13)
        out.append((p["i"], x, z, -p["a"] + 90 + 180))
    return out


CARL = (-104, 20)
PODIUM = (104, 20)


def scene(walls=True):
    kind = ground_kind()
    parts = floor_parts(kind)
    if walls:
        parts += wall_parts()
    for p in pens():
        parts += fence(p)
    for _, x, z, yaw in bull_spots():
        parts += bull(x, z, yaw)
    for name, x, z, yaw in clusters():
        parts += asset(name, x, z, yaw)
    k = TA.Kit()  # Carl's stall and the podium, as blocks where they'd stand
    k.box("Carl", (CARL[0] - 10, 0, CARL[1] - 6), (CARL[0] + 10, 8, CARL[1] + 6), (214, 170, 90))
    k.box("Podium", (PODIUM[0] - 5, 0, PODIUM[1] - 5), (PODIUM[0] + 5, 12, PODIUM[1] + 5), (240, 232, 210))
    parts += k.parts
    return parts, kind


def projector(eye, target, Wpx, Hpx, fov):
    eye, r, u, f = look_at(eye, target)
    focal = (Hpx / 2) / math.tan(math.radians(fov) / 2)

    def proj(x, y, z):
        d = np.array([x, y, z]) - eye
        return Wpx / 2 + focal * (d @ r) / (d @ f), Hpx / 2 - focal * (d @ u) / (d @ f)
    return proj


def label(img, proj, items, size=26):
    dr = ImageDraw.Draw(img)
    try:
        fnt = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except OSError:
        fnt = ImageFont.load_default()
    for text, (x, y, z) in items:
        px, py = proj(x, y, z)
        dr.text((px, py), text, font=fnt, fill="white", anchor="mm", stroke_width=4, stroke_fill="black")


def main():
    parts, kind = scene()
    print("parts", len(parts), "dirt tiles", int(kind.sum()))
    Wp, Hp = 1400, 1200
    eye, target, fov = (0, 760, -170), (0, 0, 128), 30
    img = render(parts, eye=eye, target=target, W=Wp, H=Hp, fov=fov, fog=False, ground=False, outline=False)
    pr = projector(eye, target, Wp, Hp, fov)
    items = [(f"PEN {p['i']}", (p["x"], 6, p["z"])) for p in pens()]
    items += [("Carl", (CARL[0], 10, CARL[1])), ("podium", (PODIUM[0], 14, PODIUM[1])),
              ("HOME LINE", (0, 2, -6)), ("TO THE STAMPEDE", (0, 2, -60))]
    label(img, pr, items)
    img.save(os.path.join(HERE, "arc_overhead.png"))
    Wp, Hp = 1400, 800
    eye, target, fov = (0, 110, -40), (0, 0, 150), 62
    img = render(parts, eye=eye, target=target, W=Wp, H=Hp, fov=fov, fog=False, ground=False, outline=False)
    img.save(os.path.join(HERE, "arc_from_home_line.png"))


if __name__ == "__main__":
    main()
