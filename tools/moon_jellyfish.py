"""Moon Jellyfish: World 3 Cnidaria (the reef), Common. A chubby lilac bell (one low-poly
dome mesh), four glowing pink horseshoe rings showing through
the top around the rider, big googly eyes on the front of the bell, a skirt of four
rim panels with little pink fringe tentacles with darker tips that pulse in and out, and four frilly pink oral
arms dangling underneath.

    python3 tools/moon_jellyfish.py [--gif]

writes designs/cnidaria/MoonJellyfish.bbmodel and previews in
/mnt/project-files/world3/cnidaria/renders/. ZYX, every bone rests at 0.
Bones: root (the bell; rider on top) -> SkirtF/B/L/R (rim panels + fringe),
root -> Arm1..4 -> Arm1b..4b (oral arms).

  idle    bobbing slowly, the skirt pulsing, arms swaying
  walk    quicker pulses, leaning into it
  gallop  big snappy pulses, nosed down, arms streaming back
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from cnidaria_kit import FRONT9, TAU, Build, Lathe, finish, lay, rot, track  # noqa: E402

NAME = "MoonJellyfish"
COLORS = {"bell": (196, 170, 255), "rim": (122, 88, 206), "glow": (255, 98, 186),
          "arm": (255, 150, 206), "arm2": (226, 92, 162), "fringe": (255, 96, 186), "fringe2": (196, 40, 132), "white": (255, 255, 255),
          "pupil": (24, 20, 40)}
Y = 7.0  # the bell's rim height


def build():
    b = Build(NAME, COLORS)
    root = b.group("root", (0, Y + 1.5, 0))
    # the bell: one low-poly dome (a mesh: QM Oct 15), a wide flat face on the front for the eyes
    bell = Lathe((0, 0, 0), [(Y - 0.1, 4.2), (Y + 1.2, 4.45), (Y + 2.6, 3.9), (Y + 3.6, 2.9), (Y + 4.3, 1.7)], FRONT9)
    b.hull(root, "Bell", bell.pts, "bell")
    # four glowing horseshoe pads on the upper faces, round the rider
    for k, i in enumerate((1, 3, 6, 8)):
        p, n = bell.face(i, Y + 3.1)
        b.box(root, f"Glow{k + 1}", p + n * 0.1, (1.5, 0.3, 0.8), "glow", lay(n))
    # big googly eyes on the front face
    for s in (-1, 1):
        p, n = bell.face(0, Y + 1.8)
        b.eye(root, "LR"[s > 0], p + np.array([s * 1.3, 0, 0]) + n * 0.04, n, 1.8, look=(-s * 0.4, 0))
    # skirt: four rim panels flaring out, each with three fringe tentacles
    for n, (dx, dz) in {"F": (0, -1), "B": (0, 1), "L": (-1, 0), "R": (1, 0)}.items():
        pivot = np.array([dx * 3.6, Y + 0.2, dz * 3.6])
        sk = b.group("Skirt" + n, pivot, root)
        M = rot(("y", math.degrees(math.atan2(dx, dz))))
        out = M @ np.array([0, 0, 1.0])
        side = M @ np.array([1.0, 0, 0])
        b.box(sk, "Skirt" + n, pivot + out * 0.4 + np.array([0, -0.5, 0]), (6.8, 1.2, 0.8), "rim",
              M @ rot(("x", 25)))
        for j, t in enumerate((-2.2, 0, 2.2)):
            top = pivot + out * 0.7 + side * t + np.array([0, -1.0, 0])
            end = top + out * 0.4 + np.array([0, -2.6 - 0.5 * (j == 1), 0])
            mid = top + (end - top) * 0.7
            b.bar(sk, f"Fringe{n}{j + 1}", top, mid, 0.4, "fringe")
            b.bar(sk, f"FringeTip{n}{j + 1}", mid, end, 0.4, "fringe2")
    # four frilly oral arms
    for k in range(4):
        a = math.radians(45 + 90 * k)
        d = np.array([math.sin(a), 0, math.cos(a)])
        top = np.array([0, Y - 0.2, 0]) + d * 0.9
        arm = b.group(f"Arm{k + 1}", top, root)
        mid = top + d * 0.5 + np.array([0, -3.0, 0])
        b.bar(arm, f"Arm{k + 1}a", top, mid, 0.9, "arm", d=0.6)
        b.box(arm, f"Frill{k + 1}a", (top + mid) / 2 + d * 0.45, (1.1, 1.6, 0.5), "arm2", rot(("y", math.degrees(a))))
        lo = b.group(f"Arm{k + 1}b", mid, arm)
        end = mid - d * 0.3 + np.array([0, -2.8, 0])
        b.bar(lo, f"Arm{k + 1}b", mid, end, 0.7, "arm", d=0.5)
        b.box(lo, f"Frill{k + 1}b", (mid + end) / 2 + d * 0.38, (0.9, 1.4, 0.45), "arm2", rot(("y", math.degrees(a))))
    return b.model()


def animations():
    def swim(L, pulse, bob, lean, armamp, beats=1):
        tr = {"root": [track(L, lambda u: (lean + 3 * math.sin(TAU * beats * u), 0, 2 * math.sin(TAU * u)), 16),
                       track(L, lambda u: (0, bob * math.sin(TAU * beats * u - 1.0), 0), 16, "position")]}
        # the skirt flares out (panels tip outward) then snaps in
        for n, axis, sgn in (("F", 0, -1), ("B", 0, 1), ("L", 2, 1), ("R", 2, -1)):
            def f(u, axis=axis, sgn=sgn):
                v = [0.0, 0.0, 0.0]
                v[axis] = sgn * (pulse * 0.5 + pulse * math.sin(TAU * beats * u))
                return tuple(v)
            tr["Skirt" + n] = [track(L, f, 16)]
        for k in range(4):
            a = math.radians(45 + 90 * k)
            cx, cz = math.cos(a), -math.sin(a)  # swing about the axis across the arm
            tr[f"Arm{k + 1}"] = [track(L, lambda u, k=k, cx=cx, cz=cz: (
                armamp * cx * math.sin(TAU * beats * u - k), 0, armamp * cz * math.sin(TAU * beats * u - k)), 16)]
            tr[f"Arm{k + 1}b"] = [track(L, lambda u, k=k, cx=cx, cz=cz: (
                1.4 * armamp * cx * math.sin(TAU * beats * u - k - 1.2), 0,
                1.4 * armamp * cz * math.sin(TAU * beats * u - k - 1.2)), 16)]
        return tr
    return {"idle": (2.0, swim(2.0, 9, 0.8, 0, 8)),
            "walk": (1.0, swim(1.0, 12, 1.0, -10, 10)),
            "gallop": (0.5, {**swim(0.5, 16, 1.2, -22, 8),
                             **{f"Arm{k + 1}": [track(0.5, lambda u, k=k: (28 + 6 * math.sin(TAU * u - k), 0, 0), 8)] for k in range(4)}})}


if __name__ == "__main__":
    finish(build(), animations(), dict(eye=(-26, 22, -32), target=(0, 6, 0), fov=30), sheet_target=(0, 6, 0))
