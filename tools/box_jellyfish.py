"""Box Jellyfish: World 3 Cnidaria (the reef), Rare. A real cube of a jellyfish (made for
studs): a bright cyan box bell with a stepped cap, deep-blue corner pillars, glowing
electric-yellow zigzag bolts down each side and glowing yellow sense-eyes, big googly eyes
on the front under cross brows, a skirt lip, and at each bottom corner a thick pedalium
arm carrying three long ribbon tentacles that trail and sway.

    python3 tools/box_jellyfish.py [--gif]

writes designs/cnidaria/BoxJellyfish.bbmodel and previews in
/mnt/project-files/world3/cnidaria/renders/. ZYX, every bone rests at 0.
Bones: root (the bell; rider on top) -> Corner1..4 -> Tent<c>a..c -> Tent<c>a2..c2.

  idle    hovering, bobbing, tentacles swaying
  walk    jet pulses, leaning forward, tentacles trailing
  gallop  fast hard pulses, tentacles streaming back
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from cnidaria_kit import TAU, Build, finish, rot, track  # noqa: E402

NAME = "BoxJellyfish"
COLORS = {"bell": (70, 214, 255), "bell2": (40, 176, 238), "edge": (18, 92, 176), "glow": (255, 236, 64),
          "tent": (150, 236, 255), "tent2": (40, 150, 222), "brow": (16, 60, 120), "white": (255, 255, 255),
          "pupil": (18, 22, 40)}
Y = 9.0  # bell centre
H = 3.4  # half the bell's size


def bolt(b, node, name, origin, right, down, out):
    """A zigzag lightning bolt of four short glowing blocks on a face."""
    o = np.array(origin, float)
    pts = [o, o + right * 0.9 + down * 1.2, o - right * 0.3 + down * 1.9, o + right * 0.8 + down * 3.2]
    for k in range(3):
        b.bar(node, f"Glow{name}{k + 1}", pts[k] + out * 0.08, pts[k + 1] + out * 0.08, 0.45, "glow", d=0.3, over=0.15)


def build():
    b = Build(NAME, COLORS)
    root = b.group("root", (0, Y, 0))
    b.box(root, "Bell", (0, Y, 0), (2 * H, 2 * H, 2 * H), "bell")
    b.box(root, "Cap", (0, Y + H + 0.35, 0), (2 * H - 1.2, 0.7, 2 * H - 1.2), "bell2")
    b.box(root, "Cap2", (0, Y + H + 0.85, 0), (2 * H - 2.8, 0.4, 2 * H - 2.8), "bell")
    b.box(root, "Lip", (0, Y - H - 0.3, 0), (2 * H - 0.6, 0.6, 2 * H - 0.6), "bell2")
    b.box(root, "Velum", (0, Y - H - 0.62, 0), (2 * H - 2.0, 0.2, 2 * H - 2.0), "edge")
    for k in range(4):  # corner pillars and top-edge rims
        sx, sz = (1, 1, -1, -1)[k], (1, -1, -1, 1)[k]
        b.box(root, f"Pillar{k + 1}", (sx * (H - 0.1), Y, sz * (H - 0.1)), (0.8, 2 * H + 0.2, 0.8), "edge")
    for k, (dx, dz) in enumerate(((1, 0), (-1, 0), (0, 1), (0, -1))):
        size = (0.6, 0.6, 2 * H) if dx else (2 * H, 0.6, 0.6)
        b.box(root, f"Rim{k + 1}", (dx * (H - 0.1), Y + H - 0.1, dz * (H - 0.1)), size, "edge")
    # glowing sense-eyes and a lightning bolt on the back and both sides; googly eyes in front
    for n, out, right in (("B", (0, 0, 1), (-1, 0, 0)), ("L", (-1, 0, 0), (0, 0, -1)), ("R", (1, 0, 0), (0, 0, 1))):
        out, right = np.array(out, float), np.array(right, float)
        c = np.array([0, Y, 0]) + out * H
        b.box(root, "GlowSense" + n, c + out * 0.1 + np.array([0, -H + 1.3, 0]), np.abs(right) * 1.0 + np.abs(out) * 0.3 + (0, 0.8, 0), "glow")
        bolt(b, root, "Bolt" + n, c + np.array([0, H - 1.0, 0]) - right * 0.4, right, np.array([0, -1.0, 0]), out)
    for s in (-1, 1):
        n = "LR"[s > 0]
        b.eye(root, n, (s * 1.45, Y + 0.6, -H - 0.04), (0, 0, -1), 2.0, look=(-s * 0.3, -0.3))
        b.box(root, "Brow" + n, (s * 1.45, Y + 2.15, -H - 0.2), (2.2, 0.5, 0.4), "brow", rot(("z", s * 14)))
    b.box(root, "Mouth", (0, Y - 1.5, -H - 0.1), (1.6, 0.35, 0.3), "brow")
    for s in (-1, 1):
        b.box(root, "MouthEnd" + "LR"[s > 0], (s * 0.9, Y - 1.3, -H - 0.1), (0.35, 0.6, 0.3), "brow")
    # corner pedalia with three trailing ribbon tentacles each
    for k in range(4):
        sx, sz = (1, 1, -1, -1)[k], (1, -1, -1, 1)[k]
        top = np.array([sx * (H - 0.5), Y - H - 0.2, sz * (H - 0.5)])
        c = b.group(f"Corner{k + 1}", top, root)
        foot = top + np.array([sx * 0.6, -1.0, sz * 0.6])
        b.bar(c, f"Pedalium{k + 1}", top, foot, 1.3, "bell2", over=0.2)
        b.box(c, f"Foot{k + 1}", foot, (1.6, 0.8, 1.6), "edge", rot(("y", 45)))
        for j, (ox, oz) in enumerate(((1.2, -0.6), (-0.6, 1.2), (0.5, 0.5))):
            t0 = foot + np.array([sx * ox * 0.6, -0.3, sz * oz * 0.6])
            tn = b.group(f"Tent{k + 1}{'abc'[j]}", t0, c)
            L1 = 3.0 + 0.8 * (j == 2)
            t1 = t0 + np.array([sx * ox, -L1, sz * oz])
            b.bar(tn, f"Tent{k + 1}{'abc'[j]}1", t0, t1, 0.36, "tent", over=0.1)
            tn2 = b.group(f"Tent{k + 1}{'abc'[j]}2", t1, tn)
            t2 = t1 + np.array([sx * ox * 0.4, -3.2 + 0.6 * (j == 2), sz * oz * 0.4])
            b.bar(tn2, f"Tent{k + 1}{'abc'[j]}2", t1, t2, 0.28, "tent2", over=0.1)
            b.spike(tn2, f"GlowTip{k + 1}{'abc'[j]}", t2, t2 + (t2 - t1) / np.linalg.norm(t2 - t1) * 0.9, 0.5, "glow")
    return b.model()


def animations():
    def swim(L, lean, bob, sway, splay):
        tr = {"root": [track(L, lambda u: (lean + 2 * math.sin(TAU * u), 0, 0), 16),
                       track(L, lambda u: (0, bob * math.sin(TAU * u - 1.0), 0), 16, "position")]}
        for k in range(4):
            sx, sz = (1, 1, -1, -1)[k], (1, -1, -1, 1)[k]
            # corners kick out and in (splay), tentacles trail with lag
            tr[f"Corner{k + 1}"] = [track(L, lambda u, sx=sx, sz=sz: (
                -sz * splay * (0.5 + 0.5 * math.sin(TAU * u)), 0, sx * splay * (0.5 + 0.5 * math.sin(TAU * u))), 16)]
            for j, c in enumerate("abc"):
                ph = k * 0.7 + j * 0.9
                tr[f"Tent{k + 1}{c}"] = [track(L, lambda u, ph=ph: (sway * math.sin(TAU * u - ph) - lean * 0.6, 0,
                                                                     sway * 0.6 * math.cos(TAU * u - ph)), 16)]
                tr[f"Tent{k + 1}{c}2"] = [track(L, lambda u, ph=ph: (1.4 * sway * math.sin(TAU * u - ph - 1.0) - lean * 0.6, 0,
                                                                      sway * 0.8 * math.cos(TAU * u - ph - 1.0)), 16)]
        return tr
    return {"idle": (2.0, swim(2.0, 0, 0.8, 8, 6)),
            "walk": (1.0, swim(1.0, -8, 1.0, 10, 12)),
            "gallop": (0.5, swim(0.5, -18, 1.2, 10, 18))}


if __name__ == "__main__":
    finish(build(), animations(), dict(eye=(-26, 24, -34), target=(0, 7, 0), fov=34), sheet_target=(0, 7, 0))
