"""Low-poly pine trees for the world 2 base (QM, Oct 13), in the plant meshes' style
(tools/plant_meshes.py): faceted convex pieces, flat shaded, studded, one colour per piece.

A pine is a tall tapering trunk (wood #907D72, QM) with stacked faceted cone tiers,
each tier its own piece in its own shade of mustard (#E7B658). Three sizes: tall, taller, small.

Run: python3 tools/pine_meshes.py
Writes design/pines/<Name>.obj, design/pines/pieces/<Name>_<i>.obj (same origin; colours
in pieces/colours.txt) and design/pines/pines_lineup.png.
  --rocks: design/pines/rocks_w2.png, the rocks in ROCK_SHADES (near #999287)
  --scene: design/pines/world2_scene.png, pines, brown rocks, red flowers, mustard tufts
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
from plant_meshes import prism, parts_of  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "pines")
WOOD = (0x90, 0x7D, 0x72)  # QM's #907D72
NEEDLES = [(231, 182, 88), (214, 166, 74), (242, 196, 104), (222, 172, 80)]  # QM: #E7B658 mustard, in four shades


def cone(rng, y0, y1, r, sides=7, droop=0.5):
    """A faceted cone tier: a jittered ring (its rim drooping a little) up to a point."""
    pts = []
    a0 = rng.uniform(0, 2 * math.pi)
    for i in range(sides):
        a = a0 + 2 * math.pi * i / sides + rng.uniform(-0.2, 0.2)
        rr = r * (1 + rng.uniform(-0.12, 0.12))
        pts.append((math.cos(a) * rr, y0 - droop * rng.uniform(0.4, 1.0), math.sin(a) * rr))
        # an underside ring so the tier has a little thickness under its rim
        pts.append((math.cos(a) * rr * 0.55, y0 + 0.2, math.sin(a) * rr * 0.55))
    pts.append((rng.uniform(-0.2, 0.2), y1, rng.uniform(-0.2, 0.2)))
    return np.array(pts)


def pine(rng, height, tiers, base_r, trunk_r):
    """Trunk to just under the top, then tiers from about a third up, each smaller."""
    start = height * 0.28
    pieces = [("Trunk", WOOD, [prism(rng, (0, -0.4, 0), (0, height * 0.82, 0), trunk_r, trunk_r * 0.55, 6)])]
    span = height - start
    for t in range(tiers):
        f = t / tiers
        y0 = start + span * f * 0.82
        y1 = y0 + span * (0.42 if t < tiers - 1 else 0.5)
        r = base_r * (1 - f * 0.68)
        pieces.append(("Needles", NEEDLES[t % len(NEEDLES)], [cone(rng, y0, min(y1, height), r)]))
    return pieces


PINES = [  # name, seed, height, tiers, base radius, trunk radius, label
    ("Pine", 3, 22, 4, 5.2, 0.9, "Pine (22 tall)"),
    ("PineTall", 8, 30, 5, 5.8, 1.1, "Tall pine (30)"),
    ("PineSmall", 5, 14, 3, 4.0, 0.7, "Small pine (14)"),
]


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    built = {}
    colours = ["# piece: label, RGB"]
    for name, seed, h, tiers, br, tr, _ in PINES:
        raw = pine(np.random.default_rng(seed), h, tiers, br, tr)
        pieces = [(label, col, [hull_tris(p) for p in pts]) for label, col, pts in raw]
        built[name] = pieces
        allh = [x for _, _, hs in pieces for x in hs]
        nt = write_obj(name, allh, os.path.join(OUT, name + ".obj"))
        for i, (label, col, hs) in enumerate(pieces):
            write_obj(f"{name}_{i + 1}", hs, os.path.join(OUT, "pieces", f"{name}_{i + 1}.obj"))
            colours.append(f"{name}_{i + 1}: {label}, {col[0]}, {col[1]}, {col[2]}")
        print(f"{name}: {len(pieces)} pieces, {nt} tris")
    with open(os.path.join(OUT, "pieces", "colours.txt"), "w") as f:
        f.write("\n".join(colours) + "\n")

    partlib.GROUND = np.array((105, 255, 74), float)
    partlib.GROUND2 = np.array((77, 196, 63), float)
    k = TA.Kit()
    TA.figure(k, 0)
    items = [("", None, 4)] + [(lbl, n, 2 * br + 1) for n, _, _, _, br, _, lbl in PINES]
    gap, ppst, H = 4, 22, 820
    total = sum(w for *_, w in items) + gap * (len(items) - 1)
    parts, centres = [], []
    x = -total / 2
    for label, what, w in items:
        cx = -(x + w / 2)
        if what is None:
            parts += [Part(p.name, p.size, partlib.T(cx, 0, 0) @ p.cf, p.color) for p in k.parts]
        else:
            parts += parts_of(built[what], cx, 0, 15)
        centres.append((label, cx))
        x += w + gap
    W = int((total + 6) * ppst)
    eye, target = (0, 30, -150), (0, 14, 0)
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
    out.save(os.path.join(OUT, "pines_lineup.png"))


if __name__ == "__main__" and "--rocks" not in sys.argv and "--scene" not in sys.argv:
    main()


# The rocks for the world 2 base (QM, Oct 13): near #999287, five shades made the way
# tools/biome_rocks.SHADES makes the meadow's (the meadow's steps x 2.2 round the base).
ROCK_SHADES = [(153, 146, 135), (129, 124, 115), (173, 166, 150), (140, 137, 117), (164, 153, 144)]


def rocks_render():
    import rock_meshes as RM
    from rock_meshes import as_parts
    partlib.GROUND = np.array((105, 255, 74), float)
    partlib.GROUND2 = np.array((77, 196, 63), float)
    parts, x = [], 40.0
    for name, builder, seed, _ in RM.ROCKS:
        chunks = RM.build(builder, seed)
        pts = np.concatenate([np.concatenate(t) for t in chunks])
        w = float(np.ptp(pts[:, 0]))
        for i, c in enumerate(chunks):
            parts += as_parts([c], x - w / 2, 0, 20, color=ROCK_SHADES[i % 5])
        x -= w + 3
    img = render(parts, eye=(-24, 30, -95), target=(-24, 5, 0), W=1600, H=600, fov=42, fog=False, outline=False)
    img.save(os.path.join(OUT, "rocks_w2.png"))


if __name__ == "__main__" and "--rocks" in sys.argv:
    rocks_render()


# World 2 flowers and grass (QM, Oct 13): red petals (QM's colour came through as #907D72
# again, so a plain red), and the grass tufts in the pines' mustard (#E7B658).
RED_PETALS = (222, 52, 56)
W2_GRASS = [NEEDLES[0], NEEDLES[1]]


def scene_render():
    """A world 2 corner: pines, the brown rocks, red flowers, mustard tufts."""
    import plant_meshes as PM
    import rock_meshes as RM
    partlib.GROUND = np.array((105, 255, 74), float)
    partlib.GROUND2 = np.array((77, 196, 63), float)
    pines = {n: [(l, c, [hull_tris(p) for p in pts]) for l, c, pts in pine(np.random.default_rng(s), h, t, br, tr)]
             for n, s, h, t, br, tr, _ in PINES}
    flower = PM.build(PM.flower, 2)
    grass = PM.build(PM.grass, 5)
    rng = np.random.default_rng(2)
    scene = parts_of(pines["PineTall"], 4, 30, 0) + parts_of(pines["Pine"], -10, 24, 40) + parts_of(pines["PineSmall"], 14, 20, 80)
    scene += parts_of(pines["Pine"], 24, 34, 10) + parts_of(pines["PineSmall"], -22, 32, 0)
    for name, x, z in (("RockCrag", -6, 12), ("RockBoulder", 12, 8), ("RockStone", -16, 6)):
        b = dict((n, f) for n, f, _, _ in RM.ROCKS)[name]
        s = dict((n, s) for n, _, s, _ in RM.ROCKS)[name]
        for i, c in enumerate(RM.build(b, s)):
            scene += RM.as_parts([c], x, z, 30, color=ROCK_SHADES[i % 5])
    for _ in range(10):  # the flowers and tufts at 2x, as in the lobby
        x, z = rng.uniform(-20, 20), rng.uniform(-6, 10)
        sc = parts_of(flower, recolour={"Petals": RED_PETALS})
        for p in sc:
            p.cf = partlib.T(x, 0, z) @ partlib.Ry(rng.uniform(0, 360)) @ np.diag([2, 2, 2, 1]) @ p.cf
            p.stud_axes = None
        scene += sc
    for _ in range(8):
        x, z = rng.uniform(-22, 22), rng.uniform(-6, 14)
        sc = []
        for (_, _, hs), wcol in zip(grass, W2_GRASS):
            sc += RM.as_parts(hs, 0, 0, 0, color=wcol)
        for p in sc:
            p.cf = partlib.T(x, 0, z) @ partlib.Ry(rng.uniform(0, 360)) @ np.diag([2, 2, 2, 1]) @ p.cf
            p.stud_axes = None
        scene += sc
    k = TA.Kit()
    TA.figure(k, 0)
    scene += [Part(p.name, p.size, partlib.T(0, 0, -6) @ p.cf, p.color) for p in k.parts]
    img = render(scene, eye=(0, 24, -50), target=(0, 9, 14), W=1280, H=720, fov=55, fog=False, outline=False)
    img.save(os.path.join(OUT, "world2_scene.png"))


if __name__ == "__main__" and "--scene" in sys.argv:
    scene_render()
