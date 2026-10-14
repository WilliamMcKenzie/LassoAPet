"""World 3 biome 4, Cnidaria (underwater reef) props (QM, Oct 14): brain coral, staghorn
coral, sea fan, tall kelp, anemone, giant clam with a pearl, tube coral, sunken column,
bubble vent, seashells and a starfish. Same style as the other prop sets (faceted convex
pieces, flat shaded, studded, one colour per piece). Colours are my picks.

Run: python3 tools/w3_cnidaria.py
Writes design/w3_cnidaria/<Name>.obj, pieces/<Name>_<i>.obj + colours.txt, sizes.txt and
cnidaria_lineup.png.
"""

import math
import os

import numpy as np

from w3props import (HERE, blob, prism, ball, disc, tube, torus, rot_y, rot_x, rot_z, move,
                     build_set, lineup_row, stack)
from crimson_meshes import slab
from tomb_meshes import ring, frustum, band
from rock_meshes import chunk

OUT = os.path.join(HERE, "..", "design", "w3_cnidaria")
CORAL_PINK = (255, 110, 150)
CORAL_DEEP = (216, 70, 120)
STAG = (255, 140, 60)
STAG_TIP = (255, 214, 120)
FAN = (176, 92, 236)
FAN_DARK = (136, 64, 200)
KELP = (96, 200, 96)
KELP_LIGHT = (170, 234, 90)
FLOAT = (240, 210, 70)
ANEMONE = (60, 204, 204)
TENTACLE = (255, 128, 210)
CLAM = (100, 120, 230)
CLAM_LIGHT = (150, 170, 250)
FLESH = (255, 170, 190)
PEARL = (255, 248, 252)
MARBLE = (232, 232, 238)
MARBLE_DARK = (204, 206, 216)
ALGAE = (90, 196, 130)
ROCK = (104, 112, 150)
ROCK_DARK = (84, 90, 126)
BUBBLE = (196, 238, 255)
TUBE = (255, 200, 80)
TUBE_IN = (230, 120, 40)
SHELL = (255, 214, 120)
SHELL_PINK = (255, 110, 160)
STAR = (255, 80, 60)


def brain_coral(rng):
    """A big brain coral dome (about 9 across): pink dome with deep-pink ridges."""
    dome = blob(rng, (0, 0.4, 0), 4.4, 30, squash=(1.0, 0.75, 1.0), jitter=0.03)
    dome = dome[dome[:, 1] > -0.4]
    dome = np.concatenate([dome, np.array(ring(14, 4.4, -0.4))])
    ridges = [band(dome, y - 0.22, y + 0.22, 0.035) for y in (0.6, 1.5, 2.3, 3.0)]
    cap = [ball((0, 3.55, 0), 1.0, 10, squash=(1.0, 0.3, 1.0))]
    return [("Coral", CORAL_PINK, [dome]), ("Ridges", CORAL_DEEP, ridges + cap)]


def staghorn(rng):
    """A staghorn coral (about 10 tall): orange branches that fork twice, pale tips."""
    branches, tips = [], []

    def grow(p, d, length, r, depth):
        q = p + d * length
        branches.extend(tube(rng, [p, p + d * length * 0.5 + (rng.uniform(-0.3, 0.3), 0, rng.uniform(-0.3, 0.3)), q], r, r * 0.8, 7))
        if depth == 0:
            tips.append(np.array(ring(4, r * 0.9, 0) + [(0, r * 2.2, 0)]) @ np.eye(3) + q - (0, r * 0.3, 0))  # pyramid tip
            return
        for k in range(2 if depth > 1 else 3):
            a = rng.uniform(0, 2 * math.pi)
            nd = d + np.array((math.cos(a), 0.2, math.sin(a))) * 0.75
            grow(q, nd / np.linalg.norm(nd), length * 0.72, r * 0.75, depth - 1)

    for a in (0.3, 2.4, 4.4):
        d = np.array((math.cos(a) * 0.35, 1, math.sin(a) * 0.35))
        grow(np.array((math.cos(a) * 0.6, -0.3, math.sin(a) * 0.6)), d / np.linalg.norm(d), 3.6, 0.7, 2)
    return [("Coral", STAG, branches), ("Tips", STAG_TIP, tips)]


def sea_fan(rng):
    """A sea fan (about 11 tall): a flat purple fan of ribbed lobes on a short trunk."""
    lobes, ribs = [], []
    base = np.array((0, 2.0, 0))
    for i in range(7):
        a = math.radians(30 + 120 * i / 6)
        d = np.array((math.cos(a), math.sin(a), 0))
        s = np.array((-d[1], d[0], 0))
        L = 8.0 - abs(i - 3) * 0.9
        pts = []
        for t, w in ((0.0, 0.2), (0.5, 1.1), (0.85, 1.0), (1.0, 0.45)):
            p = base + d * L * t
            for k in (-1, 1):
                for z in (-0.18, 0.18):
                    pts.append(p + s * k * w + (0, 0, z + 0.4 * t * t * (1 if i % 2 else -1)))
        lobes.append(np.array(pts))
        ribs.append(prism(rng, base + (0, 0, -0.25), base + d * L * 0.95 + (0, 0, -0.25), 0.18, 0.12, 5, 0.0))
    trunk = [prism(rng, (0, -0.4, 0), base + (0, 0.5, 0), 0.75, 0.5, 7, 0.0)]
    holdfast = [chunk(rng, 0, 0, 1.6, 0.9, 7)]
    return [("Fan", FAN, lobes[0::2]), ("Fan", (200, 120, 250), lobes[1::2]), ("Veins", FAN_DARK, ribs + trunk), ("Rock", ROCK, holdfast)]


def kelp(rng):
    """Tall glowing kelp (about 24 tall): three thick, tapered wavy fronds."""
    blades = [[], []]
    for i, (x, z, h) in enumerate(((0, 0, 24), (1.8, 0.9, 18), (-1.7, 0.5, 15))):
        prev = np.array((x, -0.4, z))
        ph = rng.uniform(0, 6.28)
        n = 5
        for k in range(1, n + 1):
            t = k / n
            p = np.array((x + 1.1 * math.sin(ph + t * 5.5) * t, h * t, z + 0.6 * math.cos(ph + t * 4) * t))
            w = 1.6 * (1 - 0.7 * t) + 0.15
            yaw = ph + t * 2
            s = np.array((math.cos(yaw), 0, math.sin(yaw)))
            nrm = np.array((-s[2], 0, s[0])) * (0.5 * (1 - 0.6 * t))  # thick, tapering
            pts = [prev + s * w + nrm, prev - s * w + nrm, prev + s * w - nrm, prev - s * w - nrm,
                   p + s * w * 0.9 + nrm, p - s * w * 0.9 + nrm, p + s * w * 0.9 - nrm, p - s * w * 0.9 - nrm]
            blades[(i + k) % 2].append(np.array(pts))
            prev = p
    return [("Kelp", KELP, blades[0]), ("Kelp", KELP_LIGHT, blades[1])]


def anemone(rng):
    """A sea anemone (about 6 across): a teal column and a crown of curling pink tentacles."""
    body = [frustum(12, 1.8, -0.3, 1.5, 2.2), frustum(12, 1.5, 2.1, 2.1, 2.9)]
    mouth = [disc((0, 2.95, 0), 0.7, 0.1, 10)]
    tents, tips = [], []
    for ring_i, (r, n, L) in enumerate(((1.9, 13, 2.6), (1.2, 8, 2.2))):
        for i in range(n):
            a = 2 * math.pi * i / n + ring_i * 0.25
            d = np.array((math.cos(a), 0, math.sin(a)))
            p0 = d * r + (0, 2.8, 0)
            p1 = p0 + d * L * 0.4 + (0, L * 0.5, 0)
            p2 = p1 + d * L * 0.45 + (0, L * 0.15, 0)
            tents += tube(rng, [p0, p1, p2], 0.3, 0.22, 6)
            tips.append(np.array(ring(4, 0.3, 0) + [(0, 0.9, 0)]) + p2 - (0, 0.1, 0))  # pyramid tip
    return [("Body", ANEMONE, body), ("Mouth", (30, 150, 160), mouth), ("Tentacles", TENTACLE, tents), ("Tips", (255, 220, 240), tips)]


def giant_clam(rng):
    """A giant clam (about 10 across) gaping open with a big pearl on its pink flesh:
    two scalloped shell halves of six ribs each, hinged at the back."""
    R = 5.0

    def half():
        ribs = []
        for i in range(6):
            a0, a1 = math.pi * i / 6, math.pi * (i + 1) / 6
            am = (a0 + a1) / 2
            pts = [(0, 0, 0), (0, 0.6, 0)]
            for a in (a0, a1):
                pts += [(math.cos(a) * R, 0.0, -math.sin(a) * R), (math.cos(a) * R * 0.97, 1.5, -math.sin(a) * R * 0.97)]
            pts.append((math.cos(am) * R * 1.06, 1.9, -math.sin(am) * R * 1.06))
            ribs.append(np.array(pts))
        return ribs

    hinge = np.array((0, 1.7, R * 0.5))
    lower = [p + (0, 0, R * 0.5) for p in half()]
    upper = [rot_x(p * (1, -1, 1), 1.35) + hinge for p in half()]  # opened wide, a clear lid
    flesh = [blob(rng, (0, 1.3, 0.2), 3.4, 16, squash=(1.0, 0.3, 0.8), jitter=0.04)]
    pearl = [ball((0, 2.9, -0.6), 1.45, 18)]
    return [("Shell", CLAM, lower[0::2] + upper[0::2]), ("Shell", CLAM_LIGHT, lower[1::2] + upper[1::2]),
            ("Flesh", FLESH, flesh), ("Pearl", PEARL, pearl)]


def tube_coral(rng):
    """A cluster of tube corals (about 6 across): yellow pipes with orange mouths."""
    pipes, rims = [], []
    for x, z, h, r, lx, lz in ((0, 0, 6.5, 0.9, 0.3, 0), (1.6, 0.6, 4.5, 0.75, 0.8, 0.2), (-1.5, 0.7, 5.2, 0.8, -0.7, 0.3),
                               (0.4, -1.5, 3.4, 0.7, 0.2, -0.6), (-1.0, -1.1, 2.6, 0.6, -0.4, -0.4)):
        top = np.array((x + lx, h, z + lz))
        pipes.append(prism(rng, (x, -0.4, z), top, r * 0.8, r, 9, 0.0))
        rims.append(np.array(ring(9, r * 1.12, top[1] - 0.25, c=(top[0], top[2])) + ring(9, r * 1.12, top[1] + 0.2, c=(top[0], top[2]))))
    return [("Tubes", TUBE, pipes), ("Mouths", TUBE_IN, rims)]


def sunken_column(rng):
    """A sunken Greek column (about 14 tall) snapped off and leaning, its fallen drum and
    capital half buried, green algae patches."""
    flutes = 12
    shaft = [frustum(flutes, 1.5, -0.6, 1.35, 11.0)]
    grooves = [band(shaft[0], y, y + 0.3, 0.04) for y in (3.6, 7.2)]
    plinth = [slab(rng, -2.4, -0.6, -2.4, 2.4, 1.0, 2.4, 0.15, 0.0)]
    top = [np.array(ring(flutes, 1.35, 11.0) + [(0.6, 12.4, 0.2), (-0.5, 11.6, -0.6), (0.2, 12.0, 0.8)])]
    algae = [blob(rng, (1.2, 2.2, -0.6), 0.9, 10, squash=(0.6, 1.6, 0.9)), blob(rng, (-0.9, 6.0, -1.0), 0.8, 10, squash=(0.7, 1.4, 0.8)),
             blob(rng, (2.0, 0.9, -1.6), 0.8, 8, squash=(1.0, 0.6, 1.0))]
    lean = lambda p: rot_z(p, -0.18)  # noqa: E731
    drum = [rot_x(frustum(flutes, 1.4, 0, 1.4, 3.2), math.pi / 2) + (5.4, 1.0, -1.0)]
    cap = [slab(rng, -6.6, -0.4, 1.8, -3.0, 1.0, 5.4, 0.2, 0.0), frustum(flutes, 1.4, 0.9, 1.0, 1.6, c=(-4.8, 3.6))]
    return [("Column", MARBLE, move(shaft + top, lean) + drum), ("Trim", MARBLE_DARK, move(plinth + grooves, lean) + cap),
            ("Algae", ALGAE, move(algae, lean))]


def bubble_vent(rng):
    """A bubble vent (about 13 tall): a stacked rock chimney with a dark mouth and a
    column of bubbles rising out of it."""
    rocks = [chunk(rng, 0, 0, 3.0, 3.2, 7), chunk(rng, 0.2, 0.1, 2.2, 5.6, 7, bevel=0.15)]
    rocks_b = [chunk(rng, 3.0, 1.2, 1.4, 1.2, 6), chunk(rng, -2.8, -1.6, 1.2, 1.0, 6)]
    rim = [np.array(ring(9, 1.4, 5.4, c=(0.2, 0.1)) + ring(9, 1.1, 6.2, c=(0.2, 0.1)))]
    mouth = [disc((0.2, 6.25, 0.1), 0.85, 0.12, 9)]
    bubbles = [ball((0.2 + 0.5 * math.sin(i * 1.7), 7.2 + i * 1.25 + 0.15 * i * i, 0.1 + 0.4 * math.cos(i * 2.3)), 0.45 + 0.12 * i, 12)
               for i in range(5)]
    return [("Rock", ROCK, rocks), ("Rock", ROCK_DARK, rocks_b + rim), ("Mouth", (40, 40, 70), mouth), ("Bubbles", BUBBLE, bubbles)]


def shells(rng):
    """Seashells (about 12 across): a spiral conch, a scallop and a starfish."""
    conch = []
    for i in range(7):
        t = i / 6
        r0, r1 = 1.4 * (1 - t * 0.8), 1.4 * (1 - (t + 1 / 6) * 0.8)
        conch.append(frustum(8, r0, 0, r1, 0.7, a0=i * 0.4) @ np.array([[0, 1, 0], [1, 0, 0], [0, 0, 1]]).T + (-0.8 + i * 0.6, 1.2, 0))
    lip = [blob(rng, (-1.4, 1.2, -0.4), 1.4, 10, squash=(0.5, 1.0, 0.8), jitter=0.04)]
    conch = move(conch + lip, lambda p: rot_y(p, 0.5) + (-1.4, 0, 0.6))
    scallop = []
    for i in range(5):
        a0, a1 = math.pi * (0.1 + 0.8 * i / 5), math.pi * (0.1 + 0.8 * (i + 1) / 5)
        pts = [(0, 0.0, 0), (0, 0.3, 0)]
        for a in (a0, a1):
            pts += [(math.cos(a) * 1.6, 0.0, -math.sin(a) * 1.6), (math.cos(a) * 1.6, 0.5, -math.sin(a) * 1.6)]
        pts.append((math.cos((a0 + a1) / 2) * 1.6, 0.75, -math.sin((a0 + a1) / 2) * 1.6))
        scallop.append(np.array(pts) + (2.4, 0, 0.6))
    star = []
    for i in range(5):
        a = 2 * math.pi * i / 5
        d = np.array((math.cos(a), 0, math.sin(a)))
        s = np.array((-d[2], 0, d[0]))
        c = np.array((0.6, 0, -1.8))
        star.append(np.array([c + s * 0.6, c - s * 0.6, c + s * 0.6 + (0, 0.5, 0), c - s * 0.6 + (0, 0.5, 0), c + d * 1.8 + (0, 0.1, 0), c + d * 1.8 + (0, 0.25, 0)]))
    big = lambda hs: [np.asarray(h) * 1.8 for h in hs]  # noqa: E731  bigger, so they read at a glance
    return [("Conch", SHELL, big(conch)), ("Scallop", SHELL_PINK, big(scallop[0::2])), ("Scallop", (255, 160, 200), big(scallop[1::2])),
            ("Starfish", STAR, big(star))]


ITEMS = [  # name, builder, seed, label
    ("Kelp", kelp, 3, "Tall kelp"),
    ("SunkenColumn", sunken_column, 1, "Sunken column"),
    ("BubbleVent", bubble_vent, 2, "Bubble vent"),
    ("SeaFan", sea_fan, 1, "Sea fan"),
    ("Staghorn", staghorn, 4, "Staghorn coral"),
    ("BrainCoral", brain_coral, 1, "Brain coral"),
    ("GiantClam", giant_clam, 1, "Giant clam"),
    ("TubeCoral", tube_coral, 1, "Tube coral"),
    ("Anemone", anemone, 1, "Anemone"),
    ("Seashells", shells, 1, "Seashells"),
]

SEABED = [(232, 214, 170), (220, 202, 158)]


def main():
    built, sizes = build_set(OUT, ITEMS)
    rows = [lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[:5]], SEABED),
            lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[5:]], SEABED, ppst=30)]
    stack(rows, os.path.join(OUT, "cnidaria_lineup.png"), "Cnidaria props (1x; figure is 5 studs)")


if __name__ == "__main__":
    main()
