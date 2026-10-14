"""Shared bits for the World 3 Candyland animals (biome 3: Pirate Cove, Garden, Candyland,
Cnidaria): the candy palette, block helpers for turned parts and the preview renders.

Every Candyland tool builds an animal_designs.Animal, writes designs/candyland/<Name>.bbmodel
(every rest baked into the parts, every bone at 0, so convert WITHOUT --zyx) and renders
to /mnt/project-files/world3/candyland/renders/.

Colours are bright and saturated with a dark stop under each, because game Lighting washes
colours out. Name prefixes the converter reads: Glow* = neon, Eye*/Pupil*/Plain* = no studs,
and any name containing "In" is drawn plain too, so avoid "In" in ordinary part names.
"""

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import EYE_WHITE, PUPIL, PLATE, PUPIL_BACK  # noqa: E402,F401
from horse_rig import pose  # noqa: E402
from partlib import Part, T, Rx, Ry, Rz, render  # noqa: E402,F401

OUT = os.path.join(A.ROOT, "designs", "candyland")
SHOTS = "/mnt/project-files/world3/candyland/renders"
BG = (244, 238, 246)
TAU = 2 * math.pi

# ---- candy palette: (bright, dark stop)
CHERRY = (236, 36, 72)
CHERRY_DK = (168, 18, 50)
STRAWB = (255, 92, 150)
STRAWB_DK = (214, 52, 118)
BUBBLE = (255, 150, 206)
BUBBLE_DK = (232, 98, 170)
LEMON = (255, 222, 40)
LEMON_DK = (240, 170, 20)
ORANGE = (255, 140, 30)
ORANGE_DK = (222, 96, 18)
LIME = (120, 222, 50)
LIME_DK = (66, 168, 34)
MINT = (60, 230, 176)
MINT_DK = (24, 176, 136)
SKY = (70, 196, 255)
SKY_DK = (34, 132, 230)
GRAPE = (160, 80, 240)
GRAPE_DK = (110, 46, 196)
LILAC = (204, 150, 255)
WHITE = (255, 252, 246)
CREAM = (255, 240, 206)
CREAM_DK = (240, 210, 160)
ICING = (255, 255, 255)
GINGER = (204, 112, 44)
GINGER_DK = (150, 72, 26)
CHOC = (110, 58, 32)
CHOC_DK = (70, 34, 18)
PASTRY = (238, 172, 84)
PASTRY_DK = (200, 124, 50)
CANDYCORN = [(255, 250, 236), (255, 150, 20), (255, 214, 30)]
RAINBOW = [(240, 50, 70), (255, 140, 30), (255, 222, 40), (90, 214, 70), (60, 160, 255), (170, 90, 240)]
SPRINKLES = [CHERRY, LEMON, LIME, SKY, GRAPE, ORANGE, BUBBLE, WHITE]


def sym(a, name, lo, hi, color, bone):
    """A box on the right (x > 0, as given) and its mirror on the left. '*' in the name
    and bone becomes L/R (left is -x)."""
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * lo[0], sx * hi[0]))
        a.box(name.replace("*", side), (xa, lo[1], lo[2]), (xb, hi[1], hi[2]), color, bone.replace("*", side))


def rbox(a, name, size, M, color, bone):
    """A box of size (w, h, d) placed by the 4x4 transform M (turns baked in)."""
    p = Part(name, size, M, color)
    p.bone = bone
    a.parts.append(p)
    return p


def frame(p0, p1):
    """4x4 transform at the midpoint of p0-p1 with local z along p0 -> p1."""
    p0, p1 = np.array(p0, float), np.array(p1, float)
    d = p1 - p0
    d /= np.linalg.norm(d)
    up = np.array([0, 1.0, 0]) if abs(d[1]) < 0.95 else np.array([1.0, 0, 0])
    x = np.cross(up, d)
    x /= np.linalg.norm(x)
    y = np.cross(d, x)
    M = np.eye(4)
    M[:3, 0], M[:3, 1], M[:3, 2] = x, y, d
    M[:3, 3] = (p0 + p1) / 2
    return M


def beam(a, name, p0, p1, w, h, color, bone, pad=0.0):
    """A w x h bar from p0 to p1 (pad lengthens it so joints overlap)."""
    L = np.linalg.norm(np.array(p1, float) - np.array(p0, float)) + pad
    return rbox(a, name, (w, h, L), frame(p0, p1), color, bone)


def rpyr(a, name, M, w, d, h, color, bone):
    """Square pyramid, base w x d on local y = 0, tip at local (0, h, 0), placed by M."""
    base = [(-w / 2, 0, -d / 2), (w / 2, 0, -d / 2), (w / 2, 0, d / 2), (-w / 2, 0, d / 2)]
    pts = [(M @ np.array([*v, 1.0]))[:3] for v in base]
    tip = (M @ np.array([0, h, 0, 1.0]))[:3]
    p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
    p.polys = [np.array(pts[::-1])] + [np.array([pts[i], pts[(i + 1) % 4], tip]) for i in range(4)]
    p.bone = bone
    a.parts.append(p)
    return p


def eyes(a, x, y0, y1, z0, z1, bone="neck", glow=False):
    """The standard googly plate eyes on both sides of a head (x = the head's half width)."""
    a.eyes(x, y0, y1, z0, z1, bone)
    if glow:
        for p in a.parts[-4:]:
            if p.name.startswith("Pupil"):
                p.name = "Glow" + p.name


def front_eyes(a, cx, y0, y1, z, w, bone="neck", pupil=PUPIL, look=0.0):
    """Googly plate eyes on a face that looks down -z: two white plates at x = +-cx,
    w wide, from y0 to y1, standing PLATE off the face at z; pupils sit lower-middle.
    look shifts the pupils sideways (outward > 0)."""
    for side, sx in (("L", -1), ("R", 1)):
        c = sx * cx
        a.box("Eye" + side, (c - w / 2, y0, z - PLATE), (c + w / 2, y1, z), EYE_WHITE, bone)
        pw, ph = w * 0.5, (y1 - y0) * 0.55
        pc = c + sx * look * w * 0.2
        a.box("Pupil" + side, (pc - pw / 2, y0 + (y1 - y0) * 0.12, z - PLATE - 0.03),
              (pc + pw / 2, y0 + (y1 - y0) * 0.12 + ph, z - PLATE + PUPIL_BACK), pupil, bone)


def stripes_box(a, name, lo, hi, colors, axis, bone, n=None):
    """A box cut into flush slices along axis (0 x, 1 y, 2 z), cycling colors."""
    lo, hi = np.array(lo, float), np.array(hi, float)
    n = n or len(colors)
    step = (hi[axis] - lo[axis]) / n
    for i in range(n):
        l, h = lo.copy(), hi.copy()
        l[axis] = lo[axis] + step * i
        h[axis] = lo[axis] + step * (i + 1)
        a.box(f"{name}{i + 1}", l, h, colors[i % len(colors)], bone)


def mark_glow(parts):
    for p in parts:
        p.neon = p.name.startswith("Glow")
    return parts


def extent(a):
    pts = []
    for p in a.parts:
        if p.shape == "Poly":
            pts += [q for poly in p.polys for q in poly]
        else:
            M = p.cf
            for c in ((-1, -1, -1), (1, 1, 1), (-1, 1, 1), (1, -1, -1)):
                pts.append((M @ np.array([*(np.array(c) * p.size / 2), 1.0]))[:3])
    pts = np.array(pts)
    return pts.min(axis=0), pts.max(axis=0)


def shot(parts, **cam):
    im = render(mark_glow(parts), transparent=True, **cam)
    out = Image.new("RGB", im.size, BG)
    out.paste(im, (0, 0), im)
    return out


def hero_cam(lo, hi, W=900, H=900):
    """A 3/4 front camera that frames the model's box."""
    c = (lo + hi) / 2
    r = float(np.linalg.norm(hi - lo)) / 2
    d = r * 2.9
    eye = c + np.array([-0.62, 0.42, -0.66]) * d
    return dict(eye=tuple(eye), target=tuple(c), W=W, H=H, fov=40)


def views(lo, hi, size=500):
    c = (lo + hi) / 2
    d = float(np.linalg.norm(hi - lo)) * 1.45
    dirs = [(-0.62, 0.42, -0.66), (-1, 0.15, 0), (0.6, 0.45, 0.66), (0, 0.2, -1)]
    return [dict(eye=tuple(c + np.array(v) / np.linalg.norm(v) * d), target=tuple(c), W=size, H=size, fov=40) for v in dirs]


def publish(a, still=False, anims=("idle", "walk", "gallop")):
    """Write the .bbmodel, the hero render <Name>.png, a four-view sheet and (unless
    still) an animation gif. Returns the model json."""
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(SHOTS, exist_ok=True)
    mark_glow(a.parts)
    model = A.build_animal(a, OUT)
    lo, hi = extent(a)
    print(f"{a.name}: {len(a.parts)} parts, extent {np.round(lo, 1)} .. {np.round(hi, 1)}")
    shot(pose(model, None, 0), **hero_cam(lo, hi)).save(os.path.join(SHOTS, a.name + ".png"))
    sheet = Image.new("RGB", (1000, 1000))
    for i, cam in enumerate(views(lo, hi)):
        sheet.paste(shot(pose(model, None, 0), **cam), ((i % 2) * 500, (i // 2) * 500))
    sheet.save(os.path.join(SHOTS, a.name + "_views.png"))
    if still:
        return model
    frames = []
    side, hero = views(lo, hi, 400)[1], hero_cam(lo, hi, 400, 400)
    for name in anims:
        anim = A.anim_named(model, name)
        if not anim:
            continue
        nf = max(12, int(anim["length"] * 20))
        for k in range(nf):
            ps = pose(model, anim, k / nf * anim["length"])
            im = Image.new("RGB", (800, 400))
            im.paste(shot(ps, **side), (0, 0))
            im.paste(shot(ps, **hero), (400, 0))
            frames.append(A.label(im, ["run" if name == "gallop" else name] * 2))
    if frames:
        A.gif(os.path.join(SHOTS, a.name + "_anims.gif"), frames, fps=20)
    return model


def track(L, fn, n=16, channel="rotation"):
    """fn(u), u = 0..1 over the loop -> (x, y, z): degrees, or Blockbench units for position."""
    return {"channel": channel, "interp": "catmullrom",
            "keys": [(round(L * k / n, 4), tuple(round(float(v), 3) for v in fn(k / n))) for k in range(n + 1)]}
