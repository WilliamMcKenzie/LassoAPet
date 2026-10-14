"""Blue-Ringed Octopus: World 3 Cnidaria (the reef), Rare. A sunny yellow octopus covered in
glowing electric-blue rings (each ring a glowing blue block round a dark ochre centre), a
domed mantle you sit on, bulging googly eyes on the front, a little beak smile, and eight
curly arms spread round it in a skirt, each banded with more rings and curling up at the
tip.

    python3 tools/blue_ring_octopus.py [--gif]

writes designs/cnidaria/BlueRingOctopus.bbmodel and previews in
/mnt/project-files/world3/cnidaria/renders/. ZYX, every bone rests at 0.
Bones: root (head + mantle; rider on top) -> Arm1..8 -> Arm<i>b -> Arm<i>c.

  idle    hovering, arms rippling round in a slow wave
  walk    arms pulling together and spreading (a jet stroke), leaning forward
  gallop  fast hard strokes, arms trailing back between strokes
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from cnidaria_kit import TAU, Build, finish, rot, track  # noqa: E402

NAME = "BlueRingOctopus"
COLORS = {"skin": (255, 204, 40), "skin2": (240, 168, 24), "dark": (176, 104, 18), "ring": (38, 120, 255),
          "ringc": (150, 86, 14), "beak": (60, 34, 20), "white": (255, 255, 255), "pupil": (24, 20, 30)}
Y = 6.0  # the head's middle


def ring(b, node, name, center, normal, size=1.5):
    """A glowing blue ring: a glowing block with a dark centre poking through it."""
    n = np.array(normal, float)
    n /= np.linalg.norm(n)
    up = np.array([0, 1.0, 0]) if abs(n[1]) < 0.9 else np.array([0, 0, 1.0])
    x = np.cross(up, n)
    x /= np.linalg.norm(x)
    M = np.stack([x, np.cross(n, x), n], axis=1)
    c = np.array(center, float)
    b.box(node, "Glow" + name, c, (size, size, 0.3), "ring", M)
    b.box(node, "RingC" + name, c + n * 0.04, (size * 0.45, size * 0.45, 0.32), "ringc", M)


def build():
    b = Build(NAME, COLORS)
    root = b.group("root", (0, Y, 0))
    # head: a rounded block (two crossed slabs) with the mantle dome above, leaning back a little
    b.box(root, "Head1", (0, Y, 0), (6.0, 3.4, 4.4), "skin")
    b.box(root, "Head2", (0, Y, 0), (4.4, 3.4, 6.0), "skin")
    b.box(root, "Skirt", (0, Y - 1.9, 0), (5.2, 0.6, 5.2), "skin2")
    tiers = ((6.0, 1.6, 0.4), (5.0, 1.4, 0.8), (3.6, 1.0, 1.1))
    y = Y + 1.7
    for k, (w, h, back) in enumerate(tiers):
        b.box(root, f"Mantle{k + 1}a", (0, y + h / 2, back), (w, h, w * 0.7), "skin" if k != 1 else "skin2")
        b.box(root, f"Mantle{k + 1}b", (0, y + h / 2, back), (w * 0.7, h, w), "skin" if k != 1 else "skin2")
        y += h
    # rings over the mantle and head sides/back
    spots = [((0, Y + 2.5, 2.95), (0, 0, 1)), ((-2.6, Y + 2.6, 0.6), (-1, 0, 0)), ((2.6, Y + 2.6, 0.6), (1, 0, 0)),
             ((-1.6, Y + 4.2, 2.7), (0, 0, 1)), ((1.6, Y + 4.2, 2.7), (0, 0, 1)), ((-2.1, Y + 4.0, -0.4), (-1, 0, 0)),
             ((2.1, Y + 4.0, -0.4), (1, 0, 0)), ((0, Y + 5.0, -1.7), (0, 0, -1)), ((-3.0, Y - 0.4, 0), (-1, 0, 0)),
             ((3.0, Y - 0.4, 0), (1, 0, 0)), ((0, Y + 0.2, 3.0), (0, 0, 1))]
    for k, (c, n) in enumerate(spots):
        ring(b, root, f"Ring{k + 1}", c, n)
    # bulging eyes on the front, beak smile under them
    for s in (-1, 1):
        n = "LR"[s > 0]
        b.box(root, "EyeBump" + n, (s * 1.5, Y + 1.0, -2.6), (2.0, 2.0, 1.2), "skin2")
        b.eye(root, n, (s * 1.5, Y + 1.05, -3.24), (0, 0, -1), 1.6, look=(-s * 0.3, 0))
        b.box(root, "Lid" + n, (s * 1.5, Y + 2.3, -2.7), (2.2, 0.5, 0.9), "skin")
    b.box(root, "Beak", (0, Y - 0.6, -3.05), (1.2, 0.5, 0.3), "beak")
    for s in (-1, 1):
        b.box(root, "BeakEnd" + "LR"[s > 0], (s * 0.7, Y - 0.42, -3.05), (0.35, 0.5, 0.3), "beak")
    # eight curly arms in a skirt, ringed, tips curling up
    for k in range(8):
        a = math.radians(22.5 + 45 * k)
        d = np.array([math.sin(a), 0, math.cos(a)])
        up = np.array([0, 1.0, 0])
        p0 = np.array([0, Y - 1.6, 0]) + d * 2.0
        p1 = p0 + d * 2.8 - up * 2.4
        p2 = p1 + d * 2.8 - up * 1.0
        p3 = p2 + d * 1.6 + up * 1.6
        tip = p3 - d * 0.5 + up * 0.9
        arm = b.group(f"Arm{k + 1}", p0, root)
        b.bar(arm, f"Arm{k + 1}a", p0, p1, 1.5, "skin", over=0.3)
        ring(b, arm, f"ArmRing{k + 1}a", (p0 + p1) / 2 + up * 0.62 + d * 0.5, up + d * 0.9, 1.2)
        arm2 = b.group(f"Arm{k + 1}b", p1, arm)
        b.bar(arm2, f"Arm{k + 1}b", p1, p2, 1.2, "skin", over=0.3)
        ring(b, arm2, f"ArmRing{k + 1}b", (p1 + p2) / 2 + up * 0.62, up + d * 0.3, 1.0)
        arm3 = b.group(f"Arm{k + 1}c", p2, arm2)
        b.bar(arm3, f"Arm{k + 1}c", p2, p3, 0.9, "skin2", over=0.25)
        b.bar(arm3, f"Arm{k + 1}d", p3, tip, 0.65, "skin2", over=0.2)
    return b.model()


def animations():
    def swim(L, lean, bob, wave, stroke, trail):
        tr = {"root": [track(L, lambda u: (lean + 2 * math.sin(TAU * u), 0, 0), 16),
                       track(L, lambda u: (0, bob * math.sin(TAU * u - 0.6), 0), 16, "position")]}
        for k in range(8):
            a = math.radians(22.5 + 45 * k)
            # rotation about the axis across the arm (tangent), so + lifts the arm
            tx, tz = math.cos(a), -math.sin(a)
            back = -math.cos(a)  # front arms (-z) swing most when trailing
            ph = TAU * k / 8

            def f(u, j, tx=tx, tz=tz, ph=ph, back=back):
                v = (wave * math.sin(TAU * u - ph - 0.8 * j) + stroke * (j + 1) * 0.6 * math.sin(TAU * u - 0.6 * j)
                     + trail * (1 if j == 0 else 0.4) * (0.5 + 0.5 * back))
                return (v * tx, 0, v * tz)
            for j, suf in enumerate(("", "b", "c")):
                tr[f"Arm{k + 1}{suf}"] = [track(L, lambda u, j=j, f=f: f(u, j), 16)]
        return tr
    return {"idle": (2.4, swim(2.4, 0, 0.6, 9, 0, 0)),
            "walk": (1.0, swim(1.0, -8, 1.0, 4, 10, 4)),
            "gallop": (0.5, swim(0.5, -16, 1.2, 3, 14, 10))}


if __name__ == "__main__":
    finish(build(), animations(), dict(eye=(-26, 22, -32), target=(0, 5, 0), fov=34), sheet_target=(0, 5, 0))
