"""Eggs for World 3's Cnidaria (the reef) standard animals, in take C's style
(tools/ocean_eggs.py): the octo shell in each animal's colours with a few chunky details.
Pointy bits are pyramids.

  MoonJellyfish     lilac, a violet rim band, four glowing pink pads on top, fringe tentacles
  Anomalocaris      coral red with dark bands, orange side flaps, eye stalks, cream arms, blue tail
  BoxJellyfish      cyan, deep-blue corner pillars, a glowing bolt, tentacles with glowing tips
  BlueRingOctopus   sunny yellow covered in glowing blue rings, curly arm stubs round the bottom
  ManOWar           periwinkle running to pink, a magenta crest sail, stinging tentacles
  Mermaid           teal tail layers, pink shell and hair, a gold crown, pearls, a fluke, a trident
  AbyssalDragon     navy, turquoise belly plates, glowing back spines, gold horns and whiskers
  ReefTitan         sea green with a gold scute rim, coral and an anemone on top, flipper stubs
  RoyalCnidarian    violet and magenta, a gold crown with gems, scowling brows, glowing tentacles

Run from the repo root: python3 tools/cnidaria_eggs.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/world3/cnidaria/eggs/.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
import moon_jellyfish  # noqa: E402
import anomalocaris  # noqa: E402
import box_jellyfish  # noqa: E402
import blue_ring_octopus  # noqa: E402
import man_o_war  # noqa: E402

TOP = N * LH


def pyramid(egg, name, base, apex, color, bone=None):
    c = [np.array(p, float) for p in base]
    a = np.array(apex, float)
    p = egg.poly(name, [c] + [[c[i], c[(i + 1) % 4], a] for i in range(4)], color,
                 bone=bone or ("top" if (np.mean([q[1] for q in c]) > 4 * LH) else "bottom"))
    return p


def down_spike(egg, name, x, y, z, w, h, color):
    """A pyramid hanging point-down under (x, y, z)."""
    return pyramid(egg, name, [(x - w, y, z - w), (x + w, y, z - w), (x + w, y, z + w), (x - w, y, z + w)], (x, y - h, z), color)


def sided(egg, name, x0, x1, y0, y1, z0, z1, color, s):
    """A block mirrored to side s (-1 left, 1 right): x0/x1 given for the right side."""
    xa, xb = sorted((s * x0, s * x1))
    return egg.block(name + "LR"[s > 0], (xa, y0, z0), (xb, y1, z1), color)


def moon_egg():
    C = moon_jellyfish.COLORS
    egg = shell([C["rim"], C["bell2"], C["bell"], C["bell"], C["bell"], C["bell"], C["bell"]])
    w = WIDTHS[2] / 2 + 0.08
    egg.block("Rim", (-w, 2 * LH, -w * 0.62), (w, 2 * LH + 0.25, w * 0.62), C["rim"])
    egg.block("Rim2", (-w * 0.62, 2 * LH, -w), (w * 0.62, 2 * LH + 0.25, w), C["rim"])
    for k, (x, z) in enumerate(((-0.25, -0.25), (0.25, -0.25), (0.25, 0.25), (-0.25, 0.25))):
        egg.block(f"GlowPad{k + 1}", (x - 0.15, TOP - 0.02, z - 0.15), (x + 0.15, TOP + 0.1, z + 0.15), C["glow"]).bone = "top"
    for k, (x, z) in enumerate(((-0.9, -0.9), (0.9, -0.9), (0.9, 0.9), (-0.9, 0.9), (0, -1.2), (0, 1.2), (-1.2, 0), (1.2, 0))):
        egg.block(f"Fringe{k + 1}", (x - 0.08, LH, z - 0.08), (x + 0.08, 2 * LH + 0.05, z + 0.08), C["fringe2"])
    return egg


def anomalocaris_egg():
    C = anomalocaris.COLORS
    egg = shell([C["dark"], C["body"], C["body2"], C["body"], C["body2"], C["body"], C["body"]])
    for s in (-1, 1):
        for k, (y, col) in enumerate(((1.5 * LH, "flap"), (2.5 * LH, "flap2"), (3.5 * LH, "flap"))):
            x = WIDTHS[int(y / LH)] / 2 - 0.05
            sided(egg, f"Flap{k + 1}", x, x + 0.45 - 0.08 * k, y - 0.12, y + 0.12, -0.45, 0.45, C[col], s)
        # eye stalks with eyeballs on top
        sided(egg, "Stalk", 0.25, 0.4, TOP - 0.05, TOP + 0.45, -0.15, 0.0, C["body2"], s).bone = "top"
        sided(egg, "EyeBall", 0.12, 0.55, TOP + 0.45, TOP + 0.85, -0.3, 0.12, C["body"], s).bone = "top"
        sided(egg, "Eye", 0.2, 0.48, TOP + 0.5, TOP + 0.8, -0.34, -0.3, C["white"], s).bone = "top"
        sided(egg, "Pupil", 0.28, 0.42, TOP + 0.55, TOP + 0.72, -0.37, -0.34, C["pupil"], s).bone = "top"
        # cream arms curling out of the front low down, a spine pointing in
        zf = -WIDTHS[2] / 2
        sided(egg, "Arm", 0.25, 0.45, 1.2 * LH, 2.6 * LH, zf - 0.35, zf + 0.05, C["arm"], s)
        sided(egg, "ArmTip", 0.25, 0.45, 1.0 * LH, 1.3 * LH, zf - 0.55, zf - 0.2, C["arm"], s)
        x = s * 0.35
        pyramid(egg, "ArmSpine" + "LR"[s > 0], [(x - 0.08, 2 * LH, zf - 0.35), (x + 0.08, 2 * LH, zf - 0.35),
                                                (x + 0.08, 2 * LH + 0.16, zf - 0.35), (x - 0.08, 2 * LH + 0.16, zf - 0.35)],
                (x, 2 * LH + 0.08, zf - 0.7), C["spine"])
    # blue tail blades out the back
    zb = WIDTHS[3] / 2
    for k, (x, y) in enumerate(((-0.35, 3 * LH), (0.35, 3 * LH), (0, 3.6 * LH))):
        pyramid(egg, f"Tail{k + 1}", [(x - 0.15, y - 0.15, zb - 0.05), (x + 0.15, y - 0.15, zb - 0.05),
                                      (x + 0.15, y + 0.15, zb - 0.05), (x - 0.15, y + 0.15, zb - 0.05)],
                (x * 1.6, y + 0.15, zb + 0.6), C["tail"])
    return egg


def box_egg():
    C = box_jellyfish.COLORS
    egg = shell([C["edge"], C["bell2"], C["bell"], C["bell"], C["bell"], C["bell"], C["bell2"]])
    # deep-blue pillars at the four corners of the widest layers
    for k, (sx, sz) in enumerate(((1, 1), (1, -1), (-1, -1), (-1, 1))):
        d = WIDTHS[3] / 2 * 0.6
        egg.block(f"Pillar{k + 1}", (sx * d - 0.14, LH, sz * d - 0.14), (sx * d + 0.14, 5 * LH, sz * d + 0.14), C["edge"])
        # a short tentacle down from each corner with a glowing tip
        t = WIDTHS[1] / 2 * 0.62
        egg.block(f"Tent{k + 1}", (sx * t - 0.08, 0.3, sz * t - 0.08), (sx * t + 0.08, 1.2 * LH, sz * t + 0.08), C["tent2"])
        down_spike(egg, f"GlowTip{k + 1}", sx * t, 0.3, sz * t, 0.11, 0.3, C["glow"])
    # a glowing zigzag bolt on the front
    zf = -WIDTHS[3] / 2 - 0.04
    for k, (x0, y0, x1, y1) in enumerate(((0.0, 4.6 * LH, 0.22, 3.6 * LH), (-0.3, 3.75 * LH, 0.2, 3.45 * LH), (-0.25, 3.55 * LH, -0.02, 2.4 * LH))):
        egg.block(f"GlowBolt{k + 1}", (min(x0, x1), y1, zf - 0.06), (max(x0, x1), y0, zf + 0.1), C["glow"])
    return egg


def octopus_egg():
    C = blue_ring_octopus.COLORS
    egg = shell([C["skin2"], C["skin"], C["skin"], C["skin"], C["skin"], C["skin"], C["skin"]])
    # glowing blue rings (a glowing square round a dark centre) on the front, back and sides
    spots = [(0, 3.5, "z", -1), (0, 5.5, "z", -1), (0, 2.5, "z", 1), (0, 5.0, "z", 1),
             (0, 3.0, "x", -1), (0, 5.2, "x", -1), (0, 3.0, "x", 1), (0, 5.2, "x", 1)]
    for k, (o, layer, axis, s) in enumerate(spots):
        y = layer * LH
        r = WIDTHS[int(layer)] / 2 * 0.98
        sz = 0.18
        if axis == "z":
            egg.block(f"GlowRing{k + 1}", (o - sz, y - sz, s * r - 0.04), (o + sz, y + sz, s * r + 0.04), C["ring"])
            egg.block(f"RingC{k + 1}", (o - 0.08, y - 0.08, s * r - 0.06), (o + 0.08, y + 0.08, s * r + 0.06), C["ringc"])
        else:
            egg.block(f"GlowRing{k + 1}", (s * r - 0.04, y - sz, o - sz), (s * r + 0.04, y + sz, o + sz), C["ring"])
            egg.block(f"RingC{k + 1}", (s * r - 0.06, y - 0.08, o - 0.08), (s * r + 0.06, y + 0.08, o + 0.08), C["ringc"])
    # eight curly arm stubs round the bottom
    for k in range(8):
        a = np.radians(22.5 + 45 * k)
        dx, dz = np.sin(a), np.cos(a)
        r = WIDTHS[0] / 2
        x, z = dx * (r + 0.25), dz * (r + 0.25)
        egg.block(f"Arm{k + 1}", (x - 0.14, 0, z - 0.14), (x + 0.14, 0.22, z + 0.14), C["skin2"])
        x2, z2 = dx * (r + 0.45), dz * (r + 0.45)
        egg.block(f"ArmTip{k + 1}", (x2 - 0.1, 0.1, z2 - 0.1), (x2 + 0.1, 0.42, z2 + 0.1), C["skin2"])
    return egg


def man_o_war_egg():
    C = man_o_war.COLORS
    egg = shell([C["stop"], C["f0"], C["f1"], C["f2"], C["f3"], C["f4"], C["f5"]])
    # crest sail along the top, front to back
    for k, (z, h) in enumerate(((-0.3, 0.35), (-0.1, 0.55), (0.1, 0.65), (0.3, 0.45))):
        col = C["crest"] if k % 2 == 0 else C["crest2"]
        egg.block(f"Crest{k + 1}", (-0.1, TOP - 0.05, z - 0.1), (0.1, TOP + h, z + 0.1), col).bone = "top"
        egg.block(f"CrestRim{k + 1}", (-0.12, TOP + h, z - 0.1), (0.12, TOP + h + 0.1, z + 0.1), C["rib"]).bone = "top"
    # stinging tentacles down the sides with glowing pink pyramid tips
    for k, (x, z) in enumerate(((-1.0, -0.3), (1.0, -0.3), (-0.7, 0.7), (0.7, 0.7), (0, -1.05))):
        egg.block(f"Tent{k + 1}", (x - 0.08, 0.3, z - 0.08), (x + 0.08, 1.4 * LH + 0.2, z + 0.08), C["tent"])
        down_spike(egg, f"GlowTip{k + 1}", x, 0.3, z, 0.12, 0.35, C["glow"])
    return egg


EGGS = [("MoonJellyfish", moon_egg), ("Anomalocaris", anomalocaris_egg), ("BoxJellyfish", box_egg),
        ("BlueRingOctopus", octopus_egg), ("ManOWar", man_o_war_egg)]



# ---------------------------------------------------------------- the big four

GOLD, GOLD_DK, PEARL = (255, 196, 40), (214, 140, 20), (250, 244, 236)


def up_spike(egg, name, x, y, z, w, h, color, lean=(0, 0)):
    """A pyramid standing point-up on (x, y, z), its tip leaning by lean (dx, dz)."""
    return pyramid(egg, name, [(x - w, y, z - w), (x + w, y, z - w), (x + w, y, z + w), (x - w, y, z + w)],
                   (x + lean[0], y + h, z + lean[1]), color)


def crown(egg, y, r, color, gems, points=(0.5, 0.35)):
    """A gold band round the top with pyramid points, gems on the front."""
    egg.block("Crown", (-r, y, -r), (r, y + 0.22, r), color).bone = "top"
    for k, (x, z) in enumerate(((-r + 0.12, -r + 0.12), (0, -r + 0.12), (r - 0.12, -r + 0.12), (r - 0.12, 0),
                                (r - 0.12, r - 0.12), (0, r - 0.12), (-r + 0.12, r - 0.12), (-r + 0.12, 0))):
        up_spike(egg, f"CrownPoint{k + 1}", x, y + 0.22, z, 0.12, points[k % 2], color).bone = "top"
    for k, (x, col) in enumerate(((-0.2, gems[0]), (0.2, gems[1]))):
        egg.block(f"GlowGem{k + 1}", (x - 0.07, y + 0.05, -r - 0.05), (x + 0.07, y + 0.17, -r + 0.02), col).bone = "top"


def mermaid_egg():
    tail, tail2, tail_dk = (34, 206, 190), (20, 160, 168), (10, 100, 110)
    hair, shell_pk = (255, 92, 150), (255, 170, 190)
    egg = shell([tail_dk, tail2, tail, tail2, shell_pk, hair, hair])
    crown(egg, TOP - 0.05, WIDTHS[6] / 2 - 0.05, GOLD, (PEARL, PEARL))
    # pearl necklace band round the shell layer
    zf = -WIDTHS[4] / 2 - 0.03
    for k in range(5):
        x = -0.6 + 0.3 * k
        egg.block(f"Pearl{k + 1}", (x - 0.08, 4 * LH + 0.05, zf - 0.06), (x + 0.08, 4 * LH + 0.21, zf + 0.04), PEARL)
    # a forked fluke out of the back at the bottom
    zb = WIDTHS[1] / 2
    for s in (-1, 1):
        pyramid(egg, "Fluke" + "LR"[s > 0], [(s * 0.05, 0.9 * LH, zb - 0.1), (s * 0.05, 1.7 * LH, zb - 0.1),
                                            (s * 0.25, 1.7 * LH, zb - 0.1), (s * 0.25, 0.9 * LH, zb - 0.1)],
                (s * 0.7, 2.3 * LH, zb + 0.5), tail2)
    # a gold trident up the right side, glowing prongs
    x = WIDTHS[3] / 2 + 0.12
    egg.block("TridentShaft", (x - 0.06, 0.2, -0.06), (x + 0.06, 5.6 * LH, 0.06), GOLD)
    egg.block("TridentBar", (x - 0.06, 5.6 * LH, -0.3), (x + 0.06, 5.6 * LH + 0.1, 0.3), GOLD).bone = "top"
    for k, z in enumerate((-0.25, 0, 0.25)):
        up_spike(egg, f"GlowProng{k + 1}", x, 5.6 * LH + 0.1, z, 0.06, 0.3 + 0.1 * (z == 0), (150, 240, 255)).bone = "top"
    return egg


def dragon_egg():
    navy, indigo, teal, belly = (30, 30, 120), (64, 48, 180), (24, 190, 200), (90, 230, 220)
    egg = shell([teal, navy, navy, indigo, navy, navy, indigo])
    # turquoise belly plates down the front
    zf = -WIDTHS[3] / 2
    for i in range(1, 5):
        w = WIDTHS[i] / 2 * 0.45
        egg.block(f"Belly{i}", (-w, i * LH + 0.04, -WIDTHS[i] / 2 - 0.05), (w, (i + 1) * LH - 0.04, -WIDTHS[i] / 2 + 0.1), belly)
    # glowing spines down the back
    for i in range(1, 7):
        z = WIDTHS[i] / 2 - 0.05
        col = (60, 240, 255) if i % 2 else (170, 80, 255)
        pyramid(egg, f"GlowSpine{i}", [(-0.1, i * LH + 0.05, z), (0.1, i * LH + 0.05, z), (0.1, i * LH + 0.35, z), (-0.1, i * LH + 0.35, z)],
                (0, i * LH + 0.35, z + 0.4), col)
    # gold swept-back horns and whiskers
    for s in (-1, 1):
        up_spike(egg, "Horn" + "LR"[s > 0], s * 0.3, TOP - 0.05, 0.05, 0.12, 0.8, GOLD, lean=(s * 0.3, 0.35)).bone = "top"
        sided(egg, "Whisker", WIDTHS[5] / 2 - 0.05, WIDTHS[5] / 2 + 0.55, 5.3 * LH, 5.3 * LH + 0.1, zf * 0.7 - 0.05, zf * 0.7 + 0.05, GOLD, s)
    return egg


def titan_egg():
    green, green2, dark, ochre = (30, 150, 110), (20, 118, 90), (16, 60, 50), (240, 170, 40)
    egg = shell([dark, green2, green, green, green2, green, green])
    # gold scute rim round the middle
    for i, w in ((2, WIDTHS[2] / 2 + 0.06),):
        egg.block("Rim", (-w, i * LH, -w * 0.6), (w, i * LH + 0.2, w * 0.6), ochre)
        egg.block("Rim2", (-w * 0.6, i * LH, -w), (w * 0.6, i * LH + 0.2, w), ochre)
    # coral on top: staghorn branches with pyramid tips, a brain coral, glowing anemone
    for k, (x, z, h, col) in enumerate(((-0.25, 0.1, 0.5, (255, 100, 170)), (0.25, -0.1, 0.4, (255, 140, 40)), (0.0, 0.3, 0.3, (255, 100, 170)))):
        egg.block(f"Coral{k + 1}", (x - 0.07, TOP - 0.05, z - 0.07), (x + 0.07, TOP + h, z + 0.07), col).bone = "top"
        up_spike(egg, f"CoralTip{k + 1}", x, TOP + h, z, 0.09, 0.2, col).bone = "top"
    egg.block("BrainCoral", (0.1, TOP - 0.05, 0.12), (0.4, TOP + 0.18, 0.4), (255, 210, 60)).bone = "top"
    egg.block("GlowAnemone", (-0.4, TOP - 0.05, -0.35), (-0.18, TOP + 0.2, -0.13), (90, 240, 230)).bone = "top"
    # flipper stubs out the sides
    for s in (-1, 1):
        sided(egg, "Flipper", WIDTHS[2] / 2 - 0.05, WIDTHS[2] / 2 + 0.5, 2 * LH - 0.1, 2 * LH + 0.1, -0.5, 0.1, (90, 190, 130), s)
    return egg


def boss_egg():
    violet, magenta, orchid, plum = (120, 40, 200), (220, 60, 190), (240, 150, 240), (70, 20, 90)
    egg = shell([plum, magenta, violet, magenta, violet, orchid, orchid])
    crown(egg, TOP - 0.05, WIDTHS[6] / 2 - 0.02, GOLD, ((80, 240, 255), (255, 70, 170)))
    # scowling brows on the front
    zf = -WIDTHS[5] / 2 - 0.04
    for s in (-1, 1):
        sided(egg, "Brow", 0.1, 0.5, 5.3 * LH, 5.3 * LH + 0.12, zf - 0.06, zf + 0.06, plum, s)
    # glowing tentacles down the sides with pyramid tips
    for k in range(6):
        a = np.radians(30 + 60 * k)
        r = WIDTHS[1] / 2 + 0.03
        x, z = np.sin(a) * r, np.cos(a) * r
        col = (80, 240, 255) if k % 2 else (255, 70, 170)
        egg.block(f"GlowTent{k + 1}", (x - 0.07, 0.3, z - 0.07), (x + 0.07, 2.2 * LH, z + 0.07), col)
        down_spike(egg, f"GlowTip{k + 1}", x, 0.3, z, 0.1, 0.3, col)
    return egg


EGGS += [("Mermaid", mermaid_egg), ("AbyssalDragon", dragon_egg), ("ReefTitan", titan_egg), ("RoyalCnidarian", boss_egg)]

if __name__ == "__main__":
    O.EGGS = EGGS
    O.main(*sys.argv[1:], preview="/mnt/project-files/world3/cnidaria/eggs")
