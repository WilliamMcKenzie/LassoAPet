"""Parrot: World 3 Pirate Cove's Uncommon (Oct 14), the pirate's macaw (RotMG's Cave Pirate Macaw).
A scarlet macaw that flies everywhere: red body, wings banded red, yellow and blue with long
blue flight feathers, a long red and blue tail, a white face patch with googly plate eyes, a big
hooked cream beak over a black lower beak, and a little black tricorn pirate hat with gold trim
and a white skull. Feet tucked under. You ride on its back between the wings.

Run: python3 tools/pirate_parrot.py [--gif]

Bones: root (body) -> neck (head); root -> WingL -> WingL2, WingR -> WingR2 (flap about Z);
root -> Tail.

  idle    hovers, slow flaps, head tilting about
  walk    steady flaps, nosing forward
  gallop  fast deep flaps, diving forward, tail streaming
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU

NAME = "Parrot"
C = {"red": (232, 36, 44), "reddark": (168, 20, 36), "yellow": (255, 206, 30), "blue": (36, 112, 236),
     "bluedark": (24, 70, 180), "green": (52, 190, 80), "face": (250, 246, 240), "beak": (250, 236, 200),
     "hat": (36, 32, 44)}


def build():
    m = Model(NAME, C)
    y0 = 5.0
    root = m.group("root", (0, y0, 0))
    p = [m.box("Body", (0, y0, 0), (3.8, 3.4, 5.4), "red"),
         m.box("Chest", (0, y0 - 0.3, -2.4), (3.4, 3.0, 1.2), "red"),
         m.box("Belly", (0, y0 - 1.55, 0.2), (3.0, 0.4, 4.2), "reddark"),
         m.box("Back", (0, y0 + 1.85, 0.6), (3.0, 0.4, 3.6), "reddark"),
         m.box("Rump", (0, y0 - 0.2, 3.0), (2.8, 2.6, 1.2), "red")]
    # tucked feet: grey-black toes under the belly
    for s in (-1, 1):
        n = "LR"[s > 0]
        p += [m.box(f"Thigh{n}", (s * 0.9, y0 - 1.9, 0.6), (0.9, 0.6, 1.0), "reddark"),
              m.box(f"Foot{n}", (s * 0.9, y0 - 2.3, 1.2), (0.7, 0.4, 1.4), "hat")]
    m.put(root, p)

    # tail: long red centre feathers flanked by blue ones, fanning slightly
    tail = m.group("Tail", (0, y0 - 0.2, 3.4), root)
    t = []
    for k, (x, col, L) in enumerate(((-1.0, "blue", 5.0), (-0.35, "red", 6.6), (0.35, "red", 6.6), (1.0, "blue", 5.0))):
        a = np.array([x * 0.6, y0 - 0.2, 3.4])
        b = a + np.array([x * 0.9, -0.6 - 0.05 * L, L])
        t.append(m.seg(f"Tail{k + 1}", a, b, 1.0, 0.45, col, up=(0, 1, 0)))
        t.append(m.box(f"TailTip{k + 1}", b, (1.05, 0.5, 0.9), "bluedark" if col == "blue" else "blue",
                       ))
    m.put(tail, t)

    # head: red cap on top, white face patches with eyes, big hooked beak, tricorn hat
    hy, hz = y0 + 2.0, -3.4
    neck = m.group("neck", (0, y0 + 1.0, -2.4), root)
    h = [m.box("Neck", (0, y0 + 1.2, -2.6), (2.6, 2.0, 1.6), "red"),
         m.box("Head", (0, hy, hz), (3.2, 3.0, 3.0), "red"),
         m.box("Cheek", (0, hy - 0.3, hz - 1.0), (3.0, 2.0, 1.2), "face")]
    for s in (-1, 1):
        n = "LR"[s > 0]
        h.append(m.box(f"Face{n}", (s * 1.62, hy - 0.1, hz - 0.3), (0.1, 2.0, 2.2), "face"))
        # a few little lines on the white face (macaws have feather stripes): dark red blocks
        for j in range(2):
            h.append(m.box(f"FaceLine{n}{j + 1}", (s * 1.66, hy - 0.7 + 0.4 * j, hz - 0.9), (0.08, 0.14, 0.8), "reddark"))
        h += m.eye(f"Eye{n}", (s * 1.7, hy + 0.25, hz + 0.1), s, size=1.25, look=(0, 0, -1))
    # beak: upper beak block + hooked pyramid down, black lower beak
    bz = hz - 1.6
    h += [m.box("BeakTop", (0, hy + 0.1, bz - 0.5), (1.6, 1.4, 1.6), "beak"),
          m.pyr("BeakHook", (0, hy - 0.4, bz - 1.2), (0, -1, -0.35), (1, 0, 0), 1.3, 0.7, 0.45, "beak"),
          m.box("BeakLow", (0, hy - 0.95, bz - 0.35), (1.3, 0.8, 1.1), "hat")]
    # tricorn: a wide black brim turned up on three sides, a crown, gold trim, a white skull
    ty = hy + 1.5
    h += [m.box("HatBrim", (0, ty + 0.15, hz + 0.2), (4.0, 0.3, 3.6), "hat"),
          m.box("HatCrown", (0, ty + 0.85, hz + 0.3), (2.6, 1.2, 2.4), "hat"),
          m.box("HatBand", (0, ty + 0.4, hz + 0.3), (2.7, 0.3, 2.5), "gold"),
          m.box("HatFront", (0, ty + 0.9, hz - 1.45), (3.0, 1.1, 0.3), "hat"),
          m.box("HatFrontTrim", (0, ty + 1.5, hz - 1.45), (3.1, 0.18, 0.36), "gold"),
          m.box("Skull", (0, ty + 1.0, hz - 1.65), (0.8, 0.65, 0.1), "white"),
          m.box("SkullJaw", (0, ty + 0.6, hz - 1.65), (0.5, 0.25, 0.1), "white")]
    for s in (-1, 1):
        n = "LR"[s > 0]
        h += [m.box(f"HatSide{n}", (s * 1.85, ty + 0.75, hz + 0.6), (0.3, 1.0, 2.6), "hat"),
              m.box(f"HatSideTrim{n}", (s * 1.85, ty + 1.3, hz + 0.6), (0.36, 0.18, 2.7), "gold"),
              m.box(f"SkullEye{n}", (s * 0.18, ty + 1.05, hz - 1.72), (0.18, 0.18, 0.05), "hat")]
    m.put(neck, h)

    # wings: inner half red, a yellow band, blue coverts; the outer half blue with long feathers
    for s in (-1, 1):
        n = "LR"[s > 0]
        sh = np.array([s * 1.9, y0 + 1.0, -0.8])
        w = m.group(f"Wing{n}", tuple(sh), root)
        x0 = sh[0]
        q = [m.box(f"WingArm{n}", (x0 + s * 2.1, y0 + 1.0, -0.9), (4.2, 1.1, 1.6), "red"),
             m.box(f"WingRed{n}", (x0 + s * 2.1, y0 + 0.9, 0.5), (4.2, 0.8, 1.4), "red"),
             m.box(f"WingYellow{n}", (x0 + s * 2.1, y0 + 0.85, 1.6), (4.0, 0.7, 1.0), "yellow"),
             m.box(f"WingBlue{n}", (x0 + s * 2.1, y0 + 0.8, 2.5), (3.8, 0.6, 1.0), "blue")]
        m.put(w, q)
        el = np.array([x0 + s * 4.2, y0 + 1.0, -0.8])
        w2 = m.group(f"Wing{n}2", tuple(el), w)
        q2 = [m.box(f"WingHand{n}", (el[0] + s * 1.6, y0 + 1.0, -0.6), (3.2, 0.9, 1.4), "blue"),
              m.box(f"WingHandYellow{n}", (el[0] + s * 1.4, y0 + 0.9, 0.6), (2.8, 0.7, 1.0), "yellow")]
        # five long flight feathers fanning out and back
        for j in range(5):
            a = np.array([el[0] + s * (0.4 + 0.75 * j), y0 + 0.85, 0.9])
            b = a + np.array([s * (0.2 + 0.45 * j), -0.1, 2.6 + 0.3 * j])
            q2.append(m.seg(f"Feather{n}{j + 1}", a, b, 0.8, 0.45, "bluedark" if j % 2 else "blue", up=(0, 1, 0)))
        m.put(w2, q2)
    return m


def animations():
    def flap(L, amp, amp2, bias=0.0, n=16):
        tr = {}
        for s, nm in ((-1, "L"), (1, "R")):
            tr[f"Wing{nm}"] = [track(L, lambda u, s=s: (0, 0, -s * (bias + amp * math.sin(TAU * u))), n)]
            tr[f"Wing{nm}2"] = [track(L, lambda u, s=s: (0, 0, -s * amp2 * math.sin(TAU * u - 0.9)), n)]
        return tr

    L = 1.2
    idle = {**flap(L, 32, 18, 6),
            "root": [track(L, lambda u: (0, 0.6 * math.sin(TAU * u - 1.4), 0), 16, "position")],
            "neck": [track(L, lambda u: (4 * math.sin(TAU * u), 0, 5 * math.sin(TAU * u - 1.0)), 16)],
            "Tail": [track(L, lambda u: (4 * math.sin(TAU * u), 0, 0), 16)]}
    Lw = 0.7
    walk = {**flap(Lw, 38, 22, 4),
            "root": [track(Lw, lambda u: (-4, 0, 0), 4), track(Lw, lambda u: (0, 0.7 * math.sin(TAU * u - 1.4), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (4 + 3 * math.sin(TAU * u), 0, 0), 16)],
            "Tail": [track(Lw, lambda u: (6 * math.sin(TAU * u), 0, 0), 16)]}
    Lg = 0.4
    gallop = {**flap(Lg, 46, 28, 0),
              "root": [track(Lg, lambda u: (-10, 0, 0), 4), track(Lg, lambda u: (0, 0.9 * math.sin(TAU * u - 1.4), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (10, 0, 0), 4)],
              "Tail": [track(Lg, lambda u: (-8 + 5 * math.sin(TAU * u), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


if __name__ == "__main__":
    build().save(animations())
