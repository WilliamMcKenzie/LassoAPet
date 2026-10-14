"""Treasure Turtle: World 3 Pirate Cove's Legendary (Oct 14). A huge old sea turtle carrying its own
desert island: a stepped green shell with gold-edged scutes, a sand island on top with a leaning
palm tree (coconuts, drooping fronds with pyramid tips) and a little treasure chest. Teal skin
with darker spots, a hooked pyramid beak, googly plate eyes, big front flippers and small back
ones. You ride on the island's sand next to the palm.

Run: python3 tools/pirate_turtle.py [--gif]

Bones: root (shell and island) -> neck (head); root -> FlipperFL, FlipperFR, FlipperBL,
FlipperBR; root -> Palm (sways).

  idle    head bobbing, flippers paddling slowly, the palm swaying
  walk    a flipper crawl: front flippers sweep together, the shell rocking
  gallop  big fast sweeps, the shell lurching, the palm whipping
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU

NAME = "TreasureTurtle"
C = {"skin": (52, 196, 172), "skindark": (28, 140, 128), "shell": (60, 150, 60), "shelldark": (34, 100, 44),
     "sand": (250, 222, 150), "sanddark": (226, 190, 110), "trunk": (150, 98, 52), "trunkdark": (110, 70, 36),
     "leaf": (60, 210, 70), "leafdark": (30, 150, 50), "coconut": (110, 66, 34), "wood": (170, 98, 46),
     "beak": (250, 220, 120)}


def build():
    m = Model(NAME, C)
    y0 = 3.2
    root = m.group("root", (0, y0, 0))
    # the shell: belly plate, a wide rim, three stepped layers
    p = [m.box("Plastron", (0, y0 - 0.6, 0), (8.0, 1.2, 10.0), "beak"),
         m.box("Rim", (0, y0 + 0.4, 0), (10.0, 1.0, 12.0), "shelldark"),
         m.box("Shell1", (0, y0 + 1.3, 0), (9.0, 1.0, 11.0), "shell"),
         m.box("Shell2", (0, y0 + 2.2, 0), (7.4, 0.9, 9.2), "shell"),
         m.box("Shell3", (0, y0 + 3.0, 0), (5.6, 0.8, 7.0), "shell")]
    # gold-edged scutes: dark green blocks round the shell's first step with gold dots between
    for k, (x, z) in enumerate(((-3.6, -3.6), (3.6, -3.6), (-3.6, 0), (3.6, 0), (-3.6, 3.6), (3.6, 3.6),
                                (0, -4.6), (0, 4.6))):
        p.append(m.box(f"Scute{k + 1}", (x, y0 + 1.85, z), (1.8, 0.2, 1.8), "shelldark"))
        p.append(m.box(f"ScuteGold{k + 1}", (x, y0 + 1.97, z), (0.6, 0.12, 0.6), "gold"))
    # the island: a stepped sand mound on top of the shell
    yi = y0 + 3.4
    p += [m.box("Sand1", (0, yi + 0.3, 0.2), (5.0, 0.6, 6.4), "sand"),
          m.box("Sand2", (0.6, yi + 0.8, 1.0), (3.2, 0.5, 3.6), "sand"),
          m.box("SandEdge", (0, yi + 0.05, 0.2), (5.4, 0.3, 6.8), "sanddark")]
    # a little treasure chest at the back left of the island, lid open on gold
    cx, cz = -1.5, 2.2
    p += [m.box("Chest", (cx, yi + 1.2, cz), (1.6, 1.0, 1.2), "wood"),
          m.box("ChestBand", (cx, yi + 1.2, cz), (0.3, 1.04, 1.24), "gold"),
          m.box("ChestGold", (cx, yi + 1.75, cz), (1.4, 0.2, 1.0), "gold"),
          m.box("ChestLid", (cx, yi + 2.1, cz + 0.65), (1.7, 0.9, 0.3), "wood"),
          m.box("Glow_Gem", (cx + 0.3, yi + 1.95, cz - 0.1), (0.35, 0.35, 0.35), "beak")]
    # tail: a short pointed stub out the back
    p.append(m.pyr("Tail", (0, y0 + 0.2, 5.8), (0, -0.2, 1), (1, 0, 0), 1.6, 0.6, 0.4, "skin"))
    m.put(root, p)

    # palm: a curved trunk leaning out over the front right, coconuts and drooping fronds
    base = np.array([1.5, yi + 1.0, 0.6])
    palm = m.group("Palm", tuple(base), root)
    pts = [base + [0.0, 0, 0], base + [0.5, 2.4, 0.2], base + [1.2, 4.6, 0.1], base + [2.1, 6.4, -0.3]]
    q = []
    for k, (a, b) in enumerate(zip(pts, pts[1:])):
        q.append(m.seg(f"Trunk{k + 1}", a, b, 1.0 - 0.1 * k, 1.0 - 0.1 * k, "trunk"))
        q.append(m.box(f"Ring{k + 1}", b, (1.05 - 0.1 * k, 0.3, 1.05 - 0.1 * k), "trunkdark"))
    top = pts[-1] + [0, 0.4, 0]
    q.append(m.box("Crown", top, (1.2, 0.8, 1.2), "leafdark"))
    for k, (dx, dz) in enumerate(((1, 0), (-1, 0), (0, 1), (0, -1), (0.7, 0.7), (-0.7, -0.7))):
        d = np.array([dx, 0, dz], float)
        d /= np.linalg.norm(d)
        mid = top + d * 2.0 + [0, 0.3, 0]
        tip = top + d * 3.6 + [0, -1.2, 0]
        col = "leaf" if k % 2 == 0 else "leafdark"
        q.append(m.seg(f"Frond{k + 1}A", top, mid, 1.2, 0.35, col, up=(0, 1, 0)))
        q.append(m.seg(f"Frond{k + 1}B", mid, tip, 1.0, 0.35, col, up=(0, 1, 0)))
        q.append(m.pyr(f"Frond{k + 1}Tip", tip, tip - mid, (d[2], 0, -d[0]) if abs(d[1]) < 0.9 else (1, 0, 0), 0.9, 0.5, 0.17, col))
    for k, (dx, dz) in enumerate(((0.6, -0.4), (-0.5, -0.3), (0.0, 0.6))):
        q.append(m.box(f"Coconut{k + 1}", top + [dx, -0.6, dz], (0.6, 0.6, 0.6), "coconut"))
    m.put(palm, q)

    # head: a big blunt head on a thick neck, hooked beak, plate eyes, spots
    neck = m.group("neck", (0, y0 + 0.4, -5.5), root)
    hy, hz = y0 + 2.0, -8.4
    h = [m.seg("Neck", (0, y0 + 0.4, -5.2), (0, hy - 0.3, hz + 1.0), 2.6, 2.4, "skin"),
         m.box("Head", (0, hy, hz), (3.4, 2.8, 3.2), "skin"),
         m.box("HeadTop", (0, hy + 1.5, hz + 0.2), (2.6, 0.3, 2.4), "skindark"),
         m.box("BeakTop", (0, hy - 0.2, hz - 1.9), (2.2, 1.2, 0.8), "beak"),
         m.pyr("BeakHook", (0, hy - 0.6, hz - 2.25), (0, -1, -0.4), (1, 0, 0), 0.9, 0.9, 0.3, "beak"),
         m.box("BeakLow", (0, hy - 1.15, hz - 1.6), (2.0, 0.5, 1.0), "golddark")]
    for s in (-1, 1):
        n = "LR"[s > 0]
        h += m.eye(f"Eye{n}", (s * 1.72, hy + 0.4, hz - 0.5), s, size=1.3)
        h += [m.box(f"Spot{n}{k + 1}", (s * 1.72, hy - 0.7 + 0.2 * k, hz + 0.6 + 0.6 * k), (0.06, 0.5, 0.5), "skindark")
              for k in range(2)]
    m.put(neck, h)

    # flippers: long front flippers swept back, short back ones
    for s in (-1, 1):
        n = "LR"[s > 0]
        sh = np.array([s * 4.2, y0 - 0.2, -3.2])
        f = m.group(f"FlipperF{n}", tuple(sh), root)
        tip = sh + np.array([s * 4.6, -(y0 - 0.6), 1.6])
        m.put(f, [m.seg(f"FlipF{n}", sh, tip, 2.4, 0.8, "skin", up=(0, 1, 0)),
                  m.seg(f"FlipFEdge{n}", sh + [0, -0.05, 0.9], tip + [0, -0.05, 0.6], 1.0, 0.7, "skindark", up=(0, 1, 0)),
                  m.pyr(f"FlipFTip{n}", tip, (s * 1, -0.1, 0.35), (0, 0, 1), 1.2, 1.0, 0.35, "skin")])
        hp = np.array([s * 3.4, y0 - 0.4, 4.0])
        b = m.group(f"FlipperB{n}", tuple(hp), root)
        tip = hp + np.array([s * 2.2, -(y0 - 0.8), 1.8])
        m.put(b, [m.seg(f"FlipB{n}", hp, tip, 1.8, 0.7, "skin", up=(0, 1, 0)),
                  m.pyr(f"FlipBTip{n}", tip, (s * 0.6, -0.1, 1), (1, 0, 0), 0.9, 0.8, 0.3, "skin")])
    return m


def animations():
    def paddle(L, amp, lift, n=16):
        tr = {}
        for s, nm in ((-1, "L"), (1, "R")):
            tr[f"FlipperF{nm}"] = [track(L, lambda u, s=s: (0, s * amp * math.sin(TAU * u), s * lift * max(0.0, math.cos(TAU * u))), n)]
            tr[f"FlipperB{nm}"] = [track(L, lambda u, s=s: (0, -s * amp * 0.6 * math.sin(TAU * u + 1.2), 0), n)]
        return tr

    L = 3.0
    idle = {**paddle(L, 6, 4),
            "neck": [track(L, lambda u: (4 * math.sin(TAU * u), 8 * math.sin(TAU * u * 0.5 * 2), 0), 16)],
            "Palm": [track(L, lambda u: (2 * math.sin(TAU * u), 0, 3 * math.sin(TAU * u + 1)), 16)]}
    Lw = 1.2
    walk = {**paddle(Lw, 26, 14),
            "root": [track(Lw, lambda u: (2 * math.sin(TAU * u), 0, 0), 16),
                     track(Lw, lambda u: (0, 0.4 * max(0.0, math.sin(TAU * u)), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (-3 * math.sin(TAU * u), 0, 0), 16)],
            "Palm": [track(Lw, lambda u: (4 * math.sin(TAU * u - 1), 0, 2 * math.sin(TAU * u)), 16)]}
    Lg = 0.6
    gallop = {**paddle(Lg, 36, 20),
              "root": [track(Lg, lambda u: (4 * math.sin(TAU * u), 0, 0), 16),
                       track(Lg, lambda u: (0, 1.0 * max(0.0, math.sin(TAU * u)), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (6 - 5 * math.sin(TAU * u), 0, 0), 16)],
              "Palm": [track(Lg, lambda u: (8 * math.sin(TAU * u - 1), 0, 4 * math.sin(TAU * u)), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


if __name__ == "__main__":
    build().save(animations())
