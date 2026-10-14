"""Crimson set (QM, Oct 13; QM's references are the Nether's crimson forest): giant and
medium red mushrooms, a little red mushroom, red tentacle-like grass tufts and "runic"
standing stones, in the rock meshes' style (tools/rock_meshes.py): faceted convex pieces,
flat shaded, studded, one colour per piece (each piece its own MeshPart).

Colours: caps and tufts QM's #D90F2C. QM's stem and stone colours came through as
#D90F2C too, so the stem is the reference's pale pink and the stone a muted rose grey;
the runes are gold like the reference's glowing eyes (Neon in game would suit them).

Run: python3 tools/crimson_meshes.py
Writes design/crimson/<Name>.obj, design/crimson/pieces/<Name>_<i>.obj (same origin;
colours in pieces/colours.txt), design/crimson/crimson_lineup.png and crimson_scene.png.
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

OUT = os.path.join(HERE, "..", "design", "crimson")
CAP = (0xD9, 0x0F, 0x2C)  # QM's #D90F2C
CAP_UNDER = (150, 10, 32)  # the cap's underside, a darker red
CAP_SPOTS = (240, 70, 90)  # (unused: the cap's lumps went, QM)
STEM = (228, 172, 180)  # pale pink, as the reference's
TUFT = [CAP, (176, 12, 36)]
STONE = [(156, 124, 120), (140, 110, 106), (170, 138, 132)]  # muted rose grey, a touch bright
RUNE = (255, 186, 60)


def mushroom(rng, h, cap_r, stem_r, bend=1.5):
    """A stem in two bent segments and a domed cap with a darker underside."""
    mid = np.array([bend * 0.6, h * 0.5, 0.0])
    top = np.array([bend, h, rng.uniform(-0.3, 0.3)])
    stem = [prism(rng, (0, -0.4, 0), mid, stem_r * 1.15, stem_r * 1.02, 7, 0.04),
            prism(rng, mid - (0, 0.4, 0), top, stem_r * 1.02, stem_r * 0.85, 7, 0.04)]
    dome = blob(rng, top + (0, cap_r * 0.18, 0), cap_r, 16, squash=(1.0, 0.55, 1.0), jitter=0.07)
    dome = dome[dome[:, 1] > top[1] - cap_r * 0.05]  # keep the upper half: a dome
    # the cap's lip: a ring round the dome's foot, in the same hull as the dome
    lip = []
    for i in range(9):
        a = 2 * math.pi * i / 9 + rng.uniform(-0.1, 0.1)
        rr = cap_r * 1.02 * (1 + rng.uniform(-0.05, 0.05))
        lip.append((top[0] + math.cos(a) * rr, top[1] - cap_r * 0.02, top[2] + math.sin(a) * rr))
    dome = np.concatenate([dome, np.array(lip)])
    # the underside: a darker shallow cone just under the cap, inside its rim
    rim = []
    for i in range(9):
        a = 2 * math.pi * i / 9
        rr = cap_r * 0.9
        rim += [(top[0] + math.cos(a) * rr, top[1] - cap_r * 0.06, top[2] + math.sin(a) * rr),
                (top[0] + math.cos(a) * rr * 0.35, top[1] - cap_r * 0.24, top[2] + math.sin(a) * rr * 0.35),
                (top[0] + math.cos(a) * rr * 0.9, top[1] + cap_r * 0.05, top[2] + math.sin(a) * rr * 0.9)]
    spots = []
    for _ in range(3):
        a = rng.uniform(0, 2 * math.pi)
        d = rng.uniform(0.3, 0.6) * cap_r
        y = top[1] + cap_r * 0.18 + math.sqrt(max(0.0, 1 - (d / cap_r) ** 2)) * cap_r * 0.55
        spots.append(blob(rng, (top[0] + math.cos(a) * d, y - 0.1 * cap_r, top[2] + math.sin(a) * d), cap_r * 0.16, 8,
                          squash=(1.0, 0.6, 1.0)))
    # (the spots are still made, so the shapes stay the same, but QM wanted them gone)
    return [("Stem", STEM, stem), ("Cap", CAP, [dome]), ("Underside", CAP_UNDER, [np.array(rim)])]


def giant(rng):
    """Giant mushroom (about 16 across, 20 tall)."""
    return mushroom(rng, 15.0, 8.0, 1.3, bend=2.4)


def medium(rng):
    """Medium mushroom (about 9 across, 10 tall)."""
    return mushroom(rng, 7.5, 4.4, 0.75, bend=1.2)


def small(rng):
    """Little mushroom to scatter (about 2.4 across, 2.6 tall)."""
    return mushroom(rng, 1.7, 1.2, 0.25, bend=0.3)


def tuft(rng):
    """Tentacle tuft: six strands, each three tapering segments curling up and out."""
    strands = [[], []]
    for i in range(6):
        a = 2 * math.pi * i / 6 + rng.uniform(-0.3, 0.3)
        d = np.array([math.cos(a), 0, math.sin(a)])
        side = np.cross(d, (0, 1, 0))
        h = rng.uniform(3.4, 4.6)
        pts = [np.array((0, -0.2, 0)) + d * 0.3]
        # out, up, then curling back over: a hook
        for f, out, curl in ((0.4, 0.8, 0.0), (0.75, 1.3, 0.35), (1.0, 1.0, 0.8)):
            pts.append(d * out + np.array((0, h * f, 0)) + side * curl * rng.choice((-1, 1)))
        r = [0.42, 0.34, 0.24, 0.1]
        for j in range(3):
            strands[i % 2].append(prism(rng, pts[j], pts[j + 1], r[j], r[j + 1], 5, 0.05))
    return [("Strands", TUFT[0], strands[0]), ("Strands", TUFT[1], strands[1])]


def slab(rng, x0, y0, z0, x1, y1, z1, c=0.4, j=0.15):
    """A chamfered, slightly uneven box (its 8 corners, each cut back toward its 3 neighbours)."""
    corners = np.array([(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)], float)
    corners += rng.uniform(-j, j, corners.shape)
    pts = []
    for i, p in enumerate(corners):
        for k in range(3):  # the neighbour along each axis: flip bit k of the index
            q = corners[i ^ (1 << (2 - k))]
            pts.append(p + (q - p) / np.linalg.norm(q - p) * c)
    return np.array(pts)


def glyph(x, y, z, s, strokes, depth=0.25):
    """Rune strokes as thin raised bars on the plane z (proud toward -z): each stroke
    (x0, y0, x1, y1) in units of s from (x, y)."""
    out = []
    for x0, y0, x1, y1 in strokes:
        a = np.array([x + x0 * s, y + y0 * s])
        b = np.array([x + x1 * s, y + y1 * s])
        d = b - a
        n = np.array([-d[1], d[0]]) / np.linalg.norm(d) * 0.18 * s
        pts = []
        for p in (a, b):
            for side in (1, -1):
                q = p + n * side
                for zz in (z + 0.1, z - depth):
                    pts.append((q[0], q[1], zz))
        out.append(np.array(pts))
    return out


# a few futhark-like runes (strokes in a 2-wide, 4-tall box from its lower-left corner)
RUNES = {
    "fehu": [(0, 0, 0, 4), (0, 2.6, 1.6, 3.8), (0, 1.6, 1.6, 2.8)],
    "algiz": [(1, 0, 1, 4), (1, 2.6, 0, 3.8), (1, 2.6, 2, 3.8)],
    "dagaz": [(0, 0, 0, 4), (2, 0, 2, 4), (0, 0, 2, 4), (0, 4, 2, 0)],
    "othala": [(1, 4, 0, 2.8), (1, 4, 2, 2.8), (0, 2.8, 1, 1.6), (2, 2.8, 1, 1.6), (1, 1.6, 0, 0), (1, 1.6, 2, 0)],
}


def menhir(rng, w, h, d, runes, lean=0.0):
    """A standing stone: a tall chamfered slab, a smaller cap stone, runes down its front."""
    body = slab(rng, -w / 2, -0.5, -d / 2, w / 2, h, d / 2, 0.5, 0.2)
    body[:, 0] += body[:, 1] * lean
    cap = slab(rng, -w * 0.4, h - 0.2, -d * 0.4, w * 0.4, h + 1.0, d * 0.4, 0.35, 0.1)
    cap[:, 0] += h * lean
    s = w / 4.0
    marks = []
    y = h - 1.0 - 4 * s
    for name in runes:
        for m in glyph(-s, y, -d / 2 - 0.05, s, RUNES[name]):
            m[:, 0] += m[:, 1] * lean
            marks.append(m)
        y -= 4 * s + 1.0
    return [("Stone", STONE[0], [body]), ("Cap", STONE[1], [cap]), ("Runes", RUNE, marks)]


def menhir_tall(rng):
    """Tall runestone (about 5 wide, 13 tall), two runes."""
    return menhir(rng, 5.0, 12.0, 3.2, ["algiz", "othala"])


def menhir_short(rng):
    """Short leaning runestone (about 4 wide, 7 tall), one rune."""
    return menhir(rng, 4.2, 6.5, 2.8, ["fehu"], lean=0.08)


def rune_block(rng):
    """Low rune block: a wide squat stone with a rune on its front and a loose chunk (about 8 x 4)."""
    body = slab(rng, -3.6, -0.5, -2.2, 3.6, 3.6, 2.2, 0.55, 0.2)
    chunk = slab(rng, 3.4, -0.5, -1.0, 5.4, 1.6, 1.0, 0.4, 0.2)
    marks = glyph(-0.8, 0.4, -2.25, 0.8, RUNES["dagaz"])
    return [("Stone", STONE[0], [body]), ("Chunk", STONE[2], [chunk]), ("Runes", RUNE, marks)]


ITEMS = [  # name, builder, seed, label
    ("MushroomGiant", giant, 3, "Giant mushroom"),
    ("MushroomMedium", medium, 6, "Medium mushroom"),
    ("MushroomSmall", small, 2, "Little mushroom"),
    ("CrimsonTuft", tuft, 4, "Tentacle tuft"),
    ("RunestoneTall", menhir_tall, 7, "Runestone"),
    ("RunestoneShort", menhir_short, 9, "Leaning runestone"),
    ("RuneBlock", rune_block, 5, "Rune block"),
]


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    built = {}
    colours = ["# piece: label, RGB (Runes: Neon in game would suit them)"]
    for name, builder, seed, _ in ITEMS:
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

    # the crimson ground of the reference for the previews
    partlib.GROUND = np.array((140, 34, 44), float)
    partlib.GROUND2 = np.array((122, 26, 38), float)
    k = TA.Kit()
    TA.figure(k, 0)
    widths = {"MushroomGiant": 17, "MushroomMedium": 10, "MushroomSmall": 3, "CrimsonTuft": 5,
              "RunestoneTall": 6, "RunestoneShort": 6, "RuneBlock": 10}
    items = [("", None, 4)] + [(lbl, n, widths[n]) for n, _, _, lbl in ITEMS]
    gap, ppst, H = 3, 22, 700
    total = sum(w for *_, w in items) + gap * (len(items) - 1)
    parts, centres = [], []
    x = -total / 2
    for label, what, w in items:
        cx = -(x + w / 2)
        if what is None:
            parts += [Part(p.name, p.size, partlib.T(cx, 0, 0) @ p.cf, p.color) for p in k.parts]
        else:
            parts += parts_of(built[what], cx, 0, 0 if what.startswith("Rune") else 20)
        centres.append((label, cx))
        x += w + gap
    W = int((total + 6) * ppst)
    eye, target = (0, 30, -150), (0, 9, 0)
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
        tw = d.textlength(label, font=font(15))
        d.text((px - tw / 2, 9), label, fill=(20, 20, 20), font=font(15))
    out.save(os.path.join(OUT, "crimson_lineup.png"))

    rng = np.random.default_rng(3)
    scene = (parts_of(built["MushroomGiant"], -8, 26, 30) + parts_of(built["MushroomMedium"], 10, 18, 120)
             + parts_of(built["MushroomGiant"], 22, 36, 200) + parts_of(built["RunestoneTall"], 2, 12, 10)
             + parts_of(built["RunestoneShort"], -16, 8, -20) + parts_of(built["RuneBlock"], 16, 4, -15))
    for _ in range(9):
        scene += parts_of(built["CrimsonTuft"], rng.uniform(-22, 22), rng.uniform(-4, 18), rng.uniform(0, 360))
    for _ in range(7):
        scene += parts_of(built["MushroomSmall"], rng.uniform(-20, 20), rng.uniform(-4, 14), rng.uniform(0, 360))
    scene += [Part(p.name, p.size, partlib.T(-4, 0, -6) @ p.cf, p.color) for p in k.parts]
    img = render(scene, eye=(0, 22, -46), target=(0, 8, 14), W=1280, H=720, fov=55, fog=False, outline=False)
    img.save(os.path.join(OUT, "crimson_scene.png"))


if __name__ == "__main__":
    main()
