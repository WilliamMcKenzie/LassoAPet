"""Eggs for World 3's Cnidaria (the reef) standard animals, in take C's style
(tools/ocean_eggs.py): the octo shell in each animal's colours with a few chunky details.
Pointy bits are pyramids.

  MoonJellyfish     lilac, a violet rim band, four glowing pink pads on top, fringe tentacles
  Anomalocaris      coral red with dark bands, orange side flaps, eye stalks, cream arms, blue tail
  BoxJellyfish      cyan, deep-blue corner pillars, a glowing bolt, tentacles with glowing tips
  BlueRingOctopus   sunny yellow covered in glowing blue rings, curly arm stubs round the bottom
  ManOWar           periwinkle with a pink top, a magenta crest sail, stinging tentacles

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
        egg.block(f"Fringe{k + 1}", (x - 0.08, LH, z - 0.08), (x + 0.08, 2 * LH + 0.05, z + 0.08), C["fringe"])
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
    egg = shell([C["float2"], C["float"], C["float"], C["float"], C["float"], C["blush"], C["blush"]])
    # crest sail along the top, front to back
    for k, (z, h) in enumerate(((-0.3, 0.35), (-0.1, 0.55), (0.1, 0.65), (0.3, 0.45))):
        col = C["crest"] if k % 2 == 0 else C["crest2"]
        egg.block(f"Crest{k + 1}", (-0.1, TOP - 0.05, z - 0.1), (0.1, TOP + h, z + 0.1), col).bone = "top"
        egg.block(f"CrestRim{k + 1}", (-0.12, TOP + h, z - 0.1), (0.12, TOP + h + 0.1, z + 0.1), C["rim"]).bone = "top"
    # stinging tentacles down the sides with glowing pink pyramid tips
    for k, (x, z) in enumerate(((-1.0, -0.3), (1.0, -0.3), (-0.7, 0.7), (0.7, 0.7), (0, -1.05))):
        egg.block(f"Tent{k + 1}", (x - 0.08, 0.3, z - 0.08), (x + 0.08, 1.4 * LH + 0.2, z + 0.08), C["tent"])
        down_spike(egg, f"GlowTip{k + 1}", x, 0.3, z, 0.12, 0.35, C["glow"])
    return egg


EGGS = [("MoonJellyfish", moon_egg), ("Anomalocaris", anomalocaris_egg), ("BoxJellyfish", box_egg),
        ("BlueRingOctopus", octopus_egg), ("ManOWar", man_o_war_egg)]

if __name__ == "__main__":
    O.EGGS = EGGS
    O.main(*sys.argv[1:], preview="/mnt/project-files/world3/cnidaria/eggs")
