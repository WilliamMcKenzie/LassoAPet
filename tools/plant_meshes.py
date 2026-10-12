"""Low-poly plant meshes (QM, Oct 12): a tree, a grass tuft, a simple flower and square
stone tiles (sized to sit inside a 4-stud floor checker square) in the
rock meshes' style (tools/rock_meshes.py): chunky faceted convex pieces, flat shaded,
studded (0.5-stud planar UVs), one flat colour per piece.

Each plant is a few pieces (trunk, canopy blobs; blades; stem, petals, centre), each its
own MeshPart in its own colour, like the multi-shade rocks. Studs, y up, base at y = 0.

Run: python3 tools/plant_meshes.py
Writes design/plants/<Name>.obj (whole plant), design/plants/pieces/<Name>_<i>.obj (same
origin as the whole; colours in pieces/colours.txt), design/plants/plants_lineup.png and
design/plants/plants_scene.png.
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
from rock_meshes import hull_tris, write_obj, as_parts, font  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "plants")

TRUNK = (124, 86, 56)
LEAF = [(98, 196, 72), (120, 214, 86), (86, 178, 64), (134, 224, 98)]  # canopy shades
GRASS = [(84, 192, 60), (112, 218, 78)]
STEM = (70, 150, 52)
PETALS = {"Pink": (255, 148, 190), "White": (250, 248, 240), "Yellow": (255, 214, 64)}
CENTRE = (255, 196, 40)
CENTRE_ON_YELLOW = (236, 128, 40)


def blob(rng, c, r, n=12, squash=(1.0, 1.0, 1.0), jitter=0.12):
    """A faceted lump: n points spread over a sphere (jittered), hulled."""
    pts = []
    for i in range(n):
        y = 1 - 2 * (i + 0.5) / n
        a = i * math.pi * (3 - math.sqrt(5)) + rng.uniform(-0.3, 0.3)
        s = math.sqrt(1 - y * y)
        rr = r * (1 + rng.uniform(-jitter, jitter))
        pts.append((c[0] + math.cos(a) * s * rr * squash[0], c[1] + y * rr * squash[1],
                    c[2] + math.sin(a) * s * rr * squash[2]))
    return np.array(pts)


def prism(rng, base, top, r0, r1, sides=6, wobble=0.1):
    """A tapered column from base to top (both 3-vectors)."""
    base, top = np.array(base, float), np.array(top, float)
    axis = top - base
    axis /= np.linalg.norm(axis)
    u = np.cross(axis, (1, 0, 0) if abs(axis[0]) < 0.9 else (0, 0, 1))
    u /= np.linalg.norm(u)
    v = np.cross(axis, u)
    a0 = rng.uniform(0, 2 * math.pi)
    pts = []
    for i in range(sides):
        a = a0 + 2 * math.pi * i / sides
        d = u * math.cos(a) + v * math.sin(a)
        pts.append(base + d * r0 * (1 + rng.uniform(-wobble, wobble)))
        pts.append(top + d * r1 * (1 + rng.uniform(-wobble, wobble)))
    return np.array(pts)


def blade(base, w, t, tip, yaw):
    """A flat grass blade / leaf: a w x t foot and a point at tip."""
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    bx, by, bz = base
    pts = [(bx + dx * c - dz * s, by, bz + dx * s + dz * c) for dx in (-w / 2, w / 2) for dz in (-t / 2, t / 2)]
    mid = [(bx + dx * c * 0.7 - dz * s + (tip[0] - bx) * 0.45, by + (tip[1] - by) * 0.45,
            bz + dx * s * 0.7 + dz * c + (tip[2] - bz) * 0.45) for dx in (-w / 2, w / 2) for dz in (-t / 2, t / 2)]
    return np.array(pts + mid + [tip])


# ---------------------------------------------------------------- the plants
# Each returns [(piece label, colour, [point sets])].

def tree(rng):
    """Round tree: a leaning trunk with a stub branch, a canopy of four green lumps (about 10 x 15)."""
    return [
        ("Trunk", TRUNK, [prism(rng, (0, -0.4, 0), (0.4, 8.0, 0.2), 1.1, 0.7, 6),
                          prism(rng, (0.3, 5.0, 0.1), (2.4, 7.4, 0.6), 0.45, 0.3, 5)]),
        ("Canopy", LEAF[0], [blob(rng, (0.3, 10.2, 0.2), 4.4, 14)]),
        ("Canopy", LEAF[1], [blob(rng, (3.0, 8.8, 0.9), 3.0, 12)]),
        ("Canopy", LEAF[2], [blob(rng, (-2.6, 9.2, -0.9), 3.2, 12)]),
        ("Canopy", LEAF[3], [blob(rng, (0.6, 13.0, -0.2), 2.7, 11)]),
    ]


def tree_small(rng):
    """Small tree: short trunk, two lumps (about 7 x 9)."""
    return [
        ("Trunk", TRUNK, [prism(rng, (0, -0.4, 0), (-0.3, 4.6, 0.1), 0.8, 0.55, 6)]),
        ("Canopy", LEAF[1], [blob(rng, (-0.3, 6.2, 0.1), 3.2, 13)]),
        ("Canopy", LEAF[0], [blob(rng, (1.4, 7.8, -0.4), 2.2, 11)]),
    ]


def grass(rng):
    """Grass tuft: seven blades leaning out from one spot, two greens (about 3 x 2.6)."""
    pieces = [[], []]
    for i in range(7):
        yaw = i * 360 / 7 + rng.uniform(-20, 20)
        a = math.radians(yaw)
        h = rng.uniform(1.5, 2.7) if i % 2 else rng.uniform(1.9, 2.7)
        lean = rng.uniform(0.7, 1.3)
        base = (math.cos(a) * 0.35, -0.2, math.sin(a) * 0.35)
        tip = (math.cos(a) * lean, h, math.sin(a) * lean)
        pieces[i % 2].append(blade(base, 0.95, 0.3, tip, -yaw + 90))
    return [("Blades", GRASS[0], pieces[0]), ("Blades", GRASS[1], pieces[1])]


def flower(rng, petal=PETALS["Pink"], centre=CENTRE):
    """Simple flower: stem with two leaves, five chunky petals round a centre (about 3 x 3.6)."""
    top = np.array([0.15, 3.0, 0.0])
    leaves = [blade((0, 0.6, 0), 0.6, 0.18, (1.1, 1.6, 0.2), 90), blade((0, 0.9, 0), 0.6, 0.18, (-1.0, 1.9, -0.3), 90)]
    petals = []
    for i in range(5):
        a = 2 * math.pi * i / 5 + rng.uniform(-0.1, 0.1)
        c = top + (math.cos(a) * 1.0, 0.08, math.sin(a) * 1.0)
        petals.append(blob(rng, c, 0.78, 9, squash=(1.0, 0.4, 1.0), jitter=0.08))
    return [
        ("Stem", STEM, [prism(rng, (0, -0.3, 0), top - (0, 0.1, 0), 0.22, 0.18, 5)] + leaves),
        ("Petals", petal, petals),
        ("Centre", centre, [blob(rng, top + (0, 0.22, 0), 0.5, 10, squash=(1.0, 0.7, 1.0))]),
    ]


TILE = (159, 161, 172)  # the base rocks' Fossil grey (tools/arc_base.py ROCK_COLOR)
TILE_SIZE = 3.4  # a bit under the floor's 4-stud checker squares, so a tile sits inside one


def stone_tile(rng):
    """Square stone tile (QM): a thin chamfered slab a bit smaller than a checker
    square, slightly uneven, its top 0.4 above the floor (bottom 0.3 under it)."""
    h = TILE_SIZE / 2
    c = 0.3
    pts = []
    for sx in (-1, 1):
        for sz in (-1, 1):
            x, z = sx * h + rng.uniform(-0.1, 0.1), sz * h + rng.uniform(-0.1, 0.1)
            top = 0.4 + rng.uniform(-0.08, 0.08)
            pts += [(x, -0.3, z), (x, top - c, z), (x - sx * c, top, z), (x, top, z - sz * c),
                    (x - sx * c * 0.6, top, z - sz * c * 0.6)]
    return [("Tile", TILE, [np.array(pts)])]


PLANTS = [  # name, builder, seed, label
    ("Tree", tree, 3, "Tree"),
    ("TreeSmall", tree_small, 7, "Small tree"),
    ("GrassTuft", grass, 5, "Grass tuft"),
    ("Flower", flower, 2, "Flower"),
    ("StoneTile", stone_tile, 1, "Stone tile"),
    ("StoneTile2", stone_tile, 4, "Stone tile 2"),
    ("StoneTile3", stone_tile, 9, "Stone tile 3"),
]


def build(builder, seed, **kw):
    pieces = builder(np.random.default_rng(seed), **kw)
    return [(label, col, [hull_tris(p) for p in pts]) for label, col, pts in pieces]


def parts_of(pieces, dx=0.0, dz=0.0, yaw=0.0, recolour=None):
    out = []
    for label, col, hulls in pieces:
        if recolour and label in recolour:
            col = recolour[label]
        out += as_parts(hulls, dx, dz, yaw, color=col)
    return out


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    built = {}
    colours = ["# piece: label, RGB (flower petals: Pink by default, also White or Yellow, see PETALS)"]
    for name, builder, seed, _ in PLANTS:
        pieces = build(builder, seed)
        built[name] = pieces
        allh = [h for _, _, hs in pieces for h in hs]
        nt = write_obj(name, allh, os.path.join(OUT, name + ".obj"))
        for i, (label, col, hs) in enumerate(pieces):
            write_obj(f"{name}_{i + 1}", hs, os.path.join(OUT, "pieces", f"{name}_{i + 1}.obj"))
            colours.append(f"{name}_{i + 1}: {label}, {col[0]}, {col[1]}, {col[2]}")
        pts = np.concatenate([np.concatenate(h) for h in allh])
        size = pts.max(0) - np.array([pts.min(0)[0], 0, pts.min(0)[2]])
        print(f"{name}: {len(pieces)} pieces, {nt} tris, {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f} studs")
    with open(os.path.join(OUT, "pieces", "colours.txt"), "w") as f:
        f.write("\n".join(colours) + "\n")

    partlib.GROUND = np.array((105, 255, 74), float)
    partlib.GROUND2 = np.array((77, 196, 63), float)

    # lineup with a 5-stud figure: tree, small tree, grass, flowers in three colours
    k = TA.Kit()
    TA.figure(k, 0)
    fig = lambda x: [Part(p.name, p.size, partlib.T(x, 0, 0) @ p.cf, p.color) for p in k.parts]
    items = [("", None, 4), ("Tree", "Tree", 11), ("Small tree", "TreeSmall", 8), ("Grass tuft", "GrassTuft", 4)]
    items += [(f"Flower ({c.lower()})", ("Flower", c), 3.5) for c in PETALS]
    items += [("Stone tiles", "Tiles", 8)]
    gap, ppst, H = 3, 30, 640
    total = sum(w for *_, w in items) + gap * (len(items) - 1)
    parts, centres = [], []
    x = -total / 2
    for label, what, w in items:
        cx = -(x + w / 2)
        if what is None:
            parts += fig(cx)
        elif what == "Tiles":  # three tiles on neighbouring checker squares
            for i, (n, (tx, tz)) in enumerate(zip(("StoneTile", "StoneTile2", "StoneTile3"), ((-2, -2), (2, -2), (2, 2)))):
                parts += parts_of(built[n], cx + tx, tz)
        elif isinstance(what, tuple):
            rec = {"Petals": PETALS[what[1]]}
            if what[1] == "Yellow":
                rec["Centre"] = CENTRE_ON_YELLOW
            parts += parts_of(built["Flower"], cx, 0, 20, rec)
        else:
            parts += parts_of(built[what], cx, 0, 20)
        centres.append((label, cx))
        x += w + gap
    W = int((total + 4) * ppst)
    eye, target = (0, 40, -120), (0, 6.5, 0)
    fov = 2 * np.degrees(np.arctan(H / 2 / ppst / 125))
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
        tw = d.textlength(label, font=font(16))
        d.text((px - tw / 2, 9), label, fill=(20, 20, 20), font=font(16))
    out.save(os.path.join(OUT, "plants_lineup.png"))

    # scene: a little corner of trees, grass and flowers
    rng = np.random.default_rng(1)
    scene = parts_of(built["Tree"], 6, 14, 30) + parts_of(built["TreeSmall"], -6, 18, 100) + parts_of(built["Tree"], -16, 22, 200)
    for _ in range(9):
        scene += parts_of(built["GrassTuft"], rng.uniform(-18, 14), rng.uniform(0, 16), rng.uniform(0, 360))
    for i in range(10):
        c = list(PETALS)[i % 3]
        rec = {"Petals": PETALS[c]}
        if c == "Yellow":
            rec["Centre"] = CENTRE_ON_YELLOW
        scene += parts_of(built["Flower"], rng.uniform(-16, 12), rng.uniform(-2, 12), rng.uniform(0, 360), rec)
    kk = [Part(p.name, p.size, partlib.T(2, 0, -6) @ p.cf, p.color) for p in k.parts]
    img = render(scene + kk, eye=(-4, 18, -34), target=(-2, 5, 10), W=1280, H=720, fov=50, fog=False, outline=False)
    img.save(os.path.join(OUT, "plants_scene.png"))


if __name__ == "__main__":
    main()
