"""Autumn birches for the woodland autumn maze biome (QM, Oct 13), in the plant meshes'
style (tools/plant_meshes.py): faceted convex pieces, flat shaded, studded, one colour per
piece (each piece its own MeshPart).

A birch: a slender white trunk (sometimes two) with dark bark marks, and a tall, loose
canopy of faceted lumps in QM's autumn colours: orange #F26D39 and yellow #FEEA5C (plus a
deeper red-orange, as QM listed #F26D39 twice). Four trees: tall yellow, twin orange,
small mixed, leaning red-orange.

Run: python3 tools/birch_meshes.py
Writes design/birches/<Name>.obj, design/birches/pieces/<Name>_<i>.obj (same origin;
colours in pieces/colours.txt), design/birches/birches_lineup.png and birches_scene.png.
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

OUT = os.path.join(HERE, "..", "design", "birches")
BARK = (238, 234, 226)
MARKS = (52, 46, 44)
ORANGE = (0xF2, 0x6D, 0x39)  # QM's #F26D39
YELLOW = (0xFE, 0xEA, 0x5C)  # QM's #FEEA5C
RED = (214, 72, 43)  # a deeper red-orange for variety
LEAVES = {"orange": [ORANGE, (246, 132, 72), (224, 92, 46)],
          "yellow": [YELLOW, (250, 214, 70), (255, 240, 120)],
          "mixed": [ORANGE, YELLOW, (248, 168, 64)],
          "red": [RED, ORANGE, (196, 58, 36)]}


def marks(rng, base, top, r, n):
    """Dark bark marks: short flat bands hugging the trunk between base and top."""
    base, top = np.array(base, float), np.array(top, float)
    axis = top - base
    length = np.linalg.norm(axis)
    axis /= length
    u = np.cross(axis, (1, 0, 0) if abs(axis[0]) < 0.9 else (0, 0, 1))
    u /= np.linalg.norm(u)
    v = np.cross(axis, u)
    out = []
    for i in range(n):
        t = (i + 0.5) / n + rng.uniform(-0.04, 0.04)
        c = base + axis * length * t
        rr = r * (1 - 0.4 * t)  # the trunk tapers
        a0 = rng.uniform(0, 2 * math.pi)
        span = rng.uniform(0.9, 1.5)
        hh = rng.uniform(0.18, 0.32)
        pts = []
        for a in np.linspace(a0, a0 + span, 3):
            d = u * math.cos(a) + v * math.sin(a)
            for dy in (-hh, hh):
                pts += [c + d * (rr + 0.08) + axis * dy, c + d * rr * 0.8 + axis * dy]
        out.append(np.array(pts))
    return out


def canopy(rng, centre, w, h, n, colours):
    """A tall loose canopy: n lumps scattered in an upright ellipsoid, coloured in turn."""
    groups = [[] for _ in colours]
    for i in range(n):
        a = rng.uniform(0, 2 * math.pi)
        d = rng.uniform(0.1, 0.6)
        y = rng.uniform(-0.5, 0.55)
        c = (centre[0] + math.cos(a) * d * w, centre[1] + y * h, centre[2] + math.sin(a) * d * w)
        r = rng.uniform(0.6, 0.85) * w * (1 - abs(y) * 0.5)
        groups[i % len(colours)].append(blob(rng, c, r, 11, squash=(1.0, 1.15, 1.0)))
    groups.append([blob(rng, (centre[0], centre[1] + h * 0.62, centre[2]), w * 0.45, 10, squash=(1, 1.3, 1))])
    return [("Leaves", colours[i % len(colours)], g) for i, g in enumerate(groups) if g]


def birch(rng, trunks, crown, w, h, n, leaves):
    """trunks: [(base, top, radius)]; crown: the canopy's centre."""
    wood, dots = [], []
    for base, top, r in trunks:
        wood.append(prism(rng, base, top, r, r * 0.6, 6, 0.05))
        dots += marks(rng, base, top, r, int(np.linalg.norm(np.subtract(top, base)) / 1.8))
    pieces = [("Trunk", BARK, wood), ("Marks", MARKS, dots)]
    leaf = canopy(rng, crown, w, h, n, LEAVES[leaves])
    # merge leaf groups of the same colour into one piece
    merged = {}
    for label, col, g in leaf:
        merged.setdefault(col, []).extend(g)
    return pieces + [("Leaves", col, g) for col, g in merged.items()]


def birch_tall(rng):
    """Tall yellow birch (about 9 across, 26 tall)."""
    return birch(rng, [((0, -0.4, 0), (0.4, 21, 0.2), 0.8)], (0.4, 19.5, 0.2), 4.4, 6.5, 13, "yellow")


def birch_twin(rng):
    """Twin-trunk orange birch: two stems splaying from one foot (about 12 across, 22 tall)."""
    return birch(rng, [((0, -0.4, 0), (-2.4, 17.5, 0.3), 0.7), ((0.3, -0.4, 0), (2.6, 15.5, -0.4), 0.65)],
                 (0.1, 16.2, 0.0), 5.6, 5.6, 15, "orange")


def birch_small(rng):
    """Small birch, mixed orange and yellow (about 6 across, 13 tall)."""
    return birch(rng, [((0, -0.4, 0), (-0.3, 10, 0.1), 0.5)], (-0.3, 9.6, 0.1), 3.0, 3.8, 10, "mixed")


def birch_lean(rng):
    """Leaning birch, red-orange (about 10 across, 19 tall)."""
    return birch(rng, [((0, -0.4, 0), (3.6, 15.5, 0.4), 0.7)], (3.8, 14.8, 0.4), 4.2, 4.8, 12, "red")


ITEMS = [  # name, builder, seed, label, lineup width
    ("BirchTall", birch_tall, 3, "Tall birch", 10),
    ("BirchTwin", birch_twin, 5, "Twin birch", 13),
    ("BirchSmall", birch_small, 2, "Small birch", 7),
    ("BirchLean", birch_lean, 8, "Leaning birch", 12),
]


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    for f in os.listdir(os.path.join(OUT, "pieces")):
        os.remove(os.path.join(OUT, "pieces", f))
    built = {}
    colours = ["# piece: label, RGB"]
    for name, builder, seed, _, _ in ITEMS:
        raw = builder(np.random.default_rng(seed))
        pieces = [(label, col, [hull_tris(p) for p in pts]) for label, col, pts in raw]
        built[name] = pieces
        allh = [x for _, _, hs in pieces for x in hs]
        nt = write_obj(name, allh, os.path.join(OUT, name + ".obj"))
        for i, (label, col, hs) in enumerate(pieces):
            write_obj(f"{name}_{i + 1}", hs, os.path.join(OUT, "pieces", f"{name}_{i + 1}.obj"))
            colours.append(f"{name}_{i + 1}: {label}, {col[0]}, {col[1]}, {col[2]}")
        pts = np.concatenate([np.concatenate(h) for h in allh])
        size = pts.max(0) - np.array([pts.min(0)[0], 0, pts.min(0)[2]])
        print(f"{name}: {len(pieces)} pieces, {nt} tris, {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f}")
    with open(os.path.join(OUT, "pieces", "colours.txt"), "w") as f:
        f.write("\n".join(colours) + "\n")

    partlib.GROUND = np.array((150, 170, 70), float)  # an autumn grass for the previews
    partlib.GROUND2 = np.array((132, 152, 60), float)
    k = TA.Kit()
    TA.figure(k, 0)
    items = [("", None, 4)] + [(lbl, n, w) for n, _, _, lbl, w in ITEMS]
    gap, ppst, H = 4, 22, 820
    total = sum(w for *_, w in items) + gap * (len(items) - 1)
    parts, centres = [], []
    x = -total / 2
    for label, what, w in items:
        cx = -(x + w / 2)
        if what is None:
            parts += [Part(p.name, p.size, partlib.T(cx, 0, 0) @ p.cf, p.color) for p in k.parts]
        else:
            parts += parts_of(built[what], cx, 0, 20)
        centres.append((label, cx))
        x += w + gap
    W = int((total + 6) * ppst)
    eye, target = (0, 30, -150), (0, 12, 0)
    fov = 2 * np.degrees(np.arctan(H / 2 / ppst / 152))
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
    out.save(os.path.join(OUT, "birches_lineup.png"))

    scene = (parts_of(built["BirchTall"], -10, 30, 0) + parts_of(built["BirchTwin"], 8, 26, 60)
             + parts_of(built["BirchSmall"], -2, 14, 30) + parts_of(built["BirchLean"], -22, 16, 160)
             + parts_of(built["BirchTall"], 22, 38, 200) + parts_of(built["BirchSmall"], 16, 10, 90)
             + parts_of(built["BirchTwin"], -28, 40, 300))
    scene += [Part(p.name, p.size, partlib.T(0, 0, -6) @ p.cf, p.color) for p in k.parts]
    img = render(scene, eye=(0, 22, -46), target=(0, 12, 16), W=1280, H=720, fov=60, fog=False, outline=False)
    img.save(os.path.join(OUT, "birches_scene.png"))


if __name__ == "__main__":
    main()
