"""Ancient tomb props (QM, Oct 13), in the rock meshes' style (faceted convex pieces,
flat shaded, studded; each piece its own MeshPart in its own colour).

Sarcophagi in QM's gold #F5B000 and navy #001122 (one lying, one standing); a golden
sphinx on a plinth; two golden statues on podiums (a warrior with spear and shield, a
giant sword); massive gold bars (one, and a stack); a golden trophy. Statue gold is QM's
#FCDE51 with a darker and a lighter shade for facets; the podiums are the sarcophagi's
navy with gold trim.

Run: python3 tools/tomb_meshes.py
Writes design/tomb/<Name>.obj, design/tomb/pieces/<Name>_<i>.obj (same origin;
colours in pieces/colours.txt), design/tomb/tomb_lineup.png and tomb_scene.png.
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

OUT = os.path.join(HERE, "..", "design", "tomb")
SARC = (0xF5, 0xB0, 0x00)  # QM's #F5B000
NAVY = (0x00, 0x11, 0x22)  # QM's #001122
GOLD = [(0xFC, 0xDE, 0x51), (226, 188, 52), (255, 236, 140)]  # QM's #FCDE51, darker, lighter


def ring(n, r, y, a0=0.0, sx=1.0, sz=1.0, c=(0.0, 0.0)):
    return [(c[0] + math.cos(a0 + 2 * math.pi * i / n) * r * sx, y,
             c[1] + math.sin(a0 + 2 * math.pi * i / n) * r * sz) for i in range(n)]


def frustum(n, r0, y0, r1, y1, a0=0.0, c=(0.0, 0.0)):
    return np.array(ring(n, r0, y0, a0, c=c) + ring(n, r1, y1, a0, c=c))


def band(pts, y0, y1, grow=0.06):
    """The slice of the hull of pts between heights y0 and y1, pushed out by grow (a stripe)."""
    from scipy.spatial import ConvexHull
    pts = np.asarray(pts, float)
    out = [p for p in pts if y0 <= p[1] <= y1]
    for tri in ConvexHull(pts).simplices:
        for a, b in ((0, 1), (1, 2), (2, 0)):
            p, q = pts[tri[a]], pts[tri[b]]
            for y in (y0, y1):
                if (p[1] - y) * (q[1] - y) < 0:
                    out.append(p + (q - p) * (y - p[1]) / (q[1] - p[1]))
    out = np.array(out)
    c = pts.mean(0)
    out[:, [0, 2]] = c[[0, 2]] + (out[:, [0, 2]] - c[[0, 2]]) * (1 + grow)
    return out


def ingot(x0, z0, w, d, y0, h, top=0.78):
    """A gold bar: a rectangular frustum (w along x, d along z), narrower on top."""
    pts = []
    for y, s in ((y0, 1.0), (y0 + h, top)):
        for sx in (-1, 1):
            for sz in (-1, 1):
                pts.append((x0 + sx * w / 2 * s, y, z0 + sz * d / 2 * s))
    return np.array(pts)


# ---------------------------------------------------------------- sarcophagi

# the coffin's outline along its length (x, feet to head): half width, height
OUTLINE = [(-4.6, 1.0, 1.7), (-3.6, 1.15, 1.95), (-1.0, 1.4, 2.2), (1.6, 1.62, 2.4), (2.6, 1.62, 2.45),
           (3.2, 1.35, 2.5), (4.6, 1.2, 2.35)]


def section(x, w, h, y0, y1, inset=1.0, grow=0.0):
    """Points round the coffin's cross-section at x between heights y0 and y1 (as fractions
    of h); the top rounds over."""
    pts = []
    for f, s in ((y0, 1.0), (min(y1, 0.8), 1.0), (y1, 0.55 if y1 > 0.95 else 1.0)):
        if f < y0 or f > y1:
            continue
        for side in (-1, 1):
            pts.append((x, f * h + (grow if f > 0.95 else 0), side * (w * s * inset + grow)))
    return pts


def sarcophagus(rng):
    """Lying sarcophagus, head toward +x (about 9.4 long, 3.3 wide, 3 tall)."""
    body = np.array([p for x, w, h in OUTLINE for p in section(x, w, h, 0.0, 0.5)])
    lid = np.array([p for x, w, h in OUTLINE for p in section(x, w, h, 0.48, 1.0, 0.96)])
    bands = []
    for b in (-3.4, -1.9, -0.4):
        sec = [(x, w, h) for x, w, h in OUTLINE]
        # the outline at b, interpolated
        xs = [s[0] for s in sec]
        w = np.interp(b, xs, [s[1] for s in sec])
        h = np.interp(b, xs, [s[2] for s in sec])
        bands.append(np.array([p for dx in (-0.22, 0.22) for p in section(b + dx, w, h, 0.47, 1.0, 0.96, 0.08)]))
    # the headdress: the head's sides and back, navy, leaving the gold face on top
    head = [(x, w, h) for x, w, h in OUTLINE if x >= 3.2]
    nemes = np.array([p for x, w, h in head for p in section(x, w, h, 0.45, 0.88, 1.04)]
                     + [(2.9, 0.45 * 2.5, s * 1.55) for s in (-1, 1)] + [(2.9, 0.86 * 2.5, s * 1.5) for s in (-1, 1)])
    stripes = [np.array([p for dx in (-0.12, 0.12) for p in section(x + dx, 1.35, 2.5, 0.5, 0.86, 1.06)])
               for x in (3.5, 4.1)]
    face = blob(rng, (3.85, 2.45, 0), 0.95, 12, squash=(1.1, 0.45, 0.95), jitter=0.04)
    eyes = [slab(rng, 3.95, 2.72, s * 0.55 - 0.22, 4.15, 2.92, s * 0.55 + 0.22, 0.04, 0.0) for s in (-1, 1)]
    beard = prism(rng, (3.1, 2.55, 0), (2.4, 2.7, 0), 0.28, 0.2, 6, 0.0)
    arms = [prism(rng, (2.0, 2.45, s * 1.0), (0.4, 2.42, -s * 0.9), 0.32, 0.3, 6, 0.0) for s in (-1, 1)]
    return [("Base", NAVY, [body]), ("Lid", SARC, [lid]), ("Bands", NAVY, bands),
            ("Headdress", NAVY, [nemes]), ("Stripes", SARC, stripes), ("Face", SARC, [face]),
            ("Eyes", NAVY, eyes), ("Beard", NAVY, [beard]), ("Arms", GOLD[1], arms)]


def stand(pieces):
    """The lying coffin stood up on its feet, its lid facing -z."""
    out = []
    for label, col, pts in pieces:
        moved = []
        for p in pts:
            p = np.asarray(p, float)
            moved.append(np.stack([p[:, 2], p[:, 0] + 4.6, -p[:, 1] + 1.3], 1))
        out.append((label, col, moved))
    return out


def sarcophagus_standing(rng):
    """Standing sarcophagus (about 3.3 wide, 9.4 tall, 2.6 deep)."""
    return stand(sarcophagus(rng))


# ---------------------------------------------------------------- sphinx

def sphinx(rng):
    """A golden sphinx lying on a plinth, facing -z (about 9 wide, 11 tall, 18 long)."""
    plinth = slab(rng, -4.6, 0, -9.2, 4.6, 1.4, 8.6, 0.3, 0.02)
    trim = slab(rng, -4.9, 0, -9.5, 4.9, 0.45, 8.9, 0.15, 0.0)
    P = 1.4
    torso = blob(rng, (0, P + 2.6, 2.4), 3.0, 18, squash=(0.95, 0.85, 1.75), jitter=0.04)
    chest = blob(rng, (0, P + 3.4, -2.2), 2.3, 14, squash=(1.0, 1.15, 0.85), jitter=0.04)
    haunch = [blob(rng, (s * 2.2, P + 2.0, 4.6), 2.1, 12, squash=(0.8, 0.95, 1.1), jitter=0.05) for s in (-1, 1)]
    legs = [slab(rng, s * 1.6 - 0.7, P, -7.6, s * 1.6 + 0.7, P + 1.5, -1.6, 0.3, 0.03) for s in (-1, 1)]
    paws = [slab(rng, s * 1.6 - 0.85, P, -8.6, s * 1.6 + 0.85, P + 1.1, -7.2, 0.3, 0.03) for s in (-1, 1)]
    tail = [prism(rng, (2.6, P + 0.5, 6.6), (3.2, P + 0.5, 2.0), 0.45, 0.35, 6, 0.0)]
    neck = prism(rng, (0, P + 4.8, -2.2), (0, P + 7.0, -2.6), 1.3, 1.1, 8, 0.0)
    H = P + 7.9  # head centre height
    nemes = np.array([(s * 1.9, H + 1.7, -3.3) for s in (-1, 1)] + [(s * 1.5, H + 2.1, -1.4) for s in (-1, 1)]
                     + [(0, H + 2.5, -2.4)] + [(s * 2.7, H - 0.3, -3.5) for s in (-1, 1)]
                     + [(s * 2.6, H - 3.4, -3.4) for s in (-1, 1)] + [(s * 2.1, H - 3.4, -2.0) for s in (-1, 1)]
                     + [(s * 2.2, H, -0.9) for s in (-1, 1)])
    stripes = [band(nemes, H + y - 0.2, H + y + 0.2, 0.04) for y in (-2.6, -1.6, -0.6, 0.4, 1.4)]
    face = slab(rng, -1.5, H - 1.7, -4.2, 1.5, H + 1.4, -2.6, 0.45, 0.02)
    nose = prism(rng, (0, H + 0.2, -4.2), (0, H - 0.6, -4.5), 0.3, 0.38, 4, 0.0)
    beard = prism(rng, (0, H - 1.6, -3.7), (0, H - 3.2, -3.8), 0.5, 0.38, 6, 0.0)
    eyes = [slab(rng, s * 0.65 - 0.32, H + 0.25, -4.32, s * 0.65 + 0.32, H + 0.55, -4.1, 0.03, 0.0) for s in (-1, 1)]
    return [("Plinth", GOLD[1], [plinth]), ("Trim", NAVY, [trim]), ("Body", GOLD[0], [torso, chest] + haunch + tail),
            ("Legs", GOLD[0], legs + paws), ("Neck", GOLD[0], [neck]), ("Headdress", GOLD[1], [nemes]),
            ("Stripes", NAVY, stripes), ("Face", GOLD[0], [face, nose, beard]), ("Eyes", NAVY, eyes)]


# ---------------------------------------------------------------- statues on podiums

def podium(rng, w, h):
    """A stepped navy podium with gold trim; returns pieces and its top height."""
    base = slab(rng, -w / 2 - 0.6, 0, -w / 2 - 0.6, w / 2 + 0.6, 0.9, w / 2 + 0.6, 0.2, 0.0)
    col = slab(rng, -w / 2, 0.9, -w / 2, w / 2, h - 0.9, w / 2, 0.2, 0.0)
    cap = slab(rng, -w / 2 - 0.4, h - 0.9, -w / 2 - 0.4, w / 2 + 0.4, h, w / 2 + 0.4, 0.2, 0.0)
    trim = [slab(rng, -w / 2 - 0.08, y - 0.18, -w / 2 - 0.08, w / 2 + 0.08, y + 0.18, w / 2 + 0.08, 0.05, 0.0)
            for y in (1.5, h - 1.5)]
    return [("Podium", NAVY, [base, col]), ("Trim", GOLD[1], [cap] + trim)], h


def warrior(rng):
    """A golden warrior with spear and shield on a podium (about 6 wide, 15 tall)."""
    pieces, P = podium(rng, 4.6, 4.2)
    legs = [slab(rng, s * 0.6 - 0.45, P, -0.45, s * 0.6 + 0.45, P + 3.0, 0.45, 0.15, 0.0) for s in (-1, 1)]
    feet = [slab(rng, s * 0.6 - 0.5, P, -0.75, s * 0.6 + 0.5, P + 0.5, 0.5, 0.12, 0.0) for s in (-1, 1)]
    kilt = np.array(ring(8, 1.45, P + 2.2, math.pi / 8, sz=0.7) + ring(8, 1.15, P + 3.5, math.pi / 8, sz=0.65))
    torso = slab(rng, -1.25, P + 3.4, -0.65, 1.25, P + 6.0, 0.65, 0.3, 0.0)
    belt = slab(rng, -1.3, P + 3.3, -0.72, 1.3, P + 3.75, 0.72, 0.08, 0.0)
    shoulders = [blob(rng, (s * 1.55, P + 5.6, 0), 0.65, 10, jitter=0.04) for s in (-1, 1)]
    arm_r = [prism(rng, (1.6, P + 5.5, 0), (1.85, P + 3.7, -0.5), 0.38, 0.33, 6, 0.0)]
    arm_l = [prism(rng, (-1.6, P + 5.5, 0), (-1.75, P + 4.0, -0.7), 0.38, 0.33, 6, 0.0)]
    neck = prism(rng, (0, P + 5.9, 0), (0, P + 6.5, 0), 0.4, 0.4, 6, 0.0)
    head = blob(rng, (0, P + 7.0, 0), 0.8, 12, jitter=0.03)
    helmet = np.array(ring(8, 0.95, P + 6.9, sz=1.05) + ring(8, 0.5, P + 8.0, sz=0.6))
    crest = slab(rng, -0.2, P + 7.5, -0.7, 0.2, P + 8.6, 1.1, 0.1, 0.0)
    spear = prism(rng, (1.95, P, -0.55), (1.95, P + 9.4, -0.55), 0.18, 0.18, 6, 0.0)
    tip = np.array(ring(4, 0.42, P + 9.3, c=(1.95, -0.55)) + [(1.95, P + 10.8, -0.55)])
    hand = [blob(rng, (1.95, P + 3.8, -0.55), 0.38, 8, jitter=0.02)]
    shield = np.array(ring(8, 1.5, -1.25, math.pi / 8, sz=1.25, c=(-2.0, 0)) + ring(8, 1.35, -1.55, math.pi / 8, sz=1.15, c=(-2.0, 0)))
    shield = shield[:, [0, 2, 1]] + (0, P + 4.3, 0)  # stand the disc up, facing -z
    boss = blob(rng, (-2.0, P + 4.3, -1.65), 0.42, 8, squash=(1, 1, 0.6), jitter=0.02)
    return pieces + [("Legs", GOLD[1], legs + feet), ("Kilt", GOLD[2], [kilt]), ("Body", GOLD[0], [torso, neck, head]),
                     ("Belt", GOLD[1], [belt]), ("Arms", GOLD[0], shoulders + arm_r + arm_l + hand),
                     ("Helmet", GOLD[2], [helmet, crest]), ("Spear", GOLD[1], [spear, tip]),
                     ("Shield", GOLD[2], [shield]), ("Boss", GOLD[1], [boss])]


def sword(rng):
    """A giant golden sword planted point-down in a podium (about 5 wide, 17 tall)."""
    pieces, P = podium(rng, 3.6, 3.6)
    blade = []
    for y, w in ((P - 0.3, 0.55), (P + 1.2, 1.1), (P + 8.4, 1.2)):
        for dx, dz in ((w, 0), (-w, 0), (0, 0.32), (0, -0.32)):
            blade.append((dx, y, dz))
    fuller = slab(rng, -0.18, P + 1.6, -0.4, 0.18, P + 7.8, 0.4, 0.05, 0.0)
    guard = slab(rng, -2.7, P + 8.4, -0.55, 2.7, P + 9.3, 0.55, 0.25, 0.0)
    ends = [blob(rng, (s * 2.75, P + 8.85, 0), 0.55, 8, jitter=0.02) for s in (-1, 1)]
    grip = prism(rng, (0, P + 9.3, 0), (0, P + 11.6, 0), 0.42, 0.38, 6, 0.0)
    wraps = [frustum(6, 0.5, P + y, 0.48, P + y + 0.25) for y in (9.8, 10.5, 11.2)]
    pommel = blob(rng, (0, P + 12.2, 0), 0.75, 10, jitter=0.04)
    return pieces + [("Blade", GOLD[2], [np.array(blade)]), ("Fuller", GOLD[0], [fuller]),
                     ("Guard", GOLD[1], [guard] + ends), ("Grip", GOLD[0], [grip]),
                     ("Wraps", GOLD[1], wraps), ("Pommel", GOLD[1], [pommel])]


# ---------------------------------------------------------------- gold

def gold_bar(rng):
    """One massive gold bar (about 8 long, 4 wide, 2.4 tall)."""
    return [("Bar", GOLD[0], [ingot(0, 0, 8, 4, 0, 2.4)]),
            ("Stamp", GOLD[1], [ingot(0, 0, 3.2, 1.6, 2.38, 0.14, 0.9)])]


def gold_stack(rng):
    """A pyramid stack of massive gold bars: 3, 2, 1 (about 14 wide, 7 tall)."""
    shade = [[], [], []]
    for row, n in enumerate((3, 2, 1)):
        for i in range(n):
            x = (i - (n - 1) / 2) * 4.4
            z = 0.25 * ((i + row) % 2 - 0.5)
            shade[(i + row) % 3].append(ingot(x, z, 4.2, 8, row * 2.3, 2.3, 0.82))
    return [("Bars", GOLD[k], shade[k]) for k in range(3) if shade[k]]


def trophy(rng):
    """A golden trophy cup standing on its own foot (about 7 wide, 7.6 tall)."""
    foot = frustum(8, 1.6, 1.3, 1.1, 1.9, math.pi / 8)
    stem = frustum(8, 0.5, 1.9, 0.4, 4.0, math.pi / 8)
    knot = blob(rng, (0, 3.2, 0), 0.75, 10, squash=(1, 0.7, 1), jitter=0.02)
    cup = np.array(ring(10, 0.6, 3.9) + ring(10, 1.9, 5.2) + ring(10, 2.5, 7.0) + ring(10, 2.75, 8.6))
    rim = frustum(10, 2.85, 8.4, 2.8, 8.95)
    handles = []
    for s in (-1, 1):
        a, b, c, d = (s * 2.2, 7.9, 0), (s * 3.6, 7.7, 0), (s * 3.6, 5.6, 0), (s * 2.0, 5.2, 0)
        handles += [prism(rng, a, b, 0.3, 0.3, 6, 0.0), prism(rng, b, c, 0.3, 0.3, 6, 0.0),
                    prism(rng, c, d, 0.3, 0.3, 6, 0.0)]
    pieces = [("Foot", GOLD[1], [foot, knot]), ("Stem", GOLD[0], [stem]), ("Cup", GOLD[0], [cup]),
              ("Rim", GOLD[2], [rim]), ("Handles", GOLD[2], handles)]
    return [(l, c, [np.asarray(p, float) - (0, 1.3, 0) for p in pts]) for l, c, pts in pieces]  # foot on the ground


ITEMS = [  # name, builder, seed, label, lineup width
    ("Sarcophagus", sarcophagus, 3, "Sarcophagus", 10),
    ("SarcophagusStanding", sarcophagus_standing, 3, "Standing sarcophagus", 4),
    ("Sphinx", sphinx, 5, "Sphinx", 11),
    ("WarriorStatue", warrior, 2, "Warrior statue", 7),
    ("SwordStatue", sword, 4, "Sword statue", 6),
    ("GoldBar", gold_bar, 1, "Gold bar", 9),
    ("GoldStack", gold_stack, 1, "Gold bars", 14),
    ("Trophy", trophy, 6, "Trophy", 8),
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

    partlib.GROUND = np.array((214, 186, 128), float)  # a sandy tomb floor for the previews
    partlib.GROUND2 = np.array((200, 172, 116), float)
    k = TA.Kit()
    TA.figure(k, 0)
    items = [("", None, 4)] + [(lbl, n, w) for n, _, _, lbl, w in ITEMS]
    gap, ppst, H = 3, 18, 600
    total = sum(w for *_, w in items) + gap * (len(items) - 1)
    parts, centres = [], []
    x = -total / 2
    for label, what, w in items:
        cx = -(x + w / 2)
        if what is None:
            parts += [Part(p.name, p.size, partlib.T(cx, 0, 0) @ p.cf, p.color) for p in k.parts]
        else:
            parts += parts_of(built[what], cx, 0, 0 if what not in ("Sphinx", "GoldStack") else 25)
        centres.append((label, cx))
        x += w + gap
    W = int((total + 6) * ppst)
    eye, target = (0, 40, -170), (0, 7, 0)
    fov = 2 * np.degrees(np.arctan(H / 2 / ppst / 172))
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
    out.save(os.path.join(OUT, "tomb_lineup.png"))

    a = render(parts_of(built["Sphinx"], 0, 0, 25) + [Part(p.name, p.size, partlib.T(-8, 0, -1) @ p.cf, p.color) for p in k.parts],
               eye=(-14, 12, -24), target=(0, 5, 0), W=720, H=720, fov=50, fog=False, outline=False)
    scene = (parts_of(built["Sarcophagus"], -6, 14, 90) + parts_of(built["Sarcophagus"], 6, 14, 90)
             + parts_of(built["SarcophagusStanding"], -14, 26, 0) + parts_of(built["SarcophagusStanding"], 14, 26, 0)
             + parts_of(built["WarriorStatue"], -16, 8, 20) + parts_of(built["SwordStatue"], 16, 8, -20)
             + parts_of(built["GoldStack"], 0, 30, 0) + parts_of(built["GoldBar"], -8, 2, 30)
             + parts_of(built["Trophy"], 8, 2, -20))
    scene += [Part(p.name, p.size, partlib.T(0, 0, -6) @ p.cf, p.color) for p in k.parts]
    b = render(scene, eye=(0, 20, -36), target=(0, 5, 14), W=1280, H=720, fov=60, fog=False, outline=False)
    out = Image.new("RGB", (2000, 720))
    out.paste(a, (0, 0))
    out.paste(b, (720, 0))
    out.save(os.path.join(OUT, "tomb_scene.png"))


if __name__ == "__main__":
    main()
