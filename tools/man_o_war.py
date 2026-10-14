"""Man o' War: World 3 Cnidaria (the reef), Epic. A big tapered, stepped gas balloon lying
along the body, periwinkle blue at the nose running through violet to pink at the upturned
tail, darker stop bands at each step; a tall ribbed magenta crest sail arching along its back
(magenta slabs ribbed in light pink, a dark rim along the top), big googly eyes on the front, you
riding on the front half, little blue polyps underneath and six long deep-blue stinging
tentacles trailing back in three sections, curling up at the ends to glowing pink pyramid tips.

    python3 tools/man_o_war.py [--gif]

writes designs/cnidaria/ManOWar.bbmodel and previews in
/mnt/project-files/world3/cnidaria/renders/. ZYX, every bone rests at 0.
Bones: root (the float; rider on the front half) -> Crest; root -> Tent1..6 -> Tent1b..6b -> Tent1c..6c.

  idle    drifting, rocking side to side, the crest swaying, tentacles waving
  walk    leaning forward, tentacles trailing
  gallop  nosed down, crest flattened back a little, tentacles streaming
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from cnidaria_kit import TAU, Build, finish, rot, track  # noqa: E402

NAME = "ManOWar"
COLORS = {"f0": (104, 136, 255), "f1": (140, 136, 255), "f2": (178, 128, 248), "f3": (216, 120, 232),
          "f4": (246, 116, 210), "f5": (255, 128, 196), "stop": (86, 70, 190), "stop2": (170, 60, 160),
          "crest": (236, 72, 196), "crest2": (255, 140, 222), "rib": (150, 36, 140), "tent": (52, 82, 214),
          "tent2": (100, 132, 255), "polyp": (70, 190, 255), "glow": (255, 92, 214), "white": (255, 255, 255),
          "pupil": (24, 20, 40)}
Y = 9.0
# the float, front to back: (z0, z1, width, height, lift, colour); a darker stop band at each joint
FLOAT = [(-7.0, -5.4, 3.6, 3.2, -0.1, "f0"), (-5.4, -2.8, 4.6, 4.0, 0.0, "f1"), (-2.8, 0.6, 5.6, 4.8, 0.1, "f2"),
         (0.6, 3.6, 5.0, 4.4, 0.35, "f3"), (3.6, 6.0, 3.8, 3.4, 0.7, "f4"), (6.0, 7.8, 2.4, 2.4, 1.1, "f5")]
CREST = (2.4, 3.4, 4.2, 4.7, 4.9, 4.6, 3.8, 2.6)  # sail heights, front to back


def build():
    b = Build(NAME, COLORS)
    root = b.group("root", (0, Y, 0))
    for k, (z0, z1, w, h, lift, col) in enumerate(FLOAT):
        c = (0, Y + lift, (z0 + z1) / 2)
        b.box(root, f"Float{k + 1}", c, (w, h, z1 - z0), col)
        if 1 <= k <= 4:  # rounder: a wider, shorter slab through the middle
            b.box(root, f"FloatSide{k + 1}", (c[0], c[1] - 0.2, c[2]), (w + 0.8, h * 0.6, z1 - z0 - 0.4), col)
        if k:
            pw, ph = min(w, FLOAT[k - 1][2]), min(h, FLOAT[k - 1][3])
            b.box(root, f"Stop{k}", (0, Y + (lift + FLOAT[k - 1][4]) / 2, z0), (pw + 0.3, ph + 0.3, 0.4),
                  "stop" if k < 3 else "stop2")
    for s in (-1, 1):
        n = "LR"[s > 0]
        b.eye(root, n, (s * 0.85, Y + 0.3, -7.04), (0, 0, -1), 1.4, look=(-s * 0.3, 0))
    # the crest sail: tall slabs in two pinks, dark ribs between them, a dark rim along the top
    crest = b.group("Crest", (0, Y + 2.4, 1.0), root)
    z = -2.2
    for k, h in enumerate(CREST):
        base = Y + 2.2 + 0.05 * k
        b.box(crest, f"Crest{k + 1}", (0, base + h / 2, z), (0.9, h, 1.0), "crest")
        b.box(crest, f"CrestRim{k + 1}", (0, base + h + 0.2, z), (1.15, 0.45, 1.0), "rib")
        if k:
            hh = min(h, CREST[k - 1])
            b.box(crest, f"Rib{k}", (0, base + hh / 2, z - 0.5), (1.15, hh, 0.3), "crest2")
        z += 1.0
    # little polyps under the float
    for k in range(6):
        x = (-1.4, 1.4)[k % 2]
        b.box(root, f"Polyp{k + 1}", (x, Y - 2.6, -2.4 + 1.6 * (k // 2) * 1.2), (0.9, 1.4, 0.9), "polyp")
    # six long stinging tentacles trailing back, curling up at the ends, glowing pyramid tips
    spots = [(-1.3, -3.6), (1.3, -3.6), (-0.7, -0.6), (0.7, -0.6), (-1.2, 2.4), (1.2, 2.4)]
    for k, (x, z) in enumerate(spots):
        t0 = np.array([x, Y - 2.0, z])
        g1 = b.group(f"Tent{k + 1}", t0, root)
        t1 = t0 + np.array([x * 0.3, -2.4, 2.2])
        b.bar(g1, f"Tent{k + 1}a", t0, t1, 0.6, "tent", over=0.2)
        g2 = b.group(f"Tent{k + 1}b", t1, g1)
        t2 = t1 + np.array([x * 0.1, -1.6, 3.2])
        b.bar(g2, f"Tent{k + 1}b", t1, t2, 0.5, "tent2", over=0.2)
        g3 = b.group(f"Tent{k + 1}c", t2, g2)
        t3 = t2 + np.array([0, -0.6, 3.0])
        b.bar(g3, f"Tent{k + 1}c", t2, t3, 0.42, "tent", over=0.2)
        b.spike(g3, f"GlowTip{k + 1}", t3, t3 + np.array([0, 0.5, 1.2]), 0.6, "glow")
    return b.model()


def animations():
    def swim(L, lean, roll, crest, sway, trail):
        tr = {"root": [track(L, lambda u: (lean, 0, roll * math.sin(TAU * u)), 16),
                       track(L, lambda u: (0, 0.6 * math.sin(TAU * u - 0.8), 0), 16, "position")],
              "Crest": [track(L, lambda u: (-crest[1], 0, -crest[0] * math.sin(TAU * u - 0.6)), 16)]}
        for k in range(6):
            ph = k * 0.9
            tr[f"Tent{k + 1}"] = [track(L, lambda u, ph=ph: (trail + sway * math.sin(TAU * u - ph), 0,
                                                              sway * 0.5 * math.cos(TAU * u - ph)), 16)]
            tr[f"Tent{k + 1}b"] = [track(L, lambda u, ph=ph: (trail * 0.6 + 1.4 * sway * math.sin(TAU * u - ph - 1.0), 0,
                                                               sway * 0.6 * math.cos(TAU * u - ph - 1.0)), 16)]
            tr[f"Tent{k + 1}c"] = [track(L, lambda u, ph=ph: (trail * 0.3 + 1.8 * sway * math.sin(TAU * u - ph - 2.0), 0,
                                                               sway * 0.8 * math.cos(TAU * u - ph - 2.0)), 16)]
        return tr
    return {"idle": (2.4, swim(2.4, 0, 6, (10, 0), 10, 0)),
            "walk": (1.2, swim(1.2, -6, 4, (8, 6), 10, 14)),
            "gallop": (0.6, swim(0.6, -12, 3, (6, 14), 8, 32))}


if __name__ == "__main__":
    finish(build(), animations(), dict(eye=(-26, 22, -32), target=(0, 7, 0), fov=34), sheet_target=(0, 7, 0))
