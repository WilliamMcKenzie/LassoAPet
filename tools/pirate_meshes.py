"""Pirate island props for World 3 (QM, Oct 14), in the rock meshes' style (faceted convex
pieces, flat shaded, studded; each piece its own MeshPart in its own colour).

Palm trees (a tall curved one and a small one, with coconuts), a crate and a crate stack,
a barrel and a barrel group, and a pirate ship (hull with a gold stripe and cannon
ports, deck, rails, fore and stern castles, two masts with billowing sails, crow's nest,
bowsprit, a black flag with white crossbones). Bright kids' colours, picked here as QM
gave none.

Run: python3 tools/pirate_meshes.py
Writes design/pirate/<Name>.obj, design/pirate/pieces/<Name>_<i>.obj (same origin;
colours in pieces/colours.txt), design/pirate/pirate_lineup.png and pirate_ship.png.
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
from crimson_meshes import slab  # noqa: E402
from tomb_meshes import ring, frustum, band  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "pirate")
TRUNK = [(186, 134, 80), (158, 108, 62)]
FROND = [(84, 176, 52), (112, 198, 64)]
COCONUT = (112, 72, 40)
CRATE = (214, 160, 92)
FRAME = (156, 104, 56)
BARREL = (188, 118, 62)
HOOP = (86, 88, 98)
LID = (150, 92, 48)
HULL = (132, 78, 42)
DECK = (210, 160, 100)
RAIL = (104, 60, 32)
STRIPE = (252, 210, 64)
PORT = (34, 28, 26)
SAIL = (248, 244, 230)
MAST = (118, 72, 40)
FLAG = (28, 28, 34)
BONE = (250, 250, 250)


# ---------------------------------------------------------------- palm trees

def palm(rng, h, lean, n_fronds, frond_len):
    """A curved trunk of tapering segments (two shades, ringed), a crown of drooping
    fronds, and coconuts under them."""
    segs = 8
    pts = []
    for i in range(segs + 1):
        t = i / segs
        pts.append(np.array((lean * t * t, h * t, 0.0)))
    trunk = [[], []]
    for i in range(segs):
        r0 = 0.95 - 0.45 * i / segs
        r1 = 0.95 - 0.45 * (i + 1) / segs
        trunk[i % 2].append(prism(rng, pts[i] - (0, 0.05, 0), pts[i + 1], r0 * 1.08, r1, 7, 0.0))
    top = pts[-1]
    fronds = [[], []]
    for i in range(n_fronds):
        a = 2 * math.pi * i / n_fronds + rng.uniform(-0.15, 0.15)
        d = np.array((math.cos(a), 0, math.sin(a)))
        side = np.array((-math.sin(a), 0, math.cos(a)))
        prev = top + (0, 0.3, 0)
        k = 4
        for j in range(k):
            t = (j + 1) / k
            # rises then droops
            p = top + d * frond_len * t + np.array((0, 1.4 * math.sin(math.pi * t * 0.8) - 2.6 * t * t, 0))
            w0 = frond_len * 0.22 * math.sin(math.pi * (j / k * 0.9 + 0.1))
            w1 = frond_len * 0.22 * math.sin(math.pi * (t * 0.9 + 0.1)) if j < k - 1 else 0.05
            seg = [prev + side * w0, prev - side * w0, p + side * w1, p - side * w1]
            seg += [q + (0, 0.18, 0) for q in seg]
            fronds[i % 2].append(np.array(seg))
            prev = p
    nuts = [blob(rng, top + (math.cos(a) * 0.65, -0.55, math.sin(a) * 0.65), 0.55, 10, jitter=0.05)
            for a in (0.3, 2.4, 4.4)]
    return [("Trunk", TRUNK[0], trunk[0]), ("Trunk", TRUNK[1], trunk[1]),
            ("Fronds", FROND[0], fronds[0]), ("Fronds", FROND[1], fronds[1]), ("Coconuts", COCONUT, nuts)]


def palm_tall(rng):
    """Tall curved palm (about 16 across, 21 tall)."""
    return palm(rng, 19.0, 4.0, 8, 7.5)


def palm_small(rng):
    """Small palm (about 11 across, 12 tall)."""
    return palm(rng, 10.5, 1.8, 7, 5.2)


# ---------------------------------------------------------------- crates and barrels

def rot_y(pts, yaw, c=(0, 0, 0)):
    ca, sa = math.cos(yaw), math.sin(yaw)
    p = np.asarray(pts, float) - c
    return np.stack([p[:, 0] * ca - p[:, 2] * sa, p[:, 1], p[:, 0] * sa + p[:, 2] * ca], 1) + c


def crate(rng, s, x=0.0, y=0.0, z=0.0, yaw=0.0):
    """A wooden crate of side s: a light core, dark edge beams and a diagonal brace on the
    front and back. Returns (core, frame) point sets."""
    h = s / 2
    f = s * 0.13
    core = [slab(rng, -h + 0.04, 0.04, -h + 0.04, h - 0.04, s - 0.04, h - 0.04, 0.05, 0.0)]
    frame = []
    for a in (-1, 1):
        for b in (-1, 1):
            frame.append(slab(rng, a * h - f * (a > 0), 0, b * h - f * (b > 0), a * h + f * (a < 0), s, b * h + f * (b < 0), 0.0, 0.0)
                         + np.array((a * 0.03, 0, b * 0.03)))  # uprights
            frame.append(slab(rng, -h, (b > 0) * (s - f), a * h - f * (a > 0), h, (b > 0) * (s - f) + f, a * h + f * (a < 0), 0.0, 0.0)
                         + np.array((0, 0, a * 0.03)))  # rails along x
            frame.append(slab(rng, a * h - f * (a > 0), (b > 0) * (s - f), -h, a * h + f * (a < 0), (b > 0) * (s - f) + f, h, 0.0, 0.0)
                         + np.array((a * 0.03, 0, 0)))  # rails along z
    for zf in (-h - 0.06, h + 0.06):
        p, q = np.array((-h + f, f, zf)), np.array((h - f, s - f, zf))
        d = (q - p)[:2] / np.linalg.norm((q - p)[:2])
        n = np.array((-d[1], d[0], 0)) * f * 0.5
        dz = np.array((0, 0, 0.1 if zf > 0 else -0.1))
        frame.append(np.array([p + n, p - n, q + n, q - n, p + n - dz, p - n - dz, q + n - dz, q - n - dz]))
    move = lambda pts: rot_y(pts, yaw) + (x, y, z)  # noqa: E731
    return [move(c) for c in core], [move(c) for c in frame]


def crate_single(rng):
    """One crate (4 studs)."""
    core, frame = crate(rng, 4.0, yaw=0.0)
    return [("Crate", CRATE, core), ("Frame", FRAME, frame)]


def crate_stack(rng):
    """Two crates side by side, one on top, a small one in front (about 9 wide, 8 tall)."""
    cores, frames = [], []
    for s, x, y, z, yaw in ((4.0, -2.2, 0, 0, 0.05), (4.0, 2.2, 0, 0.2, -0.08), (4.0, 0.0, 4.0, 0.1, 0.3),
                            (2.6, 3.4, 0, -3.4, 0.5)):
        c, f = crate(rng, s, x, y, z, yaw)
        cores += c
        frames += f
    return [("Crate", CRATE, cores), ("Frame", FRAME, frames)]


def barrel(rng, x=0.0, z=0.0, h=3.4, r=1.35, lying=False, yaw=0.0):
    """A bulging barrel with two pairs of hoops and a lid; returns (wood, hoops, lid)."""
    wood = np.array(ring(14, r * 0.84, 0) + ring(14, r, h * 0.5) + ring(14, r * 0.84, h)
                    + ring(14, r * 0.95, h * 0.25) + ring(14, r * 0.95, h * 0.75))
    hoops = [band(wood, y - 0.12, y + 0.12, 0.05) for y in (h * 0.1, h * 0.3, h * 0.7, h * 0.9)]
    lid = frustum(14, r * 0.74, h - 0.05, r * 0.7, h + 0.1)
    parts = [wood] + hoops + [lid]
    if lying:  # tip it over onto its side, resting on the ground
        parts = [np.stack([p[:, 1] - h / 2, p[:, 0] + r, p[:, 2]], 1) for p in parts]
    parts = [rot_y(p, yaw) + (x, 0, z) for p in parts]
    return [parts[0]], parts[1:5], [parts[5]]


def barrel_single(rng):
    """One barrel (about 2.7 across, 3.5 tall)."""
    w, hp, l = barrel(rng)
    return [("Barrel", BARREL, w), ("Hoops", HOOP, hp), ("Lid", LID, l)]


def barrel_group(rng):
    """Three barrels standing together and one lying in front (about 8 across)."""
    ws, hs, ls = [], [], []
    for x, z, lying, yaw in ((-1.5, 0.6, False, 0), (1.5, 0.8, False, 0.4), (0.0, 3.2, False, 0.2), (0.4, -2.6, True, 0.25)):
        w, hp, l = barrel(rng, x, z, lying=lying, yaw=yaw)
        ws += w
        hs += hp
        ls += l
    return [("Barrel", BARREL, ws), ("Hoops", HOOP, hs), ("Lid", LID, ls)]


# ---------------------------------------------------------------- pirate ship

# hull stations from bow (-z) to stern (+z): z, half width at the deck, at the keel, keel height
STATIONS = [(-21.0, 0.4, 0.2, 5.0), (-17.0, 4.0, 1.2, 2.0), (-9.0, 6.0, 2.4, 0.0), (7.0, 6.0, 2.4, 0.0),
            (16.0, 5.4, 2.6, 1.2), (17.0, 5.2, 2.6, 2.0)]
DECK_Y = 8.0


def width_at(z, y):
    zs = [s[0] for s in STATIONS]
    wd = np.interp(z, zs, [s[1] for s in STATIONS])
    wb = np.interp(z, zs, [s[2] for s in STATIONS])
    yb = np.interp(z, zs, [s[3] for s in STATIONS])
    return wb + (wd - wb) * (y - yb) / (DECK_Y - yb)


def sail(x0, x1, y0, y1, z, bulge, nx=5, ny=4):
    """A billowing sail: a thin curved sheet between x0..x1 and y0..y1 at z, bulging toward -z."""
    pts = []
    for i in range(nx + 1):
        for j in range(ny + 1):
            u, v = i / nx, j / ny
            x = x0 + (x1 - x0) * u
            y = y0 + (y1 - y0) * v
            b = bulge * math.sin(math.pi * u) * (0.55 + 0.45 * math.sin(math.pi * v))
            for t in (0, 0.25):
                pts.append((x, y, z - b + t))
    return np.array(pts)


def ship(rng):
    """A pirate ship (about 13 wide, 37 tall, 47 long), bow toward -z."""
    hull = []
    for z, wd, wb, yb in STATIONS:
        for s in (-1, 1):
            hull += [(s * wb, yb, z), (s * wd, DECK_Y, z)]
    hull = np.array(hull)
    stripe = band(hull, 6.4, 7.1, 0.025)
    deck = []
    for z, wd, _, _ in STATIONS[1:]:
        for s in (-1, 1):
            deck += [(s * (wd - 0.1), DECK_Y - 0.05, z), (s * (wd - 0.1), DECK_Y + 0.15, z)]
    deck = np.array(deck + [(0, DECK_Y + 0.15, -20.6), (0, DECK_Y - 0.05, -20.6)])
    rails = []
    zs = [-20.4, -17.0, -13.0, -9.0, -1.0, 7.0, 12.0, 16.8]
    for a, b in zip(zs[:-1], zs[1:]):
        for s in (-1, 1):
            wa, wb_ = width_at(a, DECK_Y), width_at(b, DECK_Y)
            rails.append(np.array([(s * wa, DECK_Y, a), (s * (wa - 0.45), DECK_Y, a), (s * wa, DECK_Y + 1.3, a), (s * (wa - 0.45), DECK_Y + 1.3, a),
                                   (s * wb_, DECK_Y, b), (s * (wb_ - 0.45), DECK_Y, b), (s * wb_, DECK_Y + 1.3, b), (s * (wb_ - 0.45), DECK_Y + 1.3, b)]))
    # stern castle and forecastle (hull colour), their decks (deck colour)
    stern = slab(rng, -5.3, DECK_Y - 0.2, 9.5, 5.3, DECK_Y + 3.6, 17.0, 0.25, 0.0)
    stern_deck = slab(rng, -5.0, DECK_Y + 3.5, 9.8, 5.0, DECK_Y + 3.75, 16.7, 0.05, 0.0)
    fore = np.array([(s * width_at(z, DECK_Y) * 0.96, y, z) for z in (-19.5, -17.0, -12.5) for s in (-1, 1)
                     for y in (DECK_Y - 0.2, DECK_Y + 2.2)])
    fore_deck = np.array([(s * width_at(z, DECK_Y) * 0.9, y, z) for z in (-19.2, -17.0, -12.8) for s in (-1, 1)
                          for y in (DECK_Y + 2.1, DECK_Y + 2.35)])
    windows = [slab(rng, x - 0.7, DECK_Y + 0.9, 17.0, x + 0.7, DECK_Y + 2.3, 17.15, 0.05, 0.0) for x in (-3.0, 0.0, 3.0)]
    ports = []
    for z in (-6.0, -2.0, 2.0, 6.0):
        for s in (-1, 1):
            w = width_at(z, 5.2)
            ports.append(slab(rng, s * w - 0.4, 4.6, z - 0.65, s * w + 0.06 * s, 5.8, z + 0.65, 0.05, 0.0)
                         if s > 0 else slab(rng, s * w - 0.06, 4.6, z - 0.65, s * w + 0.4, 5.8, z + 0.65, 0.05, 0.0))
    # masts, yards, crow's nest, bowsprit
    masts = [prism(rng, (0, DECK_Y - 1, -2.0), (0, 36.5, -2.0), 0.7, 0.45, 8, 0.0),
             prism(rng, (0, DECK_Y - 1, -12.5), (0, 28.0, -12.5), 0.6, 0.4, 8, 0.0),
             prism(rng, (0, DECK_Y + 1, -19.5), (0, 13.0, -28.0), 0.5, 0.3, 6, 0.0)]
    yards = [prism(rng, (-w, y, z), (w, y, z), 0.28, 0.28, 6, 0.0)
             for w, y, z in ((8.0, 14.0, -2.0), (8.0, 23.0, -2.0), (6.5, 24.0, -2.0), (5.5, 31.5, -2.0),
                             (6.0, 13.5, -12.5), (5.0, 21.0, -12.5), (4.5, 26.0, -12.5))]
    sails = [sail(-7.6, 7.6, 14.0, 22.8, -2.0 - 0.6, 2.2), sail(-6.2, 6.2, 24.0, 31.3, -2.0 - 0.6, 1.8),
             sail(-5.6, 5.6, 13.5, 20.8, -12.5 - 0.55, 1.8), sail(-4.2, 4.2, 21.0, 25.8, -12.5 - 0.55, 1.4)]
    jib = [np.array([(0, 12.6, -27.6), (0, 26.0, -12.9), (0, 13.6, -13.6), (0.2, 13.6, -14.0), (-0.2, 19.0, -20.0), (0.2, 19.0, -20.0)])]
    nest = [frustum(8, 1.3, 27.5, 1.7, 29.0, c=(0, -2.0)), frustum(8, 0.9, 26.8, 1.3, 27.6, c=(0, -2.0))]
    # the flag: streaming back (+z) from the mainmast top, crossbones on both faces
    fy, fz = 34.5, -1.6
    flag = slab(rng, -0.12, fy - 1.6, fz, 0.12, fy + 1.6, fz + 4.8, 0.05, 0.0)
    bones = []
    for s in (-1, 1):
        for k in (-1, 1):
            p = np.array((s * 0.12, fy - 0.9 * k - 0.3, fz + 1.2))
            q = np.array((s * 0.12, fy + 0.9 * k - 0.3, fz + 3.6))
            n = np.array((0, 0.25, 0))
            bones.append(np.array([p + n, p - n, q + n, q - n, p + n + (s * 0.12, 0, 0), p - n + (s * 0.12, 0, 0),
                                   q + n + (s * 0.12, 0, 0), q - n + (s * 0.12, 0, 0)]))
        bones.append(blob(rng, (s * 0.2, fy + 0.6, fz + 2.4), 0.75, 10, squash=(0.3, 1, 1), jitter=0.02))
    return [("Hull", HULL, [hull, stern, fore]), ("Stripe", STRIPE, [stripe]), ("Deck", DECK, [deck, stern_deck, fore_deck]),
            ("Rails", RAIL, rails), ("Ports", PORT, ports + windows), ("Masts", MAST, masts + yards + nest),
            ("Sails", SAIL, sails + jib), ("Flag", FLAG, [flag]), ("Crossbones", BONE, bones)]


ITEMS = [  # name, builder, seed, label, lineup width
    ("PalmTree", palm_tall, 3, "Palm tree", 16),
    ("PalmTreeSmall", palm_small, 5, "Small palm", 11),
    ("Crate", crate_single, 1, "Crate", 5),
    ("CrateStack", crate_stack, 2, "Crate stack", 10),
    ("Barrel", barrel_single, 1, "Barrel", 4),
    ("BarrelGroup", barrel_group, 2, "Barrels", 8),
    ("PirateShip", ship, 4, "Pirate ship", 0),
]


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    for f in os.listdir(os.path.join(OUT, "pieces")):
        os.remove(os.path.join(OUT, "pieces", f))
    built = {}
    colours = ["# piece: label, RGB"]
    for name, builder, seed, _, _ in ITEMS:
        raw = builder(np.random.default_rng(seed))
        pieces = [(label, col, [hull_tris(np.asarray(p, float)) for p in pts]) for label, col, pts in raw]
        built[name] = pieces
        allh = [x for _, _, hs in pieces for x in hs]
        nt = write_obj(name, allh, os.path.join(OUT, name + ".obj"))
        for i, (label, col, hs) in enumerate(pieces):
            write_obj(f"{name}_{i + 1}", hs, os.path.join(OUT, "pieces", f"{name}_{i + 1}.obj"))
            colours.append(f"{name}_{i + 1}: {label}, {col[0]}, {col[1]}, {col[2]}")
        pts = np.concatenate([np.concatenate(h) for h in allh])
        size = pts.max(0) - np.array([pts.min(0)[0], 0, pts.min(0)[2]])
        print(f"{name}: {len(pieces)} pieces, {nt} tris, {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f}, min y {pts.min(0)[1]:.2f}")
    with open(os.path.join(OUT, "pieces", "colours.txt"), "w") as f:
        f.write("\n".join(colours) + "\n")

    partlib.GROUND = np.array((240, 218, 160), float)  # island sand for the previews
    partlib.GROUND2 = np.array((228, 204, 146), float)
    k = TA.Kit()
    TA.figure(k, 0)
    items = [("", None, 4)] + [(lbl, n, w) for n, _, _, lbl, w in ITEMS if w]
    gap, ppst, H = 3, 22, 620
    total = sum(w for *_, w in items) + gap * (len(items) - 1)
    parts, centres = [], []
    x = -total / 2
    for label, what, w in items:
        cx = -(x + w / 2)
        if what is None:
            parts += [Part(p.name, p.size, partlib.T(cx, 0, 0) @ p.cf, p.color) for p in k.parts]
        else:
            parts += parts_of(built[what], cx, 0, 20 if what.startswith(("Crate", "Barrel")) else 0)
        centres.append((label, cx))
        x += w + gap
    W = int((total + 6) * ppst)
    eye, target = (0, 30, -150), (0, 8, 0)
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
    out.save(os.path.join(OUT, "pirate_lineup.png"))

    partlib.GROUND = np.array((64, 168, 214), float)  # blue water for the ship
    partlib.GROUND2 = np.array((56, 156, 204), float)
    fig = [Part(p.name, p.size, partlib.T(-2, DECK_Y, 4) @ p.cf, p.color) for p in k.parts]
    shipp = parts_of(built["PirateShip"], 0, 0, 0) + fig
    a = render(shipp, eye=(-52, 26, -46), target=(0, 15, 0), W=1000, H=800, fov=45, fog=False, outline=False)
    b = render(shipp, eye=(46, 30, 40), target=(0, 15, -4), W=1000, H=800, fov=45, fog=False, outline=False)
    out = Image.new("RGB", (2000, 800))
    out.paste(a, (0, 0))
    out.paste(b, (1000, 0))
    out.save(os.path.join(OUT, "pirate_ship.png"))


if __name__ == "__main__":
    main()
