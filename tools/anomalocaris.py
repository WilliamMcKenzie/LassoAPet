"""Anomalocaris: World 3 Cnidaria (the reef), Uncommon. The prehistoric "weird shrimp":
a long coral-red segmented body with four chunky orange swim lobes down each side
that ripple in a wave, a rounded head with two big googly eyes up on stalks, two spiny
grasping arms curled under its chin (cream with dark red pyramid spines), a little yellow ring
mouth underneath, and a tail fan of three blue pyramid blades.

    python3 tools/anomalocaris.py [--gif]

writes designs/cnidaria/Anomalocaris.bbmodel and previews in
/mnt/project-files/world3/cnidaria/renders/. ZYX, every bone rests at 0.
Bones: root (front body; rider on the back) -> neck (head, eye stalks) -> ArmL/ArmR -> ArmL2/ArmR2;
root -> Seg2 -> Seg3 -> Seg4 -> Tail; each body bone holds its own FlapL<i>/FlapR<i>.

  idle    hovering, flaps rippling slowly, arms flexing, body gently waving
  walk    flaps rippling faster, body undulating up and down
  gallop  fast ripple, big undulation, arms tucked
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from cnidaria_kit import TAU, Build, finish, rot, track  # noqa: E402

NAME = "Anomalocaris"
COLORS = {"body": (240, 78, 62), "body2": (206, 52, 50), "dark": (140, 30, 40), "flap": (255, 150, 52),
          "flap2": (255, 196, 70), "arm": (255, 226, 190), "spine": (170, 36, 46), "mouth": (255, 214, 40),
          "tail": (58, 170, 255), "white": (255, 255, 255), "pupil": (24, 20, 30)}
Y = 4.6
# body segments, front to back: (bone, z0, z1, width, height)
SEGS = [("root", -3.0, 0.0, 4.6, 2.8), ("root", 0.0, 2.6, 4.8, 2.8), ("Seg2", 2.6, 5.0, 4.4, 2.5),
        ("Seg3", 5.0, 7.2, 3.8, 2.2), ("Seg4", 7.2, 9.2, 3.0, 1.9), ("Tail", 9.2, 10.8, 2.2, 1.6)]


def build():
    b = Build(NAME, COLORS)
    bones = {"root": b.group("root", (0, Y, -1.0))}
    parent = bones["root"]
    for name, z0, *_ in SEGS[2:]:
        bones[name] = parent = b.group(name, (0, Y, z0), parent)
    # body segments: a block each, alternating two reds; four chunky flap lobes down each side
    for i, (bone, z0, z1, w, h) in enumerate(SEGS):
        node = bones[bone]
        y = Y - 0.05 * i
        b.box(node, f"Body{i + 1}", (0, y, (z0 + z1) / 2), (w, h, z1 - z0 + 0.1), "body" if i % 2 == 0 else "body2")
        if 1 <= i <= 4:
            fl = 3.6 - 0.4 * (i - 1)  # lobe reach
            for s in (-1, 1):
                n = "LR"[s > 0]
                piv = (s * (w / 2 - 0.2), y - 0.3, (z0 + z1) / 2)
                f = b.group(f"Flap{n}{i}", piv, node)
                M = rot(("z", s * 10), ("y", s * -14))
                b.box(f, f"Flap{n}{i}", np.array(piv) + M @ np.array([s * fl / 2, 0, 0.3]),
                      (fl, 0.5, z1 - z0 + 0.8), "flap" if i % 2 else "flap2", M)
    # tail fan: three blue pyramid blades flaring out the back
    tail = bones["Tail"]
    for k, yaw in enumerate((-34, 0, 34)):
        d = rot(("y", yaw), ("x", 8)) @ np.array([0, 0, 1.0])
        base = np.array([0, Y - 0.2, 10.4])
        b.spike(tail, f"TailBlade{k + 1}", base, base + d * (4.2 - 0.8 * (yaw == 0)), 1.6, "tail", d=0.5)

    # head: rounded, ring mouth underneath, eyes on stalks, two spiny arms
    neck = bones["neck"] = b.group("neck", (0, Y, -3.0), bones["root"])
    b.box(neck, "Head", (0, Y + 0.1, -4.5), (4.0, 2.6, 3.2), "body")
    b.box(neck, "Snout", (0, Y - 0.2, -6.4), (2.8, 2.0, 1.0), "body")
    b.box(neck, "Mouth", (0, Y - 1.3, -4.8), (1.8, 0.4, 1.8), "mouth")
    for s in (-1, 1):
        n = "LR"[s > 0]
        stalk0 = np.array([s * 1.4, Y + 1.2, -5.2])
        stalk1 = stalk0 + np.array([s * 1.3, 1.6, -0.4])
        b.bar(neck, "Stalk" + n, stalk0, stalk1, 0.6, "body2")
        b.box(neck, "EyeBall" + n, stalk1 + (0, 0.5, 0), (1.6, 1.6, 1.6), "body")
        b.eye(neck, n, stalk1 + (0, 0.5, -0.84), (0, 0, -1), (1.3, 1.4), look=(-s * 0.3, 0))
        # grasping arm: down from the snout, curling back under the chin, spines on the inside
        sh = np.array([s * 0.9, Y - 0.6, -6.6])
        arm = b.group("Arm" + n, sh, neck)
        el = sh + np.array([s * 0.3, -1.4, -1.6])
        b.bar(arm, f"Arm{n}1", sh, el, 0.8, "arm", over=0.2)
        arm2 = b.group("Arm" + n + "2", el, arm)
        wr = el + np.array([0, -1.5, 0.9])
        b.bar(arm2, f"Arm{n}2", el, wr, 0.7, "arm", over=0.2)
        p = (el + wr) / 2
        b.spike(arm2, f"ArmSpine{n}", p, p + np.array([0, 0.5, 0.7]), 0.4, "spine")
        b.spike(arm2, f"ArmClaw{n}", wr, wr + np.array([0, 0.6, 1.1]), 0.6, "spine")
    return b.model()


def animations():
    def swim(L, ripple, flap, und, armamp, lean=0.0, tuck=0.0):
        tr = {"root": [track(L, lambda u: (lean + und * 0.3 * math.sin(TAU * u), 0, 0), 16),
                       track(L, lambda u: (0, 0.4 * math.sin(TAU * u - 0.5), 0), 16, "position")],
              "neck": [track(L, lambda u: (-und * 0.4 * math.sin(TAU * u + 0.6), 0, 0), 16)]}
        for j, bone in enumerate(("Seg2", "Seg3", "Seg4", "Tail")):
            tr[bone] = [track(L, lambda u, j=j: (und * math.sin(TAU * u - 0.9 * (j + 1)), 0, 0), 16)]
        for i in range(1, 5):
            for s, n in ((1, "R"), (-1, "L")):
                tr[f"Flap{n}{i}"] = [track(L, lambda u, i=i, s=s: (
                    0, 0, s * flap * math.sin(TAU * ripple * u - 1.1 * i)), 16)]
        for s, n in ((1, "R"), (-1, "L")):
            tr["Arm" + n] = [track(L, lambda u: (-tuck + armamp * math.sin(TAU * u), 0, 0), 16)]
            tr["Arm" + n + "2"] = [track(L, lambda u: (-tuck - armamp * 1.3 * math.sin(TAU * u - 0.8), 0, 0), 16)]
        return tr
    return {"idle": (2.0, swim(2.0, 1, 18, 4, 8)),
            "walk": (1.0, swim(1.0, 1, 26, 8, 6, lean=-4)),
            "gallop": (0.5, swim(0.5, 1, 34, 12, 4, lean=-8, tuck=25))}


if __name__ == "__main__":
    finish(build(), animations(), dict(eye=(-26, 20, -30), target=(0, 4, 1), fov=34), sheet_target=(0, 4, 2))
