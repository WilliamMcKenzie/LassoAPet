"""Crystals and fungi (QM, Oct 13), in the rock meshes' style: faceted convex pieces,
flat shaded, studded, one colour per piece (each piece its own MeshPart).

Fungi: QM's purple caps #86538E with white spots, stems #836267; large, medium and a
small cluster of three. Crystals: clusters of pointed hexagonal prisms in QM's cyan
#00BEE7 and pink #E583FB, in three sizes: medium, large, XXL (each colour a main shade
and a lighter one).

Run: python3 tools/crystal_meshes.py
Writes design/crystals/<Name>.obj, design/crystals/pieces/<Name>_<i>.obj (same origin;
colours in pieces/colours.txt), design/crystals/crystals_lineup.png and crystals_scene.png.
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
from plant_meshes import blob, parts_of  # noqa: E402
import crimson_meshes as CM  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "crystals")
CAP = (0x86, 0x53, 0x8E)  # QM's #86538E
CAP_UNDER = (96, 56, 104)
STEM = (0x83, 0x62, 0x67)  # QM's #836267
SPOT = (250, 248, 252)
CYAN = [(0x00, 0xBE, 0xE7), (90, 220, 245)]  # QM's #00BEE7 and a lighter facet shade
PINK = [(0xE5, 0x83, 0xFB), (242, 170, 253)]  # QM's #E583FB and a lighter one


def surface_y(tris, x, z):
    """The highest point of a hull's surface straight above (x, z), or None."""
    best = None
    for t in tris:
        (ax, ay, az), (bx, by, bz), (cx, cy, cz) = t
        den = (bz - cz) * (ax - cx) + (cx - bx) * (az - cz)
        if abs(den) < 1e-9:
            continue
        l0 = ((bz - cz) * (x - cx) + (cx - bx) * (z - cz)) / den
        l1 = ((cz - az) * (x - cx) + (ax - cx) * (z - cz)) / den
        l2 = 1 - l0 - l1
        if min(l0, l1, l2) >= -1e-6:
            y = l0 * ay + l1 * by + l2 * cy
            best = y if best is None else max(best, y)
    return best


def fungus(rng, h, cap_r, stem_r, bend, spots, x=0.0, z=0.0):
    """Crimson_meshes' mushroom in QM's purple, with white spots sat on the cap."""
    m = CM.mushroom(rng, h, cap_r, stem_r, bend=bend)
    colour = {"Stem": STEM, "Cap": CAP, "Underside": CAP_UNDER}
    out = [(label, colour[label], [p + (x, 0, z) for p in pts]) for label, _, pts in m]
    cap = hull_tris(out[1][2][0])
    centre = out[1][2][0].mean(0)
    dots = []
    for i in range(spots):
        a = 2 * math.pi * i / spots + rng.uniform(-0.3, 0.3)
        d = cap_r * (0.4 + 0.3 * (i % 2)) * rng.uniform(0.9, 1.1)
        px, pz = centre[0] + math.cos(a) * d, centre[2] + math.sin(a) * d
        y = surface_y(cap, px, pz)
        if y is not None:
            r = cap_r * rng.uniform(0.17, 0.21)
            dots.append(blob(rng, (px, y - r * 0.15, pz), r, 8, squash=(1.0, 0.55, 1.0), jitter=0.05))
    centre_y = surface_y(cap, centre[0], centre[2])
    r = cap_r * 0.19
    dots.append(blob(rng, (centre[0], centre_y - r * 0.15, centre[2]), r, 8, squash=(1.0, 0.55, 1.0), jitter=0.05))
    return out + [("Spots", SPOT, dots)]


def fungus_large(rng):
    """Large fungus (about 12 across, 14 tall)."""
    return fungus(rng, 10.0, 6.0, 1.0, 1.8, 7)


def fungus_medium(rng):
    """Medium fungus (about 7 across, 7.5 tall)."""
    return fungus(rng, 5.5, 3.4, 0.6, 0.9, 5)


def fungus_cluster(rng):
    """Three small fungi growing together (about 5 across, 4 tall)."""
    out = {}
    for h, cr, sr, b, n, x, z in ((3.4, 1.7, 0.32, 0.4, 4, 0, 0), (2.4, 1.2, 0.25, -0.4, 3, -1.9, 0.9),
                                  (1.7, 0.9, 0.2, 0.3, 3, 1.4, 1.3)):
        for label, col, pts in fungus(rng, h, cr, sr, b, n, x, z):
            out.setdefault(label, (col, []))[1].extend(pts)
    return [(label, col, pts) for label, (col, pts) in out.items()]


def shard(rng, base, direction, length, r, sides=6):
    """A crystal: a hexagonal prism from base along direction, ending in a point."""
    d = np.array(direction, float)
    d /= np.linalg.norm(d)
    u = np.cross(d, (1, 0, 0) if abs(d[0]) < 0.9 else (0, 0, 1))
    u /= np.linalg.norm(u)
    v = np.cross(d, u)
    base = np.array(base, float)
    shoulder = base + d * length * 0.78
    tip = base + d * length
    a0 = rng.uniform(0, math.pi)
    pts = [tip]
    for i in range(sides):
        a = a0 + 2 * math.pi * i / sides
        o = (u * math.cos(a) + v * math.sin(a)) * r
        pts += [base + o * 0.92 - d * 0.6, shoulder + o]
    return np.array(pts)


def crystals(rng, scale, colours, n):
    """A cluster: one tall shard in the middle, n - 1 shorter ones leaning out round it,
    alternating the main and the light shade."""
    groups = [[], []]
    groups[0].append(shard(rng, (0, 0, 0), (rng.uniform(-0.1, 0.1), 1, rng.uniform(-0.1, 0.1)), 6.0 * scale, 0.9 * scale))
    for i in range(1, n):
        a = 2 * math.pi * i / (n - 1) + rng.uniform(-0.3, 0.3)
        lean = rng.uniform(0.35, 0.8)
        d = (math.cos(a) * lean, 1, math.sin(a) * lean)
        off = np.array((math.cos(a), 0, math.sin(a))) * 0.7 * scale
        groups[i % 2].append(shard(rng, off, d, rng.uniform(2.4, 4.4) * scale, rng.uniform(0.45, 0.7) * scale))
    return [("Crystal", colours[0], groups[0]), ("Crystal", colours[1], groups[1])]


ITEMS = [  # name, builder, seed, label, lineup width
    ("FungusLarge", fungus_large, 4, "Large fungus", 13),
    ("FungusMedium", fungus_medium, 2, "Medium fungus", 8),
    ("FungusCluster", fungus_cluster, 6, "Fungus cluster", 6),
]
for colour_name, cols in (("Cyan", CYAN), ("Pink", PINK)):
    for size, scale, n, w in (("Medium", 1.0, 5, 7), ("Large", 2.0, 6, 12), ("XXL", 4.0, 7, 22)):
        ITEMS.append((f"Crystal{colour_name}{size}",
                      (lambda s, c, k: (lambda rng: crystals(rng, s, c, k)))(scale, cols, n),
                      {"Medium": 11, "Large": 12, "XXL": 13}[size] + (0 if colour_name == "Cyan" else 10),
                      f"{colour_name} crystal ({size})", w))


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    for f in os.listdir(os.path.join(OUT, "pieces")):
        os.remove(os.path.join(OUT, "pieces", f))
    built = {}
    colours = ["# piece: label, RGB (crystals: Glass or Neon in game might suit them)"]
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

    partlib.GROUND = np.array((84, 70, 96), float)  # a dusky cave floor for the previews
    partlib.GROUND2 = np.array((72, 60, 84), float)
    k = TA.Kit()
    TA.figure(k, 0)
    items = [("", None, 4)] + [(lbl, n, w) for n, _, _, lbl, w in ITEMS]
    gap, ppst, H = 3, 16, 760
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
    eye, target = (0, 40, -230), (0, 11, 0)
    fov = 2 * np.degrees(np.arctan(H / 2 / ppst / 232))
    img = render(parts, eye=eye, target=target, W=W, H=H, fov=fov, fog=False, outline=False)
    e, r, u, f = partlib.look_at(eye, target)
    focal = (H / 2) / np.tan(np.radians(fov) / 2)
    out = Image.new("RGB", (W, H + 52), (255, 255, 255))
    out.paste(img, (0, 52))
    d = ImageDraw.Draw(out)
    for i, (label, cx) in enumerate(centres):
        dv = np.array([cx, 0, 0]) - e
        px = W / 2 + focal * (dv @ r) / (dv @ f)
        tw = d.textlength(label, font=font(14))
        d.text((px - tw / 2, 6 + 22 * (i % 2)), label, fill=(20, 20, 20), font=font(14))
    out.save(os.path.join(OUT, "crystals_lineup.png"))

    rng = np.random.default_rng(5)
    scene = (parts_of(built["CrystalCyanXXL"], -14, 34, 0) + parts_of(built["CrystalPinkLarge"], 12, 22, 40)
             + parts_of(built["FungusLarge"], 2, 26, 60) + parts_of(built["CrystalPinkXXL"], 26, 40, 100)
             + parts_of(built["CrystalCyanLarge"], -20, 14, 10) + parts_of(built["FungusMedium"], -6, 12, 200)
             + parts_of(built["CrystalCyanMedium"], 8, 6, 0) + parts_of(built["CrystalPinkMedium"], -12, 2, 30)
             + parts_of(built["FungusCluster"], 16, 2, 80) + parts_of(built["FungusCluster"], -2, 0, 250))
    scene += [Part(p.name, p.size, partlib.T(2, 0, -8) @ p.cf, p.color) for p in k.parts]
    img = render(scene, eye=(0, 26, -52), target=(0, 10, 16), W=1280, H=720, fov=58, fog=False, outline=False)
    img.save(os.path.join(OUT, "crystals_scene.png"))


if __name__ == "__main__":
    main()
