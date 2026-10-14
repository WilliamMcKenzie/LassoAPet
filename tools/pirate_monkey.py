"""Banana Monkey: World 3 Pirate Cove's Rare (Oct 14), the pirate's monkey (RotMG's Cave Pirate
Monkey). A chunky brown monkey knuckle-walking on all fours, chest high like a little gorilla:
a tan face and muzzle with a big grin, round ears, googly plate eyes, a red polka-dot pirate
bandana knotted at the back, a gold hoop earring, tan hands and feet, and its long tail curled
up over its back holding a big banana. You ride on its back in front of the tail.

Run: python3 tools/pirate_monkey.py [--gif]

Bones: root (body) -> neck (head); root -> ArmL, ArmR, LegL, LegR; root -> Tail -> Tail2.

  idle    sits back a little, head bobbing, tail waving the banana
  walk    knuckle-walk: arm and opposite leg together
  gallop  a bounding gallop, both arms then both legs, tail streaming
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU

NAME = "BananaMonkey"
C = {"fur": (140, 82, 44), "furdark": (96, 54, 30), "tan": (246, 200, 150), "tandark": (214, 160, 112),
     "red": (232, 40, 48), "banana": (255, 222, 40), "bananadark": (226, 176, 20), "stem": (90, 64, 30),
     "mouth": (120, 30, 40), "tooth": (255, 255, 255)}


def build():
    m = Model(NAME, C)
    y0 = 5.0
    root = m.group("root", (0, y0, 0))
    # torso: higher at the chest, sloping down to the hips
    p = [m.box("Chest", (0, y0 + 0.6, -1.4), (4.4, 4.0, 3.4), "fur"),
         m.box("Hips", (0, y0 - 0.2, 1.6), (3.8, 3.2, 3.0), "fur"),
         m.box("Belly", (0, y0 - 0.6, -0.6), (3.0, 2.6, 3.6), "tan"),
         m.box("Back", (0, y0 + 2.7, -1.0), (3.6, 0.4, 3.0), "furdark"),
         m.box("Mane", (0, y0 + 2.9, -2.6), (3.8, 0.8, 0.8), "furdark")]
    m.put(root, p)

    # head: a brown skull with a big tan face, muzzle, ears, bandana and earring
    hy, hz = y0 + 2.2, -4.6
    neck = m.group("neck", (0, y0 + 1.6, -3.0), root)
    h = [m.box("Head", (0, hy, hz), (3.6, 3.4, 3.2), "fur"),
         m.box("Face", (0, hy - 0.1, hz - 1.65), (2.8, 2.6, 0.2), "tan"),
         m.box("Brow", (0, hy + 0.85, hz - 1.75), (3.0, 0.5, 0.4), "furdark"),
         m.box("Muzzle", (0, hy - 0.8, hz - 2.2), (2.4, 1.5, 1.2), "tan"),
         m.box("Nose", (0, hy - 0.25, hz - 2.85), (0.9, 0.4, 0.15), "furdark"),
         m.box("Mouth", (0, hy - 1.15, hz - 2.82), (1.7, 0.35, 0.1), "mouth"),
         m.box("Teeth", (0, hy - 0.98, hz - 2.85), (1.3, 0.18, 0.08), "tooth")]
    h += m.eye("EyeL", (-0.65, hy + 0.35, hz - 1.8), "front", size=1.0, look=(0.2, 0, 0))
    h += m.eye("EyeR", (0.65, hy + 0.35, hz - 1.8), "front", size=1.0, look=(-0.2, 0, 0))
    for s in (-1, 1):
        n = "LR"[s > 0]
        h += [m.box(f"Ear{n}", (s * 2.1, hy + 0.1, hz + 0.1), (0.6, 1.5, 1.5), "fur"),
              m.box(f"EarIn{n}", (s * 2.42, hy + 0.1, hz + 0.1), (0.1, 1.0, 1.0), "tandark")]
    # bandana: a red band round the head above the brow, white dots, a knot and two tails behind
    by = hy + 1.25
    h += [m.box("Bandana", (0, by, hz + 0.05), (3.8, 1.0, 3.4), "red"),
          m.box("BandanaTop", (0, by + 0.65, hz + 0.25), (3.4, 0.4, 2.8), "red"),
          m.box("Knot", (0, by - 0.1, hz + 1.9), (1.0, 0.9, 0.6), "red"),
          m.seg("BandTail1", (0.2, by - 0.2, hz + 2.1), (0.8, by - 1.6, hz + 2.9), 0.7, 0.3, "red"),
          m.seg("BandTail2", (-0.2, by - 0.2, hz + 2.1), (-0.6, by - 1.3, hz + 3.1), 0.7, 0.3, "red")]
    for k, (x, z, side) in enumerate(((-1.0, -1.72, 0), (0.6, -1.72, 0), (-1.92, -0.6, -1), (1.92, 0.4, 1),
                                      (-1.92, 0.9, -1), (1.92, -0.9, 1))):
        if side == 0:
            h.append(m.box(f"Dot{k + 1}", (x, by + 0.05, hz + z), (0.35, 0.35, 0.06), "white"))
        else:
            h.append(m.box(f"Dot{k + 1}", (side * 1.92, by + 0.05, hz + z), (0.06, 0.35, 0.35), "white"))
    # a gold hoop earring hanging from the left ear (a little square ring of blocks)
    ex, ey, ez = -2.15, hy - 1.0, hz + 0.1
    h += [m.box("HoopTop", (ex, ey + 0.4, ez), (0.18, 0.16, 0.6), "gold"),
          m.box("HoopBot", (ex, ey - 0.25, ez), (0.18, 0.16, 0.6), "gold"),
          m.box("HoopF", (ex, ey + 0.07, ez - 0.25), (0.18, 0.5, 0.16), "gold"),
          m.box("HoopB", (ex, ey + 0.07, ez + 0.25), (0.18, 0.5, 0.16), "gold")]
    m.put(neck, h)

    # long arms (knuckle-walking) and short legs
    for s in (-1, 1):
        n = "LR"[s > 0]
        sh = np.array([s * 2.5, y0 + 1.6, -1.8])
        arm = m.group(f"Arm{n}", tuple(sh), root)
        el = sh + np.array([s * 0.2, -3.3, -0.3])
        hand = np.array([sh[0] + s * 0.2, 0.55, sh[2] - 0.6])
        m.put(arm, [m.box(f"Shoulder{n}", sh, (1.6, 1.6, 1.6), "fur"),
                    m.seg(f"UpperArm{n}", sh, el, 1.4, 1.4, "fur"),
                    m.seg(f"Forearm{n}", el, hand + np.array([0, 0.4, 0]), 1.3, 1.3, "fur"),
                    m.box(f"Hand{n}", hand, (1.5, 1.1, 1.6), "tan"),
                    m.box(f"Knuckles{n}", hand + np.array([0, -0.1, -0.9]), (1.4, 0.9, 0.4), "tandark")])
        hip = np.array([s * 1.7, y0 - 0.6, 2.2])
        leg = m.group(f"Leg{n}", tuple(hip), root)
        kn = hip + np.array([s * 0.3, -1.6, -0.9])
        ft = np.array([hip[0] + s * 0.3, 0.45, hip[2] - 0.2])
        m.put(leg, [m.seg(f"Thigh{n}", hip, kn, 1.5, 1.5, "fur"),
                    m.seg(f"Shin{n}", kn, ft + np.array([0, 0.3, 0]), 1.3, 1.3, "fur"),
                    m.box(f"Foot{n}", ft + np.array([0, 0, -0.4]), (1.4, 0.9, 2.2), "tan")])

    # tail: up out of the rump and curling forward over the back, the tip wrapped round a banana
    t0 = np.array([0, y0 + 0.4, 3.1])
    tail = m.group("Tail", tuple(t0), root)
    pts = [t0, t0 + [0, 1.2, 1.4], t0 + [0, 3.0, 2.0], t0 + [0, 4.4, 1.6]]
    tq = [m.seg(f"Tail{k + 1}", a, b, 0.8, 0.8, "fur") for k, (a, b) in enumerate(zip(pts, pts[1:]))]
    tq += [m.box(f"TailJoint{k + 1}", q, (0.85, 0.85, 0.85), "fur") for k, q in enumerate(pts[1:3])]
    m.put(tail, tq)
    t2 = pts[3]
    tail2 = m.group("Tail2", tuple(t2), tail)
    p2 = [t2 + [0, 1.0, -0.4], t2 + [0, 0.8, -1.4]]
    q2 = [m.box("TailJoint3", t2, (0.85, 0.85, 0.85), "fur"),
          m.seg("Tail5", t2, p2[0], 0.8, 0.8, "fur"),
          m.seg("Tail6", p2[0], p2[1], 0.75, 0.75, "fur"),
          m.box("TailCurl", p2[1] + [0, -0.4, -0.2], (0.9, 0.9, 0.9), "furdark")]
    # the banana: a curved yellow bunch of five blocks held across the tail tip, brown ends
    bc = p2[1] + np.array([0, -0.75, 0.0])
    arc = [bc + [x, 0.9 * (x / 2.4) ** 2, 0] for x in np.linspace(-2.4, 2.4, 6)]
    for k, (a, b) in enumerate(zip(arc, arc[1:])):
        w = 1.05 - 0.12 * abs(k - 2)
        q2.append(m.seg(f"Banana{k + 1}", a, b, w, w, "banana"))
        q2.append(m.box(f"BananaRidge{k + 1}", (a + b) / 2 + [0, -w / 2 + 0.05, 0], (0.9 * np.linalg.norm(b - a), 0.12, 0.3), "bananadark"))
    q2 += [m.seg("BananaStem", arc[0], arc[0] + [-0.5, 0.6, 0], 0.4, 0.4, "stem"),
           m.box("BananaEnd", arc[-1] + [0.2, 0.15, 0], (0.4, 0.4, 0.4), "stem")]
    m.put(tail2, q2)
    return m


def animations():
    L = 2.0
    idle = {"root": [track(L, lambda u: (0, 0.15 * math.sin(TAU * u), 0), 16, "position")],
            "neck": [track(L, lambda u: (4 * math.sin(TAU * 2 * u), 10 * math.sin(TAU * u), 0), 24)],
            "Tail": [track(L, lambda u: (6 * math.sin(TAU * u), 0, 8 * math.sin(TAU * u + 0.6)), 16)],
            "Tail2": [track(L, lambda u: (8 * math.sin(TAU * u - 0.8), 0, 0), 16)],
            "ArmL": [track(L, lambda u: (3 * math.sin(TAU * u), 0, 0), 8)],
            "ArmR": [track(L, lambda u: (-3 * math.sin(TAU * u), 0, 0), 8)]}
    Lw = 0.8

    def gait(L, a, l, pairs):
        tr = {}
        for nm, ph, amp in pairs:
            tr[nm] = [track(L, lambda u, ph=ph, amp=amp: (amp * math.sin(TAU * (u + ph)), 0, 0), 16)]
        return tr

    walk = {**gait(Lw, 0, 0, (("ArmL", 0, 30), ("LegR", 0, 30), ("ArmR", 0.5, 30), ("LegL", 0.5, 30))),
            "root": [track(Lw, lambda u: (0, 0, 3 * math.sin(TAU * u)), 16),
                     track(Lw, lambda u: (0, 0.35 * abs(math.sin(TAU * u)), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (3 * math.sin(TAU * 2 * u), 0, 0), 16)],
            "Tail": [track(Lw, lambda u: (4 * math.sin(TAU * u), 0, 6 * math.sin(TAU * u)), 16)],
            "Tail2": [track(Lw, lambda u: (6 * math.sin(TAU * u - 1), 0, 0), 16)]}
    Lg = 0.45
    gallop = {**gait(Lg, 0, 0, (("ArmL", 0, 45), ("ArmR", 0.06, 45), ("LegL", 0.5, 45), ("LegR", 0.56, 45))),
              "root": [track(Lg, lambda u: (6 * math.sin(TAU * u), 0, 0), 16),
                       track(Lg, lambda u: (0, 1.0 * max(0.0, math.sin(TAU * u)), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (-6 * math.sin(TAU * u), 0, 0), 16)],
              "Tail": [track(Lg, lambda u: (-18 + 6 * math.sin(TAU * u), 0, 0), 16)],
              "Tail2": [track(Lg, lambda u: (-10 + 8 * math.sin(TAU * u - 1), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


if __name__ == "__main__":
    build().save(animations())
