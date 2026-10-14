"""Flytrap Queen: World 3 Garden boss (draft, Oct 14), also a Legendary trophy pet like the Seraphs.
A towering many-headed flytrap: a huge dark bulb wrapped in two rings of giant leaves, scuttling on
six gnarled root legs; a tall central stem carries the Queen's head (the biggest trap, wide open,
magenta inside, ringed with cream spikes) wearing a crown of magenta petals (pyramids) with glowing
gold tips; two more heads on curving stems at her sides and two small ones behind them. Every eye is
a dark plate with a glowing green pupil (bosses glow). The heads chomp out of step as she charges.

Run: python3 tools/garden_flytrap_queen.py [--gif]
Bones (all rest 0): root -> HeadQ/HeadL/HeadR/HeadBL/HeadBR (stem + lower lobe) -> <name>Jaw;
Leg1L..Leg3R. Reuses build_trap() from tools/garden_flytrap.py.
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, Rm, track, sin, TAU
from garden_flytrap import build_trap

C = {"green": (52, 150, 52), "greendark": (24, 88, 40), "red": (220, 36, 140), "reddark": (130, 16, 90),
     "spike": (252, 240, 206), "root": (96, 60, 44), "rootdark": (60, 38, 30), "leaf": (84, 184, 60),
     "leafdark": (38, 120, 48), "brow": (16, 52, 24), "bulb": (86, 40, 96), "bulbdark": (52, 22, 64),
     "crown": (236, 60, 170), "crowndark": (170, 30, 120), "Glow": (255, 214, 60), "eyedark": (24, 18, 28),
     "glowgreen": (150, 255, 60)}


def stem(g, node, base, steps, cols=("green", "greendark")):
    """A curving stem: steps = [(direction, length, thickness)], each block starting where the last ended."""
    p = np.array(base, float)
    for k, (d, L, t) in enumerate(steps):
        d = np.array(d, float) / np.linalg.norm(d)
        g.box(node, "Stem", p + d * L / 2, (t, L + 0.4, t), cols[k % 2], G.frame(d))
        p = p + d * L
    return p


def build():
    g = Garden("FlytrapQueen", C, group="bosses")
    y0 = 7.0
    root = g.group("root", (0, y0, 0))
    # the bulb and two rings of leaves
    g.box(root, "Bulb", (0, y0 + 0.5, 1.0), (10.0, 7.0, 10.0), "bulb")
    g.box(root, "BulbBand", (0, y0 + 0.5, 1.0), (10.6, 1.2, 10.6), "bulbdark")
    g.box(root, "BulbTop", (0, y0 + 4.3, 1.0), (7.6, 1.0, 7.6), "bulbdark")
    for ring, (rad, yy, tilt, L, w, cols, off) in enumerate(((5.8, y0 - 1.6, 20, 6.4, 3.6, ("leaf", "leafdark"), 0),
                                                            (4.6, y0 + 1.6, 34, 5.0, 3.0, ("leafdark", "leaf"), 0.5))):
        for k in range(10):
            ang = 360 * (k + off) / 10
            a = np.radians(ang)
            M = Rm(("y", ang), ("x", -tilt))
            c = np.array([rad * np.sin(a), yy, 1.0 + rad * np.cos(a)])
            g.box(root, "Leaf", c, (w, 0.6, L), cols[k % 2], M)
            g.pyr(root, "LeafTip", c + M @ np.array([0, 0, L / 2]), M @ np.array([0, 0, 1.0]), 1.6, w / 2 - 0.2, 0.3,
                  cols[k % 2])
    # six root legs: out, then down, a pyramid claw
    for i, z in enumerate((-2.8, 1.0, 4.8)):
        for side, s in (("L", -1), ("R", 1)):
            p = np.array([s * 4.0, y0 - 2.0, z])
            leg = g.group(f"Leg{i + 1}{side}", p, root)
            out = np.array([s, 0.55, (z - 1.0) * 0.12])
            out /= np.linalg.norm(out)
            g.box(leg, f"Leg{i + 1}{side}", p + out * 2.6, (2.4, 5.2, 2.4), "root", G.frame(out))
            knee = p + out * 5.2
            g.box(leg, f"Knee{i + 1}{side}", knee, (2.8, 2.8, 2.8), "rootdark")
            g.box(leg, f"Shin{i + 1}{side}", (knee[0] + s * 0.6, knee[1] / 2 + 0.4, knee[2]), (2.2, knee[1], 2.2), "rootdark")
            g.pyr(leg, f"Claw{i + 1}{side}", (knee[0] + s * 0.6, 0.6, knee[2]), (s * 0.3, -1, 0), 0.8, 0.8, 0.8, "rootdark")
            g.pyr(leg, f"Toe{i + 1}{side}", (knee[0] + s * 0.6, 0.5, knee[2] - 0.6), (s * 0.4, -0.2, -1), 1.6, 0.5, 0.4, "rootdark")

    eyes = dict(glow="glowgreen", white="eyedark")
    # the Queen: tall central stem, the biggest trap, a crown of petals
    q = g.group("HeadQ", (0, y0 + 4.6, 0.4), root)
    tip = stem(g, q, (0, y0 + 4.6, 0.4), [((0, 1, 0.05), 4.0, 2.6), ((0, 1, -0.25), 4.0, 2.4), ((0, 1, -0.7), 3.4, 2.2)])
    hinge = tip + (0, 0.8, 1.2)
    build_trap(g, q, q, hinge, (9.0, 9.2, 1.4), 40, name="Q", **eyes)
    M = Rm(("x", 40))
    crown_c = hinge + M @ np.array([0, 1.4 + 0.6, -1.8])  # on the upper lobe, behind the eyes
    g.box(q, "CrownBand", crown_c, (7.4, 1.2, 3.0), "crowndark", M)
    for k in range(7):
        x = -3.0 + 6.0 * k / 6
        L = 4.2 if k in (0, 6) else (6.6 if k == 3 else 5.2)
        up = Rm(("x", 10)) @ np.array([x * 0.12, 1.0, 0])  # stands up, leaning back a little
        base = crown_c + M @ np.array([x, 0.5, 0])
        g.pyr(q, "CrownPetal", base, up, L, 0.8, 0.6, "crown" if k % 2 == 0 else "crowndark")
        g.box(q, "Glow_CrownTip", base + up / np.linalg.norm(up) * (L - 0.1), (0.7, 0.7, 0.7), "Glow")
    # side heads on curving stems, two small ones behind
    for side, s in (("L", -1), ("R", 1)):
        h = g.group("Head" + side, (s * 3.0, y0 + 3.6, 0.0), root)
        tip = stem(g, h, (s * 3.0, y0 + 3.6, 0.0), [((s * 1, 0.6, 0), 3.4, 2.0), ((s * 0.4, 1, -0.2), 3.0, 1.8),
                                                     ((0, 1, -0.7), 2.4, 1.7)])
        build_trap(g, h, h, tip + (0, 0.6, 0.8), (6.2, 6.4, 1.1), 36, name=side, **eyes)
        b = g.group("HeadB" + side, (s * 2.6, y0 + 3.8, 4.0), root)
        tip = stem(g, b, (s * 2.6, y0 + 3.8, 4.0), [((s * 0.6, 1, 0.5), 3.2, 1.5), ((s * 0.3, 1, -0.3), 2.6, 1.4)])
        build_trap(g, b, b, tip + (0, 0.5, 0.6), (4.4, 4.6, 0.9), 32, name="B" + side, **eyes)
    return g


def animations(m):
    heads = (("Q", 0.0, 1.0), ("L", 0.33, 0.9), ("R", 0.66, 0.9), ("BL", 0.15, 0.7), ("BR", 0.8, 0.7))
    legs = [(f"Leg{i}{s}", (0.0 if (i + (s == "R")) % 2 else 0.5)) for i in (1, 2, 3) for s in "LR"]

    def charge(L, swing, lean, hop, chomp, sway, n=16):
        tr = {"root": [track(L, lambda u: (lean, 0, 2.5 * sin(TAU * u)), n),
                       track(L, lambda u: (0, hop * abs(sin(TAU * u)), 0), n, "position")]}
        for b, ph in legs:
            tr[b] = [track(L, lambda u, ph=ph: (swing * sin(TAU * (u + ph)), 0, 0), n)]
        for h, ph, k in heads:
            head = "Head" + h if h != "Q" else "HeadQ"
            tr[head] = [track(L, lambda u, ph=ph, k=k: (-lean * 0.6 + k * 5 * sin(TAU * (u + ph)), k * sway * sin(TAU * (u + ph)), 0), n)]
            tr[h + "Jaw"] = [track(L, lambda u, ph=ph: (chomp * max(0, sin(TAU * (u + ph))) ** 2, 0, 0), n)]
        return tr

    L = 4.0
    idle = {"root": [track(L, lambda u: (0, 2 * sin(TAU * 2 * u), 0), 24, "position")]}
    for h, ph, k in heads:
        head = "Head" + h if h != "Q" else "HeadQ"
        idle[head] = [track(L, lambda u, ph=ph, k=k: (k * 4 * sin(TAU * (u + ph)), k * 10 * sin(TAU * (u + ph)), 0), 24)]
        idle[h + "Jaw"] = [track(L, lambda u, ph=ph: (30 * max(0, sin(TAU * (2 * u + ph))) ** 8, 0, 0), 48)]
    return {"idle": (L, idle), "walk": (1.0, charge(1.0, 18, 0, 3, 20, 8)), "gallop": (0.6, charge(0.6, 30, 8, 8, 36, 12))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/FlytrapQueen_anims.gif")
