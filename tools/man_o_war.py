"""Man o' War: World 3 Cnidaria (the reef), Epic. A big periwinkle gas float lying along the
body, blushing pink at both ends, with a frilly magenta crest sail standing up along its back
half (a row of slabs of different heights, a dark rim along the top), big googly eyes on the
front, you riding on the front half, a fringe of little blue polyps underneath and six long
deep-blue stinging tentacles with glowing pink pyramid tips trailing down and back.

    python3 tools/man_o_war.py [--gif]

writes designs/cnidaria/ManOWar.bbmodel and previews in
/mnt/project-files/world3/cnidaria/renders/. ZYX, every bone rests at 0.
Bones: root (the float; rider on the front half) -> Crest; root -> Tent1..6 -> Tent1b..6b.

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
COLORS = {"float": (132, 150, 255), "float2": (104, 118, 236), "blush": (255, 128, 206), "crest": (236, 72, 196),
          "crest2": (255, 140, 222), "rim": (150, 36, 140), "tent": (52, 82, 214), "tent2": (100, 132, 255),
          "polyp": (70, 190, 255), "glow": (255, 92, 214), "white": (255, 255, 255), "pupil": (24, 20, 40)}
Y = 9.0


def build():
    b = Build(NAME, COLORS)
    root = b.group("root", (0, Y, 0))
    b.box(root, "Float", (0, Y, 0), (5.2, 4.0, 9.6), "float")
    b.box(root, "FloatSide", (0, Y - 0.2, 0), (6.0, 3.0, 8.0), "float")
    b.box(root, "FloatBelly", (0, Y - 2.1, 0), (4.6, 0.6, 8.6), "float2")
    b.box(root, "Nose", (0, Y - 0.1, -5.3), (4.2, 3.2, 1.2), "blush")
    b.box(root, "Tail", (0, Y + 0.3, 5.3), (4.0, 3.2, 1.2), "blush")
    b.box(root, "Tail2", (0, Y + 0.6, 6.2), (2.6, 2.4, 0.8), "blush")
    for s in (-1, 1):
        n = "LR"[s > 0]
        b.eye(root, n, (s * 1.3, Y + 0.5, -5.95), (0, 0, -1), 1.6, look=(-s * 0.3, 0))
    # the crest sail along the back half: slabs of different heights, a dark rim on top
    crest = b.group("Crest", (0, Y + 2.0, 2.0), root)
    heights = (1.4, 2.4, 3.1, 3.5, 3.4, 2.8, 1.8)
    for k, h in enumerate(heights):
        z = -0.6 + 1.0 * k
        col = "crest" if k % 2 == 0 else "crest2"
        b.box(crest, f"Crest{k + 1}", (0, Y + 2.0 + h / 2 - 0.2, z), (0.9, h, 1.05), col)
        b.box(crest, f"CrestRim{k + 1}", (0, Y + 1.8 + h + 0.15, z), (1.1, 0.4, 1.0), "rim")
    # little polyps under the float
    for k in range(8):
        x = (-1.6, 1.6)[k % 2]
        z = -3.0 + 0.95 * k
        b.box(root, f"Polyp{k + 1}", (x, Y - 2.8, z), (0.8, 1.2 + 0.4 * (k % 3), 0.8), "polyp")
    # six long stinging tentacles
    spots = [(-1.2, -2.0), (1.2, -2.0), (-0.8, 0.6), (0.8, 0.6), (-1.2, 3.0), (1.2, 3.0)]
    for k, (x, z) in enumerate(spots):
        t0 = np.array([x, Y - 2.2, z])
        t = b.group(f"Tent{k + 1}", t0, root)
        t1 = t0 + np.array([x * 0.4, -3.6, 0.8])
        b.bar(t, f"Tent{k + 1}a", t0, t1, 0.55, "tent", over=0.15)
        t2g = b.group(f"Tent{k + 1}b", t1, t)
        t2 = t1 + np.array([x * 0.2, -3.0, 1.2])
        b.bar(t2g, f"Tent{k + 1}b", t1, t2, 0.42, "tent2", over=0.15)
        d = (t2 - t1) / np.linalg.norm(t2 - t1)
        b.spike(t2g, f"GlowTip{k + 1}", t2 - d * 0.1, t2 + d * 1.1, 0.6, "glow")
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
        return tr
    return {"idle": (2.4, swim(2.4, 0, 6, (10, 0), 10, 0)),
            "walk": (1.2, swim(1.2, -6, 4, (8, 6), 10, 14)),
            "gallop": (0.6, swim(0.6, -12, 3, (6, 14), 8, 32))}


if __name__ == "__main__":
    finish(build(), animations(), dict(eye=(-26, 22, -32), target=(0, 7, 0), fov=34), sheet_target=(0, 7, 0))
