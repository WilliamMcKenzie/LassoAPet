"""Shared pipeline for the World 3 biome prop sets (QM, Oct 14): build every item, write the
whole-item OBJ and one OBJ per colour piece (same origin) plus colours.txt, and render a
labelled lineup with a Roblox figure for scale. Same style and helpers as pirate_meshes.py.

Each set script defines ITEMS = [(name, builder, seed, label)] where builder(rng) returns
[(piece label, (r, g, b), [point sets])], every point set hulled as one convex chunk.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import partlib  # noqa: E402
from partlib import Part, render  # noqa: E402
import terrain_assets as TA  # noqa: E402
from rock_meshes import hull_tris, write_obj, font  # noqa: E402
from plant_meshes import blob, prism, parts_of  # noqa: E402

# ---------------------------------------------------------------- shape helpers


def rot_y(pts, yaw, c=(0, 0, 0)):
    ca, sa = math.cos(yaw), math.sin(yaw)
    p = np.asarray(pts, float) - c
    return np.stack([p[:, 0] * ca - p[:, 2] * sa, p[:, 1], p[:, 0] * sa + p[:, 2] * ca], 1) + c


def rot_x(pts, a, c=(0, 0, 0)):
    ca, sa = math.cos(a), math.sin(a)
    p = np.asarray(pts, float) - c
    return np.stack([p[:, 0], p[:, 1] * ca - p[:, 2] * sa, p[:, 1] * sa + p[:, 2] * ca], 1) + c


def rot_z(pts, a, c=(0, 0, 0)):
    ca, sa = math.cos(a), math.sin(a)
    p = np.asarray(pts, float) - c
    return np.stack([p[:, 0] * ca - p[:, 1] * sa, p[:, 0] * sa + p[:, 1] * ca, p[:, 2]], 1) + c


def move(sets, fn):
    return [fn(np.asarray(s, float)) for s in sets]


def ball(c, r, n=14, squash=(1.0, 1.0, 1.0)):
    """A clean faceted ball (no jitter)."""
    return blob(np.random.default_rng(0), c, r, n, squash=squash, jitter=0.0)


def disc(c, r, t, n=12, axis="y", a0=0.0):
    """A flat round plate of thickness t centred at c, its face along axis."""
    pts = []
    for i in range(n):
        a = a0 + 2 * math.pi * i / n
        u, v = math.cos(a) * r, math.sin(a) * r
        for w in (-t / 2, t / 2):
            if axis == "y":
                pts.append((c[0] + u, c[1] + w, c[2] + v))
            elif axis == "x":
                pts.append((c[0] + w, c[1] + u, c[2] + v))
            else:
                pts.append((c[0] + u, c[1] + v, c[2] + w))
    return np.array(pts)


def tube(rng, path, r0, r1, sides=7, wobble=0.0):
    """A bent tube: one tapered prism per path segment, overlapping a little."""
    path = [np.asarray(p, float) for p in path]
    n = len(path) - 1
    out = []
    for i in range(n):
        a = r0 + (r1 - r0) * i / n
        b = r0 + (r1 - r0) * (i + 1) / n
        d = path[i + 1] - path[i]
        out.append(prism(rng, path[i] - d * 0.06, path[i + 1] + d * 0.02, a, b, sides, wobble))
    return out


def torus(c, R, r, n=12, m=6, axis="y", arc=(0.0, 2 * math.pi)):
    """A ring of n convex segments (each a short tube of m sides), lying flat (axis y) or
    standing (axis z: in the x-y plane)."""
    segs = []
    for i in range(n):
        a0 = arc[0] + (arc[1] - arc[0]) * i / n
        a1 = arc[0] + (arc[1] - arc[0]) * (i + 1) / n
        pts = []
        for a in (a0, a1):
            ca, sa = math.cos(a), math.sin(a)
            for j in range(m):
                b = 2 * math.pi * j / m
                rr = R + r * math.cos(b)
                h = r * math.sin(b)
                if axis == "y":
                    pts.append((c[0] + ca * rr, c[1] + h, c[2] + sa * rr))
                else:
                    pts.append((c[0] + ca * rr, c[1] + sa * rr, c[2] + h))
        segs.append(np.array(pts))
    return segs


# ---------------------------------------------------------------- pipeline


def build_set(out_dir, items):
    os.makedirs(os.path.join(out_dir, "pieces"), exist_ok=True)
    for f in os.listdir(os.path.join(out_dir, "pieces")):
        os.remove(os.path.join(out_dir, "pieces", f))
    built, sizes = {}, {}
    colours = ["# piece: label, RGB"]
    for name, builder, seed, _ in items:
        raw = builder(np.random.default_rng(seed))
        pieces = [(label, col, [hull_tris(np.asarray(p, float)) for p in pts]) for label, col, pts in raw]
        allh = [x for _, _, hs in pieces for x in hs]
        pts = np.concatenate([np.concatenate(h) for h in allh])
        lo, hi = pts.min(0), pts.max(0)
        # centre on x/z; the builder puts the base on y=0 (a little may sink below it)
        shift = np.array((-(lo[0] + hi[0]) / 2, 0.0, -(lo[2] + hi[2]) / 2))
        pieces = [(label, col, [[t + shift for t in tris] for tris in hs]) for label, col, hs in pieces]
        allh = [x for _, _, hs in pieces for x in hs]
        built[name] = pieces
        nt = write_obj(name, allh, os.path.join(out_dir, name + ".obj"))
        for i, (label, col, hs) in enumerate(pieces):
            write_obj(f"{name}_{i + 1}", hs, os.path.join(out_dir, "pieces", f"{name}_{i + 1}.obj"))
            colours.append(f"{name}_{i + 1}: {label}, {col[0]}, {col[1]}, {col[2]}")
        size = hi - np.array((lo[0], 0.0, lo[2]))  # height above the ground
        sizes[name] = (size, nt, len(pieces))
        print(f"{name}: {len(pieces)} pieces, {nt} tris, {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f}")
    with open(os.path.join(out_dir, "pieces", "colours.txt"), "w") as f:
        f.write("\n".join(colours) + "\n")
    with open(os.path.join(out_dir, "sizes.txt"), "w") as f:
        f.write("# name: width x height x depth (studs, at 1x), tris, pieces\n")
        for name, (s, nt, np_) in sizes.items():
            f.write(f"{name}: {s[0]:.1f} x {s[1]:.1f} x {s[2]:.1f}, {nt} tris, {np_} pieces\n")
    return built, sizes


def lineup_row(built, sizes, row, ground, ppst=22, yaw=20, eye_h=None):
    """Render one row of items, left to right, with a figure first; returns an image."""
    partlib.GROUND = np.array(ground[0], float)
    partlib.GROUND2 = np.array(ground[1], float)
    k = TA.Kit()
    TA.figure(k, 0)
    entries = [("", None, 4)]
    for name, label in row:
        s = sizes[name][0]
        w = max(s[0], s[2]) * 0.92 + 1
        entries.append((label, name, w))
    gap = 3
    total = sum(w for *_, w in entries) + gap * (len(entries) - 1)
    tall = max([sizes[n][0][1] for n, _ in row] + [6])
    parts, centres = [], []
    x = -total / 2
    for label, what, w in entries:
        cx = -(x + w / 2)
        if what is None:
            parts += [Part(p.name, p.size, partlib.T(cx, 0, 0) @ p.cf, p.color) for p in k.parts]
        else:
            parts += parts_of(built[what], cx, 0, yaw)
        centres.append((label, cx))
        x += w + gap
    H = int(min(900, max(360, (tall + 6) * ppst)))
    W = int((total + 6) * ppst)
    dist = 150 + tall * 2
    eye, target = (0, tall * 0.55 + 14, -dist), (0, tall * 0.45, 0)
    fov = 2 * np.degrees(np.arctan(H / 2 / ppst / dist))
    img = render(parts, eye=eye, target=target, W=W, H=H, fov=fov, fog=False, outline=False)
    e, r, u, f = partlib.look_at(eye, target)
    focal = (H / 2) / np.tan(np.radians(fov) / 2)
    out = Image.new("RGB", (W, H + 34), (255, 255, 255))
    out.paste(img, (0, 34))
    d = ImageDraw.Draw(out)
    for label, cx in centres:
        dv = np.array([cx, 0, 0]) - e
        px = W / 2 + focal * (dv @ r) / (dv @ f)
        tw = d.textlength(label, font=font(16))
        d.text((px - tw / 2, 9), label, fill=(20, 20, 20), font=font(16))
    return out


def stack(images, path, title=None):
    W = max(i.width for i in images)
    top = 44 if title else 0
    H = sum(i.height for i in images) + top
    out = Image.new("RGB", (W, H), (255, 255, 255))
    y = top
    if title:
        ImageDraw.Draw(out).text((14, 10), title, fill=(20, 20, 20), font=font(24))
    for i in images:
        out.paste(i, ((W - i.width) // 2, y))
        y += i.height
    out.save(path)
