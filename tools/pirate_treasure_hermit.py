"""Treasure Hermit: World 3 Pirate Cove's Rare (Oct 14). A purple hermit crab that has moved into
a pirate's treasure chest: a wooden chest of planks with gold bands, gold corners, a big gold
lock with a keyhole and studs, its lid propped open on gold coins, pearls and a glowing ruby.
Out of the front pokes the crab: a purple head with eye stalks and googly eyes, two claws
(the right one huge) and four walking legs. You ride on the chest's lid.

Run: python3 tools/pirate_treasure_hermit.py [--gif]

Bones: root (chest) -> Lid (hinged at the back, peeks open), neck (head), ClawL, ClawR,
LegL1..2, LegR1..2.

  idle    the lid creaks open and shut, the claws snap, eyes look about
  walk    legs scuttle, the chest rocks side to side
  gallop  fast scuttle, the chest bouncing, the lid clattering
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU

NAME = "TreasureHermit"
C = {"wood": (170, 98, 46), "wooddark": (110, 60, 30), "crab": (160, 70, 220), "crabdark": (104, 40, 160),
     "crabbelly": (250, 200, 236), "tip": (40, 30, 50), "pearl": (250, 246, 236), "ruby": (255, 40, 80),
     "emerald": (40, 230, 120), "lock": (255, 210, 60)}


def build():
    m = Model(NAME, C)
    zc = 1.2      # the chest's centre
    y_b, H = 1.0, 3.6  # bottom and height of the chest box
    W, D = 6.4, 5.4
    root = m.group("root", (0, y_b + H / 2, zc))
    yt = y_b + H
    p = [m.box("Chest", (0, y_b + H / 2, zc), (W, H, D), "wood")]
    # plank grooves (dark strips) on the sides and front
    for k, y in enumerate((y_b + 1.2, y_b + 2.4)):
        p += [m.box(f"PlankF{k + 1}", (0, y, zc - D / 2 - 0.02), (W - 0.2, 0.14, 0.08), "wooddark"),
              m.box(f"PlankL{k + 1}", (-W / 2 - 0.02, y, zc), (0.08, 0.14, D - 0.2), "wooddark"),
              m.box(f"PlankR{k + 1}", (W / 2 + 0.02, y, zc), (0.08, 0.14, D - 0.2), "wooddark")]
    # gold bands round the chest (two vertical straps), gold corner posts, gold studs on the straps
    for s in (-1, 1):
        n = "LR"[s > 0]
        p += [m.box(f"Strap{n}", (s * 1.8, y_b + H / 2, zc), (0.6, H + 0.1, D + 0.12), "gold"),
              m.box(f"StrapBack{n}", (s * 1.8, y_b + H / 2, zc), (0.62, H + 0.1, D + 0.12), "golddark")][0:1]
        for cz in (-1, 1):
            p.append(m.box(f"Corner{n}{'FB'[cz > 0]}", (s * (W / 2 - 0.15), y_b + H / 2, zc + cz * (D / 2 - 0.15)),
                           (0.5, H + 0.12, 0.5), "golddark"))
        for j, y in enumerate((y_b + 0.7, y_b + 1.8, y_b + 2.9)):
            p.append(m.box(f"Stud{n}{j + 1}", (s * 1.8, y, zc - D / 2 - 0.1), (0.25, 0.25, 0.12), "golddark"))
    p.append(m.box("Base", (0, y_b + 0.15, zc), (W + 0.3, 0.3, D + 0.3), "wooddark"))
    # the lock: a gold plate hanging from the lid's front, with a black keyhole
    p += [m.box("Lock", (0, yt - 0.5, zc - D / 2 - 0.2), (1.2, 1.4, 0.3), "lock"),
          m.box("Keyhole", (0, yt - 0.45, zc - D / 2 - 0.37), (0.25, 0.25, 0.05), "black"),
          m.box("KeySlot", (0, yt - 0.75, zc - D / 2 - 0.37), (0.12, 0.4, 0.05), "black")]
    # treasure heaped in the open top: coins, pearls, a ruby and an emerald (seen under the lid)
    p.append(m.box("Hoard", (0, yt + 0.1, zc), (W - 0.6, 0.4, D - 0.6), "gold"))
    for k, (x, z, col, sz) in enumerate(((-1.8, -1.2, "gold", 0.9), (0.4, -1.6, "gold", 0.8), (1.9, -0.9, "golddark", 0.8),
                                         (-0.6, -0.6, "pearl", 0.6), (1.0, -0.4, "pearl", 0.5),
                                         (-2.2, 0.2, "golddark", 0.7))):
        p.append(m.box(f"Coin{k + 1}", (x, yt + 0.45, zc + z), (sz, 0.3, sz), col))
    p += [m.box("Glow_Ruby", (-0.2, yt + 0.75, zc - 1.6), (0.8, 0.8, 0.8), "ruby"),
          m.box("Glow_Emerald", (2.2, yt + 0.6, zc - 1.7), (0.6, 0.6, 0.6), "emerald")]
    # coins spilling over the front lip and down the front
    for k, (x, y, z) in enumerate(((-2.3, yt - 0.05, -2.75), (-2.6, yt - 1.0, -2.8), (2.5, yt - 0.3, -2.8))):
        p.append(m.box(f"Spill{k + 1}", (x, y, zc + z), (0.7, 0.7, 0.18), "gold"))
    m.put(root, p)

    # the lid: hinged along the top back edge, propped open 25 degrees; you sit on it
    hinge = np.array([0, yt, zc + D / 2])
    lid = m.group("Lid", tuple(hinge), root)
    tilt = np.radians(24)
    rot = np.array([[1, 0, 0], [0, math.cos(tilt), -math.sin(tilt)], [0, math.sin(tilt), math.cos(tilt)]])

    def on_lid(c):
        return hinge + rot @ (np.array(c, float) - hinge)

    lp = []
    for nm, c, sz, col in (("LidBox", (0, yt + 0.6, zc), (W + 0.2, 1.2, D + 0.2), "wood"),
                           ("LidTop", (0, yt + 1.45, zc), (W - 0.4, 0.5, D - 1.0), "wood"),
                           ("LidStrapL", (-1.8, yt + 0.85, zc), (0.65, 1.8, D + 0.3), "gold"),
                           ("LidStrapR", (1.8, yt + 0.85, zc), (0.65, 1.8, D + 0.3), "gold"),
                           ("LidRimF", (0, yt + 0.12, zc - D / 2 - 0.05), (W + 0.3, 0.3, 0.3), "golddark"),
                           ("LidGem", (0, yt + 1.2, zc - D / 2 - 0.1), (0.7, 0.7, 0.2), "ruby"),
                           ("LidSkull", (0, yt + 1.75, zc - 0.2), (1.2, 0.12, 1.1), "white"),
                           ("LidSkullEyeL", (-0.25, yt + 1.82, zc - 0.3), (0.3, 0.06, 0.3), "black"),
                           ("LidSkullEyeR", (0.25, yt + 1.82, zc - 0.3), (0.3, 0.06, 0.3), "black")):
        lp.append(m.box(nm, on_lid(c), sz, col, rot))
    m.put(lid, lp)

    # the crab: its body tucked into the front of the chest, the head poking out under the lip
    hy, hz = y_b + 1.4, zc - D / 2 - 1.3
    neck = m.group("neck", (0, hy, zc - D / 2), root)
    h = [m.box("Head", (0, hy, hz), (3.2, 2.0, 2.4), "crab"),
         m.box("HeadPlate", (0, hy + 1.05, hz + 0.1), (2.6, 0.3, 2.0), "crabdark"),
         m.box("Face", (0, hy - 0.4, hz - 1.25), (2.2, 0.8, 0.12), "crabbelly"),
         m.box("Mouth", (0, hy - 0.5, hz - 1.33), (1.0, 0.2, 0.06), "tip")]
    for s in (-1, 1):
        n = "LR"[s > 0]
        base = np.array([s * 0.8, hy + 1.0, hz - 0.5])
        top = base + np.array([s * 0.4, 1.8, -0.2])
        h += [m.seg(f"Stalk{n}", base, top, 0.4, 0.4, "crab"),
              m.box(f"EyeBall{n}", top + [0, 0.45, 0], (1.1, 1.1, 1.1), "crabdark")]
        h += m.eye(f"Eye{n}", top + [0, 0.5, -0.57], "front", size=0.95, look=(s * 0.2, 0, 0))
        # antennae
        h.append(m.seg(f"Antenna{n}", (s * 0.4, hy + 0.3, hz - 1.2), (s * 1.4, hy + 2.6, hz - 2.6), 0.18, 0.18, "crabdark"))
    m.put(neck, h)

    for s in (-1, 1):
        n = "LR"[s > 0]
        k = 1.35 if s > 0 else 0.9
        sh = np.array([s * 1.9, hy - 0.2, zc - D / 2 - 0.6])
        claw = m.group(f"Claw{n}", tuple(sh), root)
        el = sh + np.array([s * 0.9, 0.2, -1.0])
        pc = el + np.array([0, 0.3 * k, -1.2 * k])
        q = [m.seg(f"Arm{n}", sh, el, 0.8, 0.8, "crab"),
             m.box(f"Palm{n}", pc, (1.7 * k, 1.7 * k, 1.9 * k), "crab"),
             m.box(f"PalmBump{n}", pc + np.array([s * 0.3 * k, 0.9 * k, 0]), (0.9 * k, 0.25 * k, 1.3 * k), "crabdark"),
             m.box(f"Finger{n}", pc + np.array([0, 0.4 * k, -1.4 * k]), (1.2 * k, 0.8 * k, 1.0 * k), "crab"),
             m.pyr(f"FingerTip{n}", pc + np.array([0, 0.4 * k, -1.9 * k]), (0, -0.25, -1), (1, 0, 0), 1.0 * k, 0.55 * k, 0.38 * k, "tip"),
             m.box(f"Thumb{n}", pc + np.array([0, -0.55 * k, -1.3 * k]), (1.0 * k, 0.6 * k, 0.9 * k), "crab"),
             m.pyr(f"ThumbTip{n}", pc + np.array([0, -0.55 * k, -1.75 * k]), (0, 0.25, -1), (1, 0, 0), 0.8 * k, 0.45 * k, 0.28 * k, "tip")]
        m.put(claw, q)
        for i, (zz, fz) in enumerate(((zc - D / 2 - 0.4, -0.7), (zc - D / 2 + 0.6, 0.2))):
            nm = f"Leg{n}{i + 1}"
            hip = np.array([s * (W / 2 - 0.3), y_b + 0.6, zz])
            leg = m.group(nm, tuple(hip), root)
            knee = hip + np.array([s * 1.6, 1.0, fz])
            tip = knee + np.array([s * 1.0, -(y_b + 1.5), fz * 0.6])
            m.put(leg, [m.seg(nm + "Upper", hip, knee, 0.65, 0.65, "crab"),
                        m.box(nm + "Knee", knee, (0.75, 0.75, 0.75), "crabdark"),
                        m.seg(nm + "Lower", knee, tip + np.array([0, 0.5, 0]), 0.55, 0.55, "crab"),
                        m.pyr(nm + "Tip", tip + np.array([0, 0.55, 0]), (0, -1, 0), (1, 0, 0), 0.6, 0.25, 0.25, "tip")])
    return m


def animations():
    def legs(L, swing, lift, n=16):
        tr = {}
        for i in range(2):
            for s, nm in ((-1, "L"), (1, "R")):
                ph = 0.0 if (i % 2 == 0) == (s < 0) else 0.5
                tr[f"Leg{nm}{i + 1}"] = [track(L, lambda u, s=s, ph=ph: (
                    0, s * swing * math.sin(TAU * (u + ph)), s * lift * max(0.0, math.cos(TAU * (u + ph)))), n)]
        return tr

    L = 3.0
    idle = {"Lid": [track(L, lambda u: (-10 * max(0.0, math.sin(TAU * u)) ** 2, 0, 0), 24)],
            "ClawR": [track(L, lambda u: (6 * math.sin(TAU * 2 * u), 0, 0), 16)],
            "ClawL": [track(L, lambda u: (-5 * math.sin(TAU * 2 * u + 1), 0, 0), 16)],
            "neck": [track(L, lambda u: (0, 12 * math.sin(TAU * u), 0), 16)]}
    Lw = 0.7
    walk = {**legs(Lw, 22, 18),
            "root": [track(Lw, lambda u: (0, 0, 3 * math.sin(TAU * u)), 16)],
            "Lid": [track(Lw, lambda u: (-3 * max(0.0, math.sin(TAU * 2 * u)), 0, 0), 16)],
            "ClawR": [track(Lw, lambda u: (5 * math.sin(TAU * u), 0, 0), 16)],
            "ClawL": [track(Lw, lambda u: (-5 * math.sin(TAU * u), 0, 0), 16)]}
    Lg = 0.36
    gallop = {**legs(Lg, 30, 24),
              "root": [track(Lg, lambda u: (-3, 0, 4 * math.sin(TAU * u)), 16),
                       track(Lg, lambda u: (0, 0.7 * abs(math.sin(TAU * u)), 0), 16, "position")],
              "Lid": [track(Lg, lambda u: (-8 * max(0.0, math.sin(TAU * u)), 0, 0), 16)],
              "ClawR": [track(Lg, lambda u: (-15 + 8 * math.sin(TAU * u), 0, 0), 16)],
              "ClawL": [track(Lg, lambda u: (-15 - 8 * math.sin(TAU * u), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


if __name__ == "__main__":
    build().save(animations())
