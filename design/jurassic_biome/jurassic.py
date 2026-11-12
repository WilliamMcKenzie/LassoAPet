"""QM (Oct 10): the "Jurassic" biome mockup: jungle vibe (dinosaurs live here), darker
grass, brown (dirt) rocks, a rough dirt trail down the middle, and one stretch of the
course running through a giant ribcage. Jurassic is the last biome, so the course is at
its widest here and the ribcage can be huge.
Run: python3 design/jurassic_biome/jurassic.py"""
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

OUT = "/mnt/project-files/design/jurassic_biome"

GRASS = ((78, 140, 40), (86, 152, 44))      # darker jungle grass
DIRT = ((150, 104, 64), (162, 114, 70))     # the trail
WALL = ((150, 102, 62), (164, 114, 70))
ROCK_SHADES = [(132, 94, 62), (118, 82, 54), (148, 106, 70), (124, 88, 58), (140, 100, 66)]
BONE = [(238, 228, 202), (226, 214, 186), (246, 238, 216)]
SKY = np.array([89, 217, 253.0])

HALF_W = 128                                # the course near its widest (funnel MAX 137)
Z_HI, Z_LO = 40, -420


def trail_x(z):
    return 10 * math.sin(z / 70) + 6 * math.sin(z / 23 + 1.3)


def trail_half(z):
    return 11 + 3 * math.sin(z / 17) + 2 * math.sin(z / 7.3 + 0.5)


def floor():
    parts = []
    for zi in range(int((Z_HI - Z_LO) // 4)):
        z = Z_HI - zi * 4 - 2
        cx, hw = trail_x(z), trail_half(z)
        for xi in range(int(-HALF_W // 4), int(HALF_W // 4)):
            x = xi * 4 + 2
            if abs(x - cx) < hw:
                parts.append(Part("Dirt", (4, 0.1, 4), T(x, 0.05, z), DIRT[(xi + zi) % 2]))
    for side in (-1, 1):
        for zi in range(int((Z_HI - Z_LO) // 4)):
            for yi in range(5):
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, Z_HI - zi * 4 - 2),
                                  WALL[(zi + yi) % 2], plain=True))
    return parts


BUILD = {n[4:]: (f, s) for n, f, s, _ in RM.ROCKS}


def rock(name, x, z, yaw, scale):
    out = []
    for i, ch in enumerate(RM.build(*BUILD[name])):
        ch = [[v * scale for v in t] for t in ch]
        out += RM.as_parts([ch], x, z, yaw=yaw, color=ROCK_SHADES[i % len(ROCK_SHADES)])
    return out


def beam(a, b, w, color):
    """A bone segment from a to b, w across (a block along the segment)."""
    a, b = np.array(a, float), np.array(b, float)
    d = b - a
    ln = np.linalg.norm(d)
    z = d / ln
    x = np.cross([0, 0, 1.0], z) if abs(z[2]) < 0.9 else np.cross([0, 1.0, 0], z)
    x /= np.linalg.norm(x)
    y = np.cross(z, x)
    cf = np.eye(4)
    cf[:3, 0], cf[:3, 1], cf[:3, 2], cf[:3, 3] = x, y, z, (a + b) / 2
    return Part("Bone", (w, w, ln + w * 0.6), cf, color)


# ---- the ribcage: a spine overhead along the middle, rib pairs arching out past the
# middle of the course and curving back in to rest on the ground near the walls.
RIB_Z0, RIB_N, RIB_GAP = -110, 9, 26
TOP = 96            # the spine's height at the middle rib
REACH = HALF_W - 6  # the widest bulge of the middle rib


def ribcage():
    parts = []
    mid = (RIB_N - 1) / 2
    for k in range(RIB_N):
        z0 = RIB_Z0 - k * RIB_GAP
        s = 0.62 + 0.38 * math.cos((k - mid) / (mid + 1.2) * math.pi / 2)  # middle ribs biggest
        top, reach, base = TOP * s, REACH * (0.7 + 0.3 * s), 26 * s
        w0 = 9 * s
        for side in (-1, 1):
            # an ellipse round (0, base): over the top, out past half way, back in to the floor
            t_end = math.acos(-base / (top - base))
            pts = []
            n = 14
            for i in range(n + 1):
                t = 0.08 + (t_end - 0.08) * i / n
                x = side * (6 + (reach - 6) * math.sin(t))
                y = base + (top - base) * math.cos(t)
                z = z0 - (top - y) * 0.22  # ribs sweep back toward the tail
                pts.append((x, max(y, -1.0), z))
            for i in range(n):
                w = w0 * (1 - 0.45 * i / n)
                parts.append(beam(pts[i], pts[i + 1], w, BONE[(k + i) % 3 if i % 4 == 0 else 0]))
    # spine: vertebrae from in front of the first rib to past the last, tapering to a tail
    z = RIB_Z0 + 50
    i = 0
    while z > RIB_Z0 - (RIB_N - 1) * RIB_GAP - 110:
        k = (RIB_Z0 - z) / RIB_GAP
        s = 0.62 + 0.38 * math.cos(max(-1.4, min(1.4, (k - mid) / (mid + 1.2) * math.pi / 2)))
        tail = max(0.35, 1 - max(0, -(z - (RIB_Z0 - (RIB_N - 1) * RIB_GAP))) / 160)
        head = max(0.5, 1 - max(0, z - RIB_Z0) / 120)
        sz = 14 * s * min(tail, head)
        y = TOP * s * min(1, 0.6 + 0.4 * tail) + 2
        parts.append(Part("Bone", (sz, sz * 0.9, sz * 0.8), T(0, y, z), BONE[i % 2]))
        parts.append(Part("Bone", (sz * 0.35, sz * 0.9, sz * 0.5), T(0, y + sz * 0.8, z), BONE[2]))  # spinous process
        z -= sz * 1.05
        i += 1
    return parts


ROCKS = [("Boulder", -100, -20, 30, 4.0), ("Pebble", -84, -40, 0, 4.4), ("Crag", 104, -60, 200, 3.2),
         ("Stone", 88, -46, 90, 4.0), ("Slab", -108, -150, 140, 3.4), ("Boulder", 106, -190, 260, 3.6),
         ("Pebble", 90, -210, 30, 4.4), ("Crag", -104, -260, 60, 3.0), ("Stone", -86, -280, 10, 4.0),
         ("Boulder", 102, -330, 120, 3.8), ("Slab", -106, -380, 300, 3.4), ("Stone", 40, -120, 20, 3.0),
         ("Pebble", -46, -300, 70, 3.6), ("Boulder", -40, -60, 200, 2.6)]


def scene():
    parts = floor() + ribcage()
    for r in ROCKS:
        parts += rock(*r)
    return parts


def shot(parts, eye, target, W=1400, H=900, fov=55):
    partlib.SKY_TOP = partlib.SKY_BOT = SKY
    partlib.GROUND = np.array(GRASS[0], float)
    partlib.GROUND2 = np.array(GRASS[1], float)
    return partlib.render(parts, eye=eye, target=target, W=W, H=H, fov=fov, fog=False, outline=False)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    parts = scene()
    views = [("ride", (0, 110, 90), (0, 10, -110), 58, "Riding in: the trail runs under the ribcage"),
             ("inside", (6, 16, -120), (0, 40, -260), 62, "Inside the ribcage"),
             ("aerial", (260, 230, 80), (0, 20, -170), 50, "From above: the ribcage spans the whole course")]
    imgs = []
    for name, eye, target, fov, title in views:
        img = shot(parts, eye, target, fov=fov)
        img.save(os.path.join(OUT, f"jurassic_{name}.png"))
        imgs.append((img, title))
        print(name)
    band = 44
    sheet = Image.new("RGB", (1400, len(imgs) * (900 + band)), (255, 255, 255))
    d = ImageDraw.Draw(sheet)
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    for i, (img, title) in enumerate(imgs):
        y = i * (900 + band)
        d.text((16, y + 8), title, font=f, fill=(20, 20, 20))
        sheet.paste(img.convert("RGB"), (0, y + band))
    sheet.save(os.path.join(OUT, "jurassic_biome.png"))
    print("wrote", OUT)
