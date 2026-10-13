"""The Monarch: a World 2 boss (QM, Oct 13: "an insanely cool butterfly boss, giant monarch
butterfly"). A huge monarch flying low: a black body (head, thorax and a tapering abdomen
dotted white), big googly eyes, two long antennae with clubbed tips, six thin legs tucked
under, and four wings spread flat: bright orange panels split by thick black veins, inside a
wide black border with two rows of white dots, the forewing tips black with orange and white
spots. The wings are blocks on a grid (merged into big rectangles), 0.6 studs thick.

Run: python3 tools/butterfly_boss.py [out_dir] [--gif]

Built in Blockbench's ZYX Euler order; every bone rests at 0 (tilts baked into the cubes).
Bones: root (the thorax, where it floats) -> neck (the head: eyes, antennae) ;
root -> WingFL, WingFR (forewings), WingBL, WingBR (hindwings): flap about Z ;
root -> Abdomen.

  idle    hovers, wings beating slowly, the abdomen swaying
  walk    faster beats
  gallop  big fast beats, nosing down into the chase
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402

horse_rig.EULER = "ZYX"
import snake_design as S  # noqa: E402
import angel_boss as AB  # noqa: E402  (box, axis_rot)
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "Monarch"
MODEL = os.path.join(ROOT, "designs", "bosses", NAME + ".bbmodel")
TAU = 2 * math.pi

COLORS = {"orange": (246, 134, 20), "light": (255, 176, 52), "black": (26, 22, 26), "white": (255, 255, 255),
          "body": (34, 30, 36), "pupil": (16, 16, 20)}
TEX = {n: i for i, n in enumerate(COLORS)}
box = AB.box

HOVER = 9.0  # the thorax's centre, before floor() sets the lowest point GAP over y = 0
GAP = 8.0  # high enough that the downstroke clears the ground
CELL = 1.25  # wing grid
THICK = 0.6
# wing outlines (right side: x out from the body, z back; studs from the wing root)
FORE = [(0.0, -1.0), (4.0, -7.5), (11.0, -12.0), (19.0, -13.5), (22.5, -11.5), (22.0, -6.0), (16.0, 1.5),
        (8.0, 2.5), (0.0, 1.5)]
HIND = [(0.0, 0.5), (8.0, 0.5), (14.5, 3.0), (17.0, 7.5), (15.0, 13.0), (9.5, 16.0), (4.5, 14.0), (0.0, 7.0)]
# veins: lines from the root (0, 0) out to these points
FORE_VEINS = [(20.0, -12.5), (17.0, -6.5), (14.0, -1.0), (7.0, -9.5)]
HIND_VEINS = [(15.5, 6.0), (13.0, 11.5), (8.0, 14.5), (16.0, 2.5)]
ROOT_X = 1.4  # wing roots this far out from the body's middle
DIHEDRAL = 14.0  # degrees the wings rest raised


def inside(poly, x, z):
    c = False
    for (x1, z1), (x2, z2) in zip(poly, poly[1:] + poly[:1]):
        if (z1 > z) != (z2 > z) and x < (x2 - x1) * (z - z1) / (z2 - z1) + x1:
            c = not c
    return c


def seg_dist(p, a, b):
    p, a, b = (np.array(v, float) for v in (p, a, b))
    t = np.clip((p - a) @ (b - a) / ((b - a) @ (b - a)), 0, 1)
    return np.linalg.norm(p - a - t * (b - a))


def wing_grid(poly, veins, fore):
    """Colour per cell: None outside, else a texture name."""
    xs = [p[0] for p in poly]
    zs = [p[1] for p in poly]
    nx = int(math.ceil((max(xs) - min(xs)) / CELL)) + 1
    nz = int(math.ceil((max(zs) - min(zs)) / CELL)) + 1
    x0, z0 = min(xs), min(zs)
    cen = lambda i, j: (x0 + (i + 0.5) * CELL, z0 + (j + 0.5) * CELL)  # noqa: E731
    ins = [[inside(poly, *cen(i, j)) for j in range(nz)] for i in range(nx)]

    def depth(i, j):  # cells to the nearest outside cell (Chebyshev), up to 4
        for d in range(1, 5):
            for di in range(-d, d + 1):
                for dj in range(-d, d + 1):
                    ii, jj = i + di, j + dj
                    if not (0 <= ii < nx and 0 <= jj < nz) or not ins[ii][jj]:
                        return d
        return 5

    grid = {}
    for i in range(nx):
        for j in range(nz):
            if not ins[i][j]:
                continue
            x, z = cen(i, j)
            d = depth(i, j)
            near_root = x < 1.5
            if d <= 2 and not near_root:
                # the black border, a row of white dots along it
                col = "white" if d == 2 and (i + j) % 3 == 0 else "black"
            elif fore and x > 16 and z < -5 and d <= 4:
                col = "light" if (i + 2 * j) % 5 == 0 else "black"  # the black wingtip, a few spots
            elif any(seg_dist((x, z), (0, 0), v) < 0.45 for v in veins) or near_root:
                col = "black"
            else:
                col = "orange" if math.hypot(x, z) > 6 else "light"
            grid[(i, j)] = col
    return grid, x0, z0


def rects(grid):
    """Greedy merge of same-colour cells into rectangles: (i, j, w, h, colour)."""
    done, out = set(), []
    for (i, j) in sorted(grid, key=lambda c: (c[1], c[0])):
        if (i, j) in done:
            continue
        col = grid[(i, j)]
        w = 1
        while (i + w, j) in grid and grid[(i + w, j)] == col and (i + w, j) not in done:
            w += 1
        h = 1
        while all((i + k, j + h) in grid and grid[(i + k, j + h)] == col and (i + k, j + h) not in done
                  for k in range(w)):
            h += 1
        for k in range(w):
            for m in range(h):
                done.add((i + k, j + m))
        out.append((i, j, w, h, col))
    return out


def build():
    elements, groups = [], []

    def add_group(name, pivot, parent):
        g = S.group(name, pivot)
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    y0 = HOVER
    root = add_group("root", (0, y0, 0), None)
    # thorax: a fat black block with a few white flecks on the shoulders
    put(root, [box("Thorax", (0, y0, 0), (3.4, 3.2, 5.0), TEX["body"]),
               box("ThoraxTop", (0, y0 + 1.7, 0.2), (2.6, 0.4, 3.8), TEX["body"])])
    for s in (-1, 1):
        put(root, [box(f"Fleck{'LR'[s > 0]}", (s * 1.2, y0 + 1.55, -1.6), (0.5, 0.3, 0.5), TEX["white"])])

    # head with googly eyes and clubbed antennae
    neck = add_group("neck", (0, y0, -2.5), root)
    hz = -4.2
    put(neck, [box("Head", (0, y0 + 0.2, hz), (3.0, 2.8, 2.6), TEX["body"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        put(neck, [box(f"Eye{n}", (s * 1.25, y0 + 0.7, hz - 1.0), (1.6, 1.8, 0.5), TEX["white"]),
                   box(f"Pupil{n}", (s * 1.3, y0 + 0.5, hz - 1.3), (0.8, 0.9, 0.2), TEX["pupil"])])
        # antenna: up and forward, splayed out (one tilt about X, then a turn about Z)
        M = AB.axis_rot("z", -s * 22) @ AB.axis_rot("x", 38)
        d = M @ np.array([0, 1.0, 0])
        base = np.array([s * 0.7, y0 + 1.5, hz - 0.2])
        L = 8.0
        put(neck, [box(f"Antenna{n}", base + d * L / 2, (0.35, L, 0.35), TEX["body"], M),
                   box(f"AntennaClub{n}", base + d * (L + 0.4), (0.8, 1.3, 0.8), TEX["body"], M),
                   box(f"AntennaTip{n}", base + d * (L + 1.1), (0.6, 0.3, 0.6), TEX["light"], M)])

    # abdomen: tapering segments, white dots down the sides
    abd = add_group("Abdomen", (0, y0, 2.5), root)
    parts, z = [], 2.5
    for k, (w, L) in enumerate(((2.8, 2.2), (2.6, 2.2), (2.3, 2.1), (1.9, 2.0), (1.4, 1.8))):
        parts.append(box(f"Abdomen{k + 1}", (0, y0 - 0.2 - 0.25 * k, z + L / 2), (w, w * 0.95, L + 0.1), TEX["body"]))
        for s in (-1, 1):
            parts.append(box(f"Dot{k + 1}{'LR'[s > 0]}", (s * (w / 2 + 0.05), y0 - 0.2 - 0.25 * k, z + L / 2),
                             (0.2, 0.45, 0.45), TEX["white"]))
        z += L
    put(abd, parts)

    # six thin legs tucked under, angled back
    for s in (-1, 1):
        for k, zz in enumerate((-1.5, 0.0, 1.5)):
            M = AB.axis_rot("z", s * 25) @ AB.axis_rot("x", -25 + 15 * k)
            d = M @ np.array([0, -1.0, 0])
            base = np.array([s * 1.2, y0 - 1.4, zz])
            put(root, [box(f"Leg{'LR'[s > 0]}{k + 1}", base + d * 1.8, (0.3, 3.6, 0.3), TEX["body"], M)])

    # the wings
    for wname, poly, veins, fore, dz, dy in (("WingF", FORE, FORE_VEINS, True, -0.5, 0.15),
                                             ("WingB", HIND, HIND_VEINS, False, 0.6, -0.15)):
        grid, gx0, gz0 = wing_grid(poly, veins, fore)
        rs = rects(grid)
        for s in (-1, 1):
            n = "LR"[s > 0]
            pivot = np.array([s * ROOT_X, y0 + 0.6, dz])
            node = add_group(wname + n, pivot, root)
            M = AB.axis_rot("z", s * DIHEDRAL)  # raised in a shallow V, baked into the blocks
            parts = []
            for k, (i, j, w, h, col) in enumerate(rs):
                cx = gx0 + (i + w / 2) * CELL
                cz = gz0 + (j + h / 2) * CELL
                c = pivot + M @ np.array([s * cx, dy, cz])
                parts.append(box(f"{wname}{n}{k + 1}", c, (w * CELL, THICK, h * CELL), TEX[col], M))
            put(node, parts)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def floor(model):
    lo = min(q[:, 1].min() for p in S.posed(model) for q in p.polys)
    d = (GAP - lo) * S.BB
    for e in model["elements"]:
        for k in ("from", "to", "origin"):
            if k in e:
                e[k][1] = round(e[k][1] + d, 4)
    for g in model["groups"]:
        g["origin"][1] = round(g["origin"][1] + d, 4)
    return GAP - lo


def animations():
    def flap(L, amp, bias, beats, lag=0.5, n=32):
        out = {}
        for w, ph in (("WingF", 0.0), ("WingB", lag)):
            for s, n_ in ((1, "R"), (-1, "L")):
                out[w + n_] = [track(L, lambda u, s=s, ph=ph: (
                    0, 0, s * (bias + amp * math.sin(TAU * beats * u - ph))), n)]
        return out

    L = 2.0
    idle = {**flap(L, 32, 10, 2),
            "root": [track(L, lambda u: (0, 10 * math.sin(TAU * 2 * u - 0.6), 0), 16, "position")],
            "neck": [track(L, lambda u: (4 * math.sin(TAU * u), 6 * math.sin(TAU * u), 0), 16)],
            "Abdomen": [track(L, lambda u: (6 * math.sin(TAU * 2 * u), 4 * math.sin(TAU * u), 0), 16)]}
    Lw = 1.0
    walk = {**flap(Lw, 40, 10, 2),
            "root": [track(Lw, lambda u: (-6, 0, 0), 4), track(Lw, lambda u: (0, 10 * math.sin(TAU * 2 * u - 0.6), 0), 16, "position")],
            "Abdomen": [track(Lw, lambda u: (8 * math.sin(TAU * 2 * u), 0, 0), 16)]}
    Lg = 0.5
    gallop = {**flap(Lg, 45, 15, 1, n=24),
              "root": [track(Lg, lambda u: (-14, 0, 0), 4), track(Lg, lambda u: (0, 14 * math.sin(TAU * u - 0.8), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (6, 0, 0), 4)],
              "Abdomen": [track(Lg, lambda u: (10 * math.sin(TAU * u), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


CAMS = [dict(eye=(-40, 34, -48), target=(0, 8, 0)), dict(eye=(0, 18, -62), target=(0, 9, 0)),
        dict(eye=(0, 70, 22), target=(0, 6, 0)), dict(eye=(52, 14, 6), target=(0, 8, 0))]


def main(out="/mnt/project-files/animals/bosses"):
    os.makedirs(out, exist_ok=True)
    m = build()
    shift = floor(m)
    write_animations(m, {g["name"]: g for g in m["groups"]}, animations())
    for path in (MODEL, os.path.join(out, NAME + ".bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "shift", round(shift, 3))
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([26, 0, -14]) for q in p.polys]
    parts = S.posed(m)
    Wd, Ht = 640, 520
    sheet = Image.new("RGB", (Wd * 2, Ht * 2))
    for i, cam in enumerate(CAMS):
        sheet.paste(render(parts + (hparts if i == 0 else []), W=Wd, H=Ht, fov=40, **cam), ((i % 2) * Wd, (i // 2) * Ht))
    sheet.save(os.path.join(out, NAME + ".png"))
    render(parts, W=1100, H=900, fov=40, eye=(-30, 30, -50), target=(0, 8, 0)).save(os.path.join(out, NAME + "_front.png"))
    if "--gif" in sys.argv:
        frames = []
        for name, n, loops in (("idle", 24, 1), ("walk", 12, 2), ("gallop", 8, 4)):
            anim = next(a for a in m["animations"] if a["name"] == name)
            for _ in range(loops):
                for k in range(n):
                    ps = S.posed(m, anim, anim["length"] * k / n)
                    im = Image.new("RGB", (880, 360))
                    im.paste(render(ps, W=440, H=360, fov=40, **CAMS[1]), (0, 0))
                    im.paste(render(ps, W=440, H=360, fov=40, **CAMS[0]), (440, 0))
                    frames.append(A.label(im, [name] * 2))
        A.gif(os.path.join(out, NAME + "_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
