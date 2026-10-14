"""Five horse-egg design studies (voxel and low-poly) plus shared twitch / hatch
animations, exported as Blockbench models with preview renders.

Run: python3 tools/egg_designs.py <out_dir>

Every egg has the same bones so one set of animations fits them all:
  egg     pivot at the base centre (rocks on its bottom)
  bottom  lower shell
  top     upper shell, pivot on the crack line; flies off when it hatches
Eggs are ~3.2 studs tall (the Toy horse is ~11).
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, Ry, render, write_bbmodel  # noqa: E402
from horse_rig import pose, write_animations  # noqa: E402

CREAM = (250, 236, 205)
ORANGE = (226, 130, 50)
BROWN = (92, 54, 34)
HOOF = (74, 78, 102)
PINK = (242, 150, 192)
BLACK = (0, 0, 0)

H = 3.2  # egg height
R = 1.2  # widest radius
SPLIT = 1.8  # crack height: above it is the top shell


def radius(y, h=H, r=R):
    """Egg profile: wider below the middle."""
    c = max(-1.0, min(1.0, 1 - 2 * y / h))
    s = math.sqrt(max(0.0, 1 - c * c))
    return r * s * (1 + 0.14 * c)


def snap(x, g=0.2):
    return max(g, round(x / g) * g)


class Egg:
    def __init__(self):
        self.parts = []

    def block(self, name, lo, hi, color):
        lo, hi = np.array(lo, float), np.array(hi, float)
        p = Part(name, hi - lo, T(*((lo + hi) / 2)), color)
        p.bone = "top" if (lo[1] + hi[1]) / 2 > SPLIT else "bottom"
        self.parts.append(p)
        return p

    def poly(self, name, faces, color, bone=None, plain=False):
        p = Part(name, (1, 1, 1), np.eye(4), color, "Poly", plain)
        p.polys = [np.array(f, float) for f in faces]
        if bone is None:
            cy = np.concatenate(p.polys)[:, 1].mean()
            bone = "top" if cy > SPLIT else "bottom"
        p.bone = bone
        self.parts.append(p)
        return p

    def prism(self, name, pts2d, y0, y1, color):
        """Vertical prism over a convex (x, z) polygon."""
        bot = [(x, y0, z) for x, z in pts2d]
        top = [(x, y1, z) for x, z in pts2d]
        faces = [bot, top[::-1]]
        n = len(pts2d)
        for i in range(n):
            j = (i + 1) % n
            faces.append([bot[i], bot[j], top[j], top[i]])
        return self.poly(name, faces, color, "top" if (y0 + y1) / 2 > SPLIT else "bottom")


# ---------------------------------------------------------------- voxel

def cross_layer(egg, i, y0, y1, w, colors):
    """A '+' shaped layer: a centre bar plus two side blocks, no overlaps.
    colors = (centre, left, right)."""
    wi = min(w, snap(w * 0.6))
    egg.block(f"L{i}C", (-wi / 2, y0, -w / 2), (wi / 2, y1, w / 2), colors[0])
    if w > wi + 1e-6:
        d = (w - wi) / 2
        egg.block(f"L{i}L", (-w / 2, y0, -wi / 2), (-w / 2 + d, y1, wi / 2), colors[1])
        egg.block(f"L{i}R", (w / 2 - d, y0, -wi / 2), (w / 2, y1, wi / 2), colors[2])


def voxel_pinto():
    """1. Stepped voxel egg, cream with brown pinto patches."""
    egg = Egg()
    h = 0.4
    n = int(round(H / h))
    spots = {(1, 1): BROWN, (2, 1): BROWN, (4, 2): BROWN, (5, 2): BROWN, (6, 0): BROWN, (7, 0): BROWN}
    for i in range(n):
        y0, y1 = i * h, (i + 1) * h
        w = snap(2 * radius((y0 + y1) / 2))
        cross_layer(egg, i, y0, y1, w, [spots.get((i, k), CREAM) for k in range(3)])
    return egg


def octo_layer(egg, i, y0, y1, w, color, bone=None):
    """Octagonal slab from 3 blocks and 4 wedge corners. Names start with L<i>."""
    first = len(egg.parts)
    c = round(w / (2 + math.sqrt(2)) / 0.1) * 0.1
    a = w / 2
    egg.block(f"L{i}Mid", (-a, y0, -(a - c)), (a, y1, a - c), color)
    egg.block(f"L{i}Front", (-(a - c), y0, -a), (a - c, y1, -(a - c)), color)
    egg.block(f"L{i}Back", (-(a - c), y0, a - c), (a - c, y1, a), color)
    for sx in (-1, 1):
        for sz in (-1, 1):
            inner = (sx * (a - c), sz * (a - c))
            tri = [inner, (sx * a, sz * (a - c)), (sx * (a - c), sz * a)]
            if sx * sz < 0:
                tri = tri[::-1]
            egg.prism(f"L{i}Corner{'L' if sx < 0 else 'R'}{'F' if sz < 0 else 'B'}", tri, y0, y1, color)
    if bone:
        for p in egg.parts[first:]:
            p.bone = bone


def octo_stack():
    """2. Octagonal layers (blocks + wedge corners): orange base, cream top."""
    egg = Egg()
    n = 7
    h = H / n
    colors = [ORANGE] * 4 + [CREAM] * 3
    for i in range(n):
        y0, y1 = i * h, (i + 1) * h
        w = snap(2 * radius((y0 + y1) / 2), 0.2)
        octo_layer(egg, i, y0, y1, w, colors[i])
    return egg


def pony_egg():
    """5. Voxel egg with a pony's ears and a mane tuft: you can tell what's inside."""
    egg = Egg()
    h = 0.4
    n = int(round(H / h))
    for i in range(n):
        y0, y1 = i * h, (i + 1) * h
        w = snap(2 * radius((y0 + y1) / 2))
        col = CREAM if i < 2 else ORANGE
        cross_layer(egg, i, y0, y1, w, (col, col, col))
    top = H
    # ears: two wedge halves each, like the horse's
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * 0.45
        tri = [(x0 - 0.3, top - 0.05), (x0 + 0.3, top - 0.05), (x0, top + 0.65)]
        z0, z1 = -0.2, 0.15
        faces = [[(x, y, z0) for x, y in tri], [(x, y, z1) for x, y in tri[::-1]]]
        for a, b in ((0, 1), (1, 2), (2, 0)):
            faces.append([(tri[a][0], tri[a][1], z0), (tri[a][0], tri[a][1], z1), (tri[b][0], tri[b][1], z1), (tri[b][0], tri[b][1], z0)])
        egg.poly("Ear" + side, faces, ORANGE, "top")
        itri = [(x0 - 0.16, top + 0.05), (x0 + 0.16, top + 0.05), (x0, top + 0.42)]
        zi0, zi1 = -0.24, -0.2
        faces = [[(x, y, zi0) for x, y in itri], [(x, y, zi1) for x, y in itri[::-1]]]
        for a, b in ((0, 1), (1, 2), (2, 0)):
            faces.append([(itri[a][0], itri[a][1], zi0), (itri[a][0], itri[a][1], zi1), (itri[b][0], itri[b][1], zi1), (itri[b][0], itri[b][1], zi0)])
        egg.poly("EarIn" + side, faces, PINK, "top")
    egg.block("Tuft", (-0.2, top - 0.05, -0.1), (0.2, top + 0.35, 0.5), BROWN).bone = "top"
    return egg


def ear_half(egg, name, tri, z0, z1, color):
    """Right-triangle prism: tri is 3 (x, y) points with the right angle first,
    extruded along z. Converts to a WedgePart."""
    faces = [[(x, y, z0) for x, y in tri], [(x, y, z1) for x, y in tri[::-1]]]
    for a, b in ((0, 1), (1, 2), (2, 0)):
        faces.append([(tri[a][0], tri[a][1], z0), (tri[a][0], tri[a][1], z1), (tri[b][0], tri[b][1], z1), (tri[b][0], tri[b][1], z0)])
    return egg.poly(name, faces, color, "top")


def octo_pony():
    """6. Octo Stack styled like Pony Egg: cream base, orange body, the horse's
    ears and a mane tuft. Black plates on the crack faces read as a hollow
    shell once the top pops off (hidden inside the egg until then)."""
    egg = Egg()
    n, crack_layer = 7, 4
    h = H / n
    crack = crack_layer * h
    widths = [snap(2 * radius((i + 0.5) * h)) for i in range(n)]
    for i in range(n):
        octo_layer(egg, i, i * h, (i + 1) * h, widths[i], CREAM if i < 2 else ORANGE,
                   "top" if i >= crack_layer else "bottom")
    inner = min(widths[crack_layer - 1], widths[crack_layer]) - 0.16
    octo_layer(egg, "InsideBottom", crack, crack + 0.02, inner, BLACK, "bottom")
    octo_layer(egg, "InsideTop", crack - 0.02, crack, inner, BLACK, "top")

    b = H - 0.05  # ears sink a touch into the top layer
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * 0.35
        for half, d in (("A", -1), ("B", 1)):
            ear_half(egg, f"Ear{side}{half}", [(x0, b), (x0 + d * 0.25, b), (x0, b + 0.7)], -0.15, 0.15, ORANGE)
            ear_half(egg, f"EarIn{side}{half}", [(x0, b + 0.08), (x0 + d * 0.13, b + 0.08), (x0, b + 0.45)], -0.19, -0.15, PINK)
    egg.block("Tuft", (-0.15, b, -0.05), (0.15, H + 0.3, 0.45), BROWN).bone = "top"
    return egg


# ---------------------------------------------------------------- low poly

def rings(sides, levels, twist=False, base=0.3):
    """Vertex rings from the flat base up to (not including) the top pole."""
    out = []
    for k in range(levels):
        y = base + (H - base) * k / levels
        # ease rings toward the ends so the silhouette stays round
        r = radius(y)
        off = (math.pi / sides) * (k % 2) if twist else 0.0
        out.append([(r * math.cos(2 * math.pi * j / sides + off), y, r * math.sin(2 * math.pi * j / sides + off))
                    for j in range(sides)])
    return out


def lowpoly(sides, levels, twist, band_colors, name):
    egg = Egg()
    rs = rings(sides, levels, twist)
    pole = (0.0, H, 0.0)
    # base cap
    egg.poly("Plain" + name + "Base", [rs[0][::-1]], band_colors(0), "bottom", plain=True)
    for k in range(len(rs)):
        a = rs[k]
        faces = []
        if k + 1 < len(rs):
            b = rs[k + 1]
            for j in range(sides):
                j2 = (j + 1) % sides
                if twist:
                    if k % 2 == 0:
                        faces.append([a[j], b[j], a[j2]])
                        faces.append([a[j2], b[j], b[j2]])
                    else:
                        faces.append([a[j], b[j2], a[j2]])
                        faces.append([a[j], b[j], b[j2]])
                else:
                    faces.append([a[j], b[j], b[j2], a[j2]])
        else:
            for j in range(sides):
                faces.append([a[j], pole, a[(j + 1) % sides]])
        ymid = np.mean([p[1] for f in faces for p in f])
        # low-poly reads best as smooth plastic: no studs
        egg.poly(f"Plain{name}Band{k}", faces, band_colors(k), "top" if ymid > SPLIT else "bottom", plain=True)
    return egg


def lowpoly_smooth():
    """3. Low-poly, 8 sides x 7 bands, cream with an orange belly band."""
    return lowpoly(8, 7, False, lambda k: ORANGE if k in (1, 2) else CREAM, "Smooth")


def lowpoly_gem():
    """4. Chunky low-poly gem: 6 sides, twisted rings for triangle facets, orange with a cream tip."""
    return lowpoly(6, 4, True, lambda k: CREAM if k >= 3 else (BROWN if k == 0 else ORANGE), "Gem")


DESIGNS = [
    ("VoxelPinto", voxel_pinto),
    ("OctoStack", octo_stack),
    ("LowPolySmooth", lowpoly_smooth),
    ("LowPolyGem", lowpoly_gem),
    ("PonyEgg", pony_egg),
    ("PonyOcto", octo_pony),
]

BONES = [("egg", None, (0, 0, 0)), ("bottom", "egg", (0, 0, 0)), ("top", "egg", (0, SPLIT, 0))]


# ---------------------------------------------------------------- animations (shared)

def rotz(keys, interp="catmullrom"):
    return {"channel": "rotation", "interp": interp, "keys": [(t, (0, 0, v)) for t, v in keys]}


def animations():
    anims = {}
    # twitch: a quick wobble on the base and a tiny hop, then rest (plays on the ground)
    L = 1.2
    anims["twitch"] = (L, {
        "egg": [
            rotz([(0, 0), (0.08, 10), (0.18, -9), (0.28, 7), (0.38, -4), (0.48, 2), (0.56, 0), (L, 0)]),
            {"channel": "position", "interp": "catmullrom",
             "keys": [(0, (0, 0, 0)), (0.1, (0, 1.5, 0)), (0.22, (0, 0, 0)), (L, (0, 0, 0))]},
        ],
    })
    # hatch: shakes build up, a squash, then the top pops off and spins away
    anims["hatch"] = (2.0, {
        "egg": [
            rotz([(0, 0), (0.12, 4), (0.24, -4), (0.4, 0), (0.55, 7), (0.7, -7), (0.85, 10),
                  (1.0, -10), (1.12, 12), (1.24, -12), (1.34, 0), (2.0, 0)]),
            {"channel": "scale", "interp": "catmullrom",
             "keys": [(0, (1, 1, 1)), (1.34, (1, 1, 1)), (1.5, (0.9, 0.9, 0.9)), (1.6, (1.15, 1.15, 1.15)),
                      (1.72, (1, 1, 1)), (2.0, (1, 1, 1))]},
        ],
        "top": [
            {"channel": "position", "interp": "linear",
             "keys": [(0, (0, 0, 0)), (1.58, (0, 0, 0)), (1.7, (4, 18, 0)), (1.82, (8, 30, 0)), (1.94, (12, 34, 0)), (2.0, (13, 34, 0))]},
            {"channel": "rotation", "interp": "linear",
             "keys": [(0, (0, 0, 0)), (1.58, (0, 0, 0)), (2.0, (0, 0, -150))]},
        ],
    })
    return anims


def build(egg, name, out):
    model, groups = write_bbmodel(egg.parts, name, None, bones=BONES)
    write_animations(model, groups, animations())
    with open(os.path.join(out, name + ".bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    return model


CAM = dict(eye=(-6.5, 5.2, -7.5), target=(0, 1.7, 0), W=360, H=360, fov=34)


def lineup_frame(models, anim_name, t):
    tiles = []
    for m in models:
        anim = next((a for a in m["animations"] if a["name"] == anim_name), None) if anim_name else None
        parts = pose(m, anim, t)
        tiles.append(render(parts, **CAM))
    im = Image.new("RGB", (360 * len(tiles), 360))
    for i, t_ in enumerate(tiles):
        im.paste(t_, (360 * i, 0))
    return im


def main(out):
    os.makedirs(out, exist_ok=True)
    models = []
    for i, (name, fn) in enumerate(DESIGNS, 1):
        egg = fn()
        m = build(egg, f"Egg{i}_{name}", out)
        models.append(m)
        print(name, len(egg.parts), "parts")

    # labelled still sheet
    still = lineup_frame(models, None, 0)
    sheet = Image.new("RGB", (still.width, still.height + 40), (255, 255, 255))
    sheet.paste(still, (0, 40))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 20)
    except OSError:
        font = ImageFont.load_default()
    for i, (name, _) in enumerate(DESIGNS):
        d.text((360 * i + 12, 10), f"{i + 1}. {name}", fill=(20, 20, 20), font=font)
    sheet.save(os.path.join(out, "eggs.png"))

    fps = 20
    for anim_name, length in (("twitch", 1.2), ("hatch", 2.0)):
        frames = [lineup_frame(models, anim_name, i / fps).resize((900, 180)) for i in range(int(length * fps))]
        frames += [frames[-1]] * 6
        frames[0].save(os.path.join(out, f"{anim_name}.gif"), save_all=True, append_images=frames[1:],
                       duration=int(1000 / fps), loop=0)
        print(anim_name, len(frames), "frames")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "designs/eggs")
