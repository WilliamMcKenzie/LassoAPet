"""Anomalocaris: World 3 Cnidaria (the reef), Uncommon. The prehistoric "weird shrimp":
a long coral-red segmented body with a row of overlapping orange swim flaps down each side
that ripple in a wave, a rounded head with two big googly eyes up on stalks, two spiny
grasping arms curled under its chin (cream with dark red spines), a little yellow ring
mouth underneath, and a tail fan of three pairs of blue-tipped blades.

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
    # body segments: a block each, a darker band at the back edge, flaps on both sides
    for i, (bone, z0, z1, w, h) in enumerate(SEGS):
        node = bones[bone]
        y = Y - 0.05 * i
        b.box(node, f"Body{i + 1}", (0, y, (z0 + z1) / 2), (w, h, z1 - z0 + 0.1), "body")
        b.box(node, f"Band{i + 1}", (0, y + 0.1, z1 - 0.25), (w + 0.12, h + 0.12, 0.5), "body2")
        b.box(node, f"Belly{i + 1}", (0, y - h / 2 - 0.05, (z0 + z1) / 2), (w * 0.7, 0.3, z1 - z0 - 0.2), "dark")
        if i < 5:
            fl = 3.4 - 0.35 * i  # flap reach
            for s in (-1, 1):
                n = "LR"[s > 0]
                piv = (s * (w / 2 - 0.2), y - 0.3, (z0 + z1) / 2)
                f = b.group(f"Flap{n}{i + 1}", piv, node)
                M = rot(("z", s * 10), ("y", s * -14))
                L = z1 - z0 + 0.5
                col = "flap" if i % 2 == 0 else "flap2"
                b.box(f, f"Flap{n}{i + 1}", np.array(piv) + M @ np.array([s * fl * 0.4, 0, 0.2]),
                      (fl * 0.8, 0.35, L), col, M)
                b.box(f, f"FlapEdge{n}{i + 1}", np.array(piv) + M @ np.array([s * (fl * 0.8 + 0.3), 0, 0.2]),
                      (0.9, 0.35, L * 0.65), col, M)
                b.box(f, f"FlapVein{n}{i + 1}", np.array(piv) + M @ np.array([s * fl * 0.45, 0.06, 0.2]),
                      (fl * 0.7, 0.35, 0.3), "dark", M)
    # tail fan: three pairs of blades flaring up and out
    tail = bones["Tail"]
    for k, (yaw, up) in enumerate(((14, 18), (34, 10), (56, 2))):
        for s in (-1, 1):
            n = "LR"[s > 0]
            base = np.array([s * 0.6, Y - 0.2, 10.4])
            d = rot(("y", s * yaw), ("x", up)) @ np.array([0, 0, 1.0])
            tip = base + d * (4.0 - 0.5 * k)
            b.bar(tail, f"TailBlade{n}{k + 1}", base, tip, 1.2, "body2", d=0.4)
            b.spike(tail, f"TailTip{n}{k + 1}", tip - d * 0.3, tip + d * 1.6, 1.2, "tail", d=0.45)

    # head: rounded, ring mouth underneath, eyes on stalks, two spiny arms
    neck = bones["neck"] = b.group("neck", (0, Y, -3.0), bones["root"])
    b.box(neck, "Head", (0, Y + 0.1, -4.5), (4.0, 2.6, 3.2), "body")
    b.box(neck, "HeadTop", (0, Y + 1.5, -4.3), (3.0, 0.5, 2.4), "body2")
    b.box(neck, "Snout", (0, Y - 0.2, -6.4), (2.8, 2.0, 1.0), "body")
    b.box(neck, "Mouth", (0, Y - 1.3, -4.8), (1.8, 0.4, 1.8), "mouth")
    b.box(neck, "MouthHole", (0, Y - 1.36, -4.8), (0.9, 0.4, 0.9), "dark")
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
        for j, t in enumerate((0.35, 0.75)):
            p = sh + (el - sh) * t
            b.spike(arm, f"ArmSpine{n}{j + 1}", p, p + np.array([0, -0.2, 0.7]), 0.35, "spine")
        arm2 = b.group("Arm" + n + "2", el, arm)
        wr = el + np.array([0, -1.5, 0.9])
        b.bar(arm2, f"Arm{n}2", el, wr, 0.7, "arm", over=0.2)
        tip = wr + np.array([0, 0.1, 1.2])
        b.bar(arm2, f"Arm{n}3", wr, tip, 0.6, "arm", over=0.15)
        for j, t in enumerate((0.3, 0.7)):
            p = el + (wr - el) * t
            b.spike(arm2, f"ArmSpine{n}{j + 3}", p, p + np.array([0, 0.5, 0.6]), 0.32, "spine")
        b.spike(arm2, f"ArmClaw{n}", tip, tip + np.array([0, 0.7, 0.4]), 0.45, "spine")
    return b.model()


def animations():
    def swim(L, ripple, flap, und, armamp, lean=0.0, tuck=0.0):
        tr = {"root": [track(L, lambda u: (lean + und * 0.3 * math.sin(TAU * u), 0, 0), 16),
                       track(L, lambda u: (0, 0.4 * math.sin(TAU * u - 0.5), 0), 16, "position")],
              "neck": [track(L, lambda u: (-und * 0.4 * math.sin(TAU * u + 0.6), 0, 0), 16)]}
        for j, bone in enumerate(("Seg2", "Seg3", "Seg4", "Tail")):
            tr[bone] = [track(L, lambda u, j=j: (und * math.sin(TAU * u - 0.9 * (j + 1)), 0, 0), 16)]
        for i in range(5):
            for s, n in ((1, "R"), (-1, "L")):
                tr[f"Flap{n}{i + 1}"] = [track(L, lambda u, i=i, s=s: (
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
