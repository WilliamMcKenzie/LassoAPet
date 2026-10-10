"""Low-poly rock meshes (QM, Oct 10): plain faceted rocks, no moss or grass caps,
in the style of QM's reference (chunky chamfered prisms, flat shaded).

Each rock is a few convex "chunks" (a jittered polygon prism with a bevelled,
sloped top, wrapped in a convex hull) merged into one mesh. Units are studs,
y up, the rock's base at y = 0 (chunks sink 0.6 below so they sit in the ground).

Run: python3 tools/rock_meshes.py
Writes design/rocks/<Name>.obj (one mesh each, flat normals) and the renders
design/rocks/rocks_lineup.png and design/rocks/rocks_scene.png.
In Studio: Avatar/Home > Import 3D, pick the .obj (unit: studs), it becomes a
MeshPart; set its Color (one flat colour per rock) and Material SmoothPlastic.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.spatial import ConvexHull

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import partlib  # noqa: E402
from partlib import Part, render  # noqa: E402
import terrain_assets as TA  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "rocks")
ROCK = (172, 184, 212)  # pale blue-grey like QM's reference (set as MeshPart.Color)


def chunk(rng, x, z, r, h, sides=7, wobble=0.18, bevel=0.25, slope=(0.0, 0.0), squash=(1.0, 1.0), yaw=0.0):
    """Points of one chunk: a base ring, a shoulder ring and an inset top ring.
    r: radius, h: height, bevel: top chamfer as a fraction of r, slope: top tilt
    (rise per stud in x, z), squash: x/z stretch of the footprint."""
    pts = []
    a0 = rng.uniform(0, 2 * math.pi)
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    for i in range(sides):
        a = a0 + 2 * math.pi * i / sides + rng.uniform(-0.25, 0.25) * 2 * math.pi / sides
        rr = r * (1 + rng.uniform(-wobble, wobble))
        ux, uz = math.cos(a) * squash[0], math.sin(a) * squash[1]
        ux, uz = ux * c - uz * s, ux * s + uz * c
        top = h + slope[0] * ux * r + slope[1] * uz * r + rng.uniform(-0.08, 0.08) * h
        shoulder = top - bevel * r * rng.uniform(0.7, 1.3)
        foot = rr * rng.uniform(1.0, 1.12)  # a touch wider at the foot
        pts.append((x + ux * foot, -0.6, z + uz * foot))
        pts.append((x + ux * rr, shoulder, z + uz * rr))
        inset = rr * (1 - bevel * rng.uniform(0.8, 1.4))
        pts.append((x + ux * inset, top + rng.uniform(-0.05, 0.05) * r, z + uz * inset))
    return np.array(pts)


def hull_tris(pts):
    """Outward-facing triangles (each 3x3) of a convex point set."""
    hull = ConvexHull(pts)
    centre = pts.mean(0)
    tris = []
    for simplex in hull.simplices:
        t = pts[simplex]
        n = np.cross(t[1] - t[0], t[2] - t[0])
        if np.dot(n, t.mean(0) - centre) < 0:
            t = t[::-1]
        tris.append(t)
    return tris


# ---------------------------------------------------------------- the rocks
# Each builder returns a list of chunk point sets. Seeds are fixed so reruns match.

def pebble(rng):
    """Small: a low flat stone you ride over (about 3 x 1.4)."""
    return [chunk(rng, 0, 0, 1.6, 1.3, sides=6, bevel=0.35, slope=(0.08, 0.04), squash=(1.2, 0.9))]


def stone(rng):
    """Small: a chunky stone, a big piece with a little one at its side (about 5 x 3)."""
    return [chunk(rng, 0, 0, 2.0, 2.8, sides=7, bevel=0.3, slope=(-0.1, 0.06)),
            chunk(rng, 2.0, 0.6, 1.1, 1.4, sides=6, bevel=0.35)]


def pillar(rng):
    """Medium: a tall column, a short stub leaning on it (about 6 x 8)."""
    return [chunk(rng, 0, 0, 2.2, 8.0, sides=7, bevel=0.22, slope=(0.12, -0.05)),
            chunk(rng, 2.4, 1.0, 1.5, 3.6, sides=6, bevel=0.3, slope=(0.1, 0.0))]


def boulder(rng):
    """Medium: one round faceted lump (about 8 x 5.5)."""
    return [chunk(rng, 0, 0, 3.8, 4.6, sides=8, wobble=0.12, bevel=0.42, slope=(0.06, -0.08), squash=(1.1, 0.95)),
            chunk(rng, 1.0, -0.6, 2.6, 5.6, sides=7, bevel=0.45)]


def twins(rng):
    """Medium: two columns side by side, one taller, plus a pebble (about 9 x 7)."""
    return [chunk(rng, -1.6, 0, 2.3, 7.0, sides=7, bevel=0.22, slope=(-0.1, 0.05)),
            chunk(rng, 1.8, 0.4, 2.1, 5.0, sides=7, bevel=0.25, slope=(0.12, 0.0)),
            chunk(rng, 3.6, -1.6, 1.0, 1.6, sides=6, bevel=0.35)]


def slab(rng):
    """Medium: a wide low ledge with a step on top (about 11 x 3.5)."""
    return [chunk(rng, 0, 0, 4.0, 2.4, sides=8, bevel=0.2, slope=(0.05, 0.03), squash=(1.35, 0.85)),
            chunk(rng, -1.2, 0.3, 2.6, 3.6, sides=7, bevel=0.3, squash=(1.2, 0.9))]


def crag(rng):
    """Large: a stepped heap, tall back block, ledges and a column in front (about 18 x 13)."""
    return [chunk(rng, 0, 2.0, 6.0, 12.5, sides=8, bevel=0.2, slope=(0.08, -0.04)),
            chunk(rng, -4.8, -1.0, 4.2, 8.0, sides=7, bevel=0.22, slope=(-0.1, 0.04)),
            chunk(rng, 4.2, -2.0, 3.8, 6.0, sides=7, bevel=0.25, slope=(0.1, -0.06)),
            chunk(rng, 0.6, -4.0, 3.2, 3.6, sides=7, bevel=0.3),
            chunk(rng, -7.6, -3.6, 1.6, 2.2, sides=6, bevel=0.35)]


def cliff(rng):
    """Large: a big wall-side rock, one huge faceted block with stepped shoulders
    (about 26 x 18); for the base's corners and wall shelves."""
    return [chunk(rng, 2.0, 2.0, 9.5, 17.0, sides=7, wobble=0.1, bevel=0.3, slope=(0.1, -0.06), squash=(1.1, 0.9)),
            chunk(rng, -6.5, 0.0, 6.0, 11.0, sides=7, bevel=0.22, slope=(-0.12, 0.05)),
            chunk(rng, -10.5, -3.0, 3.6, 5.0, sides=7, bevel=0.28),
            chunk(rng, 8.0, -5.0, 4.0, 6.5, sides=7, bevel=0.25, slope=(0.1, 0.0)),
            chunk(rng, -2.0, -6.5, 3.0, 2.6, sides=6, bevel=0.35)]


ROCKS = [  # name, builder, seed, label
    ("RockPebble", pebble, 3, "Pebble (small)"),
    ("RockStone", stone, 11, "Stone (small)"),
    ("RockPillar", pillar, 5, "Pillar (medium)"),
    ("RockBoulder", boulder, 8, "Boulder (medium)"),
    ("RockTwins", twins, 21, "Twins (medium)"),
    ("RockSlab", slab, 4, "Slab (medium)"),
    ("RockCrag", crag, 17, "Crag (large)"),
    ("RockCliff", cliff, 9, "Cliff (large)"),
]


def build(builder, seed):
    """The rock's chunks as triangle lists, recentred so its footprint is centred on x/z."""
    chunks = builder(np.random.default_rng(seed))
    allp = np.concatenate(chunks)
    mid = (allp.min(0) + allp.max(0)) / 2
    shift = np.array([mid[0], 0, mid[2]])
    return [hull_tris(c - shift) for c in chunks]


def write_obj(name, chunks, path):
    """One OBJ per rock, every face with its own normal (flat shading in Roblox)."""
    lines = [f"# {name}: low-poly rock, studs, y up, base at y=0", f"o {name}"]
    vn = []
    nv = 0
    faces = []
    for tris in chunks:
        for t in tris:
            n = np.cross(t[1] - t[0], t[2] - t[0])
            n /= np.linalg.norm(n)
            for v in t:
                lines.append("v %.4f %.4f %.4f" % tuple(v))
            vn.append("vn %.4f %.4f %.4f" % tuple(n))
            faces.append((nv + 1, nv + 2, nv + 3, len(vn)))
            nv += 3
    lines += vn
    lines += ["f %d//%d %d//%d %d//%d" % (a, k, b, k, c, k) for a, b, c, k in faces]
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    return len(faces)


def as_parts(chunks, dx=0.0, dz=0.0, yaw=0.0, color=ROCK):
    """Poly parts for partlib.render (one per convex chunk so normals face out)."""
    cf = partlib.T(dx, 0, dz) @ partlib.Ry(yaw)
    out = []
    for tris in chunks:
        p = Part("Rock", (1, 1, 1), cf, color, shape="Poly", plain=True)
        p.polys = [t for t in tris]
        out.append(p)
    return out


def font(size):
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def main():
    os.makedirs(OUT, exist_ok=True)
    built = []
    for name, builder, seed, label in ROCKS:
        chunks = build(builder, seed)
        nt = write_obj(name, chunks, os.path.join(OUT, name + ".obj"))
        pts = np.concatenate([np.concatenate(t) for t in chunks])
        size = pts.max(0) - np.array([pts.min(0)[0], 0, pts.min(0)[2]])
        built.append((name, label, chunks, size))
        print(f"{name}: {nt} tris, {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f} studs")

    partlib.GROUND = np.array((105, 255, 74), float)  # the meadow grass checker
    partlib.GROUND2 = np.array((77, 196, 63), float)

    # lineup: smallest to largest with a 5-stud figure for scale, long lens
    gap, ppst, H = 4, 18, 520
    widths = [4] + [max(s[0], s[2]) for _, _, _, s in built]
    total = sum(widths) + gap * (len(widths) - 1)
    parts, centres = [], []
    x = -total / 2
    k = TA.Kit()
    TA.figure(k, -(x + 2))
    parts += k.parts
    x += 4 + gap
    for (name, label, chunks, size), w in zip(built, widths[1:]):
        cx = -(x + w / 2)
        parts += as_parts(chunks, cx, 0, yaw=20)
        centres.append((label, cx))
        x += w + gap
    W = int((total + 6) * ppst)
    eye, target = (0, 70, -170), (0, 9, 0)
    fov = 2 * np.degrees(np.arctan(H / 2 / ppst / 185))
    img = render(parts, eye=eye, target=target, W=W, H=H, fov=fov, fog=False, outline=False)
    e, r, u, f = partlib.look_at(eye, target)
    focal = (H / 2) / np.tan(np.radians(fov) / 2)
    band = 34
    out = Image.new("RGB", (W, H + band), (255, 255, 255))
    out.paste(img, (0, band))
    d = ImageDraw.Draw(out)
    for label, cx in centres:
        dv = np.array([cx, 0, 0]) - e
        px = W / 2 + focal * (dv @ r) / (dv @ f)
        tw = d.textlength(label, font=font(15))
        d.text((px - tw / 2, 9), label, fill=(20, 20, 20), font=font(15))
    out.save(os.path.join(OUT, "rocks_lineup.png"))

    # scene: a cluster like the old meadow ones, from a rider's height
    by = {n: c for n, _, c, _ in built}
    scene = (as_parts(by["RockCrag"], 8, 10, 15) + as_parts(by["RockPillar"], -4, 6, 70)
             + as_parts(by["RockStone"], -9, -2, 30) + as_parts(by["RockPebble"], 1, -4, 0)
             + as_parts(by["RockPebble"], -14, 3, 120) + as_parts(by["RockTwins"], 22, 2, -40)
             + as_parts(by["RockSlab"], -20, 12, 10) + as_parts(by["RockBoulder"], 30, 16, 50))
    k = TA.Kit()
    TA.figure(k, 6)
    k2 = [Part(p.name, p.size, partlib.T(0, 0, -10) @ p.cf, p.color) for p in k.parts]
    img = render(scene + k2, eye=(-6, 22, -55), target=(4, 4, 6), W=1280, H=720, fov=40, fog=False, outline=False)
    img.save(os.path.join(OUT, "rocks_scene.png"))


if __name__ == "__main__":
    main()
