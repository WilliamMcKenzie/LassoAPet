"""Temple biome props (QM, Oct 13), in the rock meshes' style (faceted convex pieces, flat
shaded, studded; each piece its own MeshPart in its own colour).

Tombstones with moss, little Japanese-style trees, medium stones and an unlit
traditional stone lantern (QM's reference: a toro with a flared pillar, a platform, a
light box with a round and a square window, a wide roof with upturned corners, a knob).
Colours (QM): tombstones #B1A367, moss #9FB600, tree trunks #2A1A00, foliage #688228,
stones and the lantern #B2A26C (each with a shade or two for facets).

Run: python3 tools/temple_meshes.py
Writes design/temple/<Name>.obj, design/temple/pieces/<Name>_<i>.obj (same origin;
colours in pieces/colours.txt), design/temple/temple_lineup.png and temple_scene.png.
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
import rock_meshes as RM  # noqa: E402
from rock_meshes import hull_tris, write_obj, font  # noqa: E402
from plant_meshes import blob, prism, parts_of  # noqa: E402
from crimson_meshes import slab  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "temple")
TOMB = [(0xB1, 0xA3, 0x67), (156, 143, 90), (194, 180, 122)]  # QM's #B1A367 and two shades
STONE = [(0xB2, 0xA2, 0x6C), (156, 142, 94), (196, 181, 128)]  # QM's #B2A26C (stones, lantern)
MOSS = (0x9F, 0xB6, 0x00)
WINDOW = (58, 50, 34)  # the lantern's unlit window holes
TRUNK = (0x2A, 0x1A, 0x00)
LEAVES = [(0x68, 0x82, 0x28), (122, 150, 52)]  # QM's #688228 and a lighter shade


def ring(n, r, y, a0=0.0, lift=None):
    """n points round a circle (corners lifted by lift(i) if given)."""
    return [(math.cos(a0 + 2 * math.pi * i / n) * r, y + (lift(i) if lift else 0),
             math.sin(a0 + 2 * math.pi * i / n) * r) for i in range(n)]


def frustum(n, r0, y0, r1, y1, a0=0.0):
    return np.array(ring(n, r0, y0, a0) + ring(n, r1, y1, a0))


# ---------------------------------------------------------------- tombstones

def moss_patch(rng, x0, x1, y0, y1, z, depth=0.12):
    """A thin irregular patch just proud of the face at z (facing -z)."""
    pts = []
    for _ in range(7):
        x, y = rng.uniform(x0, x1), rng.uniform(y0, y1)
        pts += [(x, y, z - depth), (x, y, z + 0.2)]
    return np.array(pts)


def tomb(rng, w, h, d, top="flat", step=True, lean=0.0):
    body = slab(rng, -w / 2, 0.6 if step else -0.4, -d / 2, w / 2, h, d / 2, 0.25, 0.08)
    if top == "shoulder":  # a narrower block on top, the stepped shoulders of the reference
        cap = slab(rng, -w * 0.32, h - 0.1, -d * 0.4, w * 0.32, h + w * 0.35, d * 0.4, 0.2, 0.05)
    else:  # a low pitched cap
        cap = np.array([(x, h, z) for x in (-w / 2 - 0.1, w / 2 + 0.1) for z in (-d / 2 - 0.1, d / 2 + 0.1)]
                       + [(x, h + 0.5, z) for x in (-w * 0.3, w * 0.3) for z in (-d * 0.2, d * 0.2)])
    parts = [("Stone", TOMB[0], [body]), ("Cap", TOMB[2], [cap])]
    if step:
        parts.append(("Base", TOMB[1], [slab(rng, -w / 2 - 0.7, -0.4, -d / 2 - 0.6, w / 2 + 0.7, 0.7, d / 2 + 0.6, 0.2, 0.05)]))
    moss = [moss_patch(rng, -w / 2 + 0.2, w * 0.1, 0.7, h * 0.45, -d / 2),
            moss_patch(rng, -w * 0.1, w / 2 - 0.2, h * 0.55, h - 0.3, -d / 2)]
    if step:
        moss.append(np.array([(x, 0.7 + dy, z) for x in (-w / 2 - 0.5, -w * 0.1) for z in (-d / 2 - 0.5, -d / 2 + 0.2)
                              for dy in (-0.05, 0.12)]))
    parts.append(("Moss", MOSS, moss))
    if lean:
        c, s = math.cos(lean), math.sin(lean)
        R = np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])
        parts = [(l, col, [p @ R.T for p in pts]) for l, col, pts in parts]
    return parts


def tomb_tall(rng):
    """Tall tombstone on a stepped base, shouldered top (about 5 wide, 8 tall)."""
    return tomb(rng, 3.6, 6.4, 1.4, "shoulder")


def tomb_short(rng):
    """Short tombstone, pitched cap (about 5 wide, 5 tall)."""
    return tomb(rng, 3.4, 4.0, 1.3, "flat")


def tomb_lean(rng):
    """Old leaning tombstone, no base (about 4 wide, 5 tall)."""
    return tomb(rng, 3.0, 4.6, 1.2, "flat", step=False, lean=math.radians(-9))


# ---------------------------------------------------------------- little trees

def little_tree(rng, h, pads, spread):
    """A twisty trunk in three segments with flat cloud pads of leaves on its bends."""
    pts = [np.array((0, -0.4, 0.0))]
    for i in range(3):
        pts.append(pts[-1] + (rng.uniform(-spread, spread), h / 3, rng.uniform(-spread, spread)))
    trunk = [prism(rng, pts[i], pts[i + 1], 0.55 - i * 0.12, 0.45 - i * 0.12, 6, 0.05) for i in range(3)]
    groups = [[], []]
    for i in range(pads):
        base = pts[min(3, 1 + i)] if i < 3 else pts[3]
        off = (rng.uniform(-1.2, 1.2), 0.3 + 0.2 * i, rng.uniform(-1.2, 1.2)) if i >= 3 else (0, 0.3, 0)
        r = rng.uniform(1.4, 2.0) * (1.25 if i == pads - 1 else 1)
        groups[i % 2].append(blob(rng, base + off, r, 12, squash=(1.0, 0.45, 1.0), jitter=0.08))
    return [("Trunk", TRUNK, trunk), ("Leaves", LEAVES[0], groups[0]), ("Leaves", LEAVES[1], groups[1])]


def tree_a(rng):
    """Little tree, three pads (about 6 across, 8 tall)."""
    return little_tree(rng, 6.0, 4, 1.0)


def tree_b(rng):
    """Smaller little tree, more crooked (about 5 across, 6 tall)."""
    return little_tree(rng, 4.4, 3, 1.4)


# ---------------------------------------------------------------- medium stones

def stones(name, seed):
    """One of the rock meshes (its chunks) in the temple stone, chunk by chunk shaded."""
    b = dict((n, f) for n, f, _, _ in RM.ROCKS)[name]
    chunks = b(np.random.default_rng(seed))
    return [("Stone", STONE[i % 3], [c]) for i, c in enumerate(chunks)]


# ---------------------------------------------------------------- the lantern

def lantern(rng):
    """Unlit stone lantern (QM's reference), about 5 across, 11 tall, its parts stacked:
    a square foot, a flared octagonal pillar, an octagonal platform, a square light box
    with a round and a square window, a wide roof with upturned corners, a knob."""
    y = -0.4
    foot = frustum(4, 1.9, y, 1.75, 1.0, math.pi / 4)
    y = 1.0
    pillar = [frustum(8, 1.35, y, 1.45, y + 1.8, math.pi / 8), frustum(8, 1.45, y + 1.8, 0.7, y + 3.4, math.pi / 8),
              frustum(8, 0.7, y + 3.4, 0.8, y + 4.0, math.pi / 8)]
    y += 4.0
    platform = [frustum(8, 0.95, y, 1.75, y + 0.5, math.pi / 8), frustum(8, 1.75, y + 0.5, 1.75, y + 1.1, math.pi / 8)]
    y += 1.1
    box = frustum(4, 1.35, y, 1.3, y + 2.0, math.pi / 4)
    # the windows: a square one on the front, a round one on the side, as dark insets
    wf = np.array([(x, yy, -0.95 - dz) for x in (-0.45, 0.45) for yy in (y + 0.6, y + 1.5) for dz in (-0.05, 0.02)])
    wr = np.array([(0.95 + dz, y + 1.05 + math.sin(a) * 0.42, math.cos(a) * 0.42)
                   for a in np.linspace(0, 2 * math.pi, 9)[:-1] for dz in (-0.05, 0.02)])
    wr2 = wr * np.array([-1, 1, 1])
    wf2 = wf * np.array([1, 1, -1])
    y += 2.0
    # roof: a wide square eave, its four corners kicked up, rising to a small top
    eave = 2.9
    roof = np.array(ring(4, eave * 1.18, y + 0.35, math.pi / 4, lift=lambda i: 0.45)  # the upturned corners
                    + ring(4, eave, y + 0.15, 0.0)  # the eave's mid-edges, lower
                    + ring(4, eave * 0.9, y - 0.05, 0.0) + ring(4, eave * 1.05, y + 0.05, math.pi / 4)
                    + ring(4, 0.75, y + 1.35, math.pi / 4))
    knob = [frustum(8, 0.45, y + 1.3, 0.35, y + 1.6, math.pi / 8),
            blob(rng, (0, y + 2.1, 0), 0.6, 10, squash=(1.0, 1.0, 1.0), jitter=0.04)]
    return [("Foot", STONE[1], [foot]), ("Pillar", STONE[0], pillar), ("Platform", STONE[2], platform),
            ("LightBox", STONE[0], [box]), ("Windows", WINDOW, [wf, wf2, wr, wr2]), ("Roof", STONE[2], [roof]),
            ("Knob", STONE[1], knob)]


ITEMS = [  # name, builder, seed, label, lineup width
    ("TombTall", tomb_tall, 3, "Tombstone", 6),
    ("TombShort", tomb_short, 5, "Short tombstone", 6),
    ("TombLean", tomb_lean, 7, "Leaning tombstone", 5),
    ("TempleTree", tree_a, 4, "Little tree", 7),
    ("TempleTreeSmall", tree_b, 9, "Small tree", 6),
    ("TempleStone", lambda rng: stones("RockBoulder", 8), 0, "Stone", 9),
    ("TempleStoneTwin", lambda rng: stones("RockTwins", 21), 0, "Stones", 9),
    ("StoneLantern", lantern, 2, "Stone lantern", 7),
]


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    for f in os.listdir(os.path.join(OUT, "pieces")):
        os.remove(os.path.join(OUT, "pieces", f))
    built = {}
    colours = ["# piece: label, RGB"]
    for name, builder, seed, _, _ in ITEMS:
        raw = builder(np.random.default_rng(seed))
        pieces = [(label, col, [hull_tris(np.asarray(p)) for p in pts]) for label, col, pts in raw]
        # recentre the rock-based stones on their footprint like rock_meshes.build
        if name.startswith("TempleStone"):
            allp = np.concatenate([np.concatenate(h) for _, _, hs in pieces for h in hs])
            mid = (allp.min(0) + allp.max(0)) / 2
            shift = np.array([mid[0], 0, mid[2]])
            pieces = [(l, c, [[t - shift for t in h] for h in hs]) for l, c, hs in pieces]
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

    partlib.GROUND = np.array((176, 180, 184), float)  # a grey temple courtyard for the previews
    partlib.GROUND2 = np.array((160, 164, 170), float)
    k = TA.Kit()
    TA.figure(k, 0)
    items = [("", None, 4)] + [(lbl, n, w) for n, _, _, lbl, w in ITEMS]
    gap, ppst, H = 3, 22, 520
    total = sum(w for *_, w in items) + gap * (len(items) - 1)
    parts, centres = [], []
    x = -total / 2
    for label, what, w in items:
        cx = -(x + w / 2)
        if what is None:
            parts += [Part(p.name, p.size, partlib.T(cx, 0, 0) @ p.cf, p.color) for p in k.parts]
        else:
            parts += parts_of(built[what], cx, 0, 0 if what.startswith(("Tomb", "Stone")) else 20)
        centres.append((label, cx))
        x += w + gap
    W = int((total + 6) * ppst)
    eye, target = (0, 30, -150), (0, 5, 0)
    fov = 2 * np.degrees(np.arctan(H / 2 / ppst / 152))
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
    out.save(os.path.join(OUT, "temple_lineup.png"))

    # a close look at the lantern, and a little graveyard scene
    a = render(parts_of(built["StoneLantern"], 0, 0, 20) + [Part(p.name, p.size, partlib.T(-4, 0, -2) @ p.cf, p.color) for p in k.parts],
               eye=(-8, 9, -16), target=(0, 5, 0), W=720, H=720, fov=42, fog=False, outline=False)
    scene = (parts_of(built["TombTall"], -6, 8, 0) + parts_of(built["TombShort"], 0, 8, 0) + parts_of(built["TombLean"], 6, 8, 0)
             + parts_of(built["TombShort"], -6, 16, 0) + parts_of(built["TombTall"], 0, 16, 0) + parts_of(built["TombTall"], 6, 16, 0)
             + parts_of(built["StoneLantern"], -14, 4, 10) + parts_of(built["StoneLantern"], 14, 4, -10)
             + parts_of(built["TempleTree"], -16, 20, 40) + parts_of(built["TempleTreeSmall"], 15, 20, 100)
             + parts_of(built["TempleStone"], -22, 12, 30) + parts_of(built["TempleStoneTwin"], 22, 12, 200))
    scene += [Part(p.name, p.size, partlib.T(0, 0, -4) @ p.cf, p.color) for p in k.parts]
    b = render(scene, eye=(0, 18, -30), target=(0, 4, 12), W=1280, H=720, fov=60, fog=False, outline=False)
    out = Image.new("RGB", (2000, 720))
    out.paste(a, (0, 0))
    out.paste(b, (720, 0))
    out.save(os.path.join(OUT, "temple_scene.png"))


if __name__ == "__main__":
    main()
