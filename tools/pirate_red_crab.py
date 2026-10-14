"""Red Crab: World 3 Pirate Cove's Common (Oct 14). A chunky beach crab: a wide red shell in two
stepped layers with orange speckles and a cream belly, a little ridge of bumps along the front,
two big black-tipped claws held up in front (the right one bigger, fiddler style), googly plate
eyes on short stalks and six jointed legs. You ride on its shell.

Run: python3 tools/pirate_red_crab.py [--gif]

Bones: root (shell) -> ClawL, ClawR -> PincerL, PincerR (the lower jaw, snaps open and shut);
root -> LegL1..3, LegR1..3 (1 = front).

  idle    claws snap, legs shuffle, the shell breathes
  walk    legs step in alternating pairs, claws swaying
  gallop  the same, faster and longer strides, claws up and snapping
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU

NAME = "RedCrab"
C = {"red": (232, 52, 40), "reddark": (170, 28, 30), "orange": (255, 128, 40), "cream": (255, 226, 176),
     "tip": (40, 30, 36)}


def build():
    m = Model(NAME, C)
    y0 = 2.6
    root = m.group("root", (0, y0, 0))
    p = [m.box("Belly", (0, y0 - 0.5, 0), (6.4, 1.2, 4.8), "cream"),
         m.box("Shell", (0, y0 + 0.5, 0.1), (7.6, 1.4, 5.4), "red"),
         m.box("Shell2", (0, y0 + 1.5, 0.2), (6.2, 0.8, 4.4), "red"),
         m.box("Shell3", (0, y0 + 2.1, 0.3), (4.4, 0.5, 3.2), "red"),
         m.box("Rim", (0, y0 - 0.05, 0.1), (7.9, 0.3, 5.7), "reddark")]
    # speckles on the shell's top steps (real little blocks)
    for k, (x, z) in enumerate(((-1.6, -0.4), (1.3, 0.9), (-0.4, 1.3), (2.4, -0.6), (-2.5, 0.9), (0.6, -0.9))):
        yy = y0 + (2.38 if abs(x) < 2.0 and abs(z) < 1.4 else 1.92)
        p.append(m.box(f"Speck{k + 1}", (x, yy, z), (0.55, 0.12, 0.55), "orange"))
    # a row of bumps along the shell's front edge
    for k, x in enumerate(np.linspace(-3.0, 3.0, 5)):
        p.append(m.box(f"Bump{k + 1}", (x, y0 + 1.05, -2.75), (0.6, 0.6, 0.4), "reddark"))
    # mouth: a little dark slot with cream mandibles under the front
    p += [m.box("Mouth", (0, y0 - 0.15, -2.45), (1.6, 0.45, 0.2), "tip"),
          m.box("MandibleL", (-0.45, y0 - 0.55, -2.5), (0.5, 0.45, 0.3), "cream"),
          m.box("MandibleR", (0.45, y0 - 0.55, -2.5), (0.5, 0.45, 0.3), "cream")]
    # eye stalks with googly eyes (eyes face outward and forward)
    for s in (-1, 1):
        n = "LR"[s > 0]
        base = (s * 1.3, y0 + 1.7, -1.9)
        top = (s * 1.5, y0 + 3.2, -2.1)
        p.append(m.seg(f"Stalk{n}", base, top, 0.45, 0.45, "red"))
        p.append(m.box(f"EyeBall{n}", (s * 1.5, y0 + 3.6, -2.1), (1.2, 1.2, 1.2), "red"))
        p += m.eye(f"Eye{n}", (s * 2.12, y0 + 3.65, -2.1), s, size=1.0)
        p += m.eye(f"EyeF{n}", (s * 1.5, y0 + 3.65, -2.72), "front", size=0.9, look=(s * 0.3, 0, 0))
    m.put(root, p)

    # claws: an arm reaching forward and up, then the big pincer (fixed top jaw + moving lower jaw)
    for s in (-1, 1):
        n = "LR"[s > 0]
        k = 1.25 if s > 0 else 1.0  # the right claw is the big one
        sh = np.array([s * 3.2, y0 + 0.2, -2.0])
        claw = m.group(f"Claw{n}", tuple(sh), root)
        el = sh + np.array([s * 1.0, 0.7, -0.8])
        hand = el + np.array([-s * 0.3, 0.5, -1.1])
        pc = hand + np.array([0, 0.2 * k, -1.0 * k])  # the palm's centre
        q = [m.seg(f"Arm{n}", sh, el, 0.9, 0.9, "red"),
             m.box(f"Elbow{n}", el, (1.0, 1.0, 1.0), "reddark"),
             m.seg(f"Wrist{n}", el, hand, 0.9, 0.9, "red"),
             m.box(f"Palm{n}", pc, (2.2 * k, 2.0 * k, 2.2 * k), "red"),
             m.box(f"PalmTop{n}", pc + np.array([0, 1.05 * k, 0.1 * k]), (1.6 * k, 0.3 * k, 1.6 * k), "reddark"),
             m.box(f"Finger{n}", pc + np.array([0, 0.45 * k, -1.7 * k]), (1.5 * k, 1.0 * k, 1.4 * k), "red"),
             m.pyr(f"FingerTip{n}", pc + np.array([0, 0.45 * k, -2.4 * k]), (0, -0.25, -1), (1, 0, 0), 1.2 * k,
                   0.65 * k, 0.45 * k, "tip")]
        q.append(m.pyr(f"ClawTooth{n}", pc + np.array([0, -0.05 * k, -1.9 * k]), (0, -1, 0), (0, 0, 1),
                       0.35 * k, 0.25 * k, 0.25 * k, "cream"))
        m.put(claw, q)
        jaw_p = pc + np.array([0, -0.55 * k, -1.0 * k])
        jaw = m.group(f"Pincer{n}", tuple(jaw_p), claw)
        m.put(jaw, [m.box(f"Jaw{n}", jaw_p + np.array([0, -0.15 * k, -0.6 * k]), (1.3 * k, 0.75 * k, 1.2 * k), "red"),
                    m.pyr(f"JawTip{n}", jaw_p + np.array([0, -0.15 * k, -1.2 * k]), (0, 0.25, -1), (1, 0, 0), 1.0 * k,
                          0.55 * k, 0.35 * k, "tip")])

    # six legs: out and up to a knee, then down to a pointed tip
    for i, (zz, fz) in enumerate(((-1.1, -0.6), (0.4, 0.0), (1.8, 0.7))):
        for s in (-1, 1):
            n = "LR"[s > 0]
            nm = f"Leg{n}{i + 1}"
            hip = np.array([s * 3.4, y0 - 0.2, zz])
            leg = m.group(nm, tuple(hip), root)
            knee = hip + np.array([s * 1.9, 1.0, fz])
            tip = knee + np.array([s * 1.5, -(y0 + 0.8), fz * 0.8])
            m.put(leg, [m.seg(nm + "Upper", hip, knee, 0.7, 0.7, "red"),
                        m.box(nm + "Knee", knee, (0.8, 0.8, 0.8), "reddark"),
                        m.seg(nm + "Lower", knee, tip + np.array([0, 0.5, 0]), 0.6, 0.6, "red"),
                        m.pyr(nm + "Tip", tip + np.array([0, 0.55, 0]), (0, -1, 0), (1, 0, 0), 0.6, 0.28, 0.28, "tip")])
    return m


def animations():
    def legs(L, swing, lift, n=16):
        tr = {}
        for i in range(3):
            for s, nm in ((-1, "L"), (1, "R")):
                ph = 0.0 if (i % 2 == 0) == (s < 0) else 0.5
                tr[f"Leg{nm}{i + 1}"] = [track(L, lambda u, s=s, ph=ph: (
                    0, s * swing * math.sin(TAU * (u + ph)), s * lift * max(0.0, math.cos(TAU * (u + ph)))), n)]
        return tr

    def claws(L, sway, snap, lift=0.0, n=16, speed=1):
        tr = {}
        for s, nm in ((-1, "L"), (1, "R")):
            tr[f"Claw{nm}"] = [track(L, lambda u, s=s: (lift + sway * math.sin(TAU * u), s * sway * 0.5 * math.cos(TAU * u), 0), n)]
            tr[f"Pincer{nm}"] = [track(L, lambda u, s=s: (snap * max(0.0, math.sin(TAU * speed * u + (s > 0) * 1.5)) ** 2, 0, 0), n)]
        return tr

    L = 2.4
    idle = {f"Leg{nm}{i + 1}": [track(L, lambda u, s=s, i=i: (0, s * 3 * math.sin(TAU * u + i * 1.3), 0), 16)]
            for i in range(3) for s, nm in ((-1, "L"), (1, "R"))}
    idle.update(claws(L, 4, 28, speed=2))
    idle["root"] = [track(L, lambda u: (0, 0.12 * math.sin(TAU * u), 0), 16, "position")]
    Lw = 0.7
    walk = {**legs(Lw, 20, 16), **claws(Lw, 6, 14),
            "root": [track(Lw, lambda u: (0, 0, 2.5 * math.sin(TAU * u)), 16),
                     track(Lw, lambda u: (0, 0.3 * abs(math.sin(TAU * u)), 0), 16, "position")]}
    Lg = 0.36
    gallop = {**legs(Lg, 28, 22), **claws(Lg, 10, 30, lift=-12, speed=2),
              "root": [track(Lg, lambda u: (-3, 0, 4 * math.sin(TAU * u)), 16),
                       track(Lg, lambda u: (0, 0.8 * abs(math.sin(TAU * u)), 0), 16, "position")]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


if __name__ == "__main__":
    build().save(animations())
