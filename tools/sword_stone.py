"""Sword in the stone statue (QM, Oct 13): a chunky boulder with a sword stuck in its
top, all carved from one yellowish-tinted stone, in the rock meshes' style (faceted convex
pieces, flat shaded, studded; each piece its own MeshPart in its own shade).

Run: python3 tools/sword_stone.py
Writes design/sword_stone/SwordStone.obj, design/sword_stone/pieces/SwordStone_<i>.obj
(same origin; colours in pieces/colours.txt) and design/sword_stone/sword_stone.png.
"""

import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import partlib  # noqa: E402
from partlib import Part, render  # noqa: E402
import terrain_assets as TA  # noqa: E402
from rock_meshes import chunk, hull_tris, write_obj  # noqa: E402
from plant_meshes import blob, parts_of  # noqa: E402
from crimson_meshes import slab  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "sword_stone")
STONE = [(214, 196, 142), (196, 178, 126), (236, 222, 172), (204, 186, 132), (222, 204, 150)]  # yellowish rock


def sword_stone(rng):
    rock = [chunk(rng, 0, 0, 4.6, 4.4, sides=8, wobble=0.12, bevel=0.32, slope=(0.05, -0.04)),
            chunk(rng, -3.4, 1.6, 2.6, 2.6, sides=7, bevel=0.35),
            chunk(rng, 3.2, -1.8, 2.2, 1.8, sides=7, bevel=0.4)]
    top = 4.6  # the rock's top under the sword
    tilt = math.radians(6)
    up = np.array([math.sin(tilt), math.cos(tilt), 0.0])  # the sword leans a touch

    def along(t):
        return np.array([0.2, top, 0.0]) + up * t

    # blade: a flat diamond section tapering to the (buried) point
    blade = []
    for t, w in ((-2.5, 0.4), (0.0, 1.05), (5.4, 1.15)):
        c = along(t)
        for dx, dz in ((w, 0), (-w, 0), (0, 0.32), (0, -0.32)):
            blade.append(c + np.array([dx * math.cos(tilt), -dx * math.sin(tilt), dz]))
    guard_c = along(5.85)
    guard = slab(rng, -2.8, -0.5, -0.65, 2.8, 0.5, 0.65, 0.25, 0.03)
    guard = guard @ np.array([[math.cos(tilt), -math.sin(tilt), 0], [math.sin(tilt), math.cos(tilt), 0], [0, 0, 1]]).T + guard_c
    grip = []
    for t, r in ((6.3, 0.45), (8.2, 0.4)):
        c = along(t)
        for i in range(6):
            a = 2 * math.pi * i / 6
            grip.append(c + np.array([math.cos(a) * r * math.cos(tilt), -math.cos(a) * r * math.sin(tilt), math.sin(a) * r]))
    pommel = blob(rng, along(8.75), 0.75, 10, jitter=0.05)
    return [("Rock", STONE[0], [rock[0]]), ("Rock", STONE[1], rock[1:]),
            ("Blade", STONE[2], [np.array(blade)]), ("Guard", STONE[3], [guard]),
            ("Grip", STONE[1], [np.array(grip)]), ("Pommel", STONE[4], [pommel])]


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    raw = sword_stone(np.random.default_rng(4))
    pieces = [(label, col, [hull_tris(p) for p in pts]) for label, col, pts in raw]
    allh = [x for _, _, hs in pieces for x in hs]
    nt = write_obj("SwordStone", allh, os.path.join(OUT, "SwordStone.obj"))
    lines = ["# piece: label, RGB"]
    for i, (label, col, hs) in enumerate(pieces):
        write_obj(f"SwordStone_{i + 1}", hs, os.path.join(OUT, "pieces", f"SwordStone_{i + 1}.obj"))
        lines.append(f"SwordStone_{i + 1}: {label}, {col[0]}, {col[1]}, {col[2]}")
    with open(os.path.join(OUT, "pieces", "colours.txt"), "w") as f:
        f.write("\n".join(lines) + "\n")
    pts = np.concatenate([np.concatenate(h) for h in allh])
    size = pts.max(0) - np.array([pts.min(0)[0], 0, pts.min(0)[2]])
    print(f"SwordStone: {len(pieces)} pieces, {nt} tris, {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f}")

    partlib.GROUND = np.array((150, 170, 70), float)
    partlib.GROUND2 = np.array((132, 152, 60), float)
    k = TA.Kit()
    TA.figure(k, 0)
    fig = [Part(p.name, p.size, partlib.T(-9, 0, -5) @ p.cf, p.color) for p in k.parts]
    parts = parts_of(pieces) + fig
    a = render(parts, eye=(-14, 12, -26), target=(0, 5, 0), W=800, H=800, fov=40, fog=False, outline=False)
    b = render(parts, eye=(18, 9, -22), target=(0, 5.5, 0), W=800, H=800, fov=40, fog=False, outline=False)
    out = Image.new("RGB", (1600, 800))
    out.paste(a, (0, 0))
    out.paste(b, (800, 0))
    out.save(os.path.join(OUT, "sword_stone.png"))


if __name__ == "__main__":
    main()
