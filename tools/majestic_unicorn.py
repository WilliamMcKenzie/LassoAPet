"""Majestic Unicorn: World 2 Meadow's Legendary. A grander unicorn than World 1's: pearl
white with lilac shading, a long twisted gold horn, gold hooves, and a long rainbow mane
and tail made of separate strands on their own bones that stream back and ripple as if
in the wind (every animation, idle too). Built on animal_designs.Animal (the Horse's
layout and quadruped animations) with the mane and tail bones added.

    python3 tools/majestic_unicorn.py

writes designs/world2/MajesticUnicorn.bbmodel and renders to
/mnt/project-files/animals/majestic_unicorn/.
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import rot_x  # noqa: E402
from partlib import Part, T, Ry, render  # noqa: E402
from horse_rig import pose  # noqa: E402
from snow_designs import pyramid  # noqa: E402

PEARL = (252, 250, 255)
LILAC = (226, 214, 246)
GOLD = (255, 200, 60)
RAINBOW = A.RAINBOW  # red, orange, yellow, green, blue, purple
MANE_N = 6
TAIL_N = 4


def unicorn():
    a = A.Animal("MajesticUnicorn", "Legendary")
    A.horse_body(a, PEARL, RAINBOW[5], GOLD, A.PINK, cap=False, stripe=False, tail=False)
    a.bone_order = [b for b in a.bone_order if b[0] != "Tail"]

    # lilac socks above the gold hooves
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        z0 = -2.7 + 0.001 if front else 3.3 - 0.001 - 1.1
        xa, xb = sorted((sx * 0.5, sx * 1.6))
        a.box("Sock" + leg, (xa - 0.05 * (sx < 0), 0.8, z0 - 0.05), (xb + 0.05 * (sx > 0), 1.5, z0 + 1.15), LILAC, "Leg" + leg)

    # twisted gold horn: blocks turning 45 degrees each, narrowing, a pyramid tip
    y, w = 10.5, 0.7
    for i in range(4):
        h = 0.5
        p = Part("Horn" + (str(i + 1) if i else ""), (w, h, w), T(0, y + h / 2, -3.3) @ Ry(45 * (i % 2)), GOLD)
        p.bone = "neck"
        a.parts.append(p)
        y += h - 0.02
        w -= 0.12
    pyramid(a, "HornTip", (-w / 2, y, -3.3 - w / 2), (w / 2, y, -3.3 + w / 2), "+y", 0.9, GOLD, "neck")

    # lilac shading: belly and muzzle
    a.box("Belly", (-1.55, 3.45, -2.0), (1.55, 3.55, 2.6), LILAC, "root")
    for part in a.parts:
        if part.name in ("Snout", "Bridge"):
            part.color = LILAC

    # forelock: a rainbow tuft between the ears falling over the brow
    a.box("Forelock", (-0.45, 10.0, -2.3), (0.45, 11.0, -1.4), RAINBOW[0], "neck")

    # mane: six strands down the back of the head and neck, red at the top to purple at
    # the withers, each on its own bone pivoting where it meets the neck, so it can stream
    # back. The higher strands are longer.
    for i in range(MANE_N):
        bone = f"Mane{i + 1}"
        top = 11.0 - i * 0.95
        length = 3.0 - i * 0.2
        hw = (1.7 - 0.25 * i) / 2  # each strand 0.25 narrower than the one above: no z-fighting where they overlap (QM)
        a.box(bone, (-hw, top - 1.0, -1.15), (hw, top, -1.15 + length), RAINBOW[i], bone)
        a.wedge(bone + "Tip", (-hw, top - 1.0, -1.15 + length), (hw, top, -1.15 + length + 0.6), RAINBOW[i], bone, "up_back")
        a.pivots[bone] = (0, top - 0.5, -1.15)
        a.bone_order.append((bone, "neck"))

    # tail: four rainbow segments in a chain hanging from the rump, so it can flow
    parent, ztop = "root", 6.6
    for i in range(TAIL_N):
        bone = "Tail" if i == 0 else f"Tail{i + 1}"
        seg = 1.4
        c = RAINBOW[[5, 4, 3, 1][i]]
        a.box(bone, (-0.45, ztop - seg, 3.3), (0.45, ztop, 4.2), c, bone)
        a.pivots[bone] = (0, ztop, 3.3)
        a.bone_order.append((bone, parent))
        parent, ztop = bone, ztop - seg + 0.02
    a.wedge("TailTip", (-0.45, ztop - 0.8, 3.3), (0.45, ztop, 4.2), RAINBOW[0], parent, "down_back")

    a.meta = {"seat": (0, 7.3, 1.3), "neck_loop": {"center": (0, 7.4, -1.9), "radius": 1.35}}

    base = a.animations

    def anims():
        out = {}
        for name, (L, tracks) in base().items():
            tracks = dict(tracks)
            strong = {"idle": 0.0, "walk": 0.5, "gallop": 1.0}[name]
            cycles = max(1, round(L / 0.8))  # ripple period ~0.8 s, whole cycles per loop
            n = 16
            for i in range(MANE_N):
                stream = 50 - 38 * strong - 3 * i  # hangs down the neck at rest, streams back at speed
                amp = 6 + 6 * strong
                keys = [(round(L * k / n, 4), stream + amp * math.sin(2 * math.pi * (cycles * k / n - i * 0.12)))
                        for k in range(n + 1)]
                tracks[f"Mane{i + 1}"] = [rot_x(keys, "catmullrom")]
            for i in range(1, TAIL_N):
                bend = -(10 + 15 * strong)
                amp = 10 + 6 * strong
                keys = [(round(L * k / n, 4), bend + amp * math.sin(2 * math.pi * (cycles * k / n - i * 0.18)))
                        for k in range(n + 1)]
                tracks[f"Tail{i + 1}"] = [rot_x(keys, "catmullrom")]
            out[name] = (L, tracks)
        return out

    a.animations = anims
    return a


CAM = dict(eye=(-19, 12, -21), target=(0, 5.6, -0.5), W=420, H=460, fov=38)
SIDE = dict(eye=(-30, 6.5, -1), target=(0, 5.6, -1), W=420, H=460, fov=36)
BACK = dict(eye=(-16, 13, 20), target=(0, 5.6, 0), W=420, H=460, fov=38)


def main(out=os.path.join(A.ROOT, "designs", "world2"), shots="/mnt/project-files/animals/majestic_unicorn"):
    import json
    from PIL import Image
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = unicorn()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    old = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Unicorn.bbmodel")))
    walk = A.anim_named(m, "walk")
    tiles = [render(pose(old, None, 0), **CAM), render(pose(m, walk, 0.3), **CAM),
             render(pose(m, walk, 0.3), **SIDE), render(pose(m, walk, 0.3), **BACK)]
    im = Image.new("RGB", (420 * len(tiles), 460))
    for i, t in enumerate(tiles):
        im.paste(t, (420 * i, 0))
    A.label(im, ["World 1 Unicorn", "Majestic Unicorn · Legendary", "Side", "Back"]).save(os.path.join(shots, "MajesticUnicorn.png"))
    frames = []
    for name, n in (("idle", 24), ("walk", 20), ("gallop", 16)):
        anim = A.anim_named(m, name)
        for k in range(n):
            frames.append(A.label(render(pose(m, anim, k / n * anim["length"]), **SIDE), [name]))
    A.gif(os.path.join(shots, "MajesticUnicorn_anims.gif"), frames, fps=20)
    json.dump(m, open(os.path.join(shots, "MajesticUnicorn.bbmodel"), "w"), separators=(",", ":"))


if __name__ == "__main__":
    main(*sys.argv[1:])
