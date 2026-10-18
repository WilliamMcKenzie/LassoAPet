"""Eggs for World 3's Garden animals, in take C's style (tools/ocean_eggs.py, tools/hawkmoth_egg.py):
the octo shell coloured like the animal, a few of its features in real blocks and pyramids, googly
plate eyes on the front (glowing on the giga rares' and boss's eggs). Each stays under 150 parts.

Run from the repo root: python3 tools/garden_eggs.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/world3/garden/eggs/.
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell, layer_of  # noqa: E402
import garden_ladybug, garden_bumblebee, garden_frog, garden_vine, garden_flytrap, garden_lion  # noqa: E402,E401
import garden_rafflesia, garden_treant, garden_flytrap_queen  # noqa: E402,E401

WHITE, PUPIL = (255, 255, 255), (24, 22, 30)
TOP = N * LH


def fz(y, out=0.0):
    """The front face's z at height y, plus out further forward."""
    return -WIDTHS[layer_of(y)] / 2 - out


def half(y):
    return WIDTHS[layer_of(y)] / 2


def pyr(egg, name, base, d, L, hw, ht, color, bone=None):
    d = np.array(d, float) / np.linalg.norm(d)
    wv = np.array([1.0, 0, 0]) if abs(d[0]) < 0.9 else np.array([0, 0, 1.0])
    wv = wv - d * (wv @ d)
    wv /= np.linalg.norm(wv)
    tv = np.cross(d, wv)
    b = np.array(base, float)
    c = [b - wv * hw - tv * ht, b + wv * hw - tv * ht, b + wv * hw + tv * ht, b - wv * hw + tv * ht]
    a = b + d * L
    return egg.poly(name, [c] + [[c[i], c[(i + 1) % 4], a] for i in range(4)], color, bone=bone)


def eyes(egg, y, size=0.34, gap=0.1, glow=None, white=WHITE, out=0.0):
    """Two googly plate eyes on the front at height y (pupils glow on the big ones)."""
    z = fz(y, out)
    for s in (-1, 1):
        n = "LR"[s > 0]
        x0, x1 = sorted((s * gap, s * (gap + size)))
        egg.block(f"Eye{n}", (x0, y - size / 2, z - 0.05), (x1, y + size / 2, z + 0.01), white)
        p = size * 0.5
        cx = (x0 + x1) / 2
        egg.block(f"{'Glow_Pupil' if glow else 'Pupil'}{n}", (cx - p / 2, y - p / 2 - 0.03, z - 0.08),
                  (cx + p / 2, y + p / 2 - 0.03, z - 0.04), glow or PUPIL)


def spot(egg, name, x, y, w, color, side=0):
    """A raised spot on the front (side=0) or on a side (side=+-1), with real depth."""
    if side == 0:
        z = fz(y)
        egg.block(name, (x - w / 2, y - w / 2, z - 0.06), (x + w / 2, y + w / 2, z + 0.01), color)
    else:
        xx = side * half(y)
        egg.block(name, (min(xx, xx + side * 0.06), y - w / 2, x - w / 2), (max(xx, xx + side * 0.06), y + w / 2, x + w / 2), color)


def ring_spikes(egg, name, y, n, L, hw, color, tilt=0.0, out=0.0, offset=0.0, skip_front=0.0):
    """Pyramids pointing out round the egg at height y (tilt > 0 points them up)."""
    r = half(y) + out
    for k in range(n):
        a = 2 * math.pi * (k + offset) / n
        if abs(math.atan2(math.sin(a), math.cos(a))) < skip_front:
            continue  # leave the face clear
        d = np.array([math.sin(a), tilt, -math.cos(a)])
        pyr(egg, f"{name}{k}", (r * math.sin(a), y, -r * math.cos(a)), d, L, hw, hw * 0.6, color)


def ladybug_egg():
    c = garden_ladybug.C
    egg = shell([c["black"], c["red"], c["red"], c["red"], c["red"], c["red"], c["black"]])
    egg.block("Seam", (-0.05, LH, half(1.5) - 0.2), (0.05, TOP - LH, half(1.5) + 0.05), c["black"])
    for k, (x, y, w) in enumerate(((-0.6, 2.3, 0.3), (0.55, 2.6, 0.26), (0.65, 1.0, 0.28))):
        spot(egg, f"Spot{k}", x, y, w, c["black"])
    for s in (-1, 1):
        spot(egg, f"SpotSide{'LR'[s > 0]}", 0.3, 1.9, 0.34, c["black"], side=s)
    eyes(egg, 1.55)
    for s in (-1, 1):
        n = "LR"[s > 0]
        egg.block(f"Antenna{n}", (s * 0.25 - 0.05, TOP - 0.05, -0.05), (s * 0.25 + 0.05, TOP + 0.4, 0.05), c["black"]).bone = "top"
        egg.block(f"AntennaBall{n}", (s * 0.25 - 0.1, TOP + 0.4, -0.1), (s * 0.25 + 0.1, TOP + 0.6, 0.1), c["black"]).bone = "top"
    return egg


def bumblebee_egg():
    c = garden_bumblebee.C
    egg = shell([c["black"], c["yellow"], c["black"], c["yellow"], c["black"], c["yellow"], c["black"]])
    eyes(egg, 2.55, size=0.3)
    egg.block("Cheeks", (-0.5, 2.25, fz(2.3) - 0.05), (0.5, 2.33, fz(2.3) + 0.01), c["pink"]).plain = True
    for s in (-1, 1):
        n = "LR"[s > 0]
        x = s * half(2.0)
        egg.block(f"Wing{n}", (min(x, x + s * 0.5), 2.0, -0.2), (max(x, x + s * 0.5), 2.1, 0.5), c["wing"]).bone = "top"
        egg.block(f"WingRim{n}", (min(x + s * 0.45, x + s * 0.55), 1.98, -0.2), (max(x + s * 0.45, x + s * 0.55), 2.12, 0.5), c["wingrim"]).bone = "top"
        egg.block(f"Antenna{n}", (s * 0.22 - 0.05, TOP - 0.05, -0.05), (s * 0.22 + 0.05, TOP + 0.35, 0.05), c["black"]).bone = "top"
    pyr(egg, "Stinger", (0, 0.4, half(0.4)), (0, -0.3, 1), 0.35, 0.12, 0.12, c["black"], bone="bottom")
    return egg


def frog_egg():
    c = garden_frog.C
    egg = shell([c["green"], c["green"], c["green"], c["gill"], c["cap"], c["cap"], c["capdark"]])
    eyes(egg, 1.2, size=0.36, gap=0.12)
    egg.block("Mouth", (-0.45, 0.72, fz(0.75) - 0.05), (0.45, 0.8, fz(0.75) + 0.01), c["mouth"]).plain = True
    for k, (x, y, w) in enumerate(((-0.4, 2.35, 0.3), (0.45, 2.15, 0.26), (0.1, 2.85, 0.22))):
        spot(egg, f"CapSpot{k}", x, y, w, c["spot"])
    for s in (-1, 1):
        spot(egg, f"CapSpotSide{'LR'[s > 0]}", -0.1, 2.3, 0.3, c["spot"], side=s)
    egg.block("CapTop", (-0.2, TOP - 0.02, -0.2), (0.2, TOP + 0.08, 0.2), c["spot"]).bone = "top"
    return egg


def vine_egg():
    c = garden_vine.C
    egg = shell([c["vinedark"], c["vine"], c["vinemid"], c["vine"], c["vinemid"], c["vine"], c["vinemid"]])
    eyes(egg, 1.95, size=0.32)
    egg.block("Mouth", (-0.4, 1.25, fz(1.3) - 0.05), (0.4, 1.45, fz(1.3) + 0.01), c["mouth"]).plain = True
    for t in (-0.25, 0.0, 0.25):
        pyr(egg, "Tooth", (t, 1.45, fz(1.3) - 0.05), (0, -1, 0), 0.14, 0.05, 0.02, c["tooth"])
    ring_spikes(egg, "Thorn", 1.0, 6, 0.25, 0.08, c["thorn"], offset=0.5)
    # a light tendril curling up round the egg (blocks stepping round as they climb)
    for k in range(10):
        a = 2 * math.pi * (0.15 + 0.11 * k)
        y = 0.5 + 0.25 * k
        r = half(y) + 0.02
        egg.block(f"Tendril{k}", (r * math.sin(a) - 0.1, y - 0.08, -r * math.cos(a) - 0.1),
                  (r * math.sin(a) + 0.1, y + 0.08, -r * math.cos(a) + 0.1), c["vinelight"])
    # the rose on top
    for k in range(5):
        a = 2 * math.pi * k / 5
        pyr(egg, f"Petal{k}", (0.18 * math.sin(a), TOP, 0.18 * math.cos(a)), (math.sin(a), 0.9, math.cos(a)), 0.35, 0.14, 0.05,
            c["rose"], bone="top")
    egg.block("RoseMid", (-0.1, TOP - 0.02, -0.1), (0.1, TOP + 0.22, 0.1), c["rosedark"]).bone = "top"
    return egg


def flytrap_egg(c=None, glow=None, n=8):
    c = c or garden_flytrap.C
    egg = shell([c["greendark"], c["green"], c["green"], c["red"], c["red"], c["green"], c["green"]])
    # the crack is a mouth: spikes up from the lower lobe and down from the upper
    y = 4 * LH
    ring_spikes(egg, "SpikeLow", y - 0.25, n, 0.45, 0.05, c["spike"], tilt=1.2, out=0.0)
    ring_spikes(egg, "SpikeUp", y + 0.25, n, 0.45, 0.05, c["spike"], tilt=-1.2, out=0.0, offset=0.5)
    eyes(egg, 2.6, size=0.3, glow=glow, white=(24, 18, 28) if glow else WHITE)
    egg.block("Brow", (-0.5, 2.82, fz(2.8) - 0.1), (0.5, 2.9, fz(2.8) + 0.01), c["brow"])
    return egg


def lion_egg():
    c = garden_lion.C
    egg = shell([c["cream"], c["fur"], c["fur"], c["fur"], c["fur"], c["fur"], c["furdark"]])
    ring_spikes(egg, "Petal", 1.5, 10, 0.55, 0.22, c["petal"], tilt=0.15, offset=0.5, skip_front=0.8)
    ring_spikes(egg, "PetalB", 2.0, 10, 0.5, 0.2, c["petaldark"], tilt=0.5, offset=0.0, skip_front=0.8)
    egg.block("Muzzle", (-0.3, 1.0, fz(1.1) - 0.12), (0.3, 1.32, fz(1.1) + 0.01), c["cream"])
    egg.block("Nose", (-0.12, 1.22, fz(1.1) - 0.17), (0.12, 1.34, fz(1.1) - 0.1), c["nose"])
    eyes(egg, 2.15, size=0.36)
    for s in (-1, 1):
        egg.block(f"Ear{'LR'[s > 0]}", (s * 0.3 - 0.12, TOP - 0.1, -0.08), (s * 0.3 + 0.12, TOP + 0.15, 0.08), c["furdark"]).bone = "top"
    return egg


def rafflesia_egg():
    c = garden_rafflesia.C
    egg = shell([c["mossdark"], c["moss"], c["moss"], c["moss"], c["petal"], c["petal"], c["petaldark"]])
    eyes(egg, 1.35, size=0.34, glow=(150, 255, 60), white=(24, 18, 28))
    egg.block("Mouth", (-0.45, 0.85, fz(0.9) - 0.05), (0.45, 0.97, fz(0.9) + 0.01), c["mouth"]).plain = True
    for k, (x, y, w) in enumerate(((-0.45, 2.15, 0.18), (0.4, 2.45, 0.2), (0.0, 2.75, 0.16))):
        spot(egg, f"Wart{k}", x, y, w, c["wart"])
    for s in (-1, 1):
        spot(egg, f"WartSide{'LR'[s > 0]}", 0.2, 2.25, 0.2, c["wart"], side=s)
    # big petals fanning out from the crack, a cream rim on top round the well
    ring_spikes(egg, "Petal", 4 * LH + 0.1, 5, 0.7, 0.3, c["petal"], tilt=-0.1, offset=0.5)
    for k in range(6):
        a = 2 * math.pi * k / 6
        x, z = 0.28 * math.sin(a), 0.28 * math.cos(a)
        egg.block(f"Rim{k}", (x - 0.1, TOP - 0.02, z - 0.1), (x + 0.1, TOP + 0.16, z + 0.1), c["rim"]).bone = "top"
    egg.block("Well", (-0.2, TOP - 0.02, -0.2), (0.2, TOP + 0.04, 0.2), c["well"]).bone = "top"
    return egg


def treant_egg():
    c = garden_treant.C
    egg = shell([c["barkdark"], c["bark"], c["barklight"], c["bark"], c["leafdark"], c["leaf"], c["leaflight"]])
    for k, x in enumerate((-0.78, 0.78)):
        egg.block(f"Ridge{k}", (x - 0.05, 0.7, fz(1.2) - 0.04), (x + 0.05, 1.7, fz(1.2) + 0.01), c["barkdark"]).plain = True
    eyes(egg, 1.3, size=0.32, glow=(255, 190, 60), white=c["socket"])
    egg.block("Beard", (-0.3, 0.55, fz(0.8) - 0.1), (0.3, 0.95, fz(0.8) + 0.01), c["moss"])
    pyr(egg, "BeardTip", (0, 0.55, fz(0.8) - 0.05), (0, -1, 0), 0.25, 0.25, 0.05, c["moss"])
    for k, (x, y, z) in enumerate(((-0.6, 2.4, None), (0.55, 2.7, None), (0.1, 2.25, None))):
        spot(egg, f"Blossom{k}", x, y, 0.2, c["blossom"])
    for s in (-1, 1):
        spot(egg, f"BlossomSide{'LR'[s > 0]}", 0.1, 2.5, 0.22, c["blossomdark"], side=s)
    egg.block("BlossomTop", (-0.12, TOP - 0.02, -0.12), (0.12, TOP + 0.18, 0.12), c["blossom"]).bone = "top"
    return egg


def queen_egg():
    c = garden_flytrap_queen.C
    egg = flytrap_egg(c, glow=c["glowgreen"], n=6)
    # purple bulb bottom and a crown of magenta petals with glowing gold tips
    for k in range(3):
        x = -0.24 + 0.24 * k
        L = 0.5 if k == 1 else 0.36
        pyr(egg, f"Crown{k}", (x, TOP - 0.02, 0.0), (x * 0.4, 1, 0), L, 0.07, 0.07, c["crown"], bone="top")
        egg.block(f"Glow_Tip{k}", (x * 1.13 - 0.04, TOP + L - 0.04, -0.04), (x * 1.13 + 0.04, TOP + L + 0.04, 0.04), c["Glow"]).bone = "top"
    return egg


def queen_shell_egg():
    """The Queen's egg: the flytrap egg on a purple bulb."""
    c = garden_flytrap_queen.C
    egg = queen_egg()
    # repaint the bottom two shell layers purple (the bulb)
    for p in egg.parts:
        if p.color == c["greendark"] and getattr(p, "bone", "") == "bottom":
            p.color = c["bulb"]
    return egg


EGGS = [("Ladybug", ladybug_egg), ("Bumblebee", bumblebee_egg), ("ToadstoolFrog", frog_egg), ("VineMonster", vine_egg),
        ("VenusFlytrap", flytrap_egg), ("SunflowerLion", lion_egg), ("RafflesiaBeast", rafflesia_egg),
        ("AncientTreant", treant_egg), ("FlytrapQueen", queen_shell_egg)]

if __name__ == "__main__":
    O.EGGS = EGGS
    O.main(*sys.argv[1:], preview="/mnt/project-files/world3/garden/eggs")
